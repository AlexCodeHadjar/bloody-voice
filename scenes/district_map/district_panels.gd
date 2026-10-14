class_name DistrictPanels
extends Node
## Full-screen panels over the district map (one at a time): the contract board and tablets, a heard rumor and a
## mark (GDD 8.4), the shop, the tavern-shift result, the infirmary, the Scriptorium and the morning news. Adds them to the district screen
## and tells it what happened.

signal rumor_taken(t: RumorRules.Taken)  ## «Взять в записи» on a heard rumor
signal fight_started  ## a mark started a fight

var host: Control
var current: Control = null


func is_open() -> bool:
	return current != null


func open(panel: Control) -> void:
	if current != null:
		return
	current = panel
	host.add_child(panel)
	panel.connect(&"closed", _on_closed)


## Opens the panel of a place's action; false when the action is not a panel.
func open_for(action: StringName) -> bool:
	match action:
		&"tavern":
			open(ContractBoard.new())
		&"shop":
			open(ShopTable.new())
		&"shift":
			var report := GameState.work_shift()
			if report != null:
				var panel := ShiftPanel.new()
				open(panel)
				panel.show_report(report)
		&"infirmary":
			open(InfirmaryPanel.new())
		&"library":
			open(LibraryPanel.new())
		_:
			return false
	return true


## The morning news leaflets (GDD 15), then the story letters (GDD 2.4), one after another; nothing while another
## panel is open.
func show_news() -> void:
	if current != null:
		return
	var news := EventRules.next_news(GameState.run)
	if news != "":
		var panel := NewsPanel.new()
		panel.news = news
		open(panel)
		return
	var letter := StoryRules.next_letter(GameState.run)
	if letter != "":
		var lp := LetterPanel.new()
		lp.letter = letter
		open(lp)


func open_contract(list: Array[ContractsState.Contract], index: int) -> void:
	if current != null:
		return
	var tablet := ContractTablet.new()
	open(tablet)
	tablet.open_list(list, index)


func open_heard(h: RumorGenerator.Heard) -> void:
	if current != null:
		return
	var sheet := RumorSheet.new()
	open(sheet)
	sheet.taken.connect(func(t: RumorRules.Taken) -> void: rumor_taken.emit(t))
	sheet.open_heard(h)


func open_mark(uid: int) -> void:
	if current != null:
		return
	var sheet := MarkSheet.new()
	open(sheet)
	sheet.fight_started.connect(func() -> void: fight_started.emit())
	sheet.open_mark(uid)


func _on_closed() -> void:
	var was := current
	current = null
	if was is NewsPanel:
		GameState.read_news()
	elif was is LetterPanel and (was as LetterPanel).letter != "":
		GameState.read_letter()
		if StoryRules.next_letter(GameState.run) == (was as LetterPanel).letter:
			return  # the choice was put off: the note comes back on the next morning or visit, not at once
	show_news.call_deferred()  # news that came while a panel was open (a day action) or the next leaflet
	if (was is ContractBoard or was is ContractTablet) and not ContractRules.active(GameState.run.contracts).is_empty():
		Tutorial.trigger.call_deferred(&"contract_taken")
