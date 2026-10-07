class_name HeroView
extends HBoxContainer
## The hunter's side: HP, Sanity, block, statuses, AP, and the weapon card with ammo (GDD 9.1).

signal self_clicked

var _hp: StatBar
var _sanity: StatBar
var _statuses: HBoxContainer
var _ap: Label
var _ammo: HBoxContainer
var _hero_box: PanelContainer


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var left := VBoxContainer.new()
	add_child(left)
	var ap_row := HBoxContainer.new()
	ap_row.add_child(Icons.rect("STAT", &"ap", 44))
	_ap = UiKit.label("", 34, Palette.BRASS_LIGHT)
	ap_row.add_child(_ap)
	left.add_child(ap_row)
	_hero_box = PanelContainer.new()
	_hero_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_hero_box.gui_input.connect(_on_hero_input)
	add_child(_hero_box)
	var v := VBoxContainer.new()
	_hero_box.add_child(v)
	v.add_child(UiKit.label("The Hunter", 24, Palette.PARCHMENT))
	_hp = StatBar.new().setup(Palette.BLOOD, 320.0, 17, &"hp")
	v.add_child(_hp)
	_sanity = StatBar.new().setup(Color("6b5a9a"), 320.0, 17, &"sanity")
	v.add_child(_sanity)
	_statuses = HBoxContainer.new()
	_statuses.add_theme_constant_override("separation", 12)
	_statuses.custom_minimum_size = Vector2(0, 30)
	v.add_child(_statuses)
	var weapon := PanelContainer.new()
	weapon.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.12, 0.1, 0.08, 0.95), Palette.STEEL))
	add_child(weapon)
	var wv := VBoxContainer.new()
	weapon.add_child(wv)
	wv.add_child(UiKit.label("Hunting Rifle", 20, Palette.PARCHMENT))
	_ammo = HBoxContainer.new()
	_ammo.add_theme_constant_override("separation", 2)
	_ammo.tooltip_text = "Ammo"
	wv.add_child(_ammo)


func refresh(h: HeroCombatant, targeting_self: bool) -> void:
	_ap.text = "%d/%d" % [h.ap, h.max_ap]
	_hp.show_value("HP", h.hp, h.max_hp)
	_sanity.show_value("Sanity" + ("  — PANIC" if h.panicked else ""), h.sanity, h.max_sanity)
	Icons.fill_statuses(_statuses, h)
	_refresh_ammo(h)
	var box := UiKit.panel_box(Color(0.08, 0.06, 0.06, 0.9), Palette.BRASS_LIGHT if targeting_self else Palette.BRASS)
	box.set_border_width_all(4 if targeting_self else 2)
	_hero_box.add_theme_stylebox_override("panel", box)


## One bullet per round: loaded rounds bright, spent ones dim.
func _refresh_ammo(h: HeroCombatant) -> void:
	for c: Node in _ammo.get_children():
		c.queue_free()
	for i: int in maxi(h.max_ammo, h.ammo):
		var bullet := Icons.rect("STAT", &"ammo", 34)
		bullet.modulate = Color.WHITE if i < h.ammo else Color(0.3, 0.3, 0.3, 0.6)
		_ammo.add_child(bullet)


func _on_hero_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		self_clicked.emit()
