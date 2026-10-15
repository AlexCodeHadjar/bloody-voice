class_name RumorGenerator
extends RefCounted
## Makes the rumor cards of the notebook (GDD 8.4). A rumor about a creature shows 1–2 of its true signs and maybe one
## lie; a rumor of lies shows only lies, taken from the signs people of that zone talk about. Pure: same rng, same card.


## A card about `zone`: about the creature of `target` (a contract), or — `target` null — about another creature of the
## district (none of `avoid`) or lies.
static func make(data: ContentData, district: StringName, zone: StringName, target: ContractsState.Contract,
		avoid: Array[StringName], uid: int, day: int, rng: RandomNumberGenerator) -> RumorsState.Card:
	var c := RumorsState.Card.new()
	c.uid = uid
	c.day = day
	c.zone = zone
	if target != null:
		c.monster = target.monster
		c.contract_uid = target.uid
		_creature_tags(c, data, rng)
		for t: StringName in AffixGenerator.tags(data, target.affixes):  # an affixed creature leaves its affixes' signs
			if not c.tags.has(t):
				c.tags.append(t)
	else:
		var others: Array[StringName] = []
		for id: StringName in EncounterRules.pool(data, district):
			if not avoid.has(id):
				others.append(id)
		if not others.is_empty() and rng.randf() < data.balance.rumors.wrong_creature_chance:
			c.monster = others[rng.randi_range(0, others.size() - 1)]
			_creature_tags(c, data, rng)
		else:
			_lies(c, data, district, rng)
	var witnesses := data.rumor_data.witnesses
	if not witnesses.is_empty():
		c.witness = witnesses[rng.randi_range(0, witnesses.size() - 1)].id
	var zd := data.rumor_data.zone(district, zone)
	if zd != null and not zd.art.is_empty():
		c.art = zd.art[rng.randi_range(0, zd.art.size() - 1)]
	return c


static func all_tags(data: ContentData) -> Array[StringName]:
	var out: Array[StringName] = []
	for t: StringName in data.tags:
		out.append(t)
	return out


## 1–2 true signs of the creature, maybe one lie mixed in.
static func _creature_tags(c: RumorsState.Card, data: ContentData, rng: RandomNumberGenerator) -> void:
	var b := data.balance.rumors
	var m := data.monster(c.monster)
	c.tags = SeededRng.sample(m.tags, rng.randi_range(b.true_tags_min, b.true_tags_max), rng)
	if rng.randf() < b.noise_chance:
		var noise: Array[StringName] = []
		for t: StringName in all_tags(data):
			if not m.tags.has(t):
				noise.append(t)
		if not noise.is_empty():
			var lie := noise[rng.randi_range(0, noise.size() - 1)]
			c.tags.insert(rng.randi_range(0, c.tags.size()), lie)
			c.lies.append(lie)


## Only lies: the signs people of the zone talk about (any signs when the zone has too few).
static func _lies(c: RumorsState.Card, data: ContentData, district: StringName, rng: RandomNumberGenerator) -> void:
	var b := data.balance.rumors
	var n := rng.randi_range(b.lie_tags_min, b.lie_tags_max)
	var zd := data.rumor_data.zone(district, c.zone)
	var pool := zd.tags if zd != null and zd.tags.size() >= n else all_tags(data)
	c.lies = SeededRng.sample(pool, n, rng)
	c.tags.assign(c.lies)


## A street node in the zone with no lair and no place on it; &"" when the zone has none free.
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
