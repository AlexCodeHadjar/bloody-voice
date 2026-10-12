class_name EnemyPlate
extends Control
## The brass plate under the creature: name and rank, HP bar with phase notches, block badge, statuses and, on capture
## contracts, a dial with the capture chance (GDD 21.2 zone 5).

const SIZE := Vector2(560, 112)

var _title: Label
var _hp: StatBar
var _statuses: HBoxContainer
var _block_badge: Control
var _block_label: Label
var _dial: CaptureDial


## A brass dial: an arc for the chance and the percent in the middle.
class CaptureDial extends Control:
	var chance := 0.0

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, size.x / 2.0, Color(0.12, 0.09, 0.06, 0.95))
		draw_arc(c, size.x / 2.0 - 4.0, 0.0, TAU, 48, Palette.BRASS, 4.0, true)
		draw_arc(c, size.x / 2.0 - 11.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(chance, 0.0, 1.0), 40, Palette.BRASS_LIGHT, 6.0, true)
		var font := UiKit.serif()
		draw_string(font, Vector2(0, c.y + 8.0), "%d%%" % int(chance * 100.0), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Palette.PARCHMENT)


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(CombatKit.plate(Vector2.ZERO, SIZE))
	_title = CombatKit.outlined("", 25, Palette.BRASS_LIGHT, Vector2(40, 8), SIZE.x - 80.0)
	add_child(_title)
	_hp = StatBar.new().setup(Palette.BLOOD, 420.0, 22.0)
	_hp.position = Vector2((SIZE.x - 420.0) / 2.0, 46)
	add_child(_hp)
	_statuses = HBoxContainer.new()
	_statuses.add_theme_constant_override("separation", 10)
	_statuses.position = Vector2(70, 74)
	_statuses.size = Vector2(SIZE.x - 140.0, 30)
	_statuses.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_statuses)
	_block_badge = Control.new()
	_block_badge.position = Vector2(-30, 24)
	_block_badge.size = Vector2(62, 62)
	_block_badge.add_child(CombatKit.image("shield_badge", Vector2.ZERO, _block_badge.size))
	_block_label = CombatKit.outlined("0", 22, Palette.PARCHMENT, Vector2(0, 14), 62.0)
	_block_badge.add_child(_block_label)
	add_child(_block_badge)
	_dial = CaptureDial.new()
	_dial.position = Vector2(SIZE.x - 32.0, 20)
	_dial.size = Vector2(72, 72)
	add_child(_dial)


## capture: chance 0-1 of the best capture card, or a negative number when capture is not allowed.
func refresh(e: EnemyCombatant, capture: float) -> void:
	_title.text = "%s   [%s]" % [e.display_name, e.def.rank]
	var notches: Array[float] = []
	for ph: MonsterDef.PhaseDef in e.def.phases:
		notches.append(ph.below)
	_hp.show_value("%s  %d / %d" % [Loc.t("ui.combat.hp"), maxi(e.hp, 0), e.max_hp], e.hp, e.max_hp, notches)
	CombatKit.fill_statuses(_statuses, e)
	_block_badge.visible = e.block > 0
	_block_badge.tooltip_text = Loc.t("ui.status.block", {"n": e.block})
	_block_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_block_label.text = str(e.block)
	_dial.visible = capture >= 0.0
	_dial.chance = maxf(capture, 0.0)
	_dial.tooltip_text = Loc.t("ui.combat.capture_chance", {"n": int(maxf(capture, 0.0) * 100.0)})
	_dial.queue_redraw()
