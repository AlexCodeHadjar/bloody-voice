class_name GearDrawerView
extends Control
## The drawer with spare gear (owner 2026-10-14, sketch docs/assets/ui/equipment_workbench.png): tabs «Модули» and
## «Механизмы», each spare copy in a felt tray with its picture, name, tier and what it does. A click on a tray takes
## it into the hand (the screen holds it); the tray in hand is lit.

signal picked(kind: StringName, id: StringName, tier: int)  ## kind: module | mechanism

const DRAWER_ART := "res://art/ui/EQUIP__drawer.webp"
const SLOT_ART := "res://art/ui/EQUIP__drawer_slot.webp"
const TAB_ART := "res://art/ui/WORKSHOP__tab.webp"
const TRAY := Vector2(154, 184)

var tab: StringName = &"module"
var _grid: GridContainer
var _tabs: HBoxContainer
var _held_kind: StringName = &""
var _held_id: StringName = &""
var _held_tier := 1


func setup() -> void:
	var bg := NinePatchRect.new()
	bg.texture = UiKit.texture(DRAWER_ART)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		bg.set_patch_margin(side, 120)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:  # inside the drawer's wooden sides
		margin.add_theme_constant_override("margin_" + side, 44 if side != "top" else 52)
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)
	var title := UiKit.label(Loc.t("ui.equip.drawer"), 28, Palette.BRASS_LIGHT)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	v.add_child(title)
	_tabs = HBoxContainer.new()
	v.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)


func set_held(kind: StringName, id: StringName, tier: int) -> void:
	_held_kind = kind
	_held_id = id
	_held_tier = tier


func refresh() -> void:
	for c: Node in _tabs.get_children():
		c.queue_free()
	for t: StringName in [&"module", &"mechanism"]:
		_tabs.add_child(_tab_button(t))
	for c: Node in _grid.get_children():
		c.queue_free()
	var items := _spares()
	if items.is_empty():
		var empty := UiKit.paragraph(Loc.t("ui.equip.no_spares" if tab == &"module" else "ui.equip.no_mechanisms"), 16, Palette.FOG)
		empty.custom_minimum_size = Vector2(TRAY.x * 2, 0)
		_grid.add_child(empty)
	for item: Array in items:
		_grid.add_child(_tray(item[0] as StringName, item[1] as int))


## [id, tier] of every spare copy in the current tab (mechanisms have no tiers: 1).
func _spares() -> Array[Array]:
	var l := GameState.run.loadout
	var out: Array[Array] = []
	if tab == &"mechanism":
		for m: StringName in l.spare_mechanisms():
			out.append([m, 1])
		return out
	var seen: Dictionary[StringName, bool] = {}
	for id: StringName in l.owned_modules:
		if not seen.has(id):
			seen[id] = true
			for t: int in l.spare_tiers(id):
				out.append([id, t])
	return out


func _tab_button(t: StringName) -> Button:
	var b := Button.new()
	b.text = Loc.t("ui.equip.tab_%s" % t)
	b.custom_minimum_size = Vector2(150, 42)
	b.flat = true
	var art := TextureRect.new()
	art.texture = UiKit.texture(TAB_ART)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.modulate = Color.WHITE if t == tab else Color(0.55, 0.55, 0.55)
	art.show_behind_parent = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(art)
	b.add_theme_color_override("font_color", Palette.PARCHMENT if t == tab else Palette.FOG)
	b.pressed.connect(func() -> void:
		tab = t
		UiKit.sound(&"ui.click")
		refresh())
	return b


## One felt tray: picture, name and tier, what it does; lit when it is the copy in hand.
func _tray(id: StringName, tier: int) -> Control:
	var is_module := tab == &"module"
	var m := ContentDB.data.module(id) if is_module else null
	var mech := ContentDB.data.mechanism(id) if not is_module else null
	var b := Button.new()
	b.custom_minimum_size = TRAY
	b.flat = true
	b.tooltip_text = m.effect_at(tier) if is_module else mech.effect
	var slot := TextureRect.new()
	slot.texture = UiKit.texture(SLOT_ART)
	slot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_SCALE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lit := _held_kind == tab and _held_id == id and _held_tier == tier
	slot.modulate = Color(1.25, 1.1, 0.8) if lit else Color.WHITE
	b.add_child(slot)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 18
	v.offset_right = -18
	v.offset_top = 16
	v.offset_bottom = -12
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var pic := TextureRect.new()
	pic.texture = UiKit.texture(m.art_path() if is_module else Icons.path("MECHANISM", id))
	pic.custom_minimum_size = Vector2(0, 86)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(pic)
	var title := "%s %s" % [m.name, WorkshopKit.tier_text(tier)] if is_module else mech.name
	var name_label := UiKit.paragraph(title, 15, Palette.BRASS_LIGHT if lit else Palette.PARCHMENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)
	b.pressed.connect(func() -> void: picked.emit(tab, id, tier))
	return b
