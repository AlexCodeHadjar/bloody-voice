class_name EffectSchema
extends RefCounted
## The effect language of cards and monster moves: op name -> required parameters.
## EffectApplier implements every op listed here (checked by tests/test_combat.gd).

const OPS: Dictionary[StringName, Array] = {
	&"damage": ["amount"],  # optional: hits
	&"block": ["amount"],
	&"heal": ["amount"],
	&"lose_hp": ["amount"],
	&"sanity": ["amount"],  # sanity damage to the hunter
	&"draw": ["amount"],
	&"gain_ap": ["amount"],
	&"reload": [],
	&"foresight": [],
	&"apply_status": ["status", "stacks"],  # optional: to = target | self
	&"add_card": ["card"],  # optional: pile = hand | draw | discard, count
	&"capture": ["chance"],
}

const STATUSES: Array[StringName] = [&"weak", &"exposed", &"bleed", &"dodge", &"enraged"]


## Problems with one effect dictionary ("" = fine).
static func check(effect: Dictionary) -> String:
	var op := StringName(str(effect.get("op", "")))
	if not OPS.has(op):
		return "unknown effect op '%s'" % op
	for key: String in OPS[op]:
		if not effect.has(key):
			return "op '%s' needs '%s'" % [op, key]
	if op == &"apply_status" and not STATUSES.has(StringName(str(effect["status"]))):
		return "unknown status '%s'" % effect["status"]
	return ""
