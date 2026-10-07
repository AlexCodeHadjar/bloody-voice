class_name StatBar
extends VBoxContainer
## Label + coloured bar (HP, Sanity, body part HP).

var _label: Label
var _bar: ProgressBar


## icon: a STAT icon id shown before the caption (&"" = none).
func setup(color: Color, width: float = 320.0, font_size: int = 17, icon: StringName = &"") -> StatBar:
	var head := HBoxContainer.new()
	add_child(head)
	if icon != &"":
		head.add_child(Icons.rect("STAT", icon, font_size + 9))
	_label = UiKit.label("", font_size)
	head.add_child(_label)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(width, 14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.add_theme_stylebox_override("background", bg)
	add_child(_bar)
	return self


func show_value(caption: String, value: int, max_value: int) -> void:
	_label.text = "%s  %d / %d" % [caption, maxi(value, 0), max_value]
	_bar.max_value = max_value
	_bar.value = maxi(value, 0)
