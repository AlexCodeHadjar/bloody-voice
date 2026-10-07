class_name Combatant
extends RefCounted
## Shared fight data of the hunter and the creature.

var display_name: String
var hp: int
var max_hp: int
var block: int = 0
var statuses: Dictionary[StringName, int] = {}


func status(id: StringName) -> int:
	return statuses.get(id, 0)


func add_status(id: StringName, stacks: int) -> void:
	var v := status(id) + stacks
	if v <= 0:
		statuses.erase(id)
	else:
		statuses[id] = v


func is_dead() -> bool:
	return hp <= 0
