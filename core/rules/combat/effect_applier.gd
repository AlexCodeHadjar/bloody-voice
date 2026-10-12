class_name EffectApplier
extends RefCounted
## Runs effect ops from cards and monster moves (EffectSchema lists them; GDD 19.4 "effects as data").


static func apply(state: CombatState, effect: Dictionary, ctx: EffectContext, data: ContentData) -> void:
	if state.is_over():
		return
	var b := data.balance
	var op := StringName(str(effect.get("op", "")))
	var amount := int(effect.get("amount", 0))
	match op:
		&"damage":
			for i: int in int(effect.get("hits", 1)):
				DamageRules.deal(state, ctx.actor, ctx.opponent, amount + ctx.bonus_damage, ctx.part_id(), b)
				if ctx.opponent.is_dead():
					break
		&"block":
			ctx.actor.block += amount
			state.log_event(&"block", Loc.t("log.block", {"who": ctx.actor.display_name, "n": amount}), amount)
		&"heal":
			var before := ctx.actor.hp
			ctx.actor.hp = mini(ctx.actor.max_hp, ctx.actor.hp + amount)
			state.log_event(&"heal", Loc.t("log.heal", {"who": ctx.actor.display_name, "n": ctx.actor.hp - before}), ctx.actor.hp - before, _who(state, ctx.actor))
		&"lose_hp":
			var cost := GearEffectRules.hp_cost(state, ctx, amount)
			ctx.actor.hp -= cost
			state.log_event(&"lose_hp", Loc.t("log.lose_hp", {"who": ctx.actor.display_name, "n": cost}), cost, _who(state, ctx.actor))
		&"sanity":
			_sanity(state, amount, data)
		&"draw":
			DeckRules.draw(state, amount, b)
		&"gain_ap":
			state.hero.ap += amount
		&"reload":
			state.hero.ammo = state.hero.max_ammo
			state.log_event(&"reload", Loc.t("log.reload"))
			DeckRules.draw(state, state.hero.mod(&"reload_draw"), b)
		&"foresight":
			state.foresight = true
		&"apply_status":
			_status(state, effect, ctx)
		&"add_card":
			var def := data.card(StringName(str(effect["card"])))
			DeckRules.add_cards(state, def, StringName(str(effect.get("pile", "discard"))), int(effect.get("count", 1)))
			state.log_event(&"add_card", Loc.t("log.add_card", {"card": def.name}))
		&"capture":
			_capture(state, float(effect["chance"]), b)
		_:
			push_error("Unknown effect op: %s" % op)  # the validator rejects these at start-up
	CombatRules.check_end(state)


static func _status(state: CombatState, effect: Dictionary, ctx: EffectContext) -> void:
	var who := ctx.actor if str(effect.get("to", "target")) == "self" else ctx.opponent
	var status := StringName(str(effect["status"]))
	var stacks := GearEffectRules.status_stacks(state, ctx, status, int(effect["stacks"]))
	who.add_status(status, stacks)
	state.log_event(&"status", Loc.t("log.status", {"who": who.display_name, "status": EffectText.status_name(status), "n": stacks}), stacks)


static func _who(state: CombatState, c: Combatant) -> StringName:
	return &"hero" if c == state.hero else &"enemy"


static func _sanity(state: CombatState, amount: int, data: ContentData) -> void:
	var h := state.hero
	h.sanity = maxi(0, h.sanity - amount)
	state.log_event(&"sanity", Loc.t("log.sanity", {"n": amount}), amount, &"hero")
	if h.sanity == 0 and not h.panicked:
		h.panicked = true
		state.log_event(&"panic", Loc.t("log.panic"))
		DeckRules.add_cards(state, data.card(data.balance.panic_card), &"hand", 1)


static func _capture(state: CombatState, base: float, b: BalanceDef) -> void:
	if not state.capture_allowed:
		state.log_event(&"capture", Loc.t("log.no_capture"))
		return
	var e := state.enemy
	var chance := CaptureRules.chance(base, e.hp, e.max_hp, state.hero.cunning, e.broken_parts(), b)
	if CaptureRules.roll(state.rng, chance):
		state.captured = true
		state.phase = CombatState.Phase.WON
		state.log_event(&"captured", Loc.t("log.captured", {"enemy": e.display_name, "chance": int(chance * 100)}))
	else:
		e.add_status(&"enraged", 1)
		state.log_event(&"capture_failed", Loc.t("log.capture_failed", {"chance": int(chance * 100)}))
