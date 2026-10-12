class_name ResultPanel
extends CenterContainer
## The end-of-fight panel: outcome, the creature's cracked silhouette on a kill, turns, trophies, back to the district.

signal back_pressed


func show_result(s: CombatState) -> void:
	if visible:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = true
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.05, 0.96), Palette.BRASS_LIGHT))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UiKit.label(Loc.or_default("ui.combat.outcome.%s" % s.outcome(), Loc.t("ui.combat.over")), 36, Palette.BRASS_LIGHT))
	if s.outcome() == &"slain" or s.outcome() == &"captured":
		var seal := TextureRect.new()  # the creature's silhouette, cracked: struck from the leaflets
		seal.texture = UiKit.texture(s.enemy.def.art_path("silhouette", "cracked"))
		seal.custom_minimum_size = Vector2(0, 240)
		seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(seal)
	var trophies := ", ".join(PackedStringArray(s.trophies.map(func(t: StringName) -> String: return Loc.or_default("trophy.%s" % t, String(t).capitalize()))))
	v.add_child(UiKit.label(Loc.t("ui.combat.summary", {"turns": s.turn, "hp": maxi(s.hero.hp, 0)}), 20))
	v.add_child(Icons.with_text("RESOURCE", &"trophy", Loc.t("ui.combat.trophies", {"list": trophies if trophies != "" else Loc.t("ui.combat.none")}), 30, 20))
	var back := UiKit.button(Loc.t("ui.combat.back"))
	back.pressed.connect(back_pressed.emit)
	v.add_child(back)
