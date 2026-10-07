extends SceneTree
## Balance report: the bot fights every creature N times with the starter deck.
##   Godot --headless --path . -s res://tests/bot/autoplay.gd -- --fights=200 [--capture] [--loadout=res://tests/bot/full_gear.json]


func _initialize() -> void:
	var fights := 200
	var capture := false
	var loadout_path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.trim_prefix("--fights="))
		capture = capture or arg == "--capture"
		if arg.begins_with("--loadout="):
			loadout_path = arg.trim_prefix("--loadout=")
	var errs := ErrorLog.new()
	var data := ContentLoader.load_all("res://data", errs)
	ContentValidator.validate(data, errs, false)
	if not errs.is_empty():
		printerr("\n".join(errs.messages))
		quit(1)
		return
	print("%-16s %4s %7s %7s %7s %7s %8s" % ["monster", "rank", "win%", "turns", "hp_left", "parts", "escaped"])
	var loadout := LoadoutState.from_dict(data.balance.start_loadout)
	if loadout_path != "":
		loadout = LoadoutState.from_dict(ContentLoader.read_object(loadout_path, errs))
		for problem: String in WeaponGridRules.problems(loadout, data):
			printerr("loadout: ", problem)
	for id: StringName in data.monster_order:
		_report(data, id, fights, capture, loadout)
	quit(0)


func _report(data: ContentData, id: StringName, fights: int, capture: bool, loadout: LoadoutState) -> void:
	var wins := 0
	var turns := 0
	var hp_left := 0
	var parts := 0
	var escaped := 0
	for i: int in fights:
		var setup := DeckBuilder.setup(loadout, data, id, 1000 + i)
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
