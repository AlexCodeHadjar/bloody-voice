class_name ContractDefs
extends RefCounted
## Contract content (GDD 7, 8.2): sign tags of creatures (data/contracts/tags.json), petition letters
## (data/contracts/petitions.json) and the contract numbers of balance.json.

const TYPES: Array[StringName] = [&"slay", &"capture", &"research", &"story"]
const GENERATED: Array[StringName] = [&"slay", &"capture"]  ## types the board generator can make now
const CATEGORIES: Array[StringName] = [&"sound", &"trace", &"victims", &"time", &"place", &"shape"]


class TagDef:
	var id: StringName
	var category: StringName
	var name: String


class PetitionDef:
	var id: StringName
	var types: Array[StringName] = []
	var sender: String  ## who asks (JSON "from")
	var text: String  ## the letter


## The "contracts" block of balance.json.
class Balance:
	var board_min: int = 3
	var board_max: int = 5
	var deadline_min: int = 4
	var deadline_max: int = 10
	var max_same_type: int = 2
	var max_same_monster: int = 2
	var max_active: int = 3
	var type_weights: Dictionary[StringName, float] = {}
	var reward_by_rank: Dictionary[String, int] = {}
	var reward_spread: float = 0.0
	var reward_step: int = 5
	var capture_reward_mult: float = 1.0
	var known_tags_min: int = 2
	var known_tags_max: int = 3
	var hunt_target_weight: float = 1.0
	var overdue_hp_mult: float = 1.0
	var overdue_damage_bonus: int = 0


static func tag(tag_id: StringName, d: Dictionary, errs: ErrorLog) -> TagDef:
	var t := TagDef.new()
	var w := "contracts/tags.json/%s" % tag_id
	t.id = tag_id
	t.category = DefReader.id(d, "category", errs, w)
	t.name = DefReader.string(d, "name", errs, w)
	return t


static func petition(d: Dictionary, errs: ErrorLog) -> PetitionDef:
	var p := PetitionDef.new()
	p.id = DefReader.id(d, "id", errs, "contracts/petitions.json")
	var w := "contracts/petitions.json/%s" % p.id
	p.types = DefReader.ids(d, "types", errs, w)
	p.sender = DefReader.string(d, "from", errs, w)
	p.text = DefReader.string(d, "text", errs, w)
	return p


static func balance(d: Dictionary, errs: ErrorLog) -> Balance:
	var b := Balance.new()
	var w := "balance.json/contracts"
	b.board_min = DefReader.integer(d, "board_min", errs, w, 3)
	b.board_max = DefReader.integer(d, "board_max", errs, w, 5)
	b.deadline_min = DefReader.integer(d, "deadline_min", errs, w, 4)
	b.deadline_max = DefReader.integer(d, "deadline_max", errs, w, 10)
	b.max_same_type = DefReader.integer(d, "max_same_type", errs, w, 2)
	b.max_same_monster = DefReader.integer(d, "max_same_monster", errs, w, 2)
	b.max_active = DefReader.integer(d, "max_active", errs, w, 3)
	var weights := DefReader.dict(d, "type_weights", errs, w)
	for k: Variant in weights:
		b.type_weights[StringName(str(k))] = float(weights[k])
	var rewards := DefReader.dict(d, "reward_by_rank", errs, w)
	for k: Variant in rewards:
		b.reward_by_rank[str(k)] = int(rewards[k])
	b.reward_spread = DefReader.number(d, "reward_spread", errs, w)
	b.reward_step = DefReader.integer(d, "reward_step", errs, w, 5)
	b.capture_reward_mult = DefReader.number(d, "capture_reward_mult", errs, w, 1.0)
	b.known_tags_min = DefReader.integer(d, "known_tags_min", errs, w, 2)
	b.known_tags_max = DefReader.integer(d, "known_tags_max", errs, w, 3)
	b.hunt_target_weight = DefReader.number(d, "hunt_target_weight", errs, w, 1.0)
	b.overdue_hp_mult = DefReader.number(d, "overdue_hp_mult", errs, w, 1.0)
	b.overdue_damage_bonus = DefReader.integer(d, "overdue_damage_bonus", errs, w)
	return b
