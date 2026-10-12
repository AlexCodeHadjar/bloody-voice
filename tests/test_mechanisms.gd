extends TestSuite
## Mechanisms with a trade-off (GDD 5.6): each gives a strong bonus and takes something back — cards, HP, a bullet or
## a curse in the deck; a mechanism never takes the last bullet.


func _loadout_with(data: ContentData, mech: StringName) -> LoadoutState:
	var l := LoadoutState.from_dict(data.balance.start_loadout)
	l.owned_mechanisms.append(mech)
	eq(ArmorRules.set_socket(l, data, &"helmet", 0, mech), "", "%s in the helmet" % mech)
	return l


func test_trade_offs_reach_the_deck_and_numbers() -> void:
	var data := load_content(false)
	var plain := DeckBuilder.build(LoadoutState.from_dict(data.balance.start_loadout), data)
	var harness := DeckBuilder.build(_loadout_with(data, &"galvanic_harness"), data)
	check(harness.deck.has(&"dread"), "the harness brings a curse")
	eq(int(harness.mods.get(&"first_turn_ap", 0)), 1, "and first-turn AP")
	var lens := DeckBuilder.build(_loadout_with(data, &"fog_lens"), data)
	eq(lens.max_ammo, maxi(1, plain.max_ammo - 1), "the lens costs a bullet")
	var plating := _loadout_with(data, &"heavy_plating")
	eq(DeckBuilder.max_hp_bonus(plating, data), 14, "plating adds 14 HP")
	eq(int(DeckBuilder.build(plating, data).mods.get(&"first_turn_draw", 0)), -1, "but draws less on the first turn")
	var injector := _loadout_with(data, &"ichor_injector")
	eq(DeckBuilder.max_hp_bonus(injector, data), -6, "the injector costs 6 HP")
	var run := RunState.create(71, data.balance)
	ProgressRules.ensure_start(run, data)
	var base := HealthRules.max_hp(run, data)
	run.loadout = injector
	eq(HealthRules.max_hp(run, data), base - 6, "max HP really drops")


func test_never_the_last_bullet_and_a_smaller_first_hand() -> void:
	var data := load_content(false)
	var l := _loadout_with(data, &"fog_lens")
	l.owned_mechanisms.append(&"fog_lens")
	l.owned_mechanisms.append(&"fog_lens")
	l.owned_mechanisms.append(&"fog_lens")
	eq(ArmorRules.set_socket(l, data, &"chestplate", 0, &"fog_lens"), "", "a lens in the chestplate")
	eq(ArmorRules.set_socket(l, data, &"gauntlets", 0, &"fog_lens"), "", "a lens in the gauntlets")
	eq(ArmorRules.set_socket(l, data, &"greaves", 0, &"fog_lens"), "", "a lens in the greaves")
	eq(DeckBuilder.build(l, data).max_ammo, 1, "four lenses still leave one bullet")
	var plain := CombatRules.start(DeckBuilder.default_setup(data, &"gutter_choir", 2), data)
	var setup := DeckBuilder.setup(_loadout_with(data, &"heavy_plating"), data, &"gutter_choir", 2)
	eq(CombatRules.start(setup, data).hand.size(), plain.hand.size() - 1, "plating: one card less in the first hand")


func test_every_new_mechanism_has_its_trophy_blueprint() -> void:
	var data := load_content(false)
	var trophies: Dictionary[StringName, StringName] = {&"heavy_plating": &"tail_spike", &"galvanic_harness": &"sinew",
		&"fog_lens": &"throat", &"ichor_injector": &"fang", &"blood_pump": &"wyrm_tooth"}
	for id: StringName in trophies:
		var bp := data.blueprint(id)
		check(bp != null and bp.kind == &"mechanism" and bp.unlock == trophies[id], "%s: unlocked by %s" % [id, trophies[id]])
