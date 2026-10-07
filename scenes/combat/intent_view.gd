class_name IntentView
extends PanelContainer
## A planned move of the creature, shown beside it (GDD 9.1).

const KIND_COLORS: Dictionary[StringName, Color] = {
	&"attack": Color("b03a2e"), &"defend": Color("6e7a8a"), &"fear": Color("6b4a8a"),
	&"debuff": Color("8a7a3a"), &"buff": Color("a05a2a"), &"heal": Color("4f7a4a"),
}


func setup(move: MonsterDef.MoveDef, cancelled: bool, upcoming: bool = false) -> void:
	custom_minimum_size = Vector2(230, 0)
	var border: Color = KIND_COLORS.get(move.kind, Palette.BRASS)
	add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.1, 0.08, 0.07, 0.92), border))
	modulate = Color(1, 1, 1, 0.45) if cancelled or upcoming else Color.WHITE
	var v := VBoxContainer.new()
	add_child(v)
	var head := ("Next: " if upcoming else "") + move.name + ("  (cancelled)" if cancelled else "")
	v.add_child(UiKit.label(head, 20, border.lightened(0.35)))
	v.add_child(UiKit.label(String(move.kind).capitalize(), 14, Palette.INK_MUTED))
	v.add_child(UiKit.paragraph(move.text, 16, Palette.PARCHMENT))
