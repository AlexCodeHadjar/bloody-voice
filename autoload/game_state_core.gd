extends Node
## Core of the GameState facade (GDD 19.3): the run, saving, days, gear and fights. autoload/game_state.gd extends it
## with the place actions. Screens call GameState; only this node changes RunState, through rules, then emits signals.
## Never call the child's methods from here (the analyzer checks `self` against this script).

var run: RunState = null
var combat: CombatState = null  ## the fight in progress (not saved)


func has_run() -> bool:
	return run != null


func new_game(seed_value: int = 0) -> void:
	var s := seed_value if seed_value != 0 else SeededRng.new_master_seed()
	run = RunState.create(s, ContentDB.data.balance)
	WorkshopRules.ensure_start(run, ContentDB.data)
	ProgressRules.ensure_start(run, ContentDB.data)
	Rng.set_seed(s)
	_refresh_board()
	_new_morning()
	EventBus.run_started.emit()


func continue_game() -> bool:
	var loaded := SaveService.load_run()
	if loaded == null:
		return false
	for problem: String in WeaponGridRules.drop_invalid(loaded.loadout, ContentDB.data):
		push_warning("[save] gear removed: " + problem)
	run = loaded
	WorkshopRules.ensure_start(run, ContentDB.data)  # saves from before the workshop
	ProgressRules.ensure_start(run, ContentDB.data)  # saves from before levels
	Rng.set_seed(run.master_seed)
	_refresh_board()  # an old save or a save from last week gets this week's board
	_new_morning()
	EventBus.run_loaded.emit()
	return true


func save_game() -> void:
	if run != null:
		SaveService.save_run(run)


## Free action (GDD 3.3): move the hero figure to another district.
func move_hero(district: StringName) -> void:
	if run == null or district == run.hero_district or ContentDB.data.district(district) == null or not is_open(district):
		return
	run.hero_district = district
	run.hero_node = &""
	EventBus.hero_moved.emit(district)


## Locked districts cannot be entered until story events open them.
func is_open(district: StringName) -> bool:
	return run != null and run.open_districts.has(district)


## Where the hero stands on the district map. Not saved here: the district screen saves when it wants.
func set_hero_node(node: StringName) -> void:
	if run == null or node == &"" or node == run.hero_node:
		return
	run.hero_node = node
	EventBus.hero_node_changed.emit(node)


## Ends the current day (the main day actions will call this after their effect).
func end_day() -> void:
	if run == null:
		return
	var report := DayRules.end_day(run, ContentDB.data)
	EventRules.after_tick(run, ContentDB.data, report.state_changes)  # an event that ran out leaves a leaflet
	for c: DistrictStateRules.Change in report.state_changes:
		EventBus.district_state_changed.emit(c.key, c.old_state, c.new_state)
	if report.rent_taken != 0:
		EventBus.money_changed.emit(run.money)
	_refresh_board()
	_new_morning()
	EventBus.day_changed.emit(run.day)
	save_game()


## Every Monday the tavern board gets new leaflets and the shop a new table (GDD 3.2, 7.1, 11.1); every morning
## the Register fails a missed exam or pins a due one (GDD 12.1); on Mondays a district event may start (GDD 15).
func _refresh_board() -> void:
	var week := CalendarRules.week(run.day, ContentDB.data.balance)
	var started := EventRules.weekly(run, ContentDB.data, Rng.stream(&"events", week))  # before the board: its rewards
	if started != null:
		EventBus.district_state_changed.emit(started.key, started.old_state, started.new_state)
	var changed := ContractRules.refresh_board(run, ContentDB.data, Rng.stream(&"contracts", week))
	if RegisterRules.update(run, ContentDB.data, Rng.stream(&"register", run.day)) or changed:  # the Register exam
		EventBus.contracts_changed.emit()
	ShopRules.refresh(run, ContentDB.data, Rng.stream(&"shop", week))


## The morning's rumor diamonds (GDD 8): once per day.
func _new_morning() -> void:
	if RumorRules.new_morning(run, ContentDB.data, Rng.stream(&"rumors", run.day)):
		EventBus.rumors_changed.emit()


## Gear can be changed anywhere outside a fight, for free (owner's decision, GDD 5).
func equip_module(module: StringName, section: StringName, pos: Vector2i, rot: int, tier: int = 1) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := WeaponGridRules.place(run.loadout, ContentDB.data, module, section, pos, rot, tier)
	if problem == "":
		_loadout_changed()
	return problem


## Takes a placed module out; returns the placement (module and tier) so the screen can pick it up again, or null.
func unequip_module(index: int) -> LoadoutState.Placement:
	if run == null or combat != null or index < 0 or index >= run.loadout.placements.size():
		return null
	var p := run.loadout.placements[index]
	WeaponGridRules.remove_at(run.loadout, index)
	_loadout_changed()
	return p


func set_socket(piece: StringName, index: int, mechanism: StringName) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := ArmorRules.set_socket(run.loadout, ContentDB.data, piece, index, mechanism)
	if problem == "":
		_loadout_changed()
	return problem


## Developer only (debug builds): own one of every module and mechanism to try builds.
func dev_grant_all_gear() -> void:
	if run == null or not OS.is_debug_build():
		return
	for id: StringName in ContentDB.data.modules:
		if not run.loadout.owned_modules.has(id):
			run.loadout.add_module(id)
	for id: StringName in ContentDB.data.mechanisms:
		if not run.loadout.owned_mechanisms.has(id):
			run.loadout.owned_mechanisms.append(id)
	_loadout_changed()


func _loadout_changed() -> void:
	EventBus.loadout_changed.emit()
	save_game()


## Developer and test fights (dev shots, the combat screen started on its own): a creature of the hero's district.
func start_hunt(monster_id: StringName = &"", capture_allowed: bool = false) -> void:
	if run == null:
		return
	var id := monster_id if monster_id != &"" else EncounterRules.pick_monster(ContentDB.data, run.hero_district,
		Rng.stream(&"encounters", run.day))
	_start_fight(id, null, &"", capture_allowed)


## A fight with `id`; an open contract on it counts (a net for a capture, a stronger creature when overdue).
func _start_fight(id: StringName, contract: ContractsState.Contract, zone: StringName,
		capture_allowed: bool = false) -> void:
	var data := ContentDB.data
	if contract == null:
		contract = ContractRules.for_monster(run.contracts, id)
	if contract != null and contract.type == &"capture":
		capture_allowed = true
	var setup := DeckBuilder.setup(run.loadout, data, id, Rng.stream(&"combat", run.day).randi(), capture_allowed)
	ContractRules.prepare_fight(setup, contract, run.day, data.balance)
	EventRules.strengthen(setup, run, data)  # a fog breach makes creatures stronger (GDD 14)
	var has_net := setup.deck.any(func(c: StringName) -> bool: return data.card(c).type == &"capture")
	if capture_allowed and not has_net:  # the contract issues a net unless the gear already brings one
		setup.deck.append(&"iron_net")
	setup.deck.append_array(run.bag)  # consumables of the bag (GDD 11.1)
	_hero_into(setup, data)
	GearMods.sum(setup.mods, BestiaryRules.mods(run, data, id))  # what the hunter knows of this creature (GDD 10.3)
	setup.backdrop = _backdrop(zone)
	combat = CombatRules.start(setup, data)
	EventBus.combat_started.emit()


## The hunter as the run has them (GDD 4): carried HP and Sanity, maxima by level and Will, Agility's cards and
## dodge, Cunning's capture chance and preview, the skill webs' bonuses and cards, the Voice's cards and Hunger.
func _hero_into(setup: CombatSetup, data: ContentData) -> void:
	setup.hero_max_hp = HealthRules.max_hp(run, data)
	setup.hero_hp = HealthRules.hp(run, data)
	setup.max_sanity = HealthRules.max_sanity(run, data)
	setup.hero_sanity = HealthRules.sanity(run, data)
	setup.hand_size += ProgressRules.hand_bonus(run, data)
	setup.cunning = run.progress.attribute(&"cunning")
	setup.agility = run.progress.attribute(&"agility")
	setup.preview = ProgressRules.preview(run, data)
	var skill_mods := SkillRules.mods(run, data)  # the skill webs' passives (GDD 4.4)
	GearMods.sum(setup.mods, skill_mods)
	setup.max_ammo += int(skill_mods.get(&"max_ammo", 0))
	setup.deck.append_array(SkillRules.cards(run, data))
	setup.deck.append_array(VoiceRules.fight_cards(run, data))  # the Voice (GDD 4.2)
	setup.hunger_chance = VoiceRules.hunger_chance(run, data)
	setup.voice_stage = VoiceRules.stage(run, data)


## Background of a fight: the rumor's zone (a random zone of the district when none); falls back to the district scene.
func _backdrop(zone: StringName) -> String:
	var district := String(run.hero_district)
	if zone == &"":
		zone = EncounterRules.pick_zone(ContentDB.data, run.hero_district, Rng.stream(&"backdrop", run.day))
	var path := "res://art/city/districts/%s__fight__%s.webp" % [district, zone]
	if zone != &"" and ResourceLoader.exists(path):
		return path
	return "res://art/city/districts/%s__scene__normal.webp" % district


## Returns "" or the reason the card can't be played.
func combat_play(uid: int, target: CombatTarget) -> String:
	if combat == null:
		return Loc.t("rule.no_fight")
	var problem := CombatRules.play_card(combat, uid, target, ContentDB.data)
	EventBus.combat_updated.emit()
	return problem


func combat_end_turn() -> void:
	if combat == null:
		return
	CombatRules.end_turn(combat, ContentDB.data)
	EventBus.combat_updated.emit()


## Closes the fight; a hunt costs the day (GDD 3.3).
func finish_combat() -> void:
	if combat == null:
		return
	var outcome := combat.outcome()
	var c := run.contracts.find(combat.contract_uid)
	var rep := FactionRules.fight_changes(ContentDB.data, c, outcome)  # before the contract is marked done
	var xp := ProgressRules.fight_xp(ContentDB.data, combat) + RegisterRules.exam_xp(ContentDB.data, c, outcome)
	var paid := ContractRules.resolve_fight(run, combat.contract_uid, outcome)
	xp += ContentDB.data.balance.progress.contract_xp if paid > 0 else 0
	_standing_after_fight(c, paid, rep)
	var loot := LootRules.fight_loot(ContentDB.data, combat)
	var beast := lost_control(outcome)  # one roll a day (the result panel shows the same); before the loot
	LootRules.take(run, ContentDB.data, loot)
	ShopRules.spend_bag(run, combat)
	HealthRules.after_fight(run, combat)
	combat = null
	EventBus.combat_finished.emit(outcome)
	if not loot.is_empty():
		EventBus.stock_changed.emit()
	if ProgressRules.add_xp(run, ContentDB.data, xp).xp > 0:
		EventBus.progress_changed.emit()
	if outcome == &"fallen":  # the Hunter's Fall: a day in the Ash Sisters' infirmary on top of the fight's day
		HealthRules.fall(run, ContentDB.data)
		EventBus.money_changed.emit(run.money)
		end_day()
	if paid > 0:
		EventBus.money_changed.emit(run.money)
		EventBus.contracts_changed.emit()
	if beast:  # the Beast took over: the hunter comes to somewhere in the gutters a day later
		end_day()
	end_day()


## The Bestiary marks, reputation and the Register count a fight brings (GDD 10.3, 12); a due exam is pinned the
## next morning (_refresh_board).
func _standing_after_fight(c: ContractsState.Contract, paid: int, rep: Dictionary[StringName, int]) -> void:
	BestiaryRules.after_fight(run, combat)
	FactionRules.apply(run, rep)
	if paid > 0:
		RegisterRules.contract_done(run, c)
	EventBus.progress_changed.emit()


## At the Voice's third stage the Beast may take the hunter after a won fight — slain or captured, owner 2026-10-12
## (the same roll the result panel shows).
func lost_control(outcome: StringName) -> bool:
	return run != null and VoiceRules.loses_control(run, ContentDB.data, Rng.stream(&"voice", run.day), outcome)
