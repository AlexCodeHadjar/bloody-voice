class_name StoryDefs
extends RefCounted
## The district story (GDD 2.4): data/story/grey.json — steps in order, each a story contract whose letter is a
## petition (contracts/petitions.json) and whose note comes once it is done; the last note offers choices.


class ChoiceDef:
	var id: StringName
	var text: String
	var rep: Dictionary[StringName, int] = {}  ## reputation changes (GDD 12)


class StepDef:
	var id: StringName
	var petition: StringName  ## the letter that starts it
	var monster: StringName
	var type: StringName  ## slay / capture
	var zone: StringName  ## where the creature was last seen
	var reward: int
	var portrait: StringName  ## art/ui/NPC__portrait__<portrait>.webp on its letters
	var after_from: String  ## the note once it is done
	var after_text: String
	var choices: Array[ChoiceDef] = []


class StoryDef:
	var chapter: StringName
	var steps: Array[StepDef] = []
	var end_from: String
	var end_text: String
	var end_xp: int = 0

	func step(id: StringName) -> StepDef:
		for s: StepDef in steps:
			if s.id == id:
				return s
		return null

	func index_of(id: StringName) -> int:
		for i: int in steps.size():
			if steps[i].id == id:
				return i
		return -1


static func story(d: Dictionary, errs: ErrorLog) -> StoryDef:
	var st := StoryDef.new()
	var w := "story/grey.json"
	st.chapter = DefReader.id(d, "chapter", errs, w)
	for v: Variant in DefReader.array(d, "steps", errs, w):
		st.steps.append(_step(v as Dictionary, errs))
	var end := DefReader.dict(d, "end", errs, w)
	st.end_from = DefReader.string(end, "from", errs, w + "/end")
	st.end_text = DefReader.string(end, "text", errs, w + "/end")
	st.end_xp = DefReader.integer(d, "end_xp", errs, w)
	return st


static func _step(d: Dictionary, errs: ErrorLog) -> StepDef:
	var s := StepDef.new()
	s.id = DefReader.id(d, "id", errs, "story/grey.json/steps")
	var w := "story/grey.json/%s" % s.id
	s.petition = DefReader.id(d, "petition", errs, w)
	s.monster = DefReader.id(d, "monster", errs, w)
	s.type = DefReader.id(d, "type", errs, w)
	s.zone = DefReader.id(d, "zone", errs, w)
	s.reward = DefReader.integer(d, "reward", errs, w)
	s.portrait = DefReader.id(d, "portrait", errs, w)
	var after := DefReader.dict(d, "after", errs, w)
	s.after_from = DefReader.string(after, "from", errs, w + "/after")
	s.after_text = DefReader.string(after, "text", errs, w + "/after")
	for v: Variant in DefReader.array(d, "choices", errs, w, false):
		var c := ChoiceDef.new()
		var cd := v as Dictionary
		c.id = DefReader.id(cd, "id", errs, w + "/choices")
		c.text = DefReader.string(cd, "text", errs, w + "/choices")
		c.rep = WorkshopDefs.amounts(DefReader.dict(cd, "rep", errs, w + "/choices"))
		s.choices.append(c)
	return s
