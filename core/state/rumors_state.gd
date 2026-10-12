class_name RumorsState
extends RefCounted
## Rumor diamonds on the district map (GDD 8). Saved. What a rumor leads to is decided when it is made
## (GDD 17.2 OutcomeResolver), so reloading never rerolls it. RumorRules changes it; screens only read it.


class Rumor:
	var uid: int
	var kind: StringName  ## RumorDefs.KINDS: target / wrong_monster / discovery / false_lead / empty_night
	var monster: StringName  ## the creature met (target, wrong_monster); "" otherwise
	var contract_uid: int  ## the contract a target rumor was seeded by (0 = none)
	var witness: StringName
	var tags: Array[StringName] = []  ## shown on the tablet
	var lies: Array[StringName] = []  ## the shown tags that are not true (noise, or all of a rumor without a creature)
	var zone: StringName
	var node: StringName  ## the street node of the district map the diamond stands on
	var art: StringName  ## RUMOR__art__<art>
	var day: int  ## the morning it appeared
	var expires_day: int  ## gone on this morning
	var money: int  ## paid by a discovery / false lead / empty night
	var investigated: bool = false

	func to_dict() -> Dictionary:
		return {"uid": uid, "kind": kind, "monster": monster, "contract_uid": contract_uid, "witness": witness,
			"tags": tags, "lies": lies, "zone": zone, "node": node, "art": art, "day": day, "expires_day": expires_day,
			"money": money, "investigated": investigated}

	static func from_dict(d: Dictionary) -> Rumor:
		var r := Rumor.new()
		r.uid = int(d.get("uid", 0))
		r.kind = StringName(str(d.get("kind", "empty_night")))
		r.monster = StringName(str(d.get("monster", "")))
		r.contract_uid = int(d.get("contract_uid", 0))
		r.witness = StringName(str(d.get("witness", "")))
		r.tags = RumorsState.names(d.get("tags", []) as Array)
		r.lies = RumorsState.names(d.get("lies", []) as Array)
		r.zone = StringName(str(d.get("zone", "")))
		r.node = StringName(str(d.get("node", "")))
		r.art = StringName(str(d.get("art", "")))
		r.day = int(d.get("day", 0))
		r.expires_day = int(d.get("expires_day", 0))
		r.money = int(d.get("money", 0))
		r.investigated = bool(d.get("investigated", false))
		return r


var items: Array[Rumor] = []
var next_uid: int = 1
var last_day: int = 0  ## the morning random rumors were last added; 0 = never


func find(uid: int) -> Rumor:
	for r: Rumor in items:
		if r.uid == uid:
			return r
	return null


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for r: Rumor in items:
		list.append(r.to_dict())
	return {"items": list, "next_uid": next_uid, "last_day": last_day}


static func from_dict(d: Dictionary) -> RumorsState:
	var s := RumorsState.new()
	for v: Variant in d.get("items", []) as Array:
		s.items.append(Rumor.from_dict(v as Dictionary))
	s.next_uid = int(d.get("next_uid", 1))
	s.last_day = int(d.get("last_day", 0))
	return s


static func names(a: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for v: Variant in a:
		out.append(StringName(str(v)))
	return out
