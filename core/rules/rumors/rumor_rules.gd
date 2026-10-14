class_name RumorRules
extends RefCounted
## Listening for rumors (GDD 8.4, owner 2026-10-14). In a zone with a taken contract a heard rumor is about its creature
## with true_chance, otherwise about another creature or lies. A right rumor taken in the notes adds to the contract's
## trail and teaches its true signs; at trail_needed the creature's mark appears in the zone. A wrong one taken adds to
## the zone's hidden count; at threat_needed a red mark of an unknown threat appears for threat_days. Free: no day.


## What taking a rumor in the notes did.
class Taken:
	var right: bool
	var contract_uid: int  ## the contract whose trail grew (0 = a wrong rumor)
	var trail: int  ## that trail now
	var learned: Array[StringName] = []  ## signs the contract learned
	var mark: RumorsState.Mark = null  ## a mark that appeared (the creature's or a threat)


## Taken contracts of this zone whose creature is not found yet: what a rumor here can be right about.
static func open_trails(run: RunState, zone: StringName) -> Array[ContractsState.Contract]:
	var out: Array[ContractsState.Contract] = []
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		if c.zone == zone and target_mark(run.rumors, c.uid) == null:
			out.append(c)
	return out


## The creature's mark of the contract; null if not found yet.
static func target_mark(rs: RumorsState, contract_uid: int) -> RumorsState.Mark:
	for m: RumorsState.Mark in rs.marks:
		if m.kind == &"target" and m.contract_uid == contract_uid:
			return m
	return null


## Rumors at once: max_heard, more in a noisy district state (a festival, GDD 14).
static func max_heard(run: RunState, data: ContentData) -> int:
	return data.balance.rumors.max_heard + EventRules.state_def(run, data).rumor_bonus


## A new rumor in the zone the hunter listens in. `used`: street nodes already showing a rumor. null when the zone
## has no free street node.
static func hear(run: RunState, data: ContentData, zone: StringName, used: Array[StringName],
		rng: RandomNumberGenerator) -> RumorGenerator.Heard:
	var rs := run.rumors
	var taken := used.duplicate()
	for m: RumorsState.Mark in rs.marks:
		taken.append(m.node)
	var trails := open_trails(run, zone)
	var target: ContractsState.Contract = null
	if not trails.is_empty() and rng.randf() < data.balance.rumors.true_chance:
		target = trails[rng.randi_range(0, trails.size() - 1)]
	var h := RumorGenerator.make(data, run.hero_district, zone, target, ContractRules.targets(run.contracts), taken,
		rs.next_uid, rng)
	if h.node == &"":
		return null
	rs.next_uid += 1
	return h


## Takes the rumor in the notes. A right rumor whose contract is no longer open counts as wrong; one whose creature
## is already found only teaches its signs.
static func take(run: RunState, data: ContentData, h: RumorGenerator.Heard, rng: RandomNumberGenerator) -> Taken:
	var t := Taken.new()
	var c := run.contracts.find(h.contract_uid)
	t.right = h.right() and ContractRules.active(run.contracts).has(c)
	if t.right:
		_follow(run, data, h, c, t, rng)
	else:
		_threaten(run, data, h.zone, t, rng)
	return t


## How many of the rumor's signs the contract already knows («совпадает 2 из 3»).
static func matches(h: RumorGenerator.Heard, c: ContractsState.Contract) -> int:
	var n := 0
	for t: StringName in h.tags:
		if c.known_tags.has(t):
			n += 1
	return n


## A click on a mark: the mark to fight. A threat's mark goes at once (fought or fled, it is gone); a creature's mark
## stays until its contract closes. null if there is no such mark.
static func engage(run: RunState, uid: int) -> RumorsState.Mark:
	var m := run.rumors.find(uid)
	if m != null and m.kind == &"threat":
		run.rumors.marks.erase(m)
	return m


## Morning, and after a fight: threats that faded and the marks and trails of contracts no longer open go.
## Returns true when the marks changed.
static func tidy(run: RunState) -> bool:
	var rs := run.rumors
	var open: Dictionary[int, bool] = {}
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		open[c.uid] = true
	var kept: Array[RumorsState.Mark] = []
	for m: RumorsState.Mark in rs.marks:
		if (m.kind == &"target" and open.has(m.contract_uid)) or (m.kind == &"threat" and m.expires_day > run.day):
			kept.append(m)
	for uid: int in rs.trails.keys():
		if not open.has(uid):
			rs.trails.erase(uid)
	var changed := kept.size() != rs.marks.size()
	rs.marks = kept
	return changed


static func _follow(run: RunState, data: ContentData, h: RumorGenerator.Heard, c: ContractsState.Contract, t: Taken,
		rng: RandomNumberGenerator) -> void:
	var rs := run.rumors
	t.contract_uid = c.uid
	for tag: StringName in h.tags:
		if not h.lies.has(tag) and not c.known_tags.has(tag):
			c.known_tags.append(tag)
			t.learned.append(tag)
	t.trail = rs.trail(c.uid)
	if target_mark(rs, c.uid) != null:
		return
	t.trail += 1
	rs.trails[c.uid] = t.trail
	if t.trail >= data.balance.rumors.trail_needed:
		t.mark = _add_mark(run, data, &"target", c.monster, h.zone, rng)
		if t.mark != null:
			t.mark.contract_uid = c.uid


static func _threaten(run: RunState, data: ContentData, zone: StringName, t: Taken, rng: RandomNumberGenerator) -> void:
	var rs := run.rumors
	var b := data.balance.rumors
	rs.threats[zone] = int(rs.threats.get(zone, 0)) + 1
	if rs.threats[zone] < b.threat_needed:
		return
	var pool := EncounterRules.pool(data, run.hero_district)
	if pool.is_empty():
		return
	t.mark = _add_mark(run, data, &"threat", pool[rng.randi_range(0, pool.size() - 1)], zone, rng)
	if t.mark != null:
		t.mark.expires_day = run.day + b.threat_days
		rs.threats.erase(zone)


## A mark on a free street node of the zone (any node of it when all are taken); null if the zone has no node.
static func _add_mark(run: RunState, data: ContentData, kind: StringName, monster: StringName, zone: StringName,
		rng: RandomNumberGenerator) -> RumorsState.Mark:
	var map := data.district_map(run.hero_district)
	var used: Array[StringName] = []
	for m: RumorsState.Mark in run.rumors.marks:
		used.append(m.node)
	var node := RumorGenerator.free_node(map, zone, used, rng) if map != null else &""
	if node == &"":
		return null
	var m := RumorsState.Mark.new()
	m.uid = run.rumors.next_uid
	run.rumors.next_uid += 1
	m.kind = kind
	m.monster = monster
	m.zone = zone
	m.node = node
	run.rumors.marks.append(m)
	return m
