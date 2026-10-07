extends Control
## First scene: content is already loaded by ContentDB. Broken content -> error list, never the game.

const MAIN_MENU := "res://scenes/menu/main_menu.tscn"


func _ready() -> void:
	theme = UiKit.theme()
	if ContentDB.is_ok():
		get_tree().change_scene_to_file.call_deferred(MAIN_MENU)
		return
	_show_errors(ContentDB.errors)


func _show_errors(errors: PackedStringArray) -> void:
	var bg := ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 60
	box.offset_top = 50
	box.offset_right = -60
	add_child(box)
	box.add_child(UiKit.label("Content errors — fix data/ and restart", 32, Palette.BLOOD))
	box.add_child(UiKit.paragraph("\n".join(errors), 18, Palette.PARCHMENT))
