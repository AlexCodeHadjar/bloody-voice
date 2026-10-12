extends TestSuite
## Workshop and loot (GDD 6, 17.2): start stock, crafting, the workshop day, tiers, salvage, fight loot, unlocks.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(3, data.balance)
	WorkshopRules.ensure_start(run, data)
	return run


## Gives the hunter `cost` (resources into resources, trophies into trophies).
func _give(run: RunState, data: ContentData, cost: Dictionary) -> void:
	for k: Variant in cost:
		var id := StringName(str(k))
		var into := run.workshop.resources if data.balance.workshop.resources.has(id) else run.workshop.trophies
		into[id] = int(into.get(id, 0)) + int(cost[k])


func test_new_run_has_start_stock_and_blueprints() -> void:
	var data := load_content(false)
	var run := _run(data)
	for id: StringName in data.balance.workshop.start_resources:
		eq(run.workshop.amount(id), data.balance.workshop.start_resources[id], "start %s" % id)
	for id: StringName in data.blueprint_order:
		eq(run.workshop.blueprints.has(id), data.blueprint(id).start, "blueprint %s known only if start" % id)
	check(not WorkshopRules.ensure_start(run, data), "only once")


func test_craft_spends_and_the_workshop_day_holds_two_items() -> void:
	var data := load_content(false)
	var run := _run(data)
	var item: StringName = &"bayonet_mount"
	var bp := data.blueprint(item)
	_give(run, data, bp.cost)
	_give(run, data, bp.cost)
	_give(run, data, bp.cost)
	var before := run.workshop.amount(&"scrap")
	eq(WorkshopRules.craft(run, data, item), "", "first craft")
	eq(run.workshop.amount(&"scrap"), before - int(bp.cost.get(&"scrap", 0)), "scrap paid")
	check(run.loadout.owned_modules.has(item), "the module is in the stash")
	eq(WorkshopRules.crafts_left(run, data), data.balance.workshop.crafts_per_day - 1, "one craft used")
	eq(WorkshopRules.craft(run, data, item), "", "second craft")
	check(WorkshopRules.craft(run, data, item) != "", "no third craft today")
	check(WorkshopRules.leave(run), "leaving ends a started workshop day")
	check(not WorkshopRules.leave(run), "leaving again does nothing")
	run.day += 1
	eq(WorkshopRules.crafts_left(run, data), data.balance.workshop.crafts_per_day, "a new day: crafts again")


func test_unknown_blueprint_and_missing_resources() -> void:
	var data := load_content(false)
	var run := _run(data)
	var locked: StringName = &""
	for id: StringName in data.blueprint_order:
		if not data.blueprint(id).start:
			locked = id
			break
	check(WorkshopRules.craft(run, data, locked) != "", "unknown blueprint")
	run.workshop.resources.clear()
	check(WorkshopRules.craft(run, data, &"bayonet_mount") != "", "no resources")
	eq(WorkshopRules.crafts_left(run, data), data.balance.workshop.crafts_per_day, "a refused craft uses nothing")


func test_upgrade_changes_the_deck_for_every_copy() -> void:
	var data := load_content(false)
	var run := _run(data)
	var m: StringName = &"brass_scope"
	check(run.loadout.owned_modules.has(m), "start module")
	var before := int(DeckBuilder.build(run.loadout, data).mods.get(&"part_damage", 0))
	_give(run, data, WorkshopRules.upgrade_cost(run, data, m))
	eq(WorkshopRules.upgrade(run, data, m), "", "upgrade")
	eq(run.loadout.tier(m), 2, "tier II")
	var after := int(DeckBuilder.build(run.loadout, data).mods.get(&"part_damage", 0))
	eq(after, data.module(m).mods_at(2)[&"part_damage"], "tier II bonus in the deck")
	check(after > before, "stronger")
	_give(run, data, WorkshopRules.upgrade_cost(run, data, m))
	eq(WorkshopRules.upgrade(run, data, m), "", "upgrade to III")
	check(WorkshopRules.upgrade_cost(run, data, m).is_empty(), "no tier IV")
	check(WorkshopRules.upgrade(run, data, m) != "", "max tier")


func test_salvage_only_spare_and_returns_half() -> void:
	var data := load_content(false)
	var run := _run(data)
	check(WorkshopRules.salvage(run, data, &"brass_scope") != "", "an installed module can't be salvaged")
	run.loadout.owned_modules.append(&"bayonet_mount")
	var scrap := run.workshop.amount(&"scrap")
	var refund := WorkshopRules.salvage_refund(data, &"bayonet_mount")
	eq(WorkshopRules.salvage(run, data, &"bayonet_mount"), "", "spare salvaged")
	eq(run.workshop.amount(&"scrap"), scrap + int(refund.get(&"scrap", 0)), "half the scrap back")
	check(not run.loadout.owned_modules.has(&"bayonet_mount"), "gone")
	eq(WorkshopRules.crafts_left(run, data), data.balance.workshop.crafts_per_day, "salvage is free")


func test_fight_loot_and_trophy_unlocks() -> void:
	var data := load_content(false)
	var run := _run(data)
	var s := CombatRules.start(DeckBuilder.default_setup(data, &"vigil_hound", 1), data)
	eq(LootRules.fight_loot(data, s).is_empty(), true, "no loot while the fight is on")
	s.phase = CombatState.Phase.WON
	s.trophies.append(&"fang")
	var loot := LootRules.fight_loot(data, s)
	var by_rank := data.balance.workshop.loot_by_rank[data.monster(&"vigil_hound").rank] as Dictionary
	eq(loot.resources.get(&"ichor", 0), by_rank.get(&"ichor", 0), "ichor by rank")
	eq(loot.trophies.get(&"fang", 0), 1, "the fang")
	var teach := LootRules.preview_blueprints(run, data, loot)
	check(not teach.is_empty(), "the fang teaches blueprints")
	LootRules.take(run, data, loot)
	for id: StringName in teach:
		check(run.workshop.blueprints.has(id), "%s learned" % id)
	eq(run.workshop.amount(&"fang"), 1, "the fang is in the stash")
	s.captured = true
	eq(LootRules.fight_loot(data, s).resources.get(&"ichor", 0), int(by_rank.get(&"ichor", 0)) * data.balance.workshop.capture_ichor_mult, "a capture gives more ichor")
	s.phase = CombatState.Phase.LOST
	check(LootRules.fight_loot(data, s).is_empty(), "a lost fight gives nothing")


func test_workshop_survives_save_and_old_saves_get_the_start() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.loadout.module_tiers[&"brass_scope"] = 2
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.workshop.to_dict(), run.workshop.to_dict(), "round trip")
	eq(back.loadout.tier(&"brass_scope"), 2, "tier kept")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 5, "master_seed": 9}))
	check(old.workshop.blueprints.is_empty(), "v5 save: no stock yet")
	check(WorkshopRules.ensure_start(old, data), "start stock given on load")
