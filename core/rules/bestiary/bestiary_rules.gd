class_name BestiaryRules
extends RefCounted
## The Bestiary (GDD 10.3, owner 2026-10-12: knowledge helps): marks per creature — seen (a contract on it taken or
## a fight begun), fought, slain, captured, dissected (a trophy studied in the Scriptorium). Every mark the hunter
## holds gives its bonuses (balance.json/bestiary, GearMods) in fights with that creature.


## Adds a mark; true when it is new.
static func mark(run: RunState, creature: StringName, m: StringName) -> bool:
	var list := run.bestiary.of(creature)
	if creature == &"" or list.has(m):
		return false
	list.append(m)
	run.bestiary.marks[creature] = list
	return true


## Marks a finished fight would add (pure; the result panel shows them).
static func fight_marks(run: RunState, s: CombatState) -> Array[StringName]:
	var out: Array[StringName] = []
	var wanted: Array[StringName] = [&"seen", &"fought"]
	if s.outcome() == &"slain" or s.outcome() == &"captured":
		wanted.append(s.outcome())
	for m: StringName in wanted:
		if not run.bestiary.has(s.enemy.def.id, m):
			out.append(m)
	return out


## After a fight: adds its marks; returns the new ones.
static func after_fight(run: RunState, s: CombatState) -> Array[StringName]:
	var added := fight_marks(run, s)
	for m: StringName in added:
		mark(run, s.enemy.def.id, m)
	return added


## Bonuses of the hunter's marks on `creature`, for a fight with it.
static func mods(run: RunState, data: ContentData, creature: StringName) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	for m: StringName in run.bestiary.of(creature):
		if data.balance.bestiary.mods.has(m):
			var add: Dictionary[StringName, int] = data.balance.bestiary.mods[m]
			GearMods.sum(out, add)
	return out


## Creatures the Bestiary lists: those of the hero's district (owner 2026-10-12: one district for now).
static func creatures(run: RunState, data: ContentData) -> Array[StringName]:
	return EncounterRules.pool(data, run.hero_district)
