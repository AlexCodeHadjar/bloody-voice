class_name VoiceRules
extends RefCounted
## The Voice (GDD 4.2, 4.4; owner 2026-10-12): Monster-web formulas raise it; stages at 10 / 20 / 30 (+3 per Will).
## 1 Whispers: a rage card in every fight. 2 Hunger: an attack card in hand may play itself at the turn's start.
## 3 The Beast: the Beast Form card, and after a fight a chance to lose control (a day passes). Rest and the
## infirmary's «calm the blood» lower it.


static func thresholds(run: RunState, data: ContentData) -> Array[int]:
	var v := data.balance.voice
	var out: Array[int] = []
	for t: int in v.stages:
		out.append(t + v.per_will * run.progress.attribute(&"will"))
	return out


## 0 (silent) .. 3 (the Beast) for a Voice of `voice` (the run's own by default).
static func stage(run: RunState, data: ContentData, voice: int = -1) -> int:
	var value := run.voice if voice < 0 else voice
	var n := 0
	for t: int in thresholds(run, data):
		n += 1 if value >= t else 0
	return n


## Cards the stages add to a fight's deck.
static func fight_cards(run: RunState, data: ContentData) -> Array[StringName]:
	var v := data.balance.voice
	var out: Array[StringName] = []
	var s := stage(run, data)
	if s >= 1:
		out.append(v.rage_card)
	if s >= 3:
		out.append(v.beast_card)
	return out


static func hunger_chance(run: RunState, data: ContentData) -> float:
	return data.balance.voice.hunger_chance if stage(run, data) >= 2 else 0.0


## After a won fight (slain or captured, owner 2026-10-12) at stage 3: does the hunter lose control? (rolled on the
## given stream)
static func loses_control(run: RunState, data: ContentData, rng: RandomNumberGenerator, outcome: StringName) -> bool:
	if not (outcome in [&"slain", &"captured"]):
		return false
	return stage(run, data) >= 3 and rng.randf() < data.balance.voice.lose_control_chance


const BEAST_OUTCOMES: Array[StringName] = [&"money", &"seen", &"wounded", &"fed"]


## What the Beast did when it took over (owner 2026-10-12: a random consequence and a note): money gone, the Vigil saw
## it, wounds, or it fed and the blood quiets. Applies it and leaves the morning note; returns the outcome.
static func beast_night(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> StringName:
	var v := data.balance.voice
	if v.beast_outcomes.is_empty():
		return &""
	var what := SeededRng.weighted(v.beast_outcomes, rng)
	match what:
		&"money":
			run.money -= maxi(0, floori(run.money * v.beast_money_share))
		&"seen":
			var seen: Dictionary[StringName, int] = {&"vigil": v.beast_rep}
			FactionRules.apply(run, seen)
		&"wounded":
			run.hero_hp = maxi(1, HealthRules.hp(run, data) - ceili(HealthRules.max_hp(run, data) * v.beast_hp_share))
		&"fed":
			lower(run, v.beast_fed_voice)
	run.story.letters.insert(0, "beast:%s" % what)  # first: not stuck behind a note waiting for a choice
	return what


static func lower(run: RunState, amount: int) -> void:
	run.voice = maxi(0, run.voice - amount)


## The sisters' price for calming the blood; the Grey Communion's standing and the district state change it.
static func calm_cost(run: RunState, data: ContentData) -> int:
	var mult := FactionRules.mult(run, data, &"infirmary_mult") * EventRules.state_def(run, data).infirmary_mult
	return maxi(1, roundi(data.balance.voice.calm_cost * mult))


## "" or why the sisters can't calm the blood now (no credit).
static func can_calm(run: RunState, data: ContentData) -> String:
	if run.voice <= 0:
		return Loc.t("rule.voice.silent")
	if run.money < calm_cost(run, data):
		return Loc.t("rule.voice.no_money")
	return ""


## The infirmary's «calm the blood» (the caller ends the day).
static func calm(run: RunState, data: ContentData) -> String:
	var problem := can_calm(run, data)
	if problem == "":
		run.money -= calm_cost(run, data)
		lower(run, data.balance.voice.calm_voice)
	return problem


## Hunger in a fight (stage 2+): at the start of the hunter's turn an attack card in hand may play itself at the
## creature, for free. Called by CombatRules after the draw.
static func hunger(s: CombatState, data: ContentData) -> void:
	if s.hunger_chance <= 0.0 or s.is_over() or s.rng.randf() >= s.hunger_chance:
		return
	var hungry: Array[CardInstance] = []
	for c: CardInstance in s.hand:
		if c.def.type == &"attack" and c.def.needs_enemy_target() and c.def.ammo <= s.hero.ammo:
			hungry.append(c)
	if hungry.is_empty():
		return
	var card := hungry[s.rng.randi_range(0, hungry.size() - 1)]
	s.log_event(&"hunger", Loc.t("log.hunger", {"card": card.def.name}))
	s.hero.ap += card.def.cost  # the Voice pays for it
	if CombatRules.play_card(s, card.uid, CombatTarget.enemy(), data) != "":
		s.hero.ap -= card.def.cost  # refused (e.g. panic): no free AP left behind
