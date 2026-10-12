class_name RumorLayer
extends Node2D
## Rumor diamonds on the district map (GDD 8, owner 2026-10-12): one brass diamond per rumor at its street node,
## a soft pulse, the hovered picture under the mouse. A click reports the rumor; the screen walks the hero there.

signal rumor_clicked(uid: int)

const SIZE := 150.0  ## art px
const IDLE := "res://art/ui/RUMOR__diamond__idle.webp"
const HOVERED := "res://art/ui/RUMOR__diamond__hovered.webp"

var _map: DistrictMapDef


func setup(map: DistrictMapDef) -> void:
	_map = map
	EventBus.rumors_changed.connect(refresh)
	EventBus.day_changed.connect(func(_d: int) -> void: refresh())
	refresh()


func refresh() -> void:
	for child: Node in get_children():
		child.queue_free()
	for r: RumorsState.Rumor in RumorRules.visible(GameState.run.rumors):
		add_child(_diamond(r))


func _diamond(r: RumorsState.Rumor) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = UiKit.texture(IDLE)
	b.texture_hover = UiKit.texture(HOVERED)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = Vector2(SIZE, SIZE)
	b.pivot_offset = b.size * 0.5
	b.position = _map.node_pos(r.node) - Vector2(SIZE * 0.5, SIZE * 0.85)  # the diamond floats above the street
	b.tooltip_text = Loc.t("ui.rumor.diamond_tip", {"zone": ContractKit.zone_name(_map, r.zone),
		"n": r.expires_day - GameState.run.day})
	b.mouse_entered.connect(func() -> void: UiKit.sound(&"ui.hover"))
	b.pressed.connect(func() -> void:
		UiKit.sound(&"ui.click")
		rumor_clicked.emit(r.uid))
	var tw := b.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "scale", Vector2.ONE * 1.08, 0.9)
	tw.tween_property(b, "scale", Vector2.ONE, 0.9)
	return b
