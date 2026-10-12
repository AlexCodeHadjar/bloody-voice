class_name ShopTable
extends Control
## The Rag-and-Bone shop (GDD 11.1): the dealer's wooden table with this week's cards — ready modules, blueprints,
## consumables for the bag, resource lots — each with its price and «Купить»; on the right the hunter sells
## trophies, resources and blood samples. Never sells into debt. Full-screen overlay.

signal closed

const TABLE := "res://art/ui/SHOP__table.webp"
const DEALER := "res://art/ui/NPC__portrait__junk_dealer.webp"
const CARD := Vector2(210, 300)

var _rows: VBoxContainer
var _sell: VBoxContainer
var _message: Label
var _money: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # fill the screen, not keep the 0×0 size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := TextureRect.new()
	bg.texture = UiKit.texture(TABLE)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)
	root.add_child(_build_head())
	_message = UiKit.paragraph("", 17, Palette.FOG)
	root.add_child(_message)
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 18)
	root.add_child(main)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 12)
	scroll.add_child(_rows)
	main.add_child(_build_sell())
	EventBus.stock_changed.connect(_refresh)
	EventBus.money_changed.connect(func(_m: int) -> void: _refresh())
	_refresh()
	UiKit.sound(&"ui.open")


func _build_head() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	head.add_child(UiKit.picture(UiKit.texture(DEALER), Vector2(90, 90)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiKit.label(Loc.t("ui.shop.title"), 34, Palette.BRASS_LIGHT))
	v.add_child(UiKit.label(Loc.t("ui.shop.refresh"), 16, Palette.FOG))
	var off := roundi(ProgressRules.discount(GameState.run, ContentDB.data) * 100)
	if off > 0:
		v.add_child(UiKit.label(Loc.t("ui.shop.discount", {"n": off}), 16, Palette.BRASS_LIGHT))
	head.add_child(v)
	_money = UiKit.label("", 24, Palette.BRASS_LIGHT)
	head.add_child(_money)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(48, 48)
	close.pressed.connect(close_shop)
	head.add_child(close)
	return head


func _build_sell() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Palette.PANEL, Palette.BRASS))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_sell = VBoxContainer.new()
	_sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell.add_theme_constant_override("separation", 6)
	scroll.add_child(_sell)
	return panel


func _refresh() -> void:
	var run := GameState.run
	_money.text = Loc.t("ui.shop.money", {"n": run.money})
	_money.add_theme_color_override("font_color", Palette.ALARM if run.money < 0 else Palette.BRASS_LIGHT)
	for child: Node in _rows.get_children():
		child.queue_free()
	for kind: StringName in ShopDefs.KINDS:
		var items := run.shop.items.filter(func(x: ShopState.Item) -> bool: return x.kind == kind)
		if items.is_empty():
			continue
		_rows.add_child(UiKit.label(Loc.t("ui.shop.kind.%s" % kind), 22, Palette.BRASS_LIGHT))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 14)
		row.add_theme_constant_override("v_separation", 14)
		for x: Variant in items:
			row.add_child(_card(x as ShopState.Item))
		_rows.add_child(row)
	var bag := PackedStringArray(run.bag.map(func(c: StringName) -> String: return ContentDB.data.card(c).name))
	_rows.add_child(UiKit.label(Loc.t("ui.shop.bag", {"n": run.bag.size(), "of": ContentDB.data.balance.shop.bag_size,
		"list": ", ".join(bag) if not bag.is_empty() else "—"}), 18, Palette.PARCHMENT))
	_refresh_sell()


func _card(x: ShopState.Item) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.12, 0.09, 0.07, 0.95), Palette.BRASS))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	v.add_child(UiKit.picture(ShopKit.picture(x), Vector2(0, 110)))
	var title := UiKit.paragraph(ShopKit.title(x), 18, Palette.BRASS_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var about := UiKit.paragraph(ShopKit.about(x), 14, Palette.FOG)
	about.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(about)
	var buy := Icons.button("RESOURCE", &"money", Loc.t("ui.shop.buy", {"n": ShopRules.price(GameState.run, ContentDB.data, x)}), 18)
	buy.custom_minimum_size = Vector2(0, 44)
	var problem := ShopRules.can_buy(GameState.run, ContentDB.data, x.uid)
	buy.disabled = problem != ""
	buy.tooltip_text = problem
	if x.sold:
		buy.text = Loc.t("ui.shop.sold")
		panel.modulate = Color(1, 1, 1, 0.5)
	buy.pressed.connect(_buy.bind(x.uid))
	v.add_child(buy)
	return panel


func _refresh_sell() -> void:
	for child: Node in _sell.get_children():
		child.queue_free()
	var ws := GameState.run.workshop
	_sell.add_child(UiKit.label(Loc.t("ui.shop.sell_title"), 24, Palette.BRASS_LIGHT))
	var ids: Array[StringName] = []
	for t: StringName in ws.trophies:
		ids.append(t)
	for r: StringName in ContentDB.data.balance.workshop.resources:
		if ws.amount(r) > 0:
			ids.append(r)
	if ids.is_empty() and ws.samples.is_empty() and ws.pure_samples.is_empty():
		_sell.add_child(UiKit.paragraph(Loc.t("ui.shop.nothing_to_sell"), 16, Palette.INK_MUTED))
	for id: StringName in ids:
		var price := ShopKit.sell_price(id)
		var b := Icons.button("RESOURCE", WorkshopKit.stock_icon(id), Loc.t("ui.shop.sell_row", {"name": WorkshopKit.stock_name(id),
			"have": ws.amount(id), "n": price}), 16)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 46)
		b.pressed.connect(_sell_one.bind(id))
		_sell.add_child(b)
	for pure: bool in [false, true]:  # blood samples (GDD 4.4): a pure one fetches more
		var pool: Dictionary[StringName, int] = ws.pure_samples if pure else ws.samples
		for c: StringName in pool:
			var b := Icons.button("STAT", &"voice", Loc.t("ui.shop.sell_row", {"name": WorkshopKit.sample_name(c, pure),
				"have": pool[c], "n": ShopRules.sample_price(ContentDB.data, c, pure)}), 16)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.custom_minimum_size = Vector2(0, 46)
			b.pressed.connect(_sell_sample.bind(c, pure))
			_sell.add_child(b)


func _buy(uid: int) -> void:
	var problem := GameState.buy_item(uid)
	_message.text = problem
	UiKit.sound(&"ui.error" if problem != "" else &"money.coins")


func _sell_one(id: StringName) -> void:
	var paid := GameState.sell_stock(id)
	if paid > 0:
		_message.text = Loc.t("ui.shop.sold_line", {"name": WorkshopKit.stock_name(id), "n": paid})
		UiKit.sound(&"money.coins")


func _sell_sample(creature: StringName, pure: bool) -> void:
	var paid := GameState.sell_sample(creature, pure)
	if paid > 0:
		_message.text = Loc.t("ui.shop.sold_line", {"name": WorkshopKit.sample_name(creature, pure), "n": paid})
		UiKit.sound(&"money.coins")


func close_shop() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_shop()
