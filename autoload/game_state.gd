extends "res://autoload/game_state_core.gd"
## Facade between the screens and the game rules (GDD 19.3): the place and day actions — contracts, rumors, the
## workshop, the shop, the tavern, health, the Scriptorium, progression. The run, days, gear and fights are in
## game_state_core.gd. Screens call these commands; only this node changes RunState, through rules, then emits signals.


## Free action (GDD 3.3): take a leaflet from the tavern board; rumors of its zone can now lead to its creature
## (GDD 8.4). "" or the reason it can't be taken.
func accept_contract(uid: int) -> String:
	if run == null:
		return Loc.t("rule.not_now")
	var problem := ContractRules.accept(run.contracts, ContentDB.data, uid)
	if problem == "":
		BestiaryRules.mark(run, run.contracts.find(uid).monster, &"seen")
		EventBus.contracts_changed.emit()
		EventBus.progress_changed.emit()
		save_game()
	return problem


## Gives a taken contract up: its slot frees, its petitioner's faction frowns (owner, 2026-10-12). "" or why not.
func abandon_contract(uid: int) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var changes := FactionRules.abandon_changes(ContentDB.data, run.contracts.find(uid))
	var problem := ContractRules.abandon(run.contracts, uid)
	if problem == "":
		FactionRules.apply(run, changes)
		EventBus.contracts_changed.emit()
		EventBus.progress_changed.emit()
		save_game()
	return problem


## Workshop (GDD 6.2): craft from a known blueprint. "" or the reason it can't be done.
func craft_item(item: StringName) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	return _workshop_result(WorkshopRules.craft(run, ContentDB.data, item))


## Raises one copy of the module from `tier` to the next.
func upgrade_module(module: StringName, tier: int) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	return _workshop_result(WorkshopRules.upgrade(run, ContentDB.data, module, tier))


## Takes a spare item (a module copy of that tier) apart for half its resources (free, no day spent).
func salvage_item(item: StringName, tier: int = 1) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	return _workshop_result(WorkshopRules.salvage(run, ContentDB.data, item, tier))


## Leaving the workshop ends a workshop day that was started today.
func leave_workshop() -> void:
	if run != null and combat == null and WorkshopRules.leave(run):
		end_day()


func _workshop_result(problem: String) -> String:
	if problem == "":
		EventBus.stock_changed.emit()
		_loadout_changed()
	return problem


## Walking through a zone (GDD 8.4): the screen rolls every overhear_steps footsteps; a new card or null. Free.
func overhear_rumor(zone: StringName) -> RumorsState.Card:
	if run == null or combat != null:
		return null
	var card := RumorRules.overhear(run, ContentDB.data, zone,
		Rng.stream(StringName("overhear_%d" % run.rumors.rolls), run.day))
	if card != null:
		EventBus.rumors_changed.emit()
		save_game()
	return card


## «Расспросить» in a place (the tavern): a few cards, once a day. Free. [] if not now.
func ask_rumors(place: StringName) -> Array[RumorsState.Card]:
	if run == null or combat != null:
		return []
	var cards := RumorRules.ask(run, ContentDB.data, place, Rng.stream(StringName("ask_%s" % place), run.day))
	if not cards.is_empty():
		EventBus.rumors_changed.emit()
		save_game()
	return cards


## A thread from a card's sign to a contract: it holds (the contract may learn the sign, the lair may appear) or snaps
## and the card burns. null if it can't be tied.
func link_rumor(card_uid: int, contract_uid: int, tag: StringName) -> RumorRules.Link:
	if run == null or combat != null:
		return null
	var l := RumorRules.link(run, ContentDB.data, card_uid, contract_uid, tag,
		Rng.stream(StringName("lair_%d" % contract_uid), run.day))
	if l != null:
		if l.learned != &"" or l.mark != null:
			EventBus.contracts_changed.emit()
		EventBus.rumors_changed.emit()
		save_game()
	return l


## Throws a card out of the notebook (not one on a thread). false if not.
func discard_rumor(uid: int) -> bool:
	if run == null or not RumorRules.discard(run, uid):
		return false
	EventBus.rumors_changed.emit()
	save_game()
	return true


## The notebook was opened: its new cards are seen.
func notebook_seen() -> void:
	if run != null and RumorRules.seen(run):
		EventBus.rumors_changed.emit()


## A click on a lair: the fight with the found creature on the zone's background (the day ends after it). false if
## there is no such lair.
func fight_mark(uid: int) -> bool:
	if run == null or combat != null:
		return false
	var m := RumorRules.engage(run, uid)
	if m == null:
		return false
	EventBus.rumors_changed.emit()
	_start_fight(m.monster, run.contracts.find(m.contract_uid), m.zone)
	return true


## Day action (GDD 3.3): a shift behind the bar: money and a line of gossip; the day ends. null if not now.
func work_shift() -> ShiftRules.Report:
	if run == null or combat != null or EventRules.is_closed(run, ContentDB.data, &"shift"):
		return null
	var report := ShiftRules.work(run, ContentDB.data, Rng.stream(&"shift", run.day))
	EventBus.money_changed.emit(run.money)
	end_day()
	return report


## Day action: rest at the garret (a third of HP and Sanity back).
func rest() -> void:
	if run == null or combat != null:
		return
	HealthRules.rest(run, ContentDB.data)
	end_day()


## Day action: the Ash Sisters heal fully for money. "" or the reason they won't.
func treat() -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := HealthRules.treat(run, ContentDB.data)
	if problem == "":
		EventBus.money_changed.emit(run.money)
		end_day()
	return problem


## Day action: the Ash Sisters calm the blood for money (the Voice drops). "" or the reason they won't.
func calm_voice() -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := VoiceRules.calm(run, ContentDB.data)
	if problem == "":
		EventBus.money_changed.emit(run.money)
		EventBus.progress_changed.emit()
		end_day()
	return problem


## Day action in the Scriptorium: study a trophy; returns what was learned (null = not done).
func study_trophy(trophy: StringName) -> LibraryRules.Study:
	if run == null or combat != null:
		return null
	var study := LibraryRules.study(run, ContentDB.data, trophy)
	if study != null:
		EventBus.stock_changed.emit()
		EventBus.contracts_changed.emit()
		EventBus.progress_changed.emit()
		end_day()
	return study


## Rag-and-Bone shop (GDD 11.1): buy an item of this week's table. "" or the reason it can't be bought.
func buy_item(uid: int) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := ShopRules.buy(run, ContentDB.data, uid)
	if problem == "":
		EventBus.money_changed.emit(run.money)
		EventBus.stock_changed.emit()
		_loadout_changed()
	return problem


## Sells one blood sample (pure or not); returns the money paid.
func sell_sample(creature: StringName, pure: bool) -> int:
	if run == null or combat != null:
		return 0
	var paid := ShopRules.sell_sample(run, ContentDB.data, creature, pure)
	if paid > 0:
		EventBus.money_changed.emit(run.money)
		EventBus.stock_changed.emit()
		save_game()
	return paid


## Sells one trophy or one unit of a resource; returns the money paid.
func sell_stock(id: StringName) -> int:
	if run == null or combat != null:
		return 0
	var paid := ShopRules.sell(run, ContentDB.data, id)
	if paid > 0:
		EventBus.money_changed.emit(run.money)
		EventBus.stock_changed.emit()
		save_game()
	return paid


## A story letter was read (GDD 2.4); a note waiting for a choice stays.
func read_letter() -> void:
	if run != null and StoryRules.next_letter(run) != "":
		StoryRules.read_letter(run, ContentDB.data)
		save_game()


## The hunter's choice at the end of the story: reputation, the end letter and its XP. "" or why not.
func story_choice(choice_id: StringName) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := StoryRules.choose(run, ContentDB.data, choice_id)
	if problem == "":
		StoryRules.read_letter(run, ContentDB.data)  # the note that asked is answered
		ProgressRules.add_xp(run, ContentDB.data, ContentDB.data.story.end_xp)
		EventBus.progress_changed.emit()
		save_game()
	return problem


## The morning news leaflet was read (GDD 15).
func read_news() -> void:
	if run != null and EventRules.next_news(run) != "":
		EventRules.read_news(run)
		save_game()


## Spends an attribute point (GDD 4.3). "" or why not.
func raise_attribute(attribute: StringName) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := ProgressRules.raise(run, ContentDB.data, attribute)
	if problem == "":
		EventBus.progress_changed.emit()
		save_game()
	return problem


## Buys a node of a skill web (GDD 4.4). "" or why not.
func buy_skill(web_id: StringName, node_id: StringName) -> String:
	if run == null or combat != null or ContentDB.data.webs.get(web_id) == null:
		return Loc.t("rule.not_now")
	var problem := SkillRules.buy(run, ContentDB.data, ContentDB.data.webs[web_id], node_id)
	if problem == "":
		_skills_changed()
	return problem


## Resets a web in the Scriptorium for money (owner, 2026-10-12): its points come back, learned blueprints stay.
func reset_skills(web_id: StringName) -> String:
	if run == null or combat != null or ContentDB.data.webs.get(web_id) == null:
		return Loc.t("rule.not_now")
	var problem := SkillRules.reset(run, ContentDB.data, ContentDB.data.webs[web_id])
	if problem == "":
		EventBus.money_changed.emit(run.money)
		_skills_changed()
	return problem


func _skills_changed() -> void:
	EventBus.progress_changed.emit()
	EventBus.stock_changed.emit()
	_loadout_changed()
