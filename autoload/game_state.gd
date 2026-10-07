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
	EventBus.run_started.emit()


func continue_game() -> bool:
	var loaded := SaveService.load_run()
	if loaded == null:
		return false
	for problem: String in WeaponGridRules.drop_invalid(loaded.loadout, ContentDB.data):
		push_warning("[save] gear removed: " + problem)
	run = loaded
	Rng.set_seed(run.master_seed)
	EventBus.run_loaded.emit()
	return true


func save_game() -> void:
	if run != null:
		SaveService.save_run(run)


## Free action (GDD 3.3): move the hero figure to another district.
func move_hero(district: StringName) -> void:
	if run == null or district == run.hero_district or ContentDB.data.district(district) == null:
		return
	run.hero_district = district
	EventBus.hero_moved.emit(district)


## Ends the current day (the main day actions will call this after their effect).
func end_day() -> void:
	if run == null:
		return
	var report := DayRules.end_day(run, ContentDB.data)
	for c: DistrictStateRules.Change in report.state_changes:
		EventBus.district_state_changed.emit(c.key, c.old_state, c.new_state)
	if report.rent_taken != 0:
		EventBus.money_changed.emit(run.money)
	EventBus.day_changed.emit(run.day)
	save_game()


## Gear can be changed anywhere outside a fight, for free (owner's decision, GDD 5).
func equip_module(module: StringName, section: StringName, pos: Vector2i, rot: int) -> String:
	if run == null or combat != null:
		return "Not now."
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
		return "Not now."
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


## Placeholder for "Investigate a rumor" (GDD 8): a fight in the hero's district.
func start_hunt(monster_id: StringName = &"", capture_allowed: bool = false) -> void:
	if run == null:
		return
	var rng := Rng.stream(&"encounters", run.day)
	var id := monster_id if monster_id != &"" else EncounterRules.pick_monster(ContentDB.data, run.hero_district, rng)
	var setup := DeckBuilder.setup(run.loadout, ContentDB.data, id, Rng.stream(&"combat", run.day).randi(), capture_allowed)
	if capture_allowed:
		if not setup.deck.has(&"iron_net"):  # the contract issues a net unless the gear already brings one
			setup.deck.append(&"iron_net")
	combat = CombatRules.start(setup, ContentDB.data)
	EventBus.combat_started.emit()


## Returns "" or the reason the card can't be played.
func combat_play(uid: int, target: CombatTarget) -> String:
	if combat == null:
		return "No fight."
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
	combat = null
	EventBus.combat_finished.emit(outcome)
	end_day()
