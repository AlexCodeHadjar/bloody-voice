extends TestSuite
## Tutorial hints (GDD 22): sequences are valid data, play once, wait for «do» actions, queue, can be skipped;
## the profile keeps progress and settings.


func test_sequences_are_loaded() -> void:
	var data := load_content(false)
	eq(data.tutorial[&"combat_intro"].steps.size(), 9, "combat intro steps")
	eq(data.tutorial[&"equipment_intro"].steps.size(), 5, "equipment intro steps")
	eq(data.tutorial[&"combat_intro"].steps[4].action, &"attack_played", "step 5 waits for an attack")


func test_sequence_plays_once_and_waits_for_actions() -> void:
	var flow := TutorialFlow.new(load_content(false).tutorial, ProfileState.new())
	check(flow.trigger(&"combat_start"), "first fight starts the combat intro")
	for i: int in 4:
		flow.next()
	eq(flow.step_index, 4, "four «Далее» presses")
	flow.action(&"end_turn")
	eq(flow.step_index, 4, "a wrong action does not advance")
	flow.action(&"attack_played")
	eq(flow.step_index, 5, "the awaited action advances")
	for i: int in 3:
		flow.next()
	flow.action(&"end_turn")
	check(flow.active == null, "sequence finished")
	check(flow.profile.has_seen(&"combat_intro"), "marked as seen")
	check(not flow.trigger(&"combat_start"), "never shown twice")


func test_hints_off_and_skip_all() -> void:
	var p := ProfileState.new()
	p.hints_on = false
	var flow := TutorialFlow.new(load_content(false).tutorial, p)
	check(not flow.trigger(&"combat_start"), "hints off: nothing starts")
	p.hints_on = true
	check(flow.trigger(&"equipment_open"), "hints on again")
	flow.skip_all()
	check(flow.active == null and not p.hints_on, "skip all hides and turns hints off")


func test_one_off_hint_waits_in_queue() -> void:
	var flow := TutorialFlow.new(load_content(false).tutorial, ProfileState.new())
	flow.trigger(&"combat_start")
	check(not flow.trigger(&"part_broken"), "queued while the intro runs")
	for i: int in 9:
		flow.next()
	eq(flow.active.id if flow.active != null else &"", &"first_part_broken", "queued hint follows")


func test_profile_round_trip() -> void:
	var p := ProfileState.new()
	p.mark_seen(&"combat_intro")
	p.volume_music = 0.3
	p.hints_on = false
	var back := ProfileState.from_config(p.to_config())
	check(back.has_seen(&"combat_intro"), "seen kept")
	eq(back.volume_music, 0.3, "volume kept")
	check(not back.hints_on, "hints flag kept")
	back.reset_tutorial()
	check(back.hints_on and not back.has_seen(&"combat_intro"), "reset brings the tutorial back")


func test_abort_keeps_the_hint_for_later() -> void:
	var flow := TutorialFlow.new(load_content(false).tutorial, ProfileState.new())
	flow.trigger(&"equipment_open")
	flow.trigger(&"combat_start")
	flow.abort()
	check(not flow.profile.has_seen(&"equipment_intro"), "aborted hint is not marked seen")
	eq(flow.active.id if flow.active != null else &"", &"combat_intro", "the queued sequence starts")
	flow.skip_all()
	check(not flow.trigger(&"equipment_open"), "after skipping the tutorial nothing starts")


func test_bad_tutorial_data_is_reported() -> void:
	var errs := ErrorLog.new()
	TutorialDef.from_dict(&"test_seq", {"trigger": "no_such_trigger",
		"steps": [{"anchor": "no_such_anchor", "do": "no_such_action"}]}, errs)
	var text := "; ".join(errs.messages)
	check(text.contains("unknown trigger"), "unknown trigger reported")
	check(text.contains("unknown anchor"), "unknown anchor reported")
	check(text.contains("unknown action"), "unknown action reported")
	check(text.contains("no Russian text"), "missing texts reported")
