class_name EncounterRules
extends RefCounted
## Which creature the hunter meets in a district (placeholder until rumors/contracts, GDD 8).


static func pick_monster(data: ContentData, district: StringName, rng: RandomNumberGenerator) -> StringName:
	var local: Array[StringName] = []
	for id: StringName in data.monster_order:
		if data.monster(id).districts.has(district):
			local.append(id)
	var pool := local if not local.is_empty() else data.monster_order
	return pool[rng.randi_range(0, pool.size() - 1)]


## A random zone id of the district map (the fight's background), or &"" when the district has no map.
static func pick_zone(data: ContentData, district: StringName, rng: RandomNumberGenerator) -> StringName:
	var map := data.district_map(district)
	if map == null or map.zones.is_empty():
		return &""
	return map.zones[rng.randi_range(0, map.zones.size() - 1)].id
