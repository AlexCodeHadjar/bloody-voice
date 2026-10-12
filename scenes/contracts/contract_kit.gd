class_name ContractKit
extends RefCounted
## Shared bits of the contract screens (GDD 7): texts and small widgets for the board, the tablet and the tracker.
## Reads the run and content; never changes them.


static func monster_name(c: ContractsState.Contract) -> String:
	var m := ContentDB.data.monster(c.monster)
	return m.name if m != null else str(c.monster)


static func rank(c: ContractsState.Contract) -> String:
	var m := ContentDB.data.monster(c.monster)
	return m.rank if m != null else ""


static func type_name(c: ContractsState.Contract) -> String:
	return Loc.t("ui.contract.type.%s" % c.type)


static func silhouette(c: ContractsState.Contract) -> Texture2D:
	var m := ContentDB.data.monster(c.monster)
	return UiKit.texture(m.art_path("silhouette", "leaflet")) if m != null else null


## "через 3 дня" / "последний день" / "просрочен — тварь сильнее".
static func deadline_text(c: ContractsState.Contract) -> String:
	var day := GameState.run.day
	if ContractRules.is_overdue(c, day):
		return Loc.t("ui.contract.overdue")
	var left := ContractRules.days_left(c, day)
	return Loc.t("ui.contract.last_day") if left == 0 else Loc.t("ui.contract.days_left", {"n": left})


static func deadline_color(c: ContractsState.Contract, normal: Color) -> Color:
	return Palette.ALARM if ContractRules.is_overdue(c, GameState.run.day) else normal


## Name of the zone where the creature was last seen, with the district.
static func last_seen(c: ContractsState.Contract) -> String:
	var district := GameState.run.hero_district
	var d := ContentDB.data.district(district)
	var zone := zone_name(ContentDB.data.district_map(district), c.zone)
	var dname := d.name if d != null else str(district)
	return dname if zone == "" else "%s, %s" % [zone, dname]


static func zone_name(map: DistrictMapDef, zone: StringName) -> String:
	if map == null:
		return ""
	for z: DistrictMapDef.ZoneDef in map.zones:
		if z.id == zone:
			return z.name
	return ""


static func tag_name(tag: StringName) -> String:
	var t := ContentDB.data.tag(tag)
	return t.name if t != null else str(tag)


static func tag_category(tag: StringName) -> StringName:
	var t := ContentDB.data.tag(tag)
	return t.category if t != null else &""


static func picture(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = size
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
