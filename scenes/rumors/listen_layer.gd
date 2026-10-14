class_name ListenLayer
extends Node2D
## Listening to the street on the district map (GDD 8.4, owner 2026-10-14). «Слушать улицу» while the hunter stands:
## blue rings spread from him like a locator and fade out at the zone's border; every few seconds a rumor flares up on
## a free street point of the zone (at most max_heard), an unread one fades. A click on a rumor reports it; walking or
## an open panel pauses listening. Also shows the marks: the found creature (brass) and an unknown threat (red).

signal rumor_opened(h: RumorGenerator.Heard)
signal mark_clicked(uid: int)

const DIAMOND := "res://art/ui/RUMOR__diamond__idle.webp"
const DIAMOND_HOT := "res://art/ui/RUMOR__diamond__hovered.webp"
const HEARD_SIZE := 160.0  ## art px
const MARK_SIZE := 210.0
const BLUE := Color(0.45, 0.75, 1.0)
const HEARD_TINT := Color(0.62, 0.82, 1.0)
const TARGET_TINT := Color(1.0, 0.86, 0.5)
const THREAT_TINT := Color(1.0, 0.32, 0.28)
const RING_EVERY := 1.4  ## seconds between rings
const RING_TIME := 2.6  ## seconds a ring takes to reach the farthest border
const RING_POINTS := 96
const FADE := 3.0  ## seconds an unread rumor takes to fade out

var busy: Callable = func() -> bool: return false  ## the screen: a panel is open (listening pauses)
var listening := false
var _map: DistrictMapDef
var _hero: HeroWalker
var _zone: StringName = &""
var _reach := 0.0  ## the farthest corner of the zone from the hunter, art px
var _rings: Array[float] = []  ## ages of the rings in flight
var _ring_clock := 0.0
var _next := 0.0  ## seconds until the next rumor
var _heard: Dictionary[TextureButton, RumorGenerator.Heard] = {}
var _age: Dictionary[TextureButton, float] = {}
var _marks := Node2D.new()
var _timer_rng: RandomNumberGenerator
var _button: Button


func setup(map: DistrictMapDef, hero: HeroWalker) -> void:
	_map = map
	_hero = hero
	_timer_rng = SeededRng.make_stream(GameState.run.master_seed, &"listen_timer", GameState.run.day)
	add_child(_marks)
	EventBus.rumors_changed.connect(refresh_marks)
	EventBus.day_changed.connect(func(_d: int) -> void: refresh_marks())
	refresh_marks()


## The «Слушать улицу» button at the bottom middle of the screen; it shows while the hunter stands in a zone.
func make_button() -> Button:
	_button = Icons.button("ACTION", &"investigate", Loc.t("ui.rumor.listen"), 20)
	_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_button.offset_bottom = -24.0
	_button.visible = false
	_button.pressed.connect(toggle)
	TutorialAnchors.register(&"listen_button", _button)
	return _button


## What taking a rumor did, floating up over the hunter: the trail, a found creature, something stirring — a wrong
## rumor says only that it is written down (the count is hidden).
func show_taken(t: RumorRules.Taken) -> void:
	var key := "ui.rumor.noted"
	if t.mark != null:
		key = "ui.rumor.noted_threat" if t.mark.kind == &"threat" else "ui.rumor.noted_found"
	elif t.right:
		key = "ui.rumor.noted_trail"
	var l := UiKit.label(Loc.t(key, {"n": t.trail, "of": ContentDB.data.balance.rumors.trail_needed}), 36,
		Palette.ALARM if key == "ui.rumor.noted_threat" else Palette.BRASS_LIGHT)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.reset_size()
	l.position = _hero.position - Vector2(l.size.x * 0.5, 190.0)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 60.0, 2.6)
	tw.tween_property(l, "modulate:a", 0.0, 2.6).set_delay(1.2)
	tw.chain().tween_callback(l.queue_free)
	if t.mark != null:
		UiKit.sound(&"ui.open")


func toggle() -> void:
	if listening:
		stop()
		return
	listening = true
	_enter_zone(DistrictMapRules.zone_at(_map, _hero.position))
	_next = 1.0  # the first rumor comes quickly
	UiKit.sound(&"ui.confirm")
	Tutorial.trigger(&"first_listen")


func stop() -> void:
	listening = false
	_rings.clear()
	_clear_heard()
	queue_redraw()


func _process(delta: float) -> void:
	if _button != null:
		_button.visible = not _hero.is_walking() and not busy.call() and DistrictMapRules.zone_at(_map, _hero.position) != &""
		_button.text = Loc.t("ui.rumor.stop" if listening else "ui.rumor.listen")
	if not listening or _hero.is_walking() or busy.call():
		return
	var zone := DistrictMapRules.zone_at(_map, _hero.position)
	if zone != _zone:  # the hunter walked into another zone: its own rumors
		_enter_zone(zone)
	_tick_rings(delta)
	_tick_heard(delta)
	_next -= delta
	if _next <= 0.0:
		var b := ContentDB.data.balance.rumors
		_next = _timer_rng.randf_range(b.listen_every_min, b.listen_every_max)
		_hear()


func _enter_zone(zone: StringName) -> void:
	_clear_heard()
	_zone = zone
	_reach = 0.0
	for z: DistrictMapDef.ZoneDef in _map.zones:
		if z.id == zone:
			for p: Vector2 in z.polygon:
				_reach = maxf(_reach, p.distance_to(_hero.position))


func _hear() -> void:
	if _zone == &"" or _heard.size() >= RumorRules.max_heard(GameState.run, ContentDB.data):
		return
	var used: Array[StringName] = []
	for h: RumorGenerator.Heard in _heard.values():
		used.append(h.node)
	var h := GameState.hear_rumor(_zone, used)
	if h == null:
		return
	var b := _diamond(_map.node_pos(h.node), HEARD_SIZE, HEARD_TINT, Loc.t("ui.rumor.heard_tip"))
	b.modulate.a = 0.0
	b.create_tween().tween_property(b, "modulate:a", 1.0, 0.4)
	b.pressed.connect(_open.bind(b))
	add_child(b)
	_heard[b] = h
	_age[b] = 0.0
	UiKit.sound(&"paper.map")


func _tick_heard(delta: float) -> void:
	var life := ContentDB.data.balance.rumors.heard_seconds
	for b: TextureButton in _heard.keys():
		_age[b] += delta
		if _age[b] > 0.4:  # after the fade-in: fades out over its last FADE seconds
			b.modulate.a = clampf((life - _age[b]) / FADE, 0.0, 1.0)
		if _age[b] >= life:
			_drop(b)


func _open(b: TextureButton) -> void:
	var h: RumorGenerator.Heard = _heard.get(b)
	if h == null or busy.call():  # a panel is open: the rumor stays for later
		return
	_drop(b)
	UiKit.sound(&"ui.click")
	rumor_opened.emit(h)


func _drop(b: TextureButton) -> void:
	_heard.erase(b)
	_age.erase(b)
	b.queue_free()


func _clear_heard() -> void:
	for b: TextureButton in _heard.keys():
		_drop(b)


func _tick_rings(delta: float) -> void:
	_ring_clock -= delta
	if _ring_clock <= 0.0:
		_ring_clock = RING_EVERY
		_rings.append(0.0)
	for i: int in range(_rings.size() - 1, -1, -1):
		_rings[i] += delta
		if _rings[i] >= RING_TIME:
			_rings.remove_at(i)
	queue_redraw()


## Each ring is drawn only inside the zone, fading as it spreads, so it dies out at the border.
func _draw() -> void:
	if not listening or _zone == &"":
		return
	var poly := PackedVector2Array()
	for z: DistrictMapDef.ZoneDef in _map.zones:
		if z.id == _zone:
			poly = z.polygon
	var c := _hero.position
	for age: float in _rings:
		var k := age / RING_TIME
		var r := _reach * k
		var color := Color(BLUE, 0.7 * (1.0 - k))
		var run := PackedVector2Array()
		for i: int in RING_POINTS + 1:
			var p := c + Vector2.from_angle(TAU * i / RING_POINTS) * r
			if Geometry2D.is_point_in_polygon(p, poly):
				run.append(p)
			else:
				_arc(run, color)
				run = PackedVector2Array()
		_arc(run, color)


func _arc(points: PackedVector2Array, color: Color) -> void:
	if points.size() >= 2:
		draw_polyline(points, Color(color, color.a * 0.35), 14.0, true)  # soft glow
		draw_polyline(points, color, 4.0, true)


## The marks of the run (GDD 8.4): the found creature and the unknown threats.
func refresh_marks() -> void:
	for child: Node in _marks.get_children():
		child.queue_free()
	for m: RumorsState.Mark in GameState.run.rumors.marks:
		var threat := m.kind == &"threat"
		var tip := Loc.t("ui.rumor.threat_tip", {"n": m.expires_day - GameState.run.day}) if threat \
			else Loc.t("ui.rumor.target_tip", {"name": ContentDB.data.monster(m.monster).name})
		var b := _diamond(_map.node_pos(m.node), MARK_SIZE, THREAT_TINT if threat else TARGET_TINT, tip)
		var icon := Icons.rect("INTENT" if threat else "OUTCOME", &"unknown" if threat else &"target", 64)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(MARK_SIZE - 64.0, MARK_SIZE - 64.0) * 0.5
		b.add_child(icon)
		b.pressed.connect(func() -> void:
			UiKit.sound(&"ui.click")
			mark_clicked.emit(m.uid))
		_marks.add_child(b)


## A pulsing tinted diamond floating over the street point `at`.
func _diamond(at: Vector2, side: float, tint: Color, tip: String) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = UiKit.texture(DIAMOND)
	b.texture_hover = UiKit.texture(DIAMOND_HOT)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = Vector2(side, side)
	b.pivot_offset = b.size * 0.5
	b.position = at - Vector2(side * 0.5, side * 0.85)  # floats above the street
	b.self_modulate = tint
	b.tooltip_text = tip
	b.mouse_entered.connect(func() -> void: UiKit.sound(&"ui.hover"))
	var tw := b.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2.ONE * 1.08, 0.9)
	tw.tween_property(b, "scale", Vector2.ONE, 0.9)
	return b
