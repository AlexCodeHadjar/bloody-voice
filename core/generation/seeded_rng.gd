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


## n different items of `from` in random order (all of them when n >= size).
static func sample(from: Array[StringName], n: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var rest := from.duplicate()
	var out: Array[StringName] = []
	while out.size() < n and not rest.is_empty():
		out.append(rest.pop_at(rng.randi_range(0, rest.size() - 1)))
	return out


## A key of `weights` picked with probability proportional to its weight (keys in insertion order).
static func weighted(weights: Dictionary[StringName, float], rng: RandomNumberGenerator) -> StringName:
	var total := 0.0
	for k: StringName in weights:
		total += weights[k]
	var roll := rng.randf() * total
	var last: StringName = &""
	for k: StringName in weights:
		last = k
		roll -= weights[k]
		if roll < 0.0:
			return k
	return last
