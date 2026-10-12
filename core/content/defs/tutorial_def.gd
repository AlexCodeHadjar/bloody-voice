class_name TutorialDef
extends RefCounted
## One tutorial hint sequence (data/tutorial/sequences.json, GDD 22).

## Events that start a sequence (fired by screens through the Tutorial autoload).
const TRIGGERS: Array[StringName] = [&"combat_start", &"equipment_open", &"part_broken", &"panic", &"no_ammo",
	&"rent_tomorrow", &"district_open", &"first_rumor", &"contract_board_open", &"contract_taken",
	&"workshop_open"]
## Elements a step can highlight (screens register them in TutorialAnchors).
const ANCHORS: Array[StringName] = [&"enemy", &"intents", &"hand", &"ap", &"parts", &"weapon", &"vials", &"end_turn",
	&"weapon_grid", &"spares", &"deck", &"armor", &"day_bar", &"battle", &"district_map", &"camera_buttons",
	&"contract_board", &"contract_tracker", &"rumor_tags", &"rumor_match", &"rumor_buttons",
	&"workshop_list", &"workshop_bench", &"workshop_crafts", &"workshop_stash"]
## Player actions a `do` step waits for.
const ACTIONS: Array[StringName] = [&"attack_played", &"end_turn", &"module_installed", &"hero_walked"]


class StepDef:
	var anchor: StringName
	var action: StringName = &""  ## "" = the player presses «Далее»
	var title_key: String
	var text_key: String


var id: StringName
var trigger: StringName
var steps: Array[StepDef] = []


static func from_dict(seq_id: StringName, d: Dictionary, errs: ErrorLog) -> TutorialDef:
	var t := TutorialDef.new()
	var w := "tutorial/sequences.json/%s" % seq_id
	t.id = seq_id
	t.trigger = DefReader.id(d, "trigger", errs, w)
	if not TRIGGERS.has(t.trigger):
		errs.add(w, "unknown trigger '%s'" % t.trigger)
	var steps := DefReader.array(d, "steps", errs, w)
	for i: int in steps.size():
		var sd := steps[i] as Dictionary
		var s := StepDef.new()
		s.anchor = DefReader.id(sd, "anchor", errs, w)
		s.action = StringName(str(sd.get("do", "")))
		s.title_key = "tutorial.%s.%d.title" % [seq_id, i + 1]
		s.text_key = "tutorial.%s.%d.text" % [seq_id, i + 1]
		if not ANCHORS.has(s.anchor):
			errs.add(w, "step %d: unknown anchor '%s'" % [i + 1, s.anchor])
		if s.action != &"" and not ACTIONS.has(s.action):
			errs.add(w, "step %d: unknown action '%s'" % [i + 1, s.action])
		if not Loc.has(s.title_key) or not Loc.has(s.text_key):
			errs.add(w, "step %d: no Russian text (%s)" % [i + 1, s.text_key])
		t.steps.append(s)
	return t
