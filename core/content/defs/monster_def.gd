class_name MonsterDef
extends RefCounted
## A creature: stats, body parts, its own deck of moves and phases (data/monsters/*.json, GDD 9.4).

class PartDef:
	var id: StringName
	var name: String
	var hp: int
	var removes: Array[StringName] = []  ## moves lost when this part breaks
	var trophy: StringName


class MoveDef:
	var id: StringName
	var name: String
	var kind: StringName  ## attack / defend / fear / debuff / buff / heal — for intent icons
	var text: String
	var effects: Array[Dictionary] = []


class PhaseDef:
	var below: float  ## triggers when hp <= max_hp * below
	var name: String
	var add: Array[StringName] = []
	var remove: Array[StringName] = []


var id: StringName
var name: String
var rank: String
var hp: int
var intents_per_turn: int = 1
var districts: Array[StringName] = []
var tags: Array[StringName] = []
var parts: Array[PartDef] = []
var moves: Dictionary[StringName, MoveDef] = {}
var deck: Array[StringName] = []
var phases: Array[PhaseDef] = []


static func from_dict(d: Dictionary, errs: ErrorLog, file: String) -> MonsterDef:
	var m := MonsterDef.new()
	m.id = DefReader.id(d, "id", errs, file)
	var w := "%s/%s" % [file, m.id]
	m.name = DefReader.string(d, "name", errs, w)
	m.rank = DefReader.string(d, "rank", errs, w)
	m.hp = DefReader.integer(d, "hp", errs, w)
	m.intents_per_turn = DefReader.integer(d, "intents_per_turn", errs, w, 1, false)
	m.districts = DefReader.ids(d, "districts", errs, w)
	m.tags = DefReader.ids(d, "tags", errs, w)
	m.deck = DefReader.ids(d, "deck", errs, w)
	for p: Variant in DefReader.array(d, "parts", errs, w, false):
		m.parts.append(_part(p as Dictionary, errs, w))
	for mv: Variant in DefReader.array(d, "moves", errs, w):
		var move := _move(mv as Dictionary, errs, w)
		m.moves[move.id] = move
	for ph: Variant in DefReader.array(d, "phases", errs, w, false):
		m.phases.append(_phase(ph as Dictionary, errs, w))
	return m


func part(part_id: StringName) -> PartDef:
	for p: PartDef in parts:
		if p.id == part_id:
			return p
	return null


static func _part(d: Dictionary, errs: ErrorLog, w: String) -> PartDef:
	var p := PartDef.new()
	p.id = DefReader.id(d, "id", errs, w + "/parts")
	p.name = DefReader.string(d, "name", errs, w + "/parts")
	p.hp = DefReader.integer(d, "hp", errs, w + "/parts")
	p.removes = DefReader.ids(d, "removes", errs, w + "/parts")
	p.trophy = DefReader.id(d, "trophy", errs, w + "/parts", false)
	return p


static func _move(d: Dictionary, errs: ErrorLog, w: String) -> MoveDef:
	var m := MoveDef.new()
	m.id = DefReader.id(d, "id", errs, w + "/moves")
	m.name = DefReader.string(d, "name", errs, w + "/moves")
	m.kind = DefReader.id(d, "kind", errs, w + "/moves")
	m.text = DefReader.string(d, "text", errs, w + "/moves", false)
	for e: Variant in DefReader.array(d, "effects", errs, w + "/moves"):
		m.effects.append(e as Dictionary)
	return m


static func _phase(d: Dictionary, errs: ErrorLog, w: String) -> PhaseDef:
	var p := PhaseDef.new()
	p.below = DefReader.number(d, "below", errs, w + "/phases")
	p.name = DefReader.string(d, "name", errs, w + "/phases")
	p.add = DefReader.ids(d, "add", errs, w + "/phases")
	p.remove = DefReader.ids(d, "remove", errs, w + "/phases")
	return p
