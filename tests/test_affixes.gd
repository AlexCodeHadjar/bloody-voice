extends TestSuite
## Creature affixes (GDD 17): the threat by week and rank, the roll, their moves and HP in a fight, their signs on
## leaflets and target rumors, saves.


func test_threat_grows_with_week_and_rank() -> void:
	var data := load_content(false)
	var run := RunState.create(41, data.balance)
	eq(AffixGenerator.threat(run, data), 0.0, "week 1, rank A: none")
	check(AffixGenerator.roll(data, 0.0, SeededRng.make_stream(1, &"affixes", 1)).is_empty(), "no affixes at threat 0")
	run.day = 3 * data.balance.days_per_week + 1
	run.standing.rank = 1
	check(AffixGenerator.threat(run, data) > 0.5, "later weeks and a higher rank: more threat")
	var two := AffixGenerator.roll(data, 2.0, SeededRng.make_stream(1, &"affixes", 2))
	eq(two.size(), mini(2, data.balance.affixes.max_affixes), "threat 2: two affixes")
	check(two.size() < 2 or two[0] != two[1], "distinct")
	eq(AffixGenerator.roll(data, 9.0, SeededRng.make_stream(1, &"affixes", 3)).size(), data.balance.affixes.max_affixes, "capped")


func test_affixes_in_a_fight() -> void:
	var data := load_content(false)
	var plain := CombatRules.start(DeckBuilder.default_setup(data, &"vigil_hound", 5), data)
	var setup := DeckBuilder.default_setup(data, &"vigil_hound", 5)
	setup.affixes.assign([&"carapace", &"frenzy"])
	var s := CombatRules.start(setup, data)
	check(s.enemy.max_hp > plain.enemy.max_hp, "Carapace adds HP")
	check(s.enemy.move(data.affix(&"frenzy").move.id) != null, "the affix move is known")
	var in_deck := s.enemy.move_draw.has(data.affix(&"frenzy").move.id) or s.enemy.intents.has(data.affix(&"frenzy").move.id)
	check(in_deck, "and in the creature's deck")
	eq(s.enemy.affixes, [&"carapace", &"frenzy"] as Array[StringName], "the creature knows its affixes")
	var again := CombatRules.start(setup, data)
	eq(again.enemy.move_draw, s.enemy.move_draw, "the same seed: the same deck")
	setup.affixes.assign([&"no_such_affix"])
	eq(CombatRules.start(setup, data).enemy.max_hp, plain.enemy.max_hp, "an unknown affix does nothing")


func test_leaflets_and_rumors_show_affix_signs() -> void:
	var data := load_content(false)
	var opts := ContractGenerator.Options.new()
	opts.monsters = EncounterRules.pool(data, &"GREY")
	opts.threat = 2.0
	var board := ContractGenerator.generate(data, &"GREY", 1, SeededRng.make_stream(4, &"contracts", 1), 1, opts)
	for c: ContractsState.Contract in board:
		check(not c.affixes.is_empty(), "every leaflet at threat 2 has affixes")
		for t: StringName in AffixGenerator.tags(data, c.affixes):
			check(c.known_tags.has(t), "its sign %s is known" % t)
	var r := RumorGenerator.make_target(data, &"GREY", board[0], 1, SeededRng.make_stream(4, &"rumors", 1), 99, [])
	if r != null:
		for t: StringName in AffixGenerator.tags(data, board[0].affixes):
			check(r.tags.has(t), "the target rumor carries %s" % t)


func test_affixes_survive_save_and_v14_has_none() -> void:
	var data := load_content(false)
	var run := RunState.create(41, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(41, &"contracts", 1))
	run.contracts.items[0].affixes.assign([&"venom"])
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.contracts.items[0].affixes, [&"venom"] as Array[StringName], "affixes kept")
	var old := {"version": 14, "master_seed": 3, "contracts": {"items": [{"uid": 1, "monster": "vigil_hound"}]}}
	eq(RunState.from_dict(SaveMigrations.migrate(old)).contracts.items[0].affixes.size(), 0, "v14: none")


func test_affix_signs_are_never_crossed_out_or_studied_as_missing() -> void:
	var data := load_content(false)
	var run := RunState.create(41, data.balance)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(41, &"contracts", 1))
	var c := ContractRules.board(run.contracts)[0]
	c.accepted = true
	c.affixes.assign([&"venom"])
	var sign := data.affix(&"venom").tag
	c.known_tags.append(sign)
	var r := RumorsState.Rumor.new()
	r.uid = 77
	r.kind = &"false_lead"
	r.tags.assign([sign])
	r.expires_day = run.day + 3
	run.rumors.items.append(r)
	RumorRules.investigate(run, data, 77)
	check(not c.crossed_tags.has(sign), "a false lead does not cross out the affix's sign")
	var m := data.monster(c.monster)
	var own := c.known_tags.filter(func(t: StringName) -> bool: return m.tags.has(t)).size()
	eq(LibraryRules.contracts_to_teach(run, data, c.monster).has(c), own < m.tags.size(), "only the creature's own signs count for study")
