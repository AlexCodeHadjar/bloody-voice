class_name HeroWalker
extends Node2D
## The hunter on the district map: a stone figurine on a stand (owner, 2026-10-12). Walks a route along the streets
## at a steady pace (GDD 20.4), turns to face its way (four views) and bobs a little. `position` is the feet, in art px.

signal arrived
signal stepped  ## every few steps, for the footstep sound

const SPEED := 350.0  ## art px per second (GDD 20.4)
const HEIGHT := 150.0  ## drawn size of the figurine art (square, the figure stands at its bottom)
const STEP_EVERY := 0.42  ## seconds between footstep sounds
const VIEWS: Array[StringName] = [&"front", &"back", &"left", &"right"]

var _views: Dictionary[StringName, Texture2D] = {}
var _facing: StringName = &"front"
var _route := PackedVector2Array()
var _next := 0
var _time := 0.0
var _step_time := 0.0


func _ready() -> void:
	for v: StringName in VIEWS:
		_views[v] = UiKit.texture("res://art/ui/HERO__figurine__%s.webp" % v)


func is_walking() -> bool:
	return _next < _route.size()


func place(p: Vector2) -> void:
	_route = PackedVector2Array()
	_next = 0
	position = p
	queue_redraw()


## Follows the points one by one; the first one may be where the hero already stands.
func walk(route: PackedVector2Array) -> void:
	_route = route
	_next = 0
	if route.is_empty():
		arrived.emit()


func _process(delta: float) -> void:
	_time += delta
	if is_walking():
		_advance(delta)
	queue_redraw()  # idle bob: one small sprite


func _advance(delta: float) -> void:
	var budget := SPEED * delta
	while budget > 0.0 and is_walking():
		var to := _route[_next]
		var d := position.distance_to(to)
		if d > 0.5:
			_face(to - position)
		if d <= budget:
			position = to
			budget -= d
			_next += 1
		else:
			position += (to - position) / d * budget
			budget = 0.0
	_step_time += delta
	if _step_time >= STEP_EVERY:
		_step_time = 0.0
		stepped.emit()
	if not is_walking():
		_facing = &"front"
		arrived.emit()


func _face(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_facing = &"right" if dir.x > 0.0 else &"left"
	else:
		_facing = &"front" if dir.y > 0.0 else &"back"


func _draw() -> void:
	var tex: Texture2D = _views.get(_facing)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, HEIGHT * 0.26, Color(0.0, 0.0, 0.0, 0.45))
	draw_arc(Vector2.ZERO, HEIGHT * 0.3, 0.0, TAU, 40, Color(0.45, 0.65, 1.0, 0.35 + 0.25 * pulse), 4.0, true)
	draw_set_transform(Vector2.ZERO)
	if tex == null:
		draw_circle(Vector2(0, -HEIGHT * 0.4), HEIGHT * 0.2, Palette.STEEL)
		return
	var bob := (absf(sin(_time * 9.0)) * 5.0) if is_walking() else sin(_time * 2.0) * 1.5
	draw_texture_rect(tex, Rect2(Vector2(-HEIGHT * 0.5, -HEIGHT + 6.0 - bob), Vector2(HEIGHT, HEIGHT)), false)
