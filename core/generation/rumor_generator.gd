class_name RumorGenerator
extends RefCounted
## Makes rumor diamonds (GDD 17.2 RumorGenerator v1, 17.3). A rumor about a creature shows 1–2 of its true tags and
## maybe one noise tag; rumors without a creature show only lies. Creature rumors land more often in zones whose
## tags fit the creature. The outcome and its money are fixed here (OutcomeResolver). Pure: same rng, same rumor.


## A true rumor seeded by a taken contract: investigating it means the fight with the contract's creature.
static func make_target(data: ContentData, district: StringName, c: ContractsState.Contract, day: int,
		rng: RandomNumberGenerator, uid: int, used_nodes: Array[StringName]) -> RumorsState.Rumor:
	var r := _base(data, uid, day, rng)
	r.kind = &"target"
	r.monster = c.monster
	r.contract_uid = c.uid
	_creature_tags(r, data, rng)
	return _place(r, data, district, rng, used_nodes)


## A rumor with a non-target outcome: another creature, a discovery, a false lead or an empty night.
## `avoid`: creatures not to pick as the «wrong» one (the targets of open contracts).
static func make_random(data: ContentData, district: StringName, day: int, rng: RandomNumberGenerator, uid: int,
		used_nodes: Array[StringName], avoid: Array[StringName]) -> RumorsState.Rumor:
	var b := data.balance.rumors
	var r := _base(data, uid, day, rng)
	r.kind = SeededRng.weighted(b.kind_weights, rng)
	var others: Array[StringName] = []
	for id: StringName in EncounterRules.pool(data, district):
		if not avoid.has(id):
			others.append(id)
	if r.kind == &"wrong_monster" and others.is_empty():
		r.kind = &"false_lead"
	if r.kind == &"wrong_monster":
		r.monster = others[rng.randi_range(0, others.size() - 1)]
		_creature_tags(r, data, rng)
	else:
		r.lies = SeededRng.sample(all_tags(data), rng.randi_range(b.lie_tags_min, b.lie_tags_max), rng)
		r.tags.assign(r.lies)
		var discovery := r.kind == &"discovery"
		r.money = rng.randi_range(b.discovery_money_min if discovery else b.small_money_min,
			b.discovery_money_max if discovery else b.small_money_max)
	return _place(r, data, district, rng, used_nodes)


static func all_tags(data: ContentData) -> Array[StringName]:
	var out: Array[StringName] = []
	for t: StringName in data.tags:
		out.append(t)
	return out


static func _base(data: ContentData, uid: int, day: int, rng: RandomNumberGenerator) -> RumorsState.Rumor:
	var r := RumorsState.Rumor.new()
	r.uid = uid
	r.day = day
	r.expires_day = day + data.balance.rumors.lifetime_days
	var witnesses := data.rumor_data.witnesses
	if not witnesses.is_empty():
		r.witness = witnesses[rng.randi_range(0, witnesses.size() - 1)].id
	return r


## 1–2 true tags of the creature, maybe one noise tag (a lie mixed in).
static func _creature_tags(r: RumorsState.Rumor, data: ContentData, rng: RandomNumberGenerator) -> void:
	var b := data.balance.rumors
	var m := data.monster(r.monster)
	r.tags = SeededRng.sample(m.tags, rng.randi_range(b.true_tags_min, b.true_tags_max), rng)
	if rng.randf() < b.noise_chance:
		var noise: Array[StringName] = []
		for t: StringName in all_tags(data):
			if not m.tags.has(t):
				noise.append(t)
		if not noise.is_empty():
			var lie := noise[rng.randi_range(0, noise.size() - 1)]
			r.tags.insert(rng.randi_range(0, r.tags.size()), lie)
			r.lies.append(lie)


## Zone (weighted by the creature's tags), a free street node inside it and a picture of the zone.
static func _place(r: RumorsState.Rumor, data: ContentData, district: StringName, rng: RandomNumberGenerator,
		used_nodes: Array[StringName]) -> RumorsState.Rumor:
	var map := data.district_map(district)
	if map == null or map.zones.is_empty():
		return null
	var m := data.monster(r.monster)
	var weights: Dictionary[StringName, float] = {}
	for z: DistrictMapDef.ZoneDef in map.zones:
		var zd := data.rumor_data.zone(district, z.id)
		var fit := 0
		if m != null and zd != null:
			for t: StringName in m.tags:
				fit += 1 if zd.tags.has(t) else 0
		weights[z.id] = 1.0 + data.balance.rumors.zone_tag_weight * fit
	r.zone = SeededRng.weighted(weights, rng)
	r.node = _free_node(map, r.zone, rng, used_nodes)
	var actual := DistrictMapRules.zone_at(map, map.node_pos(r.node))
	if actual != &"":
		r.zone = actual  # the zone was full and the diamond went elsewhere
	var zone_def := data.rumor_data.zone(district, r.zone)
	if zone_def != null and not zone_def.art.is_empty():
		r.art = zone_def.art[rng.randi_range(0, zone_def.art.size() - 1)]
	return r


## A street node in the zone that has no diamond and no place on it; any free node when the zone is full.
static func _free_node(map: DistrictMapDef, zone: StringName, rng: RandomNumberGenerator,
		used_nodes: Array[StringName]) -> StringName:
	var places := {}
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		places[lm.node] = true
	var in_zone: Array[StringName] = []
	var anywhere: Array[StringName] = []
	for id: StringName in map.nodes:
		if used_nodes.has(id) or places.has(id):
			continue
		anywhere.append(id)
		if DistrictMapRules.zone_at(map, map.node_pos(id)) == zone:
			in_zone.append(id)
	var pick := in_zone if not in_zone.is_empty() else anywhere
	return pick[rng.randi_range(0, pick.size() - 1)] if not pick.is_empty() else map.home
