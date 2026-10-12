class_name PartRing
extends Control
## A target ring on the creature's body at the part's spot: the red arc is the part's HP; it glows and takes clicks while
## a card that can hit parts is being aimed; a broken part shows the cracked ring (GDD 21.2 zone 4).

signal clicked(part_id: StringName)
signal body_through  ## clicked while aiming a card that cannot hit parts: the click belongs to the creature

const SIDE := 68.0

var part_id: StringName
var _pulse: Tween
var _live := false
var _tex: TextureRect
var _arc: HpArc


## The red arc of the part's HP drawn over the ring picture.
class HpArc extends Control:
	var frac := 1.0

	func _draw() -> void:
		if frac > 0.0:
			draw_arc(size / 2.0, PartRing.SIDE * 0.34, -PI / 2.0, -PI / 2.0 + TAU * frac, 40, Color(0.85, 0.15, 0.12, 0.95), 5.0, true)


func _init() -> void:
	custom_minimum_size = Vector2(SIDE, SIDE)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	_tex = CombatKit.image("part_ring__normal", Vector2.ZERO, size)
	add_child(_tex)
	_arc = HpArc.new()
	_arc.size = size
	_arc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arc)


func refresh(p: PartState, lit: bool, aiming: bool = false) -> void:
	part_id = p.def.id
	_arc.frac = clampf(float(p.hp) / float(maxi(p.def.hp, 1)), 0.0, 1.0)
	_arc.visible = not p.broken
	_arc.queue_redraw()
	_tex.texture = CombatKit.tex("part_ring__broken" if p.broken else "part_ring__normal")
	tooltip_text = Loc.t("ui.combat.part_tip", {"name": p.def.name, "hp": maxi(p.hp, 0), "max": p.def.hp}) \
		+ ("  " + Loc.t("ui.combat.broken") if p.broken else "")
	var live := lit and not p.broken
	_live = live
	mouse_filter = Control.MOUSE_FILTER_STOP if live or aiming else Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if live or aiming else Control.CURSOR_ARROW
	_set_pulse(live)
	if not live:
		modulate = Color(1, 1, 1, 0.8 if p.broken else 0.55)


func _set_pulse(on: bool) -> void:
	if on and _pulse != null and _pulse.is_valid():
		return  # already pulsing
	if _pulse != null:
		_pulse.kill()
		_pulse = null
	scale = Vector2.ONE
	if not on or not is_inside_tree():
		return
	modulate = Color.WHITE
	_pulse = create_tween().set_loops()
	_pulse.tween_property(self, "scale", Vector2(1.14, 1.14), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.parallel().tween_property(self, "modulate", Color(1.5, 1.3, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
	_pulse.parallel().tween_property(self, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mouse_filter == Control.MOUSE_FILTER_STOP:
		if _live:
			clicked.emit(part_id)
		else:
			body_through.emit()
		accept_event()
