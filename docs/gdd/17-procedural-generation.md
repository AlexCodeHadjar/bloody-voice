# 17. Procedural Generation

Generation adds variety **inside** the authored story. Every generator is a pure function of `(seed, run_state, data)` so results are reproducible: the same save + seed gives the same board, rumors and shop. This makes bugs reproducible and balance testable by bots.

## 17.1 RNG streams

One master seed per playthrough. Each system gets its **own stream** derived from it, so adding a random call in one system never changes results in another.

```text
master_seed -> stream("contracts") -> stream("rumors") -> stream("shop")
            -> stream("events")    -> stream("combat") -> stream("loot")
stream(name) = RandomNumberGenerator with seed = hash(master_seed, name, day)
```

## 17.2 Generators

| Generator | Input | Output | Key rules |
|---|---|---|---|
| ContractGenerator | week, chapter, district states, hero rank, reputation | 3–6 side contracts on the board each Monday | Monster from district pool (weighted by state); reward scales with rank; deadline 4–10 days; never more than 2 of the same type |
| RumorGenerator | district, active contracts, day, Cunning | Diamonds in the search ring | Each active contract seeds 1 TRUE rumor per 2–3 days; others are wrong-monster / discovery / false / empty; 0–1 noise tags per rumor; weights from district state |
| OutcomeResolver | rumor, contract | What happens on Investigate | Determined when the rumor is generated (stored), so reloading does not reroll |
| ShopGenerator | week, Exchange reputation, district state | Cards on the shop table | Fixed slots: 2 weapons, 4 modules, 4 consumables, 3 resource lots; rarity by chapter |
| EventScheduler | chapter, day, flags | Random world events | Weighted table with cooldowns; at most 1 random event active; story events always win |
| MonsterVariant | base monster, chapter | Affixes (e.g. 'Fog-touched', 'Starving') | 0–2 affixes; each adds 1 card to the monster deck and 1 tag |
| LootGenerator | monster, broken parts, outcome | Resources, trophies, blood sample | Trophy only from broken parts; sample quality by kill/capture |

## 17.3 Rumor generation example

```text
func generate_rumor(rng, district, contracts, data) -> Rumor:
    var kind := weighted_pick(rng, district.rumor_kind_weights)   # target / wrong / discovery / false / empty
    var source := contracts.pick_for(district) if kind == TARGET else data.monster_pool(district).pick(rng)
    var tags := source.tags.sample(rng, 1 + rng.randi() % 2)        # 1-2 true tags
    if rng.randf() < data.balance.noise_chance:                      # maybe 1 noise tag
        tags.append(data.tags.random_not_in(source.tags, rng))
    return Rumor.new(kind, source.id, tags, district.random_point(rng))
```
