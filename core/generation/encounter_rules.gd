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
