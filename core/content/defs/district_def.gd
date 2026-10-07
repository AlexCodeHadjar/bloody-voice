class_name DistrictDef
extends RefCounted
## One district of the Upper City (data/city/districts.json, GDD 13.5).

var id: StringName
var symbol: String
var name: String
var district_class: String
var size: String
var controller: String
var danger: String
var look: String
var area_ids: Array[StringName] = []
var area_names: Dictionary[StringName, String] = {}
var landmarks: String
var monsters: String
var rumor_tags: String
var role: String
var mood: String


static func from_dict(d: Dictionary, errs: ErrorLog) -> DistrictDef:
	var x := DistrictDef.new()
	x.id = DefReader.id(d, "id", errs, "districts.json")
	var w := "districts.json/%s" % x.id
	x.symbol = DefReader.string(d, "symbol", errs, w)
	x.name = DefReader.string(d, "name", errs, w)
	x.district_class = DefReader.string(d, "class", errs, w)
	x.size = DefReader.string(d, "size", errs, w, false)
	x.controller = DefReader.string(d, "controller", errs, w)
	x.danger = DefReader.string(d, "danger", errs, w)
	x.look = DefReader.string(d, "look", errs, w)
	x.landmarks = DefReader.string(d, "landmarks", errs, w, false)
	x.monsters = DefReader.string(d, "monsters", errs, w, false)
	x.rumor_tags = DefReader.string(d, "rumor_tags", errs, w, false)
	x.role = DefReader.string(d, "role", errs, w, false)
	x.mood = DefReader.string(d, "mood", errs, w, false)
	for a: Variant in DefReader.array(d, "areas", errs, w):
		if typeof(a) != TYPE_DICTIONARY:
			errs.add(w, "area must be an object")
			continue
		var area: Dictionary = a
		var area_id := DefReader.id(area, "id", errs, w + "/areas")
		x.area_ids.append(area_id)
		x.area_names[area_id] = DefReader.string(area, "name", errs, w + "/areas")
	return x


## Art path for this district: kind = "tile" | "scene", state = district state art suffix.
func art_path(kind: String, state: String = "normal") -> String:
	return "res://art/city/districts/%s__%s__%s.webp" % [id, kind, state]
