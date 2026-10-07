extends Control
## Equipment (GDD 5): weapon cells with modules, armor sockets with mechanisms, and the deck they make.
## Free and instant, anywhere outside a fight. Click a spare module, right-click / R to rotate,
## click a cell to install; click an installed module to pick it up.

const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const TABLET_ART := "res://art/ui/WEAPON__tablet.webp"
const HINT := "Pick a spare module on the right, then click a cell (right click or R rotates). Click an installed module to take it out."

var _tablet: WeaponTabletView
var _spares: VBoxContainer
var _armor: VBoxContainer
var _deck: Label
var _message: Label
var _held: StringName = &""
var _rot: int = 0


func _ready() -> void:
	theme = UiKit.theme()
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.loadout_changed.connect(_refresh)
	_refresh()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)
	root.add_child(_build_left())
	root.add_child(_build_right())


func _build_left() -> Control:
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	var top := HBoxContainer.new()
	top.add_child(UiKit.label("Equipment", 36, Palette.BRASS_LIGHT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	if OS.is_debug_build():
		var grant := UiKit.button("Dev: all gear", 16)
		grant.custom_minimum_size = Vector2(170, 40)
		grant.pressed.connect(GameState.dev_grant_all_gear)
		top.add_child(grant)
	var back := UiKit.button("Back to the city", 18)
	back.custom_minimum_size = Vector2(220, 40)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(CITY_MAP))
	top.add_child(back)
	left.add_child(top)
	var art := TextureRect.new()
	art.texture = UiKit.texture(TABLET_ART)
	art.custom_minimum_size = Vector2(0, 130)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.modulate = Color(1, 1, 1, 0.85)
	left.add_child(art)
	left.add_child(UiKit.label(GameState.run.loadout.weapon.capitalize(), 26))
	_tablet = WeaponTabletView.new()
	_tablet.setup(ContentDB.data, GameState.run.loadout)
	_tablet.cell_clicked.connect(_on_cell)
	_tablet.rotate_requested.connect(_rotate)
	left.add_child(_tablet)
	_message = UiKit.paragraph(HINT, 18, Palette.FOG)
	left.add_child(_message)
	var lower := HBoxContainer.new()
	lower.add_theme_constant_override("separation", 40)
	left.add_child(lower)
	var armor_box := VBoxContainer.new()
	armor_box.add_child(UiKit.label("Armor sockets", 24, Palette.BRASS_LIGHT))
	_armor = VBoxContainer.new()
	armor_box.add_child(_armor)
	lower.add_child(armor_box)
	var deck_box := VBoxContainer.new()
	deck_box.add_child(UiKit.label("Fight deck", 24, Palette.BRASS_LIGHT))
	_deck = UiKit.paragraph("", 16, Palette.PARCHMENT)
	_deck.custom_minimum_size = Vector2(380, 0)
	deck_box.add_child(_deck)
	lower.add_child(deck_box)
	return left


func _build_right() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(470, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 10)
	scroll.add_child(v)
	v.add_child(UiKit.label("Spare modules", 24, Palette.BRASS_LIGHT))
	_spares = VBoxContainer.new()
	v.add_child(_spares)
	return panel


func _refresh() -> void:
	_tablet.set_ghost(_held, _rot)
	_tablet.refresh()
	_refresh_spares()
	_refresh_armor()
	_refresh_deck()


func _refresh_spares() -> void:
	for c: Node in _spares.get_children():
		c.queue_free()
	var spare := GameState.run.loadout.spare_modules()
	if spare.is_empty():
		_spares.add_child(UiKit.paragraph("No spare modules. New modules will come from the shop, the workshop and special contracts (next phases).", 15, Palette.INK_MUTED))
	for id: StringName in spare:
		var m := ContentDB.data.module(id)
		var row := HBoxContainer.new()
		row.add_child(_module_picture(m))
		var b := UiKit.button("%s  [%s · %s cell]\n%s" % [m.name, m.section, m.cell, m.effect], 15)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(360, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.tooltip_text = m.effect
		b.add_theme_color_override("font_color", Palette.BRASS_LIGHT if id == _held else Palette.PARCHMENT)
		b.pressed.connect(_hold.bind(id))
		row.add_child(b)
		_spares.add_child(row)


func _refresh_armor() -> void:
	for c: Node in _armor.get_children():
		c.queue_free()
	var l := GameState.run.loadout
	for a: GearDefs.ArmorDef in ContentDB.data.armor:
		for i: int in a.sockets:
			var row := HBoxContainer.new()
			row.add_child(Icons.rect("ARMOR", a.id, 34))
			row.add_child(UiKit.label("%s:" % a.name, 18))
			var pick := OptionButton.new()
			pick.custom_minimum_size = Vector2(320, 36)
			var current := ArmorRules.mechanism_at(l, a.id, i)
			var choices: Array[StringName] = [&""]
			if current != &"":
				choices.append(current)
			for m: StringName in l.spare_mechanisms():
				if not choices.has(m):
					choices.append(m)
			for m: StringName in choices:
				var mech := ContentDB.data.mechanism(m)
				pick.add_item("— empty —" if m == &"" else "%s (%s)" % [mech.name, mech.effect])
			pick.select(choices.find(current))
			pick.item_selected.connect(func(idx: int) -> void: _message.text = GameState.set_socket(a.id, i, choices[idx]))
			row.add_child(pick)
			_armor.add_child(row)


## The module's art (its exact cell shape) or, without art, a drawn outline of the shape.
func _module_picture(m: ModuleDef) -> Control:
	var tex := UiKit.texture(m.art_path())
	if tex == null:
		return ShapeIcon.new().setup(ContentDB.data.shapes[m.shape].cells, m.cell)
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(76, 64)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _refresh_deck() -> void:
	var b := DeckBuilder.build(GameState.run.loadout, ContentDB.data)
	var counts := {}
	var order: Array[String] = []
	for i: int in b.deck.size():
		var key := "%s|%s" % [b.deck[i], b.origins[i]]
		if not counts.has(key):
			order.append(key)
		counts[key] = int(counts.get(key, 0)) + 1
	var lines: PackedStringArray = []
	for key: String in order:
		var parts := key.split("|")
		lines.append("%d × %s  — %s" % [counts[key], ContentDB.data.card(StringName(parts[0])).name, parts[1]])
	lines.append("\nCards: %d · Ammo: %d" % [b.deck.size(), b.max_ammo])
	for k: StringName in b.mods:
		if k != &"max_ammo":
			lines.append("%s +%d" % [String(k).capitalize(), b.mods[k]])
	for link: String in b.links:
		lines.append("Link: %s" % link)
	_deck.text = "\n".join(lines)


func _hold(id: StringName) -> void:
	_held = id if _held != id else &""
	_message.text = _holding_text() if _held != &"" else HINT
	_refresh()


## What installing the held module would change, so the player sees the deck effect before placing it.
func _holding_text() -> String:
	var m := ContentDB.data.module(_held)
	var gains: PackedStringArray = []
	for c: StringName in m.cards:
		gains.append("+%s" % ContentDB.data.card(c).name)
	for k: StringName in m.mods:
		gains.append("%s +%d" % [String(k).capitalize(), m.mods[k]])
	var change := ", ".join(gains) if not gains.is_empty() else m.effect
	return "Holding %s → %s. Green outlines show where it fits; right click / R rotates, Esc drops it." % [m.name, change]


func _rotate() -> void:
	_rot = (_rot + 1) % 4
	_tablet.set_ghost(_held, _rot)


func _on_cell(section: StringName, cell: Vector2i) -> void:
	if _held != &"":
		var problem := GameState.equip_module(_held, section, cell, _rot)
		_message.text = problem
		if problem == "":
			_held = &""
			_refresh()
		return
	var index := WeaponGridRules.placement_at(GameState.run.loadout, ContentDB.data, section, cell)
	if index >= 0:
		_rot = GameState.run.loadout.placements[index].rot
		_held = GameState.unequip_module(index)
		_message.text = "Picked up — click a cell to install it again."
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_R:
		_rotate()
	elif event.is_action_pressed("ui_cancel"):
		_held = &""
		_message.text = HINT
		_refresh()
