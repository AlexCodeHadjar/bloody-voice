class_name RumorDefs
extends RefCounted
## Rumor content (GDD 8): witnesses, tavern gossip and per-zone pictures and tags (data/rumors/rumors.json), and the rumor numbers
## of balance.json.

const ART_DIR := "res://art/ui/RUMOR__art__%s.webp"


class Witness:
	var id: StringName
	var text: String


class ZoneDef:
	var art: Array[StringName] = []
	var tags: Array[StringName] = []


class Data:
	var witnesses: Array[Witness] = []
	var gossip: Array[Witness] = []  ## tavern-shift gossip lines (same shape: id + text)
	var zones: Dictionary[StringName, Dictionary] = {}  ## district -> {zone id: ZoneDef}

	func zone(district: StringName, zone_id: StringName) -> ZoneDef:
		return (zones.get(district, {}) as Dictionary).get(zone_id) as ZoneDef


## The "rumors" block of balance.json (GDD 8.4).
class Balance:
	var listen_every_min: float = 4.0  ## seconds between rumors while listening
	var listen_every_max: float = 6.0
	var max_heard: int = 3  ## rumors on the map at once (+ the district state's rumor_bonus)
	var heard_seconds: float = 20.0  ## an unread rumor fades after this
	var true_chance: float = 0.5  ## in a zone with a taken contract: the rumor is about its creature
	var wrong_creature_chance: float = 0.5  ## otherwise: about another creature of the district, else lies
	var true_tags_min: int = 1
	var true_tags_max: int = 2
	var noise_chance: float = 0.0  ## a creature rumor gets one lie mixed in
	var lie_tags_min: int = 1
	var lie_tags_max: int = 3
	var trail_needed: int = 3  ## right rumors taken -> the creature's mark
	var threat_needed: int = 3  ## wrong rumors taken in a zone -> a red threat mark
	var threat_days: int = 3


static func from_dict(d: Dictionary, errs: ErrorLog) -> Data:
	var x := Data.new()
	var w := "rumors/rumors.json"
	for v: Variant in DefReader.array(d, "witnesses", errs, w):
		var wit := Witness.new()
		wit.id = DefReader.id(v as Dictionary, "id", errs, w + "/witnesses")
		wit.text = DefReader.string(v as Dictionary, "text", errs, w + "/witnesses/" + wit.id)
		x.witnesses.append(wit)
	for v: Variant in DefReader.array(d, "gossip", errs, w):
		var g := Witness.new()
		g.id = DefReader.id(v as Dictionary, "id", errs, w + "/gossip")
		g.text = DefReader.string(v as Dictionary, "text", errs, w + "/gossip/" + g.id)
		x.gossip.append(g)
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
	for key: String in ["max_heard", "true_tags_min", "true_tags_max", "lie_tags_min", "lie_tags_max", "trail_needed",
			"threat_needed", "threat_days"]:
		b.set(key, DefReader.integer(d, key, errs, w))
	for key: String in ["listen_every_min", "listen_every_max", "heard_seconds", "true_chance", "wrong_creature_chance",
			"noise_chance"]:
		b.set(key, DefReader.number(d, key, errs, w))
	return b
