class_name PartState
extends RefCounted
## A body part of the creature during a fight.

var def: MonsterDef.PartDef
var hp: int
var broken: bool = false


static func create(part_def: MonsterDef.PartDef) -> PartState:
	var p := PartState.new()
	p.def = part_def
	p.hp = part_def.hp
	return p
