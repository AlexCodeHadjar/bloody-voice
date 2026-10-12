class_name ArmorRules
extends RefCounted
## Mechanisms in armor sockets (GDD 5.1). Every armor piece has a number of sockets; any mechanism fits any socket.


## Puts a mechanism into a socket ("" empties it). Returns "" or the reason.
static func set_socket(l: LoadoutState, data: ContentData, piece: StringName, index: int, mechanism: StringName) -> String:
	var armor := _armor(data, piece)
	if armor == null:
		return Loc.t("rule.unknown_armor")
	if index < 0 or index >= socket_count(l, armor):
		return Loc.t("rule.no_socket")
	var slots := _slots(l, armor)
	if mechanism != &"":
		if data.mechanism(mechanism) == null:
			return Loc.t("rule.unknown_mechanism")
		if str(slots[index]) != String(mechanism) and not l.spare_mechanisms().has(mechanism):
			return Loc.t("rule.no_spare", {"item": data.mechanism(mechanism).name})
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


## The piece's own sockets plus those the skill web added.
static func socket_count(l: LoadoutState, armor: GearDefs.ArmorDef) -> int:
	return armor.sockets + int(l.extra_sockets.get(armor.id, 0))


## Drops sockets beyond each piece's count (a reset web); their mechanisms become spare again.
static func trim(l: LoadoutState, data: ContentData) -> void:
	for a: GearDefs.ArmorDef in data.armor:
		var slots: Array = l.sockets.get(a.id, [])
		if slots.size() > socket_count(l, a):
			l.sockets[a.id] = slots.slice(0, socket_count(l, a))


static func _slots(l: LoadoutState, armor: GearDefs.ArmorDef) -> Array:
	var slots: Array = (l.sockets.get(armor.id, []) as Array).duplicate()
	while slots.size() < socket_count(l, armor):
		slots.append("")
	return slots


static func _armor(data: ContentData, piece: StringName) -> GearDefs.ArmorDef:
	for a: GearDefs.ArmorDef in data.armor:
		if a.id == piece:
			return a
	return null
