class_name MapMarkupOps
extends RefCounted
## F3 markup (debug builds, owner 2026-10-14): what the right-click menu does to the loaded district map and life —
## street nodes, links (streets), places, zone / outline / fog corners and standing residents. Works on the live
## defs (the screen redraws them at once); MapMarkupSaver writes them into the data files on Ctrl+S.
## Functions that can refuse return the reason ("" = done).

const NEW_KIND := &"street"  ## the kind of a link the owner draws
const PLACE_RADIUS := 140.0
const SINGLE_PLACES: Array[StringName] = [&"rest", &"workshop", &"rumors", &"tavern", &"shop", &"infirmary", &"library"]


## A polygon of the map: a zone, the district outline ("contour") or the open fog side ("fog").
class PolyRef:
	var map: DistrictMapDef
	var which: StringName
	var zone: DistrictMapDef.ZoneDef

	func points() -> PackedVector2Array:
		if which == &"contour":
			return map.contour
		if which == &"fog":
			return map.fog_side
		return zone.polygon

	func set_points(p: PackedVector2Array) -> void:
		if which == &"contour":
			map.contour = p
		elif which == &"fog":
			map.fog_side = p
		else:
			zone.polygon = p


static func polygons(map: DistrictMapDef, which: StringName = &"") -> Array[PolyRef]:
	var out: Array[PolyRef] = []
	for kind: StringName in [&"zone", &"contour", &"fog"]:
		if which != &"" and which != kind:
			continue
		var zones: Array = [null]
		if kind == &"zone":
			zones.assign(map.zones)
		for z: Variant in zones:
			var r := PolyRef.new()
			r.map = map
			r.which = kind
			r.zone = z as DistrictMapDef.ZoneDef
			out.append(r)
	return out


static func unique_id(prefix: String, taken: Callable) -> StringName:
	var n := 1
	while taken.call(StringName("%s_%d" % [prefix, n])):
		n += 1
	return StringName("%s_%d" % [prefix, n])


static func add_node(map: DistrictMapDef, p: Vector2) -> StringName:
	var id := unique_id("node", func(x: StringName) -> bool: return map.nodes.has(x))
	map.nodes[id] = p.round()
	map.rebuild_adjacency()
	return id


## Links `a` to `b`: extends `street` when it ends at `a` (a chain), else starts a new street. Returns the street.
static func link(map: DistrictMapDef, street: DistrictMapDef.StreetDef, a: StringName, b: StringName) -> DistrictMapDef.StreetDef:
	if a == b or (map.adjacency.get(a, []) as Array).has(b):
		return street
	if street == null or street.nodes.is_empty() or street.nodes[-1] != a:
		street = DistrictMapDef.StreetDef.new()
		street.id = unique_id("path", func(x: StringName) -> bool: return map.streets.any(func(s: DistrictMapDef.StreetDef) -> bool: return s.id == x))
		street.name = Loc.t("ui.dev.path_name", {"id": street.id})
		street.kind = NEW_KIND
		street.nodes = [a]
		map.streets.append(street)
	street.nodes.append(b)
	map.rebuild_adjacency()
	return street


## Removes the link between two neighbouring nodes: every street through it splits in two there.
static func unlink(map: DistrictMapDef, a: StringName, b: StringName) -> void:
	var out: Array[DistrictMapDef.StreetDef] = []
	for s: DistrictMapDef.StreetDef in map.streets:
		var cut := -1
		for i: int in range(1, s.nodes.size()):
			if (s.nodes[i - 1] == a and s.nodes[i] == b) or (s.nodes[i - 1] == b and s.nodes[i] == a):
				cut = i
		if cut < 0:
			out.append(s)
			continue
		_keep_part(map, out, s, s.nodes.slice(0, cut), s.id)
		_keep_part(map, out, s, s.nodes.slice(cut), &"")
	map.streets = out
	map.rebuild_adjacency()


static func _keep_part(map: DistrictMapDef, out: Array[DistrictMapDef.StreetDef], s: DistrictMapDef.StreetDef,
		part: Array[StringName], id: StringName) -> void:
	if part.size() < 2:
		return
	var p := DistrictMapDef.StreetDef.new()
	p.id = id if id != &"" else unique_id(str(s.id), func(x: StringName) -> bool: return out.any(func(o: DistrictMapDef.StreetDef) -> bool: return o.id == x) or map.streets.any(func(o: DistrictMapDef.StreetDef) -> bool: return o.id == x))
	p.name = s.name
	p.kind = s.kind
	p.nodes = part
	out.append(p)


static func delete_node(map: DistrictMapDef, life: DistrictLifeDef, id: StringName) -> String:
	if id == map.home:
		return Loc.t("ui.dev.no_delete_home")
	if life != null:
		for r: DistrictLifeDef.ResidentDef in life.residents:
			if r.mode == &"wander" and r.nodes.has(id) and r.nodes.size() <= 2:
				return Loc.t("ui.dev.no_delete_walker", {"id": r.id})
	for other: StringName in (map.adjacency.get(id, []) as Array).duplicate():
		unlink(map, id, other)
	map.streets = map.streets.filter(func(s: DistrictMapDef.StreetDef) -> bool: return not s.nodes.has(id))
	map.nodes.erase(id)
	map.adjacency.erase(id)
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		if lm.node == id:
			lm.node = nearest_node(map, lm.pos)
	if life != null:
		for r: DistrictLifeDef.ResidentDef in life.residents:
			r.nodes.erase(id)
	map.rebuild_adjacency()
	return ""


static func rename_node(map: DistrictMapDef, life: DistrictLifeDef, old: StringName, to: StringName) -> String:
	var problem := check_id(to, map.nodes.has(to))
	if problem != "":
		return problem
	var nodes: Dictionary[StringName, Vector2] = {}
	for id: StringName in map.nodes:
		nodes[to if id == old else id] = map.nodes[id]
	map.nodes = nodes
	for s: DistrictMapDef.StreetDef in map.streets:
		for i: int in s.nodes.size():
			if s.nodes[i] == old:
				s.nodes[i] = to
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		if lm.node == old:
			lm.node = to
	if map.home == old:
		map.home = to
	if life != null:
		for r: DistrictLifeDef.ResidentDef in life.residents:
			for i: int in r.nodes.size():
				if r.nodes[i] == old:
					r.nodes[i] = to
	map.rebuild_adjacency()
	return ""


static func check_id(id: StringName, taken: bool) -> String:
	if RegEx.create_from_string("^[a-z][a-z0-9_]*$").search(str(id)) == null:
		return Loc.t("ui.dev.bad_id")
	return Loc.t("ui.dev.id_taken") if taken else ""


static func nearest_node(map: DistrictMapDef, p: Vector2) -> StringName:
	var best := &""
	for id: StringName in map.nodes:
		if best == &"" or map.nodes[id].distance_squared_to(p) < map.nodes[best].distance_squared_to(p):
			best = id
	return best


static func add_place(map: DistrictMapDef, p: Vector2, action: StringName) -> DistrictMapDef.LandmarkDef:
	var lm := DistrictMapDef.LandmarkDef.new()
	lm.id = unique_id("place", func(x: StringName) -> bool: return map.landmark(x) != null)
	lm.number = 1
	for other: DistrictMapDef.LandmarkDef in map.landmarks:
		lm.number = maxi(lm.number, other.number + 1)
	lm.name = Loc.t("ui.dev.place_name", {"n": lm.number})
	lm.pos = p.round()
	lm.node = nearest_node(map, p)
	lm.radius = PLACE_RADIUS
	lm.action = action
	lm.zone = map.zones[0].id if not map.zones.is_empty() else &""
	for z: DistrictMapDef.ZoneDef in map.zones:
		if Geometry2D.is_point_in_polygon(p, z.polygon):
			lm.zone = z.id
	map.landmarks.append(lm)
	return lm


static func delete_place(map: DistrictMapDef, lm: DistrictMapDef.LandmarkDef) -> String:
	if SINGLE_PLACES.has(lm.action) and map.landmarks.filter(func(o: DistrictMapDef.LandmarkDef) -> bool: return o.action == lm.action).size() <= 1:
		return Loc.t("ui.dev.no_delete_place")
	map.landmarks.erase(lm)
	return ""


## Adds a corner on the nearest edge of a `which` polygon (zone, contour or fog); every polygon sharing that edge
## gets it too, so neighbours stay closed.
static func add_corner(map: DistrictMapDef, which: StringName, p: Vector2) -> void:
	var best_d := INF
	var edge: Array[Vector2] = []
	for r: PolyRef in polygons(map, which):
		var pts := r.points()
		for i: int in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			var d := Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)
			if d < best_d:
				best_d = d
				edge = [a, b]
	if edge.is_empty():
		return
	for r: PolyRef in polygons(map):
		var pts := r.points()
		for i: int in pts.size():
			var a := pts[i]
			var b := pts[(i + 1) % pts.size()]
			if (a == edge[0] and b == edge[1]) or (a == edge[1] and b == edge[0]):
				pts.insert(i + 1, p.round())
				r.set_points(pts)
				break


## Removes a corner at `at` from every polygon that has it; refuses when a polygon would keep fewer than 3.
static func delete_corner(map: DistrictMapDef, at: Vector2) -> String:
	for r: PolyRef in polygons(map):
		if r.points().has(at) and r.points().size() <= 3:
			return Loc.t("ui.dev.no_delete_corner")
	for r: PolyRef in polygons(map):
		var pts := r.points()
		var i := pts.find(at)
		if i >= 0:
			pts.remove_at(i)
			r.set_points(pts)
	return ""


## Residents that stand or work in one spot: the ones a «Точка жителя» can copy.
static func standing(life: DistrictLifeDef) -> Array[DistrictLifeDef.ResidentDef]:
	var out: Array[DistrictLifeDef.ResidentDef] = []
	if life != null:
		for r: DistrictLifeDef.ResidentDef in life.residents:
			if r.mode == &"stand" or r.mode == &"work":
				out.append(r)
	return out


static func add_resident(life: DistrictLifeDef, source: DistrictLifeDef.ResidentDef, p: Vector2) -> DistrictLifeDef.ResidentDef:
	var r := DistrictLifeDef.ResidentDef.new()
	for prop: Dictionary in source.get_property_list():
		if (prop["usage"] as int) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			r.set(prop["name"] as StringName, source.get(prop["name"] as StringName))
	r.nodes = source.nodes.duplicate()
	r.id = unique_id(str(source.id), func(x: StringName) -> bool: return life.residents.any(func(o: DistrictLifeDef.ResidentDef) -> bool: return o.id == x))
	r.pos = p.round()
	life.residents.append(r)
	return r


static func rename_resident(life: DistrictLifeDef, r: DistrictLifeDef.ResidentDef, to: StringName) -> String:
	var problem := check_id(to, life.residents.any(func(o: DistrictLifeDef.ResidentDef) -> bool: return o.id == to))
	if problem == "":
		r.id = to
	return problem
