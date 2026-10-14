class_name WeaponTabletView
extends Control
## The rifle on the workbench (owner 2026-10-14, sketch docs/assets/ui/equipment_workbench.png): the weapon art large,
## each section's cells beside it with a brass leader line to its part, the placed modules (their art, rotated) and
## a ghost of the module in hand. Reports clicks on cells and the installed module under the mouse; the screen decides
## what to do (GameState commands).

signal cell_clicked(section: StringName, cell: Vector2i)
signal rotate_requested
signal module_hovered(module_name: String)  ## "" when the mouse leaves every installed module

const CELL := 54.0
const VIEW := Vector2(1050, 600)
const RIFLE := Rect2(35, 142, 980, 252)  ## the weapon art
const RIFLE_ART := "res://art/ui/EQUIP__rifle__hunting.webp"
const PIN := "res://art/ui/EQUIP__leader_pin.webp"
const CELL_ART := "res://art/ui/EQUIP__cell__%s.webp"
## Where each section's cells sit (top-left of the grid) and the point of the rifle art its leader line goes to
## (share of the art's width and height).
const LAYOUT: Dictionary[StringName, Vector2] = {&"sight": Vector2(600, 60), &"stock": Vector2(40, 446),
	&"frame": Vector2(250, 446), &"magazine": Vector2(510, 446), &"barrel": Vector2(660, 446)}
const TARGETS: Dictionary[StringName, Vector2] = {&"sight": Vector2(0.45, 0.08), &"stock": Vector2(0.13, 0.55),
	&"frame": Vector2(0.38, 0.40), &"magazine": Vector2(0.43, 0.75), &"barrel": Vector2(0.80, 0.33)}
## Empty cells without art: dark, clearly different per type. Modules without art get a bright colour + outline.
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
var _hover_module := ""
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
	_hover_module = ""  # the module under the mouse may have just been taken off
	queue_redraw()


## Sections at their places around the rifle; a section the layout does not know goes after the barrel.
func _layout() -> void:
	var weapon := _data.weapon(_loadout.weapon)
	_origins.clear()
	custom_minimum_size = VIEW
	if weapon == null:
		return
	var x := 960.0
	for s: WeaponDef.SectionDef in weapon.sections:
		if LAYOUT.has(s.id):
			_origins[s.id] = LAYOUT[s.id]
		else:
			_origins[s.id] = Vector2(x, 446)
			x += (_section_size(s).x + 1) * CELL


func _section_size(s: WeaponDef.SectionDef) -> Vector2i:
	var size_cells := Vector2i.ZERO
	for c: Vector2i in s.cells:
		size_cells = Vector2i(maxi(size_cells.x, c.x + 1), maxi(size_cells.y, c.y + 1))
	return size_cells


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


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_update_hover(Vector2(-9999, -9999))


func _update_hover(pos: Vector2) -> void:
	var weapon := _data.weapon(_loadout.weapon)
	var section := &""
	var cell := Vector2i(-99, -99)
	if weapon != null:
		for s: WeaponDef.SectionDef in weapon.sections:
			var c := Vector2i(((pos - _origins[s.id]) / CELL).floor())
			if s.cells.has(c):
				section = s.id
				cell = c
	if section != _hover_section or cell != _hover_cell:
		_hover_section = section
		_hover_cell = cell
		queue_redraw()
	var i := WeaponGridRules.placement_at(_loadout, _data, section, cell) if section != &"" else -1
	var module_name := _data.module(_loadout.placements[i].module).name if i >= 0 else ""
	if module_name != _hover_module:
		_hover_module = module_name
		module_hovered.emit(module_name)


func _draw() -> void:
	var weapon := _data.weapon(_loadout.weapon) if _data != null else null
	if weapon == null:
		return
	var rifle := _tex(RIFLE_ART)
	if rifle != null:
		draw_texture_rect(rifle, RIFLE, false)
	for s: WeaponDef.SectionDef in weapon.sections:
		_draw_section(s)
	for i: int in _loadout.placements.size():
		_draw_module(_loadout.placements[i], MODULE_COLORS[i % MODULE_COLORS.size()])
	_draw_valid_anchors(weapon)
	_draw_ghost()
	_draw_legend()


## A section: its leader line to the rifle part, its icon and name, its cells (the empty-cell art by type).
func _draw_section(s: WeaponDef.SectionDef) -> void:
	var o: Vector2 = _origins[s.id]
	var cells := _section_size(s)
	if TARGETS.has(s.id):
		var target := RIFLE.position + RIFLE.size * TARGETS[s.id]
		var below := o.y > RIFLE.position.y
		var start := o + Vector2(cells.x * CELL * 0.5, -40.0 if below else cells.y * CELL + 6.0)
		draw_dashed_line(start, target, Color(Palette.BRASS_LIGHT, 0.85), 3.0, 10.0)
		var pin := _tex(PIN)
		if pin != null:
			draw_texture_rect(pin, Rect2(target - Vector2(13, 13), Vector2(26, 26)), false)
	var icon := _tex(Icons.path("SECTION", s.id))
	if icon != null:
		draw_texture_rect(icon, Rect2(o + Vector2(0, -34), Vector2(28, 28)), false)
	draw_string_outline(_font, o + Vector2(34, -12), s.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, 6, Color(0, 0, 0, 0.85))
	draw_string(_font, o + Vector2(34, -12), s.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Palette.BRASS_LIGHT)
	for c: Vector2i in s.cells:
		var kind := _loadout.cell_type(s, c)
		var r := Rect2(o + Vector2(c) * CELL, Vector2(CELL, CELL))
		var cell_art := _tex(CELL_ART % kind)
		if cell_art != null:
			draw_texture_rect(cell_art, r, false)
		else:
			draw_rect(r.grow(-2), CELL_COLORS.get(kind, Palette.INK_MUTED))


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


## A module: its art turned like the placement (or its cells in one colour), outlined as one shape.
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
				draw_line(e[1] as Vector2, e[2] as Vector2, Palette.BRASS_LIGHT if has_art else Palette.SOOT, 2.0 if has_art else 3.0)
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
	var art_size := Vector2(_bbox(base)) * CELL
	var center: Vector2 = _origins[p.section] + (Vector2(p.pos) + Vector2(_bbox(turned)) / 2.0) * CELL
	draw_set_transform(center, p.rot * PI / 2.0, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-art_size / 2.0, art_size), false, tint)
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
			var p := _loadout.placements[i]
			var m := _data.module(p.module)
			return "%s %s\n%s" % [m.name, WorkshopKit.tier_text(p.tier), m.effect_at(p.tier)]
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


## The cell types and what the green frame means, along the bottom.
func _draw_legend() -> void:
	var y := size.y - 14.0
	var x := 40.0
	for kind: StringName in [&"gear", &"spark", &"blood"]:
		var cell_art := _tex(CELL_ART % kind)
		if cell_art != null:
			draw_texture_rect(cell_art, Rect2(Vector2(x - 4, y - 21), Vector2(26, 26)), false)
		else:
			draw_rect(Rect2(Vector2(x, y - 16), Vector2(18, 18)), CELL_COLORS[kind])
		draw_string(_font, Vector2(x + 28, y), Loc.t("ui.equip.cell_legend", {"cell": Loc.t("cell.%s" % kind)}), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.PARCHMENT)
		x += 200.0
	draw_string(_font, Vector2(x + 20, y), Loc.t("ui.equip.fit_legend"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Palette.PARCHMENT)
