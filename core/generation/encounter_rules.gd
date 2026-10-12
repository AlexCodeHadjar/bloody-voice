class_name EncounterRules
extends RefCounted
## Which creatures live in a district, a creature for a developer fight, a zone for a fight background.


## Creatures that live in the district (GDD 13: monsters[].districts).
static func pool(data: ContentData, district: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in data.monster_order:
		var m := data.monster(id)
		if m != null and m.districts.has(district):  # unknown ids are reported by the monster check
			out.append(id)
	return out


## A creature of the district (any creature when none lives there).
static func pick_monster(data: ContentData, district: StringName, rng: RandomNumberGenerator) -> StringName:
	var candidates := pool(data, district)
	if candidates.is_empty():
		candidates = data.monster_order
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## A random zone id of the district map (the fight's background), or &"" when the district has no map.
static func pick_zone(data: ContentData, district: StringName, rng: RandomNumberGenerator) -> StringName:
	var map := data.district_map(district)
	if map == null or map.zones.is_empty():
		return &""
	return map.zones[rng.randi_range(0, map.zones.size() - 1)].id
