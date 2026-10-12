class_name ContractTracker
extends VBoxContainer
## The tracker in the top-right corner (GDD 7.1): one row per taken contract — silhouette, name, days left and
## the region icon. The icon makes the zone where the creature was last seen glow on the map; the row opens the
## contract tablet. Hidden while no contract is taken.

signal zone_requested(zone: StringName)
signal contract_opened(list: Array[ContractsState.Contract], index: int)

const WIDTH := 360.0


func _ready() -> void:
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.contracts_changed.connect(refresh)
	EventBus.day_changed.connect(func(_d: int) -> void: refresh())
	refresh()


func refresh() -> void:
	for child: Node in get_children():
		child.queue_free()
	var list := ContractRules.active(GameState.run.contracts)
	visible = not list.is_empty()
	if list.is_empty():
		return
	var title := UiKit.label(Loc.t("ui.contract.tracker"), 18, Palette.BRASS_LIGHT)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	add_child(title)
	for i: int in list.size():
		add_child(_row(list, i))


func _row(list: Array[ContractsState.Contract], index: int) -> PanelContainer:
	var c := list[index]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.tooltip_text = Loc.t("ui.contract.open_hint")
	panel.gui_input.connect(_on_row_input.bind(list, index))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	panel.add_child(h)
	h.add_child(ContractKit.picture(ContractKit.silhouette(c), Vector2(48, 48)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(Icons.with_text("CONTRACT", c.type, ContractKit.monster_name(c), 22, 17))
	v.add_child(UiKit.label(ContractKit.deadline_text(c), 15, ContractKit.deadline_color(c, Palette.FOG)))
	if c.zone != &"":
		var region := Icons.button("CONTRACT", &"region", "", 14)
		region.custom_minimum_size = Vector2(44, 44)
		region.tooltip_text = Loc.t("ui.contract.region_hint", {"zone": ContractKit.last_seen(c)})
		region.pressed.connect(func() -> void: zone_requested.emit(c.zone))
		h.add_child(region)
	return panel


func _on_row_input(event: InputEvent, list: Array[ContractsState.Contract], index: int) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		UiKit.sound(&"ui.click")
		contract_opened.emit(list, index)
