class_name ContractTracker
extends VBoxContainer
## The contracts list at the right edge of the district screen (GDD 7.1; owner 2026-10-14): one panel with a title and a
## row per taken contract — name, days left and the region icon (no silhouette: owner 2026-10-14). The icon makes the zone where the creature was last seen glow on the map; the row opens the
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
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.045, 0.035, 0.88), Palette.BRASS))
	add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var title := UiKit.label(Loc.t("ui.contract.tracker"), 22, Palette.BRASS_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	for i: int in list.size():
		var line := ColorRect.new()  # a thin brass rule between the title and each row
		line.color = Color(Palette.BRASS, 0.45)
		line.custom_minimum_size = Vector2(0, 1)
		v.add_child(line)
		v.add_child(_row(list, i))


func _row(list: Array[ContractsState.Contract], index: int) -> PanelContainer:
	var c := list[index]
	var panel := PanelContainer.new()
	var flat := StyleBoxFlat.new()  # a row of the list: no frame of its own, a soft light under the mouse
	flat.bg_color = Color(1, 1, 1, 0.0)
	flat.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", flat)
	panel.mouse_entered.connect(func() -> void: flat.bg_color = Color(1.0, 0.85, 0.5, 0.08))
	panel.mouse_exited.connect(func() -> void: flat.bg_color = Color(1, 1, 1, 0.0))
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.tooltip_text = Loc.t("ui.contract.open_hint")
	panel.gui_input.connect(_on_row_input.bind(list, index))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	panel.add_child(h)
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
