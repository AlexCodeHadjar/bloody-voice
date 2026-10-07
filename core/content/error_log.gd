class_name ErrorLog
extends RefCounted
## Collects content problems with their location. Passed by reference into loaders and validators
## (PackedStringArray is copied on assignment, so it can't be used for this).

var messages: PackedStringArray = []


func add(where: String, message: String) -> void:
	messages.append("%s: %s" % [where, message])


func is_empty() -> bool:
	return messages.is_empty()
