extends Control
## «Развитие охотника» (GDD 23.2): level, XP and free points on top, the web tabs (the Monster web comes in the next
## step), the web itself and the card of the picked node with «Изучить». Resetting a web is done in the Scriptorium.

const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const TEXTURE := "res://art/ui/SKILLS__texture_mechanic.webp"
const CARD_ART := "res://art/ui/SKILLS__node_card__mechanic.webp"

var _web: SkillDefs.WebDef
var _view: SkillWebView
var _top: Label
var _card: VBoxContainer
var _picked: StringName = &"start"


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"equipment")
	if not GameState.has_run():
		GameState.new_game()
	_web = ContentDB.data.webs.get(&"mechanic") as SkillDefs.WebDef
	_build()
	EventBus.progress_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = UiKit.texture(TEXTURE)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_TILE
	bg.modulate = Color(0.55, 0.55, 0.55)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(_build_top())
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	root.add_child(main)
	_view = SkillWebView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.setup(_web, "mech")
	_view.node_picked.connect(_pick)
	main.add_child(_view)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.07, 0.06, 0.05, 0.94), Palette.BRASS))
	_card = VBoxContainer.new()
	_card.add_theme_constant_override("separation", 10)
	panel.add_child(_card)
	main.add_child(panel)


func _build_top() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)
	row.add_child(UiKit.label(Loc.t("ui.skills.title"), 30, Palette.BRASS_LIGHT))
	_top = UiKit.label("", 18, Palette.PARCHMENT)
	_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_top)
	for tab: Array in [["ui.skills.tab.mechanic", false], ["ui.skills.tab.monster", true]]:
		var b := UiKit.button(Loc.t(tab[0] as String), 18)
		b.custom_minimum_size = Vector2(190, 42)
		b.toggle_mode = true
		b.button_pressed = not tab[1]
		b.disabled = tab[1]
		if tab[1]:
			b.tooltip_text = Loc.t("ui.skills.monster_soon")
		row.add_child(b)
	var back := UiKit.button(Loc.t("ui.workshop.back"), 18)
	back.custom_minimum_size = Vector2(200, 42)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(DISTRICT))
	row.add_child(back)
	return bar


func _refresh() -> void:
	var pr := GameState.run.progress
	_top.text = Loc.t("ui.skills.top", {"level": pr.level, "points": pr.skill_points})
	_view.refresh()
	_show_card()


func _pick(node_id: StringName) -> void:
	_picked = node_id
	_show_card()


func _show_card() -> void:
	for child: Node in _card.get_children():
		child.queue_free()
	var nd := _web.node(_picked)
	if nd == null:
		return
	_card.add_child(UiKit.picture(UiKit.texture(CARD_ART), Vector2(0, 120)))
	_card.add_child(UiKit.label(nd.name, 28, Palette.BRASS_LIGHT))
	_card.add_child(UiKit.label(Loc.t("ui.skills.type.%s" % nd.type), 16, Palette.INK_MUTED))
	_card.add_child(UiKit.paragraph(nd.text, 18, Palette.PARCHMENT))
	if nd.blueprint != &"":
		var known := GameState.run.workshop.blueprints.has(nd.blueprint)
		_card.add_child(UiKit.paragraph(Loc.t("ui.skills.blueprint_known" if known else "ui.skills.blueprint_note"), 15, Palette.FOG))
	var run := GameState.run
	if SkillRules.is_owned(run, _web, nd.id):
		_card.add_child(UiKit.label(Loc.t("ui.skills.owned"), 18, Palette.BRASS))
	else:
		var problem := SkillRules.can_buy(run, ContentDB.data, _web, nd.id)
		var b := Icons.button("STAT", &"skill_point", Loc.t("ui.skills.buy", {"n": ContentDB.data.balance.skills.node_cost}), 20)
		b.disabled = problem != ""
		b.tooltip_text = problem
		b.pressed.connect(_buy.bind(nd.id))
		_card.add_child(b)
		if problem != "":
			_card.add_child(UiKit.paragraph(problem, 15, Palette.ALARM))
	_card.add_child(UiKit.paragraph(Loc.t("ui.skills.reset_note"), 14, Palette.INK_MUTED))


func _buy(node_id: StringName) -> void:
	var problem := GameState.buy_skill(_web.id, node_id)
	UiKit.sound(&"ui.error" if problem != "" else &"gear.install")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(DISTRICT)
