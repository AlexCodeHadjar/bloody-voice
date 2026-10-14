class_name MapMarkupLegend
extends RefCounted
## The F3 markup legend and filter (owner 2026-10-14): every layer with its colour, what it means and a tick that
## shows or hides it (hidden points cannot be picked either); every zone in its own colour with its name; the
## controls. `on_change` is called after a tick changes.

const ROWS := [  ## [layer, colour, locale key]
	[&"streets", MapMarkupDraw.STREET, "ui.dev.legend_streets"],
	[&"names", MapMarkupDraw.PICK, "ui.dev.legend_names"],
	[&"places", MapMarkupDraw.PLACE, "ui.dev.legend_place"],
	[&"residents", MapMarkupDraw.RESIDENT, "ui.dev.legend_resident"],
	[&"contour", MapMarkupDraw.CONTOUR, "ui.dev.legend_contour"],
	[&"fog", MapMarkupDraw.FOG, "ui.dev.legend_fog"],
]


static func build(ed: MapMarkupEditor, on_change: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.92), Palette.BRASS))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.dev.legend_title"), 18, Palette.BRASS_LIGHT))
	var ticks: Array[CheckBox] = []
	for row: Array in ROWS:
		ticks.append(_row(v, ed, row[0] as StringName, row[1] as Color, Loc.t(row[2] as String), on_change))
	v.add_child(UiKit.label(Loc.t("ui.dev.legend_zones"), 16, Palette.BRASS_LIGHT))
	for z: DistrictMapDef.ZoneDef in ed.map.zones:
		ticks.append(_row(v, ed, StringName("zone:" + z.id), MapMarkupDraw.zone_color(ed.map, z.id), z.name, on_change))
	var h := HBoxContainer.new()
	for all: bool in [true, false]:
		var b := Button.new()
		b.text = Loc.t("ui.dev.show_all" if all else "ui.dev.show_none")
		b.pressed.connect(func() -> void:
			for t: CheckBox in ticks:
				t.button_pressed = all)
		h.add_child(b)
	v.add_child(h)
	v.add_child(_swatch_line(MapMarkupDraw.PICK, Loc.t("ui.dev.legend_pick")))
	v.add_child(UiKit.label(Loc.t("ui.dev.legend_keys"), 14, Palette.FOG))
	return panel


static func _row(v: VBoxContainer, ed: MapMarkupEditor, layer: StringName, col: Color, text: String, on_change: Callable) -> CheckBox:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var tick := CheckBox.new()
	tick.button_pressed = ed.shown(layer)
	tick.toggled.connect(func(on: bool) -> void:
		ed.layers[layer] = on
		on_change.call())
	h.add_child(tick)
	h.add_child(_swatch_line(col, text))
	v.add_child(h)
	return tick


static func _swatch_line(col: Color, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var swatch := ColorRect.new()
	swatch.color = col
	swatch.custom_minimum_size = Vector2(14, 14)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(swatch)
	h.add_child(UiKit.label(text, 14, Palette.PARCHMENT))
	return h
