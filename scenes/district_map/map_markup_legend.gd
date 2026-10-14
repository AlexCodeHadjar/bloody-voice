class_name MapMarkupLegend
extends RefCounted
## The F3 markup legend (owner 2026-10-14): a swatch of every colour the markup draws, what it means, and the controls.

const ROWS := [  ## [colour, locale key]
	[Color.RED, "ui.dev.legend_node"],
	[Color.CYAN, "ui.dev.legend_street"],
	[Color(1.0, 0.55, 0.1), "ui.dev.legend_rope"],
	[Color.WHITE, "ui.dev.legend_place"],
	[Color(0.75, 0.45, 1.0), "ui.dev.legend_resident"],
	[Color(0.4, 1.0, 0.4), "ui.dev.legend_zone"],
	[Color.MAGENTA, "ui.dev.legend_contour"],
	[Color(0.35, 0.6, 1.0), "ui.dev.legend_fog"],
	[Color.YELLOW, "ui.dev.legend_pick"],
]


static func build() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_box(Color(0.06, 0.05, 0.045, 0.9), Palette.BRASS))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	v.add_child(UiKit.label(Loc.t("ui.dev.legend_title"), 18, Palette.BRASS_LIGHT))
	for row: Array in ROWS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var swatch := ColorRect.new()
		swatch.color = row[0] as Color
		swatch.custom_minimum_size = Vector2(14, 14)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(swatch)
		h.add_child(UiKit.label(Loc.t(row[1] as String), 14, Palette.PARCHMENT))
		v.add_child(h)
	v.add_child(UiKit.label(Loc.t("ui.dev.legend_keys"), 14, Palette.FOG))
	return panel
