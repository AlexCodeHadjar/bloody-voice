class_name ContractRules
extends RefCounted
## Tavern contracts (GDD 7): a new board every Monday, accepting a leaflet, deadlines, the fight that finishes a
## contract and its reward. An overdue contract stays, but its creature is stronger and the reward does not grow
## (owner, 2026-10-12).


## Fills the board for the week of run.day unless it is already filled. Leaflets nobody took and finished
## contracts go; accepted ones stay. Returns true when the board changed.
static func refresh_board(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> bool:
	var cs := run.contracts
	var week := CalendarRules.week(run.day, data.balance)
	if cs.board_week == week:
		return false
	var kept: Array[ContractsState.Contract] = []
	for c: ContractsState.Contract in cs.items:
		if c.accepted and not c.done:
			kept.append(c)
	var opts := ContractGenerator.Options.new()  # the hunter's standing (GDD 12): rank, Vigil dossiers, rewards
	opts.monsters = RegisterRules.board_pool(run, data, run.hero_district)
	opts.extra_signs = FactionRules.bonus(run, data, &"extra_signs")
	opts.threat = AffixGenerator.threat(run, data)
	opts.reward_mult = RegisterRules.reward_mult(run, data) * FactionRules.mult(run, data, &"reward_mult") \
		* EventRules.state_def(run, data).contract_reward_mult  # dangerous days pay more (GDD 14)
	var fresh := ContractGenerator.generate(data, run.hero_district, run.day, rng, cs.next_uid, opts)
	cs.next_uid += fresh.size()
	kept.append_array(fresh)
	cs.items = kept
	cs.board_week = week
	return true


## This week's leaflets, in board order (taken ones keep their place with a seal).
static func board(cs: ContractsState) -> Array[ContractsState.Contract]:
	var out: Array[ContractsState.Contract] = []
	for c: ContractsState.Contract in cs.items:
		if c.week == cs.board_week:
			out.append(c)
	return out


## Contracts the hunter has taken and not finished, the nearest deadline first.
static func active(cs: ContractsState) -> Array[ContractsState.Contract]:
	var out: Array[ContractsState.Contract] = []
	for c: ContractsState.Contract in cs.items:
		if c.accepted and not c.done:
			out.append(c)
	out.sort_custom(func(a: ContractsState.Contract, b: ContractsState.Contract) -> bool: return a.deadline_day < b.deadline_day)
	return out


## "" or the reason the leaflet cannot be taken (shown to the player).
static func can_accept(cs: ContractsState, data: ContentData, uid: int) -> String:
	var c := cs.find(uid)
	if c == null or c.done:
		return Loc.t("rule.contract.unknown")
	if c.accepted:
		return Loc.t("rule.contract.taken")
	if not c.exam and active(cs).filter(func(a: ContractsState.Contract) -> bool: return not a.exam).size() >= data.balance.contracts.max_active:
		return Loc.t("rule.contract.too_many", {"n": data.balance.contracts.max_active})
	return ""


static func accept(cs: ContractsState, data: ContentData, uid: int) -> String:
	var problem := can_accept(cs, data, uid)
	if problem == "":
		cs.find(uid).accepted = true
	return problem


## "" or why the hunter can't give the contract up: only a taken one that is not done and not a Register exam.
static func can_abandon(cs: ContractsState, uid: int) -> String:
	var c := cs.find(uid)
	if c == null or not c.accepted or c.done or c.exam:
		return Loc.t("rule.contract.cant_abandon")
	return ""


## Gives a taken contract up (owner, 2026-10-12): it goes from the list and frees its slot; the caller lowers the
## petitioner's reputation (FactionRules.abandon_changes). Counts for nothing.
static func abandon(cs: ContractsState, uid: int) -> String:
	var problem := can_abandon(cs, uid)
	if problem == "":
		cs.items.erase(cs.find(uid))
	return problem


static func days_left(c: ContractsState.Contract, day: int) -> int:
	return c.deadline_day - day


static func is_overdue(c: ContractsState.Contract, day: int) -> bool:
	return day > c.deadline_day


## Creatures of the hunter's open contracts (a «wrong creature» rumor never picks them).
static func targets(cs: ContractsState) -> Array[StringName]:
	var out: Array[StringName] = []
	for c: ContractsState.Contract in active(cs):
		if not out.has(c.monster):
			out.append(c.monster)
	return out


## The open contract a fight with `monster` counts for: a Register exam first, else the nearest deadline. null if none.
static func for_monster(cs: ContractsState, monster: StringName) -> ContractsState.Contract:
	var found: ContractsState.Contract = null
	for c: ContractsState.Contract in active(cs):
		if c.monster == monster and (found == null or (c.exam and not found.exam)):
			found = c
	return found


## Puts the contract into the fight: its uid, a net for a capture, a stronger creature when overdue or an exam.
static func prepare_fight(setup: CombatSetup, c: ContractsState.Contract, day: int, b: BalanceDef) -> void:
	if c == null:
		return
	setup.contract_uid = c.uid
	setup.capture_allowed = setup.capture_allowed or c.type == &"capture"
	if is_overdue(c, day) or c.exam:  # an exam creature is as strong as an overdue one
		setup.enemy_hp_mult = b.contracts.overdue_hp_mult
		setup.enemy_damage_bonus = b.contracts.overdue_damage_bonus


## Money the fight outcome earns on the contract: a slay needs the creature slain or captured, a capture needs
## it captured. 0 when the contract is not finished.
static func reward_for(c: ContractsState.Contract, outcome: StringName) -> int:
	if c == null or c.done or not c.accepted:
		return 0
	var finished := (outcome == &"captured") if c.type == &"capture" else (outcome in [&"slain", &"captured"])
	return c.reward if finished else 0


## After a fight: finishes the contract and pays. Returns the money paid (0 = not finished).
static func resolve_fight(run: RunState, uid: int, outcome: StringName) -> int:
	var c := run.contracts.find(uid)
	var paid := reward_for(c, outcome)
	if paid > 0:
		c.done = true
		run.money += paid
	return paid
