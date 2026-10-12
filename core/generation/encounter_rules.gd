class_name EncounterRules
extends RefCounted
## Which creatures live in a district and which one the hunter meets (placeholder until rumors, GDD 8).


## Creatures that live in the district (GDD 13: monsters[].districts).
static func pool(data: ContentData, district: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in data.monster_order:
		if data.monster(id).districts.has(district):
			out.append(id)
	return out


## A creature of the district (any creature when none lives there). Contract targets in `favoured` weigh more.
static func pick_monster(data: ContentData, district: StringName, rng: RandomNumberGenerator,
		favoured: Array[StringName] = [], favoured_weight: float = 1.0) -> StringName:
	var candidates := pool(data, district)
	if candidates.is_empty():
		candidates = data.monster_order
	var weights: Dictionary[StringName, float] = {}
	for id: StringName in candidates:
		weights[id] = favoured_weight if favoured.has(id) else 1.0
	return SeededRng.weighted(weights, rng)


## A random zone id of the district map (the fight's background), or &"" when the district has no map.
static func pick_zone(data: ContentData, district: StringName, rng: RandomNumberGenerator) -> StringName:
	var map := data.district_map(district)
	if map == null or map.zones.is_empty():
		return &""
	return map.zones[rng.randi_range(0, map.zones.size() - 1)].id
