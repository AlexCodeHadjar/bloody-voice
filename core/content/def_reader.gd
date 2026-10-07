class_name DefReader
extends RefCounted
## Typed, checked reads from JSON dictionaries. Every problem goes to the ErrorLog with its location,
## and a safe default is returned so loading can continue and report ALL problems at once.


static func string(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool = true) -> String:
	if not d.has(key):
		if required:
			errs.add(where, "missing '%s'" % key)
		return ""
	if typeof(d[key]) != TYPE_STRING:
		errs.add(where, "'%s' must be a string" % key)
		return ""
	return d[key]


static func id(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool = true) -> StringName:
	return StringName(string(d, key, errs, where, required))


static func number(d: Dictionary, key: String, errs: ErrorLog, where: String, default: float = 0.0, required: bool = true) -> float:
	if not d.has(key):
		if required:
			errs.add(where, "missing '%s'" % key)
		return default
	if typeof(d[key]) != TYPE_FLOAT and typeof(d[key]) != TYPE_INT:
		errs.add(where, "'%s' must be a number" % key)
		return default
	return float(d[key])


static func integer(d: Dictionary, key: String, errs: ErrorLog, where: String, default: int = 0, required: bool = true) -> int:
	return int(number(d, key, errs, where, float(default), required))


static func flag(d: Dictionary, key: String, default: bool = false) -> bool:
	return bool(d.get(key, default))


static func dict(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool = true) -> Dictionary:
	if not d.has(key):
		if required:
			errs.add(where, "missing '%s'" % key)
		return {}
	if typeof(d[key]) != TYPE_DICTIONARY:
		errs.add(where, "'%s' must be an object" % key)
		return {}
	return d[key]


static func array(d: Dictionary, key: String, errs: ErrorLog, where: String, required: bool = true) -> Array:
	if not d.has(key):
		if required:
			errs.add(where, "missing '%s'" % key)
		return []
	if typeof(d[key]) != TYPE_ARRAY:
		errs.add(where, "'%s' must be an array" % key)
		return []
	return d[key]


static func ids(d: Dictionary, key: String, errs: ErrorLog, where: String) -> Array[StringName]:
	var out: Array[StringName] = []
	for v: Variant in array(d, key, errs, where, false):
		out.append(StringName(str(v)))
	return out
