class_name ShiftPanel
extends Control
## The morning after a tavern shift (GDD 3.3): the keeper's portrait, the money earned and a line of gossip.
## Full-screen overlay.

signal closed

const KEEPER := "res://art/ui/NPC__portrait__tavern_keeper.webp"


func show_report(r: ShiftRules.Report) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # fill the screen, not keep the 0×0 size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.97), Palette.BRASS))
	center.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	panel.add_child(h)
	h.add_child(UiKit.picture(UiKit.texture(KEEPER), Vector2(220, 220)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	h.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.shift.title"), 32, Palette.BRASS_LIGHT))
	v.add_child(Icons.with_text("RESOURCE", &"money", Loc.t("ui.shift.money", {"n": r.money}), 30, 20, Palette.BRASS_LIGHT))
	for g: RumorDefs.Witness in ContentDB.data.rumor_data.gossip:
		if g.id == r.gossip:
			v.add_child(UiKit.paragraph("«%s»" % g.text, 18, Palette.PARCHMENT))
	v.add_child(UiKit.label(Loc.t("ui.rumor.day_over"), 16, Palette.INK_MUTED))
	var next := UiKit.button(Loc.t("ui.rumor.next"), 20)
	next.pressed.connect(close_panel)
	v.add_child(next)
	UiKit.sound(&"money.coins")


func close_panel() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_panel()
