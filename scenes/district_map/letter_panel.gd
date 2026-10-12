class_name LetterPanel
extends PlacePanel
## A story letter (GDD 2.4, owner 2026-10-12: the story is told by letters and notes): a new story contract's letter,
## the note once it is done, the end of the chapter. The last note asks for a choice (GameState.story_choice);
## otherwise «Дальше» and DistrictPanels marks it read.

var letter := ""  ## "step:<id>" / "after:<id>" / "end"


func _step() -> StoryDefs.StepDef:
	return ContentDB.data.story.step(StringName(letter.get_slice(":", 1))) if letter.contains(":") else null


func _portrait() -> String:
	var s := _step()
	return "res://art/ui/NPC__portrait__%s.webp" % (s.portrait if s != null else &"tavern_keeper")


func _title() -> String:
	return Loc.t("ui.story.title.%s" % letter.get_slice(":", 0))


func _fill() -> void:
	var st := ContentDB.data.story
	var s := _step()
	var from := st.end_from
	var text := st.end_text
	if letter.begins_with("step:") and s != null:
		var p := ContentDB.data.petition(s.petition)
		from = p.sender if p != null else ""
		text = p.text if p != null else ""
	elif s != null:
		from = s.after_from
		text = s.after_text
	body.add_child(UiKit.paragraph(text, 19, Palette.PARCHMENT))
	body.add_child(UiKit.paragraph("— " + from, 16, Palette.INK_MUTED))
	if letter.begins_with("step:") and s != null:
		var m := ContentDB.data.monster(s.monster)
		body.add_child(UiKit.paragraph(Loc.t("ui.story.contract", {"name": m.name if m != null else "",
			"type": Loc.t("ui.contract.type.%s" % s.type)}), 16, Palette.BRASS))
	var waiting := StoryRules.pending_choice(GameState.run, ContentDB.data)
	if waiting != null and s == waiting and letter.begins_with("after:"):
		for c: StoryDefs.ChoiceDef in s.choices:
			var b := UiKit.button(c.text, 19)
			b.pressed.connect(_choose.bind(c.id))
			body.add_child(b)
		return
	var next := UiKit.button(Loc.t("ui.rumor.next"), 20)
	next.pressed.connect(close_panel)
	body.add_child(next)


func _choose(choice_id: StringName) -> void:
	var problem := GameState.story_choice(choice_id)
	if problem != "":
		message.text = problem
		UiKit.sound(&"ui.error")
		return
	UiKit.sound(&"paper.map")
	letter = ""  # already read by the choice
	close_panel()
