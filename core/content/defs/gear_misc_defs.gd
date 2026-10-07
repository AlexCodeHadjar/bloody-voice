class_name GearDefs
extends RefCounted
## Small gear definitions: cell shapes, armor pieces, mechanisms (data/gear/*.json, GDD 5).

class ShapeDef:
	var id: StringName
	var name: String
	var cells: Array[Vector2i] = []


class ArmorDef:
	var id: StringName
	var name: String
	var sockets: int = 1


class MechanismDef:
	var id: StringName
	var name: String
	var cards: Array[StringName] = []
	var mods: Dictionary[StringName, int] = {}
	var effect: String


static func shape(shape_id: StringName, d: Dictionary, errs: ErrorLog) -> ShapeDef:
	var s := ShapeDef.new()
	s.id = shape_id
	var w := "shapes.json/%s" % shape_id
	s.name = DefReader.string(d, "name", errs, w)
	for cv: Variant in DefReader.array(d, "cells", errs, w):
		var c: Array = cv
		s.cells.append(Vector2i(int(c[0]), int(c[1])))
	return s


static func armor(d: Dictionary, errs: ErrorLog) -> ArmorDef:
	var a := ArmorDef.new()
	a.id = DefReader.id(d, "id", errs, "armor.json")
	a.name = DefReader.string(d, "name", errs, "armor.json/%s" % a.id)
	a.sockets = DefReader.integer(d, "sockets", errs, "armor.json/%s" % a.id, 1)
	return a


static func mechanism(d: Dictionary, errs: ErrorLog) -> MechanismDef:
	var m := MechanismDef.new()
	m.id = DefReader.id(d, "id", errs, "mechanisms.json")
	var w := "mechanisms.json/%s" % m.id
	m.name = DefReader.string(d, "name", errs, w)
	m.cards = DefReader.ids(d, "cards", errs, w)
	m.mods = GearMods.read(d, errs, w)
	m.effect = DefReader.string(d, "effect", errs, w)
	return m
