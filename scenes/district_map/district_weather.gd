class_name DistrictWeather
extends Control
## The look of a district state over the map (GDD 14.5; owner 2026-10-12: overlays until state art exists): a tint
## and drifting particles per state overlay — fog (grey veil, slow mist), chalk (a sickly pale cast for quarantine),
## lanterns (a warm glow and rising sparks). Screen-space, ignores the mouse; show_state() swaps it.

const LOOKS: Dictionary[StringName, Array] = {  ## overlay -> [tint, particle colour, amount, rising]
	&"fog": [Color(0.55, 0.58, 0.6, 0.32), Color(0.85, 0.88, 0.9, 0.18), 70, false],
	&"chalk": [Color(0.75, 0.8, 0.62, 0.16), Color(0.95, 0.95, 0.88, 0.12), 24, false],
	&"lanterns": [Color(0.95, 0.55, 0.2, 0.12), Color(1.0, 0.72, 0.3, 0.8), 60, true],
}

var _tint := ColorRect.new()
var _particles := CPUParticles2D.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tint)
	_particles.emitting = false
	_particles.lifetime = 9.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.texture = _soft_dot()  # round, fading puffs instead of squares
	add_child(_particles)
	resized.connect(_fit)
	visible = false


func show_state(def: DistrictStateDef) -> void:
	var look: Array = LOOKS.get(def.overlay if def != null else &"", [])
	visible = not look.is_empty()
	_particles.emitting = visible
	if not visible:
		return
	_tint.color = look[0] as Color
	_particles.color = look[1] as Color
	_particles.amount = look[2] as int
	var rising: bool = look[3]
	_particles.direction = Vector2(0, -1) if rising else Vector2(1, 0)
	_particles.spread = 25.0 if rising else 10.0
	_particles.initial_velocity_min = 20.0 if rising else 8.0
	_particles.initial_velocity_max = 45.0 if rising else 22.0
	_particles.gravity = Vector2.ZERO
	_particles.scale_amount_min = 0.08 if rising else 1.0  # of the 64 px dot
	_particles.scale_amount_max = 0.15 if rising else 2.5
	_fit()


static func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _fit() -> void:
	_particles.position = size * 0.5
	_particles.emission_rect_extents = size * 0.5
