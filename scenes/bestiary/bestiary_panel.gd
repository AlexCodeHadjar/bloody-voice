class_name BestiaryPanel
extends PlacePanel
## «Бестиарий» (GDD 10.3): the creatures of the district, each with its knowledge marks (seen, fought, slain, captured,
## dissected); the picked one's page — rank, body parts and moves once fought, and what every mark gives in a fight
## with it. Unseen creatures are only a black silhouette.

const ROW_ART := Vector2(72, 72)

var _picked: StringName = &""


func _portrait() -> String:
	return "res://art/ui/NPC__portrait__scribe.webp"


func _title() -> String:
	return Loc.t("ui.bestiary.title")


func _fill() -> void:
	var run := GameState.run
	var list := BestiaryRules.creatures(run, ContentDB.data)
	if _picked == &"" and not list.is_empty():
		_picked = list[0]
	for id: StringName in list:
		body.add_child(_row(id))
	body.add_child(HSeparator.new())
	if _picked != &"":
		_page(_picked)


func _row(id: StringName) -> HBoxContainer:
	var run := GameState.run
	var m := ContentDB.data.monster(id)
	var seen := not run.bestiary.of(id).is_empty()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = id == _picked
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, ROW_ART.y + 8)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.icon = UiKit.texture(m.art_path("silhouette", "normal"))
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", int(ROW_ART.x))
	b.text = "%s  [%s]" % [m.name if seen else Loc.t("ui.bestiary.unknown"), m.rank]
	b.pressed.connect(func() -> void:
		_picked = id
		refill())
	row.add_child(b)
	for k: StringName in StandingDefs.KNOWLEDGE:  # the five marks, dim when missing
		var icon := Icons.rect("KNOWLEDGE", k, 34)
		icon.modulate = Color.WHITE if run.bestiary.has(id, k) else Color(0.3, 0.3, 0.3, 0.7)
		icon.tooltip_text = Loc.t("ui.bestiary.mark.%s" % k)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(icon)
	return row


## The page: what the marks show and give.
func _page(id: StringName) -> void:
	var run := GameState.run
	var data := ContentDB.data
	var m := data.monster(id)
	if run.bestiary.of(id).is_empty():
		body.add_child(UiKit.paragraph(Loc.t("ui.bestiary.unseen"), 17, Palette.FOG))
		return
	body.add_child(UiKit.label(m.name, 26, Palette.BRASS_LIGHT))
	if run.bestiary.has(id, &"fought"):
		var parts: PackedStringArray = []
		for p: MonsterDef.PartDef in m.parts:
			parts.append("%s (%d)" % [p.name, p.hp])
		var moves: PackedStringArray = []
		for mv: MonsterDef.MoveDef in m.moves.values():
			moves.append(mv.name)
		body.add_child(UiKit.paragraph(Loc.t("ui.bestiary.body", {"hp": m.hp, "parts": ", ".join(parts)}), 16, Palette.PARCHMENT))
		body.add_child(UiKit.paragraph(Loc.t("ui.bestiary.moves", {"list": ", ".join(moves)}), 16, Palette.PARCHMENT))
	else:
		body.add_child(UiKit.paragraph(Loc.t("ui.bestiary.not_fought"), 16, Palette.FOG))
	for k: StringName in data.balance.bestiary.mods:
		var mods: Dictionary[StringName, int] = {}
		mods.assign(data.balance.bestiary.mods[k])
		var gains: PackedStringArray = []
		for mod: StringName in mods:
			gains.append("%s %s" % [Loc.t("mod.%s" % mod), UiKit.signed(mods[mod])])
		var has := run.bestiary.has(id, k)
		body.add_child(Icons.with_text("KNOWLEDGE", k, Loc.t("ui.bestiary.gives", {"mark": Loc.t("ui.bestiary.mark.%s" % k),
			"list": ", ".join(gains)}), 28, 16, Palette.BRASS if has else Palette.INK_MUTED))
