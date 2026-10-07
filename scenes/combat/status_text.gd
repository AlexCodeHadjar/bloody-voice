class_name StatusText
extends RefCounted
## Human-readable status line, e.g. "Weak 2 · Bleed 3".


static func of(c: Combatant) -> String:
	var parts: PackedStringArray = []
	for s: StringName in c.statuses:
		parts.append("%s %d" % [String(s).capitalize(), c.statuses[s]])
	return " · ".join(parts)
