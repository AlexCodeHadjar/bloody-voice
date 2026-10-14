extends Control
## Equipment (GDD 5) as the hunter's workbench (owner 2026-10-14, sketch docs/assets/ui/equipment_workbench.png, GDD 5.7):
## the armor on a mannequin with its mechanism sockets (left), the rifle large with its cells (centre), the drawer of
## spare modules and mechanisms (right), the fight deck as a fan of cards (bottom). Free and instant outside a fight.
## Take a spare from the drawer, right-click / R to rotate, click a cell (or a mechanism socket) to install; click an
## installed module or mechanism to take it back into the hand.

const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const BENCH_ART := "res://art/ui/EQUIP__bench.webp"
const FRAME := Vector2(1920, 1080)

var _frame: Control
var _tablet: WeaponTabletView
var _stand: ArmorStandView
var _drawer: GearDrawerView
var _deck: DeckFanView
var _message: Label
var _held_kind: StringName = &""  ## module | mechanism
var _held: StringName = &""
var _held_tier := 1  ## every module copy has its own tier (GDD 6.3)
var _rot: int = 0


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"equipment")
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.loadout_changed.connect(_refresh)
	_refresh()
	Tutorial.trigger.call_deferred(&"equipment_open")


func _build() -> void:
	var bench := TextureRect.new()
	bench.texture = UiKit.texture(BENCH_ART)
	bench.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bench.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bench.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bench)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.25)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -FRAME.x / 2.0
	_frame.offset_right = FRAME.x / 2.0
	_frame.offset_top = -FRAME.y / 2.0
	_frame.offset_bottom = FRAME.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_build_top()
	_build_stand()
	_build_rifle()
	_build_drawer()
	_panel(Rect2(16, 788, 300, 280))  # backing for the deck's title and totals
	_deck = DeckFanView.new()
	_deck.position = Vector2(30, 796)
	_deck.setup()
	_frame.add_child(_deck)
	TutorialAnchors.register(&"deck", _deck)


func _panel(rect: Rect2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.045, 0.035, 0.8), Palette.BRASS))
	_frame.add_child(p)
	return p


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 14)
	bar.size = Vector2(1872, 64)
	bar.add_theme_constant_override("separation", 18)
	_frame.add_child(bar)
	var title := UiKit.label(Loc.t("ui.equip.title"), 46, Palette.BRASS_LIGHT)
	title.add_theme_constant_override("outline_size", 10)  # readable over the lamp on the bench
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bar.add_child(title)
	_message = UiKit.paragraph(Loc.t("ui.equip.hint"), 17, Palette.PARCHMENT)  # what the hand holds and what to do
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_message.add_theme_constant_override("outline_size", 6)
	_message.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bar.add_child(_message)
	if OS.is_debug_build():
		var grant := UiKit.button(Loc.t("ui.equip.dev_all"), 16)
		grant.custom_minimum_size = Vector2(190, 48)
		grant.pressed.connect(GameState.dev_grant_all_gear)
		bar.add_child(grant)
	var back := UiKit.button(Loc.t("ui.equip.back"), 20)
	back.custom_minimum_size = Vector2(230, 48)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(DISTRICT))
	bar.add_child(back)


func _build_stand() -> void:
	var p := _panel(Rect2(16, 96, 360, 680))
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.equip.armor"), 28, Palette.BRASS_LIGHT))
	_stand = ArmorStandView.new()
	_stand.setup(ContentDB.data, GameState.run.loadout)
	_stand.socket_clicked.connect(_on_socket)
	v.add_child(_stand)
	TutorialAnchors.register(&"armor", _stand)


func _build_rifle() -> void:
	var p := _panel(Rect2(392, 96, 1080, 680))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(UiKit.label(ContentDB.data.weapon(GameState.run.loadout.weapon).name, 28, Palette.BRASS_LIGHT))
	_tablet = WeaponTabletView.new()
	_tablet.setup(ContentDB.data, GameState.run.loadout)
	_tablet.cell_clicked.connect(_on_cell)
	_tablet.rotate_requested.connect(_rotate)
	_tablet.module_hovered.connect(func(module_name: String) -> void: _deck.light(module_name))
	v.add_child(_tablet)
	TutorialAnchors.register(&"weapon_grid", _tablet)


func _build_drawer() -> void:
	_drawer = GearDrawerView.new()
	_drawer.position = Vector2(1488, 96)
	_drawer.size = Vector2(416, 680)
	_drawer.setup()
	_drawer.picked.connect(_hold_item)
	_frame.add_child(_drawer)
	TutorialAnchors.register(&"spares", _drawer)


func _refresh() -> void:
	_tablet.set_ghost(_held if _held_kind == &"module" else &"", _rot)
	_tablet.refresh()
	_stand.refresh()
	_drawer.set_held(_held_kind, _held, _held_tier)
	_drawer.refresh()
	_deck.refresh()


## The drawer's tray in hand (the same tray again puts it back).
func _hold_item(kind: StringName, id: StringName, tier: int) -> void:
	var same := _held_kind == kind and _held == id and _held_tier == tier
	_held_kind = &"" if same else kind
	_held = &"" if same else id
	_held_tier = tier
	if _held == &"":
		_message.text = Loc.t("ui.equip.hint")
	elif kind == &"module":
		_message.text = _holding_text()
	else:
		_message.text = Loc.t("ui.equip.holding_mech", {"mechanism": ContentDB.data.mechanism(id).name})
	UiKit.sound(&"ui.click")
	_refresh()


## Kept for the dev shots: takes a spare module into the hand.
func _hold(id: StringName, tier: int = 1) -> void:
	_hold_item(&"module", id, tier)


## What installing the held module would change, so the player sees the deck effect before placing it.
func _holding_text() -> String:
	var m := ContentDB.data.module(_held)
	var t := _held_tier
	var gains: PackedStringArray = []
	for c: StringName in m.cards_at(t):
		gains.append("+%s" % ContentDB.data.card(c).name)
	var mods := m.mods_at(t)
	for k: StringName in mods:
		gains.append("%s %s" % [Loc.t("mod.%s" % k), UiKit.signed(mods[k])])
	var change := ", ".join(gains) if not gains.is_empty() else m.effect_at(t)
	return Loc.t("ui.equip.holding", {"module": m.name, "change": change})


func _rotate() -> void:
	_rot = (_rot + 1) % 4
	_tablet.set_ghost(_held if _held_kind == &"module" else &"", _rot)


func _on_cell(section: StringName, cell: Vector2i) -> void:
	if _held_kind == &"mechanism":  # a mechanism goes into a socket on the mannequin, never onto the rifle
		_message.text = Loc.t("ui.equip.mech_not_here")
		UiKit.sound(&"ui.error")
		return
	if _held_kind == &"module":
		var problem := GameState.equip_module(_held, section, cell, _rot, _held_tier)
		_message.text = problem
		UiKit.sound(&"gear.install" if problem == "" else &"ui.error")
		if problem == "":
			Tutorial.action(&"module_installed")
			_held_kind = &""
			_held = &""
			_refresh()
		return
	var index := WeaponGridRules.placement_at(GameState.run.loadout, ContentDB.data, section, cell)
	if index >= 0:
		_rot = GameState.run.loadout.placements[index].rot
		var p := GameState.unequip_module(index)
		_held_kind = &"module" if p != null else &""
		_held = p.module if p != null else &""
		_held_tier = p.tier if p != null else 1
		_message.text = Loc.t("ui.equip.picked")
		_refresh()


## A mechanism socket on the mannequin: the mechanism in hand goes in; with an empty hand the one there comes out.
func _on_socket(piece: StringName, index: int) -> void:
	if _held_kind == &"mechanism":
		var problem := GameState.set_socket(piece, index, _held)
		_message.text = problem
		UiKit.sound(&"gear.install" if problem == "" else &"ui.error")
		if problem == "":
			_held_kind = &""
			_held = &""
			_refresh()
		return
	var current := ArmorRules.mechanism_at(GameState.run.loadout, piece, index)
	if current == &"":
		_message.text = Loc.t("ui.equip.socket_hint")
		return
	GameState.set_socket(piece, index, &"")
	_held_kind = &"mechanism"
	_held = current
	_held_tier = 1
	_message.text = Loc.t("ui.equip.picked_mech", {"mechanism": ContentDB.data.mechanism(current).name})
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_R:
		_rotate()
	elif event.is_action_pressed("ui_cancel") and _held == &"":
		SettingsPanel.open(self, true)
	elif event.is_action_pressed("ui_cancel"):
		_held_kind = &""
		_held = &""
		_message.text = Loc.t("ui.equip.hint")
		_refresh()
