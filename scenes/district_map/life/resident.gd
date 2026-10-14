class_name Resident
extends Node2D
## One person or animal on the district map (map-life-people.md): walks the street graph, looks around, chats, works,
## stands, flies or dashes. `position` is the feet in art px. Atmosphere only.

enum State { MOVE, PAUSE, CHAT, STILL, WORK, FLY, WAIT, DASH }

const BOB_HEIGHT := 3.0  ## art px
const SIDE_MIN := 10.0  ## sideways offset from the street centre, so nobody walks in single file
const SIDE_MAX := 30.0
const CHAT_COOLDOWN := 25.0
const DODGE_RANGE := 70.0  ## the hero this close ahead makes a walker step aside
const DODGE_SIDE := 30.0
const DODGE_SPEED := 90.0
const FADE_TIME := 1.5
const FLY_HEIGHT := 70.0
const SHADOW_FLATNESS := 0.32

var def: DistrictLifeDef.ResidentDef
var state: State = State.STILL
var cooldown := 0.0  ## seconds until this one may chat again

var _ctx: LifeContext
var _sprite := Sprite2D.new()
var _emote := Sprite2D.new()
var _tex: Array[Texture2D] = []
var _unit := 0.27  ## final picture scale
var _speed := 0.0
var _base := Vector2.ZERO  ## the logical feet; `position` adds the sideways dodge
var _dir := Vector2(-1, 1)
var _towards := true
var _flipped := false
var _side := 0.0
var _dodge := 0.0
var _path := PackedVector2Array()
var _pi := 0
var _node: StringName = &""
var _time := 0.0
var _bob := 0.0
var _timer := 0.0  ## time left in the current pause, chat, work beat or wait
var _flip_timer := 0.0
var _angle := 0.0
var _alpha := 1.0
var _hidden_for := 0.0
var _shadow_w := 0.0
var _cur := 0  ## index of the picture shown


func setup(d: DistrictLifeDef.ResidentDef, ctx: LifeContext) -> void:
	def = d
	_ctx = ctx
	var rng := ctx.rng
	for s: int in d.slots():
		_tex.append(ctx.texture(d.art, s))
	var v := ctx.life.var_scale
	_unit = ctx.life.figure_scale * d.scale * (1.0 + rng.randf_range(-v, v))
	_speed = d.speed * (1.0 + rng.randf_range(-ctx.life.var_speed, ctx.life.var_speed))
	_side = rng.randf_range(SIDE_MIN, SIDE_MAX) * (1.0 if rng.randf() < 0.5 else -1.0)
	_flipped = rng.randf() < 0.5
	_time = rng.randf() * 10.0
	_sprite.centered = false
	_sprite.modulate = Color.from_hsv(rng.randf(), rng.randf_range(0.0, 0.08), 1.0 - rng.randf() * ctx.life.var_value)
	_sprite.scale = Vector2(_unit, _unit)
	add_child(_sprite)
	_emote.visible = false
	add_child(_emote)
	_show(0)
	_shadow_w = _tex[0].get_width() * _unit * ctx.life.shadow if _tex[0] != null else 0.0
	_begin()
	queue_redraw()


func is_walking() -> bool:
	return state == State.MOVE


func can_chat() -> bool:
	return def.chat and state == State.MOVE and cooldown <= 0.0


## Stops and faces `other` for `seconds`; `emote_slot` > 0 pops that emote above the head.
func start_chat(other: Vector2, seconds: float, emote_slot: int) -> void:
	state = State.CHAT
	_timer = seconds
	cooldown = CHAT_COOLDOWN
	_face(other - _base)
	if emote_slot > 0:
		_pop_emote(emote_slot)


func _begin() -> void:
	match def.mode:
		&"wander":
			_node = _ctx.random_node(def.nodes)
			_set_base(_ctx.map.node_pos(_node))
			_plan_trip()
		&"work":
			_set_base(def.pos)
			state = State.WORK
			_timer = _ctx.rng.randf_range(0.6, 1.2)
		&"circle":
			_set_base(def.pos)
			state = State.FLY
			_angle = _ctx.rng.randf() * TAU
			z_index = 5
		&"dash":
			_set_base(def.pos)
			state = State.WAIT
			_timer = _ctx.rng.randf_range(0.0, def.interval.y)
			visible = false
		_:
			_set_base(def.pos)
			state = State.STILL
			_set_flip(_flipped)


func _process(delta: float) -> void:
	_time += delta
	cooldown = maxf(cooldown - delta, 0.0)
	match state:
		State.MOVE:
			_tick_move(delta)
		State.PAUSE, State.CHAT:
			_tick_pause(delta)
		State.WORK:
			_tick_work(delta)
		State.STILL:
			_tick_still(delta)
		State.FLY:
			_tick_fly(delta)
		State.WAIT, State.DASH:
			_tick_dash(delta)


# ---- walking ---------------------------------------------------------------------------------------------------

func _plan_trip() -> void:
	var rng := _ctx.rng
	var dest := _ctx.random_node(def.nodes)
	var tries := 0
	while dest == _node and tries < 6:
		dest = _ctx.random_node(def.nodes)
		tries += 1
	var route := DistrictMapRules.shortest_path(_ctx.map, _node, dest)
	_path = _offset_route(route)
	_pi = 0
	_node = dest
	if _path.is_empty():
		_pause(rng.randf_range(1.0, 3.0))
		return
	state = State.MOVE


## The street points shifted sideways by this walker's own offset (perpendicular to the way).
func _offset_route(route: Array[StringName]) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in route.size():
		var p := _ctx.map.node_pos(route[i])
		var d_in := (p - _ctx.map.node_pos(route[i - 1])).normalized() if i > 0 else Vector2.ZERO
		var d_out := (_ctx.map.node_pos(route[i + 1]) - p).normalized() if i < route.size() - 1 else Vector2.ZERO
		var d := d_in + d_out
		if d.length() < 0.3:
			d = d_out if d_out != Vector2.ZERO else d_in
		out.append(p + Vector2(-d.y, d.x).normalized() * _side)
	return out


func _tick_move(delta: float) -> void:
	var to := _path[_pi] - _base
	var step := _speed * delta
	if to.length() <= step:
		_set_base(_path[_pi])
		_pi += 1
		if _pi >= _path.size():
			_arrive()
		return
	_face(to)
	_set_base(_base + to.normalized() * step)
	_bob += delta * (5.0 + _speed * 0.05)
	_sprite.position.y = -absf(sin(_bob)) * BOB_HEIGHT
	_sprite.rotation = sin(_bob) * 0.03
	_step_aside(delta)


func _arrive() -> void:
	_sprite.position.y = 0.0
	_sprite.rotation = 0.0
	if _ctx.rng.randf() < 0.55:
		_pause(_ctx.rng.randf_range(1.0, 6.0))
	else:
		_plan_trip()


func _pause(seconds: float) -> void:
	state = State.PAUSE
	_timer = seconds
	_flip_timer = seconds / float(_ctx.rng.randi_range(2, 3))
	_sprite.position.y = 0.0
	_sprite.rotation = 0.0


func _tick_pause(delta: float) -> void:
	_timer -= delta
	if state == State.PAUSE:
		_flip_timer -= delta
		if _flip_timer <= 0.0:
			_flip_timer = maxf(_timer / 2.0, 0.4)
			_set_flip(not _flipped)
	if _timer <= 0.0:
		_emote.visible = false
		if state == State.CHAT and _pi < _path.size():
			state = State.MOVE  # a chat stops a walker mid-street: go on along the same way (owner 2026-10-14:
			return  # re-planning from the far destination sent walkers straight over the houses)
		_plan_trip()


## A hero ahead of a walker pushes it to the side (smoothly); with no hero nearby it comes back to its lane.
func _step_aside(delta: float) -> void:
	var target := 0.0
	var hero := _ctx.hero
	if hero != null and _dir != Vector2.ZERO:
		var rel := hero.position - _base
		if rel.length() < DODGE_RANGE and rel.dot(_dir) > 0.0:
			var perp := Vector2(-_dir.y, _dir.x)
			target = DODGE_SIDE * (1.0 if perp.dot(rel) < 0.0 else -1.0)
	_dodge = move_toward(_dodge, target, DODGE_SPEED * delta)
	position = _base + Vector2(-_dir.y, _dir.x).normalized() * _dodge


# ---- standing, working, flying, dashing -----------------------------------------------------------------------

func _tick_work(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = _ctx.rng.randf_range(0.6, 1.2)
		_show(1 if _cur == 0 else 0)
	_breathe()


func _tick_still(delta: float) -> void:
	_breathe()
	if def.fade_near > 0.0:
		_tick_fade(delta)


func _breathe() -> void:
	_sprite.scale.y = _unit * (1.0 + 0.012 * sin(_time * 1.6))


## The Grey Stranger melts away while the hero is close and comes back a while after the hero leaves.
func _tick_fade(delta: float) -> void:
	var hero := _ctx.hero
	var near := hero != null and hero.position.distance_to(_base) < def.fade_near
	if near:
		_hidden_for = _ctx.rng.randf_range(def.fade_back.x, def.fade_back.y)
	elif _hidden_for > 0.0:
		_hidden_for -= delta
	var target := 0.0 if near or _hidden_for > 0.0 else 1.0
	_alpha = move_toward(_alpha, target, delta / FADE_TIME)
	modulate.a = _alpha
	visible = _alpha > 0.01
	_show(1 if _alpha < 0.9 and _tex.size() > 1 else 0)


func _tick_fly(delta: float) -> void:
	_angle += _speed / def.radius * delta
	var p := def.pos + Vector2(cos(_angle), sin(_angle)) * def.radius
	var tangent := Vector2(-sin(_angle), cos(_angle))
	_set_flip(tangent.x > 0.0)
	_set_base(p)
	_sprite.position.y = -FLY_HEIGHT + sin(_time * 3.0) * 4.0


func _tick_dash(delta: float) -> void:
	if state == State.WAIT:
		_timer -= delta
		if _timer > 0.0:
			return
		visible = true
		state = State.DASH
		_path = PackedVector2Array([def.to if _base.distance_to(def.pos) < 1.0 else def.pos])
	var to := _path[0] - _base
	_face(to)
	_bob += delta * 30.0
	_sprite.position.y = -absf(sin(_bob)) * 2.0
	if to.length() <= _speed * delta:
		_set_base(_path[0])
		visible = false
		state = State.WAIT
		_timer = _ctx.rng.randf_range(def.interval.x, def.interval.y)
	else:
		_set_base(_base + to.normalized() * _speed * delta)


# ---- pictures --------------------------------------------------------------------------------------------------

func _set_base(p: Vector2) -> void:
	_base = p
	position = p


## Turns to look along `dir`: the picture (towards/away) and the mirroring.
func _face(dir: Vector2) -> void:
	if dir.length() < 0.01:
		return
	_dir = dir.normalized()
	_towards = LifeFacing.is_towards(_dir, _towards)
	_flipped = LifeFacing.is_flipped(_towards, _dir, _flipped)
	_show(0 if _towards or _tex.size() < 2 else 1)
	_sprite.flip_h = _flipped


func _set_flip(f: bool) -> void:
	_flipped = f
	_sprite.flip_h = f


## Shows picture `i` of this resident, the feet at the node's origin.
func _show(i: int) -> void:
	_cur = i
	var t := _tex[mini(i, _tex.size() - 1)]
	_sprite.texture = t
	if t != null:
		_sprite.offset = Vector2(-t.get_width() / 2.0, -t.get_height())


func _pop_emote(slot: int) -> void:
	_emote.texture = _ctx.texture(&"emote", slot)
	var head := -(_tex[0].get_height() * _unit if _tex[0] != null else 50.0) - 14.0
	_emote.position = Vector2(0, head)
	_emote.scale = Vector2.ZERO
	_emote.modulate.a = 1.0
	_emote.visible = true
	var s := _ctx.life.emote_scale
	var tw := _emote.create_tween()
	tw.tween_property(_emote, "scale", Vector2(s, s), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(_emote, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: _emote.visible = false)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SHADOW_FLATNESS))
	draw_circle(Vector2.ZERO, _shadow_w * 0.5, Color(0, 0, 0, 0.18))
	draw_circle(Vector2.ZERO, _shadow_w * 0.34, Color(0, 0, 0, 0.22))
