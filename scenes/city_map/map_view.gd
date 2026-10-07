class_name MapView
extends Control
## Draws the city map art, highlights the district under the mouse and shows the hero figure.
## Knows nothing about rules: it reports clicks and is told where the hero stands.

signal district_hovered(district: StringName)
signal district_clicked(district: StringName)

const FIGURE := "res://art/ui/HERO__figurine__front.webp"
const FIGURE_HEIGHT := 120.0
const HOVER_FILL := Color(1.0, 0.85, 0.5, 0.16)
const HOVER_LINE := Color(0.85, 0.7, 0.4, 0.95)
const HERO_LINE := Color(0.45, 0.65, 1.0, 0.75)

var _map: MapRegionsDef
var _texture: Texture2D
var _figure: Texture2D
var _draw_rect := Rect2()
var _screen_polys: Dictionary[StringName, PackedVector2Array] = {}  # region id -> screen points
var _fillable: Dictionary[StringName, bool] = {}
var _hovered: StringName = &""
var _hero_district: StringName = &""
var _time := 0.0


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
	if event is InputEventMouseMotion:
		var d := MapRegionRules.district_at(_map, _to_image((event as InputEventMouseMotion).position))
		if d != _hovered:
			_hovered = d
			district_hovered.emit(d)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _hovered != &"":
			district_clicked.emit(_hovered)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hovered != &"":
		_hovered = &""
		district_hovered.emit(&"")


func _draw() -> void:
	if _texture != null:
		draw_texture_rect(_texture, _draw_rect, false)
	for r: MapRegionsDef.Region in _map.regions if _map != null else []:
		if r.district == _hovered:
			_draw_region(r.id, HOVER_FILL, HOVER_LINE, 3.0)
		elif r.district == _hero_district:
			_draw_region(r.id, Color(0, 0, 0, 0), HERO_LINE, 2.0)
	_draw_figure()


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
