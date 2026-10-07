class_name LoadoutState
extends RefCounted
## The hunter's gear (GDD 5): weapon, modules placed in its cells, owned parts, armor sockets. Saved.

class Placement:
	var module: StringName
	var section: StringName
	var pos: Vector2i  ## top-left of the rotated shape inside the section grid
	var rot: int = 0  ## quarter turns clockwise, 0..3

	func to_dict() -> Dictionary:
		return {"module": module, "section": section, "x": pos.x, "y": pos.y, "rot": rot}

	static func from_dict(d: Dictionary) -> Placement:
		var p := Placement.new()
		p.module = StringName(str(d.get("module", "")))
		p.section = StringName(str(d.get("section", "")))
		p.pos = Vector2i(int(d.get("x", 0)), int(d.get("y", 0)))
		p.rot = posmod(int(d.get("rot", 0)), 4)
		return p


var weapon: StringName = &""
var placements: Array[Placement] = []
var owned_modules: Array[StringName] = []  ## every module the hunter has, placed or not (duplicates allowed)
var owned_mechanisms: Array[StringName] = []
var sockets: Dictionary[StringName, Array] = {}  ## armor piece -> mechanism id per socket ("" = empty)


## Modules owned but not placed (one entry per spare copy).
func spare_modules() -> Array[StringName]:
	var spare := owned_modules.duplicate()
	for p: Placement in placements:
		spare.erase(p.module)
	return spare


## Mechanisms owned but not in a socket.
func spare_mechanisms() -> Array[StringName]:
	var spare := owned_mechanisms.duplicate()
	for piece: StringName in sockets:
		for m: Variant in sockets[piece]:
			if str(m) != "":
				spare.erase(StringName(str(m)))
	return spare


func to_dict() -> Dictionary:
	var socket_out := {}
	for piece: StringName in sockets:
		socket_out[piece] = sockets[piece].duplicate()
	return {
		"weapon": weapon,
		"placements": placements.map(func(p: Placement) -> Dictionary: return p.to_dict()),
		"owned_modules": owned_modules.duplicate(),
		"owned_mechanisms": owned_mechanisms.duplicate(),
		"sockets": socket_out,
	}


## Also reads the "gear" block of balance.json (start_* keys) to build the starting loadout.
static func from_dict(d: Dictionary) -> LoadoutState:
	var l := LoadoutState.new()
	l.weapon = StringName(str(d.get("weapon", d.get("start_weapon", ""))))
	for pv: Variant in d.get("placements", d.get("start_placements", [])) as Array:
		l.placements.append(Placement.from_dict(pv as Dictionary))
	for m: Variant in d.get("owned_modules", d.get("start_modules", [])) as Array:
		l.owned_modules.append(StringName(str(m)))
	for m: Variant in d.get("owned_mechanisms", d.get("start_mechanisms", [])) as Array:
		l.owned_mechanisms.append(StringName(str(m)))
	var socket_in: Dictionary = d.get("sockets", {})
	for piece: Variant in socket_in:
		l.sockets[StringName(str(piece))] = (socket_in[piece] as Array).duplicate()
	return l
