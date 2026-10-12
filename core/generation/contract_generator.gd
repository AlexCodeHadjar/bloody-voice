class_name ContractGenerator
extends RefCounted
## The tavern board of a week (GDD 17.2 ContractGenerator v1): 3–5 side contracts on creatures of the district.
## Pure: the same seed, day, data and options give the same board. The caller passes what the hunter's standing
## changes (GDD 12): the creatures allowed by rank, extra known signs and the reward multiplier.


class Options:
	var monsters: Array[StringName] = []  ## creatures the board may offer
	var extra_signs: int = 0
	var reward_mult: float = 1.0


## New leaflets for the board of `day`'s week. uids start at `first_uid`.
static func generate(data: ContentData, district: StringName, day: int, rng: RandomNumberGenerator,
		first_uid: int, opts: Options) -> Array[ContractsState.Contract]:
	var c := data.balance.contracts
	var monsters := opts.monsters
	var out: Array[ContractsState.Contract] = []
	if monsters.is_empty():
		return out
	var per_type: Dictionary[StringName, int] = {}
	var per_monster: Dictionary[StringName, int] = {}
	for i: int in rng.randi_range(c.board_min, c.board_max):
		var x := ContractsState.Contract.new()
		x.uid = first_uid + i
		x.type = _pick_type(c, per_type, rng)
		x.monster = _pick_monster(monsters, per_monster, c.max_same_monster, rng)
		per_type[x.type] = per_type.get(x.type, 0) + 1
		per_monster[x.monster] = per_monster.get(x.monster, 0) + 1
		fill(x, data, district, day, rng)
		x.known_tags = _more_signs(x, data, opts.extra_signs)
		x.reward = maxi(c.reward_step, roundi(x.reward * opts.reward_mult / c.reward_step) * c.reward_step)
		out.append(x)
	return out


## Petition, known signs, last-seen zone, week, deadline and reward of a leaflet whose type and creature are set.
static func fill(x: ContractsState.Contract, data: ContentData, district: StringName, day: int,
		rng: RandomNumberGenerator) -> void:
	var c := data.balance.contracts
	var m := data.monster(x.monster)
	x.petition = _pick_petition(data, x.type, rng)
	x.known_tags = SeededRng.sample(m.tags, rng.randi_range(c.known_tags_min, c.known_tags_max), rng)
	x.zone = EncounterRules.pick_zone(data, district, rng)
	x.week = CalendarRules.week(day, data.balance)
	x.deadline_day = day + rng.randi_range(c.deadline_min, c.deadline_max)
	x.reward = reward(data, m.rank, x.type, rng)


## The leaflet's signs plus `n` more of the creature's (the Iron Vigil's dossiers).
static func _more_signs(x: ContractsState.Contract, data: ContentData, n: int) -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(x.known_tags)
	for t: StringName in data.monster(x.monster).tags:
		if n > 0 and not out.has(t):
			out.append(t)
			n -= 1
	return out


## Money for a contract: by the creature's rank, ± spread, more for a capture, rounded to reward_step.
static func reward(data: ContentData, rank: String, type: StringName, rng: RandomNumberGenerator) -> int:
	var c := data.balance.contracts
	var v := float(c.reward_by_rank.get(rank, 0)) * (1.0 + rng.randf_range(-c.reward_spread, c.reward_spread))
	if type == &"capture":
		v *= c.capture_reward_mult
	var step := maxi(c.reward_step, 1)
	return maxi(step, roundi(v / step) * step)


static func _pick_type(c: ContractDefs.Balance, per_type: Dictionary[StringName, int], rng: RandomNumberGenerator) -> StringName:
	var allowed: Dictionary[StringName, float] = {}
	for t: StringName in c.type_weights:
		if per_type.get(t, 0) < c.max_same_type:
			allowed[t] = c.type_weights[t]
	if allowed.is_empty():  # every type is at its cap: the cap gives way rather than leave the board short
		allowed = c.type_weights
	return SeededRng.weighted(allowed, rng)


static func _pick_monster(monsters: Array[StringName], per_monster: Dictionary[StringName, int], cap: int,
		rng: RandomNumberGenerator) -> StringName:
	var allowed: Array[StringName] = []
	for id: StringName in monsters:
		if per_monster.get(id, 0) < cap:
			allowed.append(id)
	if allowed.is_empty():
		allowed = monsters
	return allowed[rng.randi_range(0, allowed.size() - 1)]


static func _pick_petition(data: ContentData, type: StringName, rng: RandomNumberGenerator) -> StringName:
	var fits: Array[StringName] = []
	for p: ContractDefs.PetitionDef in data.petitions:
		if p.types.has(type):
			fits.append(p.id)
	return fits[rng.randi_range(0, fits.size() - 1)] if not fits.is_empty() else &""
