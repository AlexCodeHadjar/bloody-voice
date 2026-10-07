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
				DamageRules.deal(state, ctx.actor, ctx.opponent, amount, ctx.part_id(), b)
				if ctx.opponent.is_dead():
					break
		&"block":
			ctx.actor.block += amount
			state.log_event(&"block", "%s gains %d block." % [ctx.actor.display_name, amount], amount)
		&"heal":
			var before := ctx.actor.hp
			ctx.actor.hp = mini(ctx.actor.max_hp, ctx.actor.hp + amount)
			state.log_event(&"heal", "%s heals %d." % [ctx.actor.display_name, ctx.actor.hp - before], ctx.actor.hp - before)
		&"lose_hp":
			ctx.actor.hp -= amount
			state.log_event(&"lose_hp", "%s loses %d HP." % [ctx.actor.display_name, amount], amount)
		&"sanity":
			_sanity(state, amount, data)
		&"draw":
			DeckRules.draw(state, amount, b)
		&"gain_ap":
			state.hero.ap += amount
		&"reload":
			state.hero.ammo = state.hero.max_ammo
			state.log_event(&"reload", "Reloaded.")
		&"foresight":
			state.foresight = true
		&"apply_status":
			_status(state, effect, ctx)
		&"add_card":
			var def := data.card(StringName(str(effect["card"])))
			DeckRules.add_cards(state, def, StringName(str(effect.get("pile", "discard"))), int(effect.get("count", 1)))
			state.log_event(&"add_card", "%s is added to your deck." % def.name)
		&"capture":
			_capture(state, float(effect["chance"]), b)
		_:
			push_error("Unknown effect op: %s" % op)  # the validator rejects these at start-up
	CombatRules.check_end(state)


static func _status(state: CombatState, effect: Dictionary, ctx: EffectContext) -> void:
	var who := ctx.actor if str(effect.get("to", "target")) == "self" else ctx.opponent
	var status := StringName(str(effect["status"]))
	var stacks := int(effect["stacks"])
	who.add_status(status, stacks)
	state.log_event(&"status", "%s: %s %d." % [who.display_name, String(status).capitalize(), stacks], stacks)


static func _sanity(state: CombatState, amount: int, data: ContentData) -> void:
	var h := state.hero
	h.sanity = maxi(0, h.sanity - amount)
	state.log_event(&"sanity", "Sanity −%d." % amount, amount, &"hero")
	if h.sanity == 0 and not h.panicked:
		h.panicked = true
		state.log_event(&"panic", "Your hands shake — panic!")
		DeckRules.add_cards(state, data.card(data.balance.panic_card), &"hand", 1)


static func _capture(state: CombatState, base: float, b: BalanceDef) -> void:
	if not state.capture_allowed:
		state.log_event(&"capture", "Nothing to bind it with here.")
		return
	var e := state.enemy
	var chance := CaptureRules.chance(base, e.hp, e.max_hp, state.hero.cunning, e.broken_parts(), b)
	if CaptureRules.roll(state.rng, chance):
		state.captured = true
		state.phase = CombatState.Phase.WON
		state.log_event(&"captured", "%s is captured! (%d%%)" % [e.display_name, int(chance * 100)])
	else:
		e.add_status(&"enraged", 1)
		state.log_event(&"capture_failed", "The net slips (%d%%). It is enraged." % int(chance * 100))
