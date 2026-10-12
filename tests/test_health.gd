extends TestSuite
## Health between fights, the Hunter's Fall, the infirmary and the Scriptorium (GDD 4, 3.3).


func _run(data: ContentData) -> RunState:
	var run := RunState.create(6, data.balance)
	WorkshopRules.ensure_start(run, data)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(6, &"contracts", 1))
	RumorRules.new_morning(run, data, SeededRng.make_stream(6, &"rumors", 1))
	return run


func test_hp_carries_into_the_next_fight() -> void:
	var data := load_content(false)
	var run := _run(data)
	eq(HealthRules.hp(run, data), HealthRules.max_hp(run, data), "a new run starts full")
	run.hero_hp = 11
	run.hero_sanity = 5
	var setup := DeckBuilder.default_setup(data, &"vigil_hound", 1)
	setup.hero_hp = HealthRules.hp(run, data)
	setup.hero_sanity = HealthRules.sanity(run, data)
	var s := CombatRules.start(setup, data)
	eq(s.hero.hp, 11, "HP carried")
	eq(s.hero.sanity, 5, "Sanity carried")
	s.hero.hp = 7
	HealthRules.after_fight(run, s)
	eq(run.hero_hp, 7, "what the fight left")


func test_rest_restores_a_third() -> void:
	var data := load_content(false)
	var run := _run(data)
	var top := HealthRules.max_hp(run, data)
	run.hero_hp = 1
	run.hero_sanity = 0
	HealthRules.rest(run, data)
	eq(run.hero_hp, 1 + ceili(top * data.balance.health.rest_share), "a third of HP")
	eq(run.hero_sanity, ceili(HealthRules.max_sanity(run, data) * data.balance.health.rest_share), "a third of Sanity")
	for i: int in 5:
		HealthRules.rest(run, data)
	eq(run.hero_hp, top, "never above the maximum")


func test_infirmary_heals_for_money_never_on_credit() -> void:
	var data := load_content(false)
	var run := _run(data)
	check(HealthRules.can_treat(run, data) != "", "nothing to treat when healthy")
	run.hero_hp = 10
	var cost := HealthRules.treat_cost(run, data)
	check(cost > data.balance.health.treat_base, "the price grows with the wounds")
	run.money = cost - 1
	check(HealthRules.treat(run, data) != "", "no credit")
	run.money = cost
	eq(HealthRules.treat(run, data), "", "treated")
	eq(run.money, 0, "paid")
	eq(HealthRules.hp(run, data), HealthRules.max_hp(run, data), "full HP")


func test_hunters_fall_takes_the_fee_even_into_debt() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.money = 5
	run.hero_hp = 0
	var fee := HealthRules.fall(run, data)
	eq(fee, data.balance.health.fall_fee, "the fee")
	eq(run.money, 5 - fee, "into debt if need be")
	eq(HealthRules.hp(run, data), HealthRules.max_hp(run, data), "healed")


func test_scriptorium_verifies_a_rumor() -> void:
	var data := load_content(false)
	var run := _run(data)
	var r := RumorRules.visible(run.rumors)[0]
	eq(LibraryRules.verify(run, r.uid), "", "verified")
	check(r.verified, "flag set")
	check(LibraryRules.verify(run, r.uid) != "", "not twice")
	check(LibraryRules.verify(run, 9999) != "", "unknown rumor")


func test_scriptorium_studies_a_trophy() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := ContractRules.board(run.contracts)[0]
	var m := data.monster(c.monster)
	var trophy: StringName = &""
	for p: MonsterDef.PartDef in m.parts:
		if p.trophy != &"" and LibraryRules.trophy_creature(data, p.trophy) == m.id:
			trophy = p.trophy
	if trophy == &"" or c.known_tags.size() >= m.tags.size():
		return
	check(LibraryRules.study(run, data, trophy).is_empty(), "no trophy, no study")
	run.workshop.trophies[trophy] = 1
	var known := c.known_tags.size()
	var taught := LibraryRules.study(run, data, trophy)
	check(taught.has(c), "the contract learned")
	eq(c.known_tags.size(), known + 1, "one more sign")
	check(m.tags.has(c.known_tags[-1]), "a true sign")
	eq(run.workshop.amount(trophy), 0, "the trophy is spent")


func test_health_survives_save_and_old_saves_start_full() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.hero_hp = 9
	run.hero_sanity = 3
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.hero_hp, 9, "HP")
	eq(back.hero_sanity, 3, "Sanity")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 7, "master_seed": 9}))
	eq(old.hero_hp, -1, "v7 save: full")
