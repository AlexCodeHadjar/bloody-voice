extends Control
## City map screen (vertical-slice shell): map + district card + calendar bar.
## Talks to the game only through GameState commands and EventBus signals.

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const COIN := "res://art/ui/icons/RESOURCE__money.webp"

var _map_view: MapView
var _panel: DistrictPanel
var _day_label: Label
var _money_label: Label


func _ready() -> void:
	theme = UiKit.theme()
	if not GameState.has_run():
		GameState.new_game()
	_build()
	EventBus.hero_moved.connect(_on_hero_moved)
	EventBus.day_changed.connect(func(_d: int) -> void: _refresh_bar())
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
	_day_label = UiKit.label("", 22)
	row.add_child(_day_label)
	var coin := TextureRect.new()
	coin.texture = UiKit.texture(COIN)
	coin.custom_minimum_size = Vector2(30, 30)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(coin)
	_money_label = UiKit.label("", 22, Palette.BRASS_LIGHT)
	row.add_child(_money_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var end_day := UiKit.button("Rest (end day)", 18)
	end_day.custom_minimum_size = Vector2(200, 40)
	end_day.pressed.connect(GameState.end_day)
	row.add_child(end_day)
	var menu := UiKit.button("Menu", 18)
	menu.custom_minimum_size = Vector2(120, 40)
	menu.pressed.connect(_to_menu)
	row.add_child(menu)
	return bar


func _refresh_bar() -> void:
	var run := GameState.run
	var b := ContentDB.data.balance
	var rent_in := CalendarRules.days_until_rent(run.day, b)
	_day_label.text = "Day %d · %s · Week %d    Rent %s" % [
		run.day, CalendarRules.weekday_name(run.day, b), CalendarRules.week(run.day, b),
		"due today" if rent_in == 0 else "in %d d" % rent_in]
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
		_to_menu()


func _to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU)
