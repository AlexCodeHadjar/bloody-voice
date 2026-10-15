class_name RumorRules
extends RefCounted
## The notebook of rumors (GDD 8.4, owner 2026-10-15). Walking through a zone the hunter may overhear a rumor about it;
## asking in the tavern gives a few, once a day. A rumor is about the creature of a contract whose lair is not found yet
## with true_chance, otherwise about another creature or lies. The player ties a thread from a rumor's sign to a
## contract: it holds when the rumor is about that contract's creature and the sign is true (the contract learns it),
## otherwise it snaps and the card burns. trail_needed cards on a contract's threads bring its lair to the map. Free.


## What a thread did.
class Link:
	var held: bool  ## false: it snapped and the card burned
	var learned: StringName = &""  ## a sign the contract did not know
	var trail: int  ## cards on the contract's threads now
	var mark: RumorsState.Mark = null  ## the lair that appeared


## Taken contracts whose lair is not found yet (in `zone`, or anywhere when "").
static func open_trails(run: RunState, zone: StringName = &"") -> Array[ContractsState.Contract]:
	var out: Array[ContractsState.Contract] = []
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		if (zone == &"" or c.zone == zone) and target_mark(run.rumors, c.uid) == null:
			out.append(c)
	return out


## The lair of the contract's creature; null if not found yet.
static func target_mark(rs: RumorsState, contract_uid: int) -> RumorsState.Mark:
	for m: RumorsState.Mark in rs.marks:
		if m.contract_uid == contract_uid:
			return m
	return null


## Rumors that can be overheard a day: more in a noisy district state (a festival, GDD 14).
static func per_day(run: RunState, data: ContentData) -> int:
	return data.balance.rumors.overhear_per_day + EventRules.state_def(run, data).rumor_bonus


static func notebook_full(run: RunState, data: ContentData) -> bool:
	return run.rumors.cards.size() >= data.balance.rumors.notebook_max


## A roll while the hunter walks through `zone` (the caller rolls every overhear_steps footsteps): a new card or null.
static func overhear(run: RunState, data: ContentData, zone: StringName, rng: RandomNumberGenerator) -> RumorsState.Card:
	var rs := run.rumors
	rs.rolls += 1
	if rs.overheard_day != run.day:
		rs.overheard_day = run.day
		rs.overheard_count = 0
	if zone == &"" or rs.overheard_count >= per_day(run, data) or notebook_full(run, data):
		return null
	if rng.randf() >= data.balance.rumors.overhear_chance:
		return null
	rs.overheard_count += 1
	var trails := open_trails(run, zone)
	var target: ContractsState.Contract = null
	if not trails.is_empty() and rng.randf() < data.balance.rumors.true_chance:
		target = trails[rng.randi_range(0, trails.size() - 1)]
	return _add(run, data, zone, target, rng)


## "" or why the place can't be asked now (asked today, the notebook is full).
static func can_ask(run: RunState, data: ContentData, place: StringName) -> String:
	if run.rumors.asked.get(place, 0) == run.day:
		return Loc.t("rule.rumor.asked_today")
	if notebook_full(run, data):
		return Loc.t("rule.rumor.notebook_full")
	return ""


## Asking around in a place: ask_min–ask_max cards about any zones (as many as the notebook holds). [] if not now.
static func ask(run: RunState, data: ContentData, place: StringName, rng: RandomNumberGenerator) -> Array[RumorsState.Card]:
	var out: Array[RumorsState.Card] = []
	if can_ask(run, data, place) != "":
		return out
	run.rumors.asked[place] = run.day
	var b := data.balance.rumors
	var map := data.district_map(run.hero_district)
	for i: int in rng.randi_range(b.ask_min, b.ask_max):
		if notebook_full(run, data) or map == null or map.zones.is_empty():
			break
		var trails := open_trails(run)
		if not trails.is_empty() and rng.randf() < b.true_chance:
			var c := trails[rng.randi_range(0, trails.size() - 1)]
			out.append(_add(run, data, c.zone, c, rng))
		else:
			out.append(_add(run, data, map.zones[rng.randi_range(0, map.zones.size() - 1)].id, null, rng))
	return out


## A thread from the card's sign `tag` to the contract. null if it can't be tied (no such card, sign or open contract,
## or this sign is tied already).
static func link(run: RunState, data: ContentData, card_uid: int, contract_uid: int, tag: StringName,
		rng: RandomNumberGenerator) -> Link:
	var rs := run.rumors
	var card := rs.card(card_uid)
	var c := run.contracts.find(contract_uid)
	if card == null or not card.tags.has(tag) or card.threads.has(tag) or not ContractRules.active(run.contracts).has(c):
		return null
	if card.linked != 0 and card.linked != contract_uid:
		return null  # a card already tied to another contract
	var out := Link.new()
	out.held = card.contract_uid == contract_uid and not card.lies.has(tag)
	if not out.held:
		rs.cards.erase(card)  # the thread snaps and the card burns
		out.trail = rs.trail(contract_uid)
		return out
	card.threads.append(tag)
	if not c.known_tags.has(tag):
		c.known_tags.append(tag)
		out.learned = tag
	card.linked = contract_uid
	out.trail = rs.trail(contract_uid)
	if out.trail >= data.balance.rumors.trail_needed and target_mark(rs, contract_uid) == null:
		out.mark = _add_mark(run, data, c, rng)
	return out


## Throws a card away; a card on a thread that held stays (it is the trail). false if not.
static func discard(run: RunState, uid: int) -> bool:
	var card := run.rumors.card(uid)
	if card == null or card.linked != 0:
		return false
	run.rumors.cards.erase(card)
	return true


## The notebook was opened: no card is new any more. Returns true when something changed.
static func seen(run: RunState) -> bool:
	var changed := false
	for c: RumorsState.Card in run.rumors.cards:
		changed = changed or c.fresh
		c.fresh = false
	return changed


## How many of the card's signs the contract already knows.
static func matches(card: RumorsState.Card, c: ContractsState.Contract) -> int:
	var n := 0
	for t: StringName in card.tags:
		n += 1 if c.known_tags.has(t) else 0
	return n


## A click on a lair: the mark to fight (it stays until its contract closes). null if there is no such mark.
static func engage(run: RunState, uid: int) -> RumorsState.Mark:
	return run.rumors.find(uid)


## Morning, and after a fight: the lairs and the tied cards of contracts no longer open go. True when something went.
static func tidy(run: RunState) -> bool:
	var rs := run.rumors
	var open: Dictionary[int, bool] = {}
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		open[c.uid] = true
	var marks := rs.marks.filter(func(m: RumorsState.Mark) -> bool: return open.has(m.contract_uid))
	var cards := rs.cards.filter(func(c: RumorsState.Card) -> bool: return c.linked == 0 or open.has(c.linked))
	var changed := marks.size() != rs.marks.size() or cards.size() != rs.cards.size()
	rs.marks.assign(marks)
	rs.cards.assign(cards)
	return changed


static func _add(run: RunState, data: ContentData, zone: StringName, target: ContractsState.Contract,
		rng: RandomNumberGenerator) -> RumorsState.Card:
	var rs := run.rumors
	var card := RumorGenerator.make(data, run.hero_district, zone, target, ContractRules.targets(run.contracts),
		rs.next_uid, run.day, rng)
	rs.next_uid += 1
	rs.cards.append(card)
	return card


## The lair on a free street node of the contract's zone; null if the zone has none.
static func _add_mark(run: RunState, data: ContentData, c: ContractsState.Contract,
		rng: RandomNumberGenerator) -> RumorsState.Mark:
	var map := data.district_map(run.hero_district)
	var used: Array[StringName] = []
	for m: RumorsState.Mark in run.rumors.marks:
		used.append(m.node)
	var node := RumorGenerator.free_node(map, c.zone, used, rng) if map != null else &""
	if node == &"":
		return null
	var m := RumorsState.Mark.new()
	m.uid = run.rumors.next_uid
	run.rumors.next_uid += 1
	m.contract_uid = c.uid
	m.monster = c.monster
	m.zone = c.zone
	m.node = node
	run.rumors.marks.append(m)
	return m
