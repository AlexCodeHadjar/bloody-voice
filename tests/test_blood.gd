extends TestSuite
## Blood cells and the Beast's nights (GDD 4.8): Monster-web nodes turn weapon cells into blood cells (modules on
## them go back to spare, blood modules fit), and a night the Beast took over has a consequence and a note.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(61, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	run.progress.skill_points = 30
	return run


func _buy(run: RunState, data: ContentData, node: StringName) -> void:
	var web: SkillDefs.WebDef = data.webs[&"monster"]
	var nd := web.node(node)
	if nd.sample != &"":
		run.workshop.pure_samples[nd.sample] = 1
	for l: StringName in nd.links:  # buy one parent first when needed
		if not SkillRules.is_owned(run, web, l):
			_buy(run, data, l)
			break
	eq(SkillRules.buy(run, data, web, node), "", "bought %s" % node)


func test_blood_nodes_open_cells_and_blood_modules_fit() -> void:
	var data := load_content(false)
	var run := _run(data)
	var weapon := data.weapon(run.loadout.weapon)
	var frame := weapon.section(&"frame")
	eq(run.loadout.cell_type(frame, Vector2i(2, 1)), &"gear", "a gear cell at first")
	run.loadout.add_module(&"hound_eye")
	check(WeaponGridRules.place(run.loadout, data, &"hound_eye", &"frame", Vector2i(2, 1), 0) != "", "no blood cell yet")
	_buy(run, data, &"b_se")
	eq(run.loadout.cell_type(frame, Vector2i(2, 1)), &"blood", "Thick Blood opens it")
	eq(WeaponGridRules.place(run.loadout, data, &"hound_eye", &"frame", Vector2i(2, 1), 0), "", "the Hound's Eye fits")
	check(run.loadout.placements.any(func(p: LoadoutState.Placement) -> bool: return p.module == &"brass_scope"), "the start scope stays")


func test_modules_on_turned_cells_go_back_to_spare() -> void:
	var data := load_content(false)
	var run := _run(data)
	run.loadout.add_module(&"bayonet_mount")
	var placed := WeaponGridRules.place(run.loadout, data, &"bayonet_mount", &"barrel", Vector2i(0, 0), 0) == ""
	_buy(run, data, &"b_nw")
	if placed:
		check(not run.loadout.placements.any(func(p: LoadoutState.Placement) -> bool: return p.module == &"bayonet_mount"),
			"a gear module on a cell that turned to blood goes back to spare")
	run.loadout.add_module(&"vein_lattice")
	eq(WeaponGridRules.place(run.loadout, data, &"vein_lattice", &"barrel", Vector2i(0, 0), 0), "", "the Vein Lattice fits the barrel")
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	eq(back.loadout.cell_type(data.weapon(back.loadout.weapon).section(&"barrel"), Vector2i(2, 0)), &"blood", "blood cells kept")


func test_beast_nights_have_consequences_and_a_note() -> void:
	var data := load_content(false)
	var v := data.balance.voice
	for what: StringName in v.beast_outcomes:
		var run := _run(data)
		run.money = 100
		run.voice = 20
		var only: Dictionary[StringName, float] = {what: 1.0}
		v.beast_outcomes = only
		eq(VoiceRules.beast_night(run, data, SeededRng.make_stream(1, &"beast", 1)), what, "outcome %s" % what)
		check(run.story.letters.has("beast:%s" % what), "a morning note")
		match what:
			&"money":
				check(run.money < 100, "money gone")
			&"seen":
				check(run.standing.rep(&"vigil") < 0, "the Vigil saw it")
			&"wounded":
				check(HealthRules.hp(run, data) < HealthRules.max_hp(run, data), "wounded")
			&"fed":
				check(run.voice < 20, "the Voice quieter")
