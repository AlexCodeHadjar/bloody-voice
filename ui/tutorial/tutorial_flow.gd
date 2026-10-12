class_name TutorialFlow
extends RefCounted
## Which hint is on screen (GDD 22.2): starts a sequence on its trigger (once, if hints are on), waits for «Далее»
## or for the step's player action, marks finished sequences as seen. No nodes — the Tutorial autoload shows it.

var sequences: Dictionary[StringName, TutorialDef] = {}
var profile: ProfileState
var active: TutorialDef = null
var step_index := 0
var _queue: Array[StringName] = []


func _init(seqs: Dictionary[StringName, TutorialDef], p: ProfileState) -> void:
	sequences = seqs
	profile = p


func current() -> TutorialDef.StepDef:
	return active.steps[step_index] if active != null else null


## Starts (or queues) the first unseen sequence with this trigger. Returns true if a hint is now on screen.
func trigger(trigger_id: StringName) -> bool:
	if not profile.hints_on:
		return false
	for s: TutorialDef in sequences.values():
		if s.trigger == trigger_id and not profile.has_seen(s.id) and active != s and not _queue.has(s.id):
			if active == null:
				_start(s)
			else:
				_queue.append(s.id)
			return active == s
	return false


## «Далее» (also used by «Пропустить шаг»).
func next() -> void:
	if active == null:
		return
	step_index += 1
	if step_index >= active.steps.size():
		_finish()


## A player action; advances a step that waits for it.
func action(action_id: StringName) -> void:
	var s := current()
	if s != null and s.action == action_id:
		next()


## The screen of the hint was left: drop it without marking it seen (it shows again next time).
func abort() -> void:
	if active == null:
		return
	active = null
	_start_queued()


## «Пропустить обучение»: hides everything and turns hints off.
func skip_all() -> void:
	profile.hints_on = false
	if active != null:
		profile.mark_seen(active.id)
	active = null
	_queue.clear()


func _start(s: TutorialDef) -> void:
	active = s
	step_index = 0


func _finish() -> void:
	profile.mark_seen(active.id)
	active = null
	_start_queued()


func _start_queued() -> void:
	while not _queue.is_empty():
		var nxt: TutorialDef = sequences.get(_queue.pop_front())
		if nxt != null and not profile.has_seen(nxt.id):
			_start(nxt)
			return
