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


## Placeholder for "Investigate a rumor" (GDD 8): a fight in the hero's district.
func start_hunt(monster_id: StringName = &"", capture_allowed: bool = false) -> void:
	if run == null:
		return
	var rng := Rng.stream(&"encounters", run.day)
	var id := monster_id if monster_id != &"" else EncounterRules.pick_monster(ContentDB.data, run.hero_district, rng)
	var setup := CombatSetup.from_balance(ContentDB.data.balance, id, Rng.stream(&"combat", run.day).randi())
	setup.capture_allowed = capture_allowed
	if capture_allowed:
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
