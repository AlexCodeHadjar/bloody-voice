extends Control
## City map screen (vertical-slice shell): map + district card + calendar bar.
## Talks to the game only through GameState commands and EventBus signals.

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const COMBAT := "res://scenes/combat/combat_screen.tscn"
const EQUIPMENT := "res://scenes/equipment/equipment_screen.tscn"

var _map_view: MapView
var _panel: DistrictPanel
var _day_label: Label
var _money_label: Label


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"city")
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.hero_moved.connect(_on_hero_moved)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.money_changed.connect(func(_m: int) -> void: _refresh_bar())
	_refresh_bar()
	_map_view.set_hero_district(GameState.run.hero_district)
	_show(GameState.run.hero_district)


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_bar())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	_map_view = MapView.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_map_view)
	_map_view.setup(ContentDB.data.map_regions)
	_map_view.district_hovered.connect(_on_hovered)
	_map_view.district_clicked.connect(GameState.move_hero)
	_panel = DistrictPanel.new()
	body.add_child(_panel)


func _build_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	bar.add_child(row)
	row.add_child(Icons.rect("ACTION", &"day", 34))
	_day_label = UiKit.label("", 22)
	TutorialAnchors.register(&"day_bar", _day_label)
	row.add_child(_day_label)
	row.add_child(Icons.rect("RESOURCE", &"money", 34))
	_money_label = UiKit.label("", 22, Palette.BRASS_LIGHT)
	row.add_child(_money_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var gear := Icons.button("DIRECTION", &"equipment", Loc.t("ui.city.equipment"), 18)
	gear.custom_minimum_size = Vector2(190, 40)
	gear.pressed.connect(func() -> void: get_tree().change_scene_to_file(EQUIPMENT))
	row.add_child(gear)
	var hunt := Icons.button("ACTION", &"investigate", Loc.t("ui.city.hunt"), 18)
	hunt.custom_minimum_size = Vector2(250, 40)
	hunt.pressed.connect(_hunt)
	row.add_child(hunt)
	var end_day := Icons.button("ACTION", &"rest", Loc.t("ui.city.rest"), 18)
	end_day.custom_minimum_size = Vector2(225, 40)
	end_day.pressed.connect(GameState.end_day)
	row.add_child(end_day)
	var menu := Icons.button("UI", &"menu", Loc.t("ui.city.menu"), 18)
	menu.custom_minimum_size = Vector2(140, 40)
	menu.pressed.connect(_to_menu)
	row.add_child(menu)
	return bar


func _refresh_bar() -> void:
	var run := GameState.run
	var b := ContentDB.data.balance
	var rent_in := CalendarRules.days_until_rent(run.day, b)
	_day_label.text = Loc.t("ui.city.day_bar", {"day": run.day, "weekday": CalendarRules.weekday_name(run.day, b),
		"week": CalendarRules.week(run.day, b),
		"rent": Loc.t("ui.city.rent_today") if rent_in == 0 else Loc.t("ui.city.rent_in", {"n": rent_in})})
	_money_label.text = str(run.money)


func _show(district: StringName) -> void:
	var d := ContentDB.data.district(district)
	if d != null:
		_panel.show_district(d, GameState.run.city.state_of(district), district == GameState.run.hero_district)


func _on_hovered(district: StringName) -> void:
	_show(district if district != &"" else GameState.run.hero_district)


func _on_hero_moved(district: StringName) -> void:
	_map_view.set_hero_district(district)
	_show(district)
	GameState.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameState.save_game()
		SettingsPanel.open(self, true)


func _hunt() -> void:
	GameState.start_hunt()
	get_tree().change_scene_to_file(COMBAT)


func _on_day_changed(_day: int) -> void:
	_refresh_bar()
	if CalendarRules.days_until_rent(GameState.run.day, ContentDB.data.balance) == 1:
		Tutorial.trigger(&"rent_tomorrow")


func _to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU)
