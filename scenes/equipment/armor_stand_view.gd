class_name ArmorStandView
extends Control
## The armor on the mannequin (owner 2026-10-14, sketch docs/assets/ui/equipment_workbench.png): each armor piece is a
## brass socket on the stand with its icon, its mechanism sockets are small dots beside it (the mechanism's icon when
## filled). Reports a click on a mechanism socket; the screen decides what to do (GameState.set_socket).

signal socket_clicked(piece: StringName, index: int)

const VIEW := Vector2(340, 600)
const STAND := Rect2(60, 20, 220, 446)  ## the mannequin art
const STAND_ART := "res://art/ui/EQUIP__mannequin.webp"
const SOCKET_ART := "res://art/ui/EQUIP__armor_socket.webp"
const SOCKET := 74.0
const DOT := 34.0
## Where each piece sits on the mannequin (share of the art's width and height).
const SPOTS: Dictionary[StringName, Vector2] = {&"helmet": Vector2(0.5, 0.05), &"chestplate": Vector2(0.5, 0.25),
	&"gauntlets": Vector2(0.12, 0.43), &"greaves": Vector2(0.42, 0.62)}

var _data: ContentData
var _loadout: LoadoutState
var _font: Font
var _dots: Array[Array] = []  ## [Rect2, piece, index] of every mechanism socket drawn
var _hover := -1
var _textures: Dictionary[String, Texture2D] = {}  ## kept: a texture nobody holds draws white


func setup(data: ContentData, loadout: LoadoutState) -> void:
	_data = data
	_loadout = loadout
	_font = UiKit.serif()
	custom_minimum_size = VIEW
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "socket"  # real text comes from _get_tooltip
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var stand := _tex(STAND_ART)
	if stand != null:
		draw_texture_rect(stand, STAND, false)
	_dots.clear()
	var i := 0
	for a: GearDefs.ArmorDef in _data.armor:
		var share: Vector2 = SPOTS.get(a.id, Vector2(0.5, 0.2 + 0.18 * i))
		var spot := STAND.position + STAND.size * share
		_draw_piece(a, spot)
		i += 1


func _draw_piece(a: GearDefs.ArmorDef, spot: Vector2) -> void:
	var ring := _tex(SOCKET_ART)
	var box := Rect2(spot - Vector2(SOCKET, SOCKET) * 0.5, Vector2(SOCKET, SOCKET))
	if ring != null:
		draw_texture_rect(ring, box, false)
	var icon := _tex(Icons.path("ARMOR", a.id))
	if icon != null:
		draw_texture_rect(icon, box.grow(-SOCKET * 0.24), false)
	for k: int in ArmorRules.socket_count(_loadout, a):
		var dot := Rect2(spot + Vector2(SOCKET * 0.5 + 6 + k * (DOT + 4), -DOT * 0.5), Vector2(DOT, DOT))
		var mech := ArmorRules.mechanism_at(_loadout, a.id, k)
		var art := _tex(Icons.path("MECHANISM", mech) if mech != &"" else Icons.path("ARMOR", &"mechanism_socket"))
		draw_circle(dot.get_center(), DOT * 0.55, Color(0.08, 0.06, 0.05, 0.9))
		if art != null:
			draw_texture_rect(art, dot, false, Color.WHITE if mech != &"" else Color(1, 1, 1, 0.55))
		var hot := _hover == _dots.size()
		draw_arc(dot.get_center(), DOT * 0.55, 0.0, TAU, 24, Palette.BRASS_LIGHT if hot else Palette.BRASS, 3.0 if hot else 2.0)
		_dots.append([dot, a.id, k])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var at := _dot_at((event as InputEventMouseMotion).position)
		if at != _hover:
			_hover = at
			queue_redraw()
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _hover >= 0:
		socket_clicked.emit(_dots[_hover][1] as StringName, _dots[_hover][2] as int)
		accept_event()


func _dot_at(pos: Vector2) -> int:
	for i: int in _dots.size():
		if (_dots[i][0] as Rect2).grow(4).has_point(pos):
			return i
	return -1


func _get_tooltip(at_position: Vector2) -> String:
	var i := _dot_at(at_position)
	if i < 0:
		return ""
	var piece := _data.armor.filter(func(a: GearDefs.ArmorDef) -> bool: return a.id == _dots[i][1])
	var mech := ArmorRules.mechanism_at(_loadout, _dots[i][1] as StringName, _dots[i][2] as int)
	var title: String = (piece[0] as GearDefs.ArmorDef).name if not piece.is_empty() else ""
	if mech == &"":
		return "%s\n%s" % [title, Loc.t("ui.equip.socket_empty_tip")]
	var m := _data.mechanism(mech)
	return "%s — %s\n%s" % [title, m.name, m.effect]


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = UiKit.texture(path)
	return _textures[path]
