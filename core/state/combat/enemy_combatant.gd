class_name EnemyCombatant
extends Combatant
## The creature during a fight: its move deck, visible intents, parts and phases.

var def: MonsterDef
var parts: Dictionary[StringName, PartState] = {}
var part_order: Array[StringName] = []
var move_draw: Array[StringName] = []
var move_discard: Array[StringName] = []
var intents: Array[StringName] = []
var removed_moves: Dictionary[StringName, bool] = {}
var next_phase: int = 0  ## index into the phases sorted from highest threshold


func broken_parts() -> int:
	var n := 0
	for p: PartState in parts.values():
		if p.broken:
			n += 1
	return n


func move_available(move_id: StringName) -> bool:
	return not removed_moves.has(move_id)
