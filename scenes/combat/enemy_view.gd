class_name EnemyView
extends Control
## The creature stage (GDD 21.2 zones 2-5): big art that breathes, intent medallions above its head, target rings
## on its body parts, the plate under it. Hit flash and shake; clicking the body aims a card at the creature.

signal body_clicked
signal part_clicked(part_id: StringName)

const SIZE := Vector2(880, 700)
const ART_SIZE := Vector2(373, 560)

var _body: Control  ## art and rings; breathes as one
var _art: TextureRect
var _rings: Control
var _ring_views: Dictionary[StringName, PartRing] = {}
var _intents: HBoxContainer
var _plate: EnemyPlate
var _targeting := false
var _shake: Tween
var _flash: Tween


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body = Control.new()
	_body.size = ART_SIZE
	_body.position = Vector2((SIZE.x - ART_SIZE.x) / 2.0, 14)
	_body.pivot_offset = Vector2(ART_SIZE.x / 2.0, ART_SIZE.y)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_art = TextureRect.new()
	_art.size = ART_SIZE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_PASS
	_art.gui_input.connect(_on_art_input)
	_body.add_child(_art)
	_rings = Control.new()
	_rings.size = ART_SIZE
	_rings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(_rings)
	_intents = HBoxContainer.new()
	_intents.add_theme_constant_override("separation", 10)
	_intents.anchor_left = 0.5
	_intents.anchor_right = 0.5
	_intents.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_intents.offset_top = 6
	_intents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intents)
	_plate = EnemyPlate.new()
	_plate.position = Vector2((SIZE.x - EnemyPlate.SIZE.x) / 2.0, ART_SIZE.y + 22)
	add_child(_plate)
	TutorialAnchors.register(&"parts", _rings)
	TutorialAnchors.register(&"enemy", _body)
	TutorialAnchors.register(&"intents", _intents)


func _ready() -> void:
	_start_breathing()


## Slow idle "breathing" of the art: scale 1.00-1.02 around the feet.
func _start_breathing() -> void:
	var t := create_tween().set_loops()
	t.tween_property(_body, "scale", Vector2(1.02, 1.02), 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_body, "scale", Vector2.ONE, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func refresh(s: CombatState, targeting: bool, parts_allowed: bool, capture: float) -> void:
	var e := s.enemy
	_targeting = targeting
	_art.mouse_filter = Control.MOUSE_FILTER_STOP if targeting else Control.MOUSE_FILTER_PASS
	_art.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if targeting else Control.CURSOR_ARROW
	var phase_art := e.def.art_path("combat", "phase2")
	_art.texture = UiKit.texture(phase_art if e.next_phase > 0 and ResourceLoader.exists(phase_art) else e.def.art_path("combat"))
	_plate.refresh(e, capture)
	_refresh_rings(e, targeting and parts_allowed)
	_refresh_intents(s)


func _refresh_rings(e: EnemyCombatant, lit: bool) -> void:
	for id: StringName in e.part_order:
		var p: PartState = e.parts[id]
		var ring: PartRing = _ring_views.get(id)
		if ring == null:
			ring = PartRing.new()
			ring.clicked.connect(part_clicked.emit)
			ring.body_through.connect(body_clicked.emit)
			ring.position = p.def.spot * ART_SIZE - ring.size / 2.0
			_rings.add_child(ring)
			_ring_views[id] = ring
		ring.refresh(p, lit, _targeting)


func _refresh_intents(s: CombatState) -> void:
	for c: Node in _intents.get_children():
		_intents.remove_child(c)
		c.queue_free()
	var e := s.enemy
	var b := ContentDB.data.balance
	for mv_id: StringName in e.intents:
		var mv := e.def.moves[mv_id]
		var view := IntentView.new()
		view.setup(mv, IntentView.number_of(mv, e, s.hero, b), not e.move_available(mv_id))
		_intents.add_child(view)
	if s.foresight:
		for mv_id: StringName in EnemyRules.peek(s, e.def.intents_per_turn):
			var next_view := IntentView.new()
			var mv := e.def.moves[mv_id]
			next_view.setup(mv, IntentView.number_of(mv, e, s.hero, b), false, true)
			_intents.add_child(next_view)


## Where a part's ring is on the screen (canvas coordinates); the body centre for an unknown part.
func spot_global(part_id: StringName) -> Vector2:
	var ring: PartRing = _ring_views.get(part_id)
	if ring == null:
		return center_global()
	return ring.get_global_transform() * (ring.size / 2.0)


func center_global() -> Vector2:
	return _body.get_global_transform() * (ART_SIZE * Vector2(0.5, 0.45))


## Red flash and a short shake of the creature.
func play_hit() -> void:
	if _flash != null:
		_flash.kill()
	_art.modulate = Color(2.4, 1.3, 1.3)
	_flash = create_tween()
	_flash.tween_property(_art, "modulate", Color.WHITE, 0.3)
	if _shake != null:
		_shake.kill()
	var x0 := (SIZE.x - ART_SIZE.x) / 2.0
	_body.position.x = x0
	_shake = create_tween()
	for dx: float in [9.0, -8.0, 6.0, -4.0, 0.0]:
		_shake.tween_property(_body, "position:x", x0 + dx, 0.04)


func _on_art_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _targeting and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		body_clicked.emit()
		accept_event()
