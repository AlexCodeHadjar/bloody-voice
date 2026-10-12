class_name InfirmaryPanel
extends PlacePanel
## The Ash Sisters' infirmary (GDD 4, owner 2026-10-12): HP and Sanity now, the price of a full treatment and
## «Лечиться (весь день)». No credit here; after a Hunter's Fall the sisters treat you anyway (GameState).


func _portrait() -> String:
	return "res://art/ui/NPC__portrait__ash_sister.webp"


func _title() -> String:
	return Loc.t("ui.infirmary.title")


func _fill() -> void:
	var run := GameState.run
	var data := ContentDB.data
	body.add_child(UiKit.paragraph(Loc.t("ui.infirmary.text"), 17, Palette.PARCHMENT))
	body.add_child(Icons.with_text("STAT", &"hp", Loc.t("ui.health.hp", {"n": HealthRules.hp(run, data), "of": HealthRules.max_hp(run, data)}), 30, 20))
	body.add_child(Icons.with_text("STAT", &"sanity", Loc.t("ui.health.sanity", {"n": HealthRules.sanity(run, data), "of": HealthRules.max_sanity(run, data)}), 30, 20))
	var problem := HealthRules.can_treat(run, data)
	var b := Icons.button("RESOURCE", &"money", Loc.t("ui.infirmary.treat", {"n": HealthRules.treat_cost(run, data)}), 20)
	b.disabled = problem != ""
	b.tooltip_text = problem
	b.pressed.connect(_treat)
	body.add_child(b)
	if problem != "":
		message.text = problem


func _treat() -> void:
	var problem := GameState.treat()
	if problem != "":
		message.text = problem
		UiKit.sound(&"ui.error")
		return
	UiKit.sound(&"ui.confirm")
	show_done(Loc.t("ui.infirmary.done"))
