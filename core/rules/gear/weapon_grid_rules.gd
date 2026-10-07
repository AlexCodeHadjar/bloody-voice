class_name WeaponGridRules
extends RefCounted
## Placing modules into weapon cells (GDD 5.2). Modules may be rotated in quarter turns.
## A module fits when every cell lies inside its own section, on cells of its type, and overlaps nothing.


## Shape cells after `rot` clockwise quarter turns, shifted so the top-left is (0, 0).
static func rotated(cells: Array[Vector2i], rot: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in cells:
		var p := c
		for _i: int in posmod(rot, 4):
			p = Vector2i(-p.y, p.x)  # clockwise with y pointing down
		out.append(p)
	var min_x := 0
	var min_y := 0
	if not out.is_empty():
		min_x = out[0].x
		min_y = out[0].y
		for p: Vector2i in out:
			min_x = mini(min_x, p.x)
			min_y = mini(min_y, p.y)
	for i: int in out.size():
		out[i] -= Vector2i(min_x, min_y)
	return out


## Cells a placement covers inside its section grid.
static func covered(p: LoadoutState.Placement, data: ContentData) -> Array[Vector2i]:
	var module := data.module(p.module)
	var out: Array[Vector2i] = []
	if module == null or not data.shapes.has(module.shape):
		return out
	for c: Vector2i in rotated(data.shapes[module.shape].cells, p.rot):
		out.append(c + p.pos)
	return out


## "" if the module can go there, else the reason (shown to the player).
## ignore_index: a placement to leave out (when moving an already placed module).
static func can_place(l: LoadoutState, data: ContentData, module_id: StringName, section_id: StringName,
		pos: Vector2i, rot: int, ignore_index: int = -1) -> String:
	var module := data.module(module_id)
	var weapon := data.weapon(l.weapon)
	if module == null or weapon == null:
		return "Unknown module or weapon."
	if module.section != section_id:
		return "%s fits only into the %s." % [module.name, module.section]
	var section := weapon.section(section_id)
	if section == null:
		return "This weapon has no %s." % section_id
	var p := _placement(module_id, section_id, pos, rot)
	var taken := _taken(l, data, section_id, ignore_index)
	for c: Vector2i in covered(p, data):
		if not section.cells.has(c):
			return "It does not fit there."
		if section.cells[c] != module.cell:
			return "Needs %s cells." % module.cell
		if taken.has(c):
			return "Another module is in the way."
	return ""


## Places a spare module. Returns "" or the reason it can't be placed.
static func place(l: LoadoutState, data: ContentData, module_id: StringName, section_id: StringName,
		pos: Vector2i, rot: int) -> String:
	if not l.spare_modules().has(module_id):
		return "You have no spare %s." % module_id
	var problem := can_place(l, data, module_id, section_id, pos, rot)
	if problem == "":
		l.placements.append(_placement(module_id, section_id, pos, rot))
	return problem


## Takes a module out of the weapon (it becomes spare again). Returns its id or "".
static func remove_at(l: LoadoutState, index: int) -> StringName:
	if index < 0 or index >= l.placements.size():
		return &""
	var p: LoadoutState.Placement = l.placements[index]
	l.placements.remove_at(index)
	return p.module


## Index of the placement covering a cell of a section, or -1.
static func placement_at(l: LoadoutState, data: ContentData, section_id: StringName, cell: Vector2i) -> int:
	for i: int in l.placements.size():
		var p: LoadoutState.Placement = l.placements[i]
		if p.section == section_id and covered(p, data).has(cell):
			return i
	return -1


## Two placements touch when they share a section and an edge between cells.
static func touching(a: LoadoutState.Placement, b: LoadoutState.Placement, data: ContentData) -> bool:
	if a.section != b.section:
		return false
	var b_cells := covered(b, data)
	for c: Vector2i in covered(a, data):
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if b_cells.has(c + d):
				return true
	return false


## Problems with a whole loadout (start gear, loaded saves).
static func problems(l: LoadoutState, data: ContentData) -> PackedStringArray:
	if data.weapon(l.weapon) == null:
		return PackedStringArray(["unknown weapon '%s'" % l.weapon])
	var copy := LoadoutState.new()
	copy.weapon = l.weapon
	copy.owned_modules = l.owned_modules.duplicate()
	copy.placements = l.placements.duplicate()
	return drop_invalid(copy, data)


## Removes placements that no longer fit (content changed since the save). Returns what was removed.
static func drop_invalid(l: LoadoutState, data: ContentData) -> PackedStringArray:
	var removed: PackedStringArray = []
	var kept: Array[LoadoutState.Placement] = []
	var check := LoadoutState.new()
	check.weapon = l.weapon
	check.owned_modules = l.owned_modules.duplicate()
	for p: LoadoutState.Placement in l.placements:
		var problem := place(check, data, p.module, p.section, p.pos, p.rot)
		if problem == "":
			kept.append(p)
		else:
			removed.append("%s in %s: %s" % [p.module, p.section, problem])
	l.placements = kept
	return removed


static func _taken(l: LoadoutState, data: ContentData, section_id: StringName, ignore_index: int) -> Dictionary:
	var taken := {}
	for i: int in l.placements.size():
		var p: LoadoutState.Placement = l.placements[i]
		if i != ignore_index and p.section == section_id:
			for c: Vector2i in covered(p, data):
				taken[c] = true
	return taken


static func _placement(module_id: StringName, section_id: StringName, pos: Vector2i, rot: int) -> LoadoutState.Placement:
	var p := LoadoutState.Placement.new()
	p.module = module_id
	p.section = section_id
	p.pos = pos
	p.rot = posmod(rot, 4)
	return p
