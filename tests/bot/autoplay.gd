extends SceneTree
## Balance report: the bot fights every creature N times with the starter deck.
##   Godot --headless --path . -s res://tests/bot/autoplay.gd -- --fights=200 [--capture]


func _initialize() -> void:
	var fights := 200
	var capture := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.trim_prefix("--fights="))
		capture = capture or arg == "--capture"
	var errs := ErrorLog.new()
	var data := ContentLoader.load_all("res://data", errs)
	ContentValidator.validate(data, errs, false)
	if not errs.is_empty():
		printerr("\n".join(errs.messages))
		quit(1)
		return
	print("%-16s %4s %7s %7s %7s %7s %8s" % ["monster", "rank", "win%", "turns", "hp_left", "parts", "escaped"])
	for id: StringName in data.monster_order:
		_report(data, id, fights, capture)
	quit(0)


func _report(data: ContentData, id: StringName, fights: int, capture: bool) -> void:
	var wins := 0
	var turns := 0
	var hp_left := 0
	var parts := 0
	var escaped := 0
	for i: int in fights:
		var setup := CombatSetup.from_balance(data.balance, id, 1000 + i)
		setup.capture_allowed = capture
		if capture:
			setup.deck.append(&"iron_net")
		var s := CombatBot.run_fight(setup, data)
		turns += s.turn
		parts += s.enemy.broken_parts()
		if s.phase == CombatState.Phase.WON:
			wins += 1
			hp_left += s.hero.hp
		if s.escaped:
			escaped += 1
	print("%-16s %4s %6.0f%% %7.1f %7.1f %7.2f %8d" % [id, data.monster(id).rank, 100.0 * wins / fights,
		float(turns) / fights, float(hp_left) / maxi(wins, 1), float(parts) / fights, escaped])
