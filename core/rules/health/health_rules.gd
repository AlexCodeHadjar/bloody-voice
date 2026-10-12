class_name HealthRules
extends RefCounted
## Health between fights (GDD 4, owner 2026-10-12): HP and Sanity carry over. Rest at the garret restores a third;
## the Ash Sisters heal fully for a day and money; at 0 HP the hunter falls and wakes in their infirmary, healed,
## with the fee taken even into debt (the fight's loot is lost — LootRules gives none on a loss).


## Base + per level + skill web + gear (GDD 4.2).
static func max_hp(run: RunState, data: ContentData) -> int:
	var levels := data.balance.hp_per_level * (run.progress.level - 1)
	var skills := int(SkillRules.mods(run, data).get(&"max_hp", 0))
	return data.balance.base_hp + levels + skills + DeckBuilder.max_hp_bonus(run.loadout, data)


## Base + 4 per Will (GDD 4.2).
static func max_sanity(run: RunState, data: ContentData) -> int:
	return data.balance.base_sanity + data.balance.progress.sanity_per_will * run.progress.attribute(&"will")


static func hp(run: RunState, data: ContentData) -> int:
	var top := max_hp(run, data)
	return top if run.hero_hp < 0 else mini(run.hero_hp, top)


static func sanity(run: RunState, data: ContentData) -> int:
	var top := max_sanity(run, data)
	return top if run.hero_sanity < 0 else mini(run.hero_sanity, top)


## Rest at the garret (the caller ends the day): a third of each back; the Voice drops a little.
static func rest(run: RunState, data: ContentData) -> void:
	var share := data.balance.health.rest_share
	run.hero_hp = mini(max_hp(run, data), hp(run, data) + ceili(max_hp(run, data) * share))
	run.hero_sanity = mini(max_sanity(run, data), sanity(run, data) + ceili(max_sanity(run, data) * share))
	VoiceRules.lower(run, data.balance.voice.rest_voice)  # sleep quiets the blood a little


## The infirmary's price for what is missing; the Grey Communion's standing (GDD 12) and the district state change it.
static func treat_cost(run: RunState, data: ContentData) -> int:
	var h := data.balance.health
	var missing_hp := max_hp(run, data) - hp(run, data)
	var missing_sanity := max_sanity(run, data) - sanity(run, data)
	var base := h.treat_base + h.treat_per_hp * missing_hp + h.treat_per_sanity * missing_sanity
	var mult := FactionRules.mult(run, data, &"infirmary_mult") * EventRules.state_def(run, data).infirmary_mult
	return maxi(1, roundi(base * mult))


## "" or why the sisters won't treat now.
static func can_treat(run: RunState, data: ContentData) -> String:
	if hp(run, data) >= max_hp(run, data) and sanity(run, data) >= max_sanity(run, data):
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
