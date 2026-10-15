extends Control
## District screen (GDD 20): the Grey Chapels up close. The hunter walks the streets by click, the map is dragged with
## the held left button; places open a card with what can be done there. Talks to the game only through GameState
## commands and EventBus signals; walking itself is presentation and costs no time (GDD 20.4).

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"
const COMBAT := "res://scenes/combat/combat_screen.tscn"
const EQUIPMENT := "res://scenes/equipment/equipment_screen.tscn"
const WORKSHOP := "res://scenes/workshop/workshop_screen.tscn"
const CITY_MAP := "res://scenes/city_map/city_map_screen.tscn"
const STREET_PICK := 110.0  ## art px: a click this close to a street sends the hero there
const SOUND_CHECK := 0.3  ## seconds between checks of the zone under the camera

var _map: DistrictMapDef
var _view: DistrictView
var _hero: HeroWalker
var _life: LifeLayer
var _markup: MapMarkupUi
var _card: LandmarkCard
var _tracker: ContractTracker
var _panels := DistrictPanels.new()  ## the board, tablets, notebook, shop, shift result over the map
var _bar: DistrictBar
var _tip: PanelContainer
var _tip_label: Label
var _weather: DistrictWeather
var _spot: DistrictMapRules.Spot  ## where the hero stands or walks to
var _target: DistrictMapDef.LandmarkDef = null  ## the card opens when the hero gets there
var _target_mark := 0  ## the lair's sheet opens when the hero gets to this lair
var _sound_clock := 0.0


func _ready() -> void:
	theme = UiKit.theme()
	UiKit.screen_sound(&"district")
	if not GameState.has_run():
		GameState.new_game()
	GameState.leave_workshop()  # back from the workshop: a started workshop day ends here
	_map = ContentDB.data.district_map(GameState.run.hero_district)
	if _map == null:  # the hero is in a district without a close-up map yet: the city map is the way out
		get_tree().change_scene_to_file.call_deferred(CITY_MAP)
		return
	_build()
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.district_state_changed.connect(func(_k: StringName, _o: StringName, _n: StringName) -> void: _refresh_weather())
	_refresh_weather()
	_panels.show_news.call_deferred()  # the morning leaflet of a district event (GDD 15)
	_place_hero()
	_view.center_on.call_deferred(_hero.position)
	Tutorial.trigger.call_deferred(&"district_open")


func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	_bar = DistrictBar.new()
	_bar.pressed.connect(_on_bar)
	root.add_child(_bar)
	_view = DistrictView.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_view)
	_view.setup(_map)
	TutorialAnchors.register(&"district_map", _view)
	_life = LifeLayer.new()  # residents (map-life-people.md), below the hero
	_life.setup(_map, ContentDB.data)
	_view.add_layer(_life)
	_hero = HeroWalker.new()
	var lairs := MarkLayer.new()  # the lairs rumors led to (GDD 8.4), below the hero
	lairs.setup(_map)
	lairs.mark_clicked.connect(_go_to_mark)
	_view.add_layer(lairs)
	_view.add_layer(_hero)
	_life.hero = _hero
	_view.hero = _hero
	_build_overlays()
	_view.landmark_hovered.connect(_on_hovered)
	_view.landmark_clicked.connect(_on_landmark_clicked)
	_view.street_clicked.connect(_on_street_clicked)
	_view.hero_double_clicked.connect(_to_hero)
	_view.city_requested.connect(_to_city)  # the wheel on past the farthest zoom (owner 2026-10-14)
	_hero.arrived.connect(_on_arrived)
	_hero.stepped.connect(func() -> void: UiKit.sound(&"world.step"))
	_build_card()
	_panels.host = self
	_panels.fight_started.connect(func() -> void: get_tree().change_scene_to_file(COMBAT))
	add_child(_panels)
	var ears := Overhearing.new()  # rumors overheard on the way fly into the notebook (GDD 8.4)
	ears.setup(_map, _hero, _bar, _panels.is_open)
	add_child(ears)
	_build_tracker()
	_build_tip()
	_markup = MapMarkupUi.new()  # F3 markup tools (debug builds)
	_markup.setup(_view)
	_markup.life_changed.connect(func() -> void: _life.rebuild(_map, ContentDB.data))
	_view.markup_ui = _markup
	add_child(_markup)


## The veil and hover outline over the map, and the district state's look (fog, chalk, lanterns, GDD 14.6).
func _build_overlays() -> void:
	var overlay := DistrictOverlay.new()
	overlay.setup(_map)
	_view.add_overlay(overlay)
	_weather = DistrictWeather.new()
	_view.add_child(_weather)


## The top bar's icon buttons.
func _on_bar(id: StringName) -> void:
	match id:
		&"hunter":
			_panels.open(HeroPanel.new())
		&"bestiary":
			_panels.open(BestiaryPanel.new())
		&"notebook":
			_panels.open_notebook()
		&"bag":
			_to_equipment()
		&"menu":
			_to_menu()


## The district state's look over the map (fog, chalk, lanterns, GDD 14.6).
func _refresh_weather() -> void:
	_weather.show_state(EventRules.state_def(GameState.run, ContentDB.data))


func _build_card() -> void:
	_card = LandmarkCard.new()
	_card.set_anchors_preset(Control.PRESET_TOP_LEFT)  # the contracts list holds the right edge
	_card.position = Vector2(16.0, 90.0)
	_card.action_chosen.connect(_on_action)
	add_child(_card)


## Taken contracts as a list at the right edge (GDD 7.1; owner 2026-10-14); the place card opens at the left.
func _build_tracker() -> void:
	_tracker = ContractTracker.new()
	_tracker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tracker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tracker.offset_left = -ContractTracker.WIDTH - 16.0  # offsets, not position: pressed to the right edge
	_tracker.offset_right = -16.0
	_tracker.offset_top = 84.0
	_tracker.zone_requested.connect(_on_zone_requested)
	_tracker.contract_opened.connect(_panels.open_contract)
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
	_target_mark = 0
	_walk_to(DistrictMapRules.spot_at_node(_map, lm.node))


func _on_street_clicked(p: Vector2) -> void:
	var inside := Geometry2D.is_point_in_polygon(p, _map.contour)  # a house counts as its nearest street (owner 2026-10-14)
	var spot := DistrictMapRules.nearest_spot(_map, p, INF if inside else STREET_PICK)
	if spot == null:
		return
	_target = null
	_target_mark = 0
	_walk_to(spot)


func _walk_to(to: DistrictMapRules.Spot) -> void:
	_card.close_card()
	var from := _current_spot()
	var route := DistrictMapRules.route(_map, from, to)
	_spot = to
	_hero.walk(route)
	ClickRipple.spawn(_view.world, to.point)  # a ring of light where the hunter is going (owner 2026-10-14)


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
	if _target_mark != 0:
		_panels.open_mark(_target_mark)
		_target_mark = 0
	if _target != null:
		_card.position.y = _tracker.position.y + _tracker.size.y + 14.0 if _tracker.visible else 90.0
		_card.show_landmark(_target, _zone_name(_target.zone))
		_target = null


func _on_day_changed(_day: int) -> void:
	_refresh_weather()
	_panels.show_news.call_deferred()  # after the panel of the day's action opens: the leaflet waits for it to close
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
			GameState.rest()
		&"workshop":
			GameState.save_game()
			get_tree().change_scene_to_file(WORKSHOP)
		_:
			_card.close_card()
			_panels.open_for(action)


## The hunter walks to the mark; its sheet opens there (GDD 8.4).
func _go_to_mark(uid: int) -> void:
	var m := GameState.run.rumors.find(uid)
	if m == null:
		return
	_target = null
	_target_mark = uid
	_walk_to(DistrictMapRules.spot_at_node(_map, m.node))


## The tracker's region icon: the zone where the creature was last seen glows and the view glides there.
func _on_zone_requested(zone: StringName) -> void:
	_view.center_on(_view.overlay.flash_zone(zone), true)
	UiKit.sound(&"paper.map")


func _unhandled_input(event: InputEvent) -> void:
	if _view == null or _panels.is_open():
		return
	if OS.is_debug_build() and _markup.key(event):  # F3 markup: F3, Ctrl+S, Esc in the chain or rename
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


func _to_hero() -> void:
	_view.center_on(_hero.position, true)


func _to_city() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(CITY_MAP)


func _to_equipment() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(EQUIPMENT)


func _to_menu() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(MAIN_MENU)
