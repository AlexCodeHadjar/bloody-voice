class_name RumorsState
extends RefCounted
## Rumors (GDD 8.4, owner 2026-10-15): the hunter's notebook — rumor cards overheard on the way or asked in the tavern,
## the threads the player tied from their signs to contracts — and the lairs on the map the threads led to.


## A rumor card in the notebook: who told it, which signs, about what. Stays until thrown away or its contract closes.
class Card:
	var uid: int
	var zone: StringName  ## the zone it is about
	var monster: StringName  ## the creature it is about ("" = lies)
	var contract_uid: int  ## the contract whose creature it is about (0 = a wrong rumor)
	var witness: StringName
	var art: StringName  ## a picture of the zone (RumorDefs.ART_DIR)
	var tags: Array[StringName] = []
	var lies: Array[StringName] = []  ## the shown signs that are not the creature's
	var day: int
	var fresh: bool = true  ## not seen in the notebook yet
	var linked: int = 0  ## the contract it is tied to by a thread that held (0 = none)
	var threads: Array[StringName] = []  ## its signs tied to that contract

	func right() -> bool:
		return contract_uid != 0

	func to_dict() -> Dictionary:
		return {"uid": uid, "zone": zone, "monster": monster, "contract_uid": contract_uid, "witness": witness, "art": art,
			"tags": tags, "lies": lies, "day": day, "fresh": fresh, "linked": linked, "threads": threads}

	static func from_dict(d: Dictionary) -> Card:
		var c := Card.new()
		c.uid = int(d.get("uid", 0))
		c.zone = StringName(str(d.get("zone", "")))
		c.monster = StringName(str(d.get("monster", "")))
		c.contract_uid = int(d.get("contract_uid", 0))
		c.witness = StringName(str(d.get("witness", "")))
		c.art = StringName(str(d.get("art", "")))
		c.tags = ContractsState.names(d.get("tags", []) as Array)
		c.lies = ContractsState.names(d.get("lies", []) as Array)
		c.day = int(d.get("day", 0))
		c.fresh = bool(d.get("fresh", true))
		c.linked = int(d.get("linked", 0))
		c.threads = ContractsState.names(d.get("threads", []) as Array)
		return c


## A lair on the district map: the creature of a contract the threads led to.
class Mark:
	var uid: int
	var contract_uid: int
	var monster: StringName
	var zone: StringName
	var node: StringName  ## the street node it stands on

	func to_dict() -> Dictionary:
		return {"uid": uid, "contract_uid": contract_uid, "monster": monster, "zone": zone, "node": node}

	static func from_dict(d: Dictionary) -> Mark:
		var m := Mark.new()
		m.uid = int(d.get("uid", 0))
		m.contract_uid = int(d.get("contract_uid", 0))
		m.monster = StringName(str(d.get("monster", "")))
		m.zone = StringName(str(d.get("zone", "")))
		m.node = StringName(str(d.get("node", "")))
		return m


var cards: Array[Card] = []
var marks: Array[Mark] = []
var asked: Dictionary[StringName, int] = {}  ## place -> the day it was last asked
var overheard_day: int = 0  ## the day overheard_count counts
var overheard_count: int = 0  ## rumors overheard that day
var rolls: int = 0  ## overhearing rolls so far (each roll its own random stream)
var next_uid: int = 1


func card(uid: int) -> Card:
	for c: Card in cards:
		if c.uid == uid:
			return c
	return null


func find(uid: int) -> Mark:
	for m: Mark in marks:
		if m.uid == uid:
			return m
	return null


## Cards tied to the contract by a thread that held: its trail.
func trail(contract_uid: int) -> int:
	var n := 0
	for c: Card in cards:
		n += 1 if c.linked == contract_uid and contract_uid != 0 else 0
	return n


func fresh_count() -> int:
	return cards.filter(func(c: Card) -> bool: return c.fresh).size()


func to_dict() -> Dictionary:
	var list: Array[Dictionary] = []
	for c: Card in cards:
		list.append(c.to_dict())
	var ms: Array[Dictionary] = []
	for m: Mark in marks:
		ms.append(m.to_dict())
	return {"cards": list, "marks": ms, "asked": asked, "overheard_day": overheard_day, "overheard_count": overheard_count,
		"rolls": rolls, "next_uid": next_uid}


static func from_dict(d: Dictionary) -> RumorsState:
	var s := RumorsState.new()
	for v: Variant in d.get("cards", []) as Array:
		s.cards.append(Card.from_dict(v as Dictionary))
	for v: Variant in d.get("marks", []) as Array:
		s.marks.append(Mark.from_dict(v as Dictionary))
	var asked: Dictionary = d.get("asked", {})
	for k: Variant in asked:
		s.asked[StringName(str(k))] = int(asked[k])
	s.overheard_day = int(d.get("overheard_day", 0))
	s.overheard_count = int(d.get("overheard_count", 0))
	s.rolls = int(d.get("rolls", 0))
	s.next_uid = int(d.get("next_uid", 1))
	return s
