class_name StatBar
extends Control
## A drawn bar: dark trough, coloured fill that eases to new values, phase notches and a centred caption (creature HP).

var shown: float = 0.0:  ## fill fraction currently drawn
	set(v):
		shown = v
		queue_redraw()

var _color: Color = Palette.BLOOD
var _notches: Array[float] = []
var _caption := ""
var _font_size := 15
var _tween: Tween


func setup(color: Color, width: float = 320.0, height: float = 22.0) -> StatBar:
	_color = color
	custom_minimum_size = Vector2(width, height)
	size = custom_minimum_size
	_font_size = int(height * 0.7)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


## notches: fractions of max where a phase begins (drawn as marks on the bar).
func show_value(caption: String, value: int, max_value: int, notches: Array[float] = []) -> void:
	_caption = caption
	_notches = notches
	var f := clampf(float(value) / float(maxi(max_value, 1)), 0.0, 1.0)
	if _tween != null:
		_tween.kill()
	if is_inside_tree() and absf(f - shown) > 0.001:
		_tween = create_tween()
		_tween.tween_property(self, "shown", f, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		shown = f
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.04, 0.03, 0.03, 0.85))
	draw_rect(Rect2(r.position, Vector2(r.size.x * shown, r.size.y)), _color)
	draw_rect(Rect2(r.position, Vector2(r.size.x * shown, r.size.y * 0.4)), Color(1, 1, 1, 0.1))
	for n: float in _notches:
		draw_line(Vector2(r.size.x * n, 0), Vector2(r.size.x * n, r.size.y), Palette.BRASS_LIGHT, 2.0)
	draw_rect(r, Palette.BRASS, false, 2.0)
	var font := UiKit.serif()
	var base := Vector2(0, r.size.y / 2.0 + _font_size * 0.35)
	draw_string_outline(font, base, _caption, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, _font_size, 4, CombatKit.FONT_OUTLINE)
	draw_string(font, base, _caption, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, _font_size, Palette.PARCHMENT)
