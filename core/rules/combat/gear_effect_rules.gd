class_name GearEffectRules
extends RefCounted
## How passive gear mods (GearMods) act during a fight. Called by CombatRules and EffectApplier.


## Extra AP, cards and foresight on the first turn.
static func first_turn(s: CombatState) -> void:
	var h := s.hero
	h.ap += h.mod(&"first_turn_ap")
	if h.mod(&"foresight_start") > 0:
		s.foresight = true


static func extra_first_draw(s: CombatState) -> int:
	return s.hero.mod(&"first_turn_draw") if s.turn == 1 else 0


## Bonus damage for every hit of a hunter card: shots get shot_damage, shots at body parts also part_damage.
static func bonus_damage(s: CombatState, card: CardDef, target: CombatTarget) -> int:
	if card.ammo <= 0:
		return 0
	var bonus := s.hero.mod(&"shot_damage")
	if target.kind == CombatTarget.PART:
		bonus += s.hero.mod(&"part_damage")
	return bonus


## After a card that uses ammo resolved: block and bleed from the gear.
static func after_shot(s: CombatState, card: CardDef) -> void:
	if card.ammo <= 0 or s.is_over():
		return
	var h := s.hero
	var block := h.mod(&"shot_block")
	if block > 0:
		h.block += block
		s.log_event(&"block", "The recoil spring braces you: block %d." % block, block)
	var bleed := h.mod(&"shot_bleed")
	if bleed > 0:
		var stacks := bleed + h.mod(&"bleed_bonus")
		s.enemy.add_status(&"bleed", stacks)
		s.log_event(&"status", "%s: Bleed %d." % [s.enemy.display_name, stacks], stacks)


## Bleed applied by the hunter is stronger with bleed_bonus.
static func status_stacks(s: CombatState, ctx: EffectContext, status: StringName, stacks: int) -> int:
	if ctx.actor_is_hero and status == &"bleed" and ctx.actor != ctx.opponent:
		return stacks + s.hero.mod(&"bleed_bonus")
	return stacks


## HP cost of Rage cards is lowered by rage_hp_discount.
static func hp_cost(s: CombatState, ctx: EffectContext, amount: int) -> int:
	if ctx.actor_is_hero and ctx.card != null and ctx.card.type == &"rage":
		return maxi(0, amount - s.hero.mod(&"rage_hp_discount"))
	return amount
