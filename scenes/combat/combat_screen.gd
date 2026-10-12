extends Control
## Fight screen v2 (GDD 9.1, 21). Reads GameState.combat, sends commands through GameState, redraws on signals; plays the
## basic animations (card flight, floating numbers, hit flash). Laid out on a 1920 x 1080 frame centred on the window.

const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const FRAME := Vector2(1920, 1080)
const RESULT_DELAY := 0.8
const FX_KINDS: Array[StringName] = [&"damage", &"sanity", &"heal", &"bleed", &"lose_hp"]  ## log events that show a number

var _frame: Control
var _fx: Control  ## floating numbers and flying cards
var _enemy_view: EnemyView
var _hero_view: HeroView
var _hand: HandView
var _piles: Dictionary[StringName, PileView] = {}
var _log: LogPanel
var _result: ResultPanel
var _popup: CardListPopup
var _prompt: Label
var _top_left: Label
var _top_turn: Label
var _lever: TextureButton
var _lever_pulse: Tween
var _selected_uid: int = 0
var _fx_seen := 0
var _result_queued := false


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"combat")
	if GameState.combat == null:
		GameState.start_hunt()
	_fx_seen = GameState.combat.events.size()  # the opening lines are not animated
	_build()
	add_child(CombatSounds.new())
	Tutorial.trigger.call_deferred(&"combat_start")
	EventBus.combat_updated.connect(_refresh)
	_refresh()


## The 1920 x 1080 frame, centred in the window; every zone is placed inside it.
func _add_frame() -> void:
	_frame = Control.new()
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_top = 0.5
	_frame.anchor_bottom = 0.5
	_frame.offset_left = -FRAME.x / 2.0
	_frame.offset_right = FRAME.x / 2.0
	_frame.offset_top = -FRAME.y / 2.0
	_frame.offset_bottom = FRAME.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	TutorialAnchors.register(&"battle", _frame)


func _build() -> void:
	_add_background(GameState.combat.backdrop)
	_add_frame()
	_build_top_bar()
	_enemy_view = EnemyView.new()
	_enemy_view.position = Vector2(520, 52)
	_enemy_view.body_clicked.connect(func() -> void: _on_target(CombatTarget.enemy()))
	_enemy_view.part_clicked.connect(func(id: StringName) -> void: _on_target(CombatTarget.part(id)))
	_frame.add_child(_enemy_view)
	_hero_view = HeroView.new()
	_hero_view.position = Vector2(0, 690)
	_frame.add_child(_hero_view)
	_prompt = CombatKit.outlined("", 22, Palette.BRASS_LIGHT, Vector2(560, 752), 800.0)
	_frame.add_child(_prompt)
	_hand = HandView.new()
	_hand.position = Vector2(410, 740)
	_hand.card_chosen.connect(_on_card_chosen)
	_frame.add_child(_hand)
	_build_piles()
	_build_lever()
	_log = LogPanel.new()
	_log.position = Vector2(FRAME.x, 300)
	_frame.add_child(_log)
	_fx = Control.new()
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_fx)
	_result = ResultPanel.new()
	_result.visible = false
	_result.back_pressed.connect(_return_to_city)
	add_child(_result)


## The fight's backdrop darkened (~45 % black) with a vignette, so the creature stands out.
func _add_background(path: String) -> void:
	var art := TextureRect.new()
	art.texture = UiKit.texture(path)
	if art.texture == null and GameState.has_run():
		var district := ContentDB.data.district(GameState.run.hero_district)
		art.texture = UiKit.texture(district.art_path("scene")) if district != null else null
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.modulate = Color(0.55, 0.55, 0.55)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.35, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.8)])
	var vignette := GradientTexture2D.new()
	vignette.gradient = gradient
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.0, 0.5)
	vignette.width = 256
	vignette.height = 256
	var shade := TextureRect.new()
	shade.texture = vignette
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _build_top_bar() -> void:
	var strip := ColorRect.new()
	strip.color = Color(0.03, 0.02, 0.02, 0.6)
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.offset_bottom = 56
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(strip)
	_top_left = UiKit.label("", 24, Palette.BRASS_LIGHT)
	_top_left.position = Vector2(24, 10)
	_frame.add_child(_top_left)
	_top_turn = CombatKit.outlined("", 24, Palette.PARCHMENT, Vector2(760, 10), 400.0)
	_frame.add_child(_top_turn)
	var settings := TextureButton.new()
	settings.texture_normal = Icons.texture("UI", &"settings")
	settings.ignore_texture_size = true
	settings.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings.position = Vector2(FRAME.x - 56, 8)
	settings.size = Vector2(40, 40)
	settings.tooltip_text = Loc.t("ui.combat.settings")
	settings.pressed.connect(func() -> void: SettingsPanel.open(self, true))
	_frame.add_child(settings)


func _build_piles() -> void:
	for spec: Array in [[&"draw_pile", Vector2(24, 948), Color.WHITE], [&"exhaust_pile", Vector2(1696, 948), Color(0.7, 0.55, 0.85)],
			[&"discard_pile", Vector2(1800, 948), Color(0.75, 0.75, 0.75)]]:
		var pile := PileView.new(spec[0] as StringName, spec[2] as Color)
		pile.position = spec[1] as Vector2
		pile.clicked.connect(_open_pile)
		_frame.add_child(pile)
		_piles[pile.pile] = pile


func _build_lever() -> void:
	_lever = TextureButton.new()
	_lever.texture_normal = CombatKit.tex("end_turn_lever")
	_lever.ignore_texture_size = true
	_lever.stretch_mode = TextureButton.STRETCH_SCALE
	_lever.position = Vector2(1524, 800)
	_lever.size = Vector2(150, 156)
	_lever.pivot_offset = _lever.size / 2.0
	_lever.pressed.connect(_end_turn)
	_lever.mouse_entered.connect(func() -> void: UiKit.sound(&"ui.hover"))
	TutorialAnchors.register(&"end_turn", _lever)
	_frame.add_child(_lever)
	_frame.add_child(CombatKit.outlined(Loc.t("ui.combat.end_turn"), 22, Palette.BRASS_LIGHT, Vector2(1504, 958), 190.0))


func _refresh() -> void:
	var s := GameState.combat
	if s == null:
		return
	var selected := s.find_in_hand(_selected_uid)
	if selected == null:
		_selected_uid = 0
	var targeting := selected != null
	_enemy_view.refresh(s, targeting, targeting and selected.def.target == &"enemy_or_part", _capture_chance(s))
	_hero_view.refresh(s.hero)
	_refresh_hand(s)
	_piles[&"draw_pile"].set_count(s.draw_pile.size())
	_piles[&"discard_pile"].set_count(s.discard_pile.size())
	_piles[&"exhaust_pile"].set_count(s.exhaust_pile.size())
	_log.refresh(s)
	_top_left.text = _top_text(s)
	_top_turn.text = Loc.t("ui.combat.turn", {"n": s.turn})
	_play_fx(s)
	if s.is_over() and not _result_queued:
		_result_queued = true  # a short pause so the last card's flight and numbers are seen
		create_tween().tween_callback(func() -> void: _result.show_result(s)).set_delay(RESULT_DELAY)


## «Охота: X», «Заказ: убить X» or «Заказ на поимку: X»; «тварь усилилась» when the contract is overdue.
func _top_text(s: CombatState) -> String:
	var key := "ui.combat.top.hunt"
	if s.capture_allowed:
		key = "ui.combat.top.contract"
	elif s.contract_uid != 0:
		key = "ui.combat.top.contract_slay"
	var text := Loc.t(key, {"enemy": s.enemy.display_name})
	return text + Loc.t("ui.combat.top.stronger") if s.enemy.damage_bonus > 0 else text


func _refresh_hand(s: CombatState) -> void:
	var playable: Dictionary[int, bool] = {}
	var hints: Array[int] = []
	var any := false
	for card: CardInstance in s.hand:
		var ok := CombatRules.can_play(s, card, _any_target(card)) == ""
		playable[card.uid] = ok
		any = any or ok
		if s.hero.ammo == 0 and _is_reload(card):
			hints.append(card.uid)
	_hand.refresh(s.hand, _selected_uid, playable, hints)
	_pulse_lever(not any and s.phase == CombatState.Phase.PLAYER)


func _is_reload(card: CardInstance) -> bool:
	for e: Dictionary in card.def.effects:
		if StringName(str(e["op"])) == &"reload":
			return true
	return false


## The lever pulses when no playable card is left.
func _pulse_lever(on: bool) -> void:
	if _lever_pulse != null:
		_lever_pulse.kill()
		_lever_pulse = null
	_lever.scale = Vector2.ONE
	_lever.modulate = Color.WHITE
	if not on:
		return
	_lever_pulse = _lever.create_tween().set_loops()
	_lever_pulse.tween_property(_lever, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE)
	_lever_pulse.parallel().tween_property(_lever, "modulate", Color(1.4, 1.25, 0.95), 0.55)
	_lever_pulse.tween_property(_lever, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
	_lever_pulse.parallel().tween_property(_lever, "modulate", Color.WHITE, 0.55)


## Chance 0-1 of the best capture card still in the hunter's piles, or -1 when capture is not allowed or no net is left.
func _capture_chance(s: CombatState) -> float:
	if not s.capture_allowed:
		return -1.0
	var base := 0.0
	for pile: Array in [s.hand, s.draw_pile, s.discard_pile]:
		for card: CardInstance in pile:
			for e: Dictionary in card.def.effects:
				if StringName(str(e["op"])) == &"capture":
					base = maxf(base, float(e["chance"]))
	if base <= 0.0:
		return -1.0
	var e := s.enemy
	return CaptureRules.chance(base, e.hp, e.max_hp, s.hero.cunning, e.broken_parts(), ContentDB.data.balance)


func _any_target(card: CardInstance) -> CombatTarget:
	return CombatTarget.enemy() if card.def.needs_enemy_target() else CombatTarget.self_target()


func _on_card_chosen(uid: int) -> void:
	var s := GameState.combat
	var card := s.find_in_hand(uid)
	if card == null or s.is_over():
		return
	if _selected_uid == uid:
		_selected_uid = 0
		_prompt.text = ""
	elif card.def.needs_enemy_target():
		var problem := CombatRules.can_play(s, card, CombatTarget.enemy())
		_prompt.text = problem if problem != "" else Loc.t("ui.combat.choose_target")
		_selected_uid = uid if problem == "" else 0
		UiKit.sound(&"ui.error" if problem != "" else &"card.draw")
	else:
		_play(uid, CombatTarget.self_target())
		return
	_refresh()


func _on_target(target: CombatTarget) -> void:
	if _selected_uid == 0:
		return
	var uid := _selected_uid
	_selected_uid = 0
	_play(uid, target)


## Sends the card to the rules; a played card flies to its target and fades.
func _play(uid: int, target: CombatTarget) -> void:
	var view := _hand.view_of(uid)
	var ghost := _make_ghost(view)
	var problem := GameState.combat_play(uid, target)
	_prompt.text = problem
	if problem != "":
		UiKit.sound(&"ui.error")
		if ghost != null:
			ghost.queue_free()
		return
	if ghost != null:
		var to := _hero_view.portrait_global() if target.kind == CombatTarget.SELF else _target_point(target)
		_fly(ghost, to)
	var s := GameState.combat
	_prompt.text = s.events.back().text if not s.events.is_empty() else ""


func _target_point(target: CombatTarget) -> Vector2:
	return _enemy_view.spot_global(target.part_id) if target.part_id != &"" else _enemy_view.center_global()


func _make_ghost(view: CardView) -> CardView:
	if view == null:
		return null
	var ghost := CardView.new().setup(view.card)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.add_child(ghost)
	ghost.position = _fx.make_canvas_position_local(view.get_global_transform() * (view.size / 2.0)) - ghost.size / 2.0
	ghost.rotation = view.rotation
	ghost.scale = view.scale
	return ghost


func _fly(ghost: CardView, to_global: Vector2) -> void:
	var t := ghost.create_tween().set_parallel(true)
	var dest := _fx.make_canvas_position_local(to_global) - ghost.size / 2.0
	t.tween_property(ghost, "position", dest, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(ghost, "scale", Vector2(0.45, 0.45), 0.38)
	t.tween_property(ghost, "rotation", 0.0, 0.38)
	t.tween_property(ghost, "modulate:a", 0.0, 0.2).set_delay(0.22)
	t.chain().tween_callback(ghost.queue_free)


## Floating numbers and hit flashes for the log lines added since the last update.
func _play_fx(s: CombatState) -> void:
	var delay := 0.0
	for i: int in range(_fx_seen, s.events.size()):
		var ev := s.events[i]
		var hero_hit := ev.subject == &"hero"
		if ev.amount <= 0 or not FX_KINDS.has(ev.kind) or (ev.kind == &"sanity" and not hero_hit):
			continue
		var heal := ev.kind == &"heal"
		var color: Color = Color("c7a8ff") if ev.kind == &"sanity" else (Color("8fe08a") if heal else (Color("ff6a5a") if hero_hit else Color("fff2d0")))
		var at := _hero_view.portrait_global() if hero_hit else (_enemy_view.center_global() if ev.subject == &"enemy" else _enemy_view.spot_global(ev.subject))
		CombatKit.float_text(_fx, ("+%d" if heal else "-%d") % ev.amount, _fx.make_canvas_position_local(at), color, delay)
		if not heal:
			var flash: Callable = _hero_view.play_hit if hero_hit else _enemy_view.play_hit
			create_tween().tween_callback(flash).set_delay(delay)
		delay += 0.2
	_fx_seen = s.events.size()


func _open_pile(pile: StringName) -> void:
	if _popup != null:
		return
	var s := GameState.combat
	var cards: Array[CardInstance] = s.get(pile)
	_popup = CardListPopup.new().setup(Loc.t("ui.combat.pile_title", {"pile": Loc.t("ui.combat.pile.%s" % pile), "n": cards.size()}), cards)
	_popup.closed.connect(func() -> void: _popup = null)
	add_child(_popup)


func _end_turn() -> void:
	_selected_uid = 0
	_prompt.text = ""
	UiKit.sound(&"turn.end")
	GameState.combat_end_turn()
	Tutorial.action(&"end_turn")


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		_deselect()
	elif event.is_action_pressed("ui_cancel"):
		if _popup != null:
			_popup.close_popup()
		elif _log.is_open():
			_log.set_open(false)
		elif _selected_uid != 0:
			_deselect()
		elif not GameState.combat.is_over():
			SettingsPanel.open(self, true)


func _deselect() -> void:
	_selected_uid = 0
	_prompt.text = ""
	_refresh()


func _return_to_city() -> void:
	GameState.finish_combat()
	get_tree().change_scene_to_file(DISTRICT)
