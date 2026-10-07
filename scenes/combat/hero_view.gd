class_name HeroView
extends HBoxContainer
## The hunter's side: HP, Sanity, block, statuses, AP, and the weapon card with ammo (GDD 9.1).

signal self_clicked

var _hp: StatBar
var _sanity: StatBar
var _info: Label
var _ap: Label
var _weapon: Label
var _hero_box: PanelContainer


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var left := VBoxContainer.new()
	add_child(left)
	_ap = UiKit.label("", 34, Palette.BRASS_LIGHT)
	left.add_child(_ap)
	_hero_box = PanelContainer.new()
	_hero_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_hero_box.gui_input.connect(_on_hero_input)
	add_child(_hero_box)
	var v := VBoxContainer.new()
	_hero_box.add_child(v)
	v.add_child(UiKit.label("The Hunter", 24, Palette.PARCHMENT))
	_hp = StatBar.new().setup(Palette.BLOOD)
	v.add_child(_hp)
	_sanity = StatBar.new().setup(Color("6b5a9a"))
	v.add_child(_sanity)
	_info = UiKit.label("", 16, Palette.FOG)
	v.add_child(_info)
	var weapon := PanelContainer.new()
	weapon.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.12, 0.1, 0.08, 0.95), Palette.STEEL))
	add_child(weapon)
	var wv := VBoxContainer.new()
	weapon.add_child(wv)
	wv.add_child(UiKit.label("Hunting Rifle", 20, Palette.PARCHMENT))
	_weapon = UiKit.label("", 26, Palette.BRASS_LIGHT)
	wv.add_child(_weapon)


func refresh(h: HeroCombatant, targeting_self: bool) -> void:
	_ap.text = "AP %d/%d" % [h.ap, h.max_ap]
	_hp.show_value("HP", h.hp, h.max_hp)
	_sanity.show_value("Sanity" + ("  — PANIC" if h.panicked else ""), h.sanity, h.max_sanity)
	_info.text = "Block %d    %s" % [h.block, StatusText.of(h)]
	_weapon.text = "Ammo " + "●".repeat(h.ammo) + "○".repeat(maxi(h.max_ammo - h.ammo, 0))
	var box := UiKit.panel_box(Color(0.08, 0.06, 0.06, 0.9), Palette.BRASS_LIGHT if targeting_self else Palette.BRASS)
	box.set_border_width_all(4 if targeting_self else 2)
	_hero_box.add_theme_stylebox_override("panel", box)


func _on_hero_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		self_clicked.emit()
