class_name DistrictBar
extends PanelContainer
## The top bar of the district screen: the day and rent, money, HP and Sanity, the Voice, the district state,
## resources; on the right icon buttons (owner 2026-10-14) — the hunter, the bestiary, the notebook of rumors with the
## count of new cards (GDD 8.4), the bag, the menu. Refreshes itself on the run's signals; buttons report by id.

signal pressed(id: StringName)

var _day_label: Label
var _money_label: Label
var _health_label: Label
var _voice_box: HBoxContainer  ## the Voice and its stage (GDD 4.2), hidden while silent
var _state_box: HBoxContainer  ## the district state and its days left (GDD 14), hidden when normal
var _stock_row: HBoxContainer
var _notebook: Button
var _badge: Label  ## new rumor cards on the notebook button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	row.add_child(Icons.rect("ACTION", &"day", 34))
	_day_label = UiKit.label("", 22)
	TutorialAnchors.register(&"day_bar", _day_label)
	row.add_child(_day_label)
	row.add_child(Icons.rect("RESOURCE", &"money", 34))
	_money_label = UiKit.label("", 22, Palette.BRASS_LIGHT)
	_money_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_money_label)
	row.add_child(Icons.rect("STAT", &"hp", 30))
	_health_label = UiKit.label("", 20)  # HP and Sanity carried between fights (GDD 4)
	row.add_child(_health_label)
	_voice_box = Icons.with_text("STAT", &"voice", "", 30, 20)
	_voice_box.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_voice_box)
	_state_box = Icons.with_text("STATE", &"fog_breach", "", 30, 20, Palette.ALARM)
	_state_box.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_state_box)
	_stock_row = HBoxContainer.new()  # resources (GDD 6.1)
	_stock_row.add_theme_constant_override("separation", 10)
	row.add_child(_stock_row)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_add_buttons(row)
	EventBus.money_changed.connect(func(_m: int) -> void: refresh())
	EventBus.progress_changed.connect(refresh)
	EventBus.day_changed.connect(func(_d: int) -> void: refresh())
	EventBus.district_state_changed.connect(func(_k: StringName, _o: StringName, _n: StringName) -> void: refresh())
	EventBus.stock_changed.connect(_refresh_stock)
	EventBus.rumors_changed.connect(_refresh_badge)
	refresh()
	_refresh_stock()
	_refresh_badge()


## The screen's own place for where the notebook sits (rumor cards fly there).
func notebook_center() -> Vector2:
	return _notebook.get_global_rect().get_center()


# no camera or city-map buttons (owner 2026-10-14): Space / double-click the hunter, the wheel
func _add_buttons(row: HBoxContainer) -> void:
	row.add_child(_button("PLACE", &"hunter", "ui.progress.button", &"hunter"))
	row.add_child(_button("UI", &"bestiary", "ui.bestiary.button", &"bestiary"))
	_notebook = _button("UI", &"journal", "ui.rumor.notebook", &"notebook")
	_badge = UiKit.label("", 16, Palette.PARCHMENT)
	_badge.add_theme_stylebox_override("normal", UiKit.panel_box(Palette.ALARM, Palette.ALARM))
	_badge.position = Vector2(40, -4)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notebook.add_child(_badge)
	TutorialAnchors.register(&"notebook_button", _notebook)
	row.add_child(_notebook)
	row.add_child(_button("UI", &"bag", "ui.city.equipment", &"bag"))
	row.add_child(_button("UI", &"menu", "ui.city.menu", &"menu"))


## A square icon button with its name as a tooltip (the bag falls back to the equipment icon until its art comes).
func _button(set_code: String, icon: StringName, key: String, id: StringName) -> Button:
	var b := Button.new()
	var tex := Icons.texture(set_code, icon)
	b.icon = tex if tex != null else Icons.texture("DIRECTION", &"equipment")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(62, 56)
	b.add_theme_constant_override("icon_max_width", 44)
	b.tooltip_text = Loc.t(key)
	b.pressed.connect(func() -> void: pressed.emit(id))
	return b


func refresh() -> void:
	var run := GameState.run
	var data := ContentDB.data
	var b := data.balance
	var rent_in := CalendarRules.days_until_rent(run.day, b)
	_day_label.text = Loc.t("ui.city.day_bar", {"day": run.day, "weekday": CalendarRules.weekday_name(run.day, b),
		"week": CalendarRules.week(run.day, b),
		"rent": Loc.t("ui.city.rent_today") if rent_in == 0 else Loc.t("ui.city.rent_in", {"n": rent_in})})
	_money_label.text = str(run.money)
	_health_label.text = Loc.t("ui.health.bar", {"hp": HealthRules.hp(run, data), "max": HealthRules.max_hp(run, data),
		"sanity": HealthRules.sanity(run, data), "max_sanity": HealthRules.max_sanity(run, data)})
	var low := HealthRules.hp(run, data) * 3 < HealthRules.max_hp(run, data)
	_health_label.add_theme_color_override("font_color", Palette.ALARM if low else Palette.PARCHMENT)
	_money_label.add_theme_color_override("font_color", Palette.ALARM if run.money < 0 else Palette.BRASS_LIGHT)
	_money_label.tooltip_text = "" if run.money >= 0 else Loc.t("ui.district.debt", {"n": run.debt_strikes, "of": b.debt_strikes})
	var stage := VoiceRules.stage(run, data)
	_voice_box.visible = run.voice > 0
	(_voice_box.get_child(1) as Label).text = Loc.t("ui.voice.now", {"n": run.voice, "stage": Loc.t("ui.voice.stage.%d" % stage)})
	_voice_box.tooltip_text = Loc.t("ui.voice.effect.%d" % stage)
	_refresh_state(run, data)


## The district state on the bar: icon, name, days left, what it changes.
func _refresh_state(run: RunState, data: ContentData) -> void:
	var state := run.city.state_of(run.hero_district)
	var days := (run.city.places[run.hero_district] as PlaceState).days_left if run.city.places.has(run.hero_district) else 0
	_state_box.visible = state != &"normal"
	(_state_box.get_child(0) as TextureRect).texture = Icons.texture("STATE", state)
	(_state_box.get_child(1) as Label).text = Loc.t("ui.event.badge", {"state": Loc.t("state.%s.name" % state), "n": days})
	_state_box.tooltip_text = NewsPanel.effects_text(EventRules.state_def(run, data), data)


## Resources on the bar, rebuilt only when the stock changes.
func _refresh_stock() -> void:
	var run := GameState.run
	for child: Node in _stock_row.get_children():
		child.queue_free()
	for id: StringName in ContentDB.data.balance.workshop.resources:
		var cell := Icons.with_text("RESOURCE", id, str(run.workshop.amount(id)), 28, 18)
		cell.tooltip_text = WorkshopKit.stock_name(id)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		_stock_row.add_child(cell)


func _refresh_badge() -> void:
	var n := GameState.run.rumors.fresh_count()
	_badge.text = " %d " % n
	_badge.visible = n > 0
