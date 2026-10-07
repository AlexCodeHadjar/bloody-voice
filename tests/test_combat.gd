extends TestSuite
## Combat core (GDD 9–10).


func _start(monster: StringName = &"gutter_choir", deck: Array[StringName] = [], seed_value: int = 7) -> Array:
	var data := load_content(false)
	var setup := DeckBuilder.default_setup(data, monster, seed_value)
	setup.mods = {}  # rules tests run without gear bonuses (see test_gear.gd)
	if not deck.is_empty():
		setup.deck = deck
	return [CombatRules.start(setup, data), data]


func _card(s: CombatState, id: StringName) -> CardInstance:
	for c: CardInstance in s.hand:
		if c.def.id == id:
			return c
	return null


func test_start_draws_hand_and_reveals_intents() -> void:
	var r := _start()
	var s: CombatState = r[0]
	eq(s.hand.size(), 5, "hand")
	eq(s.hero.ap, 3, "ap")
	eq(s.enemy.intents.size(), 1, "intents")
	eq(s.phase, CombatState.Phase.PLAYER, "player turn")


func test_same_seed_same_fight() -> void:
	var a: CombatState = _start(&"lamplighter", [], 5)[0]
	var b: CombatState = _start(&"lamplighter", [], 5)[0]
	for i: int in a.hand.size():
		eq(a.hand[i].def.id, b.hand[i].def.id, "hand card %d" % i)
	eq(a.enemy.intents, b.enemy.intents, "intents")


func test_strike_damages_and_costs_ap() -> void:
	var r := _start(&"gutter_choir", [&"strike", &"strike", &"strike", &"strike", &"strike"])
	var s: CombatState = r[0]
	var problem := CombatRules.play_card(s, s.hand[0].uid, CombatTarget.enemy(), r[1])
	eq(problem, "", "played")
	eq(s.enemy.hp, s.enemy.max_hp - 6, "6 damage")
	eq(s.hero.ap, 2, "1 AP spent")
	eq(s.discard_pile.size(), 1, "to discard")


func test_not_enough_ap() -> void:
	var r := _start(&"gutter_choir", [&"strike", &"strike", &"strike", &"strike", &"strike"])
	var s: CombatState = r[0]
	for i: int in 3:
		CombatRules.play_card(s, s.hand[0].uid, CombatTarget.enemy(), r[1])
	check(CombatRules.play_card(s, s.hand[0].uid, CombatTarget.enemy(), r[1]).contains("action points"), "4th strike refused")


func test_shot_needs_ammo_and_reload_refills() -> void:
	var r := _start(&"clay_saint", [&"shot", &"shot", &"shot", &"shot", &"reload"])
	var s: CombatState = r[0]
	s.hero.ammo = 0
	var shot := _card(s, &"shot")
	check(CombatRules.play_card(s, shot.uid, CombatTarget.enemy(), r[1]).contains("ammo"), "no ammo")
	eq(CombatRules.play_card(s, _card(s, &"reload").uid, CombatTarget.self_target(), r[1]), "", "reload")
	eq(s.hero.ammo, s.hero.max_ammo, "full ammo")


func test_breaking_a_part_removes_its_move() -> void:
	var r := _start(&"gutter_choir", [&"shot", &"shot", &"shot", &"strike", &"strike"])
	var s: CombatState = r[0]
	var data: ContentData = r[1]
	CombatRules.play_card(s, _card(s, &"shot").uid, CombatTarget.part(&"left_throat"), data)
	check(s.enemy.parts[&"left_throat"].broken, "9 damage breaks an 8 hp throat")
	check(not s.enemy.move_available(&"wail"), "wail removed")
	check(s.trophies.has(&"throat"), "trophy")
	eq(s.enemy.hp, s.enemy.max_hp - int(round(9 * data.balance.part_main_damage_mult)), "half to the body")


func test_broken_part_cannot_be_targeted() -> void:
	var r := _start(&"gutter_choir", [&"shot", &"shot", &"shot", &"strike", &"strike"])
	var s: CombatState = r[0]
	CombatRules.play_card(s, _card(s, &"shot").uid, CombatTarget.part(&"left_throat"), r[1])
	check(CombatRules.play_card(s, _card(s, &"shot").uid, CombatTarget.part(&"left_throat"), r[1]).contains("broken"), "refused")


func test_phase_triggers_below_threshold() -> void:
	var r := _start(&"gutter_choir")
	var s: CombatState = r[0]
	s.enemy.hp = 10
	EnemyRules.check_phase(s)
	eq(s.enemy.next_phase, 1, "phase passed")
	check(s.enemy.move_draw.has(&"chorus"), "chorus added")


func test_block_absorbs_and_dodge_negates() -> void:
	var data := load_content(false)
	var s := CombatState.new()
	s.hero.hp = 20
	s.hero.max_hp = 20
	s.hero.block = 4
	var attacker := Combatant.new()
	eq(DamageRules.deal(s, attacker, s.hero, 6, &"", data.balance), 2, "4 blocked")
	s.hero.add_status(&"dodge", 1)
	eq(DamageRules.deal(s, attacker, s.hero, 6, &"", data.balance), 0, "dodged")
	eq(s.hero.status(&"dodge"), 0, "dodge used")


func test_weak_and_exposed_modify_damage() -> void:
	var b := load_content(false).balance
	var a := Combatant.new()
	var d := Combatant.new()
	a.add_status(&"weak", 1)
	eq(DamageRules.compute(8, a, d, b), 6, "weak 8 -> 6")
	d.add_status(&"exposed", 1)
	eq(DamageRules.compute(8, a, d, b), 9, "weak + exposed 8 -> 9")


func test_enemy_turn_hits_hero_and_new_turn_starts() -> void:
	var r := _start(&"vigil_hound", [&"guard", &"guard", &"guard", &"guard", &"guard"])
	var s: CombatState = r[0]
	s.enemy.intents = [&"maul"]
	var maul := int(s.enemy.def.moves[&"maul"].effects[0]["amount"])
	CombatRules.end_turn(s, r[1])
	eq(s.hero.hp, s.hero.max_hp - maul, "maul hits")
	eq(s.turn, 2, "turn 2")
	eq(s.hand.size(), 5, "new hand")


func test_fear_to_zero_causes_panic() -> void:
	var r := _start(&"mourning_bride")
	var s: CombatState = r[0]
	var data: ContentData = r[1]
	s.hero.sanity = 3
	var ctx := EffectContext.create(s.enemy, s.hero, CombatTarget.self_target(), false)
	EffectApplier.apply(s, {"op": "sanity", "amount": 5}, ctx, data)
	check(s.hero.panicked, "panicked")
	check(_card(s, data.balance.panic_card) != null, "panic card in hand")


func test_capture_chance_formula() -> void:
	var b := load_content(false).balance
	near(CaptureRules.chance(0.6, 100, 100, 0, 0, b), 0.0, "full hp -> 0")
	near(CaptureRules.chance(0.6, 50, 100, 0, 0, b), 0.3, "half hp")
	near(CaptureRules.chance(0.6, 50, 100, 5, 2, b), 0.3 * 1.2 * 1.3, "cunning and parts")
	near(CaptureRules.chance(1.0, 0, 100, 10, 3, b), b.capture_max_chance, "capped")


func test_every_effect_op_is_implemented() -> void:
	var r := _start(&"gutter_choir")
	var s: CombatState = r[0]
	var data: ContentData = r[1]
	var samples := {
		&"damage": {"op": "damage", "amount": 1}, &"block": {"op": "block", "amount": 1},
		&"heal": {"op": "heal", "amount": 1}, &"lose_hp": {"op": "lose_hp", "amount": 1},
		&"sanity": {"op": "sanity", "amount": 1}, &"draw": {"op": "draw", "amount": 1},
		&"gain_ap": {"op": "gain_ap", "amount": 1}, &"reload": {"op": "reload"},
		&"foresight": {"op": "foresight"}, &"apply_status": {"op": "apply_status", "status": "weak", "stacks": 1},
		&"add_card": {"op": "add_card", "card": "dread"}, &"capture": {"op": "capture", "chance": 0.0},
	}
	for op: StringName in EffectSchema.OPS:
		check(samples.has(op), "test sample for op %s" % op)
		if samples.has(op):
			var one: Array[Dictionary] = [samples[op] as Dictionary]
			check(EffectText.describe(one) != "Does nothing.", "EffectText has a phrase for op %s" % op)
			var before := s.events.size()
			EffectApplier.apply(s, samples[op] as Dictionary, EffectContext.create(s.hero, s.enemy, CombatTarget.enemy(), true), data)
			check(s.events.size() >= before, "op %s ran" % op)


func test_bot_finishes_every_fight() -> void:
	var data := load_content(false)
	for id: StringName in data.monster_order:
		for i: int in 25:
			var s := CombatBot.run_fight(DeckBuilder.default_setup(data, id, i), data)
			check(s.is_over(), "%s fight %d finished" % [id, i])
			check(s.turn <= data.balance.turn_limit + 1, "%s within turn limit" % id)


func test_move_text_is_built_from_effects() -> void:
	eq(EffectText.describe([{"op": "damage", "amount": 4, "hits": 2}, {"op": "apply_status", "status": "bleed", "stacks": 2}]),
		"Deal 4 twice, Bleed 2.", "damage + status")
	eq(EffectText.describe([{"op": "sanity", "amount": 4}, {"op": "apply_status", "status": "enraged", "stacks": 1, "to": "self"}]),
		"4 Sanity damage, Enraged 1 (self).", "fear + self buff")
	var lament: MonsterDef.MoveDef = load_content(false).monster(&"mourning_bride").moves[&"lament"]
	eq(lament.text, "%d Sanity damage." % int(lament.effects[0]["amount"]), "data text follows numbers")
