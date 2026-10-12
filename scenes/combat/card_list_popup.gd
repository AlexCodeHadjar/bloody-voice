class_name CardListPopup
extends Control
## A pile's cards as a list on a dimmed screen (draw pile sorted so its order stays hidden). Click anywhere or Esc closes.

signal closed


func setup(title: String, cards: Array[CardInstance]) -> CardListPopup:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.015, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var box := VBoxContainer.new()  # its mouse filter passes clicks up to this popup, which closes on any click
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 140
	box.offset_right = -140
	box.offset_top = 40
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var head := UiKit.label(title, 34, Palette.BRASS_LIGHT)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	if cards.is_empty():
		var empty := UiKit.label(Loc.t("ui.combat.pile_empty"), 24, Palette.FOG)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(empty)
	box.add_child(_card_grid(cards))
	var close := UiKit.button(Loc.t("ui.combat.close"))
	close.pressed.connect(close_popup)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(close)
	return self


func _card_grid(cards: Array[CardInstance]) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	var grid := HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(grid)
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a: CardInstance, b: CardInstance) -> bool:
		return a.def.type < b.def.type or (a.def.type == b.def.type and a.def.name < b.def.name))
	for c: CardInstance in sorted:
		var view := CardView.new().setup(c)
		view.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(view)
	return scroll


func close_popup() -> void:
	closed.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		close_popup()
		accept_event()
