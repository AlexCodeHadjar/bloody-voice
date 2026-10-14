class_name DistrictView
extends Control
## The district map in a camera (GDD 20.3): drag with the held left button, zoom with the wheel, clicks on landmarks
## and streets. Everything inside `world` is in art pixels. Knows no rules: it only reports what was clicked.

signal landmark_hovered(landmark: DistrictMapDef.LandmarkDef)  ## null when the mouse leaves every landmark
signal landmark_clicked(landmark: DistrictMapDef.LandmarkDef)
signal street_clicked(point: Vector2)  ## art pixels
signal hero_double_clicked
signal city_requested  ## the wheel was turned on past the farthest zoom: rise to the city map (owner 2026-10-14)

const DRAG_THRESHOLD := 6.0  ## px of mouse travel before a press becomes a drag (GDD 20.3)
const ZOOM_MAX := 1.25
const ZOOM_STEP := 1.12
const PULL_TICKS := 3  ## wheel notches past the farthest zoom that rise to the city map (owner 2026-10-14)
const PULL_RESET_MS := 1500  ## a pause this long starts the count again
const PULL_GAP_MS := 180  ## notches closer than this count once (a touchpad sends many events per swipe)
const START_ZOOM := 0.8
const JUMP_TIME := 0.45
const HERO_PICK_RADIUS := 70.0  ## art px around the hero's feet that count as "the hero" for a double-click

var map: DistrictMapDef
var world := Node2D.new()
var overlay: DistrictOverlay
var hero: Node2D = null  ## for the double-click on the hero; the camera never follows him (owner 2026-10-14)

var _zoom := START_ZOOM
var _pressed := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _hovered: DistrictMapDef.LandmarkDef = null
var _jump: Tween = null
var _pull := 0  ## wheel notches past the farthest zoom
var _pull_ms := 0
var _pull_label: Label = null  ## «turn on — the city map» at the bottom while pulling out
var _pull_fade: Tween = null
var markup: MapMarkupEditor  ## F3 markup (debug builds): the picked point and its move
var markup_ui: MapMarkupUi = null  ## F3 markup tools: right-click menu, chain mode, legend (set by the screen)
var _dev_label: Label = null  ## F3 markup help and the last save, over the map

const EDIT_PICK := 18.0  ## screen px around a node, a landmark centre or a zone corner that picks it in F3 markup


func setup(district_map: DistrictMapDef) -> void:
	map = district_map
	markup = MapMarkupEditor.new(map, ContentDB.data.life(map.district))
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	world.z_index = -10  # the map, residents and smoke stay under every panel and window (they use z 3..5 inside)
	add_child(world)
	var art := Sprite2D.new()
	art.centered = false
	art.texture = UiKit.texture(map.image)
	world.add_child(art)
	resized.connect(func() -> void: _apply(world.position))


## Adds a layer above the art (life, hero, ...). Layers are drawn in the order they are added.
func add_layer(node: Node2D) -> void:
	world.add_child(node)


## The veil and hover outline go on top of everything else.
func add_overlay(o: DistrictOverlay) -> void:
	overlay = o
	o.markup = markup
	o.z_index = 6  # over the residents (z 3..5): veil, signboards, hover and the F3 markup
	world.add_child(o)


func zoom_level() -> float:
	return _zoom


## Art pixel in the middle of the view: the zone under it chooses the background sound.
func camera_center() -> Vector2:
	return screen_to_art(size * 0.5)


func screen_to_art(p: Vector2) -> Vector2:
	return (p - world.position) / _zoom


func art_to_screen(p: Vector2) -> Vector2:
	return world.position + p * _zoom


## Puts `p` (art px) in the middle of the view, at once or with a short glide.
func center_on(p: Vector2, glide: bool = false) -> void:
	if _jump != null:
		_jump.kill()
	var target := _clamped(size * 0.5 - p * _zoom)
	if not glide:
		_apply(target)
		return
	_jump = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_jump.tween_method(_apply, world.position, target, JUMP_TIME)


func _gui_input(event: InputEvent) -> void:
	if map == null:
		return
	if event is InputEventMouseButton:
		_on_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_on_motion(event as InputEventMouseMotion)


func _on_button(mb: InputEventMouseButton) -> void:
	match mb.button_index:
		MOUSE_BUTTON_WHEEL_UP when mb.pressed:
			_pull = 0
			_zoom_at(mb.position, _zoom * ZOOM_STEP)
		MOUSE_BUTTON_WHEEL_DOWN when mb.pressed:
			if _zoom <= _min_zoom() + 0.001:
				_pull_out()
			else:
				_zoom_at(mb.position, _zoom / ZOOM_STEP)
		MOUSE_BUTTON_RIGHT when mb.pressed and _markup_on() and markup_ui != null:
			markup_ui.right_click(mb.position)
		MOUSE_BUTTON_LEFT:
			if _markup_button(mb):
				return
			if mb.pressed:
				_pressed = true
				_dragging = false
				_press_pos = mb.position
				if mb.double_click and hero != null \
						and screen_to_art(mb.position).distance_to(hero.position) < HERO_PICK_RADIUS:
					hero_double_clicked.emit()
			else:
				if _pressed and not _dragging:
					_click(screen_to_art(mb.position))
				_pressed = false
				_dragging = false


func _on_motion(mm: InputEventMouseMotion) -> void:
	if markup.moving:  # F3 markup: the picked point follows the mouse
		markup.move_to(screen_to_art(mm.position), EDIT_PICK / _zoom)
		show_pick()
		return
	if markup_ui != null and (markup_ui.chain_from != &"" or markup_ui.drafting):  # F3: a line to the mouse
		if markup_ui.chain_from != &"":
			overlay.chain_from = map.node_pos(markup_ui.chain_from)
		overlay.chain_to = screen_to_art(mm.position)
		overlay.queue_redraw()
	if _pressed and not _dragging and mm.position.distance_to(_press_pos) > DRAG_THRESHOLD:
		_dragging = true
		if _jump != null:
			_jump.kill()
	if _dragging:
		_apply(world.position + mm.relative)
		return
	_set_hovered(DistrictMapRules.landmark_at(map, screen_to_art(mm.position)))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_hovered(null)


func _click(p: Vector2) -> void:
	if _markup_on() and markup_ui != null and markup_ui.click(p):  # F3 chain or a new zone's outline
		return
	if _markup_on() and markup.pick(p, EDIT_PICK / _zoom):  # F3 markup: a click on a point picks it
		show_pick()
		return
	var lm := DistrictMapRules.landmark_at(map, p)
	if lm != null:
		landmark_clicked.emit(lm)
	else:
		street_clicked.emit(p)


func _set_hovered(lm: DistrictMapDef.LandmarkDef) -> void:
	if lm == _hovered:
		return
	_hovered = lm
	if overlay != null:
		overlay.set_hovered(lm)
	landmark_hovered.emit(lm)


func _zoom_at(screen_pos: Vector2, new_zoom: float) -> void:
	var z := clampf(new_zoom, _min_zoom(), ZOOM_MAX)
	var anchor := screen_to_art(screen_pos)
	_zoom = z
	world.scale = Vector2(z, z)
	_apply(screen_pos - anchor * z)


## Wheel on at the farthest zoom: counts notches (a pause starts again); the last one asks for the city map.
func _pull_out() -> void:
	var now := Time.get_ticks_msec()
	if now - _pull_ms < PULL_GAP_MS:
		return
	if now - _pull_ms > PULL_RESET_MS:
		_pull = 0
	_pull_ms = now
	_pull = mini(_pull + 1, PULL_TICKS)
	_show_pull(_pull)
	if _pull >= PULL_TICKS:
		_pull = 0
		city_requested.emit()


func _show_pull(ticks: int) -> void:
	if _pull_label == null:
		_pull_label = UiKit.label("", 26, Palette.BRASS_LIGHT)
		_pull_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_pull_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_pull_label.offset_top = -90.0
		_pull_label.add_theme_constant_override("outline_size", 10)
		_pull_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_pull_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_pull_label)
	_pull_label.text = Loc.t("ui.district.pull_city", {"n": ticks, "of": PULL_TICKS})
	_pull_label.modulate.a = 1.0
	if _pull_fade != null:
		_pull_fade.kill()
	_pull_fade = create_tween()
	_pull_fade.tween_interval(PULL_RESET_MS / 1000.0 * 0.6)
	_pull_fade.tween_property(_pull_label, "modulate:a", 0.0, 0.4)


## The art always covers the view: the smallest zoom shows the whole width (or height) of the map.
func _min_zoom() -> float:
	if map == null or size.x <= 0.0:
		return 0.5
	return maxf(size.x / map.image_size.x, size.y / map.image_size.y)


func _apply(pos: Vector2) -> void:
	if map == null:
		return
	if _zoom < _min_zoom():
		_zoom = _min_zoom()
	world.scale = Vector2(_zoom, _zoom)
	world.position = _clamped(pos)


## The middle of the view may go to any point of the district's outline box (owner 2026-10-14: the camera is free),
## so the edges can be centred too; it never goes past the outline, i.e. not into the fog beyond the Ringwall.
func _clamped(pos: Vector2) -> Vector2:
	var box := map.contour_box()
	var half := size * 0.5
	return Vector2(clampf(pos.x, half.x - box.end.x * _zoom, half.x - box.position.x * _zoom),
		clampf(pos.y, half.y - box.end.y * _zoom, half.y - box.position.y * _zoom))


## F3 markup (debug builds): Ctrl + a press anywhere starts moving the picked point (a Ctrl-press on a point picks it
## first), the release drops it. True when the press or release was the markup's.
func _markup_button(mb: InputEventMouseButton) -> bool:
	if not mb.pressed:
		var was := markup.moving
		markup.moving = false
		if was and markup.resident != null and markup_ui != null:
			markup_ui.life_changed.emit()  # the moved resident is built again at his new spot
		elif was and markup.corner != Vector2.INF and markup_ui != null:
			markup_ui.heal_zones(markup.corner_zone())  # the zones close up again around the moved corner
		return was
	if not _markup_on() or not mb.ctrl_pressed:
		return false
	var at := screen_to_art(mb.position)
	markup.pick(at, EDIT_PICK / _zoom)
	if not markup.has_pick():
		return false
	markup.start_move(at)
	show_pick()
	return true


func _markup_on() -> bool:
	return overlay != null and overlay.debug_visible


## The picked point: a ring on the overlay and its name and coordinates in the line over the map.
func show_pick() -> void:
	overlay.queue_redraw()
	if not markup.has_pick():
		overlay.markup_pick = Vector2.INF
		return
	var p := markup.position()
	overlay.markup_pick = p
	set_dev_text(Loc.t("ui.dev.map_point", {"id": markup.label(), "x": p.x, "y": p.y}))


## F3 off: nothing stays picked.
func end_markup() -> void:
	markup.clear()
	overlay.markup_pick = Vector2.INF


## The F3 markup line over the map ("" hides it).
func set_dev_text(text: String) -> void:
	if _dev_label == null:
		_dev_label = UiKit.label("", 18, Palette.PARCHMENT)
		_dev_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)  # top centre: the tracker sits at the left
		_dev_label.offset_top = 12.0
		_dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_dev_label.add_theme_constant_override("outline_size", 6)
		_dev_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_dev_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dev_label)
	_dev_label.text = text
	_dev_label.visible = text != ""
