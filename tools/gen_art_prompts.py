"""Art prompts for ChatGPT as Markdown, generated from game data (so prompts never drift from the game).

Reads data/gear/shapes.json, data/gear/modules.json, data/monsters/*.json, data/ui/icons.json.
Writes docs/art-prompts/{README,modules,creatures,icons}.md.
(district-grey-chapels.md and combat-ui.md in the same folder are hand-written.) Templates: python tools/gen_art_templates.py
Run from the project root:  python tools/gen_art_prompts.py
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "art-prompts"
TPL = "../assets/templates"  # relative to docs/art-prompts/
ART = "../../art"


def load(rel: str):
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


SHAPES = {k: v for k, v in load("data/gear/shapes.json").items() if not k.startswith("_")}
MODULES = load("data/gear/modules.json")
MONSTERS = [m for f in sorted((ROOT / "data/monsters").glob("*.json")) for m in load(f"data/monsters/{f.name}")]
ICONS = load("data/ui/icons.json")

STYLE = """STYLE BLOCK (paste at the start of every prompt):
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved plate coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast.
Late-19th-century craftsmanship fused with advanced machinery (brass, rivets, glass).
No text, no letters, no numbers, no watermarks, no modern objects, no neon, no anime style."""

MODULE_STYLE = """MODULE STYLE (after the style block):
A single weapon part seen from directly above (top-down, orthographic, no perspective),
as if laid flat on a workbench. Same rendering as the attached resource icons:
thick dark ink outline, painted metal with scratches and wear, warm light from the top-left.
Transparent background. No table, no frame, no grid, no cell borders, no shadow outside the part."""

CELL_TYPES = {
    "gear": ("GEAR (mechanical)", "brass, blued steel, rivets, springs, warm gold highlights, no glow", "Start (Mechanic web)"),
    "spark": ("SPARK (electric)", "copper coils, glass, porcelain insulators, a cold blue glow (#6FA8FF) and thin electric arcs", "Mechanic web"),
    "blood": ("BLOOD (beast)", "bone, sinew, leather, glass vials with dark red ichor, organic shapes, a faint red glow", "Monster web (the Voice)"),
}

SHAPE_WORDS = {
    "M1": "a single square cell",
    "I2": "two cells side by side (a 2×1 bar)",
    "I3": "three cells in a row (a 3×1 bar)",
    "L3": "a corner of three cells: one on top, two below (left one under it)",
    "I4": "four cells in a row (a 4×1 bar)",
    "O4": "a 2×2 square of four cells",
    "T4": "a T of four cells: three in a row on top, one under the middle",
    "L4": "an L of four cells: three stacked vertically, one to the right of the bottom cell",
    "J4": "a J of four cells: three stacked vertically, one to the left of the bottom cell",
    "S4": "an S of four cells: two on top shifted right, two below shifted left",
    "Z4": "a Z of four cells: two on top shifted left, two below shifted right",
}

ICON_STYLES = {
    "object": ("Object icon", """ICON STYLE — OBJECT:
A painted game icon of an object, slight 3/4 view, thick dark ink outline,
painted metal / leather / wood / glass with wear, warm light from the top-left —
exactly the look of the attached resource icons. Readable at 64 px."""),
    "symbol": ("Symbol icon", """ICON STYLE — SYMBOL:
A small game symbol icon that must read at 32 px: one simple bold shape,
cast in dark tarnished brass like a token or engraved badge, thick dark outline,
minimal inner detail, strong silhouette. Palette: brass, soot black, parchment,
plus ONE accent colour only where it carries meaning (blood red, cold blue, sickly green, violet)."""),
    "crest": ("Crest", """ICON STYLE — CREST:
A heraldic emblem: a bold central symbol pressed into an aged round wax seal or painted on a
small chipped iron shield. Readable at 64 px, no lettering, no banners with words."""),
    "badge": ("Badge", """ICON STYLE — BADGE:
A blank metal rank badge with an EMPTY, smooth centre (the game prints a letter there).
Front view, thick dark outline, aged metal. No letters, no numbers."""),
}

ACCENTS = {
    "STATUS": "Accents: weak = ochre, exposed = steel blue, bleed = blood red, dodge = fog grey, enraged = red-orange, panic = violet.",
    "INTENT": "Accents (match the intent card borders): attack = red #B03A2E, defend = steel #6E7A8A, fear = violet #6B4A8A, "
              "debuff = ochre #8A7A3A, buff = orange #A05A2A, heal = green #4F7A4A, unknown = grey.",
    "CELL": "Accents: gear = warm brass, spark = cold blue glow, blood = dark red.",
    "STATE": "Accents: fog = grey, flood = blue-grey, fire = orange, quarantine = sickly yellow, riot = red, "
             "festival = warm gold, eclipse = silver, cleansed = white.",
    "STAT": "Accents: health = blood red, sanity = violet, voice = dark red, all others brass only.",
}


# ------------------------------------------------------------------ helpers

def code_block(text: str) -> str:
    return "```text\n" + text + "\n```"


def table(headers: list[str], rows: list[list[str]]) -> str:
    esc = lambda c: str(c).replace("|", "\\|").replace("\n", "<br>")
    lines = ["| " + " | ".join(headers) + " |", "|" + "---|" * len(headers)]
    lines += ["| " + " | ".join(esc(c) for c in r) + " |" for r in rows]
    return "\n".join(lines)


def shape_size(sid: str) -> tuple[int, int]:
    cells = SHAPES[sid]["cells"]
    return max(c[0] for c in cells) + 1, max(c[1] for c in cells) + 1


def aspect(sid: str) -> str:
    c, r = shape_size(sid)
    if c == r:
        return "1:1 (1024×1024)"
    return "3:2 landscape (1536×1024)" if c > r else "2:3 portrait (1024×1536)"


def parts_line(m: dict) -> str:
    return ", ".join(p["name"] for p in m["parts"])


def phase_name(m: dict) -> str:
    return m["phases"][0]["name"] if m.get("phases") else "true form"


# ------------------------------------------------------------------ prompts

def module_prompt(m: dict) -> str:
    c, r = shape_size(m["shape"])
    name, materials, _ = CELL_TYPES[m["cell"]]
    return f"""[STYLE BLOCK]
[MODULE STYLE]
Attached: SHAPE__{m['shape']}.png (exact shape of the part), RESOURCE icons (style reference),
WEAPON__tablet (the rifle these parts are installed into).
Weapon module "{m['name']}" for a monster hunter's rifle — {m['section']} section.
Cell type {name}: {materials}.
The part: {m['look']}.
SHAPE {m['shape']}: {SHAPE_WORDS[m['shape']]} — {c}×{r} cells.
Make the part fill the dark area of the attached template edge to edge, following its outline;
keep the important details inside the dashed inner lines. Everything outside the shape is transparent.
Do not draw the template's grid or dashed lines.
Output: transparent PNG, aspect {aspect(m['shape'])}."""


def creature_prompts(m: dict) -> list[tuple[str, str]]:
    code = m["id"].upper()
    return [
        ("1 — Combat art, first phase", f"""[STYLE BLOCK]
Attached: COMBAT__frame.png (framing guide), TAVERN__contract_board (silhouette style reference).
Full-body art of the creature "{m['name']}" (danger rank {m['rank']}) for the combat screen.
The creature: {m['look']}.
Mostly in deep shadow, lit by a cold rim light from behind and a weak warm light from the front;
slightly turned (3/4 view), standing on the ground line of the frame, filling the dashed safe area.
These body parts must be clearly visible and separate from each other (the player aims at them):
{parts_line(m)}.
Wrong proportions rather than gore. Transparent background, no floor, no text.
Output: transparent PNG, 2:3 portrait (1024×1536)."""),
        ("2 — Combat art, second phase", f"""[STYLE BLOCK]
Attached: {code}__combat__normal.png (the same creature, first phase).
Repaint THE SAME CREATURE in the same pose, camera, scale and position — its second phase
"{phase_name(m)}":
{m['true_form']}.
Keep the body parts {parts_line(m)} in the same places; broken-looking is fine.
Stronger glow, more threatening. Transparent background, no text.
Output: transparent PNG, 2:3 portrait (1024×1536)."""),
        ("3 — Leaflet silhouette", f"""[STYLE BLOCK]
Attached: {code}__combat__normal.png (the creature), LEAFLET__frame.png (size guide),
TAVERN__contract_board (how silhouettes look on hunters' leaflets).
A pure flat black silhouette (#120D0B) of the attached creature, as drawn on a hunters' contract
leaflet by a witness: same pose, slightly exaggerated, readable even at 96 px.
No inner details, no eyes, no shading, no outline of another colour.
It must fit inside the dashed circle of the frame with a little margin, standing on the line.
Transparent background (do not paint the parchment). No text.
Output: transparent PNG, 1:1 (1024×1024)."""),
        ("4 — Cracked silhouette", f"""[STYLE BLOCK]
Attached: {code}__silhouette__leaflet.png, {code}__combat__phase2.png.
The SAME black silhouette, cracked like broken porcelain: through thin glowing cracks a glimpse of
the creature's true form shows ({m['true_form'].split(';')[0]}).
Keep the outline identical. Transparent background, no text.
Output: transparent PNG, 1:1 (1024×1024)."""),
    ]


def icon_prompt(s: dict) -> str:
    cols, rows = s["grid"]
    lines = []
    for r in range(rows):
        row = s["icons"][r * cols:(r + 1) * cols]
        if not row:
            break
        lines.append(f"Row {r + 1}:")
        lines += [f"  {r * cols + i + 1}. {ic['name']} — {ic['look']}" for i, ic in enumerate(row)]
    empty = cols * rows - len(s["icons"])
    extra = (f"Leave the last {empty} slot{'s' if empty > 1 else ''} empty.\n" if empty else "")
    extra += (ACCENTS[s["set"]] + "\n") if s["set"] in ACCENTS else ""
    return f"""[STYLE BLOCK]
[ICON STYLE — {s['style'].upper()}]
Attached: RESOURCE icons (style reference), {s['set']}__grid.png (layout guide).
ONE image with ALL {len(s['icons'])} icons of this set: {s['about']}
Lay them out as a grid of {cols} column{'s' if cols > 1 else ''} × {rows} row{'s' if rows > 1 else ''}, exactly like the attached layout guide:
each icon centred in its own slot, all the same size and style, clear empty space between
them (they must not touch). Order: left to right, top to bottom.
""" + "\n".join(lines) + f"""
{extra}Transparent background. Do not draw the guide lines or slot numbers.
No text, no labels, no numbers, no frames or circles around the icons.
Output: transparent PNG, 3:2 landscape (1536×1024). Save as {s['set']}__sheet.png."""


# ------------------------------------------------------------------ pages

def readme() -> str:
    n_icons = sum(len(s["icons"]) for s in ICONS)
    return f"""# Art Prompts — Modules, Creatures, Icons

Prompts for ChatGPT image generation, **generated from the game data** — do not edit by hand,
change the data and run `python tools/gen_art_prompts.py`. City, districts, district states and UI props:
see [GDD §16](../gdd/16-art-direction-and-generation-prompts.md).

| Page | Content |
|---|---|
| [modules.md](modules.md) | {len(MODULES)} weapon modules in {len(SHAPES)} cell shapes |
| [creatures.md](creatures.md) | {len(MONSTERS)} creatures × 4 images (combat art, phase 2, leaflet silhouette, cracked) |
| [icons.md](icons.md) | {n_icons} icons in {len(ICONS)} sets — one image per set |
| [district-grey-chapels.md](district-grey-chapels.md) | Hand-written: close-up map of the Grey Chapels (overview + 12 tiles) |
| [combat-ui.md](combat-ui.md) | Hand-written: combat screen v2 pieces (card frames, medallions, vials, lamps…) |

## How to use

1. One chat per set: one for all modules, one per creature, one per icon style. The model keeps the style inside a chat.
2. Paste the STYLE BLOCK first (plus the MODULE STYLE or ICON STYLE the prompt names), then the prompt.
3. Attach the files the prompt names: templates from `docs/assets/templates/` (`python tools/gen_art_templates.py`),
   references from `art/ui/` (resource icons: `art/ui/icons/RESOURCE__*.webp`).
4. When a result is good, attach it as a style reference for the next one.
5. Save with the exact file name into `assets/modules/`, `assets/monsters/` or `assets/icons/`, then run
   `python tools/import_art.py` (modules are cut to their cell shape, icon sets into single icons).

{code_block(STYLE)}

## Quality checklist

| Check | Modules | Creatures | Icons |
|---|---|---|---|
| Transparent background, no text / grid / frames | yes | yes | yes |
| Fills the template | dark shape edge to edge | safe area, feet on the ground line | grid as in the layout guide |
| Readable small | 64 px per cell | silhouette at 96 px | symbols at 32 px |
| Consistency | cell type readable by material | phase 2 and silhouettes match the first combat art | one accent colour; rank badges empty |

If ChatGPT keeps adding a background, add: "The background must be fully transparent (alpha 0)."
"""


def modules_page() -> str:
    out = ["# A. Weapon Modules", "",
           "A module is a part installed into the cells of a weapon section (sight, magazine, stock, frame, barrel). "
           "Its art must have **the exact shape of its cells** — the player places it on the weapon tablet like a puzzle "
           "piece. The game rotates modules, so draw each one in its base orientation (as in the template).", "",
           f"![The weapon tablet]({ART}/ui/WEAPON__tablet.webp)", "",
           "## Shapes and templates", "",
           f"One cell = **256×256 px** in the game. Attach the template named in the prompt from "
           f"`docs/assets/templates/modules/`: the dark area is the part, the dashed line is the safe zone.", "",
           f"![All module shapes]({TPL}/modules/shapes_overview.png)", ""]
    rows = []
    for sid, s in SHAPES.items():
        c, r = shape_size(sid)
        rows.append([sid, str(len(s["cells"])), SHAPE_WORDS[sid], f"{c * 256}×{r * 256}", aspect(sid)])
    out += [table(["Shape", "Cells", "Description", "Game size", "Ask ChatGPT for"], rows), "",
            "> ChatGPT only outputs 1:1, 3:2 or 2:3. `tools/import_art.py` scales every module to its exact size and "
            "cuts away everything outside its cells — just keep the part centred and filling the shape.", "",
            "## Cell types and materials", "",
            table(["Cell type", "Materials and colour", "Unlocked by"], [list(v) for v in CELL_TYPES.values()]), "",
            "## Styles", "", code_block(MODULE_STYLE), "",
            "## Catalog", "",
            table(["Module", "Section", "Shape", "Cell", "Effect in game"],
                  [[m["name"], m["section"], m["shape"], m["cell"], m["effect"]] for m in MODULES]), "",
            "## Prompts", "",
            "File: `assets/modules/<MODULE_ID>__module__normal.png`, e.g. `CAPACITOR_BANK__module__normal.png`.", ""]
    for m in MODULES:
        out += [f"### {m['name']} — `{m['id'].upper()}` · {m['shape']} · {m['cell']}", "", code_block(module_prompt(m)), ""]
    return "\n".join(out)


def creatures_page() -> str:
    out = ["# B. Creature Silhouettes and Combat Art", "",
           table(["#", "Image", "Used in", "File name", "Size"], [
               ["1", "Combat art — first phase", "Combat screen", "`<CODE>__combat__normal.png`", "2:3 (1024×1536)"],
               ["2", "Combat art — second phase", "After the phase change", "`<CODE>__combat__phase2.png`", "2:3 (1024×1536)"],
               ["3", "Leaflet silhouette", "Leaflets, contract tablet, tracker", "`<CODE>__silhouette__leaflet.png`", "1:1 (1024×1024)"],
               ["4", "Cracked silhouette", "After the phase is seen; Bestiary", "`<CODE>__silhouette__cracked.png`", "1:1 (1024×1024)"]]), "",
           "> **Order:** 1 → 2 → 3 → 4 in ONE chat per creature, always attaching the previous result — the silhouette "
           "is cut from the combat art, so they always match.", "",
           "## Rules", "",
           "- **Silhouettes:** flat black #120D0B, transparent background, readable at 96 px, inside the circle of "
           "`LEAFLET__frame.png` (the round frame of the contract tablet).",
           "- **Combat art:** transparent background, inside the safe area of `COMBAT__frame.png`, on the ground ellipse; "
           "mostly shadow with rim light.",
           "- **Body parts** named in the prompt must be visible and separate — they become click targets in combat.",
           "- Same pose, camera and scale for phase 1 and 2 (the game cross-fades them). Wrong proportions, not gore.", "",
           f"![Leaflet frame]({TPL}/monsters/LEAFLET__frame.png)", "",
           f"![Silhouette style — tavern leaflets]({ART}/ui/TAVERN__contract_board.webp)", "",
           "## Prompts", "", "Files go to `assets/monsters/`.", ""]
    for m in MONSTERS:
        ph = m["phases"][0] if m.get("phases") else None
        out += [f"### {m['name']} — `{m['id'].upper()}` · rank {m['rank']}", "",
                table(["Field", "Value"], [
                    ["Body parts", parts_line(m)],
                    ["Phase 2", f"{ph['name']} (at {round(ph['below'] * 100)}% HP)" if ph else "—"],
                    ["Rumor tags", ", ".join(m["tags"]).replace("_", " ")]]), ""]
        for title, prompt in creature_prompts(m):
            out += [f"**{title}**", "", code_block(prompt), ""]
    return "\n".join(out)


def icons_page() -> str:
    total = sum(len(s["icons"]) for s in ICONS)
    out = ["# D. Game Icons", "",
           f"Every icon of the game: **{total} icons in {len(ICONS)} sets**, catalog `data/ui/icons.json`.", "",
           "## One image per set", "",
           "- Every set is generated as **ONE image** with all its icons on a grid — never icon by icon.",
           "- Grid per set: up to 5 icons → one row, up to 10 → two rows, up to 15 → three rows. Attach the set's "
           "layout guide `docs/assets/templates/icons/<SET>__grid.png` (numbered slots).",
           "- Save as `assets/icons/<SET>__sheet.png`; the import cuts it into `art/ui/icons/<SET>__<id>.webp` "
           "(each piece goes to the slot of its centre, so drips and sparks stay with their icon).",
           "- One bad icon → regenerate the whole set, attaching the previous image and asking to change only that icon.", "",
           f"![Example layout guide — FACTION 5×3]({TPL}/icons/FACTION__grid.png)", "",
           "## Styles", "",
           table(["Style", "Used for", "Size in game"], [
               ["Object", "Resources, weapon sections, armor, day actions", "64–256 px"],
               ["Symbol", "Stats, statuses, intents, card types, tags, outcomes, UI — must read at 32 px", "24–96 px"],
               ["Crest", "Factions and districts", "48–256 px"],
               ["Badge", "Register ranks A / P / D / S (letter added by the game)", "32–96 px"]]), ""]
    out += [code_block(v[1]) + "\n" for v in ICON_STYLES.values()]
    out += ["## Sets", "",
            table(["Set", "Icons", "Grid", "Style", "File"],
                  [[s["set"], str(len(s["icons"])), f"{s['grid'][0]} × {s['grid'][1]}", ICON_STYLES[s["style"]][0],
                    f"`{s['set']}__sheet.png`"] for s in ICONS]), ""]
    for s in ICONS:
        done = " · DONE" if s["status"] == "done" else ""
        out += [f"### {s['set']} — {len(s['icons'])} icons · grid {s['grid'][0]}×{s['grid'][1]} · "
                f"{ICON_STYLES[s['style']][0]}{done}", "", s["about"], "",
                table(["#", "File", "Name", "Where it is used", "Look"],
                      [[str(i + 1), f"`{s['set']}__{ic['id']}`", ic["name"], ic["use"], ic["look"]]
                       for i, ic in enumerate(s["icons"])]), "",
                code_block(icon_prompt(s)), ""]
    return "\n".join(out)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    pages = {"README.md": readme(), "modules.md": modules_page(), "creatures.md": creatures_page(), "icons.md": icons_page()}
    for name, text in pages.items():
        (OUT / name).write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")
    print("written", ", ".join(pages), "->", OUT)
