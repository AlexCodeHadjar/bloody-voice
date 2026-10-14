class_name JsonLayout
extends RefCounted
## Writes JSON in the hand layout of the data files (F3 markup saves, owner 2026-10-14): one key per line at the top,
## lists of objects and big objects one entry per line, everything else inline with ", " and ": ";
## whole numbers without ".0"; one space of indent per level. Reading and writing a data file gives the same text.

const BIG := 8  ## an object of more points than this goes one entry per line (the street nodes)


static func format(v: Variant) -> String:
	return _value(v, 0) + "\n"


static func _value(v: Variant, depth: int) -> String:
	if v is Dictionary:
		var d: Dictionary = v
		return _dict_lines(d, depth) if depth == 0 or _multiline(d) else _dict_inline(d)
	if v is Array:
		var a: Array = v
		return _array_lines(a, depth) if _multiline(a) else _array_inline(a)
	if v is float and is_equal_approx(v as float, roundf(v as float)) and absf(v as float) < 1e15:
		return str(int(v as float))
	return JSON.stringify(v)


static func _multiline(v: Variant) -> bool:
	if v is Array:
		var a: Array = v
		return not a.is_empty() and a.all(func(x: Variant) -> bool: return x is Dictionary)
	var d: Dictionary = v
	if d.size() > BIG and d.values().all(func(x: Variant) -> bool: return x is Array):
		return true
	for x: Variant in d.values():
		if (x is Array or x is Dictionary) and _multiline(x):
			return true
	return false


static func _dict_inline(d: Dictionary) -> String:
	var parts := PackedStringArray()
	for k: Variant in d:
		parts.append("%s: %s" % [JSON.stringify(str(k)), _value(d[k], 99)])
	return "{" + ", ".join(parts) + "}"


static func _array_inline(a: Array) -> String:
	var parts := PackedStringArray()
	for x: Variant in a:
		parts.append(_value(x, 99))
	return "[" + ", ".join(parts) + "]"


static func _dict_lines(d: Dictionary, depth: int) -> String:
	var pad := " ".repeat(depth + 1)
	var parts := PackedStringArray()
	for k: Variant in d:
		parts.append(pad + "%s: %s" % [JSON.stringify(str(k)), _value(d[k], depth + 1)])
	return "{\n" + ",\n".join(parts) + "\n" + " ".repeat(depth) + "}"


static func _array_lines(a: Array, depth: int) -> String:
	var pad := " ".repeat(depth + 1)
	var parts := PackedStringArray()
	for x: Variant in a:
		parts.append(pad + _value(x, depth + 1))
	return "[\n" + ",\n".join(parts) + "\n" + " ".repeat(depth) + "]"
