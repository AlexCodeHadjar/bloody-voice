class_name BlueprintList
extends VBoxContainer
## The blueprint list of the workshop (GDD 23.1 zones 2–4): tabs Модули · Механизмы, «только доступные», rows with
## the item's picture, name, tier and cost. Unknown blueprints are dim with a lock and the trophy that teaches them.

signal picked(item: StringName)

var _kind: StringName = &"module"
var _only_ready := false
var _rows: VBoxContainer
var _tabs: Dictionary[StringName, Button] = {}
var selected: StringName = &""


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var tabs := HBoxContainer.new()
	for kind: StringName in WorkshopDefs.KINDS:
		var b := UiKit.button(Loc.t("ui.workshop.tab.%s" % kind), 18)
		b.custom_minimum_size = Vector2(170, 44)
		b.toggle_mode = true
		b.pressed.connect(_set_kind.bind(kind))
		tabs.add_child(b)
		_tabs[kind] = b
	var ready_box := CheckBox.new()
	ready_box.text = Loc.t("ui.workshop.only_ready")
	ready_box.toggled.connect(func(on: bool) -> void:
		_only_ready = on
		refresh())
	tabs.add_child(ready_box)
	add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)
	_set_kind(&"module")


func refresh() -> void:
	for kind: StringName in _tabs:
		_tabs[kind].button_pressed = kind == _kind
	for child: Node in _rows.get_children():
		child.queue_free()
	var data := ContentDB.data
	for id: StringName in data.blueprint_order:
		var bp := data.blueprint(id)
		if bp.kind != _kind:
			continue
		if _only_ready and WorkshopRules.can_craft(GameState.run, data, id) != "":
			continue
		_rows.add_child(_row(bp))


func _set_kind(kind: StringName) -> void:
	_kind = kind
	refresh()


func _row(bp: WorkshopDefs.BlueprintDef) -> Button:
	var known := GameState.run.workshop.blueprints.has(bp.item)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 84)
	b.toggle_mode = true
	b.button_pressed = bp.item == selected
	b.pressed.connect(func() -> void:
		selected = bp.item
		picked.emit(bp.item)
		refresh())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	h.add_child(UiKit.picture(WorkshopKit.item_art(bp.item), Vector2(72, 72)))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var title := WorkshopKit.item_name(bp.item)
	var owned := GameState.run.loadout.tiers_of(bp.item).size() if bp.kind == &"module" else GameState.run.loadout.owned_mechanisms.count(bp.item)
	if owned > 0:
		title += "   " + Loc.t("ui.workshop.owned_short", {"n": owned})
	v.add_child(UiKit.label(title, 18, Palette.BRASS_LIGHT if known else Palette.INK_MUTED))
	if known:
		v.add_child(WorkshopKit.cost_row(bp.cost, 15))
	else:
		v.add_child(Icons.with_text("UI", &"lock", Loc.t("ui.workshop.locked", {"trophy": WorkshopKit.stock_name(bp.unlock)}), 22, 15, Palette.INK_MUTED))
		b.modulate = Color(1, 1, 1, 0.6)
	return b
