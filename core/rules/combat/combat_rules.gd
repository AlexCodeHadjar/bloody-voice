class_name CombatRules
extends RefCounted
## The fight's flow (GDD 9): start, play a card, end the turn, win / lose.
## Pure: works on a CombatState and content; never touches nodes or autoloads.


static func start(setup: CombatSetup, data: ContentData) -> CombatState:
	var s := CombatState.new()
	s.rng.seed = setup.rng_seed
	s.capture_allowed = setup.capture_allowed
	var h := s.hero
	h.display_name = Loc.t("log.hunter_name")
	h.hp = setup.hero_hp
	h.max_hp = setup.hero_max_hp
	h.sanity = setup.max_sanity
	h.max_sanity = setup.max_sanity
	h.max_ap = setup.max_ap
	h.hand_size = setup.hand_size
	h.max_ammo = setup.max_ammo
	h.ammo = setup.max_ammo
	h.cunning = setup.cunning
	h.mods = setup.mods.duplicate()
	EnemyRules.setup(s, data.monster(setup.monster_id))
	DeckRules.build(s, setup.deck, data)
	s.log_event(&"start", Loc.t("log.start", {"enemy": s.enemy.display_name}))
	_start_player_turn(s, data)
	return s


## "" if the card can be played on that target, otherwise the reason (shown to the player).
static func can_play(s: CombatState, card: CardInstance, target: CombatTarget) -> String:
	if s.phase != CombatState.Phase.PLAYER:
		return Loc.t("rule.not_your_turn")
	if card == null or not s.hand.has(card):
		return Loc.t("rule.not_in_hand")
	var def := card.def
	if def.unplayable or def.target == &"none":
		return Loc.t("rule.card_unplayable", {"card": def.name})
	if def.cost > s.hero.ap:
		return Loc.t("rule.no_ap")
	if def.ammo > s.hero.ammo:
		return Loc.t("rule.no_ammo")
	return _target_problem(s, def, target)


static func play_card(s: CombatState, uid: int, target: CombatTarget, data: ContentData) -> String:
	var card := s.find_in_hand(uid)
	var problem := can_play(s, card, target)
	if problem != "":
		return problem
	var def := card.def
	s.hero.ap -= def.cost
	s.hero.ammo -= def.ammo
	s.hand.erase(card)
	s.log_event(&"play", Loc.t("log.play", {"card": def.name}), 0, def.id)
	var ctx := EffectContext.create(s.hero, s.enemy, target, true)
	ctx.card = def
	ctx.bonus_damage = GearEffectRules.bonus_damage(s, def, target)
	for effect: Dictionary in def.effects:
		EffectApplier.apply(s, effect, ctx, data)
	GearEffectRules.after_shot(s, def)
	if def.exhaust:
		s.exhaust_pile.append(card)
	else:
		s.discard_pile.append(card)
	check_end(s)
	return ""


static func end_turn(s: CombatState, data: ContentData) -> void:
	if s.phase != CombatState.Phase.PLAYER:
		return
	DeckRules.discard_hand(s)
	StatusRules.turn_end(s.hero)
	s.phase = CombatState.Phase.ENEMY
	EnemyRules.run_turn(s, data)
	check_end(s)
	if not s.is_over():
		_start_player_turn(s, data)


static func check_end(s: CombatState) -> void:
	if s.is_over():
		return
	if s.enemy.is_dead():
		s.phase = CombatState.Phase.WON
		s.log_event(&"won", Loc.t("log.won", {"enemy": s.enemy.display_name}))
	elif s.hero.is_dead():
		s.phase = CombatState.Phase.LOST
		s.log_event(&"lost", Loc.t("log.lost"))


static func _start_player_turn(s: CombatState, data: ContentData) -> void:
	s.turn += 1
	if s.turn > data.balance.turn_limit:
		s.escaped = true
		s.phase = CombatState.Phase.LOST
		s.log_event(&"escaped", Loc.t("log.escaped", {"enemy": s.enemy.display_name}))
		return
	s.phase = CombatState.Phase.PLAYER
	StatusRules.turn_start(s, s.hero)
	check_end(s)
	if s.is_over():
		return
	s.hero.ap = s.hero.max_ap
	s.foresight = false
	if s.hero.panicked:
		DeckRules.add_cards(s, data.card(data.balance.panic_card), &"hand", 1)
	DeckRules.draw(s, s.hero.hand_size + GearEffectRules.extra_first_draw(s), data.balance)
	if s.turn == 1:
		GearEffectRules.first_turn(s)
	EnemyRules.reveal_intents(s)


static func _target_problem(s: CombatState, def: CardDef, target: CombatTarget) -> String:
	match def.target:
		&"self":
			return "" if target.kind == CombatTarget.SELF else Loc.t("rule.on_self")
		&"enemy":
			return "" if target.kind == CombatTarget.ENEMY else Loc.t("rule.aim_creature")
		&"enemy_or_part":
			if target.kind == CombatTarget.ENEMY:
				return ""
			if target.kind == CombatTarget.PART:
				var part: PartState = s.enemy.parts.get(target.part_id)
				if part == null:
					return Loc.t("rule.no_part")
				return Loc.t("rule.part_broken") if part.broken else ""
			return Loc.t("rule.aim")
	return Loc.t("rule.unplayable")
