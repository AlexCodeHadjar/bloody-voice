class_name ContractTablet
extends Control
## The contract tablet (GDD 7.2) in front of the hero: petition, type, silhouette, known signs, where the creature
## was last seen, deadline, reward and danger rank. Arrows switch between the tablets of the list; «Принять»
## stamps a seal (GameState.accept_contract). Full-screen overlay; closes with the cross, Esc or a click outside.

signal closed

const ART := "res://art/ui/CONTRACT__tablet.webp"
const SEAL := "res://art/ui/WAX__seal.webp"
const TABLET := Vector2(660, 880)

var _list: Array[ContractsState.Contract] = []
var _index := 0
var _body: VBoxContainer
var _accept: Button
var _problem: Label
var _seal: TextureRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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


func _build_tablet() -> Control:
	var tablet := TextureRect.new()
	tablet.texture = UiKit.texture(ART)
	tablet.custom_minimum_size = TABLET
	tablet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tablet.stretch_mode = TextureRect.STRETCH_SCALE
	tablet.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := PanelContainer.new()  # a dark inlay so the text reads on any part of the art
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.8), Palette.BRASS))
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 80
	panel.offset_bottom = -80
	tablet.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_body)
	_problem = UiKit.paragraph("", 16, Palette.ALARM)
	_problem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_problem)
	v.add_child(_build_buttons())
	_seal = ContractKit.picture(UiKit.texture(SEAL), Vector2(150, 150))
	_seal.size = Vector2(150, 150)
	_seal.position = Vector2(TABLET.x - 230, TABLET.y - 300)
	_seal.pivot_offset = Vector2(75, 75)
	_seal.rotation = -0.3
	tablet.add_child(_seal)
	var close := Icons.button("UI", &"close", "", 16)
	close.custom_minimum_size = Vector2(44, 44)
	close.position = Vector2(TABLET.x - 64, 18)
	close.pressed.connect(close_tablet)
	tablet.add_child(close)
	return tablet


func _build_buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var prev := Icons.button("UI", &"arrow_left", "", 16)
	prev.custom_minimum_size = Vector2(52, 52)
	prev.pressed.connect(_step.bind(-1))
	row.add_child(prev)
	_accept = Icons.button("UI", &"accept", Loc.t("ui.contract.accept"), 20)
	_accept.pressed.connect(_on_accept)
	row.add_child(_accept)
	var next := Icons.button("UI", &"arrow_right", "", 16)
	next.custom_minimum_size = Vector2(52, 52)
	next.pressed.connect(_step.bind(1))
	row.add_child(next)
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


func _fill(c: ContractsState.Contract) -> void:
	var head := HBoxContainer.new()
	head.add_child(Icons.with_text("CONTRACT", c.type, ContractKit.type_name(c), 34, 20, Palette.BRASS_LIGHT))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	head.add_child(Icons.with_text("RANK", StringName(ContractKit.rank(c).to_lower()),
		Loc.t("ui.contract.rank", {"rank": ContractKit.rank(c)}), 34, 18, Palette.FOG))
	_body.add_child(head)
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 14)
	who.add_child(ContractKit.picture(ContractKit.silhouette(c), Vector2(150, 150)))
	var letter := VBoxContainer.new()
	letter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	letter.add_child(UiKit.label(ContractKit.monster_name(c), 30, Palette.BRASS_LIGHT))
	var p := ContentDB.data.petition(c.petition)
	if p != null:
		letter.add_child(UiKit.paragraph(p.text, 16, Palette.PARCHMENT))
		letter.add_child(UiKit.paragraph("— " + p.sender, 15, Palette.INK_MUTED))
	who.add_child(letter)
	_body.add_child(who)
	_fill_facts(c)


func _fill_facts(c: ContractsState.Contract) -> void:
	_body.add_child(UiKit.label(Loc.t("ui.contract.signs"), 18, Palette.BRASS))
	for tag: StringName in c.known_tags:
		_body.add_child(Icons.with_text("TAG", ContractKit.tag_category(tag), ContractKit.tag_name(tag), 26, 17))
	if not c.crossed_tags.is_empty():  # signs false leads proved not to be the creature's (GDD 8.2)
		var crossed := PackedStringArray(c.crossed_tags.map(func(t: StringName) -> String: return "[s]%s[/s]" % ContractKit.tag_name(t)))
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.add_theme_font_size_override("normal_font_size", 16)
		l.add_theme_color_override("default_color", Palette.INK_MUTED)
		l.text = "%s %s" % [Loc.t("ui.contract.crossed"), ", ".join(crossed)]
		_body.add_child(l)
	_body.add_child(_fact("CONTRACT", &"region", "ui.contract.last_seen", ContractKit.last_seen(c), Palette.PARCHMENT))
	_body.add_child(_fact("CONTRACT", &"deadline", "ui.contract.deadline", ContractKit.deadline_text(c),
		ContractKit.deadline_color(c, Palette.PARCHMENT)))
	_body.add_child(_fact("RESOURCE", &"money", "ui.contract.reward", str(c.reward), Palette.BRASS_LIGHT))


func _fact(set_code: String, icon: StringName, key: String, value: String, color: Color) -> HBoxContainer:
	var h := Icons.with_text(set_code, icon, Loc.t(key), 30, 17, Palette.BRASS)
	var l := UiKit.label(value, 17, color)
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
