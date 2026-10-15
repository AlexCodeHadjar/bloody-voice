class_name MarkLayer
extends Node2D
## The lairs the rumors led to (GDD 8.4, owner 2026-10-15), on the district map: a dark iron disc with a slow red glow
## and three claw marks over the street point. A click reports the lair; the screen walks the hunter there.

signal mark_clicked(uid: int)

const RADIUS := 62.0  ## art px
const GLOW := Color(0.85, 0.12, 0.08)
const DISC := Color(0.08, 0.06, 0.05, 0.92)
const RIM := Color(0.72, 0.56, 0.3)
const CLAW := Color(0.78, 0.1, 0.06)
const LIFT := 70.0  ## the disc floats above the street

var _map: DistrictMapDef
var _spots: Array[Vector2] = []
var _hot := -1  ## the hovered lair
var _t := 0.0


func setup(map: DistrictMapDef) -> void:
	_map = map
	EventBus.rumors_changed.connect(refresh)
	EventBus.day_changed.connect(func(_d: int) -> void: refresh())
	refresh()


func refresh() -> void:
	for child: Node in get_children():
		child.queue_free()
	_spots.clear()
	for m: RumorsState.Mark in GameState.run.rumors.marks:
		var at := _map.node_pos(m.node) - Vector2(0.0, LIFT)
		var i := _spots.size()
		_spots.append(at)
		var b := Button.new()  # an invisible button over the disc: the click and the name
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2.ONE * RADIUS * 2.0
		b.position = at - b.size * 0.5
		b.tooltip_text = Loc.t("ui.rumor.target_tip", {"name": ContentDB.data.monster(m.monster).name})
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.mouse_entered.connect(func() -> void:
			_hot = i
			UiKit.sound(&"ui.hover"))
		b.mouse_exited.connect(func() -> void: _hot = -1)
		b.pressed.connect(func() -> void:
			UiKit.sound(&"ui.click")
			mark_clicked.emit(m.uid))
		add_child(b)
	queue_redraw()


func _process(delta: float) -> void:
	if not _spots.is_empty():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 2.2)
	for i: int in _spots.size():
		var c := _spots[i]
		var r := RADIUS * (1.1 if i == _hot else 1.0)
		for k: int in 4:  # a soft red glow, wider as it pulses
			draw_circle(c, r * (1.25 + 0.12 * k + 0.1 * pulse), Color(GLOW, 0.09 + 0.04 * pulse))
		draw_circle(c, r, DISC)
		draw_arc(c, r, 0.0, TAU, 48, RIM if i != _hot else Color(1.0, 0.83, 0.5), 5.0, true)
		for k: int in 3:  # three claw marks across the disc
			var x := (k - 1) * r * 0.32
			var from := c + Vector2(x - r * 0.28, -r * 0.55)
			var to := c + Vector2(x + r * 0.28, r * 0.55)
			draw_line(from, to, CLAW, 9.0, true)
			draw_line(from + Vector2(2, 2), to + Vector2(2, 2), Color(0, 0, 0, 0.5), 3.0, true)
