class_name StoryRules
extends RefCounted
## The Grey Chapels story (GDD 2.4, owner 2026-10-12: «the mystery of the Grey Communion», a prologue and 3 story
## contracts without deadlines, told by letters and notes). A step is a story contract taken at once (no slot, not on
## the board, never overdue, can't be given up); finishing it brings its note and starts the next step. The last
## note offers a choice (reputation); then the end letter closes the chapter.

const NO_DEADLINE := 1 << 30


## A run that never had the story (a new game, an old save) gets the prologue's contract and letter.
static func ensure_start(run: RunState, data: ContentData) -> bool:
	if run.story.started or data.story == null or data.story.steps.is_empty():
		return false
	run.story.started = true
	_start_step(run, data, 0)
	return true


static func _start_step(run: RunState, data: ContentData, i: int) -> void:
	var s := data.story.steps[i]
	var c := ContractsState.Contract.new()
	c.uid = run.contracts.next_uid
	run.contracts.next_uid += 1
	c.monster = s.monster
	c.type = s.type
	c.petition = s.petition
	c.zone = s.zone
	var tags := data.monster(s.monster).tags
	c.known_tags.assign(tags.slice(0, mini(2, tags.size())))
	c.deadline_day = NO_DEADLINE  # sorts last among open contracts; ContractRules.has_deadline says it has none
	c.week = -1  # never on a weekly board
	c.reward = s.reward
	c.accepted = true
	c.story = s.id
	run.contracts.items.append(c)
	run.story.letters.append("step:%s" % s.id)


## A finished story contract: its note, then the next step (or, after the last, the choice or the end). True when it
## was a story contract.
static func step_done(run: RunState, data: ContentData, c: ContractsState.Contract) -> bool:
	if c == null or c.story == &"" or data.story == null or run.story.done.has(c.story):
		return false
	run.story.done.append(c.story)
	run.story.letters.append("after:%s" % c.story)
	var i := data.story.index_of(c.story)
	if i + 1 < data.story.steps.size():
		_start_step(run, data, i + 1)
	elif data.story.steps[i].choices.is_empty():
		_finish(run)
	return true


## The step whose note waits for the hunter's choice (null if none).
static func pending_choice(run: RunState, data: ContentData) -> StoryDefs.StepDef:
	if data.story == null or run.story.finished or run.story.choice != &"":
		return null
	var last := data.story.steps[-1]
	return last if run.story.done.has(last.id) and not last.choices.is_empty() else null


## The hunter's choice at the end: its reputation changes, then the end letter. "" or why not.
static func choose(run: RunState, data: ContentData, choice_id: StringName) -> String:
	var step := pending_choice(run, data)
	if step == null:
		return Loc.t("rule.story.no_choice")
	for c: StoryDefs.ChoiceDef in step.choices:
		if c.id == choice_id:
			FactionRules.apply(run, c.rep)
			run.story.choice = choice_id
			_finish(run)
			return ""
	return Loc.t("rule.story.no_choice")


static func _finish(run: RunState) -> void:
	run.story.finished = true
	run.story.letters.append("end")


static func next_letter(run: RunState) -> String:
	return run.story.letters[0] if not run.story.letters.is_empty() else ""


## Reads the oldest letter; a note that waits for a choice stays until the choice is made.
static func read_letter(run: RunState, data: ContentData) -> void:
	var l := next_letter(run)
	if l == "":
		return
	var step := pending_choice(run, data)
	if step != null and l == "after:%s" % step.id:
		return
	run.story.letters.remove_at(0)
