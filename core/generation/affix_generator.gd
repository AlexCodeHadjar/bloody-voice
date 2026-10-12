class_name AffixGenerator
extends RefCounted
## Creature affixes (GDD 17 MonsterVariant; owner 2026-10-12): how many by the week and the hunter's Register rank,
## which by weight. Pure: the same threat and stream give the same affixes.


## threat = per_week × (week − 1) + per_rank × rank.
static func threat(run: RunState, data: ContentData) -> float:
	var b := data.balance.affixes
	return b.per_week * (CalendarRules.week(run.day, data.balance) - 1) + b.per_rank * run.standing.rank


## 0..max distinct affixes: the whole part of the threat, plus one more by the chance of the rest.
static func roll(data: ContentData, threat_value: float, rng: RandomNumberGenerator) -> Array[StringName]:
	var out: Array[StringName] = []
	var n := floori(threat_value) + (1 if rng.randf() < threat_value - floorf(threat_value) else 0)
	n = mini(n, data.balance.affixes.max_affixes)
	for i: int in n:
		var weights: Dictionary[StringName, float] = {}
		for a: AffixDefs.AffixDef in data.affixes:
			if not out.has(a.id):
				weights[a.id] = a.weight
		if weights.is_empty():
			break
		out.append(SeededRng.weighted(weights, rng))
	return out


## The signs the affixes add (for leaflets and target rumors).
static func tags(data: ContentData, affixes: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in affixes:
		var a := data.affix(id)
		if a != null and not out.has(a.tag):
			out.append(a.tag)
	return out


## «Frenzy, Carapace» for leaflets and the creature's plate ("" when none).
static func names(data: ContentData, affixes: Array[StringName]) -> String:
	var parts: PackedStringArray = []
	for id: StringName in affixes:
		var a := data.affix(id)
		if a != null:
			parts.append(a.name)
	return ", ".join(parts)
