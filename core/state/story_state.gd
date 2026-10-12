class_name StoryState
extends RefCounted
## The district story (GDD 2.4): started, the steps done, the final choice and the letters the hunter has not read
## yet ("step:<id>" a new story contract's letter, "after:<id>" its note, "end"). Saved. StoryRules changes it.

var started: bool = false
var done: Array[StringName] = []
var choice: StringName = &""
var finished: bool = false
var letters: Array[String] = []


func to_dict() -> Dictionary:
	return {"started": started, "done": done.duplicate(), "choice": choice, "finished": finished, "letters": letters.duplicate()}


static func from_dict(d: Dictionary) -> StoryState:
	var s := StoryState.new()
	s.started = bool(d.get("started", false))
	s.done = ContractsState.names(d.get("done", []) as Array)
	s.choice = StringName(str(d.get("choice", "")))
	s.finished = bool(d.get("finished", false))
	for v: Variant in d.get("letters", []) as Array:
		s.letters.append(str(v))
	return s
