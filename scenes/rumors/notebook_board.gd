class_name NotebookBoard
extends Control
## The hunter's notebook (GDD 8.4, owner 2026-10-15): a board of dark wood — the taken contracts on the left, the rumor
## cards pinned on the right. The player pulls a red thread from a rumor's sign to a contract: it holds when the rumor
## is about that contract's creature and the sign is true (the contract learns it), otherwise it snaps and the card
## burns. Three cards on a contract's threads bring its lair to the map. Free. Full-screen overlay.

signal closed

const PANEL := Vector2(1780, 960)
const WOOD := "res://art/ui/TEX__dark_wood.webp"

var _contracts: VBoxContainer
var _grid: GridContainer
var _threads: ThreadView
var _message: Label
var _fresh: Dictionary[int, bool] = {}  ## cards new when the notebook opened
var _rumor_rows: Dictionary[int, Dictionary] = {}  ## card uid -> {sign: row}
var _notes: Dictionary[int, Dictionary] = {}  ## contract uid -> {"node", "rows", "slot"}
var _drag_card := 0
var _drag_tag: StringName = &""


func _ready() -> void:
	for c: RumorsState.Card in GameState.run.rumors.cards:
		if c.fresh:
			_fresh[c.uid] = true
	GameState.notebook_seen()
	var panel := UiKit.overlay(self, Palette.BRASS, PANEL)
	var wood := TextureRect.new()
	wood.texture = UiKit.texture(WOOD)
	wood.stretch_mode = TextureRect.STRETCH_TILE
	wood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wood.modulate = Color(0.75, 0.68, 0.62)
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(wood)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(_header())
	v.add_child(_body())
	_message = UiKit.label("", 19, Palette.BRASS_LIGHT)
	v.add_child(_message)
	_threads = ThreadView.new()
	add_child(_threads)
	EventBus.rumors_changed.connect(refill)
	EventBus.contracts_changed.connect(refill)
	refill()
	UiKit.sound(&"paper.map")
	if not GameState.run.rumors.cards.is_empty():
		Tutorial.trigger.call_deferred(&"first_rumor")


func _header() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 20)
	h.add_child(UiKit.label(Loc.t("ui.rumor.notebook"), 34, Palette.BRASS_LIGHT))
	var hint := UiKit.paragraph(Loc.t("ui.rumor.board_hint"), 17, Palette.PARCHMENT)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(hint)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(44, 44)
	close.pressed.connect(close_board)
	h.add_child(close)
	return h


## Contracts on the left, rumor cards on the right, each scrolling on its own.
func _body() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 60)  # room for the threads to sag across
	var left := ScrollContainer.new()
	left.custom_minimum_size = Vector2(NotebookCards.CONTRACT_WIDTH + 16.0, 0)
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_contracts = VBoxContainer.new()
	_contracts.add_theme_constant_override("separation", 14)
	left.add_child(_contracts)
	TutorialAnchors.register(&"notebook_contracts", left)
	h.add_child(left)
	var right := ScrollContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	right.add_child(_grid)
	TutorialAnchors.register(&"notebook_rumors", right)
	h.add_child(right)
	return h


func refill() -> void:
	for box: Node in [_contracts, _grid]:
		for child: Node in box.get_children():
			child.queue_free()
	_notes.clear()
	_rumor_rows.clear()
	var run := GameState.run
	for c: ContractsState.Contract in ContractRules.active(run.contracts):
		var note := NotebookCards.contract(c)
		_contracts.add_child(note["node"] as Control)
		_notes[c.uid] = note
	if _notes.is_empty():
		_contracts.add_child(UiKit.paragraph(Loc.t("ui.rumor.no_contracts"), 17, Palette.PARCHMENT))
	for card: RumorsState.Card in run.rumors.cards:
		var made := NotebookCards.rumor(card, _fresh.has(card.uid), _grab, _discard)
		_grid.add_child(made["node"] as Control)
		_rumor_rows[card.uid] = made["rows"]
	if _rumor_rows.is_empty():
		_grid.add_child(UiKit.paragraph(Loc.t("ui.rumor.no_cards"), 17, Palette.PARCHMENT))
	_threads.held = _held()


## Threads that held: each tied sign of a card to the same sign on its contract.
func _held() -> Array[Array]:
	var out: Array[Array] = []
	for card: RumorsState.Card in GameState.run.rumors.cards:
		var note: Dictionary = _notes.get(card.linked, {})
		for t: StringName in card.threads:
			var to: Variant = (note.get("rows", {}) as Dictionary).get(t)
			if to != null:
				out.append([(_rumor_rows[card.uid] as Dictionary)[t], to])
	return out


func _grab(card_uid: int, tag: StringName, row: Control) -> void:
	_drag_card = card_uid
	_drag_tag = tag
	_threads.pulling = row
	UiKit.sound(&"ui.click")


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if _drag_card != 0 and mb != null and not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_drop()


## The thread is let go: over a contract it is tied there; anywhere else it goes back.
func _drop() -> void:
	var row := _threads.pulling
	_threads.pulling = null
	var card_uid := _drag_card
	_drag_card = 0
	var target := 0
	for uid: int in _notes:
		if ((_notes[uid] as Dictionary)["node"] as Control).get_global_rect().has_point(get_global_mouse_position()):
			target = uid
	if target == 0 or row == null:
		return
	var from := _threads.left_pin(row)
	var to := _threads.get_local_mouse_position()
	var card_rect := (row.get_parent().get_parent() as Control).get_global_rect()  # row -> its box -> the card
	var l := GameState.link_rumor(card_uid, target, _drag_tag)
	if l == null:
		_say(Loc.t("ui.rumor.cant_tie"), &"ui.error")
	elif not l.held:
		_threads.snap(from, to)
		_burn(card_rect)
		_say(Loc.t("ui.rumor.snapped"), &"ui.error")
	else:
		_say(_held_text(l), &"ui.confirm")


func _held_text(l: RumorRules.Link) -> String:
	if l.mark != null:
		return Loc.t("ui.rumor.noted_found")
	var of := ContentDB.data.balance.rumors.trail_needed
	if l.learned != &"":
		return Loc.t("ui.rumor.held_learned", {"tag": ContractKit.tag_name(l.learned), "n": l.trail, "of": of})
	return Loc.t("ui.rumor.held", {"n": l.trail, "of": of})


## The burned card: a scorched paper that darkens and falls away where the card was.
func _burn(rect: Rect2) -> void:
	var ash := ColorRect.new()
	ash.color = Color(0.95, 0.45, 0.12, 0.9)
	ash.position = rect.position - get_global_rect().position
	ash.size = rect.size
	ash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ash)
	var tw := ash.create_tween()
	tw.tween_property(ash, "color", Color(0.1, 0.05, 0.03, 0.85), 0.35)
	tw.parallel().tween_property(ash, "position:y", ash.position.y + 40.0, 0.9)
	tw.tween_property(ash, "modulate:a", 0.0, 0.5)
	tw.tween_callback(ash.queue_free)


func _discard(uid: int) -> void:
	if GameState.discard_rumor(uid):
		UiKit.sound(&"ui.close")


func _say(text: String, sound: StringName) -> void:
	_message.text = text
	UiKit.sound(sound)


func close_board() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_board()
