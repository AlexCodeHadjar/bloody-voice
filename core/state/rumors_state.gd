class_name RumorsState
extends RefCounted
## Rumors (GDD 8.4, owner 2026-10-14): what listening to the street has gathered — each contract's trail (right rumors
## taken), the hidden count of wrong rumors taken per zone, and the marks on the map (the creature found, an unknown
## threat). Heard rumors themselves are not kept: they flare up and fade while the hunter listens.


## A mark on the district map: the creature of a contract found, or an unknown threat (red).
class Mark:
	var uid: int
	var kind: StringName  ## target | threat
	var contract_uid: int  ## the contract a target mark belongs to (0 = a threat)
	var monster: StringName
	var zone: StringName
	var node: StringName  ## the street node it stands on
	var expires_day: int  ## a threat fades on this morning (0 = never: a target stays while its contract is open)

	func to_dict() -> Dictionary:
		return {"uid": uid, "kind": kind, "contract_uid": contract_uid, "monster": monster, "zone": zone, "node": node,
			"expires_day": expires_day}

	static func from_dict(d: Dictionary) -> Mark:
		var m := Mark.new()
		m.uid = int(d.get("uid", 0))
		m.kind = StringName(str(d.get("kind", "threat")))
		m.contract_uid = int(d.get("contract_uid", 0))
		m.monster = StringName(str(d.get("monster", "")))
		m.zone = StringName(str(d.get("zone", "")))
		m.node = StringName(str(d.get("node", "")))
		m.expires_day = int(d.get("expires_day", 0))
		return m


var marks: Array[Mark] = []
var trails: Dictionary[int, int] = {}  ## contract uid -> right rumors taken
var threats: Dictionary[StringName, int] = {}  ## zone -> wrong rumors taken (hidden from the player)
var next_uid: int = 1


func find(uid: int) -> Mark:
	for m: Mark in marks:
		if m.uid == uid:
			return m
	return null


func trail(contract_uid: int) -> int:
	return trails.get(contract_uid, 0)


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for m: Mark in marks:
		list.append(m.to_dict())
	var t := {}
	for k: int in trails:
		t[str(k)] = trails[k]
	return {"marks": list, "trails": t, "threats": threats, "next_uid": next_uid}


static func from_dict(d: Dictionary) -> RumorsState:
	var s := RumorsState.new()
	for v: Variant in d.get("marks", []) as Array:
		s.marks.append(Mark.from_dict(v as Dictionary))
	var t: Dictionary = d.get("trails", {})
	for k: Variant in t:
		s.trails[int(str(k))] = int(t[k])
	var th: Dictionary = d.get("threats", {})
	for k: Variant in th:
		s.threats[StringName(str(k))] = int(th[k])
	s.next_uid = int(d.get("next_uid", 1))
	return s
