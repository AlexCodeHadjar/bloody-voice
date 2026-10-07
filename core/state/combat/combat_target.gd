class_name CombatTarget
extends RefCounted
## Where a card is aimed: the creature, one of its body parts, or the hunter.

const ENEMY := &"enemy"
const PART := &"part"
const SELF := &"self"

var kind: StringName = SELF
var part_id: StringName = &""


static func enemy() -> CombatTarget:
	var t := CombatTarget.new()
	t.kind = ENEMY
	return t


static func part(id: StringName) -> CombatTarget:
	var t := CombatTarget.new()
	t.kind = PART
	t.part_id = id
	return t


static func self_target() -> CombatTarget:
	return CombatTarget.new()
