class_name LifeFacing
extends RefCounted
## Which picture and mirroring a walker shows for a direction (map-life-people.md): the sheets hold "towards" (down-left)
## and "away" (up-right); the other two diagonals are the same pictures mirrored.

const DEAD_ZONE := 0.12  ## |dir.y| below this keeps the current view, so a walker on a flat street does not flicker


## True = the "towards" picture (moving down the screen). Near-horizontal moves keep `current`.
static func is_towards(dir: Vector2, current: bool) -> bool:
	var n := dir.normalized()
	if n.y > DEAD_ZONE:
		return true
	if n.y < -DEAD_ZONE:
		return false
	return current


## "Towards" looks down-left, "away" looks up-right: mirror when the walker goes the other way horizontally.
static func is_flipped(towards: bool, dir: Vector2, current: bool) -> bool:
	if absf(dir.x) < 0.01:
		return current
	return dir.x > 0.0 if towards else dir.x < 0.0


## Index into a weighted list of non-negative numbers for a roll in [0, sum).
static func weighted_index(weights: Array[float], roll: float) -> int:
	var acc := 0.0
	for i: int in weights.size():
		acc += weights[i]
		if roll < acc:
			return i
	return maxi(weights.size() - 1, 0)
