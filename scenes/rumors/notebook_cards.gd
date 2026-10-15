class_name NotebookCards
extends RefCounted
## The cards pinned on the notebook board (GDD 8.4): a rumor (who told it, about which zone, its signs, each with a
## pin a thread is pulled from) and a contract (its creature, where it was seen, the signs it knows, a slot for a new
## sign, the trail). Ink on paper. The board keeps the sign rows to draw threads between them.

const PAPER := Color(0.86, 0.79, 0.64)
const PAPER_DARK := Color(0.74, 0.66, 0.5)
const INK := Color(0.16, 0.11, 0.07)
const INK_SOFT := Color(0.36, 0.28, 0.2)
const INK_RED := Color(0.55, 0.08, 0.05)
const RUMOR_SIZE := Vector2(296, 250)
const CONTRACT_WIDTH := 400.0


## A rumor card. `grab(card_uid, tag, row)` starts a thread from a sign; `discard(uid)` throws the card away.
## Returns {"node": the card, "rows": {sign: its row}}.
static func rumor(card: RumorsState.Card, fresh: bool, grab: Callable, discard: Callable) -> Dictionary:
	var run := GameState.run
	var panel := _paper(PAPER, Color(0.45, 0.32, 0.18))
	panel.custom_minimum_size = RUMOR_SIZE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	var head := HBoxContainer.new()
	var map := ContentDB.data.district_map(run.hero_district)
	var zone := UiKit.label(ContractKit.zone_name(map, card.zone), 17, INK_RED)
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(zone)
	if fresh:
		head.add_child(UiKit.label(Loc.t("ui.rumor.fresh"), 14, INK_RED))
	if card.linked == 0:
		var x := Button.new()
		x.text = "✕"
		x.flat = true
		x.add_theme_color_override("font_color", INK_SOFT)
		x.add_theme_color_override("font_hover_color", INK_RED)
		x.add_theme_font_size_override("font_size", 18)
		x.tooltip_text = Loc.t("ui.rumor.discard")
		x.pressed.connect(discard.bind(card.uid))
		head.add_child(x)
	v.add_child(head)
	var who := UiKit.paragraph(_witness(card.witness), 15, INK_SOFT)
	v.add_child(who)
	var rows := _rumor_rows(v, card, grab)
	if ProgressRules.suspicious(run, ContentDB.data, card):  # Cunning (GDD 4.3)
		v.add_child(Icons.with_text("ATTRIBUTE", &"cunning", Loc.t("ui.rumor.suspicious"), 22, 14, INK_RED))
	if card.linked != 0:
		var c := run.contracts.find(card.linked)
		v.add_child(UiKit.label(Loc.t("ui.rumor.on_thread", {"name": ContractKit.monster_name(c) if c != null else ""}), 14, INK_RED))
	return {"node": panel, "rows": rows}


## The rumor's signs; a sign not tied yet can be pulled (a card on a thread can tie more of its signs).
static func _rumor_rows(v: VBoxContainer, card: RumorsState.Card, grab: Callable) -> Dictionary:
	var rows: Dictionary = {}
	for t: StringName in card.tags:
		var row := _sign_row(t, INK if not card.threads.has(t) else INK_RED, true)
		if not card.threads.has(t):
			row.mouse_default_cursor_shape = Control.CURSOR_DRAG
			row.tooltip_text = Loc.t("ui.rumor.pull_hint")
			row.gui_input.connect(func(e: InputEvent) -> void:
				var mb := e as InputEventMouseButton
				if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					grab.call(card.uid, t, row))
		v.add_child(row)
		rows[t] = row
	return rows


## A contract card. Returns {"node", "rows": {sign: its row}, "slot": the new-sign row}.
static func contract(c: ContractsState.Contract) -> Dictionary:
	var run := GameState.run
	var panel := _paper(PAPER, Palette.BRASS)
	panel.custom_minimum_size = Vector2(CONTRACT_WIDTH, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(Icons.with_text("CONTRACT", c.type, ContractKit.monster_name(c), 26, 21, INK))
	v.add_child(UiKit.label(Loc.t("ui.contract.last_seen") + " " + ContractKit.last_seen(c), 15, INK_SOFT))
	var rows: Dictionary = {}
	for t: StringName in c.known_tags:
		var row := _sign_row(t, INK, false)
		v.add_child(row)
		rows[t] = row
	var slot := _sign_row(&"", INK_SOFT, false)
	v.add_child(slot)
	var needed := ContentDB.data.balance.rumors.trail_needed
	var trail := run.rumors.trail(c.uid)
	var found := RumorRules.target_mark(run.rumors, c.uid) != null
	var dots := "●".repeat(mini(trail, needed)) + "○".repeat(maxi(0, needed - trail))
	v.add_child(UiKit.label(Loc.t("ui.rumor.found") if found else Loc.t("ui.rumor.trail_dots", {"dots": dots}), 17,
		INK_RED if found else INK))
	return {"node": panel, "rows": rows, "slot": slot}


## A sign with its pin: on the left of a rumor's row, on the right of a contract's (they face each other). `tag` "" = the new-sign slot.
static func _sign_row(tag: StringName, color: Color, pin_left: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_theme_constant_override("separation", 6)
	var pin := ColorRect.new()
	pin.custom_minimum_size = Vector2(10, 10)
	pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pin.color = Color(0.62, 0.48, 0.25)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text: Control = UiKit.label(Loc.t("ui.rumor.new_sign"), 16, color)
	if tag != &"":
		text = Icons.with_text("TAG", ContractKit.tag_category(tag), ContractKit.tag_name(tag), 22, 17, color)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pin_left:
		row.add_child(pin)
	row.add_child(text)
	if not pin_left:
		row.add_child(pin)
	return row


static func _paper(fill: Color, border: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var box := UiKit.panel_box(fill, border)
	box.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", box)
	return p


static func _witness(id: StringName) -> String:
	for wi: RumorDefs.Witness in ContentDB.data.rumor_data.witnesses:
		if wi.id == id:
			return wi.text
	return ""
