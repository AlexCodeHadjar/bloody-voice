class_name MapMarkupEditor
extends RefCounted
## Debug builds only (F3 on the district map, owner 2026-10-12): a click picks a street node, a landmark spot or a
## zone corner; Ctrl + the held left button anywhere on the map moves the picked point with the mouse (no jump).
## A zone corner shared by several zones moves in all of them, so neighbouring zones stay closed.
## Ctrl+S (MapMarkupSaver) writes the numbers into the map file.

var map: DistrictMapDef
var _node: StringName = &""
var _landmark: DistrictMapDef.LandmarkDef = null
var _corners: Array = []  ## [ZoneDef, index] pairs at the picked zone corner
var _offset := Vector2.ZERO  ## the picked point minus the art point under the mouse when the move started
var moving := false


func _init(district_map: DistrictMapDef) -> void:
	map = district_map


func has_pick() -> bool:
	return _node != &"" or _landmark != null or not _corners.is_empty()


func clear() -> void:
	_node = &""
	_landmark = null
	_corners = []
	moving = false


## Picks the point within `radius` art px of `p`: street nodes first, then landmark spots, then zone corners.
func pick(p: Vector2, radius: float) -> bool:
	for id: StringName in map.nodes:
		if map.nodes[id].distance_to(p) <= radius:
			clear()
			_node = id
			return true
	for lm: DistrictMapDef.LandmarkDef in map.landmarks:
		if lm.pos.distance_to(p) <= radius:
			clear()
			_landmark = lm
			return true
	for z: DistrictMapDef.ZoneDef in map.zones:
		for i: int in z.polygon.size():
			if z.polygon[i].distance_to(p) <= radius:
				var at := z.polygon[i]
				clear()
				for other: DistrictMapDef.ZoneDef in map.zones:
					for j: int in other.polygon.size():
						if other.polygon[j].distance_to(at) < 0.5:
							_corners.append([other, j])
				return true
	return false


func position() -> Vector2:
	if _node != &"":
		return map.nodes[_node]
	if _landmark != null:
		return _landmark.pos
	var first: Array = _corners[0]
	return (first[0] as DistrictMapDef.ZoneDef).polygon[first[1] as int]


## What the line over the map shows: the point's name and its coordinates.
func label() -> String:
	if _node != &"":
		return str(_node)
	if _landmark != null:
		return str(_landmark.id)
	var names := PackedStringArray()
	for c: Array in _corners:
		names.append("%s #%d" % [(c[0] as DistrictMapDef.ZoneDef).id, c[1] as int])
	return ", ".join(names)


func start_move(mouse_art: Vector2) -> void:
	moving = true
	_offset = position() - mouse_art


## Moves the picked point after the mouse; returns its new position.
func move_to(mouse_art: Vector2) -> Vector2:
	var p := (mouse_art + _offset).round()
	if _node != &"":
		map.nodes[_node] = p
	elif _landmark != null:
		_landmark.pos = p
	else:
		for c: Array in _corners:
			var z := c[0] as DistrictMapDef.ZoneDef
			z.polygon[c[1] as int] = p
	return p
