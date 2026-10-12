class_name RumorRules
extends RefCounted
## Rumors (GDD 8, owner 2026-10-12): each morning 1–2 new diamonds on the district map (at most 5), each lives 3
## days; every taken contract seeds a true rumor every 2–3 days, the first one at once. «Расследовать» costs the
## day: the target or another creature means a fight; a discovery, false lead or empty night pays a little money
## (a discovery and an empty night also resources), and a false lead or empty night crosses out a sign that is not
## the creature's.


class Outcome:
	var kind: StringName
	var monster: StringName  ## the creature to fight ("" = no fight)
	var contract_uid: int  ## the contract the target rumor belongs to (0 = none)
	var zone: StringName
	var money: int = 0
	var resources: Dictionary[StringName, int] = {}
	var crossed: StringName = &""  ## the sign crossed out on `crossed_contract`
	var crossed_contract: int = 0


## Diamonds on the map now, oldest first.
static func visible(rs: RumorsState) -> Array[RumorsState.Rumor]:
	var out: Array[RumorsState.Rumor] = []
	for r: RumorsState.Rumor in rs.items:
		if not r.investigated:
			out.append(r)
	return out


## The morning's rumors: old and finished ones go, contracts seed their true rumors, then 1–2 random ones.
## Does nothing if this morning was already done. Returns true when the diamonds changed.
static func new_morning(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> bool:
	var rs := run.rumors
	if rs.last_day == run.day:
		return false
	rs.last_day = run.day
	_drop_stale(run)
	seed_targets(run, data, rng)
	var b := data.balance.rumors
	for i: int in rng.randi_range(b.new_min, b.new_max):
		if visible(rs).size() >= b.max_on_map:
			break
		_add(rs, RumorGenerator.make_random(data, run.hero_district, run.day, rng, rs.next_uid, _used_nodes(rs),
			ContractRules.targets(run.contracts)))
	return true


## True rumors of the taken contracts that are due (a new contract: at once). They may exceed max_on_map.
static func seed_targets(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> bool:
	var rs := run.rumors
	var b := data.balance.rumors
	var changed := false
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		if c.next_rumor_day > run.day:
			continue
		var r := RumorGenerator.make_target(data, run.hero_district, c, run.day, rng, rs.next_uid, _used_nodes(rs))
		if r == null:
			continue
		_add(rs, r)
		c.next_rumor_day = run.day + rng.randi_range(b.true_every_min, b.true_every_max)
		changed = true
	return changed


## How many of the rumor's signs are among the contract's known signs («совпадает 2 из 3»).
static func matches(r: RumorsState.Rumor, c: ContractsState.Contract) -> int:
	var n := 0
	for t: StringName in r.tags:
		if c.known_tags.has(t):
			n += 1
	return n


## The open contract the rumor fits best (most matching signs, then the nearest deadline); null if none is open.
static func best_contract(cs: ContractsState, r: RumorsState.Rumor) -> ContractsState.Contract:
	var best: ContractsState.Contract = null
	for c: ContractsState.Contract in ContractRules.active(cs):
		if best == null or matches(r, c) > matches(r, best):
			best = c
	return best


## Investigates the rumor (the caller ends the day or starts the fight). null if there is no such diamond.
static func investigate(run: RunState, data: ContentData, uid: int) -> Outcome:
	var r := run.rumors.find(uid)
	if r == null or r.investigated:
		return null
	r.investigated = true
	var o := Outcome.new()
	o.kind = r.kind
	o.zone = r.zone
	if RumorDefs.FIGHTS.has(r.kind):
		o.monster = r.monster
		o.contract_uid = r.contract_uid
		return o
	o.money = r.money
	run.money += r.money
	o.resources = r.resources
	LootRules.add_resources(run.workshop, r.resources)
	if r.kind == &"false_lead" or r.kind == &"empty_night":
		_cross_out(run, data, r, o)
	return o


## Crosses out one shown sign that is not the best-fitting contract creature's own.
static func _cross_out(run: RunState, data: ContentData, r: RumorsState.Rumor, o: Outcome) -> void:
	var c := best_contract(run.contracts, r)
	if c == null:
		return
	var m := data.monster(c.monster)
	for t: StringName in r.tags:
		if not m.tags.has(t) and not c.crossed_tags.has(t):
			c.crossed_tags.append(t)
			o.crossed = t
			o.crossed_contract = c.uid
			return


## Expired and investigated diamonds go, and target rumors of contracts that are no longer open.
static func _drop_stale(run: RunState) -> void:
	var kept: Array[RumorsState.Rumor] = []
	for r: RumorsState.Rumor in run.rumors.items:
		var open_target := r.kind != &"target" or ContractRules.active(run.contracts).has(run.contracts.find(r.contract_uid))
		if not r.investigated and r.expires_day > run.day and open_target:
			kept.append(r)
	run.rumors.items = kept


static func _used_nodes(rs: RumorsState) -> Array[StringName]:
	var out: Array[StringName] = []
	for r: RumorsState.Rumor in visible(rs):
		out.append(r.node)
	return out


static func _add(rs: RumorsState, r: RumorsState.Rumor) -> void:
	if r == null:
		return
	rs.items.append(r)
	rs.next_uid = maxi(rs.next_uid, r.uid + 1)
