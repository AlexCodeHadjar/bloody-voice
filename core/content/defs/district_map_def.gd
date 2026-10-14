class_name DistrictMapDef
extends RefCounted
## Walkable map of one district (data/city/district_maps/<ID>.json, GDD 20): border contour, street graph of nodes,
## landmarks, sound zones. Coordinates are pixels of the map image (image_size).

const KINDS: Array[StringName] = [&"main", &"street", &"alley", &"rope"]
const ACTIONS: Array[StringName] = [&"rest", &"workshop", &"tavern", &"shop", &"infirmary", &"library", &"locked",
	&"soon"]


class LandmarkDef:
	var id: StringName
	var number: int
	var name: String  ## English working name; ContentLoc puts the Russian one
	var desc: String  ## tooltip line, comes from the locale table
	var zone: StringName
	var pos: Vector2
	var node: StringName  ## street node the hero walks to
	var radius: float
	var action: StringName


class StreetDef:
	var id: StringName
	var name: String
	var kind: StringName
	var nodes: Array[StringName] = []


class ZoneDef:
	var id: StringName
	var name: String  ## English default = id; ContentLoc puts the Russian one
	var ambience: StringName  ## "" = the screen's own ambience
	var polygon: PackedVector2Array


class SoundSpotDef:
	var ambience: StringName
	var pos: Vector2
	var radius: float


class NeighbourDef:
	var district: StringName
	var label: Vector2


var district: StringName
var image: String
var image_size: Vector2 = Vector2.ONE
var home: StringName
var contour: PackedVector2Array
var fog_side: PackedVector2Array  ## outside the contour but open fog (beyond the Ringwall): no veil there; optional
var neighbours: Array[NeighbourDef] = []
var zones: Array[ZoneDef] = []
var sound_spots: Array[SoundSpotDef] = []
var nodes: Dictionary[StringName, Vector2] = {}
var streets: Array[StreetDef] = []
var landmarks: Array[LandmarkDef] = []
var adjacency: Dictionary[StringName, Array] = {}  ## node -> neighbouring nodes (streets join both ways)


static func from_dict(d: Dictionary, errs: ErrorLog, where: String) -> DistrictMapDef:
	var x := DistrictMapDef.new()
	x.district = DefReader.id(d, "district", errs, where)
	x.image = DefReader.string(d, "image", errs, where)
	x.image_size = _point(DefReader.array(d, "image_size", errs, where), errs, where + "/image_size", Vector2.ONE)
	x.home = DefReader.id(d, "home", errs, where)
	x.contour = _polygon(DefReader.array(d, "contour", errs, where), errs, where + "/contour")
	x.fog_side = _polygon(DefReader.array(d, "fog_side", errs, where, false), errs, where + "/fog_side")
	for n: Variant in DefReader.array(d, "neighbours", errs, where):
		var nd := _object(n, errs, where + "/neighbours")
		var nb := NeighbourDef.new()
		nb.district = DefReader.id(nd, "district", errs, where + "/neighbours")
		nb.label = _point(DefReader.array(nd, "label", errs, where + "/neighbours"), errs, where + "/neighbours", Vector2.ZERO)
		x.neighbours.append(nb)
	for z: Variant in DefReader.array(d, "zones", errs, where):
		x.zones.append(_zone(_object(z, errs, where + "/zones"), errs, where))
	for s: Variant in DefReader.array(d, "sound_spots", errs, where, false):
		var sd := _object(s, errs, where + "/sound_spots")
		var spot := SoundSpotDef.new()
		spot.ambience = DefReader.id(sd, "ambience", errs, where + "/sound_spots")
		spot.pos = _point(DefReader.array(sd, "pos", errs, where + "/sound_spots"), errs, where + "/sound_spots", Vector2.ZERO)
		spot.radius = DefReader.number(sd, "radius", errs, where + "/sound_spots")
		x.sound_spots.append(spot)
	var nodes := DefReader.dict(d, "nodes", errs, where)
	for key: Variant in nodes:
		if not str(key).begins_with("_"):
			var id := StringName(str(key))
			x.nodes[id] = _point(nodes[key] as Array if typeof(nodes[key]) == TYPE_ARRAY else [], errs, where + "/nodes/" + id, Vector2.ZERO)
	for s: Variant in DefReader.array(d, "streets", errs, where):
		x.streets.append(_street(_object(s, errs, where + "/streets"), errs, where))
	for l: Variant in DefReader.array(d, "landmarks", errs, where):
		x.landmarks.append(_landmark(_object(l, errs, where + "/landmarks"), errs, where))
	x._build_adjacency()
	return x


func landmark(id: StringName) -> LandmarkDef:
	for l: LandmarkDef in landmarks:
		if l.id == id:
			return l
	return null


func zone(id: StringName) -> ZoneDef:
	for z: ZoneDef in zones:
		if z.id == id:
			return z
	return null


## The bounding box of the district outline (art px): how far the camera's middle may go.
func contour_box() -> Rect2:
	var box := Rect2(contour[0], Vector2.ZERO) if not contour.is_empty() else Rect2(Vector2.ZERO, image_size)
	for p: Vector2 in contour:
		box = box.expand(p)
	return box


func node_pos(id: StringName) -> Vector2:
	return nodes.get(id, Vector2.ZERO)


func has_node_id(id: StringName) -> bool:
	return nodes.has(id)


## After the F3 markup changed nodes or streets.
func rebuild_adjacency() -> void:
	adjacency.clear()
	_build_adjacency()


func _build_adjacency() -> void:
	for id: StringName in nodes:
		adjacency[id] = []
	for s: StreetDef in streets:
		for i: int in range(1, s.nodes.size()):
			var a: StringName = s.nodes[i - 1]
			var b: StringName = s.nodes[i]
			if a == b or not nodes.has(a) or not nodes.has(b):
				continue
			if not adjacency[a].has(b):
				adjacency[a].append(b)
			if not adjacency[b].has(a):
				adjacency[b].append(a)


static func _zone(zd: Dictionary, errs: ErrorLog, where: String) -> ZoneDef:
	var z := ZoneDef.new()
	z.id = DefReader.id(zd, "id", errs, where + "/zones")
	z.name = String(z.id)
	z.ambience = DefReader.id(zd, "ambience", errs, where + "/zones/" + z.id, false)
	z.polygon = _polygon(DefReader.array(zd, "polygon", errs, where + "/zones/" + z.id), errs, where + "/zones/" + z.id)
	return z


static func _street(sd: Dictionary, errs: ErrorLog, where: String) -> StreetDef:
	var s := StreetDef.new()
	s.id = DefReader.id(sd, "id", errs, where + "/streets")
	var w := where + "/streets/" + s.id
	s.name = DefReader.string(sd, "name", errs, w)
	s.kind = DefReader.id(sd, "kind", errs, w)
	if not KINDS.has(s.kind):
		errs.add(w, "unknown kind '%s'" % s.kind)
	s.nodes = DefReader.ids(sd, "nodes", errs, w)
	if s.nodes.size() < 2:
		errs.add(w, "a street needs at least 2 nodes")
	return s


static func _landmark(ld: Dictionary, errs: ErrorLog, where: String) -> LandmarkDef:
	var l := LandmarkDef.new()
	l.id = DefReader.id(ld, "id", errs, where + "/landmarks")
	var w := where + "/landmarks/" + l.id
	l.number = DefReader.integer(ld, "number", errs, w)
	l.name = DefReader.string(ld, "name", errs, w)
	l.desc = DefReader.string(ld, "desc", errs, w, false)
	l.zone = DefReader.id(ld, "zone", errs, w)
	l.pos = _point(DefReader.array(ld, "pos", errs, w), errs, w, Vector2.ZERO)
	l.node = DefReader.id(ld, "node", errs, w)
	l.radius = DefReader.number(ld, "radius", errs, w)
	l.action = DefReader.id(ld, "action", errs, w)
	return l


static func _object(v: Variant, errs: ErrorLog, where: String) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY:
		errs.add(where, "every entry must be an object")
		return {}
	return v


static func _point(a: Array, errs: ErrorLog, where: String, default: Vector2) -> Vector2:
	if a.size() != 2 or not _is_num(a[0]) or not _is_num(a[1]):
		errs.add(where, "a point must be [x, y]")
		return default
	return Vector2(float(a[0]), float(a[1]))


static func _polygon(a: Array, errs: ErrorLog, where: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in a:
		out.append(_point(p as Array if typeof(p) == TYPE_ARRAY else [], errs, where, Vector2.ZERO))
	return out


static func _is_num(v: Variant) -> bool:
	return typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT
