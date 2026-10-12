class_name LibraryPanel
extends PlacePanel
## The Crypt Scriptorium (GDD 3.3, owner 2026-10-12): spend the day verifying one rumor (its tablet will show what it
## leads to) or studying one trophy (every contract on that creature learns one more sign); reset the Mechanic web for
## money (no day).


func _portrait() -> String:
	return "res://art/ui/NPC__portrait__scribe.webp"


func _title() -> String:
	return Loc.t("ui.library.title")


func _fill() -> void:
	var data := ContentDB.data
	var run := GameState.run
	body.add_child(UiKit.label(Loc.t("ui.library.verify_title"), 22, Palette.BRASS_LIGHT))
	var map := data.district_map(run.hero_district)
	var rumors := RumorRules.visible(run.rumors)
	if rumors.is_empty():
		body.add_child(UiKit.paragraph(Loc.t("ui.library.no_rumors"), 16, Palette.INK_MUTED))
	for r: RumorsState.Rumor in rumors:
		var tags := PackedStringArray(r.tags.map(func(t: StringName) -> String: return ContractKit.tag_name(t)))
		var text := "%s: %s" % [ContractKit.zone_name(map, r.zone), ", ".join(tags)]
		body.add_child(_row(text, LibraryRules.can_verify(run, r.uid), _verify.bind(r.uid)))
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


func _verify(uid: int) -> void:
	var r := GameState.run.rumors.find(uid)
	var problem := GameState.verify_rumor(uid)
	if problem != "":
		message.text = problem
		return
	show_done(Loc.t("ui.library.verified", {"outcome": Loc.t("ui.rumor.outcome.%s" % r.kind)}))


## A reset spends no day: the panel stays open with the points back.
func _reset(web_id: StringName) -> void:
	var problem := GameState.reset_skills(web_id)
	message.text = problem if problem != "" else Loc.t("ui.library.reset_done")
	UiKit.sound(&"ui.error" if problem != "" else &"money.coins")
	refill()


func _study(trophy: StringName) -> void:
	var taught := GameState.study_trophy(trophy)
	if taught.is_empty():
		message.text = LibraryRules.can_study(GameState.run, ContentDB.data, trophy)
		return
	show_done(Loc.t("ui.library.studied", {"name": ContractKit.monster_name(taught[0]), "n": taught.size()}))
