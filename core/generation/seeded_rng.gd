class_name SeededRng
extends RefCounted
## Pure helpers behind the Rng autoload, usable from tests and generators without the scene tree.


static func make_stream(master_seed: int, system: StringName, day: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([master_seed, String(system), day])
	return rng


static func new_master_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
