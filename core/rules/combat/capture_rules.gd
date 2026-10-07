class_name CaptureRules
extends RefCounted
## Capture chance (GDD 10.1). Pure functions.


static func chance(card_base: float, hp: int, max_hp: int, cunning: int, broken_parts: int, b: BalanceDef) -> float:
	var missing := 1.0 - float(maxi(hp, 0)) / float(maxi(max_hp, 1))
	var bonus := (1.0 + b.capture_per_cunning * cunning) * (1.0 + b.capture_per_broken_part * broken_parts)
	return clampf(card_base * missing * bonus, 0.0, b.capture_max_chance)


static func roll(rng: RandomNumberGenerator, chance_value: float) -> bool:
	return rng.randf() < chance_value
