extends Node
## Facade between the screens and the game rules (GDD 19.3).
## Screens call these commands; only this node changes RunState, always through rules, then emits signals.

var run: RunState = null
var combat: CombatState = null  ## the fight in progress (not saved)


func has_run() -> bool:
	return run != null


func new_game(seed_value: int = 0) -> void:
	var s := seed_value if seed_value != 0 else SeededRng.new_master_seed()
	run = RunState.create(s, ContentDB.data.balance)
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
	for c: DistrictStateRules.Change in report.state_changes:
		EventBus.district_state_changed.emit(c.key, c.old_state, c.new_state)
	if report.rent_taken != 0:
		EventBus.money_changed.emit(run.money)
	_refresh_board()
	_new_morning()
	EventBus.day_changed.emit(run.day)
	save_game()


## Every Monday the tavern board gets new leaflets (GDD 3.2, 7.1).
func _refresh_board() -> void:
	var rng := Rng.stream(&"contracts", CalendarRules.week(run.day, ContentDB.data.balance))
	if ContractRules.refresh_board(run, ContentDB.data, rng):
		EventBus.contracts_changed.emit()


## The morning's rumor diamonds (GDD 8): once per day.
func _new_morning() -> void:
	if RumorRules.new_morning(run, ContentDB.data, Rng.stream(&"rumors", run.day)):
		EventBus.rumors_changed.emit()


## Free action (GDD 3.3): take a leaflet from the tavern board; its first true rumor appears at once.
## "" or the reason it can't be taken.
func accept_contract(uid: int) -> String:
	if run == null:
		return Loc.t("rule.not_now")
	var problem := ContractRules.accept(run.contracts, ContentDB.data, uid)
	if problem == "":
		EventBus.contracts_changed.emit()
		if RumorRules.seed_targets(run, ContentDB.data, Rng.stream(StringName("rumor_target_%d" % uid), run.day)):
			EventBus.rumors_changed.emit()
		save_game()
	return problem


## Gear can be changed anywhere outside a fight, for free (owner's decision, GDD 5).
func equip_module(module: StringName, section: StringName, pos: Vector2i, rot: int) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := WeaponGridRules.place(run.loadout, ContentDB.data, module, section, pos, rot)
	if problem == "":
		_loadout_changed()
	return problem


## Takes a placed module out; returns its id so the screen can pick it up again.
func unequip_module(index: int) -> StringName:
	if run == null or combat != null:
		return &""
	var id := WeaponGridRules.remove_at(run.loadout, index)
	if id != &"":
		_loadout_changed()
	return id


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
			run.loadout.owned_modules.append(id)
	for id: StringName in ContentDB.data.mechanisms:
		if not run.loadout.owned_mechanisms.has(id):
			run.loadout.owned_mechanisms.append(id)
	_loadout_changed()


func _loadout_changed() -> void:
	EventBus.loadout_changed.emit()
	save_game()


## Investigate a rumor (GDD 8): costs the day. A fight starts for the target or another creature (the day ends
## after it); otherwise the money and a crossed-out sign are taken and the day ends now. null if not possible.
func investigate_rumor(uid: int) -> RumorRules.Outcome:
	if run == null or combat != null:
		return null
	var o := RumorRules.investigate(run, ContentDB.data, uid)
	if o == null:
		return null
	EventBus.rumors_changed.emit()
	if o.monster != &"":
		var contract := run.contracts.find(o.contract_uid)
		_start_fight(o.monster, contract if ContractRules.active(run.contracts).has(contract) else null, o.zone)
		return o
	if o.money != 0:
		EventBus.money_changed.emit(run.money)
	if o.crossed != &"":
		EventBus.contracts_changed.emit()
	end_day()
	return o


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
	if capture_allowed:
		if not setup.deck.has(&"iron_net"):  # the contract issues a net unless the gear already brings one
			setup.deck.append(&"iron_net")
	setup.backdrop = _backdrop(zone)
	combat = CombatRules.start(setup, data)
	EventBus.combat_started.emit()


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
	var paid := ContractRules.resolve_fight(run, combat.contract_uid, outcome)
	combat = null
	EventBus.combat_finished.emit(outcome)
	if paid > 0:
		EventBus.money_changed.emit(run.money)
		EventBus.contracts_changed.emit()
	end_day()
