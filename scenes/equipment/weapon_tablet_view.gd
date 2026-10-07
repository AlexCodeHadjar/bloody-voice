class_name WeaponTabletView
extends Control
## Draws the weapon's sections as cell grids, the placed modules (their art, rotated) and a ghost of the
## module in hand.
## Reports clicks on cells; the screen decides what to do (GameState commands).

signal cell_clicked(section: StringName, cell: Vector2i)
signal rotate_requested

const CELL := 54.0
const GAP_CELLS := 1
const TITLE_H := 34.0
const LEGEND_H := 40.0
## Empty cells: dark, clearly different per type. Installed modules get their own bright colour + outline.
const CELL_COLORS: Dictionary[StringName, Color] = {
	&"gear": Color("4a3f2e"), &"spark": Color("23466e"), &"blood": Color("6a2222"),
}
const MODULE_COLORS: Array[Color] = [
	Color("c9a35a"), Color("8fb07a"), Color("c98a5a"), Color("a98fc9"), Color("6fb0b0"), Color("c96f8a"),
]
const VALID_ANCHOR := Color(0.45, 0.95, 0.55, 0.9)

var _data: ContentData
var _loadout: LoadoutState
var _origins: Dictionary[StringName, Vector2] = {}
var _ghost_module: StringName = &""
var _ghost_rot: int = 0
var _hover_section: StringName = &""
var _hover_cell := Vector2i(-99, -99)
var _font: Font
## Textures used in _draw must stay referenced here: draw calls keep only the RID, a freed texture draws white.
var _textures: Dictionary[String, Texture2D] = {}


func setup(data: ContentData, loadout: LoadoutState) -> void:
	_data = data
	_loadout = loadout
	_font = UiKit.serif()
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "module"  # real text comes from _get_tooltip
	_layout()
	queue_redraw()


func set_ghost(module: StringName, rot: int) -> void:
	_ghost_module = module
	_ghost_rot = rot
	queue_redraw()


func refresh() -> void:
	queue_redraw()


## Sections in a row: stock, frame, magazine, sight, barrel (roughly the rifle from butt to muzzle).
func _layout() -> void:
	var weapon := _data.weapon(_loadout.weapon)
	_origins.clear()
	if weapon == null:
		return
	var x := 0.0
	var tallest := 0.0
	for s: WeaponDef.SectionDef in _ordered(weapon):
		_origins[s.id] = Vector2(x, TITLE_H)
		var size_cells := _section_size(s)
		x += (size_cells.x + GAP_CELLS) * CELL
		tallest = maxf(tallest, size_cells.y * CELL)
	custom_minimum_size = Vector2(x, TITLE_H + tallest + LEGEND_H)


func _ordered(weapon: WeaponDef) -> Array[WeaponDef.SectionDef]:
	var order: Array[StringName] = [&"stock", &"frame", &"magazine", &"sight", &"barrel"]
	var out: Array[WeaponDef.SectionDef] = []
	for id: StringName in order:
		if weapon.section(id) != null:
			out.append(weapon.section(id))
	for s: WeaponDef.SectionDef in weapon.sections:
		if not out.has(s):
			out.append(s)
	return out


func _section_size(s: WeaponDef.SectionDef) -> Vector2i:
	var size := Vector2i.ZERO
	for c: Vector2i in s.cells:
		size = Vector2i(maxi(size.x, c.x + 1), maxi(size.y, c.y + 1))
	return size


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		rotate_requested.emit()
		accept_event()
	elif mb.button_index == MOUSE_BUTTON_LEFT and _hover_section != &"":
		cell_clicked.emit(_hover_section, _hover_cell)
		accept_event()


func _update_hover(pos: Vector2) -> void:
	var weapon := _data.weapon(_loadout.weapon)
	var section := &""
	var cell := Vector2i(-99, -99)
	if weapon != null:
		for s: WeaponDef.SectionDef in weapon.sections:
			var local := pos - _origins[s.id]
			var c := Vector2i(floori(local.x / CELL), floori(local.y / CELL))
			if s.cells.has(c):
				section = s.id
				cell = c
	if section != _hover_section or cell != _hover_cell:
		_hover_section = section
		_hover_cell = cell
		queue_redraw()


func _draw() -> void:
	var weapon := _data.weapon(_loadout.weapon) if _data != null else null
	if weapon == null:
		return
	for s: WeaponDef.SectionDef in weapon.sections:
		var o: Vector2 = _origins[s.id]
		var icon := _tex(Icons.path("SECTION", s.id))
		if icon != null:
			draw_texture_rect(icon, Rect2(o + Vector2(0, -32), Vector2(28, 28)), false)
		draw_string(_font, o + Vector2(32 if icon != null else 0, -10), s.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Palette.PARCHMENT)
		for c: Vector2i in s.cells:
			var r := Rect2(o + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-2)
			draw_rect(r, CELL_COLORS.get(s.cells[c], Palette.INK_MUTED))
			draw_rect(r, Palette.SOOT, false, 2.0)
	for i: int in _loadout.placements.size():
		var p: LoadoutState.Placement = _loadout.placements[i]
		_draw_module(p, MODULE_COLORS[i % MODULE_COLORS.size()])
	_draw_valid_anchors(weapon)
	_draw_ghost()
	_draw_legend()


## Where the held module can go with its current rotation: outlined anchor cells.
func _draw_valid_anchors(weapon: WeaponDef) -> void:
	if _ghost_module == &"":
		return
	var m := _data.module(_ghost_module)
	var s := weapon.section(m.section) if m != null else null
	if s == null:
		return
	for c: Vector2i in s.cells:
		if WeaponGridRules.can_place(_loadout, _data, _ghost_module, s.id, c, _ghost_rot) == "":
			draw_rect(Rect2(_origins[s.id] + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-4), VALID_ANCHOR, false, 3.0)


func _draw_ghost() -> void:
	if _ghost_module == &"" or _hover_section == &"":
		return
	var p := LoadoutState.Placement.new()
	p.module = _ghost_module
	p.section = _hover_section
	p.pos = _hover_cell
	p.rot = _ghost_rot
	var ok := WeaponGridRules.can_place(_loadout, _data, _ghost_module, _hover_section, _hover_cell, _ghost_rot) == ""
	var o: Vector2 = _origins[_hover_section]
	_draw_art(p, Color(1, 1, 1, 0.6))
	for c: Vector2i in WeaponGridRules.covered(p, _data):
		var r := Rect2(o + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-6)
		draw_rect(r, Color(0.4, 0.9, 0.5, 0.3) if ok else Color(0.9, 0.25, 0.2, 0.45))


## A module: its cells in one colour, joined, with an outline around the whole shape and its name.
func _draw_module(p: LoadoutState.Placement, col: Color) -> void:
	var m := _data.module(p.module)
	if m == null or not _origins.has(p.section):
		return
	var o: Vector2 = _origins[p.section]
	var cells := WeaponGridRules.covered(p, _data)
	var has_art := _draw_art(p, Color.WHITE)
	if not has_art:
		for c: Vector2i in cells:
			draw_rect(Rect2(o + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-3), col)
	for c: Vector2i in cells:
		var r := Rect2(o + Vector2(c) * CELL, Vector2(CELL, CELL)).grow(-3)
		var edges: Array = [[Vector2i.UP, r.position, r.position + Vector2(r.size.x, 0)],
			[Vector2i.DOWN, r.position + Vector2(0, r.size.y), r.end],
			[Vector2i.LEFT, r.position, r.position + Vector2(0, r.size.y)],
			[Vector2i.RIGHT, r.position + Vector2(r.size.x, 0), r.end]]
		for e: Array in edges:
			if not cells.has(c + (e[0] as Vector2i)):
				draw_line(e[1] as Vector2, e[2] as Vector2, col if has_art else Palette.SOOT, 2.0 if has_art else 3.0)
	if not has_art:
		_draw_name(m.name, o, cells)


## The module's art, turned like the placement. Returns false when the module has no art.
func _draw_art(p: LoadoutState.Placement, tint: Color) -> bool:
	var m := _data.module(p.module)
	if m == null or not _origins.has(p.section) or not _data.shapes.has(m.shape):
		return false
	var tex := _tex(m.art_path())
	if tex == null:
		return false
	var base := WeaponGridRules.rotated(_data.shapes[m.shape].cells, 0)
	var turned := WeaponGridRules.rotated(base, p.rot)
	var size := Vector2(_bbox(base)) * CELL
	var center: Vector2 = _origins[p.section] + (Vector2(p.pos) + Vector2(_bbox(turned)) / 2.0) * CELL
	draw_set_transform(center, p.rot * PI / 2.0, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-size / 2.0, size), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = UiKit.texture(path)
	return _textures[path]


static func _bbox(cells: Array[Vector2i]) -> Vector2i:
	var out := Vector2i.ZERO
	for c: Vector2i in cells:
		out = Vector2i(maxi(out.x, c.x + 1), maxi(out.y, c.y + 1))
	return out


## Hovering an installed module names it and says what it does.
func _get_tooltip(at_position: Vector2) -> String:
	for s: StringName in _origins:
		var c := Vector2i(((at_position - _origins[s]) / CELL).floor())
		var i := WeaponGridRules.placement_at(_loadout, _data, s, c)
		if i >= 0:
			var m := _data.module(_loadout.placements[i].module)
			return "%s\n%s" % [m.name, m.effect]
	return ""


## The module name once, word per line, inside the module's top row of cells (never over other cells).
func _draw_name(module_name: String, o: Vector2, cells: Array[Vector2i]) -> void:
	if cells.is_empty():
		return
	var top := cells[0]
	for c: Vector2i in cells:
		if c.y < top.y or (c.y == top.y and c.x < top.x):
			top = c
	var run := 1
	while cells.has(top + Vector2i(run, 0)):
		run += 1
	var width := run * CELL - 10.0
	var y := 17.0
	for word: String in module_name.split(" "):
		draw_string(_font, o + Vector2(top) * CELL + Vector2(5, y), word, HORIZONTAL_ALIGNMENT_LEFT, width, 12, Palette.SOOT)
		y += 13.0


func _draw_legend() -> void:
	var y := size.y - 14.0
	var x := 0.0
	for kind: StringName in [&"gear", &"spark", &"blood"]:
		draw_rect(Rect2(Vector2(x, y - 16), Vector2(18, 18)), CELL_COLORS[kind])
		draw_rect(Rect2(Vector2(x, y - 16), Vector2(18, 18)), Palette.FOG, false, 1.0)
		var icon := _tex(Icons.path("CELL", kind))
		if icon != null:
			draw_texture_rect(icon, Rect2(Vector2(x - 3, y - 19), Vector2(24, 24)), false)
		draw_string(_font, Vector2(x + 26, y), "%s cell" % String(kind).capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.FOG)
		x += 140.0
	draw_string(_font, Vector2(x + 20, y), "Green outline = where the held module fits.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.FOG)
