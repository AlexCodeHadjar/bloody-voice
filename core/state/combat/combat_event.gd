class_name CombatEvent
extends RefCounted
## One line of the fight log. Screens read new events to animate and to show the log.

var kind: StringName
var text: String
var amount: int = 0
var subject: StringName = &""  ## hero / enemy / part id


static func create(kind_value: StringName, text_value: String, amount_value: int = 0, subject_value: StringName = &"") -> CombatEvent:
	var e := CombatEvent.new()
	e.kind = kind_value
	e.text = text_value
	e.amount = amount_value
	e.subject = subject_value
	return e
