class_name AffixRules
extends RefCounted
## Puts a creature's affixes into its fight (GDD 17): each adds its move to the creature's deck (at a random place)
## and multiplies its HP; the creature's plate lists them (the log keeps the short name).


static func apply(state: CombatState, data: ContentData, affixes: Array[StringName]) -> void:
	var e := state.enemy
	for id: StringName in affixes:
		var a := data.affix(id)
		if a == null:
			continue
		e.affixes.append(id)
		e.moves[a.move.id] = a.move
		e.move_draw.insert(state.rng.randi_range(0, e.move_draw.size()), a.move.id)
		e.max_hp = ceili(e.max_hp * a.hp_mult)
		e.hp = e.max_hp
