# 24. Audio

> Owner, 2026-10-12: the sound kit «Bloody Voice - Sound Kit» (CC0 / Public Domain). Basics wired in Phase 2b;
> volume settings, footsteps on the district map, creature idle voices and more music come with their screens.

## 24.1 Files and data

| What | Where |
|---|---|
| Sounds used by the game (≈ 35 MB, committed) | `res://audio/` — `sfx/`, `monsters/<ID>/`, `music/`, `ambience/` |
| Copying them from the kit, under game names | `python tools/import_audio.py ["<kit folder>"]` |
| Which sound plays on which event | `data/audio/sounds.json` → `AudioDef`, checked by `AudioValidator` (missing file = game does not start) |
| Playing | autoload `Sound`: `play(id)`, `play_monster(id, event)`, `screen(screen_id)`; screens call `UiKit.sound()`, `UiKit.screen_sound()`, `UiKit.monster_sound()` |
| Credits | `docs/credits.md` |

## 24.2 Buses and levels

Buses `UI`, `SFX`, `Music`, `Ambience` (created at start). Levels from the kit brief: hover −20 dB, clicks −14,
card play −12, hits −10, creature attack −8, creature phase change −6, music −14…−16, ambience −20. The same sound
does not repeat faster than its `min_gap` (hover 0.06 s, creature select 0.3 s).

## 24.3 What plays now

| Event | Sound |
|---|---|
| Any button: hover / press | `ui.hover` / `ui.click` (in `UiKit.button`) |
| Refused action | `ui.error` |
| Card chosen / played | `card.draw` / `card.play` |
| End turn | `turn.end` (lever) |
| Combat log (`CombatSounds`, `sounds.json/combat_log`) | fight start → creature `select`; its attack → creature `attack`; hit on it → creature `hit`; hit on the hunter → `combat.impact`; block → `combat.block`; phase → creature `phase2`; shuffle, reload, panic, win (bell), loss |
| Module installed | `gear.install` |
| Screens | menu → «Kokopelli's Graveyard»; city and equipment → «Unsolved Investigation» + rain; combat → «Post Apocalyptic Wastelands» |

## 24.4 Next

Volume sliders (settings, art `UI__slider_*` exists), footsteps of the hero on the district map (`world.step`),
creature `idle` voices (20 % after its turn, 12–25 s apart), district ambience by zone (fire in the tavern,
cellar air in Fog Hollow), more music once the owner picks tracks (the kit has alternatives).
