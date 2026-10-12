extends TestSuite
## The Grey Chapels story (GDD 2.4): the prologue starts at once, story contracts take no slot and have no deadline,
## finishing one brings its note and the next step, the last note asks for a choice, saves.


func _run(data: ContentData) -> RunState:
	var run := RunState.create(51, data.balance)
	WorkshopRules.ensure_start(run, data)
	ProgressRules.ensure_start(run, data)
	return run


func _story_contract(run: RunState) -> ContractsState.Contract:
	for c: ContractsState.Contract in run.contracts.items:
		if c.story != &"" and not c.done:
			return c
	return null


func test_prologue_starts_once() -> void:
	var data := load_content(false)
	var run := _run(data)
	check(StoryRules.ensure_start(run, data), "the story starts")
	check(not StoryRules.ensure_start(run, data), "only once")
	var c := _story_contract(run)
	eq(c.story, data.story.steps[0].id, "the prologue's contract")
	check(c.accepted, "taken at once")
	eq(StoryRules.next_letter(run), "step:%s" % c.story, "its letter waits")
	check(not ContractRules.is_overdue(c, run.day + 500), "no deadline")
	check(ContractRules.can_abandon(run.contracts, c.uid) != "", "can't be given up")
	eq(ContractRules.board(run.contracts).has(c), false, "not on the board")


func test_story_contracts_take_no_slot() -> void:
	var data := load_content(false)
	var run := _run(data)
	StoryRules.ensure_start(run, data)
	ContractRules.refresh_board(run, data, SeededRng.make_stream(51, &"contracts", 1))
	var taken := 0
	for c: ContractsState.Contract in ContractRules.board(run.contracts):
		if ContractRules.accept(run.contracts, data, c.uid) == "":
			taken += 1
	eq(taken, mini(data.balance.contracts.max_active, ContractRules.board(run.contracts).size()), "all slots free for side contracts")
	check(_story_contract(run) != null, "the story contract is still open")


func test_steps_follow_and_the_end_asks_for_a_choice() -> void:
	var data := load_content(false)
	var run := _run(data)
	StoryRules.ensure_start(run, data)
	for i: int in data.story.steps.size():
		var c := _story_contract(run)
		eq(c.story, data.story.steps[i].id, "step %d" % i)
		check(ContractRules.resolve_fight(run, c.uid, &"captured") > 0, "a capture finishes slay and capture steps")
		check(StoryRules.step_done(run, data, c), "step done")
		check(run.story.letters.has("after:%s" % c.story), "its note")
	check(_story_contract(run) == null, "no more story contracts")
	var last := data.story.steps[-1]
	eq(StoryRules.pending_choice(run, data), last, "the last note asks")
	run.story.letters.assign(["after:%s" % last.id])
	StoryRules.read_letter(run, data)
	eq(StoryRules.next_letter(run), "after:%s" % last.id, "the asking note stays until answered")
	var vigil_before := run.standing.rep(&"vigil")
	eq(StoryRules.choose(run, data, last.choices[0].id), "", "chosen")
	check(run.standing.rep(&"vigil") != vigil_before or run.standing.rep(&"grey_communion") != 0, "reputation moved")
	check(run.story.finished and run.story.letters.has("end"), "the end letter")
	check(StoryRules.choose(run, data, last.choices[1].id) != "", "no second choice")


func test_story_survives_save_and_v15_starts_on_load() -> void:
	var data := load_content(false)
	var run := _run(data)
	StoryRules.ensure_start(run, data)
	var parsed: Variant = JSON.parse_string(JSON.stringify(run.to_dict()))
	var back := RunState.from_dict(SaveMigrations.migrate(parsed as Dictionary))
	check(back.story.started, "started kept")
	eq(back.story.letters, run.story.letters, "letters kept")
	check(_story_contract(back) != null, "the story contract kept")
	var old := RunState.from_dict(SaveMigrations.migrate({"version": 15, "master_seed": 2}))
	check(not old.story.started, "v15: not started")
	check(StoryRules.ensure_start(old, data), "the prologue comes on load")
