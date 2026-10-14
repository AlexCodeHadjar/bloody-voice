class_name MapView
extends Control
## Draws the city map art, highlights the district under the mouse and shows the hero figure.
## Knows nothing about rules: it reports clicks and is told where the hero stands.

signal district_hovered(district: StringName)
signal district_clicked(district: StringName)
signal zoomed_in  ## the wheel towards the player: back down to the district (owner 2026-10-14)

const FIGURE := "res://art/ui/HERO__figurine__front.webp"
const FIGURE_HEIGHT := 120.0
const HOVER_FILL := Color(1.0, 0.85, 0.5, 0.16)
const HOVER_LINE := Color(0.85, 0.7, 0.4, 0.95)
const LOCKED_FILL := Color(0, 0, 0, 0.6)
const HERO_LINE := Color(0.45, 0.65, 1.0, 0.75)

var _map: MapRegionsDef
var _texture: Texture2D
var _figure: Texture2D
var _draw_rect := Rect2()
var _screen_polys: Dictionary[StringName, PackedVector2Array] = {}  # region id -> screen points
var _fillable: Dictionary[StringName, bool] = {}
var _hovered: StringName = &""
var _hero_district: StringName = &""
var _locked: Array[StringName] = []  # district ids drawn dark
var _time := 0.0
var markup: RegionMarkup = null  ## F3 (debug builds): the districts' borders on the city map (set by the screen)
var markup_text := ""  ## the F3 line at the top
var _markup_menu: PopupMenu = null


func setup(map: MapRegionsDef) -> void:
	_map = map
	_texture = UiKit.texture(map.image)
	_figure = UiKit.texture(FIGURE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_relayout)
	_relayout()


func set_hero_district(district: StringName) -> void:
	_hero_district = district
	queue_redraw()


func set_locked(districts: Array[StringName]) -> void:
	_locked = districts
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta  # figure idle bob: cheap redraw of one control
	queue_redraw()


func _relayout() -> void:
	if _map == null:
		return
	var s := minf(size.x / _map.image_size.x, size.y / _map.image_size.y)
	var draw_size := _map.image_size * s
	_draw_rect = Rect2((size - draw_size) * 0.5, draw_size)
	_screen_polys.clear()
	_fillable.clear()
	for r: MapRegionsDef.Region in _map.regions:
		var pts := PackedVector2Array()
		for p: Vector2 in r.polygon:
			pts.append(_to_screen(p))
		_screen_polys[r.id] = pts
		_fillable[r.id] = not Geometry2D.triangulate_polygon(pts).is_empty()
	queue_redraw()


func _to_screen(p: Vector2) -> Vector2:
	return _draw_rect.position + p * (_draw_rect.size / _map.image_size)


## Image pixel -> global (viewport) position. Used by tools such as auto-screenshots.
func image_to_global(p: Vector2) -> Vector2:
	return get_global_transform() * _to_screen(p)


func _to_image(p: Vector2) -> Vector2:
	return (p - _draw_rect.position) * (_map.image_size / _draw_rect.size)


func _gui_input(event: InputEvent) -> void:
	if _map == null:
		return
	if markup != null and markup.on:
		_markup_input(event)
		return
	if event is InputEventMouseMotion:
		var d := MapRegionRules.district_at(_map, _to_image((event as InputEventMouseMotion).position))
		if d != _hovered:
			_hovered = d
			district_hovered.emit(d)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _hovered != &"":
			district_clicked.emit(_hovered)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomed_in.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hovered != &"":
		_hovered = &""
		district_hovered.emit(&"")


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, _draw_rect, false)
	for r: MapRegionsDef.Region in _map.regions if _map != null else []:
		if _locked.has(r.district):
			_draw_locked(r)
		if r.district == _hovered:
			_draw_region(r.id, HOVER_FILL, HOVER_LINE, 3.0)
		elif r.district == _hero_district:
			_draw_region(r.id, Color(0, 0, 0, 0), HERO_LINE, 2.0)
	_draw_figure()
	if markup != null and markup.on:
		markup.draw(self, _to_screen)
		draw_string_outline(get_theme_default_font(), Vector2(16, 28), markup_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 18, 6, Color(0, 0, 0, 0.9))
		draw_string(get_theme_default_font(), Vector2(16, 28), markup_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 32, 18, Palette.PARCHMENT)


func _draw_locked(r: MapRegionsDef.Region) -> void:
	var pts: PackedVector2Array = _screen_polys[r.id]
	if _fillable[r.id]:
		draw_colored_polygon(pts, LOCKED_FILL)
	var font := get_theme_default_font()
	var text := Loc.t("ui.district.locked_short")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(font, _to_screen(r.center) - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.FOG)


func _draw_region(region_id: StringName, fill: Color, line: Color, width: float) -> void:
	var pts: PackedVector2Array = _screen_polys[region_id]
	if fill.a > 0.0 and _fillable[region_id]:
		draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, line, width, true)


func _draw_figure() -> void:
	if _figure == null or _map == null:
		return
	var region := MapRegionRules.home_region(_map, _hero_district)
	if region == null:
		return
	var foot := _to_screen(region.center)
	var h := FIGURE_HEIGHT * (_draw_rect.size.y / 1000.0)
	var bob := sin(_time * 2.0) * 2.0
	draw_circle(foot, h * 0.28, Color(0.35, 0.6, 1.0, 0.18 + 0.06 * sin(_time * 2.0)))
	draw_texture_rect(_figure, Rect2(foot - Vector2(h * 0.5, h - 4.0 + bob), Vector2(h, h)), false)


## F3: a click picks a corner or a figure point, Ctrl + the held button moves it, right click adds / deletes a corner.
func _markup_input(event: InputEvent) -> void:
	var px_per_screen := _map.image_size.x / _draw_rect.size.x  # image px per screen px
	var mm := event as InputEventMouseMotion
	if mm != null and markup.moving:
		markup.move_to(_to_image(mm.position))
		markup_text = "%s: %d, %d" % [markup.label(), markup.picked().x, markup.picked().y]
		_relayout()
		return
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		markup.moving = false
	elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		var found := markup.pick(_to_image(mb.position), RegionMarkup.PICK * px_per_screen)
		if mb.ctrl_pressed and markup.has_pick():
			markup.start_move(_to_image(mb.position))
		if found:
			markup_text = "%s: %d, %d" % [markup.label(), markup.picked().x, markup.picked().y]
	elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		_open_markup_menu(_to_image(mb.position))
	queue_redraw()


func _open_markup_menu(at: Vector2) -> void:
	if _markup_menu == null:
		_markup_menu = PopupMenu.new()
		add_child(_markup_menu)
	for c: Dictionary in _markup_menu.id_pressed.get_connections():
		_markup_menu.id_pressed.disconnect(c["callable"] as Callable)
	_markup_menu.clear()
	_markup_menu.add_item(Loc.t("ui.dev.region_add_corner"), 1)
	if markup.has_pick():
		_markup_menu.add_item(Loc.t("ui.dev.menu_delete"), 2)
	_markup_menu.id_pressed.connect(func(id: int) -> void:
		if id == 1:
			markup.add_corner(at)
		else:
			var problem := markup.delete_corner()
			if problem != "":
				markup_text = problem
		_relayout())
	_markup_menu.reset_size()
	_markup_menu.popup(Rect2i(Vector2i(get_viewport().get_mouse_position()), Vector2i.ZERO))
