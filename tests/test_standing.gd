extends TestSuite
## The hunter's standing (GDD 10.3, 12): Bestiary marks and their fight bonuses, faction reputation and its effects,
## the Register rank, the board by rank and the exam.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(21, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(21, &"contracts", 1))
	return run


func _won_fight(data: ContentData, monster: StringName, captured: bool = false) -> CombatState:
	var s := CombatRules.start(DeckBuilder.default_setup(data, monster, 3), data)
	s.phase = CombatState.Phase.WON
	s.captured = captured
	return s


func test_bestiary_marks_and_bonuses() -> void:
	var data := load_content(false)
	var run := _run(data)
	var s := _won_fight(data, &"vigil_hound")
	eq(BestiaryRules.fight_marks(run, s), [&"seen", &"fought", &"slain"] as Array[StringName], "a first kill")
	BestiaryRules.after_fight(run, s)
	check(BestiaryRules.fight_marks(run, s).is_empty(), "nothing new the second time")
	var mods := BestiaryRules.mods(run, data, &"vigil_hound")
	for k: StringName in data.balance.bestiary.mods.get(&"slain", {}) as Dictionary:
		check(mods.has(k), "the kill's bonus %s" % k)
	check(BestiaryRules.mods(run, data, &"gutter_choir").is_empty(), "nothing for an unknown creature")
	check(BestiaryRules.creatures(run, data).has(&"vigil_hound"), "the district's creatures are listed")


func test_reputation_tiers_and_effects() -> void:
	var data := load_content(false)
	var run := _run(data)
	eq(FactionRules.tier(run, data, &"grey_communion"), &"neutral", "neutral at first")
	eq(FactionRules.mult(run, data, &"infirmary_mult"), 1.0, "usual prices")
	run.hero_hp = 1
	var cost := HealthRules.treat_cost(run, data)
	run.standing.reputation[&"grey_communion"] = data.balance.factions.tier_min[&"trusted"]
	eq(FactionRules.tier(run, data, &"grey_communion"), &"trusted", "trusted")
	check(HealthRules.treat_cost(run, data) < cost, "the sisters are cheaper")
	run.standing.reputation[&"vigil"] = data.balance.factions.tier_min[&"sworn"]
	eq(FactionRules.bonus(run, data, &"extra_signs"), 1, "the Vigil's dossiers")
	var big: Dictionary[StringName, int] = {&"vigil": 500}
	FactionRules.apply(run, big)
	eq(run.standing.rep(&"vigil"), FactionRules.MAX_REP, "capped")


func test_fight_changes_follow_outcome_and_petition() -> void:
	var data := load_content(false)
	var run := _run(data)
	var c := ContractRules.board(run.contracts)[0]
	c.accepted = true
	c.type = &"slay"
	c.petition = &"watch_corporal"
	var changes := FactionRules.fight_changes(data, c, &"slain")
	check(changes.get(&"vigil", 0) >= data.balance.factions.petition_done, "the Vigil's petition and the kill")
	check(changes.get(&"grey_communion", 0) < 0, "the rival frowns")
	var none := FactionRules.fight_changes(data, null, &"captured")
	check(none.get(&"grey_communion", 0) > 0, "a capture pleases the Communion")


func test_board_offers_up_to_one_rank_above() -> void:
	var data := load_content(false)
	var run := _run(data)
	for id: StringName in RegisterRules.board_pool(run, data, &"GREY"):
		check(RegisterRules.rank_of(data, data.monster(id).rank) <= 1, "%s is A or P" % id)
	run.standing.rank = 1
	check(RegisterRules.board_pool(run, data, &"GREY").has(&"burrow_wyrm"), "rank P sees the D-rank Burrow Wyrm")
	check(RegisterRules.reward_mult(run, data) > 1.0, "rewards grow with the rank")


func test_exam_is_pinned_passed_and_failed() -> void:
	var data := load_content(false)
	var run := _run(data)
	var rng := SeededRng.make_stream(21, &"register", 1)
	check(not RegisterRules.update(run, data, rng), "no exam before enough contracts")
	run.standing.rank_contracts = data.balance.register.exam_after[0]
	check(RegisterRules.update(run, data, rng), "the exam is pinned")
	var exam := RegisterRules.open_exam(run.contracts)
	check(exam != null and exam.exam, "an exam leaflet")
	eq(data.monster(exam.monster).rank, data.balance.register.ranks[1], "a creature of the next rank")
	eq(ContractRules.can_accept(run.contracts, data, exam.uid), "", "an exam takes no slot")
	ContractRules.accept(run.contracts, data, exam.uid)
	var setup := DeckBuilder.default_setup(data, exam.monster, 1)
	ContractRules.prepare_fight(setup, exam, run.day, data.balance)
	eq(setup.enemy_hp_mult, data.balance.contracts.overdue_hp_mult, "an exam creature is stronger")
	eq(RegisterRules.exam_xp(data, exam, &"slain"), data.balance.register.exam_xp, "exam XP")
	check(ContractRules.resolve_fight(run, exam.uid, &"slain") > 0, "paid")
	check(RegisterRules.contract_done(run, exam), "passed")
	eq(run.standing.rank, 1, "rank P")
	eq(run.standing.rank_contracts, 0, "the count starts again")
	run.standing.rank_contracts = data.balance.register.exam_after[1]
	RegisterRules.update(run, data, rng)
	var second := RegisterRules.open_exam(run.contracts)
	check(second != null, "the next exam")
	run.day = second.deadline_day + 1
	check(RegisterRules.update(run, data, rng), "a missed exam fails")
	check(RegisterRules.open_exam(run.contracts) == null, "and goes")
	check(not RegisterRules.update(run, data, rng), "not again this week")


func test_standing_survives_save_and_v12_starts_at_a() -> void:
	var data := load_content(false)
	var run := _run(data)
	BestiaryRules.mark(run, &"lamplighter", &"dissected")
	run.standing.reputation[&"vigil"] = -12
	run.standing.rank = 2
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	check(back.bestiary.has(&"lamplighter", &"dissected"), "marks kept")
	eq(back.standing.rep(&"vigil"), -12, "reputation kept")
	eq(back.standing.rank, 2, "rank kept")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 12, "master_seed": 4}))
	eq(old.standing.rank, 0, "v12: rank A")
	check(old.bestiary.marks.is_empty(), "v12: knows nothing")
