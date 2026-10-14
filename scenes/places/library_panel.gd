class_name LibraryPanel
extends PlacePanel
## The Crypt Scriptorium (GDD 3.3, owner 2026-10-12): spend the day studying one trophy (every contract on that
## creature learns one more sign); reset the Mechanic web for money (no day). Verifying rumors is gone (2026-10-14).


func _portrait() -> String:
	return "res://art/ui/NPC__portrait__scribe.webp"


func _title() -> String:
	return Loc.t("ui.library.title")


func _fill() -> void:
	var data := ContentDB.data
	var run := GameState.run
	var web := data.webs.get(&"mechanic") as SkillDefs.WebDef
	if web != null:  # resetting the Mechanic web: money, no day (owner, 2026-10-12)
		body.add_child(UiKit.label(Loc.t("ui.library.reset_title"), 22, Palette.BRASS_LIGHT))
		body.add_child(_row(Loc.t("ui.library.reset_text", {"n": SkillRules.reset_cost(run, data, web)}),
			SkillRules.can_reset(run, data, web), _reset.bind(web.id)))
	body.add_child(UiKit.label(Loc.t("ui.library.study_title"), 22, Palette.BRASS_LIGHT))
	if run.workshop.trophies.is_empty():
		body.add_child(UiKit.paragraph(Loc.t("ui.library.no_trophies"), 16, Palette.INK_MUTED))
	for t: StringName in run.workshop.trophies:
		var m := data.monster(LibraryRules.trophy_creature(data, t))
		var text := "%s ×%d — %s" % [WorkshopKit.stock_name(t), run.workshop.trophies[t], m.name if m != null else ""]
		body.add_child(_row(text, LibraryRules.can_study(run, data, t), _study.bind(t)))


func _row(text: String, problem: String, action: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := UiKit.paragraph(text, 16, Palette.PARCHMENT if problem == "" else Palette.INK_MUTED)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var b := UiKit.button(Loc.t("ui.library.do"), 16)
	b.custom_minimum_size = Vector2(170, 40)
	b.disabled = problem != ""
	b.tooltip_text = problem
	b.pressed.connect(action)
	h.add_child(b)
	return h


## A reset spends no day: the panel stays open with the points back.
func _reset(web_id: StringName) -> void:
	var problem := GameState.reset_skills(web_id)
	message.text = problem if problem != "" else Loc.t("ui.library.reset_done")  # HP above a lower maximum is capped
	UiKit.sound(&"ui.error" if problem != "" else &"money.coins")
	refill()


func _study(trophy: StringName) -> void:
	var study := GameState.study_trophy(trophy)
	if study == null:
		message.text = LibraryRules.can_study(GameState.run, ContentDB.data, trophy)
		return
	var name_text := ContentDB.data.monster(study.creature).name
	var lines: PackedStringArray = []
	if not study.taught.is_empty():
		lines.append(Loc.t("ui.library.studied", {"name": name_text, "n": study.taught.size()}))
	if study.dissected:
		lines.append(Loc.t("ui.library.dissected", {"name": name_text}))
	show_done("\n".join(lines))
