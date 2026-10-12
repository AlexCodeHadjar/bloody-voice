class_name WorkshopRules
extends RefCounted
## The workshop (GDD 6.2, owner 2026-10-12): crafting from known blueprints, upgrading one module copy to tier II–III,
## salvage for half the resources. The first craft or upgrade of a day starts a workshop day (2 items); leaving the
## workshop ends that day (GameState). Salvage and changing gear are free.


## A run that never had a stock (a new game, an old save) gets the start resources and blueprints.
static func ensure_start(run: RunState, data: ContentData) -> bool:
	if run.workshop.started:
		return false
	var old := run.workshop
	run.workshop = WorkshopState.create(data)
	run.workshop.trophies = old.trophies
	return true


static func crafts_left(run: RunState, data: ContentData) -> int:
	var used := run.workshop.crafts_used if run.workshop.day == run.day else 0
	return maxi(0, data.balance.workshop.crafts_per_day - used)


## Ids of `cost` the hunter has too few of.
static func missing(ws: WorkshopState, cost: Dictionary) -> Array[StringName]:
	var out: Array[StringName] = []
	for k: Variant in cost:
		if ws.amount(StringName(str(k))) < int(cost[k]):
			out.append(StringName(str(k)))
	return out


## "" or why the item can't be made now (shown to the player).
static func can_craft(run: RunState, data: ContentData, item: StringName) -> String:
	var bp := data.blueprint(item)
	if bp == null or not run.workshop.blueprints.has(item):
		return Loc.t("rule.workshop.unknown")
	return _can_spend(run, data, bp.cost)


static func craft(run: RunState, data: ContentData, item: StringName) -> String:
	var problem := can_craft(run, data, item)
	if problem != "":
		return problem
	var bp := data.blueprint(item)
	_spend(run, data, bp.cost)
	if bp.kind == &"module":
		run.loadout.add_module(item)
	else:
		run.loadout.owned_mechanisms.append(item)
	return ""


## Cost of raising a copy from `tier` to the next; empty at tier III.
static func upgrade_cost(data: ContentData, module: StringName, tier: int) -> Dictionary:
	var bp := data.blueprint(module)
	if bp == null or tier >= ModuleDef.MAX_TIER or bp.upgrade.size() < tier:
		return {}
	return bp.upgrade[tier - 1]


static func can_upgrade(run: RunState, data: ContentData, module: StringName, tier: int) -> String:
	if not run.loadout.tiers_of(module).has(tier):
		return Loc.t("rule.workshop.not_owned")
	var cost := upgrade_cost(data, module, tier)
	if cost.is_empty():
		return Loc.t("rule.workshop.max_tier")
	return _can_spend(run, data, cost)


## Raises ONE copy of that tier (owner, 2026-10-12): a spare one if there is, else the one in a cell (its place
## keeps it and shows the new tier).
static func upgrade(run: RunState, data: ContentData, module: StringName, tier: int) -> String:
	var problem := can_upgrade(run, data, module, tier)
	if problem != "":
		return problem
	_spend(run, data, upgrade_cost(data, module, tier))
	var l := run.loadout
	if not l.spare_tiers(module).has(tier):
		for p: LoadoutState.Placement in l.placements:
			if p.module == module and p.tier == tier:
				p.tier = tier + 1
				break
	l.remove_module(module, tier)
	l.add_module(module, tier + 1)
	return ""


## Resources salvage returns: salvage_share of what the copy cost (the blueprint and the upgrades up to its tier),
## rounded down; trophies are not returned.
static func salvage_refund(data: ContentData, item: StringName, tier: int = 1) -> Dictionary[StringName, int]:
	var out: Dictionary[StringName, int] = {}
	var bp := data.blueprint(item)
	if bp == null:
		return out
	var paid: Dictionary[StringName, int] = {}
	LootRules.add_to(paid, bp.cost)
	for t: int in range(1, tier):
		LootRules.add_to(paid, upgrade_cost(data, item, t))
	for k: StringName in paid:
		var n := floori(paid[k] * data.balance.workshop.salvage_share)
		if data.balance.workshop.resources.has(k) and n > 0:
			out[k] = n
	return out


## Only a spare copy (not in a cell or socket) can be taken apart.
static func can_salvage(run: RunState, data: ContentData, item: StringName, tier: int = 1) -> String:
	if is_locked(run):
		return Loc.t("rule.workshop.locked")
	var bp := data.blueprint(item)
	if bp == null:
		return Loc.t("rule.workshop.installed")
	var spare := run.loadout.spare_tiers(item).has(tier) if bp.kind == &"module" else run.loadout.spare_mechanisms().has(item)
	return "" if spare else Loc.t("rule.workshop.installed")


static func salvage(run: RunState, data: ContentData, item: StringName, tier: int = 1) -> String:
	var problem := can_salvage(run, data, item, tier)
	if problem != "":
		return problem
	if data.blueprint(item).kind == &"module":
		run.loadout.remove_module(item, tier)
	else:
		run.loadout.owned_mechanisms.erase(item)
	LootRules.add_resources(run.workshop, salvage_refund(data, item, tier))
	return ""


## True when a workshop day was started today: the caller ends the day. Clears it either way.
static func leave(run: RunState) -> bool:
	var started := run.workshop.day == run.day and run.workshop.crafts_used > 0
	run.workshop.day = 0
	run.workshop.crafts_used = 0
	return started


static func is_locked(run: RunState) -> bool:
	return run.workshop_locked_day == run.day


static func _can_spend(run: RunState, data: ContentData, cost: Dictionary) -> String:
	if is_locked(run):
		return Loc.t("rule.workshop.locked")
	if crafts_left(run, data) <= 0:
		return Loc.t("rule.workshop.no_crafts", {"n": data.balance.workshop.crafts_per_day})
	if not missing(run.workshop, cost).is_empty():
		return Loc.t("rule.workshop.no_resources")
	return ""


## Pays the cost and uses one of today's crafts (the first one starts the workshop day).
static func _spend(run: RunState, data: ContentData, cost: Dictionary) -> void:
	var ws := run.workshop
	for k: Variant in cost:
		var id := StringName(str(k))
		if data.balance.workshop.resources.has(id):
			ws.resources[id] = ws.amount(id) - int(cost[k])
		else:
			ws.trophies[id] = ws.amount(id) - int(cost[k])
			if ws.trophies[id] <= 0:
				ws.trophies.erase(id)
	if ws.day != run.day:
		ws.day = run.day
		ws.crafts_used = 0
	ws.crafts_used += 1
