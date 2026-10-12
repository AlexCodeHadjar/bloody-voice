extends TestSuite
## The Monster web and the Voice (GDD 4.2, 4.4): blood samples from fights, nodes that use them up and raise the Voice,
## stages and their cards, Hunger, losing control, rest and calming, selling samples, no reset, saves.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(12, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	run.progress.skill_points = 30
	return run


func _web(data: ContentData) -> SkillDefs.WebDef:
	return data.webs[&"monster"]


func test_fights_give_samples_and_captures_pure_ones() -> void:
	var data := load_content(false)
	var run := _run(data)
	var s := CombatRules.start(DeckBuilder.default_setup(data, &"vigil_hound", 1), data)
	s.phase = CombatState.Phase.WON
	var loot := LootRules.fight_loot(data, s)
	eq(loot.samples.get(&"vigil_hound", 0), 1, "a kill gives a sample")
	check(loot.pure_samples.is_empty(), "no pure sample from a kill")
	LootRules.take(run, data, loot)
	eq(run.workshop.samples.get(&"vigil_hound", 0), 1, "the sample is in the stock")
	s.captured = true
	loot = LootRules.fight_loot(data, s)
	eq(loot.pure_samples.get(&"vigil_hound", 0), 1, "a capture gives a pure sample")
	check(loot.samples.is_empty(), "and no normal one")


func test_nodes_use_up_samples_and_raise_the_voice() -> void:
	var data := load_content(false)
	var run := _run(data)
	var web := _web(data)
	check(SkillRules.buy(run, data, web, &"h1") != "", "no sample, no formula")
	run.workshop.samples[&"vigil_hound"] = 1
	run.workshop.pure_samples[&"vigil_hound"] = 1
	eq(SkillRules.buy(run, data, web, &"h1"), "", "a sample bought it")
	check(not run.workshop.samples.has(&"vigil_hound"), "the normal sample is used first")
	eq(run.workshop.pure_samples.get(&"vigil_hound", 0), 1, "the pure one stays")
	eq(run.voice, web.node(&"h1").voice, "the Voice grew")
	eq(SkillRules.buy(run, data, web, &"h2"), "", "a pure sample stands in for a normal one")
	check(run.workshop.pure_samples.is_empty(), "used up")
	run.workshop.samples[&"vigil_hound"] = 3
	check(SkillRules.buy(run, data, web, &"h_key") != "", "a keystone needs a pure sample")
	eq(SkillRules.buy(run, data, web, &"b_se"), "", "a blood node needs no sample")
	check(SkillRules.cards(run, data).has(&"hounds_rage"), "Hound's Hunger adds its card")
	check(SkillRules.can_reset(run, data, web) != "", "the Monster web is never reset")


func test_stages_cards_and_will() -> void:
	var data := load_content(false)
	var run := _run(data)
	var v := data.balance.voice
	eq(VoiceRules.stage(run, data), 0, "silent")
	check(VoiceRules.fight_cards(run, data).is_empty(), "no cards while silent")
	run.voice = v.stages[0]
	eq(VoiceRules.stage(run, data), 1, "Whispers")
	eq(VoiceRules.fight_cards(run, data), [v.rage_card] as Array[StringName], "a rage card")
	eq(VoiceRules.hunger_chance(run, data), 0.0, "no Hunger yet")
	run.voice = v.stages[1]
	eq(VoiceRules.hunger_chance(run, data), v.hunger_chance, "Hunger")
	run.voice = v.stages[2]
	check(VoiceRules.fight_cards(run, data).has(v.beast_card), "the Beast's card")
	run.progress.attributes[&"will"] = run.progress.attribute(&"will") + 1
	eq(VoiceRules.stage(run, data), 2, "Will pushes the stages back")


func test_rest_and_calm_lower_the_voice() -> void:
	var data := load_content(false)
	var run := _run(data)
	var v := data.balance.voice
	check(VoiceRules.calm(run, data) != "", "nothing to calm")
	run.voice = 12
	HealthRules.rest(run, data)
	eq(run.voice, 12 - v.rest_voice, "rest quiets it a little")
	run.money = v.calm_cost - 1
	check(VoiceRules.calm(run, data) != "", "no credit")
	run.money = v.calm_cost
	eq(VoiceRules.calm(run, data), "", "calmed")
	eq(run.money, 0, "paid")
	eq(run.voice, maxi(0, 12 - v.rest_voice - v.calm_voice), "the Voice dropped")


func test_lose_control_only_at_the_beast() -> void:
	var data := load_content(false)
	var run := _run(data)
	var rng := SeededRng.make_stream(1, &"voice", 1)
	for i: int in 20:
		check(not VoiceRules.loses_control(run, data, rng), "never below stage 3")
	run.voice = 100
	var lost := 0
	for i: int in 200:
		lost += 1 if VoiceRules.loses_control(run, data, rng) else 0
	check(lost > 0 and lost < 200, "a chance at stage 3")


func test_hunger_plays_an_attack_card() -> void:
	var data := load_content(false)
	var setup := DeckBuilder.default_setup(data, &"vigil_hound", 4)
	setup.hunger_chance = 1.0
	var s := CombatRules.start(setup, data)
	var played := s.events.any(func(e: CombatEvent) -> bool: return e.kind == &"hunger")
	var has_attack := s.hand.any(func(c: CardInstance) -> bool: return c.def.type == &"attack")
	check(played or not has_attack, "Hunger played a card when one was there")


func test_samples_sell_and_survive_save() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.workshop.samples[&"lamplighter"] = 1
	run.workshop.pure_samples[&"lamplighter"] = 1
	run.voice = 7
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.voice, 7, "the Voice kept")
	eq(back.workshop.pure_samples.get(&"lamplighter", 0), 1, "samples kept")
	var money := run.money
	var normal := ShopRules.sell_sample(run, data, &"lamplighter", false)
	var pure := ShopRules.sell_sample(run, data, &"lamplighter", true)
	eq(pure, normal * data.balance.voice.pure_sell_mult, "a pure sample fetches more")
	eq(run.money, money + normal + pure, "paid")
	eq(ShopRules.sell_sample(run, data, &"lamplighter", false), 0, "none left")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 11, "master_seed": 4}))
	eq(old.voice, 0, "v11: the Voice starts silent")
