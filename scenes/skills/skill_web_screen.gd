extends Control
## «Развитие охотника» (GDD 23.2): level, free points and the Voice on top, the Mechanic and Monster web tabs, the
## web itself and the card of the picked node with «Изучить» (a Monster node shows its blood sample and how much the
## Voice grows, and warns when it crosses a stage). Resetting the Mechanic web is done in the Scriptorium.

const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const WEBS: Array[StringName] = [&"mechanic", &"monster"]
const PREFIX: Dictionary[StringName, String] = {&"mechanic": "mech", &"monster": "beast"}

var _web: SkillDefs.WebDef
var _views: Dictionary[StringName, SkillWebView] = {}
var _tabs: Dictionary[StringName, Button] = {}
var _bg: TextureRect
var _top: Label
var _card: VBoxContainer
var _picked: StringName = &"start"


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"equipment")
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.progress_changed.connect(_refresh)
	_switch(&"mechanic")


func _build() -> void:
	_bg = TextureRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.stretch_mode = TextureRect.STRETCH_TILE
	_bg.modulate = Color(0.55, 0.55, 0.55)
	add_child(_bg)
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
	for id: StringName in WEBS:
		var view := SkillWebView.new()
		view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view.setup(ContentDB.data.webs[id], PREFIX[id])
		view.node_picked.connect(_pick)
		view.visible = false
		main.add_child(view)
		_views[id] = view
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
	for id: StringName in WEBS:
		var b := Icons.button("SKILL", id, Loc.t("ui.skills.tab.%s" % id), 18)
		b.custom_minimum_size = Vector2(190, 42)
		b.toggle_mode = true
		b.pressed.connect(_switch.bind(id))
		row.add_child(b)
		_tabs[id] = b
	var back := UiKit.button(Loc.t("ui.workshop.back"), 18)
	back.custom_minimum_size = Vector2(200, 42)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(DISTRICT))
	row.add_child(back)
	return bar


func _switch(web_id: StringName) -> void:
	_web = ContentDB.data.webs[web_id]
	_picked = &"start"
	_views[web_id].selected = &"start"  # the ring follows the card
	_bg.texture = UiKit.texture("res://art/ui/SKILLS__texture_%s.webp" % web_id)
	for id: StringName in WEBS:
		_views[id].visible = id == web_id
		_tabs[id].set_pressed_no_signal(id == web_id)
	_refresh()


func _refresh() -> void:
	var run := GameState.run
	var data := ContentDB.data
	_top.text = Loc.t("ui.skills.top", {"level": run.progress.level, "points": run.progress.skill_points})
	_top.text += "   " + Loc.t("ui.voice.now", {"n": run.voice, "stage": Loc.t("ui.voice.stage.%d" % VoiceRules.stage(run, data))})
	_views[_web.id].refresh()
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
	_card.add_child(UiKit.picture(UiKit.texture("res://art/ui/SKILLS__node_card__%s.webp" % _web.id), Vector2(0, 120)))
	_card.add_child(UiKit.label(nd.name, 28, Palette.BRASS_LIGHT))
	_card.add_child(UiKit.label(Loc.t("ui.skills.type.%s" % nd.type), 16, Palette.INK_MUTED))
	_card.add_child(UiKit.paragraph(nd.text, 18, Palette.PARCHMENT))
	if nd.blueprint != &"":
		var known := GameState.run.workshop.blueprints.has(nd.blueprint)
		_card.add_child(UiKit.paragraph(Loc.t("ui.skills.blueprint_known" if known else "ui.skills.blueprint_note"), 15, Palette.FOG))
	var run := GameState.run
	if nd.sample != &"" or nd.voice > 0:
		_blood_lines(nd)
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
	var note := "ui.skills.reset_note" if _web.id != &"monster" else "ui.skills.monster_note"
	_card.add_child(UiKit.paragraph(Loc.t(note), 14, Palette.INK_MUTED))


## A Monster node: the blood sample it uses up and what the hunter has, the Voice it adds, a stage warning.
func _blood_lines(nd: SkillDefs.NodeDef) -> void:
	var run := GameState.run
	var data := ContentDB.data
	if nd.sample != &"":
		var ws := run.workshop
		_card.add_child(Icons.with_text("STAT", &"voice", Loc.t("ui.skills.sample", {"name": WorkshopKit.sample_name(nd.sample, nd.pure),
			"n": ws.samples.get(nd.sample, 0), "p": ws.pure_samples.get(nd.sample, 0)}), 26, 16, Palette.PARCHMENT))
	if nd.voice > 0:
		_card.add_child(Icons.with_text("STAT", &"voice", Loc.t("ui.skills.voice_cost", {"n": nd.voice}), 26, 16, Palette.PARCHMENT))
	var after := VoiceRules.stage(run, data, run.voice + nd.voice)
	if not SkillRules.is_owned(run, _web, nd.id) and after > VoiceRules.stage(run, data):
		_card.add_child(UiKit.picture(UiKit.texture("res://art/ui/SKILLS__voice_warning.webp"), Vector2(0, 60)))
		_card.add_child(UiKit.paragraph(Loc.t("ui.skills.voice_warning", {"stage": Loc.t("ui.voice.stage.%d" % after),
			"what": Loc.t("ui.voice.effect.%d" % after)}), 15, Palette.ALARM))


func _buy(node_id: StringName) -> void:
	var problem := GameState.buy_skill(_web.id, node_id)
	UiKit.sound(&"ui.error" if problem != "" else &"gear.install")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(DISTRICT)
