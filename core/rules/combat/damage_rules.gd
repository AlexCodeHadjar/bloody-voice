class_name DamageRules
extends RefCounted
## Damage numbers and dealing damage (dodge -> block -> hp; body parts; phases).


## Final damage of one hit before dodge/block.
static func compute(base: int, attacker: Combatant, defender: Combatant, b: BalanceDef) -> int:
	var v := float(base)
	if attacker.status(&"enraged") > 0:
		v += b.enraged_bonus
	if attacker.status(&"weak") > 0:
		v *= b.weak_mult
	if defender.status(&"exposed") > 0:
		v *= b.exposed_mult
	return maxi(0, int(floor(v)))


## Deals one hit. part_id = body part of the creature that was aimed at ("" = the body).
## Returns hp actually lost by the target (part hits: the part's loss).
static func deal(state: CombatState, attacker: Combatant, defender: Combatant, base: int,
		part_id: StringName, b: BalanceDef) -> int:
	var amount := compute(base, attacker, defender, b)
	if defender.status(&"dodge") > 0:
		defender.add_status(&"dodge", -1)
		state.log_event(&"dodge", "%s dodges." % defender.display_name, 0, _subject(state, defender))
		return 0
	var absorbed := mini(defender.block, amount)
	defender.block -= absorbed
	var dealt := amount - absorbed
	if part_id != &"" and defender is EnemyCombatant:
		return _hit_part(state, part_id, dealt, b)
	defender.hp -= dealt
	if dealt == 0:
		state.log_event(&"blocked", "%s blocks the blow." % defender.display_name, 0, _subject(state, defender))
	else:
		state.log_event(&"damage", "%s takes %d." % [defender.display_name, dealt], dealt, _subject(state, defender))
	if defender is EnemyCombatant:
		EnemyRules.check_phase(state)
	return dealt


static func _hit_part(state: CombatState, part_id: StringName, dealt: int, b: BalanceDef) -> int:
	var enemy := state.enemy
	var part: PartState = enemy.parts[part_id]
	part.hp -= dealt
	var to_body := int(round(dealt * b.part_main_damage_mult))
	enemy.hp -= to_body
	state.log_event(&"damage", "%s takes %d (%d to the body)." % [part.def.name, dealt, to_body], dealt, part_id)
	if part.hp <= 0 and not part.broken:
		EnemyRules.break_part(state, part_id)
	EnemyRules.check_phase(state)
	return dealt


static func _subject(state: CombatState, c: Combatant) -> StringName:
	return &"hero" if c == state.hero else &"enemy"
