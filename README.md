# Bloody Voice

A story-driven monster-hunting game with roguelike elements: deck-building combat,
investigation through rumors, crafting your own weapons, and a living city that changes after events.

Engine: **Godot 4.7** · Language: **GDScript** · Status: **Phase 1 — Combat core** (grey-box)

The full design is in [`docs/gdd/`](docs/gdd/README.md); art prompts in [`docs/art-prompts/`](docs/art-prompts/README.md).

## Run

```bash
G="/d/Godot_v4.7.2-stable_win64_console.exe"   # path to your Godot 4.7 binary
"$G" --headless --path . --import              # after new files / art
"$G" --path .                                   # play
"$G" --headless --path . -s res://tests/run_tests.gd            # tests
"$G" --path . --resolution 1920x1080 -- --shots=<abs dir>        # auto-screenshots
"$G" --headless --path . -s res://tests/bot/autoplay.gd -- --fights=200   # balance report (bot)
```

## Project layout

| Folder | What lives there |
|---|---|
| `autoload/` | Thin singletons: `EventBus`, `ContentDB`, `Rng`, `SaveService`, `GameState` (the only writer of state) |
| `core/content/` | JSON → typed defs (`defs/`), loader, validator. Broken data = the game refuses to start |
| `core/state/` | `RunState` and friends — pure, serialisable data + save migrations |
| `core/rules/` | Pure static game rules, grouped by domain (`time/`, `city/`, …) |
| `core/generation/` | Seeded random streams and generators |
| `core/dev/` | Developer tools active only with command-line flags |
| `data/` | All content and tuning numbers (`balance.json`, `city/…`) |
| `scenes/` | Presentation only: screens read state and call `GameState` commands |
| `ui/theme/` | Palette and UI factory |
| `art/` | Processed game art (webp). Sources go to `assets/` (not committed) |
| `docs/` | Design document `gdd/`, art prompts `art-prompts/`, templates and city sketch `assets/` (Markdown only; ignored by Godot) |
| `tools/` | Python tools: project check, art import, city sketch, map region check, art prompts, monster tuning |
| `tests/` | Headless test runner + one suite per rules file |

## Art pipeline

1. Put source images into `assets/<districts|map|ui>/` named `<CODE>__<kind>__<state>.png`.
2. `python tools/import_art.py` → webp files in `art/`.
3. `"$G" --headless --path . --import`.

District click regions on the map art live in `data/city/map_regions.json`;
check them visually with `python tools/check_map_regions.py`.
