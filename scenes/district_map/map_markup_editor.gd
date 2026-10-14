class_name MapMarkupEditor
extends RefCounted
## Debug builds only (F3 on the district map, owner 2026-10-12/14): a click picks a street node, a place, a standing
## resident or a corner (zone, district outline, open fog); Ctrl + the held left button anywhere on the map moves the
## picked point with the mouse (no jump). A corner shared by several polygons moves in all of them, so neighbouring
## zones and the outline stay closed. MapMarkupOps changes the structure, MapMarkupSaver writes it (Ctrl+S).

var map: DistrictMapDef
var life: DistrictLifeDef
var node: StringName = &""
var landmark: DistrictMapDef.LandmarkDef = null
var resident: DistrictLifeDef.ResidentDef = null
var corner := Vector2.INF  ## the picked corner's position (INF = none)
var _corners: Array = []  ## [PolyRef, index] pairs at the picked corner
var _offset := Vector2.ZERO  ## the picked point minus the art point under the mouse when the move started
var moving := false
var renamed_residents: Dictionary[StringName, StringName] = {}  ## new id -> id in the file (for the saver)
var copied_residents: Dictionary[StringName, StringName] = {}  ## new resident -> the one it was copied from
var named_places: Dictionary[StringName, bool] = {}  ## places whose Russian name the saver writes to the table
var layers: Dictionary[StringName, bool] = {}  ## the legend filter: streets, names, places, residents, contour, fog, zone:<id> (missing = shown)


func _init(district_map: DistrictMapDef, district_life: DistrictLifeDef) -> void:
	map = district_map
	life = district_life


func shown(layer: StringName) -> bool:
	return layers.get(layer, true)


func has_pick() -> bool:
	return node != &"" or landmark != null or resident != null or corner != Vector2.INF


func clear() -> void:
	node = &""
	landmark = null
	resident = null
	corner = Vector2.INF
	_corners = []
	moving = false


## Picks the shown point within `radius` art px of `p`: nodes, places, residents, then corners. False if none.
func pick(p: Vector2, radius: float) -> bool:
	for id: StringName in (map.nodes if shown(&"streets") else {}):
		if map.nodes[id].distance_to(p) <= radius:
			clear()
			node = id
			return true
	for lm: DistrictMapDef.LandmarkDef in (map.landmarks if shown(&"places") else []):
		if lm.pos.distance_to(p) <= radius:
			clear()
			landmark = lm
			return true
	for r: DistrictLifeDef.ResidentDef in (MapMarkupOps.standing(life) if shown(&"residents") else []):
		if r.pos.distance_to(p) <= radius:
			clear()
			resident = r
			return true
	for poly: MapMarkupOps.PolyRef in MapMarkupOps.polygons(map):
		if not shown(poly_layer(poly)):
			continue
		for q: Vector2 in poly.points():
			if q.distance_to(p) <= radius:
				pick_corner(q)
				return true
	return false


static func poly_layer(poly: MapMarkupOps.PolyRef) -> StringName:
	return StringName("zone:" + poly.zone.id) if poly.zone != null else poly.which


func pick_corner(at: Vector2) -> void:
	clear()
	corner = at
	for poly: MapMarkupOps.PolyRef in MapMarkupOps.polygons(map):
		var pts := poly.points()
		for j: int in pts.size():
			if pts[j].distance_to(at) < 0.5:
				_corners.append([poly, j])


func position() -> Vector2:
	if node != &"":
		return map.nodes[node]
	if landmark != null:
		return landmark.pos
	if resident != null:
		return resident.pos
	return corner


## What the line over the map shows: the point's name and its coordinates.
func label() -> String:
	if node != &"":
		return str(node)
	if landmark != null:
		return "%s (%s)" % [landmark.name, landmark.id]
	if resident != null:
		return str(resident.id)
	var names := PackedStringArray()
	for c: Array in _corners:
		var poly := c[0] as MapMarkupOps.PolyRef
		names.append("%s #%d" % [poly.zone.id if poly.zone != null else poly.which, c[1] as int])
	return ", ".join(names)


func start_move(mouse_art: Vector2) -> void:
	moving = true
	_offset = position() - mouse_art


## Moves the picked point after the mouse; returns its new position.
func move_to(mouse_art: Vector2) -> Vector2:
	var p := (mouse_art + _offset).round()
	if node != &"":
		map.nodes[node] = p
	elif landmark != null:
		landmark.pos = p
	elif resident != null:
		resident.pos = p
	else:
		for c: Array in _corners:
			var poly := c[0] as MapMarkupOps.PolyRef
			var pts := poly.points()
			pts[c[1] as int] = p
			poly.set_points(pts)
		corner = p
	return p


## The id the resident has in the file (before any renames this session).
func file_id(r: DistrictLifeDef.ResidentDef) -> StringName:
	return renamed_residents.get(r.id, r.id)


## Keeps the saver's books when a resident's id changes.
func note_rename(old: StringName, to: StringName) -> void:
	if copied_residents.has(old):
		copied_residents[to] = copied_residents[old]
		copied_residents.erase(old)
		return
	renamed_residents[to] = renamed_residents.get(old, old)
	renamed_residents.erase(old)
