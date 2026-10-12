extends TestSuite
## The Mechanic skill web (GDD 4.4): buying linked nodes, blueprints, sockets, workshop crafts, passives, reset.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(10, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	run.progress.skill_points = 30
	return run


func _web(data: ContentData) -> SkillDefs.WebDef:
	return data.webs[&"mechanic"]


func test_nodes_need_a_linked_owned_node_and_points() -> void:
	var data := load_content(false)
	var run := _run(data)
	var web := _web(data)
	check(SkillRules.is_owned(run, web, &"start"), "the start is owned")
	check(SkillRules.buy(run, data, web, &"g_helm") != "", "not linked yet")
	eq(SkillRules.buy(run, data, web, &"g_hp1"), "", "linked to the start")
	eq(SkillRules.buy(run, data, web, &"g_helm"), "", "now linked")
	eq(run.progress.skill_points, 28, "two points spent")
	check(SkillRules.buy(run, data, web, &"g_hp1") != "", "not twice")
	run.progress.skill_points = 0
	check(SkillRules.buy(run, data, web, &"g_chest") != "", "no points")


func test_effects_blueprint_socket_crafts_and_passives() -> void:
	var data := load_content(false)
	var run := _run(data)
	var web := _web(data)
	SkillRules.buy(run, data, web, &"c_lantern")
	check(run.workshop.blueprints.has(&"lantern_of_revealing"), "a blueprint learned")
	var helmet: GearDefs.ArmorDef = data.armor.filter(func(a: GearDefs.ArmorDef) -> bool: return a.id == &"helmet")[0]
	var sockets := ArmorRules.socket_count(run.loadout, helmet)
	SkillRules.buy(run, data, web, &"g_hp1")
	SkillRules.buy(run, data, web, &"g_helm")
	eq(ArmorRules.socket_count(run.loadout, helmet), sockets + 1, "+1 helmet socket")
	eq(int(SkillRules.mods(run, data).get(&"max_hp", 0)), 4, "passive max HP")
	for id: StringName in [&"m_draw", &"m_ichor", &"m_bleed", &"m_cap", &"m_galv", &"m_key"]:
		eq(SkillRules.buy(run, data, web, id), "", "modules path: %s" % id)
	eq(WorkshopRules.crafts_per_day(run, data), data.balance.workshop.crafts_per_day + 1, "Tinkerer: one more craft")


func test_reset_refunds_points_for_money_and_keeps_blueprints() -> void:
	var data := load_content(false)
	var run := _run(data)
	var web := _web(data)
	for id: StringName in [&"g_hp1", &"g_helm", &"c_lantern"]:
		SkillRules.buy(run, data, web, id)
	run.loadout.owned_mechanisms.append(&"lantern_of_revealing")
	ArmorRules.set_socket(run.loadout, data, &"helmet", 1, &"lantern_of_revealing")  # the socket the web added
	var cost := SkillRules.reset_cost(run, data, web)
	eq(cost, 3 * data.balance.skills.reset_cost_per_point, "per refunded point")
	run.money = cost - 1
	check(SkillRules.reset(run, data, web) != "", "no credit")
	run.money = cost
	var points := run.progress.skill_points
	eq(SkillRules.reset(run, data, web), "", "reset")
	eq(run.money, 0, "paid")
	eq(run.progress.skill_points, points + 3, "points back")
	check(run.skills.owned_in(web.id).is_empty(), "nothing owned")
	check(run.workshop.blueprints.has(&"lantern_of_revealing"), "the blueprint stays")
	check(run.loadout.spare_mechanisms().has(&"lantern_of_revealing"), "the mechanism of the vanished socket is spare again")


func test_skills_survive_save_and_old_saves_migrate() -> void:
	var data := load_content(false)
	var run := _run(data)
	SkillRules.buy(run, data, _web(data), &"w_dmg1")
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.skills.owned_in(&"mechanic"), [&"w_dmg1"] as Array[StringName], "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 10, "master_seed": 9}))
	check(old.skills.owned.is_empty(), "v10 save: nothing bought")
