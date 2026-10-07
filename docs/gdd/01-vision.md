# 1. Vision

| Field | Value |
|---|---|
| Working title | **Bloody Voice** |
| Genre | Story-driven monster-hunting game with roguelike elements: deck-building combat, investigation, crafting |
| Platform / engine | PC (Windows first). Godot 4.7, GDScript |
| Session / length | Campaign of 3 chapters + prologue, about 12 in-game weeks, 10–15 hours of play |
| Tone | Lovecraftian mysticism, gaslight-and-steel city, quiet dread with human warmth |
| Player fantasy | I am a monster hunter who thinks first, builds his own weapons and pays for power with his humanity |

## 1.1 Logline

A hunter in **Hallowdeep**, a city built on a metal platform and sealed from the world by a wall of living fog, takes contracts in a tavern, tracks creatures through rumors, forges his own weapons in a workshop and injects the blood of the beasts he kills. The blood has a voice. The more he listens, the stronger he becomes, and the less of him is left.

## 1.2 Meaning of the title

Hunters draw power from the blood of dreamspawn. That blood **speaks**: whispers, hunger, the memory of the beast. In-game this is the **Voice** meter (corruption). It also echoes the setting: black magicians draw power from spoken words, white magicians from written signs. The city itself is full of voices — rumors are the main source of information.

## 1.3 Design pillars

| Pillar | What it means in practice |
|---|---|
| Hunt with your head | Before every fight the player investigates: compares rumor tags with the contract, rules out false leads, prepares gear for the expected monster. |
| Your gear is your deck | Cards come from weapon modules and armor mechanisms. The weapon tablet is the deck editor. Crafting = deck building. |
| Every day counts | Days are the main resource: rumors, workshop, library and tavern work all cost a day. Contracts have deadlines; rent is due weekly. |
| The city remembers | Districts change their look and rules after events and player actions (floods, fires, quarantines, fog breaches). Changes persist. |
| Power has a voice | Two growth paths: the Mechanic (safe, engineered) and the Monster (blood formulas, huge power, corruption). The choice shapes the ending. |

## 1.4 Story-driven game with roguelike elements

The game is **not** a pure roguelike. The story, chapters, main characters and key contracts are hand-written. Roguelike elements give variety and tension inside that frame:

| Fixed (authored) | Generated each playthrough (seeded) |
|---|---|
| Main story, chapters, main characters, endings | Side contracts on the tavern board (monster, district, reward, deadline) |
| Story contracts and their monsters | Rumors in the search ring and their tags (true / noise) |
| City layout, districts, landmarks | Shop stock every week, black-market offers |
| Faction storylines | Random city events (fog breach, riot, festival) and their districts |
| Skill webs, blueprint catalog | Investigation outcomes, loot, monster variants (affixes) |

**Failure is not game over by default.** If the hero falls in combat he wakes up in the Morrell clinic: loses days, money and one random equipped module, and gains a **Scar** (permanent trait). An optional **Ironman mode** makes death final (the Bestiary carries over to a new game).

## 1.5 Inspirations

- **Atmosphere and world structure:** the web novel *I'm Really Not the Evil God's Lackey* (layered capital on a metal platform, fog wall, hunters using beast blood, knowledge monopoly, moon church). All names in this document are **original**; see Appendix A for the mapping.
- **Mechanics:** Slay the Spire (visible enemy intents), The Witcher contracts (investigation), Darkest Dungeon (stress/sanity), Backpack Hero (shaped modules in a grid), Inscryption (tabletop presentation).
