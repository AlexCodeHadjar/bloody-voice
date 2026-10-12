class_name RumorPost
extends Control
## The leaflet post on Bonfire Square (GDD 20.6, owner 2026-10-12): every rumor diamond of the district as a list —
## picture, zone, how well it fits the best contract, days until it cools. «Идти» sends the hunter to the diamond.
## Full-screen overlay.

signal closed
signal rumor_chosen(uid: int)

const PANEL := Vector2(900, 0)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.97), Palette.BRASS))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var title := UiKit.label(Loc.t("ui.rumor.post_title"), 34, Palette.BRASS_LIGHT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(44, 44)
	close.pressed.connect(close_post)
	head.add_child(close)
	v.add_child(head)
	_fill(v)
	UiKit.sound(&"paper.map")


func _fill(v: VBoxContainer) -> void:
	var list := RumorRules.visible(GameState.run.rumors)
	if list.is_empty():
		v.add_child(UiKit.paragraph(Loc.t("ui.rumor.post_empty"), 19, Palette.FOG))
	for r: RumorsState.Rumor in list:
		v.add_child(_row(r))


func _row(r: RumorsState.Rumor) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.INK_MUTED))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	panel.add_child(h)
	h.add_child(UiKit.picture(UiKit.texture(RumorDefs.ART_DIR % r.art), Vector2(96, 96)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var map := ContentDB.data.district_map(GameState.run.hero_district)
	info.add_child(UiKit.label(ContractKit.zone_name(map, r.zone), 22, Palette.BRASS_LIGHT))
	var tags := PackedStringArray(r.tags.map(func(t: StringName) -> String: return ContractKit.tag_name(t)))
	info.add_child(UiKit.paragraph(", ".join(tags), 17, Palette.PARCHMENT))
	var best := RumorRules.best_contract(GameState.run.contracts, r)
	var fit := Loc.t("ui.rumor.no_contract_short") if best == null else Loc.t("ui.rumor.match",
		{"name": ContractKit.monster_name(best), "n": RumorRules.matches(r, best), "of": best.known_tags.size()})
	info.add_child(UiKit.label("%s · %s" % [fit, Loc.t("ui.rumor.cools", {"n": r.expires_day - GameState.run.day})], 15, Palette.FOG))
	var go := Icons.button("PLACE", &"hunter", Loc.t("ui.rumor.go"), 18)
	go.custom_minimum_size = Vector2(150, 48)
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		close_post()  # first, so the tablet can open at once if the hunter already stands there
		rumor_chosen.emit(r.uid))
	h.add_child(go)
	return panel


func close_post() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_post()
