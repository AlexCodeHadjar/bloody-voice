extends Node
## Seeded randomness (GDD 17.1). One master seed per playthrough; every system draws from its own
## named stream, so extra random calls in one system never change results in another.

var master_seed: int = 0


func set_seed(seed_value: int) -> void:
	master_seed = seed_value


## A fresh generator for (system, day). Same inputs -> same sequence.
func stream(system: StringName, day: int = 0) -> RandomNumberGenerator:
	return SeededRng.make_stream(master_seed, system, day)
