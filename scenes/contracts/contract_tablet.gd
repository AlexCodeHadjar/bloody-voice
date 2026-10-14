class_name ContractTablet
extends Control
## The contract tablet (GDD 7.2) in front of the hero: petition, type, silhouette, known signs, where the creature
## was last seen, deadline, reward and danger rank. Arrows switch between the tablets of the list; «Принять»
## stamps a seal (GameState.accept_contract). Full-screen overlay; closes with the cross, Esc or a click outside.

signal closed

const ART := "res://art/ui/CONTRACT__tablet.webp"
const SEAL := "res://art/ui/WAX__seal.webp"
const TABLET := Vector2(660, 880)
const MEDALLION := Vector2(314, 244)  ## the centre of the ornate ring on the tablet art (silhouette)
const SEAL_SPOT := Vector2(314, 770)  ## the small ring at the foot (the seal)
const INK := Color(0.11, 0.07, 0.04)  ## text on the parchment: near-black ink (owner 2026-10-14: readable)
const INK_RED := Color(0.38, 0.06, 0.03)
const INK_SOFT := Color(0.27, 0.2, 0.14)
const PAPER := Color(0.93, 0.88, 0.78, 0.86)  ## a clean patch of paper under the text, over the ruled lines

var _list: Array[ContractsState.Contract] = []
var _index := 0
var _body: Control
var _accept: Button
var _abandon: Button  ## gives a taken contract up (two presses)
var _abandon_armed := false
var _problem: Label
var _seal: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # fill the screen, not keep the 0×0 size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SHADE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(_build_tablet())
	EventBus.contracts_changed.connect(_show_current)


## Shows `list[index]`; the arrows walk the list.
func open_list(list: Array[ContractsState.Contract], index: int) -> void:
	_list = list
	_index = clampi(index, 0, maxi(list.size() - 1, 0))
	_show_current()
	UiKit.sound(&"paper.map")


## The tablet art with everything in its own place on the parchment (owner 2026-10-14: no dark inlay, ink on paper):
## type and rank on the bars beside the medallion, the silhouette in it, the name and the petition under it, the facts
## on the ruled lines, the seal in the small circle at the foot. The arrows flank the tablet, the buttons sit under it.
func _build_tablet() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	row.add_child(_arrow("arrow_left", -1))
	var tablet := TextureRect.new()
	tablet.texture = UiKit.texture(ART)
	tablet.custom_minimum_size = TABLET
	tablet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tablet.stretch_mode = TextureRect.STRETCH_SCALE
	tablet.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(tablet)
	row.add_child(_arrow("arrow_right", 1))
	_body = Control.new()  # holds the per-contract pieces, placed by hand on the tablet
	_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tablet.add_child(_body)
	_seal = UiKit.picture(UiKit.texture(SEAL), Vector2(120, 120))
	_seal.size = Vector2(120, 120)
	_seal.position = SEAL_SPOT - Vector2(60, 60)
	_seal.pivot_offset = Vector2(60, 60)
	_seal.rotation = -0.3
	tablet.add_child(_seal)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(44, 44)
	close.position = Vector2(TABLET.x - 64, 18)
	close.pressed.connect(close_tablet)
	tablet.add_child(close)
	col.add_child(_build_buttons())
	_problem = UiKit.paragraph("", 16, Palette.ALARM)
	_problem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_problem)
	return col


func _arrow(icon: StringName, step: int) -> Button:
	var b := Icons.button("UI", icon, "", 16)
	b.custom_minimum_size = Vector2(56, 56)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_step.bind(step))
	return b


func _build_buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	_accept = Icons.button("UI", &"accept", Loc.t("ui.contract.accept"), 20)
	_accept.custom_minimum_size = Vector2(260, 52)
	_accept.pressed.connect(_on_accept)
	row.add_child(_accept)
	_abandon = UiKit.button(Loc.t("ui.contract.abandon"), 18)
	_abandon.custom_minimum_size = Vector2(240, 52)
	_abandon.pressed.connect(_on_abandon)
	row.add_child(_abandon)
	return row


func _show_current() -> void:
	for child: Node in _body.get_children():
		child.queue_free()
	_problem.text = ""
	if _list.is_empty():
		return
	var c := _list[_index]
	_fill(c)
	_seal.visible = c.accepted or c.done
	_seal.modulate = Color(1, 1, 1, 0.55 if c.done else 1.0)
	var status := "ui.contract.done" if c.done else ("ui.contract.taken" if c.accepted else "ui.contract.accept")
	_accept.text = Loc.t(status)
	_accept.disabled = c.accepted or c.done
	_abandon.visible = ContractRules.can_abandon(GameState.run.contracts, c.uid) == ""
	_abandon.text = Loc.t("ui.contract.abandon")
	_abandon_armed = false


func _fill(c: ContractsState.Contract) -> void:
	_paper(Rect2(74, 236, 140, 42))
	_place(Icons.with_text("CONTRACT", c.type, ContractKit.type_name(c), 32, 20, INK), Rect2(78, 236, 140, 42))
	_paper(Rect2(442, 236, 140, 42))
	_place(Icons.with_text("RANK", StringName(ContractKit.rank(c).to_lower()), Loc.t("ui.contract.rank", {"rank": ContractKit.rank(c)}),
		32, 20, INK), Rect2(446, 236, 140, 42))
	_place(UiKit.picture(ContractKit.silhouette(c), Vector2(170, 170)), Rect2(MEDALLION - Vector2(85, 85), Vector2(170, 170)))
	var title := UiKit.label(ContractKit.monster_name(c), 34, INK_RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(title, Rect2(70, 372, 520, 40))
	var p := ContentDB.data.petition(c.petition)
	if p != null:
		var letter := VBoxContainer.new()
		letter.add_theme_constant_override("separation", 0)
		var text := UiKit.paragraph(p.text, 17, INK)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.add_child(text)
		var who := UiKit.paragraph("— " + p.sender, 15, INK_SOFT)
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.add_child(who)
		_paper(Rect2(72, 412, 516, 84))
		_place(letter, Rect2(80, 414, 500, 80))
	var facts := VBoxContainer.new()
	facts.add_theme_constant_override("separation", 2)
	_paper(Rect2(76, 500, 508, 236))
	_place(facts, Rect2(86, 504, 488, 228))
	_fill_facts(c, facts)


## A clean patch of paper under a block of text, so the ruled lines of the form do not cross the letters.
func _paper(rect: Rect2) -> void:
	var patch := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.set_corner_radius_all(6)
	box.shadow_color = Color(PAPER, 0.5)
	box.shadow_size = 6  # soft edges, no frame
	patch.add_theme_stylebox_override("panel", box)
	_place(patch, rect)


func _place(node: Control, rect: Rect2) -> void:
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(node)


## Signs and facts on the ruled lines, in ink.
func _fill_facts(c: ContractsState.Contract, box: VBoxContainer) -> void:
	box.add_child(UiKit.label(Loc.t("ui.contract.signs"), 19, INK_RED))
	for tag: StringName in c.known_tags:
		box.add_child(Icons.with_text("TAG", ContractKit.tag_category(tag), ContractKit.tag_name(tag), 26, 18, INK))
	if not c.affixes.is_empty():  # a stronger creature: its affixes add moves and HP (GDD 17)
		box.add_child(_fact("INTENT", &"buff", "ui.contract.affixes", AffixGenerator.names(ContentDB.data, c.affixes), INK_RED))
	box.add_child(_fact("CONTRACT", &"region", "ui.contract.last_seen", ContractKit.last_seen(c), INK))
	box.add_child(_fact("CONTRACT", &"deadline", "ui.contract.deadline", ContractKit.deadline_text(c),
		ContractKit.deadline_color(c, INK)))
	box.add_child(_fact("RESOURCE", &"money", "ui.contract.reward", str(c.reward), INK))


func _fact(set_code: String, icon: StringName, key: String, value: String, color: Color) -> HBoxContainer:
	var h := Icons.with_text(set_code, icon, Loc.t(key), 28, 18, INK_RED)
	var l := UiKit.label(value, 18, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _step(delta: int) -> void:
	if _list.size() < 2:
		return
	_index = posmod(_index + delta, _list.size())
	_show_current()
	UiKit.sound(&"paper.map")


func _on_accept() -> void:
	if _list.is_empty():
		return
	var problem := GameState.accept_contract(_list[_index].uid)
	if problem != "":
		_problem.text = problem
		UiKit.sound(&"ui.error")
		return
	UiKit.sound(&"ui.confirm")
	_seal.scale = Vector2.ONE * 2.2  # the seal comes down onto the tablet
	_seal.modulate = Color(1, 1, 1, 0)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_seal, "scale", Vector2.ONE, 0.25)
	tw.tween_property(_seal, "modulate", Color.WHITE, 0.15)


## The first press warns (the petitioner's faction will frown), the second gives the contract up.
func _on_abandon() -> void:
	if _list.is_empty():
		return
	if not _abandon_armed:
		_abandon_armed = true
		_abandon.text = Loc.t("ui.contract.abandon_sure")
		_problem.text = Loc.t("ui.contract.abandon_warn")
		return
	var c := _list[_index]
	if ContractRules.can_abandon(GameState.run.contracts, c.uid) != "":
		_problem.text = ContractRules.can_abandon(GameState.run.contracts, c.uid)
		UiKit.sound(&"ui.error")
		return
	_list.erase(c)  # before the call: contracts_changed redraws from the list
	_index = clampi(_index, 0, maxi(0, _list.size() - 1))
	GameState.abandon_contract(c.uid)
	UiKit.sound(&"paper.map")
	if _list.is_empty():
		close_tablet()  # otherwise contracts_changed has already redrawn the tablet


func close_tablet() -> void:
	UiKit.sound(&"ui.close")
	closed.emit()
	queue_free()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close_tablet()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_tablet()
	elif event.is_action_pressed("ui_left"):
		_step(-1)
	elif event.is_action_pressed("ui_right"):
		_step(1)
