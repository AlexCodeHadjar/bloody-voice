class_name DistrictView
extends Control
## The district map in a camera (GDD 20.3): drag with the held left button, zoom with the wheel, clicks on landmarks
## and streets. Everything inside `world` is in art pixels. Knows no rules: it only reports what was clicked.

signal landmark_hovered(landmark: DistrictMapDef.LandmarkDef)  ## null when the mouse leaves every landmark
signal landmark_clicked(landmark: DistrictMapDef.LandmarkDef)
signal street_clicked(point: Vector2)  ## art pixels
signal hero_double_clicked

const DRAG_THRESHOLD := 6.0  ## px of mouse travel before a press becomes a drag (GDD 20.3)
const ZOOM_MAX := 1.25
const ZOOM_STEP := 1.12
const START_ZOOM := 0.8
const FOLLOW_SPEED := 5.0  ## how fast the camera catches up with the walking hero
const JUMP_TIME := 0.45
const HERO_PICK_RADIUS := 70.0  ## art px around the hero's feet that count as "the hero" for a double-click

var map: DistrictMapDef
var world := Node2D.new()
var overlay: DistrictOverlay
var follow: Node2D = null  ## the camera keeps this in the centre while it moves, unless the player drags

var _zoom := START_ZOOM
var _pressed := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _hovered: DistrictMapDef.LandmarkDef = null
var _jump: Tween = null


func setup(district_map: DistrictMapDef) -> void:
	map = district_map
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
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


func _process(delta: float) -> void:
	if follow == null or _dragging or (_jump != null and _jump.is_running()):
		return
	var target := _clamped(size * 0.5 - follow.position * _zoom)
	if world.position.distance_squared_to(target) > 1.0:
		_apply(world.position.lerp(target, minf(1.0, delta * FOLLOW_SPEED)))


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
			_zoom_at(mb.position, _zoom * ZOOM_STEP)
		MOUSE_BUTTON_WHEEL_DOWN when mb.pressed:
			_zoom_at(mb.position, _zoom / ZOOM_STEP)
		MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressed = true
				_dragging = false
				_press_pos = mb.position
				if mb.double_click and follow != null \
						and screen_to_art(mb.position).distance_to(follow.position) < HERO_PICK_RADIUS:
					hero_double_clicked.emit()
			else:
				if _pressed and not _dragging:
					_click(screen_to_art(mb.position))
				_pressed = false
				_dragging = false


func _on_motion(mm: InputEventMouseMotion) -> void:
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


func _clamped(pos: Vector2) -> Vector2:
	var art := map.image_size * _zoom
	return Vector2(clampf(pos.x, minf(0.0, size.x - art.x), 0.0), clampf(pos.y, minf(0.0, size.y - art.y), 0.0))
