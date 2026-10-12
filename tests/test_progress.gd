extends TestSuite
## XP, levels and attributes (GDD 4.1–4.3).


func _run(data: ContentData) -> RunState:
	var run := RunState.create(8, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	return run


func test_start_attributes_and_maxima() -> void:
	var data := load_content(false)
	var run := _run(data)
	for a: StringName in data.balance.progress.start_attributes:
		eq(run.progress.attribute(a), data.balance.progress.start_attributes[a], "start %s" % a)
	eq(HealthRules.max_sanity(run, data), data.balance.base_sanity + data.balance.progress.sanity_per_will * run.progress.attribute(&"will"), "Sanity from Will")
	check(not ProgressRules.ensure_start(run, data), "only once")


func test_levels_give_points_and_hp() -> void:
	var data := load_content(false)
	var run := _run(data)
	var hp := HealthRules.max_hp(run, data)
	var r := ProgressRules.add_xp(run, data, ProgressRules.xp_to_next(data, 1))
	eq(r.levels, 1, "one level")
	eq(run.progress.level, 2, "level 2")
	eq(run.progress.xp, 0, "XP spent")
	eq(run.progress.skill_points, data.balance.progress.skill_points_per_level, "skill point")
	eq(run.progress.attribute_points, 1 if 2 % data.balance.progress.attribute_point_every == 0 else 0, "attribute point every second level")
	eq(HealthRules.max_hp(run, data), hp + data.balance.hp_per_level, "+HP per level")
	var big := ProgressRules.add_xp(run, data, 100000)
	eq(run.progress.level, data.balance.progress.level_cap, "capped")
	eq(run.progress.xp, 0, "no XP kept at the cap")
	check(big.skill_points > big.levels, "bonus points at the bonus levels")
	eq(ProgressRules.add_xp(run, data, 50).xp, 0, "nothing more at the cap")


func test_fight_xp_by_rank_and_capture() -> void:
	var data := load_content(false)
	var s := CombatRules.start(DeckBuilder.default_setup(data, &"vigil_hound", 1), data)
	eq(ProgressRules.fight_xp(data, s), 0, "no XP while fighting")
	s.phase = CombatState.Phase.WON
	var slain := ProgressRules.fight_xp(data, s)
	eq(slain, data.balance.progress.xp_by_rank[data.monster(&"vigil_hound").rank], "by rank")
	s.captured = true
	eq(ProgressRules.fight_xp(data, s), roundi(slain * data.balance.progress.capture_xp_mult), "more for a capture")


func test_raising_attributes() -> void:
	var data := load_content(false)
	var run := _run(data)
	check(ProgressRules.raise(run, data, &"will") != "", "no points")
	run.progress.attribute_points = 1
	run.hero_sanity = 3
	eq(ProgressRules.raise(run, data, &"will"), "", "raised")
	eq(run.progress.attribute(&"will"), data.balance.progress.start_attributes[&"will"] + 1, "Will +1")
	eq(run.hero_sanity, 3 + data.balance.progress.sanity_per_will, "the new Sanity is there at once")
	check(ProgressRules.raise(run, data, &"luck") != "", "unknown attribute")


func test_attribute_effects() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.progress.attributes[&"agility"] = 8
	run.progress.attributes[&"cunning"] = 6
	eq(ProgressRules.hand_bonus(run, data), data.balance.progress.agility_hand_at.size(), "two extra cards")
	eq(ProgressRules.preview(run, data), data.balance.progress.cunning_preview_at.size(), "two moves ahead")
	check(ProgressRules.discount(run, data) <= data.balance.progress.max_discount, "discount capped")
	var r := RumorsState.Rumor.new()
	r.uid = 3
	r.lies = [&"howl"]
	eq(ProgressRules.flagged(run, data, r), ProgressRules.flagged(run, data, r), "the same rumor is flagged the same way")
	run.progress.attributes[&"cunning"] = 0
	eq(ProgressRules.flagged(run, data, r).size(), 0, "no Cunning, no flags")


func test_progress_survives_save_and_old_saves_start() -> void:
	var data := load_content(false)
	var run := _run(data)
	ProgressRules.add_xp(run, data, 300)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.progress.to_dict(), run.progress.to_dict(), "round trip")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 9, "master_seed": 9}))
	check(not old.progress.started and old.progress.level == 1, "v9 save: level 1, no attributes yet")
	check(ProgressRules.ensure_start(old, data), "attributes given on load")
