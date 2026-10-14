class_name ClickRipple
extends Node2D
## Where the hunter is going (owner 2026-10-14): a warm ring of light at the clicked point that spreads out and fades,
## with a second, later ring and a soft glow in the middle. Lives in the map's world (art px) and frees itself.

const TIME := 0.9
const FROM := 8.0  ## art px
const TO := 70.0
const LIGHT := Color(1.0, 0.82, 0.45)

var _t := 0.0


static func spawn(parent: Node, at: Vector2) -> void:
	var r := ClickRipple.new()
	r.position = at
	r.z_index = 2  # over the street and the residents' feet, under the signboards
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # light, not paint
	r.material = mat
	parent.add_child(r)


func _process(delta: float) -> void:
	_t += delta
	if _t >= TIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / TIME
	_ring(k)
	_ring(clampf((k - 0.25) / 0.75, 0.0, 1.0))  # the second ring starts a little later
	draw_circle(Vector2.ZERO, FROM * 1.6, Color(LIGHT, 0.35 * (1.0 - k)))


func _ring(k: float) -> void:
	if k <= 0.0:
		return
	var eased := 1.0 - pow(1.0 - k, 3.0)  # quick at first, slowing as it spreads
	var radius := lerpf(FROM, TO, eased)
	var alpha := 1.0 - k
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(LIGHT, 0.25 * alpha), 14.0, true)  # soft halo
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(LIGHT, 0.9 * alpha), 4.0, true)
