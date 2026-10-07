class_name ContentLoader
extends RefCounted
## Reads data/*.json into a ContentData. Never stops at the first problem: everything goes to the ErrorLog.

const BALANCE := "balance.json"
const DISTRICTS := "city/districts.json"
const DISTRICT_STATES := "city/district_states.json"
const MAP_REGIONS := "city/map_regions.json"


static func load_all(root: String, errs: ErrorLog) -> ContentData:
	var data := ContentData.new()
	data.balance = BalanceDef.from_dict(read_object(root.path_join(BALANCE), errs), errs)
	for d: Variant in read_array(root.path_join(DISTRICTS), errs):
		var def := DistrictDef.from_dict(d as Dictionary, errs)
		if data.districts.has(def.id):
			errs.add(DISTRICTS, "duplicate district id '%s'" % def.id)
		data.districts[def.id] = def
		data.district_order.append(def.id)
	var states := read_object(root.path_join(DISTRICT_STATES), errs)
	for key: Variant in states:
		if str(key).begins_with("_"):
			continue
		var sid := StringName(str(key))
		data.district_states[sid] = DistrictStateDef.from_dict(sid, states[key] as Dictionary, errs)
	data.map_regions = MapRegionsDef.from_dict(read_object(root.path_join(MAP_REGIONS), errs), errs)
	return data


static func read_json(path: String, errs: ErrorLog) -> Variant:
	if not FileAccess.file_exists(path):
		errs.add(path, "file not found")
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		errs.add(path, "JSON error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	return json.data


static func read_object(path: String, errs: ErrorLog) -> Dictionary:
	var v: Variant = read_json(path, errs)
	if v != null and typeof(v) != TYPE_DICTIONARY:
		errs.add(path, "top level must be an object")
	return v if typeof(v) == TYPE_DICTIONARY else {}


static func read_array(path: String, errs: ErrorLog) -> Array:
	var v: Variant = read_json(path, errs)
	if v != null and typeof(v) != TYPE_ARRAY:
		errs.add(path, "top level must be an array")
	return v if typeof(v) == TYPE_ARRAY else []
