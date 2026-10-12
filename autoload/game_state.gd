extends "res://autoload/game_state_core.gd"
## Facade between the screens and the game rules (GDD 19.3): the place and day actions — contracts, rumors, the
## workshop, the shop, the tavern, health, the Scriptorium, progression. The run, days, gear and fights are in
## game_state_core.gd. Screens call these commands; only this node changes RunState, through rules, then emits signals.


## Free action (GDD 3.3): take a leaflet from the tavern board; its first true rumor appears at once.
## "" or the reason it can't be taken.
func accept_contract(uid: int) -> String:
	if run == null:
		return Loc.t("rule.not_now")
	var problem := ContractRules.accept(run.contracts, ContentDB.data, uid)
	if problem == "":
		EventBus.contracts_changed.emit()
		if RumorRules.seed_targets(run, ContentDB.data, Rng.stream(StringName("rumor_target_%d" % uid), run.day)):
			EventBus.rumors_changed.emit()
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


## Investigate a rumor (GDD 8): costs the day. A fight starts for the target or another creature (the day ends
## after it); otherwise the money and a crossed-out sign are taken and the day ends now. null if not possible.
func investigate_rumor(uid: int) -> RumorRules.Outcome:
	if run == null or combat != null:
		return null
	var o := RumorRules.investigate(run, ContentDB.data, uid)
	if o == null:
		return null
	EventBus.rumors_changed.emit()
	if o.monster != &"":
		var contract := run.contracts.find(o.contract_uid)
		_start_fight(o.monster, contract if ContractRules.active(run.contracts).has(contract) else null, o.zone)
		return o
	if o.money != 0:
		EventBus.money_changed.emit(run.money)
	if not o.resources.is_empty():
		EventBus.stock_changed.emit()
	if o.kind == &"discovery":
		var gained := ProgressRules.add_xp(run, ContentDB.data, ContentDB.data.balance.progress.discovery_xp)
		o.xp = gained.xp
		o.levels = gained.levels
		EventBus.progress_changed.emit()
	if o.crossed != &"":
		EventBus.contracts_changed.emit()
	end_day()
	return o


## Day action (GDD 3.3): a shift behind the bar. The day ends; the morning brings the overheard rumor. null if not now.
func work_shift() -> ShiftRules.Report:
	if run == null or combat != null:
		return null
	var report := ShiftRules.work(run, ContentDB.data, Rng.stream(&"shift", run.day))
	EventBus.money_changed.emit(run.money)
	end_day()
	# the rumor belongs to the new morning, so it comes after end_day (which saves); quitting in between loses only it
	var r := RumorRules.overheard(run, ContentDB.data, Rng.stream(&"overheard", run.day))
	if r != null:
		report.rumor_uid = r.uid
		EventBus.rumors_changed.emit()
		save_game()
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


## Day action in the Scriptorium: verify a rumor. "" or the reason it can't be done.
func verify_rumor(uid: int) -> String:
	if run == null or combat != null:
		return Loc.t("rule.not_now")
	var problem := LibraryRules.verify(run, uid)
	if problem == "":
		EventBus.rumors_changed.emit()
		end_day()
	return problem


## Day action in the Scriptorium: study a trophy; returns the contracts that learned a sign (empty = not done).
func study_trophy(trophy: StringName) -> Array[ContractsState.Contract]:
	if run == null or combat != null:
		return []
	var taught := LibraryRules.study(run, ContentDB.data, trophy)
	if not taught.is_empty():
		EventBus.stock_changed.emit()
		EventBus.contracts_changed.emit()
		end_day()
	return taught


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
