class_name DistrictMapValidator
extends RefCounted
## Checks district maps (data/city/district_maps, GDD 20): nodes, street graph, landmarks, zones, sounds.


static func validate(data: ContentData, errs: ErrorLog, check_files: bool = true) -> void:
	for m: DistrictMapDef in data.district_maps.values():
		var w := "district_maps/%s" % m.district
		if not data.districts.has(m.district):
			errs.add(w, "unknown district '%s'" % m.district)
		if check_files and not ResourceLoader.exists(m.image):
			errs.add(w, "missing image %s" % m.image)
		if m.contour.size() < 3:
			errs.add(w, "contour needs at least 3 points")
		for nb: DistrictMapDef.NeighbourDef in m.neighbours:
			if not data.districts.has(nb.district):
				errs.add(w, "unknown neighbour district '%s'" % nb.district)
		_graph(m, errs, w)
		_places(m, errs, w)
		_zones(m, data, errs, w)


static func _graph(m: DistrictMapDef, errs: ErrorLog, w: String) -> void:
	var used := {}
	for s: DistrictMapDef.StreetDef in m.streets:
		for n: StringName in s.nodes:
			used[n] = true
			if not m.nodes.has(n):
				errs.add(w + "/streets/" + s.id, "unknown node '%s'" % n)
	if not m.nodes.has(m.home):
		errs.add(w, "home node '%s' does not exist" % m.home)
		return
	for n: StringName in m.nodes:
		if not used.has(n):
			errs.add(w + "/nodes", "node '%s' is not on any street" % n)
		if m.contour.size() >= 3 and not Geometry2D.is_point_in_polygon(m.nodes[n], m.contour):
			errs.add(w + "/nodes", "node '%s' is outside the contour" % n)
	var seen := {m.home: true}
	var queue: Array[StringName] = [m.home]
	while not queue.is_empty():
		var cur: StringName = queue.pop_back()
		for nxt: StringName in m.adjacency.get(cur, []):
			if not seen.has(nxt):
				seen[nxt] = true
				queue.append(nxt)
	for n: StringName in m.nodes:
		if not seen.has(n):
			errs.add(w + "/nodes", "node '%s' is not connected to home '%s'" % [n, m.home])


static func _places(m: DistrictMapDef, errs: ErrorLog, w: String) -> void:
	var ids := {}
	for l: DistrictMapDef.LandmarkDef in m.landmarks:
		var lw := w + "/landmarks/" + l.id
		if ids.has(l.id):
			errs.add(lw, "duplicate landmark id")
		ids[l.id] = true
		if not m.nodes.has(l.node):
			errs.add(lw, "unknown node '%s'" % l.node)
		if not DistrictMapDef.ACTIONS.has(l.action):
			errs.add(lw, "unknown action '%s'" % l.action)
		if l.radius <= 0.0:
			errs.add(lw, "radius must be > 0")
		if m.contour.size() >= 3 and not _near_contour(m.contour, l.pos, l.radius):
			errs.add(lw, "position is outside the contour")
		var zone_ok := false
		for z: DistrictMapDef.ZoneDef in m.zones:
			zone_ok = zone_ok or z.id == l.zone
		if not zone_ok:
			errs.add(lw, "unknown zone '%s'" % l.zone)


## Landmarks on the border (gates, the wall relief) may sit on the contour line: inside, or within `slack` of it.
static func _near_contour(contour: PackedVector2Array, p: Vector2, slack: float) -> bool:
	if Geometry2D.is_point_in_polygon(p, contour):
		return true
	for i: int in contour.size():
		var q := Geometry2D.get_closest_point_to_segment(p, contour[i], contour[(i + 1) % contour.size()])
		if p.distance_to(q) <= slack:
			return true
	return false


static func _zones(m: DistrictMapDef, data: ContentData, errs: ErrorLog, w: String) -> void:
	for z: DistrictMapDef.ZoneDef in m.zones:
		if z.polygon.size() < 3:
			errs.add(w + "/zones/" + z.id, "polygon needs at least 3 points")
		_ambience(z.ambience, data, errs, w + "/zones/" + z.id)
	for s: DistrictMapDef.SoundSpotDef in m.sound_spots:
		_ambience(s.ambience, data, errs, w + "/sound_spots")
		if s.radius <= 0.0:
			errs.add(w + "/sound_spots", "radius must be > 0")


static func _ambience(id: StringName, data: ContentData, errs: ErrorLog, w: String) -> void:
	if id != &"" and not data.audio.ambience.has(id):
		errs.add(w, "unknown ambience '%s'" % id)
