class_name HealthRules
extends RefCounted
## Health between fights (GDD 4, owner 2026-10-12): HP and Sanity carry over. Rest at the garret restores a third;
## the Ash Sisters heal fully for a day and money; at 0 HP the hunter falls and wakes in their infirmary, healed,
## with the fee taken even into debt (the fight's loot is lost — LootRules gives none on a loss).


static func max_hp(run: RunState, data: ContentData) -> int:
	return data.balance.base_hp + int(DeckBuilder.build(run.loadout, data).mods.get(&"max_hp", 0))


static func max_sanity(data: ContentData) -> int:
	return data.balance.base_sanity


static func hp(run: RunState, data: ContentData) -> int:
	var top := max_hp(run, data)
	return top if run.hero_hp < 0 else mini(run.hero_hp, top)


static func sanity(run: RunState, data: ContentData) -> int:
	var top := max_sanity(data)
	return top if run.hero_sanity < 0 else mini(run.hero_sanity, top)


## Rest at the garret (the caller ends the day): a third of each back.
static func rest(run: RunState, data: ContentData) -> void:
	var share := data.balance.health.rest_share
	run.hero_hp = mini(max_hp(run, data), hp(run, data) + ceili(max_hp(run, data) * share))
	run.hero_sanity = mini(max_sanity(data), sanity(run, data) + ceili(max_sanity(data) * share))


## The infirmary's price for what is missing.
static func treat_cost(run: RunState, data: ContentData) -> int:
	var h := data.balance.health
	var missing_hp := max_hp(run, data) - hp(run, data)
	var missing_sanity := max_sanity(data) - sanity(run, data)
	return h.treat_base + h.treat_per_hp * missing_hp + h.treat_per_sanity * missing_sanity


## "" or why the sisters won't treat now.
static func can_treat(run: RunState, data: ContentData) -> String:
	if hp(run, data) >= max_hp(run, data) and sanity(run, data) >= max_sanity(data):
		return Loc.t("rule.health.healthy")
	if run.money < treat_cost(run, data):
		return Loc.t("rule.health.no_money")
	return ""


## Full treatment (the caller ends the day).
static func treat(run: RunState, data: ContentData) -> String:
	var problem := can_treat(run, data)
	if problem == "":
		run.money -= treat_cost(run, data)
		heal_fully(run)
	return problem


static func heal_fully(run: RunState) -> void:
	run.hero_hp = -1
	run.hero_sanity = -1


## What the fight left of the hunter.
static func after_fight(run: RunState, s: CombatState) -> void:
	run.hero_hp = maxi(0, s.hero.hp)
	run.hero_sanity = maxi(0, s.hero.sanity)


## The Hunter's Fall: the sisters take the fee (even into debt) and heal; returns the fee. The caller ends two days.
static func fall(run: RunState, data: ContentData) -> int:
	var fee := data.balance.health.fall_fee
	run.money -= fee
	heal_fully(run)
	return fee
