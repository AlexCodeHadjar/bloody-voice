class_name HeroView
extends Control
## The hunter's corner (GDD 21.2 zones 7-9): portrait medallion, HP and Sanity vials, block badge, statuses, the weapon
## plate with one bullet per round and the action-point lamps (they go out one by one).

const SIZE := Vector2(560, 400)
const LAMP := Vector2(42, 80)

var _portrait: TextureRect
var _hp: VialView
var _sanity: VialView
var _block_badge: Control
var _block_label: Label
var _statuses: HFlowContainer
var _bullets: HBoxContainer
var _weapon_label: Label
var _lamp_box: Control
var _lamps: Array[TextureRect] = []
var _lit: Array[bool] = []
var _flash: Tween


func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_weapon()
	_portrait = CombatKit.image("hunter_portrait", Vector2(18, 118), Vector2(152, 150))
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_portrait)
	var vials := Control.new()
	vials.position = Vector2(184, 112)
	vials.size = Vector2(120, 240)
	vials.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vials)
	_hp = VialView.new("hp")
	vials.add_child(_hp)
	_sanity = VialView.new("sanity")
	_sanity.position.x = 62
	vials.add_child(_sanity)
	TutorialAnchors.register(&"vials", vials)
	_block_badge = Control.new()
	_block_badge.position = Vector2(112, 222)
	_block_badge.size = Vector2(60, 60)
	_block_badge.mouse_filter = Control.MOUSE_FILTER_STOP
	_block_badge.add_child(CombatKit.image("shield_badge", Vector2.ZERO, _block_badge.size))
	_block_label = CombatKit.outlined("0", 22, Palette.PARCHMENT, Vector2(0, 14), 60.0)
	_block_badge.add_child(_block_label)
	add_child(_block_badge)
	_statuses = HFlowContainer.new()
	_statuses.position = Vector2(318, 118)
	_statuses.size = Vector2(130, 200)
	_statuses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_statuses)
	_build_lamps()


func _build_weapon() -> void:
	var weapon := Control.new()
	weapon.position = Vector2(18, 8)
	weapon.size = Vector2(310, 88)
	weapon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(weapon)
	weapon.add_child(CombatKit.image("weapon_plate", Vector2.ZERO, weapon.size))
	_weapon_label = CombatKit.outlined(_weapon_name(), 15, Palette.PARCHMENT, Vector2(30, 6), 250.0)
	weapon.add_child(_weapon_label)
	_bullets = HBoxContainer.new()
	_bullets.add_theme_constant_override("separation", 6)
	_bullets.alignment = BoxContainer.ALIGNMENT_CENTER
	_bullets.position = Vector2(30, 30)
	_bullets.size = Vector2(250, 50)
	_bullets.tooltip_text = Loc.t("ui.combat.ammo")
	weapon.add_child(_bullets)
	TutorialAnchors.register(&"weapon", weapon)


func _build_lamps() -> void:
	_lamp_box = Control.new()
	_lamp_box.position = Vector2(392, 4)
	_lamp_box.size = Vector2(150, 84)
	_lamp_box.tooltip_text = Loc.t("ui.combat.ap")
	add_child(_lamp_box)
	TutorialAnchors.register(&"ap", _lamp_box)


func refresh(h: HeroCombatant) -> void:
	_hp.show_value(h.hp, h.max_hp, Loc.t("ui.combat.hp"))
	_sanity.show_value(h.sanity, h.max_sanity, Loc.t("ui.combat.sanity") + (" — " + Loc.t("ui.combat.panic") if h.panicked else ""))
	_block_badge.visible = h.block > 0
	_block_badge.tooltip_text = Loc.t("ui.status.block", {"n": h.block})
	_block_label.text = str(h.block)
	CombatKit.fill_statuses(_statuses, h)
	_refresh_bullets(h)
	_refresh_lamps(h)


## One bullet per round: loaded rounds bright, spent ones dim.
func _refresh_bullets(h: HeroCombatant) -> void:
	for c: Node in _bullets.get_children():
		_bullets.remove_child(c)
		c.queue_free()
	for i: int in maxi(h.max_ammo, h.ammo):
		var bullet := CombatKit.image("bullet", Vector2.ZERO, Vector2(9, 52))
		bullet.custom_minimum_size = bullet.size
		bullet.modulate = Color.WHITE if i < h.ammo else Color(0.25, 0.25, 0.25, 0.6)
		_bullets.add_child(bullet)


## Lamps that go dark do so one after another; lamps that light up change at once.
func _refresh_lamps(h: HeroCombatant) -> void:
	while _lamps.size() < h.max_ap:
		var lamp := CombatKit.image("ap_lamp__lit", Vector2(_lamps.size() * (LAMP.x + 6.0), 2), LAMP)
		lamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lamp.pivot_offset = LAMP / 2.0
		_lamp_box.add_child(lamp)
		_lamps.append(lamp)
		_lit.append(true)
	var going_out := 0
	for i: int in _lamps.size():
		var want := i < h.ap
		if want == _lit[i]:
			continue
		_lit[i] = want
		var tex := CombatKit.tex("ap_lamp__lit" if want else "ap_lamp__dark")
		if want:
			_lamps[i].texture = tex
		else:
			_go_dark(_lamps[i], tex, going_out * 0.16)
			going_out += 1


func _go_dark(lamp: TextureRect, tex: Texture2D, delay: float) -> void:
	var t := lamp.create_tween()
	t.tween_interval(delay)
	t.tween_property(lamp, "modulate", Color(1.8, 1.5, 1.0), 0.08)
	t.tween_callback(func() -> void: lamp.texture = tex)
	t.tween_property(lamp, "modulate", Color.WHITE, 0.3)


## The hunter was hit: the portrait flashes red.
func play_hit() -> void:
	if _flash != null:
		_flash.kill()
	_portrait.modulate = Color(2.2, 1.0, 1.0)
	_flash = create_tween()
	_flash.tween_property(_portrait, "modulate", Color.WHITE, 0.35)


func portrait_global() -> Vector2:
	return _portrait.get_global_transform() * (_portrait.size / 2.0)


func _weapon_name() -> String:
	var w := ContentDB.data.weapon(GameState.run.loadout.weapon)
	return w.name if w != null else ""
