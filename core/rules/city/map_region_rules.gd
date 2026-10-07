class_name MapRegionRules
extends RefCounted
## Hit-testing on the city map. Points are in source-image pixels (MapRegionsDef.image_size).


## Region under a point, or null. Regions are tested in data order (small enclaves first).
static func region_at(map: MapRegionsDef, point: Vector2) -> MapRegionsDef.Region:
	for r: MapRegionsDef.Region in map.regions:
		if Geometry2D.is_point_in_polygon(point, r.polygon):
			return r
	return null


static func district_at(map: MapRegionsDef, point: Vector2) -> StringName:
	var r := region_at(map, point)
	return r.district if r != null else &""


## Main region of a district (the first one in data order that is not an enclave of another id).
static func home_region(map: MapRegionsDef, district: StringName) -> MapRegionsDef.Region:
	for r: MapRegionsDef.Region in map.regions:
		if r.district == district and r.id == district:
			return r
	for r: MapRegionsDef.Region in map.regions:
		if r.district == district:
			return r
	return null
