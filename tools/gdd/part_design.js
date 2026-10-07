// Part 1 — game design (vision, story, loops, hero, gear, investigation, combat, economy, factions)
const { H1, H1nb, H2, H3, P, Bul, Num, Note, Code, Tbl, KV } = require("./lib");

module.exports = () => [
  // ------------------------------------------------------------------ 1
  H1nb("1. Vision"),
  KV([
    ["Working title", "**Bloody Voice**"],
    ["Genre", "Story-driven monster-hunting game with roguelike elements: deck-building combat, investigation, crafting"],
    ["Platform / engine", "PC (Windows first). Godot 4.7, GDScript"],
    ["Session / length", "Campaign of 3 chapters + prologue, about 12 in-game weeks, 10–15 hours of play"],
    ["Tone", "Lovecraftian mysticism, gaslight-and-steel city, quiet dread with human warmth"],
    ["Player fantasy", "I am a monster hunter who thinks first, builds his own weapons and pays for power with his humanity"],
  ]),
  H2("1.1 Logline"),
  P("A hunter in **Hallowdeep**, a city built on a metal platform and sealed from the world by a wall of living fog, takes contracts in a tavern, tracks creatures through rumors, forges his own weapons in a workshop and injects the blood of the beasts he kills. The blood has a voice. The more he listens, the stronger he becomes, and the less of him is left."),
  H2("1.2 Meaning of the title"),
  P("Hunters draw power from the blood of dreamspawn. That blood **speaks**: whispers, hunger, the memory of the beast. In-game this is the **Voice** meter (corruption). It also echoes the setting: black magicians draw power from spoken words, white magicians from written signs. The city itself is full of voices — rumors are the main source of information."),
  H2("1.3 Design pillars"),
  Tbl(["Pillar", "What it means in practice"], [
    ["Hunt with your head", "Before every fight the player investigates: compares rumor tags with the contract, rules out false leads, prepares gear for the expected monster."],
    ["Your gear is your deck", "Cards come from weapon modules and armor mechanisms. The weapon tablet is the deck editor. Crafting = deck building."],
    ["Every day counts", "Days are the main resource: rumors, workshop, library and tavern work all cost a day. Contracts have deadlines; rent is due weekly."],
    ["The city remembers", "Districts change their look and rules after events and player actions (floods, fires, quarantines, fog breaches). Changes persist."],
    ["Power has a voice", "Two growth paths: the Mechanic (safe, engineered) and the Monster (blood formulas, huge power, corruption). The choice shapes the ending."],
  ], [1, 3]),
  H2("1.4 Story-driven game with roguelike elements"),
  P("The game is **not** a pure roguelike. The story, chapters, main characters and key contracts are hand-written. Roguelike elements give variety and tension inside that frame:"),
  Tbl(["Fixed (authored)", "Generated each playthrough (seeded)"], [
    ["Main story, chapters, main characters, endings", "Side contracts on the tavern board (monster, district, reward, deadline)"],
    ["Story contracts and their monsters", "Rumors in the search ring and their tags (true / noise)"],
    ["City layout, districts, landmarks", "Shop stock every week, black-market offers"],
    ["Faction storylines", "Random city events (fog breach, riot, festival) and their districts"],
    ["Skill webs, blueprint catalog", "Investigation outcomes, loot, monster variants (affixes)"],
  ], [1, 1]),
  P("**Failure is not game over by default.** If the hero falls in combat he wakes up in the Morrell clinic: loses days, money and one random equipped module, and gains a **Scar** (permanent trait). An optional **Ironman mode** makes death final (the Bestiary carries over to a new game)."),
  H2("1.5 Inspirations"),
  Bul([
    "**Atmosphere and world structure:** the web novel *I'm Really Not the Evil God's Lackey* (layered capital on a metal platform, fog wall, hunters using beast blood, knowledge monopoly, moon church). All names in this document are **original**; see Appendix A for the mapping.",
    "**Mechanics:** Slay the Spire (visible enemy intents), The Witcher contracts (investigation), Darkest Dungeon (stress/sanity), Backpack Hero (shaped modules in a grid), Inscryption (tabletop presentation).",
  ]),

  // ------------------------------------------------------------------ 2
  H1("2. Story Structure"),
  H2("2.1 Chapters"),
  Tbl(["Chapter", "Length", "Area unlocked", "Main thread"], [
    ["Prologue — First Blood", "3 days", "Nordhal Quarter, tavern, workshop", "Tutorial hunt. The hero takes his first injection of beast blood and hears the Voice for the first time."],
    ["I — The Lantern & Hook", "4 weeks", "Upper City (all 12 districts)", "Disappearances across the city lead to the Church of the Pale Vault and the Masked Moon. Factions introduce themselves."],
    ["II — Beneath the Platform", "4 weeks", "Transition Zone, Lower City levels 6–5", "Deepwright Company, the Grey Communion, an uprising below. A section of the platform collapses."],
    ["III — Where Voices Gather", "4 weeks", "Levels 4–1, Ruins of the Old Capital", "The fissure into the Underdream. The source of the Voice. Final hunt."],
    ["Finale", "1 battle", "The Underdream Fissure", "Ending depends on faction standing and the Voice level."],
  ], [1.4, 0.8, 1.6, 3]),
  H2("2.2 Story gates and deadlines"),
  Bul([
    "Each chapter has 3–4 **story contracts** with deadlines. Missing a deadline does not end the game: it branches the story (someone dies, a faction turns hostile, a district changes state).",
    "Between story contracts the player is free to take side contracts, craft, train and build reputation.",
    "A chapter ends when its final story contract is resolved or its last day passes.",
  ]),
  H2("2.3 Endings (draft)"),
  Tbl(["Ending", "Condition"], [
    ["The Hunter", "Voice below stage 2 at the finale. The hero seals the fissure and stays human."],
    ["The Hybrid", "Voice at stage 2. The hero controls the beast and becomes a new kind of guardian — feared by the city."],
    ["The Beast", "Voice at stage 3. The hero becomes the thing he hunted; epilogue from the next hunter's view."],
    ["Faction variants", "The faction with the highest standing decides what happens to the Lower City and the Mistveil."],
  ], [1, 3]),

  // ------------------------------------------------------------------ 3
  H1("3. Core Loops and Time"),
  H2("3.1 Three nested loops"),
  Tbl(["Loop", "Scale", "Player decisions"], [
    ["Chapter loop", "Weeks", "Which contracts to accept, which faction to support, where to spend money (rent, shop, weapons), Mechanic vs Monster growth."],
    ["Day loop", "1 day = 1 main action", "Investigate a rumor, work in the workshop, study in the library, take a tavern shift, or rest."],
    ["Combat loop", "5–15 turns", "Which cards to play with limited action points, which body part to target, when to reload, when to try capture."],
  ], [1, 1, 3]),
  H2("3.2 Calendar"),
  Bul([
    "Time unit: **day**. 7 days = **week**. A chapter is about 4 weeks. There are no years: the game is short and tight.",
    "**Monday:** the shop and black market refresh their stock; new contracts appear on the board.",
    "**Sunday (Rentday):** rent for the workshop-home is due. Unpaid rent becomes debt; after 2 missed payments the workshop is locked for a day.",
    "Every contract shows its deadline in days on the tracker (top-right).",
  ]),
  H2("3.3 Day actions"),
  Tbl(["Action", "Cost", "Result"], [
    ["Investigate a rumor", "1 day", "Mission at the rumor: false lead, wrong monster, discovery, empty, or the target. Story/contract fights happen here."],
    ["Workshop", "1 day", "Craft up to 2 items from blueprints, upgrade a module tier, salvage items. (Installing modules is free at any time in the hub.)"],
    ["Library", "1 day", "Study a trophy (Bestiary knowledge), verify one rumor without travelling (chance by Cunning), learn a blueprint from a book."],
    ["Tavern shift", "1 day", "Money + one free rumor 'overheard at the bar' in any district + small faction gossip."],
    ["Rest", "1 day", "Restore HP and Sanity; lower the Voice slightly."],
    ["Free actions", "0", "Accept contracts, visit the shop, move the hero figure to another district (the search ring restarts), manage equipment."],
  ], [1.2, 0.6, 3.2]),
  Note("A failed or empty rumor still gives something (a crossed-out tag, a small resource, a hint). A day must never feel completely wasted.", "Rule"),

  // ------------------------------------------------------------------ 4
  H1("4. The Hunter"),
  H2("4.1 Attributes"),
  Tbl(["Attribute", "In combat", "Outside combat"], [
    ["**Will**", "Max Sanity; resistance to Fear and Curse cards", "Thresholds of the Voice (corruption); resisting story temptations"],
    ["**Agility**", "+1 card drawn at 4 and 8; dodge chance; bonuses for light modules", "Speed of the search ring growth"],
    ["**Cunning**", "Preview depth of enemy intents; capture chance; trap power", "Rumor analysis (flags noise tags), shop prices, contract reward bargaining"],
  ], [0.8, 2, 2]),
  H2("4.2 Resources of the hero"),
  Tbl(["Resource", "Start", "Rule"], [
    ["HP", "40 (+5 per level)", "0 HP in combat = Hunter's Fall (clinic, losses, Scar)."],
    ["Sanity", "20 + 4 × Will", "Damaged by Fear. At 0 the hero panics: useless cards enter the hand for the rest of the fight."],
    ["Action Points (AP)", "3 per turn", "Spent to play cards. Consumable cards cost 0 AP but are destroyed after use."],
    ["The Voice (corruption)", "0", "Grows with blood formulas and mutations. Stages at 10 / 20 / 30 (+3 per Will point)."],
    ["Level / XP", "Level 1", "XP from slaying, capturing and researching monsters. Level cap 15."],
  ], [1, 1, 3]),
  H2("4.3 Levelling"),
  Bul([
    "Each level: **+1 skill point**. Levels 5, 10 and 15 give an extra point.",
    "Every second level: **+1 attribute point** (Will, Agility or Cunning).",
    "Skill points are spent in two **skill webs**: the Mechanic and the Monster.",
  ]),
  H2("4.4 Skill webs"),
  P("Each web is a **graph** (spider-web) growing outward from the centre. A node can be bought when it is connected to an owned node. Both webs have the same directions:"),
  Tbl(["Direction", "Content"], [
    ["Equipment", "Four sub-webs: **Helmet**, **Chestplate**, **Gauntlets & Pauldrons**, **Greaves**. Each piece has its own branches (e.g. Helmet: Perception / Focus / Masks)."],
    ["Weapon", "Frames and base weapon blueprints, ammo types, weapon handling passives."],
    ["Weapon modules", "Blueprints for modules that go into weapon grid cells."],
    ["Mechanisms", "Blueprints for mechanisms that go into free armor sockets; extra sockets."],
  ], [1, 3.5]),
  Tbl(["Node type", "Effect"], [
    ["Passive", "Small permanent bonus (+HP, +capture chance, +ammo)."],
    ["Blueprint", "Unlocks a craftable item in the workshop. **Everything from the webs is a blueprint, not a free item.**"],
    ["Socket", "Adds a mechanism socket to an armor piece."],
    ["Keystone", "Rule-changing node at the edge of a web (e.g. 'Reload draws a card')."],
  ], [1, 3.5]),
  H3("The Mechanic web"),
  P("Engineering, precision and control. Safe and predictable. Rich in Support cards, traps, armor sockets and electric modules. Key blueprints come from the Lumen Collegium and the Order of the Iron Vigil."),
  H3("The Monster web — the Voice"),
  Bul([
    "Nodes are **blood formulas** of specific creatures (e.g. 'Formula of the Vigil Hound'). A formula node can only be bought if the hero owns a **blood sample** of that creature — from a kill (normal sample) or a capture (pure sample, stronger node).",
    "Every formula adds **Voice**. Stages of the Voice:",
    ["Stage 1 — Whispers: Rage cards sometimes enter the deck (strong, but cost HP).", "Stage 2 — Hunger: one card per turn may be played automatically.", "Stage 3 — The Beast: unlocks Beast Form (huge power); after the fight there is a chance of losing control (story consequence)."],
    "The Voice is reduced by Collegium sedatives, Morrell treatments and Rest days — at the cost of money and time.",
    "Monster nodes unlock **blood sockets** in the weapon and armor.",
  ]),

  // ------------------------------------------------------------------ 5
  H1("5. Equipment, Weapons and the Deck"),
  H2("5.1 Armor"),
  Tbl(["Piece", "Role", "Example branches"], [
    ["Helmet", "Perception, mind protection", "Intent preview, Fear resistance, masks that change rumor reading"],
    ["Chestplate", "Survival", "Armor, HP, Bleed and Acid resistance"],
    ["Gauntlets & Pauldrons", "Handling and strikes", "Melee cards, reload speed, capture tools"],
    ["Greaves", "Mobility", "Dodge, search ring speed, escape from fights"],
  ], [1, 1.2, 3]),
  P("Each piece has **mechanism sockets** (1 at start, up to 3 through the webs). **Mechanisms** add tags and cards: e.g. 'Lantern of Revealing' (+1 intent preview, card 'Flash'), 'Smoke Bellows' (card 'Smoke Screen'), 'Tag Reader' (rumor analysis bonus)."),
  H2("5.2 The weapon tablet"),
  P("The weapon is shown as a **card**. Clicking it opens the **weapon tablet**: a side view of the weapon split into five sections. Each section contains connected square **cells** of different counts and directions."),
  Tbl(["Section", "Gameplay role"], [
    ["Sight (scope)", "Crits, aimed shots at body parts, intent preview"],
    ["Magazine", "Ammo capacity, reload cards, ammo types"],
    ["Stock", "Defense, recoil, melee bash"],
    ["Frame", "Total number of cells and their types; the 'body' of the weapon"],
    ["Barrel", "Damage type (shot, slug, harpoon, flame), range"],
  ], [1, 3]),
  Bul([
    "**Cell types:** Gear (mechanical), Spark (electric), Blood (opened by the Monster web).",
    "**Modules** are shaped like polyominoes (1–4 cells) and can be rotated.",
    "**Links:** modules touching each other can form combos (e.g. Coil next to Harpoon turns 'Shot' into 'Shock Harpoon').",
    "Hovering a weapon in the shop opens its tablet so the player can compare sections and stats before buying.",
  ]),
  H2("5.3 How the deck is built"),
  Code(`Deck = Base cards (6)
     + cards from the weapon (frame + installed modules)
     + cards from armor mechanisms
     + consumables chosen for this mission (single use)
     + contract-only capture consumables (only on that capture contract)
     + Curse/Rage cards added by the Voice or by monsters`),
  P("The number of cells and sockets naturally limits deck size. There are no random 'pick 1 of 3 cards' rewards: **the player builds the deck by crafting and installing**."),
  H2("5.4 The weapon in combat"),
  Bul([
    "The weapon card sits to the right of the hero and shows **ammo**. Weapon attack cards spend ammo; 'Reload' costs 1 AP (or a card).",
    "Some frames build **heat** instead of ammo (electric weapons): overheating skips the next weapon card.",
  ]),

  // ------------------------------------------------------------------ 6
  H1("6. Workshop and Crafting"),
  H2("6.1 Resources"),
  Tbl(["Icon", "Resource", "Main sources", "Used for"], [
    ["Gear", "Gears", "Industrial districts, slain mechanical monsters", "Mechanical modules, frames"],
    ["Scrap", "Work scrap", "Everywhere, search ring, salvage", "Basic items, repairs, armor"],
    ["Chip", "Electronics", "Lumen Campus, Deepwright, rare finds", "Spark modules, mechanisms"],
    ["Drop", "Ichor (beast blood)", "Slain/captured monsters, black market", "Blood modules, formulas"],
    ["Fang", "Trophies (fang, eye, chitin…)", "Body parts broken in combat", "Special and legendary blueprints"],
    ["Coin", "Money", "Contracts, tavern, selling", "Rent, shop, weapons, treatment"],
  ], [0.6, 1.2, 2, 2]),
  H2("6.2 Blueprints"),
  P("Blueprints come from the skill webs, the shop, special missions and faction rewards. In the workshop the player selects a blueprint, sees the cost and crafts it. A workshop day allows **2 crafts**."),
  Bul([
    "**Tiers:** modules have tiers I–III; upgrading costs resources and a workshop day.",
    "**Salvage:** returns 50% of resources — the player is never punished for experimenting.",
    "Shop-bought modules and blueprints are a shortcut for money instead of resources.",
  ]),

  // ------------------------------------------------------------------ 7
  H1("7. Tavern and Contracts"),
  H2("7.1 The contract board"),
  Bul([
    "The tavern 'The Lantern & Hook' has a **wooden wall with pinned leaflets**: reward, short description, black silhouette.",
    "Clicking a leaflet opens the **contract tablet** in front of the hero. Arrows left/right switch between tablets.",
    "**Accept** stamps a seal on the leaflet (the hunter has taken the job). The contract moves to the **tracker** in the top-right corner.",
    "Tracker row: monster silhouette, name, days left, **region icon**. Clicking the icon plays a glowing outline animation of the region where the creature was last seen.",
  ]),
  H2("7.2 Contract tablet"),
  KV([
    ["Petition", "Who asks and why (in-world letter text)"],
    ["Type", "Slay / Capture / Research / Story"],
    ["Silhouette", "Black outline of the creature (can be partial or wrong if witnesses lied)"],
    ["Known signs", "2–3 known tags (sound, trace, victims, time, place, shape)"],
    ["Last seen", "District (and area) with a region icon"],
    ["Deadline", "Days"],
    ["Reward", "Money, XP, reputation, sometimes a blueprint"],
    ["Expected danger", "Register rank A / P / D / S"],
  ]),
  H2("7.3 Contract types"),
  Tbl(["Type", "Goal", "Notes"], [
    ["Slay", "Kill the target", "Base type. Trophies from broken body parts."],
    ["Capture", "Bring the creature alive", "Contract-only capture consumables are issued. Higher reward and a pure blood sample if kept."],
    ["Research", "Observe the creature in combat", "Play 'Observe' on N body parts and survive N turns. Low money, big Bestiary gain."],
    ["Story", "Chapter progression", "Authored, may contain dialogue choices and special fights."],
  ], [0.8, 1.4, 3]),

  // ------------------------------------------------------------------ 8
  H1("8. Investigation"),
  H2("8.1 Flow"),
  Num([
    "Select a contract in the tracker, click its region icon — the region glows on the city map.",
    "Drag the **hero figure** (a stone figurine on a pedestal) to that district.",
    "While the figure stays there, a **blue aura ring** spreads from it. Each day the ring grows.",
    "Inside the ring **diamond icons** (rumors), resources and small events appear.",
    "Clicking a diamond opens the **rumor tablet**: an illustration on the left, rumors about the missing and what happened to them on the right, with **highlighted tags**.",
    "The player may open his contract tablet at any time to compare the silhouette and known signs.",
    "Either skip the rumor (wait for the next diamond) or press **Investigate** (costs the day).",
  ]),
  H2("8.2 Tag system"),
  P("Every monster has 4–6 sign tags across categories:"),
  Tbl(["Category", "Examples"], [
    ["Sound", "grinding metal, children singing, church bell, sudden silence (birds stop)"],
    ["Trace", "three parallel furrows, acid burns, frost, slime, no traces at all"],
    ["Victims", "children vanish, bodies drained dry, eyes missing, people come back 'different'"],
    ["Time", "only in fog, only at full moon, during rain, in daylight"],
    ["Place", "underground, rooftops, near water, inside churches"],
    ["Shape", "too tall, many arms, hunched, 'a man, but wrong'"],
  ], [1, 4]),
  Bul([
    "A rumor carries 1–3 tags; some may be **noise** (lies or confusion).",
    "High **Cunning** marks suspicious tags ('this sounds made up').",
    "The rumor tablet shows a **confidence line**: 'matches 2 of 3 known signs' — never a guarantee.",
    "A failed investigation **crosses out** a tag, so each next decision is better informed.",
    "**Rival hunters** (Pale Hounds, Weavers) take rumors too: a diamond can disappear if the player waits too long.",
  ]),
  H2("8.3 Investigation outcomes"),
  Tbl(["Outcome", "What happens", "Gives"], [
    ["The target", "Fight with the contract monster", "Contract completion"],
    ["Wrong monster", "Fight with another creature", "XP, ichor, sometimes starts a new contract"],
    ["Discovery", "Interesting find, no fight", "Resources, sometimes a blueprint or lore"],
    ["False lead", "Nothing there; rumor was a lie", "A crossed-out tag, small resource"],
    ["Empty night", "Wasted time", "Always at least a hint or a few scrap"],
  ], [1, 2, 2]),

  // ------------------------------------------------------------------ 9
  H1("9. Combat"),
  H2("9.1 Screen layout"),
  Code(`+--------------------------------------------------------------+
|  [intent]        [ ENEMY CARD + silhouette ]        [intent] |
|   left                body parts / phases               right |
|                                                              |
| HP  40/40                                                    |
| SAN 28/28                                                    |
| AP  3/3                                                      |
| VOICE stage 0          [ HERO CARD ]  [ WEAPON CARD: ammo ]  |
|                                                              |
| [draw pile]   [  hand of cards on the hunter's tablet  ]  [discard] |
+--------------------------------------------------------------+`, 15),
  Bul([
    "**Top centre:** the enemy card. Its planned actions are shown as cards **to the left and right** of it; hovering shows their direction (target).",
    "**Bottom centre:** the hero card. To its right: the **weapon card** with ammo.",
    "**Left edge:** HP, Sanity, AP and Voice as icons with numbers.",
    "**Draw pile** (cards not in hand or discard, always shuffled) and **discard pile** (played or discarded at end of turn).",
  ]),
  H2("9.2 Turn structure"),
  Num([
    "Start of turn: restore AP, draw 5 cards (+Agility bonus). Enemy intents for its next turn are already visible.",
    "Player plays cards by dragging them onto a target (enemy, enemy body part, or self).",
    "End of turn: unplayed cards go to the discard pile (unless Retain).",
    "Enemy turn: plays its revealed intents, then reveals the next ones.",
    "When the draw pile is empty, the discard pile is shuffled into it.",
  ]),
  H2("9.3 Card types"),
  Tbl(["Type", "Cost", "Notes"], [
    ["Attack", "AP", "Damage, may target a body part"],
    ["Support", "AP", "Block, buffs, draw, debuffs, Observe"],
    ["Consumable", "0 AP", "Single use, destroyed after play (bombs, tonics, antidotes, immunity)"],
    ["Capture", "AP or 0", "Contract-only; chance grows as enemy HP drops"],
    ["Rage", "0–1 AP", "Added by the Voice; strong but costs HP or Sanity"],
    ["Curse / Fear", "unplayable or costly", "Added by monsters; clog the hand"],
  ], [1, 0.8, 3]),
  H2("9.4 Monsters in combat"),
  Bul([
    "Each monster has **its own deck** and plays visible intents.",
    "**Body parts** are separate targets with HP. Breaking a part removes a card from its deck and drops a **trophy** (e.g. break the jaw — no more Bite).",
    "**Phases:** at 50% HP the silhouette cracks and reveals the true form, the deck changes.",
    "**Environment** comes from the rumor's tags: fighting 'in fog' or 'near water' adds field modifiers. A player who read the rumor right prepares the right mechanisms.",
  ]),

  // ------------------------------------------------------------------ 10
  H1("10. Capture and Research"),
  H2("10.1 Capture"),
  Bul([
    "Capture contracts issue special **capture consumables** for the duration of the contract. They appear **only** in fights against that contract's target.",
    "Chance formula (start values):",
  ]),
  Code(`chance = card_base * (1 - hp / max_hp) * (1 + 0.04 * cunning) * (1 + 0.15 * broken_parts)
clamp(chance, 0.0, 0.95)
on failure: the monster becomes Enraged for 1 turn (+damage)`),
  Tbl(["What to do with a captured creature", "Result"], [
    ["Hand over to the client", "Full contract reward"],
    ["Sell to a faction (Collegium, House Morrell)", "Money + reputation, client is angry"],
    ["Keep for experiments", "Pure blood sample (stronger Monster node), Voice +1, moral weight"],
  ], [2, 3]),
  H2("10.2 Research"),
  P("Research contracts reward knowledge. The player must play **Observe** on body parts and survive a number of turns. Rewards go to the **Bestiary**."),
  H2("10.3 The Bestiary"),
  Bul([
    "Each creature has a page: silhouette, tags, weaknesses, body parts, deck.",
    "Knowledge levels: Seen → Fought → Slain → Captured → Dissected (library).",
    "Knowledge works in combat: +1 intent preview, revealed weakness (+50% damage of a type), revealed ultimate card.",
    "In Ironman mode the Bestiary carries over to a new game.",
  ]),

  // ------------------------------------------------------------------ 11
  H1("11. Economy"),
  Tbl(["Money in", "Money out"], [
    ["Contract rewards", "Weekly rent for the workshop-home"],
    ["Tavern shifts", "Shop: consumables, modules, blueprints, weapons"],
    ["Selling trophies, captured creatures", "Treatment of HP / Voice at House Morrell"],
    ["Faction bonuses", "Bribes, passes into quarantined districts, Lower City permits"],
  ], [1, 1]),
  H2("11.1 The shop"),
  Bul([
    "A permanent location, like the tavern. Shown as a **wooden table with cards** lying on it.",
    "Resources are sold as cards with the resource icon in the centre.",
    "Refreshes every Monday. Stock depends on the district state and on Rowan Exchange reputation.",
    "Weapons for sale: hovering opens the weapon tablet (sections, cells, stats).",
    "Consumables for missions: damage, healing, immunity to effects, utility.",
  ]),
  H2("11.2 Black market"),
  P("In Scarlet Lantern Row: illegal modules, ichor, forbidden formulas. Buying lowers standing with the Order of the Iron Vigil and the Church of the Pale Vault."),

  // ------------------------------------------------------------------ 12
  H1("12. Factions and Reputation"),
  P("Reputation range −100…+100 with tiers **Hostile / Wary / Neutral / Trusted / Sworn**. It rises through faction contracts and fighting monsters on their territory. Trusted and Sworn unlock exclusive modules and **exclusive skill-web branches**."),
  Tbl(["Faction", "Home district", "Unlocks", "Conflicts with"], [
    ["Crown Magistracy", "Crown Ward", "High-pay secret contracts, rent relief", "Scarlet Supper, Grey Communion"],
    ["Order of the Iron Vigil", "Vigil Spire Ward", "Monster dossiers (contract tags revealed), knight armor", "Scarlet Supper"],
    ["Lumen Collegium", "Lumen Campus", "Mechanic+ branches, Register rank, sedatives", "Grey Communion"],
    ["Church of the Pale Vault", "Silverhill", "Healing, holy consumables, moon modules", "Grey Communion; later the hero"],
    ["Rowan Exchange (Harrow / Brannoc / Varga)", "Rowan Market + gate posts", "Shop discounts; Hawk = scopes, Bear = armor, Wolf = hunting gear", "—"],
    ["Hunter crews (Pale Hounds / Weavers)", "Nordhal Quarter", "Blood formulas (Monster web)", "Each other — choose one"],
    ["Scarlet Supper", "Scarlet Lantern Row", "Black market, forbidden modules", "Iron Vigil, Pale Vault"],
    ["House Morrell", "Morrell Ward", "Voice treatment, tonics", "—"],
    ["Deepwright Company", "Deepwright Lifts", "Lower City permits, resources", "Grey Communion"],
    ["Grey Communion", "Grey Chapels / Lower City", "Ichor, fog formulas, way into the depths", "Almost everyone above"],
    ["The Dusk Anointed", "Hidden", "Legendary 'Elder Mother' modules", "—"],
  ], [1.6, 1.2, 2.4, 1.6]),
  H2("12.1 The Lumen Register (public rank)"),
  Bul([
    "The Lumen Collegium publishes the **Register** of extraordinary beings: ranks **A** (Anomalous), **P** (Panic), **D** (Desolation), **S** (Sovereign).",
    "The hero has a public rank. It rises through deeds — defeating a creature of a higher rank.",
    "Rank unlocks higher contracts on the board and changes how factions treat the hero.",
    "The Register is published at the end of every chapter (an event with a recap).",
    "Places also have danger ranks; a district or area can be classified A/P/D/S (see section 13).",
  ]),
];
