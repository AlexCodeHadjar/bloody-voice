class_name MapRegionsDef
extends RefCounted
## Clickable district regions traced over the city map art (data/city/map_regions.json).
## Coordinates are in pixels of the source image (image_size).

class Region:
	var id: StringName
	var district: StringName
	var polygon: PackedVector2Array
	var center: Vector2  ## where the hero figure stands ("anchor" in data, else the centroid)


var image: String
var image_size: Vector2
var regions: Array[Region] = []


static func from_dict(d: Dictionary, errs: ErrorLog) -> MapRegionsDef:
	var x := MapRegionsDef.new()
	var w := "map_regions.json"
	x.image = DefReader.string(d, "image", errs, w)
	var size := DefReader.array(d, "image_size", errs, w)
	x.image_size = Vector2(float(size[0]), float(size[1])) if size.size() == 2 else Vector2.ONE
	for r: Variant in DefReader.array(d, "regions", errs, w):
		var rd: Dictionary = r
		var region := Region.new()
		region.id = DefReader.id(rd, "id", errs, w)
		region.district = DefReader.id(rd, "district", errs, w + "/" + region.id)
		for p: Variant in DefReader.array(rd, "polygon", errs, w + "/" + region.id):
			var pt: Array = p
			region.polygon.append(Vector2(float(pt[0]), float(pt[1])))
		var anchor := DefReader.array(rd, "anchor", errs, w + "/" + region.id, false)
		region.center = Vector2(float(anchor[0]), float(anchor[1])) if anchor.size() == 2 else _centroid(region.polygon)
		x.regions.append(region)
	return x


static func _centroid(poly: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for p: Vector2 in poly:
		sum += p
	return sum / maxf(1.0, poly.size())
