class_name DistrictOverlay
extends Node2D
## Drawn over the district art (GDD 20.2): the veil over the locked neighbours (70 % black with diagonal hatching,
## owner 2026-10-12) with «<name> — закрыто» labels, the brass outline of the landmark under the mouse and, in debug
## builds (F3), the calibration overlay: street graph, landmark spots, zones and the contour (GDD 20.9 step 6b).
## flash_zone() makes a zone glow for a moment: where a contract's creature was last seen (GDD 7.1).

const VEIL := Color(0.0, 0.0, 0.0, 0.7)
const HATCH := Color(0.55, 0.5, 0.45, 0.22)
const HATCH_STEP := 46.0
const LABEL_SIZE := 64
const RING := Color(0.85, 0.7, 0.4, 0.95)
const RING_FILL := Color(1.0, 0.85, 0.5, 0.10)
const FLASH := Color(0.55, 0.75, 1.0)  ## the blue glow of a contract's region
const FLASH_IN := 0.35
const FLASH_HOLD := 1.2
const FLASH_OUT := 2.0

var debug_visible := false
var markup_pick := Vector2.INF  ## F3 markup: the picked point (INF = none)

var _map: DistrictMapDef
var _veil: PackedVector2Array  ## the whole art with the district cut out (one "keyhole" polygon)
var _hatch: Array[PackedVector2Array] = []
var _labels: Array[Array] = []  ## [[pos: Vector2, text: String], ...]
var _hovered: DistrictMapDef.LandmarkDef = null
var _font: Font
var _flash := PackedVector2Array()
var _flash_tween: Tween
var flash_alpha := 0.0:
	set(v):
		flash_alpha = v
		queue_redraw()


func setup(map: DistrictMapDef) -> void:
	_map = map
	_font = UiKit.heading_font()
	_veil = _keyhole(map.contour, map.image_size)
	_hatch = _hatch_lines(map.contour, map.image_size)
	for n: DistrictMapDef.NeighbourDef in map.neighbours:
		var d := ContentDB.data.district(n.district)
		var name := d.name if d != null else str(n.district)
		_labels.append([n.label, Loc.t("ui.district.closed_label", {"name": name})])
	queue_redraw()


func set_hovered(lm: DistrictMapDef.LandmarkDef) -> void:
	_hovered = lm
	queue_redraw()


## Glows the zone's outline in, holds and fades out. Returns the zone's centre (art px), or the art centre if unknown.
func flash_zone(zone: StringName) -> Vector2:
	_flash = PackedVector2Array()
	for z: DistrictMapDef.ZoneDef in _map.zones:
		if z.id == zone:
			_flash = z.polygon
	if _flash.is_empty():
		return _map.image_size * 0.5
	if _flash_tween != null:
		_flash_tween.kill()
	flash_alpha = 0.0
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "flash_alpha", 1.0, FLASH_IN)
	_flash_tween.tween_interval(FLASH_HOLD)
	_flash_tween.tween_property(self, "flash_alpha", 0.0, FLASH_OUT)
	var sum := Vector2.ZERO
	for p: Vector2 in _flash:
		sum += p
	return sum / _flash.size()


func toggle_debug() -> void:
	debug_visible = not debug_visible
	queue_redraw()


func _draw() -> void:
	if _map == null:
		return
	if not Geometry2D.triangulate_polygon(_veil).is_empty():
		draw_colored_polygon(_veil, VEIL)
	for line: PackedVector2Array in _hatch:
		draw_line(line[0], line[1], HATCH, 3.0)
	for l: Array in _labels:
		_draw_label(l[0] as Vector2, l[1] as String)
	if flash_alpha > 0.0 and not _flash.is_empty():
		_draw_flash()
	if _hovered != null:
		draw_circle(_hovered.pos, _hovered.radius, RING_FILL)
		draw_arc(_hovered.pos, _hovered.radius, 0.0, TAU, 64, RING, 5.0, true)
	if debug_visible:
		_draw_debug()


func _draw_flash() -> void:
	if not Geometry2D.triangulate_polygon(_flash).is_empty():
		draw_colored_polygon(_flash, Color(FLASH, 0.16 * flash_alpha))
	var outline := _closed(_flash)
	draw_polyline(outline, Color(FLASH, 0.25 * flash_alpha), 26.0, true)
	draw_polyline(outline, Color(FLASH, 0.95 * flash_alpha), 7.0, true)


func _draw_label(pos: Vector2, text: String) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var at := pos - Vector2(w * 0.5, 0.0)
	at.x = clampf(at.x, 30.0, maxf(30.0, _map.image_size.x - w - 30.0))  # never cut by the edge of the art
	draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, 10, Color(0, 0, 0, 0.9))
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, Palette.FOG)


## Calibration view: streets (by kind), nodes with ids, landmark circles with numbers, zones and the contour.
func _draw_debug() -> void:
	var font := UiKit.serif()
	draw_polyline(_closed(_map.contour), Color.MAGENTA, 4.0)
	for z: DistrictMapDef.ZoneDef in _map.zones:
		draw_polyline(_closed(z.polygon), Color(0.4, 1.0, 0.4, 0.8), 2.0)
	for s: DistrictMapDef.StreetDef in _map.streets:
		var pts := PackedVector2Array()
		for id: StringName in s.nodes:
			pts.append(_map.node_pos(id))
		draw_polyline(pts, Color(1.0, 0.55, 0.1) if s.kind == &"rope" else Color.CYAN, 5.0)
	for id: StringName in _map.nodes:
		var p: Vector2 = _map.nodes[id]
		draw_circle(p, 9.0, Color.RED)
		draw_string(font, p + Vector2(12, -8), str(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.YELLOW)
	for lm: DistrictMapDef.LandmarkDef in _map.landmarks:
		draw_arc(lm.pos, lm.radius, 0.0, TAU, 48, Color.WHITE, 3.0)
		draw_string(font, lm.pos, str(lm.number), HORIZONTAL_ALIGNMENT_CENTER, -1, 34, Color.WHITE)
	for z: DistrictMapDef.ZoneDef in _map.zones:
		for p: Vector2 in z.polygon:
			draw_rect(Rect2(p - Vector2(6, 6), Vector2(12, 12)), Color(0.4, 1.0, 0.4))
	if markup_pick != Vector2.INF:
		draw_arc(markup_pick, 22.0, 0.0, TAU, 32, Color.YELLOW, 5.0)


static func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var out := poly.duplicate()
	if not poly.is_empty():
		out.append(poly[0])
	return out


## One simple polygon = the art rectangle with the contour cut out: walk the rectangle, step in to the contour point
## nearest to the top-left corner, walk the contour the other way round and step back out ("keyhole").
static func _keyhole(contour: PackedVector2Array, art: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2.ZERO, Vector2(art.x, 0), art, Vector2(0, art.y), Vector2.ZERO])
	var hole := contour.duplicate()
	if Geometry2D.is_polygon_clockwise(hole) == Geometry2D.is_polygon_clockwise(out.slice(0, 4)):
		hole.reverse()  # the hole must run the other way round than the rectangle
	var start := 0
	for i: int in hole.size():
		if hole[i].length_squared() < hole[start].length_squared():
			start = i
	for i: int in hole.size() + 1:
		out.append(hole[(start + i) % hole.size()])
	return out


## Diagonal hatching lines, cut where they cross into the district.
static func _hatch_lines(contour: PackedVector2Array, art: Vector2) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var c := -art.y
	while c < art.x:
		var line := PackedVector2Array([Vector2(c, 0.0), Vector2(c + art.y, art.y)])
		for part: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(line, contour):
			out.append(part)
		c += HATCH_STEP
	return out
