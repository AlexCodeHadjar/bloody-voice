class_name EnemyRules
extends RefCounted
## The creature's side: move deck, visible intents, its turn, broken parts and phases (GDD 9.4).


static func setup(state: CombatState, def: MonsterDef) -> void:
	var e := state.enemy
	e.def = def
	e.display_name = def.name
	e.hp = def.hp
	e.max_hp = def.hp
	for p: MonsterDef.PartDef in def.parts:
		e.parts[p.id] = PartState.create(p)
		e.part_order.append(p.id)
	e.move_draw = def.deck.duplicate()
	_shuffle(state, e.move_draw)


## Reveal the moves the creature will make at the end of the hunter's turn.
static func reveal_intents(state: CombatState) -> void:
	var e := state.enemy
	e.intents.clear()
	for i: int in e.def.intents_per_turn:
		e.intents.append(_draw_move(state))


## Upcoming moves after the current intents (for Foresight). May be shorter than n.
static func peek(state: CombatState, n: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var e := state.enemy
	for i: int in range(e.move_draw.size() - 1, -1, -1):
		if out.size() >= n:
			break
		if e.move_available(e.move_draw[i]):
			out.append(e.move_draw[i])
	return out


static func run_turn(state: CombatState, data: ContentData) -> void:
	var e := state.enemy
	StatusRules.turn_start(state, e)
	if e.is_dead():
		return
	for move_id: StringName in e.intents:
		var move: MonsterDef.MoveDef = e.def.moves[move_id]
		if not e.move_available(move_id):
			state.log_event(&"cancelled", "%s can no longer %s." % [e.display_name, move.name], 0, move_id)
			continue
		state.log_event(&"intent", "%s: %s." % [e.display_name, move.name], 0, move_id)
		var ctx := EffectContext.create(e, state.hero, CombatTarget.self_target(), false)
		for effect: Dictionary in move.effects:
			EffectApplier.apply(state, effect, ctx, data)
		e.move_discard.append(move_id)
		if state.hero.is_dead() or e.is_dead():
			return
	e.intents.clear()
	StatusRules.turn_end(e)


static func break_part(state: CombatState, part_id: StringName) -> void:
	var e := state.enemy
	var part: PartState = e.parts[part_id]
	part.broken = true
	part.hp = 0
	for mv: StringName in part.def.removes:
		e.removed_moves[mv] = true
	if part.def.trophy != &"":
		state.trophies.append(part.def.trophy)
	state.log_event(&"part_broken", "%s is broken!" % part.def.name, 0, part_id)


static func check_phase(state: CombatState) -> void:
	var e := state.enemy
	var phases := sorted_phases(e.def)
	while e.next_phase < phases.size() and e.hp > 0 and e.hp <= int(e.max_hp * phases[e.next_phase].below):
		var ph := phases[e.next_phase]
		e.next_phase += 1
		for mv: StringName in ph.remove:
			e.removed_moves[mv] = true
		for mv: StringName in ph.add:
			e.move_draw.append(mv)
		_shuffle(state, e.move_draw)
		state.log_event(&"phase", "%s — %s." % [e.display_name, ph.name])


static func sorted_phases(def: MonsterDef) -> Array[MonsterDef.PhaseDef]:
	var out := def.phases.duplicate()
	out.sort_custom(func(a: MonsterDef.PhaseDef, b: MonsterDef.PhaseDef) -> bool: return a.below > b.below)
	return out


## Expected damage of the visible intents against the hunter (used by the bot and UI hints).
static func incoming_damage(state: CombatState, b: BalanceDef) -> int:
	var total := 0
	var e := state.enemy
	for move_id: StringName in e.intents:
		if not e.move_available(move_id):
			continue
		for effect: Dictionary in e.def.moves[move_id].effects:
			if StringName(str(effect["op"])) == &"damage":
				var hits := int(effect.get("hits", 1))
				total += DamageRules.compute(int(effect["amount"]), e, state.hero, b) * hits
	return total


static func _draw_move(state: CombatState) -> StringName:
	var e := state.enemy
	for _attempt: int in 64:
		if e.move_draw.is_empty():
			e.move_draw = e.move_discard
			e.move_discard = []
			_shuffle(state, e.move_draw)
			if e.move_draw.is_empty():
				break
		var mv: StringName = e.move_draw.pop_back()
		if e.move_available(mv):
			return mv
	return _fallback_move(e)


static func _fallback_move(e: EnemyCombatant) -> StringName:
	for mv: StringName in e.def.deck:
		if e.move_available(mv):
			return mv
	return e.def.deck[0]


static func _shuffle(state: CombatState, pile: Array[StringName]) -> void:
	for i: int in range(pile.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp := pile[i]
		pile[i] = pile[j]
		pile[j] = tmp
