class_name ProgressRules
extends RefCounted
## The hunter's growth (GDD 4.1–4.3, owner 2026-10-12): XP for won fights, finished contracts and discoveries;
## levels give skill points, attribute points and max HP; what Will, Agility and Cunning do.


class Report:
	var xp: int = 0
	var levels: int = 0  ## levels gained
	var skill_points: int = 0
	var attribute_points: int = 0


## A run without attributes yet (a new game, an old save) gets the start ones.
static func ensure_start(run: RunState, data: ContentData) -> bool:
	if run.progress.started:
		return false
	run.progress.attributes = data.balance.progress.start_attributes.duplicate()
	run.progress.started = true
	return true


static func xp_to_next(data: ContentData, level: int) -> int:
	var p := data.balance.progress
	return p.xp_base + p.xp_per_level * level


## XP of a won fight: by the creature's rank, more for a capture. 0 for a loss.
static func fight_xp(data: ContentData, s: CombatState) -> int:
	var outcome := s.outcome()
	if outcome != &"slain" and outcome != &"captured":
		return 0
	var p := data.balance.progress
	var xp := float(p.xp_by_rank.get(s.enemy.def.rank, 0))
	return roundi(xp * p.capture_xp_mult) if outcome == &"captured" else roundi(xp)


## Adds XP and levels up as often as it reaches; returns what was gained. At the level cap XP is not kept.
static func add_xp(run: RunState, data: ContentData, amount: int) -> Report:
	var p := data.balance.progress
	var pr := run.progress
	var r := Report.new()
	if amount <= 0 or pr.level >= p.level_cap:
		return r
	r.xp = amount
	pr.xp += amount
	while pr.level < p.level_cap and pr.xp >= xp_to_next(data, pr.level):
		pr.xp -= xp_to_next(data, pr.level)
		_level_up(run, data, r)
	if pr.level >= p.level_cap:
		pr.xp = 0
	return r


## How many levels `amount` XP would give now (for the result panel before the XP is taken).
static func levels_from(run: RunState, data: ContentData, amount: int) -> int:
	var copy := RunState.new()
	copy.progress = ProgressState.from_dict(run.progress.to_dict())
	return add_xp(copy, data, amount).levels


static func _level_up(run: RunState, data: ContentData, r: Report) -> void:
	var p := data.balance.progress
	var pr := run.progress
	pr.level += 1
	r.levels += 1
	var points := p.skill_points_per_level + (1 if p.bonus_point_levels.has(pr.level) else 0)
	pr.skill_points += points
	r.skill_points += points
	if p.attribute_point_every > 0 and pr.level % p.attribute_point_every == 0:
		pr.attribute_points += 1
		r.attribute_points += 1
	if run.hero_hp >= 0:  # wounded: the new max HP adds to the current HP too
		run.hero_hp += data.balance.hp_per_level


## Spends an attribute point. "" or why not.
static func raise(run: RunState, data: ContentData, attribute: StringName) -> String:
	if not ProgressDefs.ATTRIBUTES.has(attribute):
		return Loc.t("rule.progress.unknown")
	if run.progress.attribute_points <= 0:
		return Loc.t("rule.progress.no_points")
	run.progress.attribute_points -= 1
	run.progress.attributes[attribute] = run.progress.attribute(attribute) + 1
	if attribute == &"will" and run.hero_sanity >= 0:
		run.hero_sanity += data.balance.progress.sanity_per_will
	return ""


## Agility: cards in hand added (one per threshold reached).
static func hand_bonus(run: RunState, data: ContentData) -> int:
	return _reached(data.balance.progress.agility_hand_at, run.progress.attribute(&"agility"))


## Cunning: creature moves always visible ahead.
static func preview(run: RunState, data: ContentData) -> int:
	return _reached(data.balance.progress.cunning_preview_at, run.progress.attribute(&"cunning"))


## Cunning: the shop's discount, 0..max_discount.
static func discount(run: RunState, data: ContentData) -> float:
	var p := data.balance.progress
	return minf(p.max_discount, p.discount_per_cunning * run.progress.attribute(&"cunning"))


## Cunning: the hunter senses that a rumor card is wrong («Чутьё: слух сомнительный»). Never on a right one;
## stable per card (seeded).
static func suspicious(run: RunState, data: ContentData, h: RumorsState.Card) -> bool:
	if h.right():
		return false
	var chance := data.balance.progress.flag_per_cunning * run.progress.attribute(&"cunning")
	return SeededRng.make_stream(run.master_seed, StringName("flag_%d" % h.uid)).randf() < chance


static func _reached(thresholds: Array[int], value: int) -> int:
	var n := 0
	for t: int in thresholds:
		n += 1 if value >= t else 0
	return n
