extends Control
## Fight screen (GDD 9.1). Reads GameState.combat, sends commands through GameState, redraws on signals.

const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const OUTCOME_TITLES: Dictionary[StringName, String] = {
	&"slain": "The creature is slain", &"captured": "The creature is captured",
	&"fallen": "The hunter falls", &"escaped": "It slipped away",
}

var _enemy_view: EnemyView
var _hero_view: HeroView
var _intents_left: VBoxContainer
var _intents_right: VBoxContainer
var _hand: HBoxContainer
var _piles: Label
var _message: Label
var _log: Label
var _result: CenterContainer
var _selected_uid: int = 0


func _ready() -> void:
	theme = UiKit.theme()
	if GameState.combat == null:
		GameState.start_hunt()
	_build()
	EventBus.combat_updated.connect(_refresh)
	_refresh()


func _build() -> void:
	_add_background()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	root.add_child(_build_enemy_row())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	_message = UiKit.label("", 20, Palette.BRASS_LIGHT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_message)
	root.add_child(_build_hero_row())
	root.add_child(_build_hand_row())
	_build_log()
	_build_result()


func _add_background() -> void:
	var art := TextureRect.new()
	var district := ContentDB.data.district(GameState.run.hero_district) if GameState.has_run() else null
	art.texture = UiKit.texture(district.art_path("scene")) if district != null else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.35, 0.32, 0.32)
	add_child(art)


func _build_enemy_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	_intents_left = VBoxContainer.new()
	row.add_child(_intents_left)
	_enemy_view = EnemyView.new()
	_enemy_view.body_clicked.connect(_on_target.bind(CombatTarget.enemy()))
	_enemy_view.part_clicked.connect(func(id: StringName) -> void: _on_target(CombatTarget.part(id)))
	row.add_child(_enemy_view)
	_intents_right = VBoxContainer.new()
	row.add_child(_intents_right)
	return row


func _build_hero_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	_hero_view = HeroView.new()
	row.add_child(_hero_view)
	var end_turn := UiKit.button("End Turn", 24)
	end_turn.pressed.connect(_end_turn)
	row.add_child(end_turn)
	return row


func _build_hand_row() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override("separation", 10)
	row.add_child(_hand)
	_piles = UiKit.label("", 17, Palette.FOG)
	row.add_child(_piles)
	return row


func _build_log() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -380
	panel.offset_top = 22
	panel.offset_right = -22
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.05, 0.04, 0.04, 0.8), Palette.INK_MUTED))
	add_child(panel)
	_log = UiKit.paragraph("", 15, Palette.FOG)
	_log.custom_minimum_size = Vector2(330, 0)
	panel.add_child(_log)


func _build_result() -> void:
	_result = CenterContainer.new()
	_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result.visible = false
	add_child(_result)


func _refresh() -> void:
	var s := GameState.combat
	if s == null:
		return
	var selected := s.find_in_hand(_selected_uid)
	if selected == null:
		_selected_uid = 0
	var targeting := selected != null
	_enemy_view.refresh(s.enemy, targeting, targeting and selected.def.target == &"enemy_or_part")
	_hero_view.refresh(s.hero, false)
	_refresh_intents(s)
	_refresh_hand(s)
	_piles.text = "Draw %d\nDiscard %d\nExhaust %d" % [s.draw_pile.size(), s.discard_pile.size(), s.exhaust_pile.size()]
	_refresh_log(s)
	if s.is_over():
		_show_result(s)


func _refresh_intents(s: CombatState) -> void:
	for box: VBoxContainer in [_intents_left, _intents_right]:
		for c: Node in box.get_children():
			c.queue_free()
	var e := s.enemy
	for i: int in e.intents.size():
		var view := IntentView.new()
		view.setup(e.def.moves[e.intents[i]], not e.move_available(e.intents[i]))
		(_intents_left if i % 2 == 0 else _intents_right).add_child(view)
	if s.foresight:
		for mv: StringName in EnemyRules.peek(s, e.def.intents_per_turn):
			var next_view := IntentView.new()
			next_view.setup(e.def.moves[mv], false, true)
			_intents_right.add_child(next_view)


func _refresh_hand(s: CombatState) -> void:
	for c: Node in _hand.get_children():
		c.queue_free()
	for card: CardInstance in s.hand:
		var view := CardView.new()
		var ok := CombatRules.can_play(s, card, _any_target(card)) == ""
		view.setup(card, ok, card.uid == _selected_uid)
		view.chosen.connect(_on_card_chosen)
		_hand.add_child(view)


func _refresh_log(s: CombatState) -> void:
	var lines: PackedStringArray = []
	for i: int in range(maxi(0, s.events.size() - 12), s.events.size()):
		lines.append(s.events[i].text)
	_log.text = "\n".join(lines)


func _any_target(card: CardInstance) -> CombatTarget:
	return CombatTarget.enemy() if card.def.needs_enemy_target() else CombatTarget.self_target()


func _on_card_chosen(uid: int) -> void:
	var s := GameState.combat
	var card := s.find_in_hand(uid)
	if card == null or s.is_over():
		return
	if _selected_uid == uid:
		_selected_uid = 0
	elif card.def.needs_enemy_target():
		var problem := CombatRules.can_play(s, card, CombatTarget.enemy())
		_message.text = problem if problem != "" else "Choose a target: the creature or a body part."
		_selected_uid = uid if problem == "" else 0
	else:
		_message.text = GameState.combat_play(uid, CombatTarget.self_target())
		return
	_refresh()


func _on_target(target: CombatTarget) -> void:
	if _selected_uid == 0:
		return
	var uid := _selected_uid
	_selected_uid = 0
	_message.text = GameState.combat_play(uid, target)


func _end_turn() -> void:
	_selected_uid = 0
	_message.text = ""
	GameState.combat_end_turn()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if (mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT) or event.is_action_pressed("ui_cancel"):
		_selected_uid = 0
		_message.text = ""
		_refresh()


func _show_result(s: CombatState) -> void:
	if _result.visible:
		return
	_result.visible = true
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.05, 0.96), Palette.BRASS_LIGHT))
	_result.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UiKit.label(OUTCOME_TITLES.get(s.outcome(), "The fight is over"), 36, Palette.BRASS_LIGHT))
	var trophies := ", ".join(PackedStringArray(s.trophies.map(func(t: StringName) -> String: return String(t).capitalize())))
	v.add_child(UiKit.label("Turns: %d    HP left: %d" % [s.turn, maxi(s.hero.hp, 0)], 20))
	v.add_child(UiKit.label("Trophies: %s" % (trophies if trophies != "" else "none"), 20))
	var back := UiKit.button("Return to the city")
	back.pressed.connect(_return_to_city)
	v.add_child(back)


func _return_to_city() -> void:
	GameState.finish_combat()
	get_tree().change_scene_to_file(CITY_MAP)
