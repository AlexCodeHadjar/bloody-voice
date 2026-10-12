class_name ResultPanel
extends CenterContainer
## The end-of-fight panel: outcome, the creature's cracked silhouette on a kill, turns, trophies, resources and new
## blueprints, the blood sample, the Beast taking over, the contract reward, back to the district.

signal back_pressed


func show_result(s: CombatState) -> void:
	if visible:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # a root made in code: fill the screen
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
	_add_loot_lines(v, s)
	_add_sample_line(v, s)
	_add_xp_line(v, s)
	if GameState.lost_control(s.outcome()):  # the Voice's third stage (GameState.finish_combat adds the day)
		v.add_child(UiKit.paragraph(Loc.t("ui.voice.lost_control"), 18, Palette.ALARM))
	if s.outcome() == &"fallen":  # the Hunter's Fall (GameState.finish_combat)
		v.add_child(UiKit.paragraph(Loc.t("ui.combat.fall", {"n": ContentDB.data.balance.health.fall_fee}), 18, Palette.ALARM))
	_add_contract_line(v, s)
	_add_standing_lines(v, s)
	var back := UiKit.button(Loc.t("ui.combat.back"))
	back.pressed.connect(back_pressed.emit)
	v.add_child(back)


## Resources and the blueprints the trophies teach (taken on «back to the district», GameState.finish_combat).
func _add_loot_lines(v: VBoxContainer, s: CombatState) -> void:
	var loot := LootRules.fight_loot(ContentDB.data, s)
	if loot.resources.is_empty():
		return
	var parts: PackedStringArray = []
	for k: StringName in loot.resources:
		parts.append("%s +%d" % [WorkshopKit.stock_name(k), loot.resources[k]])
	v.add_child(Icons.with_text("RESOURCE", &"scrap", Loc.t("ui.combat.loot", {"list": ", ".join(parts)}), 30, 20))
	for id: StringName in LootRules.preview_blueprints(GameState.run, ContentDB.data, loot):
		v.add_child(Icons.with_text("DIRECTION", &"modules", Loc.t("ui.combat.new_blueprint", {"name": WorkshopKit.item_name(id)}), 30, 20, Palette.BRASS_LIGHT))


## The creature's blood sample (a pure one from a capture) for the Monster web.
func _add_sample_line(v: VBoxContainer, s: CombatState) -> void:
	var loot := LootRules.fight_loot(ContentDB.data, s)
	for pure: bool in [false, true]:
		var pool: Dictionary[StringName, int] = loot.pure_samples if pure else loot.samples
		for c: StringName in pool:
			v.add_child(Icons.with_text("STAT", &"voice", Loc.t("ui.combat.sample", {"name": WorkshopKit.sample_name(c, pure)}), 30, 20, Palette.BRASS_LIGHT))


## XP the win brings (taken on «back to the district») and a level-up if it reaches one.
func _add_xp_line(v: VBoxContainer, s: CombatState) -> void:
	var data := ContentDB.data
	var c := GameState.run.contracts.find(s.contract_uid)
	var xp := ProgressRules.fight_xp(data, s) + (data.balance.progress.contract_xp if ContractRules.reward_for(c, s.outcome()) > 0 else 0)
	xp += RegisterRules.exam_xp(data, c, s.outcome())
	if xp <= 0:
		return
	v.add_child(Icons.with_text("STAT", &"xp", Loc.t("ui.progress.xp_gain", {"n": xp}), 30, 20))
	if ProgressRules.levels_from(GameState.run, data, xp) > 0:
		v.add_child(UiKit.label(Loc.t("ui.progress.level_up"), 24, Palette.BRASS_LIGHT))


## The contract this fight counted for: paid on «back to the district» (GameState.finish_combat), or still open.
func _add_contract_line(v: VBoxContainer, s: CombatState) -> void:
	var c := GameState.run.contracts.find(s.contract_uid)
	if c == null:
		return
	var paid := ContractRules.reward_for(c, s.outcome())
	if paid > 0:
		v.add_child(Icons.with_text("RESOURCE", &"money", Loc.t("ui.combat.contract_done", {"n": paid}), 30, 20, Palette.BRASS_LIGHT))
	else:
		v.add_child(UiKit.label(Loc.t("ui.combat.contract_open"), 18, Palette.FOG))


## New Bestiary marks, reputation changes and a passed Register exam (taken on «back to the district»).
func _add_standing_lines(v: VBoxContainer, s: CombatState) -> void:
	var data := ContentDB.data
	var marks: PackedStringArray = []
	for k: StringName in BestiaryRules.fight_marks(GameState.run, s):
		marks.append(Loc.t("ui.bestiary.mark.%s" % k))
	if not marks.is_empty():
		v.add_child(Icons.with_text("UI", &"bestiary", Loc.t("ui.bestiary.new_marks", {"list": ", ".join(marks)}), 30, 18))
	var c := GameState.run.contracts.find(s.contract_uid)
	var changes := FactionRules.fight_changes(data, c, s.outcome())
	for f: StringName in changes:
		var fd := data.faction(f)
		v.add_child(Icons.with_text("FACTION", f, "%s %+d" % [fd.name if fd != null else String(f), changes[f]], 30, 18,
			Palette.BRASS_LIGHT if changes[f] > 0 else Palette.ALARM))
	if RegisterRules.exam_xp(data, c, s.outcome()) > 0:
		var letter := RegisterRules.rank_letter(data, GameState.run.standing.rank + 1)
		v.add_child(UiKit.label(Loc.t("ui.register.passed", {"rank": letter}), 24, Palette.BRASS_LIGHT))
