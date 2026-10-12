class_name WorkshopKit
extends RefCounted
## Shared bits of the workshop screen (GDD 23.1): names, pictures and cost rows of blueprints and stock items.
## Reads the run and content; never changes them.


static func item_name(id: StringName) -> String:
	var m := ContentDB.data.module(id)
	if m != null:
		return m.name
	var mech := ContentDB.data.mechanism(id)
	return mech.name if mech != null else str(id)


static func item_art(id: StringName) -> Texture2D:
	var m := ContentDB.data.module(id)
	return UiKit.texture(m.art_path()) if m != null else Icons.texture("MECHANISM", id)


## Name of a resource or a trophy.
static func stock_name(id: StringName) -> String:
	return Loc.or_default("resource.%s" % id, Loc.or_default("trophy.%s" % id, String(id).capitalize()))


static func stock_icon(id: StringName) -> StringName:
	return id if ContentDB.data.balance.workshop.resources.has(id) else &"trophy"


## Icons with «have / need» per cost entry; a missing amount is red. Trophies say their name.
static func cost_row(cost: Dictionary, size: int = 16) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ws := GameState.run.workshop
	for k: Variant in cost:
		var id := StringName(str(k))
		var need := int(cost[k])
		var have := ws.amount(id)
		var text := "%d/%d" % [have, need]
		if stock_icon(id) == &"trophy":
			text = "%s %s" % [stock_name(id), text]
		var color := Palette.ALARM if have < need else Palette.PARCHMENT
		var cell := Icons.with_text("RESOURCE", stock_icon(id), text, size + 10, size, color)
		cell.tooltip_text = stock_name(id)
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(cell)
	return row


## «I · II · III» with the reached tiers lit.
static func tier_text(tier: int) -> String:
	var marks: PackedStringArray = []
	for i: int in ModuleDef.MAX_TIER:
		marks.append(["I", "II", "III"][i] if i < tier else "·")
	return " ".join(marks)


## "Blood sample: <creature>" / "Pure sample: <creature>" (GDD 4.4).
static func sample_name(creature: StringName, pure: bool) -> String:
	var m := ContentDB.data.monster(creature)
	return Loc.t("ui.voice.pure_sample" if pure else "ui.voice.sample", {"name": m.name if m != null else String(creature)})
