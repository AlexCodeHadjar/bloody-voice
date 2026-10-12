class_name ContractsState
extends RefCounted
## The tavern board and the hunter's contracts (GDD 7). Saved. One list: this week's leaflets plus contracts
## accepted earlier and not done yet. ContractRules changes it; screens only read it.


class Contract:
	var uid: int
	var monster: StringName
	var type: StringName  ## slay / capture (ContractDefs.TYPES)
	var petition: StringName
	var known_tags: Array[StringName] = []
	var zone: StringName  ## last seen: a zone of the district map
	var week: int  ## the week whose board it was pinned on
	var deadline_day: int  ## the last day to finish it; after that it is overdue (the creature gets stronger)
	var reward: int
	var accepted: bool = false
	var done: bool = false
	var next_rumor_day: int = 0  ## the morning its next true rumor appears (0 = at once, GDD 17.2)
	var crossed_tags: Array[StringName] = []  ## signs proven not to be the creature's (false leads, GDD 8.2)

	func to_dict() -> Dictionary:
		return {"uid": uid, "monster": monster, "type": type, "petition": petition, "known_tags": known_tags,
			"zone": zone, "week": week, "deadline_day": deadline_day, "reward": reward, "accepted": accepted, "done": done,
			"next_rumor_day": next_rumor_day, "crossed_tags": crossed_tags}

	static func from_dict(d: Dictionary) -> Contract:
		var c := Contract.new()
		c.uid = int(d.get("uid", 0))
		c.monster = StringName(str(d.get("monster", "")))
		c.type = StringName(str(d.get("type", "slay")))
		c.petition = StringName(str(d.get("petition", "")))
		c.known_tags = RumorsState.names(d.get("known_tags", []) as Array)
		c.zone = StringName(str(d.get("zone", "")))
		c.week = int(d.get("week", 0))
		c.deadline_day = int(d.get("deadline_day", 0))
		c.reward = int(d.get("reward", 0))
		c.accepted = bool(d.get("accepted", false))
		c.done = bool(d.get("done", false))
		c.next_rumor_day = int(d.get("next_rumor_day", 0))
		c.crossed_tags = RumorsState.names(d.get("crossed_tags", []) as Array)
		return c


var items: Array[Contract] = []
var board_week: int = 0  ## the week the board was last filled; 0 = never
var next_uid: int = 1


func find(uid: int) -> Contract:
	for c: Contract in items:
		if c.uid == uid:
			return c
	return null


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for c: Contract in items:
		list.append(c.to_dict())
	return {"items": list, "board_week": board_week, "next_uid": next_uid}


static func from_dict(d: Dictionary) -> ContractsState:
	var s := ContractsState.new()
	for v: Variant in d.get("items", []) as Array:
		s.items.append(Contract.from_dict(v as Dictionary))
	s.board_week = int(d.get("board_week", 0))
	s.next_uid = int(d.get("next_uid", 1))
	return s
