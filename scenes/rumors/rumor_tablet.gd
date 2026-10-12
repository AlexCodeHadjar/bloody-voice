class_name RumorTablet
extends Control
## The rumor tablet (GDD 8.1): the picture on the left; on the right who tells it, the signs (highlighted; signs
## crossed out on the best-fitting contract are struck through), the confidence line «совпадает 2 из 3 известных
## примет» — never a guarantee — and «Расследовать» (the whole day) or «Пропустить». A rumor without a fight shows
## its outcome here. Full-screen overlay.

signal closed
signal fight_started

const PANEL := Vector2(1240, 700)
const TAG_COLOR := "d9b56a"
const CROSSED_COLOR := "8c8174"

var _uid := 0
var _art: TextureRect
var _right: VBoxContainer


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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	_art = ContractKit.picture(null, Vector2(560, 560))
	row.add_child(_art)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.add_theme_constant_override("separation", 12)
	row.add_child(_right)


func open_rumor(uid: int) -> void:
	_uid = uid
	var r := GameState.run.rumors.find(uid)
	if r == null:
		close_tablet()
		return
	_art.texture = UiKit.texture(RumorDefs.ART_DIR % r.art)
	_show_rumor(r)
	UiKit.sound(&"paper.map")
	Tutorial.trigger.call_deferred(&"first_rumor")


func _show_rumor(r: RumorsState.Rumor) -> void:
	_clear()
	var map := ContentDB.data.district_map(GameState.run.hero_district)
	_right.add_child(UiKit.label(Loc.t("ui.rumor.title"), 34, Palette.BRASS_LIGHT))
	_right.add_child(UiKit.label(ContractKit.zone_name(map, r.zone), 18, Palette.INK_MUTED))
	_right.add_child(UiKit.paragraph(_witness(r.witness), 19, Palette.PARCHMENT))
	var best := RumorRules.best_contract(GameState.run.contracts, r)
	var tags := _rich(_tag_lines(r, best), 20)
	_right.add_child(tags)
	TutorialAnchors.register(&"rumor_tags", tags)
	var match_box := _match_box(r, best)
	_right.add_child(match_box)
	TutorialAnchors.register(&"rumor_match", match_box)
	_right.add_child(UiKit.label(Loc.t("ui.rumor.cools", {"n": r.expires_day - GameState.run.day}), 16, Palette.INK_MUTED))
	_right.add_child(_gap())
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	var go := Icons.button("ACTION", &"investigate", Loc.t("ui.rumor.investigate"), 20)
	go.pressed.connect(_on_investigate)
	buttons.add_child(go)
	var skip := UiKit.button(Loc.t("ui.rumor.skip"), 20)
	skip.pressed.connect(close_tablet)
	buttons.add_child(skip)
	_right.add_child(buttons)
	TutorialAnchors.register(&"rumor_buttons", buttons)


func _witness(id: StringName) -> String:
	for wi: RumorDefs.Witness in ContentDB.data.rumor_data.witnesses:
		if wi.id == id:
			return wi.text
	return ""


## One line per sign, highlighted; signs crossed out on the best contract are struck through.
func _tag_lines(r: RumorsState.Rumor, best: ContractsState.Contract) -> String:
	var lines: PackedStringArray = []
	for t: StringName in r.tags:
		var text := "— " + ContractKit.tag_name(t)
		if best != null and best.crossed_tags.has(t):
			lines.append("[color=#%s][s]%s[/s][/color]" % [CROSSED_COLOR, text])
		else:
			lines.append("[color=#%s]%s[/color]" % [TAG_COLOR, text])
	return "\n".join(lines)


func _match_box(r: RumorsState.Rumor, best: ContractsState.Contract) -> VBoxContainer:
	var box := VBoxContainer.new()
	if best == null:
		box.add_child(UiKit.paragraph(Loc.t("ui.rumor.no_contract"), 17, Palette.FOG))
		return box
	box.add_child(Icons.with_text("CONTRACT", best.type, Loc.t("ui.rumor.match", {"name": ContractKit.monster_name(best),
		"n": RumorRules.matches(r, best), "of": best.known_tags.size()}), 28, 18, Palette.BRASS_LIGHT))
	var known := PackedStringArray(best.known_tags.map(func(t: StringName) -> String: return ContractKit.tag_name(t)))
	box.add_child(UiKit.paragraph(Loc.t("ui.rumor.known", {"list": ", ".join(known)}), 16, Palette.FOG))
	return box


func _on_investigate() -> void:
	var o := GameState.investigate_rumor(_uid)
	if o == null:
		close_tablet()
		return
	if o.monster != &"":
		fight_started.emit()
		return
	_show_outcome(o)


## A rumor that led to no fight: what it was, the money, the crossed-out sign. The day is already over.
func _show_outcome(o: RumorRules.Outcome) -> void:
	_clear()
	UiKit.sound(&"money.coins" if o.money > 0 else &"ui.confirm")
	_right.add_child(Icons.with_text("OUTCOME", o.kind, Loc.t("ui.rumor.outcome.%s" % o.kind), 56, 32, Palette.BRASS_LIGHT))
	_right.add_child(UiKit.paragraph(Loc.t("ui.rumor.outcome.%s.text" % o.kind), 19, Palette.PARCHMENT))
	if o.money > 0:
		_right.add_child(Icons.with_text("RESOURCE", &"money", Loc.t("ui.rumor.money", {"n": o.money}), 30, 20, Palette.BRASS_LIGHT))
	if o.crossed != &"":
		var c := GameState.run.contracts.find(o.crossed_contract)
		var who := ContractKit.monster_name(c) if c != null else ""
		_right.add_child(_rich(Loc.t("ui.rumor.crossed", {"tag": "[s]%s[/s]" % ContractKit.tag_name(o.crossed), "name": who}), 18))
	_right.add_child(UiKit.label(Loc.t("ui.rumor.day_over"), 16, Palette.INK_MUTED))
	_right.add_child(_gap())
	var next := UiKit.button(Loc.t("ui.rumor.next"), 20)
	next.pressed.connect(close_tablet)
	_right.add_child(next)


func _rich(bbcode: String, size: int) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_color_override("default_color", Palette.PARCHMENT)
	l.text = bbcode
	return l


func _gap() -> Control:
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return gap


func _clear() -> void:
	for child: Node in _right.get_children():
		child.queue_free()


func close_tablet() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_tablet()
