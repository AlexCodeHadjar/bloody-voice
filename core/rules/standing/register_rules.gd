class_name RegisterRules
extends RefCounted
## The hunter's Register rank (GDD 12.1, owner 2026-10-12: it rises by an exam). The board offers creatures up to one
## rank above the hunter's; rewards grow with the rank. After exam_after[rank] finished contracts at a rank the
## Register pins an exam leaflet: slay a stronger creature of the next rank of the district before the deadline. It
## uses no contract slot; at the deadline it fails and goes, taken or not (a new one next Monday). Passing raises
## the rank.


static func rank_letter(data: ContentData, rank: int) -> String:
	var ranks := data.balance.register.ranks
	return ranks[clampi(rank, 0, ranks.size() - 1)] if not ranks.is_empty() else ""


static func rank_of(data: ContentData, letter: String) -> int:
	return data.balance.register.ranks.find(letter)


## Creatures of `district` the board may offer the hunter: up to one rank above theirs.
static func board_pool(run: RunState, data: ContentData, district: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in EncounterRules.pool(data, district):
		if rank_of(data, data.monster(id).rank) <= run.standing.rank + 1:
			out.append(id)
	return out


## Contract rewards: +reward_bonus per rank above A.
static func reward_mult(run: RunState, data: ContentData) -> float:
	return 1.0 + data.balance.register.reward_bonus * run.standing.rank


static func is_top(run: RunState, data: ContentData) -> bool:
	return run.standing.rank >= data.balance.register.ranks.size() - 1


## The rank can still rise here: not the top one, and the district has a creature of the next rank (the Grey
## Chapels have no S creature, so the slice stops at D).
static func can_advance(run: RunState, data: ContentData) -> bool:
	return not is_top(run, data) and not exam_pool(run, data).is_empty()


## Contracts still needed before the exam (0 = the exam is due, or the rank can't rise here).
static func contracts_left(run: RunState, data: ContentData) -> int:
	if not can_advance(run, data):
		return 0
	return maxi(0, data.balance.register.exam_after[run.standing.rank] - run.standing.rank_contracts)


## Creatures of the next rank in the hero's district (an exam needs one).
static func exam_pool(run: RunState, data: ContentData) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in EncounterRules.pool(data, run.hero_district):
		if rank_of(data, data.monster(id).rank) == run.standing.rank + 1:
			out.append(id)
	return out


static func open_exam(cs: ContractsState) -> ContractsState.Contract:
	for c: ContractsState.Contract in cs.items:
		if c.exam and not c.done:
			return c
	return null


## Every morning: a missed exam fails; a due one is pinned. Returns true when the board changed.
static func update(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> bool:
	var week := CalendarRules.week(run.day, data.balance)
	var exam := open_exam(run.contracts)
	if exam != null and ContractRules.is_overdue(exam, run.day):
		run.contracts.items.erase(exam)
		run.standing.exam_block_week = week
		return true
	if exam != null or not can_advance(run, data) or contracts_left(run, data) > 0 or run.standing.exam_block_week == week:
		return false
	var pool := exam_pool(run, data)
	var x := ContractsState.Contract.new()
	x.uid = run.contracts.next_uid
	run.contracts.next_uid += 1
	x.type = &"slay"
	x.monster = pool[rng.randi_range(0, pool.size() - 1)]
	ContractGenerator.fill(x, data, run.hero_district, run.day, rng)
	x.exam = true
	x.petition = &"register_exam"
	x.week = run.contracts.board_week
	x.deadline_day = run.day + data.balance.register.exam_days
	x.reward = data.balance.register.exam_reward[run.standing.rank]
	run.contracts.items.append(x)
	return true


## A finished contract: an exam raises the rank (true), any other counts toward the next exam.
static func contract_done(run: RunState, c: ContractsState.Contract) -> bool:
	if c.exam:
		run.standing.rank += 1
		run.standing.rank_contracts = 0
		return true
	run.standing.rank_contracts += 1
	return false


## XP of passing an exam with this fight (0 otherwise).
static func exam_xp(data: ContentData, c: ContractsState.Contract, outcome: StringName) -> int:
	return data.balance.register.exam_xp if c != null and c.exam and ContractRules.reward_for(c, outcome) > 0 else 0
