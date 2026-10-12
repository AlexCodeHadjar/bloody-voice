class_name VialView
extends Control
## A glass vial that fills by value and eases to new values (hunter HP: blood, Sanity: violet; GDD 21.2 zone 7).

const SIZE := Vector2(50, 200)

var fill: float = 1.0:  ## fraction of liquid drawn
	set(v):
		fill = v
		_apply_fill()

var _clip: Control
var _liquid: TextureRect
var _liquid_top := 0.0
var _liquid_height := 0.0
var _label: Label
var _tween: Tween


func _init(kind: String = "hp") -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tex := CombatKit.tex("vial__%s" % kind)
	_liquid_height = SIZE.y * 0.84
	_liquid_top = SIZE.y * 0.07
	var w := _liquid_height * (float(tex.get_width()) / float(tex.get_height()) if tex != null else 0.25)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.position.x = (SIZE.x - w) / 2.0
	_clip.size.x = w
	add_child(_clip)
	_liquid = CombatKit.image("vial__%s" % kind, Vector2.ZERO, Vector2(w, _liquid_height))
	_clip.add_child(_liquid)
	add_child(CombatKit.image("vial__glass", Vector2.ZERO, SIZE))
	_label = CombatKit.outlined("", 17, Palette.PARCHMENT, Vector2(-20, SIZE.y + 2), SIZE.x + 40.0)
	add_child(_label)
	_apply_fill()


func show_value(value: int, max_value: int, caption: String) -> void:
	var f := clampf(float(value) / float(maxi(max_value, 1)), 0.0, 1.0)
	_label.text = "%d / %d" % [maxi(value, 0), max_value]
	tooltip_text = caption
	if _tween != null:
		_tween.kill()
	if is_inside_tree() and absf(f - fill) > 0.001:
		_tween = create_tween()
		_tween.tween_property(self, "fill", f, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		fill = f


func _apply_fill() -> void:
	if _clip == null:
		return
	var h := _liquid_height * fill
	_clip.position.y = _liquid_top + _liquid_height - h
	_clip.size.y = h
	_liquid.position.y = -(_liquid_height - h)
