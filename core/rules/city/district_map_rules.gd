class_name DistrictMapRules
extends RefCounted
## Walking on a district map (GDD 20): shortest street paths, spots on the streets, routes, and what lies under a point
## (landmark, zone, ambience). Pure static functions over a DistrictMapDef.


## A point on the street graph: on the edge a-b, or exactly at node a when a == b.
class Spot:
	var point: Vector2
	var a: StringName
	var b: StringName


static func spot_at_node(map: DistrictMapDef, node: StringName) -> Spot:
	var s := Spot.new()
	s.point = map.node_pos(node)
	s.a = node
	s.b = node
	return s


## Closest point on any street edge within max_dist of p; null if none.
static func nearest_spot(map: DistrictMapDef, p: Vector2, max_dist: float) -> Spot:
	var best: Spot = null
	var best_d := max_dist
	for a: StringName in map.adjacency:
		for b: StringName in map.adjacency[a]:
			if String(a) > String(b):
				continue  # each edge once
			var pa := map.node_pos(a)
			var pb := map.node_pos(b)
			var q := Geometry2D.get_closest_point_to_segment(p, pa, pb)
			var d := p.distance_to(q)
			if d <= best_d:
				best_d = d
				best = Spot.new()
				best.point = q
				best.a = a
				best.b = b
				if q.is_equal_approx(pa):
					best.b = a
				elif q.is_equal_approx(pb):
					best.a = b
	return best


static func shortest_path(map: DistrictMapDef, from_node: StringName, to_node: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if not map.nodes.has(from_node) or not map.nodes.has(to_node):
		return out
	if from_node == to_node:
		out.append(from_node)
		return out
	var dist: Dictionary[StringName, float] = {from_node: 0.0}
	var prev: Dictionary[StringName, StringName] = {}
	var open: Array[StringName] = [from_node]
	var done := {}
	while not open.is_empty():
		var cur := open[0]
		for n: StringName in open:
			if dist[n] < dist[cur]:
				cur = n
		open.erase(cur)
		if cur == to_node:
			break
		done[cur] = true
		for nxt: StringName in map.adjacency.get(cur, []):
			var nd := dist[cur] + map.node_pos(cur).distance_to(map.node_pos(nxt))
			if not done.has(nxt) and nd < dist.get(nxt, INF):
				dist[nxt] = nd
				prev[nxt] = cur
				if not open.has(nxt):
					open.append(nxt)
	if not dist.has(to_node):
		return out
	var at := to_node
	out.append(at)
	while at != from_node:
		at = prev[at]
		out.push_front(at)
	return out


## The polyline to walk from one spot to another (starts at from.point, ends at to.point).
static func route(map: DistrictMapDef, from: Spot, to: Spot) -> PackedVector2Array:
	var best := PackedVector2Array([from.point, to.point])
	if _same_edge(from, to):
		return best
	var best_len := INF
	for start: StringName in _ends(from):
		for finish: StringName in _ends(to):
			var path := shortest_path(map, start, finish)
			if path.is_empty():
				continue
			var line := PackedVector2Array([from.point])
			for n: StringName in path:
				_add_point(line, map.node_pos(n))
			_add_point(line, to.point)
			var total := _length(line)
			if total < best_len:
				best_len = total
				best = line
	return best


## The closer end of the spot's edge (what is saved as "where the hero stands").
static func nearest_node(map: DistrictMapDef, spot: Spot) -> StringName:
	if spot.point.distance_to(map.node_pos(spot.a)) <= spot.point.distance_to(map.node_pos(spot.b)):
		return spot.a
	return spot.b


static func landmark_at(map: DistrictMapDef, p: Vector2) -> DistrictMapDef.LandmarkDef:
	var best: DistrictMapDef.LandmarkDef = null
	var best_d := INF
	for l: DistrictMapDef.LandmarkDef in map.landmarks:
		var d := p.distance_to(l.pos)
		if d <= l.radius and d < best_d:
			best_d = d
			best = l
	return best


## First zone (file order) whose polygon contains p; "" if none.
static func zone_at(map: DistrictMapDef, p: Vector2) -> StringName:
	for z: DistrictMapDef.ZoneDef in map.zones:
		if Geometry2D.is_point_in_polygon(p, z.polygon):
			return z.id
	return &""


## A sound spot around p wins over the zone's own ambience; "" = nothing special.
static func ambience_at(map: DistrictMapDef, p: Vector2) -> StringName:
	for s: DistrictMapDef.SoundSpotDef in map.sound_spots:
		if p.distance_to(s.pos) <= s.radius:
			return s.ambience
	for z: DistrictMapDef.ZoneDef in map.zones:
		if Geometry2D.is_point_in_polygon(p, z.polygon):
			return z.ambience
	return &""


static func inside(map: DistrictMapDef, p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, map.contour)


static func _add_point(line: PackedVector2Array, p: Vector2) -> void:
	if line.is_empty() or not line[line.size() - 1].is_equal_approx(p):
		line.append(p)


static func _ends(s: Spot) -> Array[StringName]:
	var out: Array[StringName] = [s.a]
	if s.b != s.a:
		out.append(s.b)
	return out


static func _same_edge(x: Spot, y: Spot) -> bool:
	var xs := _ends(x)
	var ys := _ends(y)
	if xs.size() == 2 and ys.size() == 2:
		return xs.has(ys[0]) and xs.has(ys[1])
	if xs.size() == 2:
		return xs.has(ys[0])  # y is at a node of x's edge
	if ys.size() == 2:
		return ys.has(xs[0])
	return xs[0] == ys[0]


static func _length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i: int in range(1, line.size()):
		total += line[i - 1].distance_to(line[i])
	return total
