extends TestSuite
## Weapon cells, modules, links, armor sockets, deck building and gear bonuses in combat (GDD 5).


func _start_loadout(data: ContentData) -> LoadoutState:
	return LoadoutState.from_dict(data.balance.start_loadout)


func test_rotation() -> void:
	var t: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
	var r1 := WeaponGridRules.rotated(t, 1)
	eq(r1, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 1)] as Array[Vector2i], "T turned once")
	eq(WeaponGridRules.rotated(t, 4), t, "four turns = no turn")


func test_start_loadout_is_valid_and_builds_the_starter_deck() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	eq(WeaponGridRules.problems(l, data).size(), 0, "start gear fits")
	var b := DeckBuilder.build(l, data)
	eq(b.deck.size(), data.balance.starter_deck.size() + data.weapon(&"hunting_rifle").cards.size(), "deck size")
	eq(b.max_ammo, 3, "rifle magazine")
	eq(b.mods.get(&"part_damage", 0), 3, "brass scope bonus")


func test_placement_rules() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	l.placements.clear()
	l.owned_modules.append_array([&"coil_accelerator", &"drum_magazine", &"quick_loader"])
	check(WeaponGridRules.can_place(l, data, &"brass_scope", &"sight", Vector2i.ZERO, 1).contains("does not fit"), "vertical scope is too tall")
	check(WeaponGridRules.can_place(l, data, &"brass_scope", &"barrel", Vector2i.ZERO, 0).contains("fits only"), "wrong section")
	check(WeaponGridRules.can_place(l, data, &"coil_accelerator", &"barrel", Vector2i(3, 0), 0).contains("spark"), "needs spark cells")
	eq(WeaponGridRules.place(l, data, &"drum_magazine", &"magazine", Vector2i.ZERO, 0), "", "drum fills the magazine")
	check(WeaponGridRules.place(l, data, &"quick_loader", &"magazine", Vector2i.ZERO, 0).contains("in the way"), "no overlap")
	check(WeaponGridRules.place(l, data, &"drum_magazine", &"magazine", Vector2i.ZERO, 0).contains("no spare"), "only owned copies")
	eq(WeaponGridRules.placement_at(l, data, &"magazine", Vector2i(1, 1)), 0, "found by cell")
	eq(WeaponGridRules.remove_at(l, 0), &"drum_magazine", "removed")
	check(l.spare_modules().has(&"drum_magazine"), "spare again")


func test_every_gear_module_fits_the_starting_rifle() -> void:
	var data := load_content(false)
	for id: StringName in data.modules:
		var m := data.module(id)
		if m.cell != &"gear":
			continue
		var l := _start_loadout(data)
		l.placements.clear()
		var fits := false
		for y: int in 3:
			for x: int in 5:
				for rot: int in 4:
					fits = fits or WeaponGridRules.can_place(l, data, id, m.section, Vector2i(x, y), rot) == ""
		check(fits, "%s fits somewhere in the %s" % [id, m.section])


func test_links_swap_cards_when_modules_touch() -> void:
	var data := load_content(false)
	var w := WeaponDef.new()
	w.id = &"test_rifle"
	w.max_ammo = 2
	var barrel := WeaponDef.SectionDef.new()
	barrel.id = &"barrel"
	for x: int in 3:
		barrel.cells[Vector2i(x, 0)] = &"gear"
	for x: int in range(3, 5):
		barrel.cells[Vector2i(x, 0)] = &"spark"
	w.sections.append(barrel)
	data.weapons[w.id] = w
	var l := LoadoutState.new()
	l.weapon = w.id
	l.owned_modules = [&"harpoon_launcher", &"coil_accelerator"]
	eq(WeaponGridRules.place(l, data, &"harpoon_launcher", &"barrel", Vector2i.ZERO, 0), "", "harpoon")
	eq(WeaponGridRules.place(l, data, &"coil_accelerator", &"barrel", Vector2i(3, 0), 0), "", "coil")
	var b := DeckBuilder.build(l, data)
	check(b.deck.has(&"shock_harpoon") and not b.deck.has(&"harpoon_shot"), "linked card swapped")
	eq(b.links.size(), 1, "one active link")


func test_armor_sockets_add_cards_and_mods() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	check(ArmorRules.set_socket(l, data, &"helmet", 0, &"lantern_of_revealing").contains("no spare"), "must own it")
	l.owned_mechanisms = [&"lantern_of_revealing", &"riveted_plates"]
	eq(ArmorRules.set_socket(l, data, &"helmet", 0, &"lantern_of_revealing"), "", "helmet socket")
	eq(ArmorRules.set_socket(l, data, &"chestplate", 0, &"riveted_plates"), "", "chest socket")
	check(ArmorRules.set_socket(l, data, &"greaves", 0, &"riveted_plates").contains("no spare"), "one copy only")
	var s := DeckBuilder.setup(l, data, &"gutter_choir", 1)
	check(s.deck.has(&"flash"), "lantern card")
	eq(s.hero_max_hp, data.balance.base_hp + 6, "plates add HP")
	eq(ArmorRules.set_socket(l, data, &"helmet", 0, &""), "", "emptied")
	check(not DeckBuilder.build(l, data).deck.has(&"flash"), "card gone")


func test_gear_bonuses_in_combat() -> void:
	var data := load_content(false)
	var setup := DeckBuilder.default_setup(data, &"gutter_choir", 3)
	setup.deck = [&"shot", &"shot", &"shot", &"reload", &"strike", &"strike", &"strike"]
	setup.mods = {&"part_damage": 3, &"shot_damage": 2, &"shot_block": 2, &"shot_bleed": 1,
		&"bleed_bonus": 1, &"first_turn_ap": 1, &"first_turn_draw": 1, &"reload_draw": 1}
	var s := CombatRules.start(setup, data)
	eq(s.hero.ap, setup.max_ap + 1, "first turn AP")
	eq(s.hand.size(), setup.hand_size + 1, "first turn draw")
	var shot := _card(s, &"shot")
	CombatRules.play_card(s, shot.uid, CombatTarget.part(&"right_throat"), data)
	eq(s.enemy.parts[&"right_throat"].hp, 8 - mini(8, 9 + 2 + 3), "shot + shot_damage + part_damage")
	eq(s.hero.block, 2, "shot_block")
	eq(s.enemy.status(&"bleed"), 2, "shot_bleed + bleed_bonus")


func test_reload_draw_and_rage_discount() -> void:
	var data := load_content(false)
	var setup := DeckBuilder.default_setup(data, &"clay_saint", 4)
	setup.deck = [&"strike", &"strike", &"strike", &"strike", &"strike", &"strike", &"strike", &"strike"]
	setup.mods = {&"reload_draw": 1, &"rage_hp_discount": 1}
	var s := CombatRules.start(setup, data)
	DeckRules.add_cards(s, data.card(&"reload"), &"hand", 1)
	DeckRules.add_cards(s, data.card(&"hounds_rage"), &"hand", 1)
	var hand_before := s.hand.size()
	CombatRules.play_card(s, _card(s, &"reload").uid, CombatTarget.self_target(), data)
	eq(s.hand.size(), hand_before - 1 + 1 + 1, "reload card draws 1, gear draws 1 more")
	var hp := s.hero.hp
	CombatRules.play_card(s, _card(s, &"hounds_rage").uid, CombatTarget.enemy(), data)
	eq(s.hero.hp, hp - 3, "rage costs 4 - 1")


func test_loadout_survives_save_and_old_saves_get_start_gear() -> void:
	var data := load_content(false)
	var run := RunState.create(9, data.balance)
	run.loadout.owned_mechanisms.append(&"smoke_bellows")
	ArmorRules.set_socket(run.loadout, data, &"greaves", 0, &"smoke_bellows")
	var back := RunState.from_dict(SaveMigrations.migrate(JSON.parse_string(JSON.stringify(run.to_dict())) as Dictionary))
	eq(back.loadout.placements.size(), 1, "placement kept")
	eq(back.loadout.placements[0].module, &"brass_scope", "module kept")
	eq(ArmorRules.mechanism_at(back.loadout, &"greaves", 0), &"smoke_bellows", "socket kept")
	var old := {"version": 1, "master_seed": 1, "day": 3}
	var migrated := RunState.from_dict(SaveMigrations.migrate(old, data.balance.start_loadout))
	eq(migrated.loadout.weapon, &"hunting_rifle", "v1 save gets the start weapon")


func test_rotation_with_offset_and_touching_edges_only() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	l.placements.clear()
	l.owned_modules = [&"quick_loader", &"recoil_spring", &"gyro_stabilizer"]
	eq(WeaponGridRules.place(l, data, &"recoil_spring", &"stock", Vector2i(0, 0), 0), "", "S in stock")
	eq(WeaponGridRules.covered(l.placements[0], data), [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i], "S cells")
	eq(WeaponGridRules.place(l, data, &"quick_loader", &"magazine", Vector2i(0, 1), 0), "", "loader lower row")
	eq(WeaponGridRules.covered(l.placements[1], data), [Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i], "offset applied")
	check(not WeaponGridRules.touching(l.placements[0], l.placements[1], data), "different sections never touch")
	var diag := LoadoutState.Placement.new()
	diag.module = &"quick_loader"
	diag.section = &"magazine"
	diag.pos = Vector2i(0, 0)
	diag.rot = 1
	var other := LoadoutState.Placement.new()
	other.module = &"quick_loader"
	other.section = &"magazine"
	other.pos = Vector2i(1, 0)
	other.rot = 1
	check(WeaponGridRules.touching(diag, other, data), "side by side columns touch")


func test_replacing_a_socket_frees_the_old_mechanism() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	l.owned_mechanisms = [&"lantern_of_revealing", &"smoke_bellows"]
	ArmorRules.set_socket(l, data, &"helmet", 0, &"lantern_of_revealing")
	eq(ArmorRules.set_socket(l, data, &"helmet", 0, &"smoke_bellows"), "", "swap")
	check(l.spare_mechanisms().has(&"lantern_of_revealing"), "old one is spare again")


func test_duplicate_modules_stack() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	l.placements.clear()
	l.owned_modules = [&"quick_loader", &"quick_loader"]
	eq(WeaponGridRules.place(l, data, &"quick_loader", &"magazine", Vector2i(0, 0), 0), "", "first")
	eq(WeaponGridRules.place(l, data, &"quick_loader", &"magazine", Vector2i(0, 1), 0), "", "second copy")
	eq(DeckBuilder.build(l, data).mods.get(&"reload_draw", 0), 2, "effects add up")


func test_capture_cards_only_on_capture_contracts() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	l.placements.clear()
	l.owned_modules = [&"net_caster"]
	WeaponGridRules.place(l, data, &"net_caster", &"barrel", Vector2i.ZERO, 0)
	check(not DeckBuilder.build(l, data).deck.has(&"iron_net"), "no net on normal hunts")
	eq(DeckBuilder.build(l, data, true).deck.count(&"iron_net"), 1, "one net on capture contracts")


func test_invalid_saved_placements_are_dropped() -> void:
	var data := load_content(false)
	var l := _start_loadout(data)
	var bad := LoadoutState.Placement.new()
	bad.module = &"drum_magazine"
	bad.section = &"sight"
	l.owned_modules.append(&"drum_magazine")
	l.placements.append(bad)
	eq(WeaponGridRules.drop_invalid(l, data).size(), 1, "one removed")
	eq(l.placements.size(), 1, "scope kept")


func _card(s: CombatState, id: StringName) -> CardInstance:
	for c: CardInstance in s.hand:
		if c.def.id == id:
			return c
	return null
