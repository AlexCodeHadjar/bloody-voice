class_name WeaponDef
extends RefCounted
## A weapon: base cards, magazine and its sections with typed cells (data/gear/weapons.json, GDD 5.2).

class SectionDef:
	var id: StringName
	var name: String
	var cells: Dictionary[Vector2i, StringName] = {}  ## cell position -> cell type (gear / spark / blood)


var id: StringName
var name: String
var cards: Array[StringName] = []
var max_ammo: int = 0
var sections: Array[SectionDef] = []


static func from_dict(d: Dictionary, errs: ErrorLog) -> WeaponDef:
	var w := WeaponDef.new()
	w.id = DefReader.id(d, "id", errs, "weapons.json")
	var where := "weapons.json/%s" % w.id
	w.name = DefReader.string(d, "name", errs, where)
	w.cards = DefReader.ids(d, "cards", errs, where)
	w.max_ammo = DefReader.integer(d, "max_ammo", errs, where)
	for sv: Variant in DefReader.array(d, "sections", errs, where):
		var sd: Dictionary = sv
		var s := SectionDef.new()
		s.id = DefReader.id(sd, "id", errs, where + "/sections")
		s.name = DefReader.string(sd, "name", errs, where + "/sections")
		for cv: Variant in DefReader.array(sd, "cells", errs, where + "/" + s.id):
			var c: Array = cv
			if c.size() != 3:
				errs.add(where + "/" + s.id, "cell must be [x, y, type]")
				continue
			s.cells[Vector2i(int(c[0]), int(c[1]))] = StringName(str(c[2]))
		w.sections.append(s)
	return w


func section(section_id: StringName) -> SectionDef:
	for s: SectionDef in sections:
		if s.id == section_id:
			return s
	return null
