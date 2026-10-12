extends Control
## District screen (GDD 20): the Grey Chapels up close. The hunter walks the streets by click, the map is dragged with
## the held left button; places open a card with what can be done there. Talks to the game only through GameState
## commands and EventBus signals; walking itself is presentation and costs no time (GDD 20.4).

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const COMBAT := "res://scenes/combat/combat_screen.tscn"
const EQUIPMENT := "res://scenes/equipment/equipment_screen.tscn"
const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const STREET_PICK := 110.0  ## art px: a click this close to a street sends the hero there
const SOUND_CHECK := 0.3  ## seconds between checks of the zone under the camera

var _map: DistrictMapDef
var _view: DistrictView
var _hero: HeroWalker
var _life: LifeLayer
var _card: LandmarkCard
var _tracker: ContractTracker
var _overlay_open: Control = null  ## the contract board or a tablet over the map
var _tip: PanelContainer
var _tip_label: Label
var _day_label: Label
var _money_label: Label
var _spot: DistrictMapRules.Spot  ## where the hero stands or walks to
var _target: DistrictMapDef.LandmarkDef = null  ## the card opens when the hero gets there
var _sound_clock := 0.0


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"district")
	if not GameState.has_run():
		GameState.new_game()
	_map = ContentDB.data.district_map(GameState.run.hero_district)
	if _map == null:  # the hero is in a district without a close-up map yet: the city map is the way out
		get_tree().change_scene_to_file.call_deferred(CITY_MAP)
		return
	_build()
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.money_changed.connect(func(_m: int) -> void: _refresh_bar())
	_refresh_bar()
	_place_hero()
	_view.center_on.call_deferred(_hero.position)
	Tutorial.trigger.call_deferred(&"district_open")


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_bar())
	_view = DistrictView.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_view)
	_view.setup(_map)
	TutorialAnchors.register(&"district_map", _view)
	_life = LifeLayer.new()  # residents (map-life-people.md), below the hero
	_life.setup(_map, ContentDB.data)
	_view.add_layer(_life)
	_hero = HeroWalker.new()
	_view.add_layer(_hero)
	_life.hero = _hero
	_view.follow = _hero
	var overlay := DistrictOverlay.new()
	overlay.setup(_map)
	_view.add_overlay(overlay)
	_view.landmark_hovered.connect(_on_hovered)
	_view.landmark_clicked.connect(_on_landmark_clicked)
	_view.street_clicked.connect(_on_street_clicked)
	_view.hero_double_clicked.connect(_to_hero)
	_hero.arrived.connect(_on_arrived)
	_hero.stepped.connect(func() -> void: UiKit.sound(&"world.step"))
	_build_card()
	_build_tracker()
	_build_tip()


func _build_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
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
	var camera_buttons := HBoxContainer.new()
	camera_buttons.add_theme_constant_override("separation", 18)
	camera_buttons.add_child(_bar_button("PLACE", &"hunter", "ui.district.to_hero", _to_hero))
	camera_buttons.add_child(_bar_button("PLACE", &"home", "ui.district.to_home", _to_home))
	TutorialAnchors.register(&"camera_buttons", camera_buttons)
	row.add_child(camera_buttons)
	row.add_child(_bar_button("PLACE", &"city_map", "ui.district.city_map", _to_city))
	row.add_child(_bar_button("DIRECTION", &"equipment", "ui.city.equipment", _to_equipment))
	row.add_child(_bar_button("UI", &"menu", "ui.city.menu", _to_menu))
	return bar


func _bar_button(set_code: String, icon: StringName, key: String, action: Callable) -> Button:
	var b := Icons.button(set_code, icon, Loc.t(key), 18)
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(action)
	return b


func _build_card() -> void:
	_card = LandmarkCard.new()
	_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_card.position = Vector2(-LandmarkCard.WIDTH - 24.0, 90.0)
	_card.action_chosen.connect(_on_action)
	add_child(_card)


## Taken contracts in the top-right corner (GDD 7.1); the place card opens below them.
func _build_tracker() -> void:
	_tracker = ContractTracker.new()
	_tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tracker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tracker.position = Vector2(-ContractTracker.WIDTH - 24.0, 74.0)
	_tracker.zone_requested.connect(_on_zone_requested)
	_tracker.contract_opened.connect(_open_tablet)
	add_child(_tracker)
	TutorialAnchors.register(&"contract_tracker", _tracker)


func _build_tip() -> void:
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_label = UiKit.label("", 18)
	_tip.add_child(_tip_label)
	_tip.visible = false
	add_child(_tip)


func _refresh_bar() -> void:
	var run := GameState.run
	var b := ContentDB.data.balance
	var rent_in := CalendarRules.days_until_rent(run.day, b)
	_day_label.text = Loc.t("ui.city.day_bar", {"day": run.day, "weekday": CalendarRules.weekday_name(run.day, b),
		"week": CalendarRules.week(run.day, b),
		"rent": Loc.t("ui.city.rent_today") if rent_in == 0 else Loc.t("ui.city.rent_in", {"n": rent_in})})
	_money_label.text = str(run.money)


func _place_hero() -> void:
	var node := GameState.run.hero_node
	if not _map.nodes.has(node):
		node = _map.home
	_spot = DistrictMapRules.spot_at_node(_map, node)
	_hero.place(_spot.point)


func _process(delta: float) -> void:
	if _view == null:
		return
	if _tip.visible:
		_tip.position = get_local_mouse_position() + Vector2(22, 18)
	_sound_clock += delta
	if _sound_clock >= SOUND_CHECK:
		_sound_clock = 0.0
		UiKit.zone_sound(DistrictMapRules.ambience_at(_map, _view.camera_center()))


func _on_hovered(lm: DistrictMapDef.LandmarkDef) -> void:
	_tip.visible = lm != null
	if lm == null:
		return
	_tip_label.text = "%s\n%s" % [lm.name, Loc.t("ui.district.hint.%s" % lm.action)]
	_tip.reset_size()
	UiKit.sound(&"ui.hover")


func _on_landmark_clicked(lm: DistrictMapDef.LandmarkDef) -> void:
	_target = lm
	_walk_to(DistrictMapRules.spot_at_node(_map, lm.node))


func _on_street_clicked(p: Vector2) -> void:
	var spot := DistrictMapRules.nearest_spot(_map, p, STREET_PICK)
	if spot == null:
		return
	_target = null
	_walk_to(spot)


func _walk_to(to: DistrictMapRules.Spot) -> void:
	_card.close_card()
	_view.follow = _hero  # the camera may have been sent to a contract's zone
	var from := _current_spot()
	var route := DistrictMapRules.route(_map, from, to)
	_spot = to
	_hero.walk(route)


## Where the hero is right now: mid-walk it is a point on the street it is crossing.
func _current_spot() -> DistrictMapRules.Spot:
	if not _hero.is_walking():
		return _spot
	var near := DistrictMapRules.nearest_spot(_map, _hero.position, INF)
	return near if near != null else _spot


func _on_arrived() -> void:
	GameState.set_hero_node(DistrictMapRules.nearest_node(_map, _spot))
	GameState.save_game()
	Tutorial.action(&"hero_walked")
	if _target != null:
		_card.position.y = _tracker.position.y + _tracker.size.y + 14.0 if _tracker.visible else 90.0
		_card.show_landmark(_target, _zone_name(_target.zone))
		_target = null


func _on_day_changed(_day: int) -> void:
	_refresh_bar()
	if CalendarRules.days_until_rent(GameState.run.day, ContentDB.data.balance) == 1:
		Tutorial.trigger(&"rent_tomorrow")


func _zone_name(zone: StringName) -> String:
	for z: DistrictMapDef.ZoneDef in _map.zones:
		if z.id == zone:
			return z.name
	return ""


func _on_action(action: StringName) -> void:
	match action:
		&"rest":
			_card.close_card()
			GameState.end_day()
		&"equipment":
			_to_equipment()
		&"tavern":
			_card.close_card()
			_open_overlay(ContractBoard.new())
		&"hunt":
			GameState.save_game()
			GameState.start_hunt()
			get_tree().change_scene_to_file(COMBAT)


func _open_overlay(o: Control) -> void:
	if _overlay_open != null:
		return
	_overlay_open = o
	add_child(o)
	o.connect(&"closed", _on_overlay_closed)


func _open_tablet(list: Array[ContractsState.Contract], index: int) -> void:
	if _overlay_open != null:
		return
	var tablet := ContractTablet.new()
	_open_overlay(tablet)
	tablet.open_list(list, index)


func _on_overlay_closed() -> void:
	_overlay_open = null
	if not ContractRules.active(GameState.run.contracts).is_empty():
		Tutorial.trigger.call_deferred(&"contract_taken")


## The tracker's region icon: the zone where the creature was last seen glows and the view glides there
## (the camera stops following the hero until the hunter walks again).
func _on_zone_requested(zone: StringName) -> void:
	_view.follow = null
	_view.center_on(_view.overlay.flash_zone(zone), true)
	UiKit.sound(&"paper.map")


func _unhandled_input(event: InputEvent) -> void:
	if _view == null or _overlay_open != null:
		return
	if event.is_action_pressed("ui_cancel"):
		if _card.visible:
			_card.close_card()
		else:
			GameState.save_game()
			SettingsPanel.open(self, true)
	elif event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).keycode:
			KEY_SPACE:
				_to_hero()
			KEY_F3 when OS.is_debug_build():
				_view.overlay.toggle_debug()


func _to_hero() -> void:
	_view.follow = _hero
	_view.center_on(_hero.position, true)


func _to_home() -> void:
	_view.center_on(_map.node_pos(_map.home), true)


func _to_city() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(CITY_MAP)


func _to_equipment() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(EQUIPMENT)


func _to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU)
