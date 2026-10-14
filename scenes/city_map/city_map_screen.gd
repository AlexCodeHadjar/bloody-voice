extends Control
## City map screen (vertical-slice shell): map + district card + calendar bar.
## Talks to the game only through GameState commands and EventBus signals.

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const DISTRICT := "res://scenes/district_map/district_map_screen.tscn"

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
	_map_view.set_locked(_locked_districts())
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
	_map_view.district_clicked.connect(_on_clicked)
	_map_view.zoomed_in.connect(_to_district)  # the wheel back the way it came
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
	# no equipment or «back» buttons (owner 2026-10-14): a click on the district or the wheel towards you goes there
	var menu := Button.new()
	menu.icon = Icons.texture("UI", &"menu")
	menu.expand_icon = true
	menu.custom_minimum_size = Vector2(62, 56)
	menu.add_theme_constant_override("icon_max_width", 44)
	menu.tooltip_text = Loc.t("ui.city.menu")
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
		_panel.show_district(d, GameState.run.city.state_of(district), district == GameState.run.hero_district,
			not GameState.is_open(district))


func _locked_districts() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in ContentDB.data.districts:
		if not GameState.is_open(id):
			out.append(id)
	return out


## An open district: the hunter goes there and the view goes down into it at once (owner 2026-10-14).
func _on_clicked(district: StringName) -> void:
	if GameState.is_open(district):
		GameState.move_hero(district)
		_to_district()
	else:
		UiKit.sound(&"ui.error")


func _on_hovered(district: StringName) -> void:
	_show(district if district != &"" else GameState.run.hero_district)


func _on_hero_moved(district: StringName) -> void:
	_map_view.set_hero_district(district)
	_show(district)
	GameState.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and _markup_key(event):
		return
	if event.is_action_pressed("ui_cancel"):
		GameState.save_game()
		SettingsPanel.open(self, true)


## F3 toggles the districts' borders editor (RegionMarkup); in it Ctrl+S checks and saves them. True when handled.
func _markup_key(event: InputEvent) -> bool:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return false
	if k.keycode == KEY_F3:
		if _map_view.markup == null:
			_map_view.markup = RegionMarkup.new(ContentDB.data.map_regions)
		_map_view.markup.on = not _map_view.markup.on
		_map_view.markup.clear()
		_map_view.markup_text = Loc.t("ui.dev.region_help")
		_map_view.queue_redraw()
		return true
	if k.keycode == KEY_S and k.ctrl_pressed and _map_view.markup != null and _map_view.markup.on:
		_map_view.markup_text = _map_view.markup.save(ContentDB.data)
		_map_view.queue_redraw()
		return true
	return false


## Back to the close-up map of the hero's district (hunts and rest happen there now, GDD 20).
func _to_district() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(DISTRICT)


func _on_day_changed(_day: int) -> void:
	_refresh_bar()
	if CalendarRules.days_until_rent(GameState.run.day, ContentDB.data.balance) == 1:
		Tutorial.trigger(&"rent_tomorrow")


func _to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU)
