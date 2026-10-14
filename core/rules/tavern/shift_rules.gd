class_name ShiftRules
extends RefCounted
## A shift behind the bar of the Lantern & Hook (GDD 3.3, owner 2026-10-12): the day's main action. Pays money and
## a line of gossip (no rumor is overheard any more, owner 2026-10-14).


class Report:
	var money: int = 0
	var gossip: StringName = &""  ## rumor_data.gossip id


static func work(run: RunState, data: ContentData, rng: RandomNumberGenerator) -> Report:
	var t := data.balance.tavern
	var r := Report.new()
	r.money = roundi(rng.randi_range(t.shift_money_min, t.shift_money_max) * EventRules.state_def(run, data).shift_pay_mult)
	run.money += r.money
	var lines := data.rumor_data.gossip
	if not lines.is_empty():
		r.gossip = lines[rng.randi_range(0, lines.size() - 1)].id
	return r
