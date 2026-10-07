class_name GearValidator
extends RefCounted
## Checks weapons, modules, shapes, armor, mechanisms and the starting loadout (GDD 5).

const CELL_TYPES: Array[StringName] = [&"gear", &"spark", &"blood"]


static func validate(data: ContentData, errs: ErrorLog) -> void:
	var section_ids := {}
	for w: WeaponDef in data.weapons.values():
		var where := "weapons.json/%s" % w.id
		_cards(w.cards, data, errs, where)
		if w.max_ammo < 1:
			errs.add(where, "max_ammo must be >= 1")
		for s: WeaponDef.SectionDef in w.sections:
			section_ids[s.id] = true
			for c: Vector2i in s.cells:
				if not CELL_TYPES.has(s.cells[c]):
					errs.add(where + "/" + s.id, "unknown cell type '%s'" % s.cells[c])
	for m: ModuleDef in data.modules.values():
		var where := "modules.json/%s" % m.id
		if not section_ids.has(m.section):
			errs.add(where, "no weapon has a '%s' section" % m.section)
		if not data.shapes.has(m.shape):
			errs.add(where, "unknown shape '%s'" % m.shape)
		if not CELL_TYPES.has(m.cell):
			errs.add(where, "unknown cell type '%s'" % m.cell)
		_cards(m.cards + m.capture_cards, data, errs, where)
		for link: ModuleDef.LinkDef in m.links:
			if not data.modules.has(link.with_module):
				errs.add(where, "link with unknown module '%s'" % link.with_module)
			_cards(Array(link.replace.keys() + link.replace.values(), TYPE_STRING_NAME, "", null), data, errs, where + "/links")
	for mech: GearDefs.MechanismDef in data.mechanisms.values():
		_cards(mech.cards, data, errs, "mechanisms.json/%s" % mech.id)
	for a: GearDefs.ArmorDef in data.armor:
		if a.sockets < 1:
			errs.add("armor.json/%s" % a.id, "sockets must be >= 1")
	_start_loadout(data, errs)


static func _start_loadout(data: ContentData, errs: ErrorLog) -> void:
	var l := LoadoutState.from_dict(data.balance.start_loadout)
	for id: StringName in l.owned_modules:
		if not data.modules.has(id):
			errs.add("balance.json/gear", "unknown start module '%s'" % id)
	for id: StringName in l.owned_mechanisms:
		if data.mechanism(id) == null:
			errs.add("balance.json/gear", "unknown start mechanism '%s'" % id)
	for problem: String in WeaponGridRules.problems(l, data):
		errs.add("balance.json/gear", problem)


static func _cards(ids: Array[StringName], data: ContentData, errs: ErrorLog, where: String) -> void:
	for id: StringName in ids:
		if not data.cards.has(id):
			errs.add(where, "unknown card '%s'" % id)
