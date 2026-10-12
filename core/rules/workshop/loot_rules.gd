class_name LootRules
extends RefCounted
## What a won fight gives (GDD 17.2 LootGenerator, owner 2026-10-12): ichor and scrap by the creature's rank (ichor
## x2 for a capture), the creature's own extra loot, the trophies of broken parts. The first find of a trophy teaches
## the blueprints it unlocks. A lost fight gives nothing.


class Loot:
	var resources: Dictionary[StringName, int] = {}
	var trophies: Dictionary[StringName, int] = {}
	var blueprints: Array[StringName] = []  ## blueprints this loot teaches (filled by preview / take)

	func is_empty() -> bool:
		return resources.is_empty() and trophies.is_empty()


static func fight_loot(data: ContentData, s: CombatState) -> Loot:
	var loot := Loot.new()
	var outcome := s.outcome()
	if outcome != &"slain" and outcome != &"captured":
		return loot
	var m := s.enemy.def
	add_to(loot.resources, data.balance.workshop.loot_by_rank.get(m.rank, {}) as Dictionary)
	add_to(loot.resources, m.loot)
	if outcome == &"captured" and loot.resources.has(&"ichor"):
		loot.resources[&"ichor"] *= data.balance.workshop.capture_ichor_mult
	for t: StringName in s.trophies:
		loot.trophies[t] = int(loot.trophies.get(t, 0)) + 1
	return loot


## Blueprints the loot would teach: unknown ones whose unlock trophy is in it.
static func preview_blueprints(run: RunState, data: ContentData, loot: Loot) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in data.blueprint_order:
		var bp := data.blueprint(id)
		if bp.unlock != &"" and loot.trophies.has(bp.unlock) and not run.workshop.blueprints.has(id):
			out.append(id)
	return out


## Puts the loot into the stock and teaches its blueprints (listed in loot.blueprints).
static func take(run: RunState, data: ContentData, loot: Loot) -> void:
	loot.blueprints = preview_blueprints(run, data, loot)
	add_resources(run.workshop, loot.resources)
	add_to(run.workshop.trophies, loot.trophies)
	run.workshop.blueprints.append_array(loot.blueprints)


static func add_resources(ws: WorkshopState, add: Dictionary) -> void:
	add_to(ws.resources, add)


## into[k] += add[k] for every key.
static func add_to(into: Dictionary[StringName, int], add: Dictionary) -> void:
	for k: Variant in add:
		var id := StringName(str(k))
		into[id] = int(into.get(id, 0)) + int(add[k])
