extends Control
## Workshop «Ржавая Шестерня» (GDD 6, 23.1): blueprints on the left, the workbench in the middle, the hunter's stash on
## the right; resources and «Изготовлений сегодня» on top. The first craft or upgrade starts a workshop day (2 items);
## leaving ends it (the district screen calls GameState.leave_workshop). Salvage is free.

const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"
const EQUIPMENT := "res://scenes/equipment/equipment_screen.tscn"
const BACKGROUND := "res://art/ui/WORKSHOP__background.webp"

var _list: BlueprintList
var _bench: WorkbenchView
var _stash: VBoxContainer
var _stock: HBoxContainer
var _crafts: Label
var _message: Label
var _tier := 1  ## tier of the module copy on the workbench


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"equipment")
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.stock_changed.connect(_refresh)
	_refresh()
	Tutorial.trigger.call_deferred(&"workshop_open")


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = UiKit.texture(BACKGROUND)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	root.add_child(_build_top())
	_message = UiKit.paragraph("", 17, Palette.FOG)
	root.add_child(_message)
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	root.add_child(main)
	_list = BlueprintList.new()
	_list.custom_minimum_size = Vector2(560, 0)
	_list.picked.connect(_pick)
	main.add_child(_list)
	TutorialAnchors.register(&"workshop_list", _list)
	_bench = WorkbenchView.new()
	_bench.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bench.action.connect(_on_action)
	main.add_child(_bench)
	TutorialAnchors.register(&"workshop_bench", _bench)
	main.add_child(_build_stash())


func _build_top() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	row.add_child(UiKit.label(Loc.t("ui.workshop.title"), 30, Palette.BRASS_LIGHT))
	_stock = HBoxContainer.new()
	_stock.add_theme_constant_override("separation", 14)
	row.add_child(_stock)
	_crafts = UiKit.label("", 18, Palette.PARCHMENT)
	row.add_child(_crafts)
	TutorialAnchors.register(&"workshop_crafts", _crafts)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var gear := Icons.button("DIRECTION", &"equipment", Loc.t("ui.workshop.to_equipment"), 18)
	gear.custom_minimum_size = Vector2(0, 42)
	gear.pressed.connect(func() -> void: get_tree().change_scene_to_file(EQUIPMENT))
	row.add_child(gear)
	var back := UiKit.button(Loc.t("ui.workshop.back"), 18)
	back.custom_minimum_size = Vector2(200, 42)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(DISTRICT))
	row.add_child(back)
	return bar


func _build_stash() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_stash = VBoxContainer.new()
	_stash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stash.add_theme_constant_override("separation", 6)
	scroll.add_child(_stash)
	TutorialAnchors.register(&"workshop_stash", panel)
	return panel


func _refresh() -> void:
	var ws := GameState.run.workshop
	for child: Node in _stock.get_children():
		child.queue_free()
	for id: StringName in ContentDB.data.balance.workshop.resources:
		var cell := Icons.with_text("RESOURCE", id, str(ws.amount(id)), 32, 20)
		cell.tooltip_text = WorkshopKit.stock_name(id)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		_stock.add_child(cell)
	var left := WorkshopRules.crafts_left(GameState.run, ContentDB.data)
	var per_day := ContentDB.data.balance.workshop.crafts_per_day
	_crafts.text = Loc.t("ui.workshop.crafts_today", {"n": left, "of": per_day})
	if left < per_day:  # a workshop day is on: leaving ends it
		_crafts.text += Loc.t("ui.workshop.day_on")
	if WorkshopRules.is_locked(GameState.run):
		_crafts.text = Loc.t("ui.workshop.locked_today")
	_list.refresh()
	_bench.show_item(_list.selected, _tier)
	_refresh_stash()


func _refresh_stash() -> void:
	for child: Node in _stash.get_children():
		child.queue_free()
	var l := GameState.run.loadout
	_stash.add_child(UiKit.label(Loc.t("ui.workshop.stash"), 24, Palette.BRASS_LIGHT))
	var seen: Array[String] = []
	for id: StringName in l.owned_modules:  # one row per module kind and tier: every copy has its own tier
		for t: int in l.tiers_of(id):
			if not seen.has("%s#%d" % [id, t]):
				seen.append("%s#%d" % [id, t])
				var n := l.tiers_of(id).count(t)
				_stash.add_child(_stash_row(id, t, n, n - l.spare_tiers(id).count(t)))
	for id: StringName in l.owned_mechanisms:
		if not seen.has(String(id)):
			seen.append(String(id))
			var n := l.owned_mechanisms.count(id)
			_stash.add_child(_stash_row(id, 1, n, n - l.spare_mechanisms().count(id)))
	var trophies: PackedStringArray = []
	for t: StringName in GameState.run.workshop.trophies:
		trophies.append("%s ×%d" % [WorkshopKit.stock_name(t), GameState.run.workshop.trophies[t]])
	_stash.add_child(UiKit.label(Loc.t("ui.workshop.trophies"), 20, Palette.BRASS))
	_stash.add_child(UiKit.paragraph(", ".join(trophies) if not trophies.is_empty() else Loc.t("ui.combat.none"), 16, Palette.PARCHMENT))


func _stash_row(id: StringName, tier: int, owned: int, used: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 60)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = WorkshopKit.item_art(id)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 48)
	var marks := "  " + WorkshopKit.tier_text(tier) if ContentDB.data.module(id) != null else ""
	b.text = Loc.t("ui.workshop.stash_row", {"name": WorkshopKit.item_name(id) + marks, "n": owned, "used": used})
	b.pressed.connect(_pick.bind(id, tier))
	return b


## A blueprint shows its lowest owned copy (or tier I); a stash row shows that copy.
func _pick(item: StringName, tier: int = 0) -> void:
	var owned := GameState.run.loadout.tiers_of(item)
	_tier = tier if tier > 0 else (owned[0] if not owned.is_empty() else 1)
	_list.selected = item
	_message.text = ""
	_bench.show_item(item, _tier)
	_list.refresh()


func _on_action(kind: StringName, item: StringName, tier: int) -> void:
	var problem := ""
	match kind:
		&"craft":
			problem = GameState.craft_item(item)
		&"upgrade":
			problem = GameState.upgrade_module(item, tier)
		&"salvage":
			problem = GameState.salvage_item(item, tier)
	if problem != "":
		_message.text = problem
		UiKit.sound(&"ui.error")
		return
	UiKit.sound(&"gear.install" if kind != &"salvage" else &"money.coins")
	if kind == &"upgrade":
		_tier = tier + 1  # follow the upgraded copy
	_bench.show_item(item, _tier)
	_message.text = Loc.t("ui.workshop.done.%s" % kind, {"name": WorkshopKit.item_name(item)})
	if WorkshopRules.crafts_left(GameState.run, ContentDB.data) == 0 and kind != &"salvage":
		_message.text += " " + Loc.t("ui.workshop.day_full")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(DISTRICT)
