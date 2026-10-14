class_name ZoneMosaic
extends RefCounted
## F3 markup (owner 2026-10-14): the zones always tile the district — no holes, no overlaps. heal() cuts every zone to
## the district outline, removes overlaps (the zone just edited keeps its shape, the others give way), hands every gap
## to the neighbour that borders it most, and gives places in a vanished or wrong zone the zone they stand in.
## snap() pulls a dragged corner onto a nearby corner or border of another zone so neighbours share borders.

const SLIVER := 400.0  ## art px²: smaller leftovers of clipping are dust, not gaps
const THIN := 3.0  ## art px: a leftover thinner than this on average (a seam from rounding) is not a gap either
const TOUCH := 3.0  ## art px: a gap point this close to a zone's border touches that zone
const GROW := 1.0  ## a gap grows this much before it merges, so the shared border closes


static func heal(map: DistrictMapDef, first: DistrictMapDef.ZoneDef = null) -> void:
	if map.contour.size() < 3 or map.zones.is_empty():
		return
	var order: Array[DistrictMapDef.ZoneDef] = []
	if first != null and map.zones.has(first):
		order.append(first)
	for z: DistrictMapDef.ZoneDef in map.zones:
		if z != first:
			order.append(z)
	_cut(map, order)
	for _round: int in 2:
		_fill_gaps(map, order, first)
		_cut(map, order)
	for z: DistrictMapDef.ZoneDef in map.zones:
		z.polygon = tidy(z.polygon)
	_fix_places(map)


## Each zone inside the outline and outside the zones before it in `order`.
static func _cut(map: DistrictMapDef, order: Array[DistrictMapDef.ZoneDef]) -> void:
	var taken: Array[PackedVector2Array] = []
	for z: DistrictMapDef.ZoneDef in order:
		var poly := largest(Geometry2D.intersect_polygons(z.polygon, map.contour))
		for t: PackedVector2Array in taken:
			if poly.size() < 3:
				break
			poly = largest(Geometry2D.clip_polygons(poly, t))
		if poly.size() >= 3:  # a zone swallowed whole keeps its old shape rather than vanish
			z.polygon = poly
		taken.append(z.polygon)


## A hole left by the zone just edited (`first`) goes to its neighbours, not back to it (or the drag would undo itself).
static func _fill_gaps(map: DistrictMapDef, order: Array[DistrictMapDef.ZoneDef], first: DistrictMapDef.ZoneDef) -> void:
	for gap: PackedVector2Array in gaps(map):
		var others := order.filter(func(z: DistrictMapDef.ZoneDef) -> bool: return z != first)
		var z := _neighbour(gap, others, true)
		if z == null:
			z = _neighbour(gap, order, false)
		if z == null:
			continue
		var grown := largest(Geometry2D.offset_polygon(gap, GROW))
		var merged := largest(Geometry2D.merge_polygons(z.polygon, grown))
		if merged.size() >= 3:
			z.polygon = merged


## The parts of the district outline no zone covers (dust left out).
static func gaps(map: DistrictMapDef) -> Array[PackedVector2Array]:
	var left: Array[PackedVector2Array] = [map.contour]
	for z: DistrictMapDef.ZoneDef in map.zones:
		var next: Array[PackedVector2Array] = []
		for g: PackedVector2Array in left:
			next.append_array(subtract(g, z.polygon))
		left = next
	return left.filter(func(g: PackedVector2Array) -> bool: return absf(area(g)) >= SLIVER and 2.0 * absf(area(g)) / perimeter(g) >= THIN)


## `a` minus `b` as simple shapes. When `b` lies wholly inside `a` the result would be a ring (an outline with a hole,
## which a zone cannot be): `a` is cut in two through `b`'s middle and each half loses its part of `b`.
static func subtract(a: PackedVector2Array, b: PackedVector2Array) -> Array[PackedVector2Array]:
	var res := Geometry2D.clip_polygons(a, b)
	var big := largest(res)
	if res.size() < 2 or not res.any(func(p: PackedVector2Array) -> bool:
			return Geometry2D.is_polygon_clockwise(p) != Geometry2D.is_polygon_clockwise(big)):
		return res
	var x := centre(b).x
	var out: Array[PackedVector2Array] = []
	for half: PackedVector2Array in [PackedVector2Array([Vector2(-1e6, -1e6), Vector2(x, -1e6), Vector2(x, 1e6), Vector2(-1e6, 1e6)]),
			PackedVector2Array([Vector2(x, -1e6), Vector2(1e6, -1e6), Vector2(1e6, 1e6), Vector2(x, 1e6)])]:
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(a, half):
			out.append_array(Geometry2D.clip_polygons(piece, b))
	return out


## The zone whose border the gap touches most (the nearest one when it touches none, unless `touching_only`).
static func _neighbour(gap: PackedVector2Array, order: Array, touching_only: bool) -> DistrictMapDef.ZoneDef:
	var best: DistrictMapDef.ZoneDef = null
	var best_touch := 0
	var best_d := INF
	var mid := centre(gap)
	for z: DistrictMapDef.ZoneDef in order:
		var touch := 0
		for p: Vector2 in gap:
			touch += 1 if border_distance(z.polygon, p) <= TOUCH else 0
		var d := centre(z.polygon).distance_to(mid)
		if touch > best_touch or (touch == best_touch and d < best_d):
			best = z
			best_touch = touch
			best_d = d
	return best if best_touch > 0 or not touching_only else null


## True when `outline` lies wholly inside one zone without reaching its border: a zone cannot hold a hole, so such an
## island would leave the old zone lying under the new one.
static func is_island(map: DistrictMapDef, outline: PackedVector2Array) -> bool:
	for z: DistrictMapDef.ZoneDef in map.zones:
		if outline.size() >= 3 and Array(outline).all(func(p: Vector2) -> bool:
				return Geometry2D.is_point_in_polygon(p, z.polygon) and border_distance(z.polygon, p) > TOUCH):
			return true
	return false


## A place whose zone vanished or who stands in another zone takes the zone it stands in.
static func _fix_places(map: DistrictMapDef) -> void:
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		var here := DistrictMapRules.zone_at(map, lm.pos)
		if here != &"" and (map.zone(lm.zone) == null or not Geometry2D.is_point_in_polygon(lm.pos, map.zone(lm.zone).polygon)):
			lm.zone = here
		elif map.zone(lm.zone) == null and not map.zones.is_empty():
			lm.zone = map.zones[0].id


## Pulls `p` onto a corner (first) or a border of the shapes within `radius`, skipping the points in `skip`.
static func snap(map: DistrictMapDef, p: Vector2, radius: float, skip: PackedVector2Array) -> Vector2:
	var best := p
	var best_d := radius
	var polys: Array[PackedVector2Array] = [map.contour]
	for z: DistrictMapDef.ZoneDef in map.zones:
		polys.append(z.polygon)
	for poly: PackedVector2Array in polys:
		for q: Vector2 in poly:
			if not skip.has(q) and q.distance_to(p) < best_d:
				best = q
				best_d = q.distance_to(p)
	if best != p:
		return best
	for poly: PackedVector2Array in polys:
		for i: int in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if skip.has(a) or skip.has(b):
				continue
			var q := Geometry2D.get_closest_point_to_segment(p, a, b)
			if q.distance_to(p) < best_d:
				best = q.round()
				best_d = q.distance_to(p)
	return best


## Whole pixels, no repeated points, no points sitting on a straight line between their neighbours.
static func tidy(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in poly:
		var r := p.round()
		if out.is_empty() or out[-1].distance_to(r) > 1.5:
			out.append(r)
	if out.size() > 3 and out[0].distance_to(out[-1]) <= 1.5:
		out.remove_at(out.size() - 1)
	var i := 0
	while i < out.size() and out.size() > 3:
		var a := out[(i - 1 + out.size()) % out.size()]
		var c := out[(i + 1) % out.size()]
		if Geometry2D.get_closest_point_to_segment(out[i], a, c).distance_to(out[i]) < 0.75:
			out.remove_at(i)
		else:
			i += 1
	return out


static func largest(polys: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	for p: PackedVector2Array in polys:
		if absf(area(p)) > absf(area(best)):
			best = p
	return best


static func area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i: int in poly.size():
		s += poly[i].cross(poly[(i + 1) % poly.size()])
	return s * 0.5


static func perimeter(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i: int in poly.size():
		s += poly[i].distance_to(poly[(i + 1) % poly.size()])
	return maxf(s, 0.001)


static func centre(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p: Vector2 in poly:
		sum += p
	return sum / maxf(1.0, poly.size())


static func border_distance(poly: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i: int in poly.size():
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()]).distance_to(p))
	return best
