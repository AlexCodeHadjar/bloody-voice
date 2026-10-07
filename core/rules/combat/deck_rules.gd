class_name DeckRules
extends RefCounted
## The hunter's piles: draw (always shuffled), hand, discard, exhaust (GDD 9.2).


static func build(state: CombatState, deck: Array[StringName], data: ContentData) -> void:
	for id: StringName in deck:
		state.draw_pile.append(new_card(state, data.card(id)))
	shuffle(state, state.draw_pile)


static func new_card(state: CombatState, def: CardDef) -> CardInstance:
	var c := CardInstance.create(state.next_uid, def)
	state.next_uid += 1
	return c


## Fisher–Yates with the fight's own rng (deterministic per seed).
static func shuffle(state: CombatState, pile: Array[CardInstance]) -> void:
	for i: int in range(pile.size() - 1, 0, -1):
		var j := state.rng.randi_range(0, i)
		var tmp := pile[i]
		pile[i] = pile[j]
		pile[j] = tmp


static func draw(state: CombatState, count: int, b: BalanceDef) -> int:
	var drawn := 0
	for i: int in count:
		if state.draw_pile.is_empty():
			if state.discard_pile.is_empty():
				break
			state.draw_pile = state.discard_pile
			state.discard_pile = []
			shuffle(state, state.draw_pile)
			state.log_event(&"shuffle", "The discard pile is shuffled into the draw pile.")
		var card: CardInstance = state.draw_pile.pop_back()
		if state.hand.size() >= b.max_hand:
			state.discard_pile.append(card)
		else:
			state.hand.append(card)
		drawn += 1
	return drawn


## End of turn: everything without Retain goes to the discard pile.
static func discard_hand(state: CombatState) -> void:
	var kept: Array[CardInstance] = []
	for c: CardInstance in state.hand:
		if c.def.retain:
			kept.append(c)
		else:
			state.discard_pile.append(c)
	state.hand = kept


static func add_cards(state: CombatState, def: CardDef, pile: StringName, count: int) -> void:
	for i: int in count:
		var c := new_card(state, def)
		match pile:
			&"hand":
				state.hand.append(c)
			&"draw":
				state.draw_pile.insert(state.rng.randi_range(0, state.draw_pile.size()), c)
			_:
				state.discard_pile.append(c)
