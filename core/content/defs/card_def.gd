class_name CardDef
extends RefCounted
## A hunter card (data/cards/*.json, GDD 9.3). Effects are data ops run by EffectApplier.

const TYPES: Array[StringName] = [&"attack", &"support", &"consumable", &"capture", &"rage", &"curse"]
## enemy = the creature, enemy_or_part = creature or one of its body parts, self = the hunter, none = unplayable.
const TARGETS: Array[StringName] = [&"enemy", &"enemy_or_part", &"self", &"none"]

var id: StringName
var name: String
var type: StringName
var cost: int = 0
var ammo: int = 0
var target: StringName = &"self"
var text: String
var effects: Array[Dictionary] = []
var unplayable: bool = false
var exhaust: bool = false  ## destroyed after play (consumables always are)
var retain: bool = false  ## stays in hand at end of turn


static func from_dict(d: Dictionary, errs: ErrorLog, file: String) -> CardDef:
	var c := CardDef.new()
	c.id = DefReader.id(d, "id", errs, file)
	var w := "%s/%s" % [file, c.id]
	c.name = DefReader.string(d, "name", errs, w)
	c.type = DefReader.id(d, "type", errs, w)
	c.cost = DefReader.integer(d, "cost", errs, w)
	c.ammo = DefReader.integer(d, "ammo", errs, w, 0, false)
	c.target = DefReader.id(d, "target", errs, w)
	c.text = DefReader.string(d, "text", errs, w)
	c.unplayable = DefReader.flag(d, "unplayable")
	c.exhaust = DefReader.flag(d, "exhaust") or c.type == &"consumable"
	c.retain = DefReader.flag(d, "retain")
	for e: Variant in DefReader.array(d, "effects", errs, w):
		c.effects.append(e as Dictionary)
	return c


func needs_enemy_target() -> bool:
	return target == &"enemy" or target == &"enemy_or_part"
