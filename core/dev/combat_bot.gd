class_name CombatBot
extends RefCounted
## A simple, honest player for balance testing (GDD 18.1 "bots test balance").
## It sees only what the real player sees: hand, ammo, visible intents, parts.


## Plays a whole fight and returns the final state.
static func run_fight(setup: CombatSetup, data: ContentData) -> CombatState:
	var s := CombatRules.start(setup, data)
	while not s.is_over():
		play_turn(s, data)
	return s


static func play_turn(s: CombatState, data: ContentData) -> void:
	for _step: int in 20:
		if s.is_over() or not _play_best(s, data):
			break
	CombatRules.end_turn(s, data)


static func _play_best(s: CombatState, data: ContentData) -> bool:
	var b := data.balance
	var playable := _playable(s)
	if playable.is_empty():
		return false
	var incoming := EnemyRules.incoming_damage(s, b)
	var free := _first(playable, func(c: CardInstance) -> bool: return c.def.cost == 0 and c.def.type != &"rage" and c.def.type != &"curse")
	if free != null:
		return _play(s, free, data)
	if s.capture_allowed and float(s.enemy.hp) / s.enemy.max_hp < 0.35:
		var net := _first(playable, func(c: CardInstance) -> bool: return c.def.type == &"capture")
		if net != null:
			return _play(s, net, data)
	if s.hero.ammo == 0 and _has_ammo_cards(s):
		var reload := _first(playable, func(c: CardInstance) -> bool: return c.def.id == &"reload")
		if reload != null:
			return _play(s, reload, data)
	if incoming - s.hero.block >= 5 and s.hero.status(&"dodge") == 0:
		var defend := _best_defense(playable, incoming - s.hero.block)
		if defend != null:
			return _play(s, defend, data)
	var attack := _best_attack(playable)
	if attack != null:
		return _play(s, attack, data)
	var other := _first(playable, func(c: CardInstance) -> bool: return c.def.type == &"support" and c.def.id != &"reload")
	return _play(s, other, data) if other != null else false


static func _play(s: CombatState, c: CardInstance, data: ContentData) -> bool:
	return CombatRules.play_card(s, c.uid, _target_for(s, c), data) == ""


static func _target_for(s: CombatState, c: CardInstance) -> CombatTarget:
	match c.def.target:
		&"enemy":
			return CombatTarget.enemy()
		&"enemy_or_part":
			var part := _part_worth_breaking(s, _damage_of(c))
			return CombatTarget.part(part) if part != &"" else CombatTarget.enemy()
	return CombatTarget.self_target()


## A part that removes a currently threatening move and can be broken soon.
static func _part_worth_breaking(s: CombatState, dmg: int) -> StringName:
	var e := s.enemy
	for id: StringName in e.part_order:
		var p: PartState = e.parts[id]
		if p.broken or p.hp > dmg * 2:
			continue
		for mv: StringName in p.def.removes:
			if e.intents.has(mv) or e.def.moves[mv].kind == &"attack":
				return id
	return &""


static func _playable(s: CombatState) -> Array[CardInstance]:
	var out: Array[CardInstance] = []
	for c: CardInstance in s.hand:
		if c.def.unplayable or c.def.type == &"curse" or c.def.cost > s.hero.ap or c.def.ammo > s.hero.ammo:
			continue
		out.append(c)
	return out


static func _best_defense(cards: Array[CardInstance], need: int) -> CardInstance:
	var best: CardInstance = null
	var best_value := 0
	for c: CardInstance in cards:
		var v := 0
		for e: Dictionary in c.def.effects:
			if StringName(str(e["op"])) == &"block":
				v += int(e["amount"])
			elif StringName(str(e["op"])) == &"apply_status" and StringName(str(e["status"])) == &"dodge":
				v += need
		if v > best_value:
			best_value = v
			best = c
	return best


static func _best_attack(cards: Array[CardInstance]) -> CardInstance:
	var best: CardInstance = null
	var best_value := 0
	for c: CardInstance in cards:
		var v := _damage_of(c)
		if v > best_value:
			best_value = v
			best = c
	return best


static func _damage_of(c: CardInstance) -> int:
	var total := 0
	for e: Dictionary in c.def.effects:
		if StringName(str(e["op"])) == &"damage":
			total += int(e["amount"]) * int(e.get("hits", 1))
	return total


static func _has_ammo_cards(s: CombatState) -> bool:
	for pile: Array[CardInstance] in [s.hand, s.draw_pile, s.discard_pile]:
		for c: CardInstance in pile:
			if c.def.ammo > 0:
				return true
	return false


static func _first(cards: Array[CardInstance], pred: Callable) -> CardInstance:
	for c: CardInstance in cards:
		if pred.call(c):
			return c
	return null
