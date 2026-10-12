# 8. Investigation

> **Owner, 2026-10-12:** while the game is confined to the Grey Chapels, rumors appear as **diamonds right on the
> district map** (GDD §20), in zones that fit their tags; the leaflet post on Bonfire Square lists them too. The hero
> walks to a diamond, opens the rumor tablet, «Расследовать» costs the day. Built in Phase 3 step 2 (8.4); the city-map
> figure and search ring below return when other districts open.

## 8.1 Flow

1. Select a contract in the tracker, click its region icon — the region glows on the city map.
2. Drag the **hero figure** (a stone figurine on a pedestal) to that district.
3. While the figure stays there, a **blue aura ring** spreads from it. Each day the ring grows.
4. Inside the ring **diamond icons** (rumors), resources and small events appear.
5. Clicking a diamond opens the **rumor tablet**: an illustration on the left, rumors about the missing and what happened to them on the right, with **highlighted tags**.
6. The player may open his contract tablet at any time to compare the silhouette and known signs.
7. Either skip the rumor (wait for the next diamond) or press **Investigate** (costs the day).

## 8.2 Tag system

Every monster has 4–6 sign tags across categories:

| Category | Examples |
|---|---|
| Sound | grinding metal, children singing, church bell, sudden silence (birds stop) |
| Trace | three parallel furrows, acid burns, frost, slime, no traces at all |
| Victims | children vanish, bodies drained dry, eyes missing, people come back 'different' |
| Time | only in fog, only at full moon, during rain, in daylight |
| Place | underground, rooftops, near water, inside churches |
| Shape | too tall, many arms, hunched, 'a man, but wrong' |

- A rumor carries 1–3 tags; some may be **noise** (lies or confusion).
- High **Cunning** marks suspicious tags ('this sounds made up').
- The rumor tablet shows a **confidence line**: 'matches 2 of 3 known signs' — never a guarantee.
- A failed investigation **crosses out** a tag, so each next decision is better informed.
- **Rival hunters** (Pale Hounds, Weavers) take rumors too: a diamond can disappear if the player waits too long.

## 8.3 Investigation outcomes

| Outcome | What happens | Gives |
|---|---|---|
| The target | Fight with the contract monster | Contract completion |
| Wrong monster | Fight with another creature | XP, ichor, sometimes starts a new contract |
| Discovery | Interesting find, no fight | Resources, sometimes a blueprint or lore |
| False lead | Nothing there; rumor was a lie | A crossed-out tag, small resource |
| Empty night | Wasted time | Always at least a hint or a few scrap |

## 8.4 How it works now (Phase 3 step 2, owner 2026-10-12)

| Rule | Value |
|---|---|
| Where | Brass diamonds stand on street nodes of the district map (not on places). Creature rumors land 3× more often in zones whose tags fit the creature (`data/rumors/rumors.json → zones`); each zone has its rumor pictures (`RUMOR__art__*`). Bonfire Square is the **rumor post**: a list of all diamonds, «Идти» sends the hunter there. The random hunt is gone: fights come only from rumors. |
| How many | Every morning 1–2 new diamonds (at most 5 on the map); each cools after 3 days. A taken contract seeds a **true** rumor at once and then every 2–3 days (these may exceed the cap). |
| Rumor kinds | Target (the contract's creature) · Wrong creature (another creature of the district, never a contract target) · Discovery · False lead · Empty night — weights in `balance.json → rumors.kind_weights`. Fixed when the rumor is made (reload never rerolls). |
| Signs | A creature rumor shows 1–2 of its true tags and, with a 35 % chance, one noise tag; rumors without a creature show 1–3 random tags (lies). |
| Tablet | Picture, zone, witness line (`witnesses`), signs (highlighted; signs crossed out on the best contract struck through), confidence line «Заказ «X»: совпадает N из M известных примет» for the best-fitting open contract (most matches) with its known signs, days until it cools; «Расследовать (весь день)» / «Пропустить». |
| Outcomes | Target / wrong creature: a fight on the rumor zone's background, the day ends after it. Discovery: 10–25 money. False lead / empty night: 3–8 money and one shown sign that is not the best contract creature's own is **crossed out** on that contract (shown on its tablet). The day ends. Resources replace money in Phase 4. |
| Not yet | Cunning marking suspicious tags (Phase 6), rival hunters taking diamonds (with factions), the city-map figure and search ring (when other districts open). |

Code: `core/generation/rumor_generator.gd`, `core/rules/rumors/rumor_rules.gd`, `core/state/rumors_state.gd`,
screens `scenes/rumors/` (diamond layer, rumor tablet, rumor post).
