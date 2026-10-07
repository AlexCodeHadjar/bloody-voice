class_name ArmorRules
extends RefCounted
## Mechanisms in armor sockets (GDD 5.1). Every armor piece has a number of sockets; any mechanism fits any socket.


## Puts a mechanism into a socket ("" empties it). Returns "" or the reason.
static func set_socket(l: LoadoutState, data: ContentData, piece: StringName, index: int, mechanism: StringName) -> String:
	var armor := _armor(data, piece)
	if armor == null:
		return "Unknown armor piece."
	if index < 0 or index >= armor.sockets:
		return "No such socket."
	var slots := _slots(l, armor)
	if mechanism != &"":
		if data.mechanism(mechanism) == null:
			return "Unknown mechanism."
		if str(slots[index]) != String(mechanism) and not l.spare_mechanisms().has(mechanism):
			return "You have no spare %s." % mechanism
	slots[index] = String(mechanism)
	l.sockets[piece] = slots
	return ""


## Mechanism ids currently in sockets.
static func installed(l: LoadoutState) -> Array[StringName]:
	var out: Array[StringName] = []
	for piece: StringName in l.sockets:
		for m: Variant in l.sockets[piece]:
			if str(m) != "":
				out.append(StringName(str(m)))
	return out


static func mechanism_at(l: LoadoutState, piece: StringName, index: int) -> StringName:
	var slots: Array = l.sockets.get(piece, [])
	return StringName(str(slots[index])) if index < slots.size() else &""


static func _slots(l: LoadoutState, armor: GearDefs.ArmorDef) -> Array:
	var slots: Array = (l.sockets.get(armor.id, []) as Array).duplicate()
	while slots.size() < armor.sockets:
		slots.append("")
	return slots


static func _armor(data: ContentData, piece: StringName) -> GearDefs.ArmorDef:
	for a: GearDefs.ArmorDef in data.armor:
		if a.id == piece:
			return a
	return null
