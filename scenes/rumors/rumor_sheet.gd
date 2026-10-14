class_name RumorSheet
extends Control
## A heard rumor (GDD 8.4): the picture of the zone on the left; on the right who tells it, the signs, for each contract
## taken in this zone «совпадает N из M известных примет» and its trail — never a guarantee — and Cunning's whisper on
## a wrong one. «Взять в записи» or «Отбросить». Free: no day passes. Full-screen overlay.

signal closed
signal taken(t: RumorRules.Taken)

const PANEL := Vector2(1240, 700)

var _h: RumorGenerator.Heard
var _right: VBoxContainer


func open_heard(h: RumorGenerator.Heard) -> void:
	_h = h
	var panel := UiKit.overlay(self, Palette.BRASS, PANEL)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	row.add_child(UiKit.picture(UiKit.texture(RumorDefs.ART_DIR % h.art) if h.art != &"" else null, Vector2(560, 560)))
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right.add_theme_constant_override("separation", 12)
	row.add_child(_right)
	_fill()
	UiKit.sound(&"paper.map")
	Tutorial.trigger.call_deferred(&"first_rumor")


func _fill() -> void:
	var run := GameState.run
	var map := ContentDB.data.district_map(run.hero_district)
	_right.add_child(UiKit.label(Loc.t("ui.rumor.title"), 34, Palette.BRASS_LIGHT))
	_right.add_child(UiKit.label(ContractKit.zone_name(map, _h.zone), 18, Palette.INK_MUTED))
	_right.add_child(UiKit.paragraph(_witness(_h.witness), 19, Palette.PARCHMENT))
	var tags := VBoxContainer.new()
	for t: StringName in _h.tags:
		tags.add_child(Icons.with_text("TAG", ContractKit.tag_category(t), ContractKit.tag_name(t), 26, 20, Palette.BRASS_LIGHT))
	_right.add_child(tags)
	TutorialAnchors.register(&"rumor_tags", tags)
	if ProgressRules.suspicious(run, ContentDB.data, _h):  # Cunning (GDD 4.3)
		_right.add_child(Icons.with_text("ATTRIBUTE", &"cunning", Loc.t("ui.rumor.suspicious"), 26, 17, Palette.FOG))
	var match_box := _match_box()
	_right.add_child(match_box)
	TutorialAnchors.register(&"rumor_match", match_box)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right.add_child(gap)
	_right.add_child(UiKit.label(Loc.t("ui.rumor.free"), 16, Palette.INK_MUTED))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	var keep := Icons.button("UI", &"journal", Loc.t("ui.rumor.take"), 20)
	keep.pressed.connect(_on_take)
	buttons.add_child(keep)
	var drop := UiKit.button(Loc.t("ui.rumor.discard"), 20)
	drop.pressed.connect(close_sheet)
	buttons.add_child(drop)
	_right.add_child(buttons)
	TutorialAnchors.register(&"rumor_buttons", buttons)


func _witness(id: StringName) -> String:
	for wi: RumorDefs.Witness in ContentDB.data.rumor_data.witnesses:
		if wi.id == id:
			return wi.text
	return ""


## For each contract taken in this zone: how many of the rumor's signs it knows and its trail.
func _match_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	var needed := ContentDB.data.balance.rumors.trail_needed
	for c: ContractsState.Contract in ContractRules.active(GameState.run.contracts):
		if c.zone != _h.zone:
			continue
		box.add_child(Icons.with_text("CONTRACT", c.type, Loc.t("ui.rumor.match", {"name": ContractKit.monster_name(c),
			"n": RumorRules.matches(_h, c), "of": c.known_tags.size()}), 28, 18, Palette.BRASS_LIGHT))
		var known := PackedStringArray(c.known_tags.map(func(t: StringName) -> String: return ContractKit.tag_name(t)))
		box.add_child(UiKit.paragraph(Loc.t("ui.rumor.known", {"list": ", ".join(known)}), 16, Palette.FOG))
		box.add_child(UiKit.label(Loc.t("ui.rumor.trail", {"n": GameState.run.rumors.trail(c.uid), "of": needed}), 16, Palette.FOG))
	if box.get_child_count() == 0:
		box.add_child(UiKit.paragraph(Loc.t("ui.rumor.no_contract"), 17, Palette.FOG))
	return box


func _on_take() -> void:
	var t := GameState.take_rumor(_h)
	if t != null:
		UiKit.sound(&"ui.confirm")
		taken.emit(t)
	close_sheet()


func close_sheet() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_sheet()
