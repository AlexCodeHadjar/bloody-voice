class_name HeroPanel
extends PlacePanel
## «Охотник» (GDD 4, 23.2 zones 1 and 4): level and XP toward the next, HP and Sanity, free skill points with the way
## to the skill webs, attribute points and the three attributes with «+» while points are free; the Register rank and
## reputation with the district's factions (GDD 12).


func _portrait() -> String:
	return "res://art/ui/COMBAT__hunter_portrait.webp"


func _title() -> String:
	return Loc.t("ui.progress.title", {"n": GameState.run.progress.level})


func _fill() -> void:
	var run := GameState.run
	var data := ContentDB.data
	var pr := run.progress
	var cap := pr.level >= data.balance.progress.level_cap
	var xp_text := Loc.t("ui.progress.max_level") if cap else Loc.t("ui.progress.xp", {"n": pr.xp, "of": ProgressRules.xp_to_next(data, pr.level)})
	body.add_child(Icons.with_text("STAT", &"xp", xp_text, 30, 20))
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = ProgressRules.xp_to_next(data, pr.level)
	bar.value = bar.max_value if cap else pr.xp
	body.add_child(bar)
	body.add_child(Icons.with_text("STAT", &"hp", Loc.t("ui.health.hp", {"n": HealthRules.hp(run, data), "of": HealthRules.max_hp(run, data)}), 30, 18))
	body.add_child(Icons.with_text("STAT", &"sanity", Loc.t("ui.health.sanity", {"n": HealthRules.sanity(run, data), "of": HealthRules.max_sanity(run, data)}), 30, 18))
	var points := HBoxContainer.new()
	points.add_child(Icons.with_text("STAT", &"skill_point", Loc.t("ui.progress.skill_points", {"n": pr.skill_points}), 30, 18))
	var webs := UiKit.button(Loc.t("ui.progress.to_webs"), 18)
	webs.custom_minimum_size = Vector2(220, 42)
	webs.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/skills/skill_web_screen.tscn"))
	points.add_child(webs)
	body.add_child(points)
	body.add_child(UiKit.label(Loc.t("ui.progress.attributes", {"n": pr.attribute_points}), 22, Palette.BRASS_LIGHT))
	for a: StringName in ProgressDefs.ATTRIBUTES:
		body.add_child(_attribute_row(a))
	_standing(run, data)


func _standing(run: RunState, data: ContentData) -> void:
	body.add_child(HSeparator.new())
	var letter := RegisterRules.rank_letter(data, run.standing.rank)
	var next := Loc.t("ui.register.top")
	if RegisterRules.can_advance(run, data):
		var left := RegisterRules.contracts_left(run, data)
		next = Loc.t("ui.register.left", {"n": left}) if left > 0 else Loc.t("ui.register.exam_due")
	body.add_child(Icons.with_text("RANK", StringName(letter.to_lower()), Loc.t("ui.register.rank", {"rank": letter,
		"name": Loc.t("ui.register.rank_name.%s" % letter), "next": next}), 34, 18))
	for f: StandingDefs.FactionDef in data.factions:
		var t := FactionRules.tier(run, data, f.id)
		var row := Icons.with_text("FACTION", f.id, Loc.t("ui.faction.row", {"name": f.name, "n": run.standing.rep(f.id),
			"tier": Loc.t("ui.faction.tier.%s" % t)}), 34, 18)
		row.tooltip_text = f.text + "\n" + _effects_text(f.tiers.get(t, {}) as Dictionary)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		body.add_child(row)


func _attribute_row(a: StringName) -> HBoxContainer:
	var pr := GameState.run.progress
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(Icons.rect("ATTRIBUTE", a, 36))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiKit.label("%s — %d" % [Loc.t("ui.progress.attr.%s" % a), pr.attribute(a)], 19, Palette.PARCHMENT))
	v.add_child(UiKit.paragraph(Loc.t("ui.progress.attr.%s.about" % a), 15, Palette.FOG))
	h.add_child(v)
	var plus := UiKit.button("+", 22)
	plus.custom_minimum_size = Vector2(52, 44)
	plus.disabled = pr.attribute_points <= 0
	plus.pressed.connect(_raise.bind(a))
	h.add_child(plus)
	return h


func _raise(a: StringName) -> void:
	var problem := GameState.raise_attribute(a)
	message.text = problem
	UiKit.sound(&"ui.error" if problem != "" else &"ui.confirm")
	refill()


## A tier's effects in words, from factions.json (no numbers in the texts).
func _effects_text(effects: Dictionary) -> String:
	var lines: PackedStringArray = []
	for e: Variant in effects:
		var v := float(effects[e])
		var n := roundi((v - 1.0) * 100.0) if str(e).ends_with("_mult") else int(v)
		var shown := ("+" if n > 0 else "") + str(n) + (" %" if str(e).ends_with("_mult") else "")
		lines.append(Loc.t("ui.faction.effect.%s" % e, {"v": shown}))
	return "\n".join(lines) if not lines.is_empty() else Loc.t("ui.faction.effect.none")
