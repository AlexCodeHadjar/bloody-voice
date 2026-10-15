class_name ThreadView
extends Control
## The red threads over the notebook board (GDD 8.4): the ones that held, from a rumor's sign pin (left end) to the
## contract's sign pin (right end), sagging a little; the one being pulled, to the mouse; a snapped one flashes and
## falls. Ignores the mouse.

const THREAD := Color(0.72, 0.07, 0.05)
const SAG := 36.0
const SNAP_TIME := 0.6

var held: Array[Array] = []  ## [rumor row, contract row]
var pulling: Control = null  ## the rumor row a thread is pulled from
var _snap_from := Vector2.ZERO
var _snap_to := Vector2.ZERO
var _snap_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A thread that snapped between two points (local), shown for a moment.
func snap(from: Vector2, to: Vector2) -> void:
	_snap_from = from
	_snap_to = to
	_snap_t = SNAP_TIME


func _process(delta: float) -> void:
	_snap_t = maxf(0.0, _snap_t - delta)
	queue_redraw()  # the cards move with the layout and the mouse moves: cheap, a few lines


func _draw() -> void:
	for pair: Array in held:
		var a := pair[0] as Control
		var b := pair[1] as Control
		if is_instance_valid(a) and is_instance_valid(b) and a.is_visible_in_tree() and b.is_visible_in_tree():
			_thread(left_pin(a), right_pin(b), THREAD)
	if pulling != null and is_instance_valid(pulling):
		_thread(left_pin(pulling), get_local_mouse_position(), THREAD)
	if _snap_t > 0.0:
		var k := _snap_t / SNAP_TIME
		var mid := _snap_from.lerp(_snap_to, 0.5) + Vector2(0.0, SAG * 2.0 * (1.0 - k))  # the halves fall
		draw_line(_snap_from, mid, Color(THREAD, k), 3.0, true)
		draw_line(_snap_to, mid + Vector2(0.0, 20.0 * (1.0 - k)), Color(THREAD, k * 0.7), 3.0, true)


## The pin on the right end of a contract's sign row, in local coordinates.
func right_pin(row: Control) -> Vector2:
	var r := row.get_global_rect()
	return Vector2(r.end.x - 5.0, r.get_center().y) - get_global_rect().position


## The pin on the left end of a rumor's sign row.
func left_pin(row: Control) -> Vector2:
	var r := row.get_global_rect()
	return Vector2(r.position.x + 5.0, r.get_center().y) - get_global_rect().position


func _thread(a: Vector2, b: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var ctrl := a.lerp(b, 0.5) + Vector2(0.0, SAG)
	for i: int in 17:
		var t := i / 16.0
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))  # a quadratic curve: the thread sags
	draw_polyline(pts, Color(0, 0, 0, 0.35), 5.0, true)
	draw_polyline(pts, color, 3.0, true)
	draw_circle(a, 5.0, Color(0.85, 0.7, 0.4))
	draw_circle(b, 5.0, Color(0.85, 0.7, 0.4))
