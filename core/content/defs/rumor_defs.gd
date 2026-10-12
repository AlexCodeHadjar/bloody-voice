class_name RumorDefs
extends RefCounted
## Rumor content (GDD 8): witnesses and per-zone pictures and tags (data/rumors/rumors.json), and the rumor numbers
## of balance.json.

const KINDS: Array[StringName] = [&"target", &"wrong_monster", &"discovery", &"false_lead", &"empty_night"]
const FIGHTS: Array[StringName] = [&"target", &"wrong_monster"]  ## outcomes that start a fight
const ART_DIR := "res://art/ui/RUMOR__art__%s.webp"


class Witness:
	var id: StringName
	var text: String


class ZoneDef:
	var art: Array[StringName] = []
	var tags: Array[StringName] = []


class Data:
	var witnesses: Array[Witness] = []
	var zones: Dictionary[StringName, Dictionary] = {}  ## district -> {zone id: ZoneDef}

	func zone(district: StringName, zone_id: StringName) -> ZoneDef:
		return (zones.get(district, {}) as Dictionary).get(zone_id) as ZoneDef


## The "rumors" block of balance.json.
class Balance:
	var new_min: int = 1
	var new_max: int = 2
	var max_on_map: int = 5
	var lifetime_days: int = 3
	var true_every_min: int = 2
	var true_every_max: int = 3
	var kind_weights: Dictionary[StringName, float] = {}
	var true_tags_min: int = 1
	var true_tags_max: int = 2
	var noise_chance: float = 0.0
	var lie_tags_min: int = 1
	var lie_tags_max: int = 3
	var zone_tag_weight: float = 1.0
	var discovery_money_min: int = 0
	var discovery_money_max: int = 0
	var small_money_min: int = 0
	var small_money_max: int = 0
	var discovery_resources: Dictionary[StringName, Vector2i] = {}  ## resource -> [min, max]
	var empty_night_resources: Dictionary[StringName, Vector2i] = {}


static func from_dict(d: Dictionary, errs: ErrorLog) -> Data:
	var x := Data.new()
	var w := "rumors/rumors.json"
	for v: Variant in DefReader.array(d, "witnesses", errs, w):
		var wit := Witness.new()
		wit.id = DefReader.id(v as Dictionary, "id", errs, w + "/witnesses")
		wit.text = DefReader.string(v as Dictionary, "text", errs, w + "/witnesses/" + wit.id)
		x.witnesses.append(wit)
	var districts := DefReader.dict(d, "zones", errs, w)
	for district: Variant in districts:
		var zones: Dictionary = {}
		for zone_id: Variant in districts[district] as Dictionary:
			var zd := ((districts[district] as Dictionary)[zone_id]) as Dictionary
			var z := ZoneDef.new()
			z.art = DefReader.ids(zd, "art", errs, "%s/zones/%s/%s" % [w, district, zone_id])
			z.tags = DefReader.ids(zd, "tags", errs, "%s/zones/%s/%s" % [w, district, zone_id])
			zones[StringName(str(zone_id))] = z
		x.zones[StringName(str(district))] = zones
	return x


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/rumors"
	for key: String in ["new_min", "new_max", "max_on_map", "lifetime_days", "true_every_min", "true_every_max",
			"true_tags_min", "true_tags_max", "lie_tags_min", "lie_tags_max", "discovery_money_min",
			"discovery_money_max", "small_money_min", "small_money_max"]:
		b.set(key, DefReader.integer(d, key, errs, w))
	b.noise_chance = DefReader.number(d, "noise_chance", errs, w)
	b.zone_tag_weight = DefReader.number(d, "zone_tag_weight", errs, w, 1.0)
	var weights := DefReader.dict(d, "kind_weights", errs, w)
	for k: Variant in weights:
		b.kind_weights[StringName(str(k))] = float(weights[k])
	b.discovery_resources = _ranges(DefReader.dict(d, "discovery_resources", errs, w), errs, w)
	b.empty_night_resources = _ranges(DefReader.dict(d, "empty_night_resources", errs, w), errs, w)
	return b


static func _ranges(d: Dictionary, errs: ErrorLog, w: String) -> Dictionary[StringName, Vector2i]:
	var out: Dictionary[StringName, Vector2i] = {}
	for k: Variant in d:
		var a: Variant = d[k]
		if typeof(a) != TYPE_ARRAY or (a as Array).size() != 2:
			errs.add(w, "'%s' must be [min, max]" % k)
			continue
		out[StringName(str(k))] = Vector2i(int((a as Array)[0]), int((a as Array)[1]))
	return out
