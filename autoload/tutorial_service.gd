extends Node
## Tutorial hints (GDD 22): screens call Tutorial.trigger(&"combat_start") and Tutorial.action(&"end_turn"); fight
## events (first broken part, panic, empty magazine, an attack card played) are watched here. Progress is saved in
## the profile (Profile autoload), not in the run.

var flow: TutorialFlow
var _overlay: TutorialOverlay
var _seen_events := 0
var _fight: CombatState


func _ready() -> void:
	flow = TutorialFlow.new(ContentDB.data.tutorial, Profile.state)
	_overlay = TutorialOverlay.new()
	add_child(_overlay)
	_overlay.next_pressed.connect(_on_next)
	_overlay.skip_step_pressed.connect(_on_next)
	_overlay.skip_all_pressed.connect(_on_skip_all)
	EventBus.combat_updated.connect(_watch_combat)


func trigger(trigger_id: StringName) -> void:
	flow.profile = Profile.state
	if flow.trigger(trigger_id):
		_show()


func action(action_id: StringName) -> void:
	if flow.active != null:
		flow.action(action_id)
		_show()


## A hint whose element is gone (its screen was left) is dropped and shows again next time;
## hints turned off in the settings hide the current one.
func _process(_delta: float) -> void:
	var s := flow.current()
	if s == null:
		return
	if not Profile.state.hints_on:
		flow.skip_all()
		_show()
	elif not TutorialAnchors.alive(s.anchor):
		flow.abort()
		_show()


func _on_next() -> void:
	flow.next()
	_show()


func _on_skip_all() -> void:
	flow.skip_all()
	_show()


func _show() -> void:
	var s := flow.current()
	if s == null:
		_overlay.hide_hint()
		Profile.save()
		return
	var counter := "%d / %d" % [flow.step_index + 1, flow.active.steps.size()] if flow.active.steps.size() > 1 else ""
	_overlay.show_step(Loc.t(s.title_key), Loc.t(s.text_key), counter, s.anchor, s.action != &"")


## One-off hints and «do» steps from the fight log.
func _watch_combat() -> void:
	var s := GameState.combat
	if s == null:
		return
	if s != _fight:
		_fight = s
		_seen_events = 0
	for i: int in range(_seen_events, s.events.size()):
		var e := s.events[i]
		match e.kind:
			&"part_broken":
				trigger(&"part_broken")
			&"panic":
				trigger(&"panic")
			&"play":
				var card := ContentDB.data.card(e.subject)
				if card != null and card.type == &"attack":
					action(&"attack_played")
	_seen_events = s.events.size()
	if s.hero.max_ammo > 0 and s.hero.ammo == 0:
		trigger(&"no_ammo")
