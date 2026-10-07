class_name DeckBuilder
extends RefCounted
## "Your gear is your deck" (GDD 5.3): the fight deck and bonuses come from the hunter's own cards,
## the weapon, the modules in its cells (with links between touching modules) and the armor mechanisms.

class Build:
	var deck: Array[StringName] = []
	var origins: Array[String] = []  ## where each deck card comes from (same index as deck)
	var mods: Dictionary[StringName, int] = {}
	var max_ammo: int = 0
	var links: Array[String] = []  ## active link descriptions, for the equipment screen


static func build(l: LoadoutState, data: ContentData, capture_allowed: bool = false) -> Build:
	var b := Build.new()
	var weapon := data.weapon(l.weapon)
	_add(b, data.balance.starter_deck, "Hunter")
	if weapon != null:
		_add(b, weapon.cards, weapon.name)
		b.max_ammo = weapon.max_ammo
	for p: LoadoutState.Placement in l.placements:
		var m := data.module(p.module)
		if m == null:
			continue
		_add(b, m.cards, m.name)
		if capture_allowed:
			_add(b, m.capture_cards, m.name)
		GearMods.sum(b.mods, m.mods)
	for mech_id: StringName in ArmorRules.installed(l):
		var mech := data.mechanism(mech_id)
		if mech != null:
			_add(b, mech.cards, mech.name)
			GearMods.sum(b.mods, mech.mods)
	_apply_links(l, data, b)
	b.max_ammo += int(b.mods.get(&"max_ammo", 0))
	return b


## Fight setup for the run's hunter.
static func setup(l: LoadoutState, data: ContentData, monster: StringName, seed_value: int,
		capture_allowed: bool = false) -> CombatSetup:
	var b := build(l, data, capture_allowed)
	var bal := data.balance
	var s := CombatSetup.new()
	s.monster_id = monster
	s.deck = b.deck
	s.mods = b.mods
	s.hero_max_hp = bal.base_hp + int(b.mods.get(&"max_hp", 0))
	s.hero_hp = s.hero_max_hp
	s.max_sanity = bal.base_sanity
	s.max_ap = bal.base_ap
	s.hand_size = bal.hand_size
	s.max_ammo = b.max_ammo
	s.capture_allowed = capture_allowed
	s.rng_seed = seed_value
	return s


## Setup with the starting gear from balance.json (tests, bots).
static func default_setup(data: ContentData, monster: StringName, seed_value: int) -> CombatSetup:
	return setup(LoadoutState.from_dict(data.balance.start_loadout), data, monster, seed_value)


static func _add(b: Build, cards: Array[StringName], origin: String) -> void:
	for c: StringName in cards:
		b.deck.append(c)
		b.origins.append(origin)


static func _apply_links(l: LoadoutState, data: ContentData, b: Build) -> void:
	for p: LoadoutState.Placement in l.placements:
		var m := data.module(p.module)
		if m == null:
			continue
		for link: ModuleDef.LinkDef in m.links:
			for q: LoadoutState.Placement in l.placements:
				if q != p and q.module == link.with_module and WeaponGridRules.touching(p, q, data):
					_replace_cards(b.deck, link.replace)
					b.links.append("%s + %s" % [m.name, data.module(q.module).name])
					break


static func _replace_cards(deck: Array[StringName], replace: Dictionary[StringName, StringName]) -> void:
	for i: int in deck.size():
		if replace.has(deck[i]):
			deck[i] = replace[deck[i]]
