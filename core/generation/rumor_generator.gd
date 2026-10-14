class_name RumorGenerator
extends RefCounted
## Makes the rumors the hunter hears while listening to the street (GDD 8.4). A rumor about a creature shows 1–2 of
## its true signs and maybe one lie; a rumor of lies shows only lies, taken from the signs people of that zone talk
## about. Pure: same rng, same rumor.


## A heard rumor: lives on the screen until it is read, taken, thrown away or fades. Never saved.
class Heard:
	var uid: int
	var zone: StringName
	var node: StringName  ## the street node its icon flares up on
	var monster: StringName  ## the creature it is about ("" = lies)
	var contract_uid: int  ## the contract whose creature it is about (0 = a wrong rumor)
	var witness: StringName
	var art: StringName  ## a picture of the zone (RumorDefs.ART_DIR)
	var tags: Array[StringName] = []
	var lies: Array[StringName] = []  ## the shown signs that are not the creature's

	func right() -> bool:
		return contract_uid != 0


## A rumor in `zone`: about the creature of `target` (a contract taken in this zone), or — `target` null — about
## another creature of the district (none of `avoid`) or lies. `used`: street nodes already showing a rumor.
static func make(data: ContentData, district: StringName, zone: StringName, target: ContractsState.Contract,
		avoid: Array[StringName], used: Array[StringName], uid: int, rng: RandomNumberGenerator) -> Heard:
	var h := Heard.new()
	h.uid = uid
	h.zone = zone
	if target != null:
		h.monster = target.monster
		h.contract_uid = target.uid
		_creature_tags(h, data, rng)
		for t: StringName in AffixGenerator.tags(data, target.affixes):  # an affixed creature leaves its affixes' signs
			if not h.tags.has(t):
				h.tags.append(t)
	else:
		var others: Array[StringName] = []
		for id: StringName in EncounterRules.pool(data, district):
			if not avoid.has(id):
				others.append(id)
		if not others.is_empty() and rng.randf() < data.balance.rumors.wrong_creature_chance:
			h.monster = others[rng.randi_range(0, others.size() - 1)]
			_creature_tags(h, data, rng)
		else:
			_lies(h, data, district, rng)
	_dress(h, data, district, used, rng)
	return h


static func all_tags(data: ContentData) -> Array[StringName]:
	var out: Array[StringName] = []
	for t: StringName in data.tags:
		out.append(t)
	return out


## 1–2 true signs of the creature, maybe one lie mixed in.
static func _creature_tags(h: Heard, data: ContentData, rng: RandomNumberGenerator) -> void:
	var b := data.balance.rumors
	var m := data.monster(h.monster)
	h.tags = SeededRng.sample(m.tags, rng.randi_range(b.true_tags_min, b.true_tags_max), rng)
	if rng.randf() < b.noise_chance:
		var noise: Array[StringName] = []
		for t: StringName in all_tags(data):
			if not m.tags.has(t):
				noise.append(t)
		if not noise.is_empty():
			var lie := noise[rng.randi_range(0, noise.size() - 1)]
			h.tags.insert(rng.randi_range(0, h.tags.size()), lie)
			h.lies.append(lie)


## Only lies: the signs people of the zone talk about (any signs when the zone has too few).
static func _lies(h: Heard, data: ContentData, district: StringName, rng: RandomNumberGenerator) -> void:
	var b := data.balance.rumors
	var n := rng.randi_range(b.lie_tags_min, b.lie_tags_max)
	var zd := data.rumor_data.zone(district, h.zone)
	var pool := zd.tags if zd != null and zd.tags.size() >= n else all_tags(data)
	h.lies = SeededRng.sample(pool, n, rng)
	h.tags.assign(h.lies)


## The witness, a picture of the zone and a free street node in it.
static func _dress(h: Heard, data: ContentData, district: StringName, used: Array[StringName],
		rng: RandomNumberGenerator) -> void:
	var witnesses := data.rumor_data.witnesses
	if not witnesses.is_empty():
		h.witness = witnesses[rng.randi_range(0, witnesses.size() - 1)].id
	var zd := data.rumor_data.zone(district, h.zone)
	if zd != null and not zd.art.is_empty():
		h.art = zd.art[rng.randi_range(0, zd.art.size() - 1)]
	var map := data.district_map(district)
	if map != null:
		h.node = free_node(map, h.zone, used, rng)


## A street node in the zone with no rumor or mark and no place on it; &"" when the zone has none free.
static func free_node(map: DistrictMapDef, zone: StringName, used: Array[StringName],
		rng: RandomNumberGenerator) -> StringName:
	var places := {}
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		places[lm.node] = true
	var free: Array[StringName] = []
	for id: StringName in map.nodes:
		if not used.has(id) and not places.has(id) and DistrictMapRules.zone_at(map, map.node_pos(id)) == zone:
			free.append(id)
	return free[rng.randi_range(0, free.size() - 1)] if not free.is_empty() else &""
