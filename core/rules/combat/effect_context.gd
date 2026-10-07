class_name EffectContext
extends RefCounted
## Who is acting on whom while effects run.

var actor: Combatant
var opponent: Combatant
var target: CombatTarget
var actor_is_hero: bool


static func create(actor_value: Combatant, opponent_value: Combatant, target_value: CombatTarget, is_hero: bool) -> EffectContext:
	var c := EffectContext.new()
	c.actor = actor_value
	c.opponent = opponent_value
	c.target = target_value
	c.actor_is_hero = is_hero
	return c


func part_id() -> StringName:
	return target.part_id if target.kind == CombatTarget.PART else &""
