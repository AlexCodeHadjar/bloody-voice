class_name MarkSheet
extends Control
## A mark on the district map (GDD 8.4): the creature of a contract the rumors led to, or a red unknown threat (an
## optional fight with any creature of the district, it fades in a few days). «В бой» starts the fight (the day ends
## after it); «Не сейчас» closes. Full-screen overlay.

signal closed
signal fight_started

var _uid := 0


func open_mark(uid: int) -> void:
	_uid = uid
	var m := GameState.run.rumors.find(uid)
	var threat := m != null and m.kind == &"threat"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	UiKit.overlay(self, Palette.ALARM if threat else Palette.BRASS, Vector2(720, 0)).add_child(v)
	if m == null:
		close_sheet.call_deferred()
		return
	_fill_text(v, m, threat)
	v.add_child(UiKit.label(Loc.t("ui.rumor.fight_day"), 16, Palette.INK_MUTED))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	var go := Icons.button("INTENT", &"attack", Loc.t("ui.rumor.fight"), 20)
	go.pressed.connect(_on_fight)
	buttons.add_child(go)
	var later := UiKit.button(Loc.t("ui.rumor.later"), 20)
	later.pressed.connect(close_sheet)
	buttons.add_child(later)
	v.add_child(buttons)
	UiKit.sound(&"ui.open")


## The threat: where it roams and when it leaves; the creature: whose lair the trail led to.
func _fill_text(v: VBoxContainer, m: RumorsState.Mark, threat: bool) -> void:
	var zone := ContractKit.zone_name(ContentDB.data.district_map(GameState.run.hero_district), m.zone)
	if threat:
		v.add_child(Icons.with_text("INTENT", &"unknown", Loc.t("ui.rumor.threat_title"), 48, 30, Palette.ALARM))
		v.add_child(UiKit.paragraph(Loc.t("ui.rumor.threat_text", {"zone": zone, "n": m.expires_day - GameState.run.day}),
			19, Palette.PARCHMENT))
		return
	var c := GameState.run.contracts.find(m.contract_uid)
	v.add_child(Icons.with_text("OUTCOME", &"target", Loc.t("ui.rumor.target_title"), 48, 30, Palette.BRASS_LIGHT))
	v.add_child(UiKit.paragraph(Loc.t("ui.rumor.target_text", {"name": ContractKit.monster_name(c) if c != null else "",
		"zone": zone}), 19, Palette.PARCHMENT))


func _on_fight() -> void:
	if GameState.fight_mark(_uid):
		fight_started.emit()
	else:
		close_sheet()


func close_sheet() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_sheet()
