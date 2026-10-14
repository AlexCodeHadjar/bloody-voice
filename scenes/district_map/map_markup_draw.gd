class_name MapMarkupDraw
extends RefCounted
## Draws the F3 markup on the district overlay (owner 2026-10-14), layer by layer as the legend's filter allows: zones
## each in their own colour (a light fill, a border, corner squares and the zone's name in the middle), the district
## outline, the open fog side, streets and nodes with their names, places, standing residents, the chain line and
## the picked point.

const ZONE_COLORS: Array[Color] = [Color(0.35, 0.9, 0.35), Color(1.0, 0.6, 0.2), Color(1.0, 0.45, 0.55),
	Color(0.2, 0.8, 0.7), Color(0.8, 0.95, 0.25), Color(0.9, 0.7, 0.4), Color(0.7, 0.6, 1.0), Color(0.5, 1.0, 0.8)]
const CONTOUR := Color.MAGENTA
const FOG := Color(0.35, 0.6, 1.0)
const NODE := Color.RED
const STREET := Color.CYAN
const ROPE := Color(1.0, 0.55, 0.1)
const PLACE := Color.WHITE
const RESIDENT := Color(0.75, 0.45, 1.0)
const PICK := Color.YELLOW
const FILL := 0.22  ## zone fill opacity


static func zone_color(map: DistrictMapDef, id: StringName) -> Color:
	for i: int in map.zones.size():
		if map.zones[i].id == id:
			return ZONE_COLORS[i % ZONE_COLORS.size()]
	return ZONE_COLORS[0]


static func draw(c: CanvasItem, ed: MapMarkupEditor, overlay: DistrictOverlay, font: Font) -> void:
	var map := ed.map
	for z: DistrictMapDef.ZoneDef in map.zones:
		if ed.shown(StringName("zone:" + z.id)):
			_zone(c, z, zone_color(map, z.id), font)
	if ed.shown(&"contour"):
		_outline(c, map.contour, CONTOUR, 4.0)
	if ed.shown(&"fog") and map.fog_side.size() >= 3:
		_outline(c, map.fog_side, FOG, 3.0)
	if ed.shown(&"streets"):
		_streets(c, map, font, ed.shown(&"names"))
	if overlay.chain_from != Vector2.INF:
		c.draw_dashed_line(overlay.chain_from, overlay.chain_to, PICK, 4.0, 18.0)
	if ed.shown(&"places"):
		for lm: DistrictMapDef.LandmarkDef in map.landmarks:
			c.draw_arc(lm.pos, lm.radius, 0.0, TAU, 48, PLACE, 3.0)
			c.draw_string(font, lm.pos, str(lm.number), HORIZONTAL_ALIGNMENT_CENTER, -1, 34, PLACE)
	if ed.shown(&"residents"):
		for r: DistrictLifeDef.ResidentDef in MapMarkupOps.standing(ed.life):
			c.draw_circle(r.pos, 8.0, RESIDENT)
			c.draw_string(font, r.pos + Vector2(12, 18), str(r.id), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, RESIDENT)
	if overlay.markup_pick != Vector2.INF:
		c.draw_arc(overlay.markup_pick, 22.0, 0.0, TAU, 32, PICK, 5.0)


static func _zone(c: CanvasItem, z: DistrictMapDef.ZoneDef, col: Color, font: Font) -> void:
	if z.polygon.size() < 2:
		return
	if not Geometry2D.triangulate_polygon(z.polygon).is_empty():
		c.draw_colored_polygon(z.polygon, Color(col, FILL))
	c.draw_polyline(_closed(z.polygon), col, 4.0)
	for p: Vector2 in z.polygon:
		c.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), col)
	var mid := Vector2.ZERO
	for p: Vector2 in z.polygon:
		mid += p
	mid /= maxf(1.0, z.polygon.size())
	var w := font.get_string_size(z.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 52).x
	c.draw_string_outline(font, mid - Vector2(w * 0.5, 0), z.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, 10, Color(0, 0, 0, 0.85))
	c.draw_string(font, mid - Vector2(w * 0.5, 0), z.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 52, col)


static func _outline(c: CanvasItem, poly: PackedVector2Array, col: Color, width: float) -> void:
	c.draw_polyline(_closed(poly), col, width)
	for p: Vector2 in poly:
		c.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), col, false, 3.0)


static func _streets(c: CanvasItem, map: DistrictMapDef, font: Font, names: bool) -> void:
	for s: DistrictMapDef.StreetDef in map.streets:
		var pts := PackedVector2Array()
		for id: StringName in s.nodes:
			pts.append(map.node_pos(id))
		c.draw_polyline(pts, ROPE if s.kind == &"rope" else STREET, 5.0)
	for id: StringName in map.nodes:
		var p: Vector2 = map.nodes[id]
		c.draw_circle(p, 9.0, NODE)
		if names:
			c.draw_string(font, p + Vector2(12, -8), str(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, PICK)


static func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var out := poly.duplicate()
	if not poly.is_empty():
		out.append(poly[0])
	return out
