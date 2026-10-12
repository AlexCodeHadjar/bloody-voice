class_name LifeProp
extends Node2D
## A picture on the district map that only moves a little: bonfire flicker, drifting smoke, ripples, swaying laundry,
## a breathing crowd (map-life-people.md). `position` is the centre of the picture, in art px.

var _def: DistrictLifeDef.PropDef
var _sprite := Sprite2D.new()
var _frames: Array[Texture2D] = []
var _unit := 1.0
var _time := 0.0
var _phase := 0.0


func setup(d: DistrictLifeDef.PropDef, at: Vector2, unit: float, rng: RandomNumberGenerator) -> void:
	_def = d
	_unit = unit
	position = at
	_phase = rng.randf() * TAU
	_time = rng.randf() * 20.0
	_frames.append(UiKit.texture(DistrictLifeDef.prop_path(d.art)))
	if d.art_b != "":
		_frames.append(UiKit.texture(DistrictLifeDef.prop_path(d.art_b)))
	_sprite.texture = _frames[0]
	_sprite.scale = Vector2(unit, unit)
	if d.additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_sprite.material = mat
	if d.kind == &"ripple" or d.kind == &"static":
		z_index = -1  # on the ground, under people
	elif d.kind == &"smoke":
		z_index = 3
	add_child(_sprite)
	set_process(d.kind != &"static")
	if d.kind == &"smoke" or d.kind == &"ripple":
		_sprite.modulate.a = 0.0


func _process(delta: float) -> void:
	_time += delta
	match _def.kind:
		&"flicker":
			var a := _time * _def.rate + _phase
			_sprite.modulate.a = 1.0 - _def.amp * (0.5 + 0.25 * (sin(a) + sin(a * 1.7 + _phase)))
			var j := _unit * (1.0 + 0.04 * sin(a * 2.3))
			_sprite.scale = Vector2(j, j)
		&"smoke":
			var f := fposmod(_time * _def.rate + _phase, 1.0)
			_sprite.position.y = -_def.rise * f
			_sprite.modulate.a = sin(f * PI) * 0.7
			_sprite.scale = Vector2.ONE * _unit * (0.7 + 0.8 * f)
		&"ripple":
			var f := fposmod(_time * _def.rate + _phase, 1.0)
			_sprite.modulate.a = (1.0 - f) * 0.8
			_sprite.scale = Vector2.ONE * _unit * (0.3 + 0.9 * f)
		&"sway":
			_sprite.texture = _frames[int(_time / maxf(_def.rate, 0.1)) % _frames.size()]
		&"breathe":
			_sprite.scale = Vector2(_unit, _unit * (1.0 + 0.012 * sin(_time * 1.3 + _phase)))
