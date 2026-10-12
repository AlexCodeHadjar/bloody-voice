class_name WorkbenchView
extends PanelContainer
## The workbench (GDD 23.1 zones 5–7, 9): the selected item large — picture, section and cell, tier, what it does,
## the cards it puts into the deck — with «Изготовить», the upgrade path I » II » III with the next tier's effect and
## cost («Улучшить»), and «Разобрать» with what comes back. Buttons only report; the screen calls GameState.

signal action(kind: StringName, item: StringName, tier: int)  ## kind: craft / upgrade / salvage; tier of the copy

const SHEET := "res://art/ui/WORKSHOP__blueprint_sheet.webp"
const CARD_SCALE := 0.7

var _item: StringName = &""
var _tier := 1  ## the copy shown (modules); blueprints show tier I
var _box: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.07, 0.06, 0.05, 0.9), Palette.BRASS))
	var sheet := TextureRect.new()
	sheet.texture = UiKit.texture(SHEET)
	sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.stretch_mode = TextureRect.STRETCH_SCALE
	sheet.modulate = Color(1, 1, 1, 0.18)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sheet)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_box)
	show_item(&"")


func show_item(item: StringName, tier: int = 1) -> void:
	_item = item
	_tier = tier
	for child: Node in _box.get_children():
		child.queue_free()
	if item == &"":
		_box.add_child(UiKit.paragraph(Loc.t("ui.workshop.pick"), 20, Palette.FOG))
		return
	var data := ContentDB.data
	var m := data.module(item)
	var shown := _tier if m != null else 1
	_head(item, m, shown)
	var cards: Array[StringName] = []
	if m != null:
		cards.append_array(m.cards_at(shown))
		cards.append_array(m.capture_cards_at(shown))
	else:
		cards.append_array(data.mechanism(item).cards)
	_box.add_child(_cards(cards))
	_craft_part(item)
	if m != null:
		_upgrade_part(m, shown)
	_salvage_part(item)


func _head(item: StringName, m: ModuleDef, tier: int) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.add_child(UiKit.picture(WorkshopKit.item_art(item), Vector2(200, 200)))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(UiKit.label(WorkshopKit.item_name(item), 32, Palette.BRASS_LIGHT))
	var info := Loc.t("ui.workshop.mechanism_info")
	var effect := ContentDB.data.mechanism(item).effect if m == null else m.effect_at(tier)
	if m != null:
		info = Loc.t("ui.workshop.module_info", {"section": Loc.t("section.%s" % m.section), "cell": Loc.t("cell.%s" % m.cell),
			"tier": WorkshopKit.tier_text(tier)})
	v.add_child(UiKit.label(info, 17, Palette.INK_MUTED))
	v.add_child(UiKit.paragraph(effect, 18, Palette.PARCHMENT))
	var l := GameState.run.loadout
	var owned := l.tiers_of(item).count(tier) if m != null else l.owned_mechanisms.count(item)
	var spare := l.spare_tiers(item).count(tier) if m != null else l.spare_mechanisms().count(item)
	v.add_child(UiKit.label(Loc.t("ui.workshop.owned", {"n": owned, "used": owned - spare}), 16, Palette.FOG))
	_box.add_child(h)


func _cards(ids: Array[StringName]) -> Control:
	var v := VBoxContainer.new()
	if ids.is_empty():
		return v
	v.add_child(UiKit.label(Loc.t("ui.workshop.cards"), 18, Palette.BRASS))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for i: int in ids.size():
		var holder := Control.new()  # CardView is drawn scaled; the holder keeps the row's spacing
		holder.custom_minimum_size = CardView.SIZE * CARD_SCALE
		var card := CardView.new().setup(CardInstance.create(i + 1, ContentDB.data.card(ids[i])))
		card.scale = Vector2.ONE * CARD_SCALE
		card.pivot_offset = Vector2.ZERO
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(card)
		row.add_child(holder)
	v.add_child(row)
	return v


func _craft_part(item: StringName) -> void:
	var bp := ContentDB.data.blueprint(item)
	if bp == null:
		return
	_box.add_child(HSeparator.new())
	if not GameState.run.workshop.blueprints.has(item):
		_box.add_child(Icons.with_text("UI", &"lock", Loc.t("ui.workshop.locked", {"trophy": WorkshopKit.stock_name(bp.unlock)}), 26, 17, Palette.INK_MUTED))
		return
	_box.add_child(UiKit.label(Loc.t("ui.workshop.craft_cost"), 18, Palette.BRASS))
	if ContentDB.data.module(item) != null:
		_box.add_child(UiKit.label(Loc.t("ui.workshop.craft_tier"), 15, Palette.INK_MUTED))
	_box.add_child(WorkshopKit.cost_row(bp.cost, 17))
	_box.add_child(_button(&"craft", "ui.workshop.craft", WorkshopRules.can_craft(GameState.run, ContentDB.data, item)))


func _upgrade_part(m: ModuleDef, tier: int) -> void:
	_box.add_child(HSeparator.new())
	if tier >= ModuleDef.MAX_TIER:
		_box.add_child(UiKit.label(Loc.t("ui.workshop.max_tier"), 17, Palette.FOG))
		return
	_box.add_child(UiKit.label(Loc.t("ui.workshop.next_tier", {"tier": ["I", "II", "III"][tier]}), 18, Palette.BRASS))
	_box.add_child(UiKit.paragraph(m.effect_at(tier + 1), 17, Palette.PARCHMENT))
	if GameState.run.loadout.tiers_of(m.id).has(tier):  # spare first (WorkshopRules.upgrade)
		var spare := GameState.run.loadout.spare_tiers(m.id).has(tier)
		_box.add_child(UiKit.label(Loc.t("ui.workshop.upgrades_spare" if spare else "ui.workshop.upgrades_installed"), 15, Palette.INK_MUTED))
	_box.add_child(WorkshopKit.cost_row(WorkshopRules.upgrade_cost(ContentDB.data, m.id, tier), 17))
	_box.add_child(_button(&"upgrade", "ui.workshop.upgrade", WorkshopRules.can_upgrade(GameState.run, ContentDB.data, m.id, tier)))


func _salvage_part(item: StringName) -> void:
	var l := GameState.run.loadout
	var problem := WorkshopRules.can_salvage(GameState.run, ContentDB.data, item, _tier)
	if problem != "" and not (l.tiers_of(item).has(_tier) or l.owned_mechanisms.has(item)):
		return  # no such copy: no salvage line at all
	_box.add_child(HSeparator.new())
	var back := WorkshopRules.salvage_refund(ContentDB.data, item, _tier)
	var parts: PackedStringArray = []
	for k: StringName in back:
		parts.append("%s +%d" % [WorkshopKit.stock_name(k), back[k]])
	_box.add_child(UiKit.label(Loc.t("ui.workshop.salvage_gives", {"list": ", ".join(parts) if not parts.is_empty() else "—"}), 16, Palette.FOG))
	_box.add_child(_button(&"salvage", "ui.workshop.salvage", problem))


func _button(kind: StringName, key: String, problem: String) -> Button:
	var icons: Dictionary[StringName, String] = {&"craft": "res://art/ui/WORKSHOP__craft_token.webp",
		&"upgrade": "res://art/ui/WORKSHOP__icon_upgrade.webp", &"salvage": "res://art/ui/WORKSHOP__icon_salvage.webp"}
	var b := UiKit.button(Loc.t(key), 20)
	b.icon = UiKit.texture(icons[kind])
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 34)
	b.disabled = problem != ""
	b.tooltip_text = problem
	b.pressed.connect(func() -> void: action.emit(kind, _item, _tier))
	return b
