class_name StatusRules
extends RefCounted
## Status timing: bleed hurts at the start of its owner's turn; weak/exposed/enraged fade at the end.
## Dodge stays until an attack uses it.

const FADING: Array[StringName] = [&"weak", &"exposed", &"enraged"]


static func turn_start(state: CombatState, c: Combatant) -> void:
	c.block = 0
	var bleed := c.status(&"bleed")
	if bleed > 0:
		c.hp -= bleed
		c.add_status(&"bleed", -1)
		state.log_event(&"bleed", "%s bleeds for %d." % [c.display_name, bleed], bleed)


static func turn_end(c: Combatant) -> void:
	for s: StringName in FADING:
		if c.status(s) > 0:
			c.add_status(s, -1)
