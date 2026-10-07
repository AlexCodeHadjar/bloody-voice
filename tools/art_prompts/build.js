// Builds "Bloody Voice - Art Prompts (Modules, Creatures, Icons).docx" from game data:
//   data/gear/shapes.json, data/gear/modules.json, data/monsters/*.json, data/ui/icons.json
// Usage (project root): python tools/art_prompts/refs.py && node tools/art_prompts/build.js
// Needs the npm package "docx" (npm install in tools/gdd, or NODE_PATH to a folder that has it).
const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, AlignmentType, Footer, PageNumber, PageBreak,
  TableOfContents, BorderStyle, Header,
} = require("docx");
const L = require("../gdd/lib");

const ROOT = path.resolve(__dirname, "..", "..");
const read = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), "utf8"));
const SHAPES = read("data/gear/shapes.json");
const MODULES = read("data/gear/modules.json");
const MONSTERS = fs.readdirSync(path.join(ROOT, "data/monsters")).filter((f) => f.endsWith(".json")).sort()
  .flatMap((f) => read("data/monsters/" + f));
const ICONS = read("data/ui/icons.json");
const TPL = (p) => path.join(ROOT, "docs/assets/templates", p);
const REF = (p) => path.join(__dirname, ".cache", p);
const code = (id) => id.toUpperCase();

const STYLE = `STYLE BLOCK (paste at the start of every prompt):
Dark gaslight-and-steel fantasy, Lovecraftian mysticism. Hand-painted illustration
with ink linework, like an old engraved plate coloured with muted watercolour.
Palette: soot black #2B2420, parchment #ECE4D2, tarnished brass #B08A4A,
cold steel blue #6E7A8A, dried blood red #8A1C1C, fog grey #BDBDB8,
sickly moon silver #C9CCD8. Low saturation, strong value contrast.
Late-19th-century craftsmanship fused with advanced machinery (brass, rivets, glass).
No text, no letters, no numbers, no watermarks, no modern objects, no neon, no anime style.`;

const MODULE_STYLE = `MODULE STYLE (after the style block):
A single weapon part seen from directly above (top-down, orthographic, no perspective),
as if laid flat on a workbench. Same rendering as the attached resource icons:
thick dark ink outline, painted metal with scratches and wear, warm light from the top-left.
Transparent background. No table, no frame, no grid, no cell borders, no shadow outside the part.`;

const CELL_TYPES = {
  gear: ["GEAR (mechanical)", "brass, blued steel, rivets, springs, warm gold highlights, no glow"],
  spark: ["SPARK (electric)", "copper coils, glass, porcelain insulators, a cold blue glow (#6FA8FF) and thin electric arcs"],
  blood: ["BLOOD (beast)", "bone, sinew, leather, glass vials with dark red ichor, organic shapes, a faint red glow"],
};

const SHAPE_WORDS = {
  M1: "a single square cell",
  I2: "two cells side by side (a 2×1 bar)",
  I3: "three cells in a row (a 3×1 bar)",
  L3: "a corner of three cells: one on top, two below (left one under it)",
  I4: "four cells in a row (a 4×1 bar)",
  O4: "a 2×2 square of four cells",
  T4: "a T of four cells: three in a row on top, one under the middle",
  L4: "an L of four cells: three stacked vertically, one to the right of the bottom cell",
  J4: "a J of four cells: three stacked vertically, one to the left of the bottom cell",
  S4: "an S of four cells: two on top shifted right, two below shifted left",
  Z4: "a Z of four cells: two on top shifted left, two below shifted right",
};

function shapeSize(id) {
  const cells = SHAPES[id].cells;
  const cols = Math.max(...cells.map((c) => c[0])) + 1;
  const rows = Math.max(...cells.map((c) => c[1])) + 1;
  return [cols, rows];
}
function chatgptAspect(id) {
  const [c, r] = shapeSize(id);
  if (c === r) return "1:1 (1024×1024)";
  return c > r ? "3:2 landscape (1536×1024)" : "2:3 portrait (1024×1536)";
}

const modulePrompt = (m) => {
  const [cols, rows] = shapeSize(m.shape);
  return `[STYLE BLOCK]
[MODULE STYLE]
Attached: SHAPE__${m.shape}.png (exact shape of the part), RESOURCE icons (style reference),
WEAPON__tablet (the rifle these parts are installed into).
Weapon module "${m.name}" for a monster hunter's rifle — ${m.section} section.
Cell type ${CELL_TYPES[m.cell][0]}: ${CELL_TYPES[m.cell][1]}.
The part: ${m.look}.
SHAPE ${m.shape}: ${SHAPE_WORDS[m.shape]} — ${cols}×${rows} cells.
Make the part fill the dark area of the attached template edge to edge, following its outline;
keep the important details inside the dashed inner lines. Everything outside the shape is transparent.
Do not draw the template's grid or dashed lines.
Output: transparent PNG, aspect ${chatgptAspect(m.shape)}.`;
};

const partsLine = (m) => m.parts.map((p) => p.name).join(", ");
const combatPrompt = (m) => `[STYLE BLOCK]
Attached: COMBAT__frame.png (framing guide), TAVERN__contract_board (silhouette style reference).
Full-body art of the creature "${m.name}" (danger rank ${m.rank}) for the combat screen.
The creature: ${m.look}.
Mostly in deep shadow, lit by a cold rim light from behind and a weak warm light from the front;
slightly turned (3/4 view), standing on the ground line of the frame, filling the dashed safe area.
These body parts must be clearly visible and separate from each other (the player aims at them):
${partsLine(m)}.
Wrong proportions rather than gore. Transparent background, no floor, no text.
Output: transparent PNG, 2:3 portrait (1024×1536).`;

const phasePrompt = (m) => `[STYLE BLOCK]
Attached: ${code(m.id)}__combat__normal.png (the same creature, first phase).
Repaint THE SAME CREATURE in the same pose, camera, scale and position — its second phase
"${m.phases && m.phases[0] ? m.phases[0].name : "true form"}":
${m.true_form}.
Keep the body parts ${partsLine(m)} in the same places; broken-looking is fine.
Stronger glow, more threatening. Transparent background, no text.
Output: transparent PNG, 2:3 portrait (1024×1536).`;

const leafletPrompt = (m) => `[STYLE BLOCK]
Attached: ${code(m.id)}__combat__normal.png (the creature), LEAFLET__frame.png (size guide),
TAVERN__contract_board (how silhouettes look on hunters' leaflets).
A pure flat black silhouette (#120D0B) of the attached creature, as drawn on a hunters' contract
leaflet by a witness: same pose, slightly exaggerated, readable even at 96 px.
No inner details, no eyes, no shading, no outline of another colour.
It must fit inside the dashed circle of the frame with a little margin, standing on the line.
Transparent background (do not paint the parchment). No text.
Output: transparent PNG, 1:1 (1024×1024).`;

const crackedPrompt = (m) => `[STYLE BLOCK]
Attached: ${code(m.id)}__silhouette__leaflet.png, ${code(m.id)}__combat__phase2.png.
The SAME black silhouette, cracked like broken porcelain: through thin glowing cracks a glimpse of
the creature's true form shows (${m.true_form.split(";")[0]}).
Keep the outline identical. Transparent background, no text.
Output: transparent PNG, 1:1 (1024×1024).`;

function moduleSection() {
  const out = [
    L.H1("A. Weapon Modules"),
    L.H2("A.1 What a module is"),
    L.P("A module is a part installed into the cells of a weapon section (sight, magazine, stock, frame, barrel). Its art must have **the exact shape of its cells**, because the player places it on the weapon tablet like a puzzle piece. The game rotates modules, so draw each one in its base orientation (as in the template)."),
    ...L.Img(REF("WEAPON__tablet.png"), 520, "Reference — the weapon tablet the modules are installed into (art/ui/WEAPON__tablet.webp)"),
    L.H2("A.2 Shapes and templates"),
    L.P("Every shape is made of square cells. One cell = **256×256 px** in the game. The templates are in `docs/assets/templates/modules/` — attach the one named in the prompt (`SHAPE__T4.png` etc.). The dark area is the part; the dashed inner line is the safe zone for important details."),
    ...L.Img(TPL("modules/shapes_overview.png"), 640, "All module shapes (docs/assets/templates/modules/shapes_overview.png)"),
    L.Tbl(["Shape", "Cells", "Description", "Game size", "Ask ChatGPT for"],
      Object.keys(SHAPES).filter((k) => !k.startsWith("_")).map((id) => {
        const [c, r] = shapeSize(id);
        return [id, String(SHAPES[id].cells.length), SHAPE_WORDS[id], `${c * 256}×${r * 256}`, chatgptAspect(id)];
      }), [0.6, 0.5, 3, 1, 1.6]),
    L.Note("ChatGPT can only output 1:1, 3:2 or 2:3 images. That is fine: `tools/import_art.py` scales every module to its exact size and cuts away everything outside its cells automatically. Just keep the part centred and filling the shape.", "Why the sizes differ"),
    L.H2("A.3 Cell types and materials"),
    L.P("The cell type tells which cells of the weapon a module fits into, and it must be readable from the art at a glance:"),
    L.Tbl(["Cell type", "Materials and colour", "Unlocked by"],
      [[CELL_TYPES.gear[0], CELL_TYPES.gear[1], "Start (Mechanic web)"],
       [CELL_TYPES.spark[0], CELL_TYPES.spark[1], "Mechanic web"],
       [CELL_TYPES.blood[0], CELL_TYPES.blood[1], "Monster web (the Voice)"]], [1.2, 3, 1.3]),
    L.H2("A.4 Style references to attach"),
    L.P("Attach the resource icons sheet as the **item style reference** (same ink outline, same painted metal):"),
    ...L.Img(REF("RESOURCES__six_icons.png"), 520, "Style reference — resource icons (assets/ui/RESOURCES__six_icons.png)"),
    L.Code(STYLE, 16),
    L.Code(MODULE_STYLE, 16),
    L.H2("A.5 Module catalog"),
    L.Tbl(["Module", "Section", "Shape", "Cell", "Effect in game"],
      MODULES.map((m) => [m.name, m.section, m.shape, m.cell, m.effect]), [1.4, 0.9, 0.6, 0.6, 2.6]),
    L.H2("A.6 Prompts, one per module"),
    L.P("File name: `assets/modules/<MODULE_ID>__module__normal.png` (upper-case id, e.g. `CAPACITOR_BANK__module__normal.png`)."),
  ];
  for (const m of MODULES) {
    out.push(L.H3(`${m.name}  [${code(m.id)} · ${m.shape} · ${m.cell}]`));
    out.push(...L.Code(modulePrompt(m), 15));
  }
  return out;
}

function creatureSection() {
  const out = [
    L.H1("B. Creature Silhouettes and Combat Art"),
    L.H2("B.1 Four images per creature"),
    L.Tbl(["#", "Image", "Used in", "File name", "Size"], [
      ["1", "Combat art — first phase", "Combat screen, centre top", "<CODE>__combat__normal.png", "2:3 (1024×1536)"],
      ["2", "Combat art — second phase", "Combat screen after the phase change", "<CODE>__combat__phase2.png", "2:3 (1024×1536)"],
      ["3", "Leaflet silhouette", "Tavern leaflets, contract tablet, tracker", "<CODE>__silhouette__leaflet.png", "1:1 (1024×1024)"],
      ["4", "Cracked silhouette", "Leaflet/tracker after the phase is seen; Bestiary", "<CODE>__silhouette__cracked.png", "1:1 (1024×1024)"],
    ], [0.3, 1.6, 2, 2.2, 1.2]),
    L.Note("Make them in this order: 1 → 2 → 3 → 4, in ONE chat per creature, always attaching the previous result. The silhouette is cut from the combat art, so they always match.", "Order"),
    L.H2("B.2 Rules"),
    L.Bul([
      "**Silhouettes** are pure flat black (#120D0B) on a transparent background, readable at 96 px, no inner details. They must fit the dashed circle of `LEAFLET__frame.png` — the round frame at the top of the contract tablet.",
      "**Combat art** is on a transparent background inside the dashed safe area of `COMBAT__frame.png`, standing on the ground ellipse. Mostly shadow with rim light: the creature is revealed, not explained.",
      "**Body parts** listed in each prompt must be clearly visible and separate — later they become clickable areas in combat (traced like the district regions).",
      "Wrong proportions instead of gore. No text anywhere.",
      "Keep the same pose, camera and scale between phase 1 and phase 2 so the game can cross-fade them.",
    ]),
    L.H2("B.3 Templates and references"),
    ...L.Img(TPL("monsters/LEAFLET__frame.png"), 240, "LEAFLET__frame.png — the silhouette fits inside the circle"),
    ...L.Img(REF("TAVERN__contract_board.png"), 520, "Style reference — silhouettes on the tavern leaflets (art/ui/TAVERN__contract_board.webp)"),
    ...L.Img(REF("CONTRACT__tablet.png"), 220, "The contract tablet — the silhouette goes into the round frame at the top"),
    L.P("`COMBAT__frame.png` (2:3, transparent with a dashed safe area and a ground ellipse) is in `docs/assets/templates/monsters/`."),
    L.H2("B.4 Prompts, four per creature"),
    L.P("Files go to `assets/monsters/`, e.g. `GUTTER_CHOIR__combat__normal.png`."),
  ];
  for (const m of MONSTERS) {
    out.push(L.H3(`${m.name}  [${code(m.id)} · rank ${m.rank}]`));
    out.push(L.KV([
      ["Body parts", partsLine(m)],
      ["Phase 2", m.phases && m.phases[0] ? `${m.phases[0].name} (at ${Math.round(m.phases[0].below * 100)}% HP)` : "—"],
      ["Rumor tags", m.tags.join(", ").replace(/_/g, " ")],
    ]));
    out.push(L.P("**1 — Combat art, first phase**"), ...L.Code(combatPrompt(m), 15));
    out.push(L.P("**2 — Combat art, second phase**"), ...L.Code(phasePrompt(m), 15));
    out.push(L.P("**3 — Leaflet silhouette**"), ...L.Code(leafletPrompt(m), 15));
    out.push(L.P("**4 — Cracked silhouette**"), ...L.Code(crackedPrompt(m), 15));
  }
  return out;
}

const ICON_STYLES = {
  object: ["Object icon", `ICON STYLE — OBJECT:
A painted game icon of an object, slight 3/4 view, thick dark ink outline,
painted metal / leather / wood / glass with wear, warm light from the top-left —
exactly the look of the attached resource icons. Readable at 64 px.`],
  symbol: ["Symbol icon", `ICON STYLE — SYMBOL:
A small game symbol icon that must read at 32 px: one simple bold shape,
cast in dark tarnished brass like a token or engraved badge, thick dark outline,
minimal inner detail, strong silhouette. Palette: brass, soot black, parchment,
plus ONE accent colour only where it carries meaning (blood red, cold blue, sickly green, violet).`],
  crest: ["Crest", `ICON STYLE — CREST:
A heraldic emblem: a bold central symbol pressed into an aged round wax seal or painted on a
small chipped iron shield. Readable at 64 px, no lettering, no banners with words.`],
  badge: ["Badge", `ICON STYLE — BADGE:
A blank metal rank badge with an EMPTY, smooth centre (the game prints a letter there).
Front view, thick dark outline, aged metal. No letters, no numbers.`],
};

const ACCENTS = {
  STATUS: "Accents: weak = ochre, exposed = steel blue, bleed = blood red, dodge = fog grey, enraged = red-orange, panic = violet.",
  INTENT: "Accents (match the intent card borders): attack = red #B03A2E, defend = steel #6E7A8A, fear = violet #6B4A8A, debuff = ochre #8A7A3A, buff = orange #A05A2A, heal = green #4F7A4A, unknown = grey.",
  CELL: "Accents: gear = warm brass, spark = cold blue glow, blood = dark red.",
  STATE: "Accents: fog = grey, flood = blue-grey, fire = orange, quarantine = sickly yellow, riot = red, festival = warm gold, eclipse = silver, cleansed = white.",
  STAT: "Accents: health = blood red, sanity = violet, voice = dark red, all others brass only.",
};

function iconSheetPrompt(set) {
  const [cols, rows] = set.grid;
  const lines = [];
  for (let r = 0; r < rows; r++) {
    const row = set.icons.slice(r * cols, (r + 1) * cols);
    if (row.length === 0) break;
    lines.push(`Row ${r + 1}:`);
    row.forEach((ic, i) => lines.push(`  ${r * cols + i + 1}. ${ic.name} — ${ic.look}`));
  }
  const empty = cols * rows - set.icons.length;
  const accent = ACCENTS[set.set] ? ACCENTS[set.set] + "\n" : "";
  return `[STYLE BLOCK]
[ICON STYLE — ${set.style.toUpperCase()}]
Attached: RESOURCE icons (style reference), ${set.set}__grid.png (layout guide).
ONE image with ALL ${set.icons.length} icons of this set: ${set.about}
Lay them out as a grid of ${cols} column${cols > 1 ? "s" : ""} × ${rows} row${rows > 1 ? "s" : ""}, exactly like the attached layout guide:
each icon centred in its own slot, all the same size and style, clear empty space between
them (they must not touch). Order: left to right, top to bottom.
${lines.join("\n")}
${empty > 0 ? `Leave the last ${empty} slot${empty > 1 ? "s" : ""} empty.\n` : ""}${accent}Transparent background. Do not draw the guide lines or slot numbers.
No text, no labels, no numbers, no frames or circles around the icons.
Output: transparent PNG, 3:2 landscape (1536×1024). Save as ${set.set}__sheet.png.`;
}

function iconSection() {
  const total = ICONS.reduce((a, s) => a + s.icons.length, 0);
  const out = [
    L.H1("D. Game Icons"),
    L.P(`Every icon the game needs: **${total} icons in ${ICONS.length} sets**. The catalog is \`data/ui/icons.json\` — the game, the import tool and this document all read it, so ids, order and grid never drift apart.`),
    L.H2("D.1 Four icon styles"),
    L.Tbl(["Style", "Used for", "Size in game"], [
      ["Object", "Resources, weapon sections, armor, day actions — things you can hold", "64–256 px"],
      ["Symbol", "Stats, statuses, intents, card types, tags, outcomes, UI buttons — must read at 32 px", "24–96 px"],
      ["Crest", "Factions and districts", "48–256 px"],
      ["Badge", "Register ranks A / P / D / S (the letter is added by the game)", "32–96 px"],
    ], [0.8, 3.4, 1]),
    ...Object.values(ICON_STYLES).map((v) => L.Code(v[1], 15)),
    L.H2("D.2 One image per group"),
    L.Bul([
      "**Every set is generated as ONE image** with all its icons on a grid — never icon by icon. Icons drawn together share size, light and style automatically.",
      "Each set has its grid (columns × rows) in the catalog: up to 5 icons → one row, up to 10 → two rows, up to 15 → three rows. Attach the set's layout guide `docs/assets/templates/icons/<SET>__grid.png` (numbered slots) so the model keeps the order.",
      "Save the image as `assets/icons/<SET>__sheet.png`. `python tools/import_art.py` cuts it into `art/ui/icons/<SET>__<id>.webp`: every shape goes to the slot that holds its centre, so loose drips and sparks stay with their icon.",
      "If one icon is bad, regenerate the whole set: attach the previous image and ask to change only that icon, keeping all the others and the layout.",
      "Do the sets of one style in the same chat (all symbol sets, then all crests…), attaching an earlier finished set as a style reference.",
    ]),
    ...L.Img(TPL("icons/FACTION__grid.png"), 420, "Example layout guide — FACTION, 5 × 3 (docs/assets/templates/icons/FACTION__grid.png)"),
    ...L.Img(REF("RESOURCES__six_icons.png"), 520, "Style reference for all icons — the resource set (already done)"),
    L.H2("D.3 Sets: grid, catalog and prompt"),
    L.Tbl(["Set", "Icons", "Grid", "Style", "File"],
      ICONS.map((x) => [x.set, String(x.icons.length), `${x.grid[0]} × ${x.grid[1]}`, ICON_STYLES[x.style][0], `${x.set}__sheet.png`]),
      [1.3, 0.6, 0.7, 1, 2]),
  ];
  for (const set of ICONS) {
    out.push(L.H3(`${set.set} — ${set.icons.length} icons · grid ${set.grid[0]}×${set.grid[1]} · ${ICON_STYLES[set.style][0]}${set.status === "done" ? " · DONE" : ""}`));
    out.push(L.P(set.about));
    out.push(L.Tbl(["#", "File", "Name", "Where it is used", "Look"],
      set.icons.map((ic, i) => [String(i + 1), `${set.set}__${ic.id}`, ic.name, ic.use, ic.look]), [0.3, 1.6, 1.1, 1.5, 2.3]));
    out.push(...L.Code(iconSheetPrompt(set), 15));
  }
  return out;
}

function finishSection() {
  return [
    L.H1("C. After Generation"),
    L.H2("C.1 Import"),
    L.Num([
      "Save the PNG into `assets/modules/`, `assets/monsters/` or `assets/icons/` with the exact file name from the prompt.",
      "Run `python tools/import_art.py` — modules are cut to their cell shape, icon sheets (one per set) into single icons; everything becomes webp in `art/gear/modules/`, `art/monsters/` and `art/ui/icons/`.",
      "Run Godot `--import` (or open the editor).",
    ]),
    L.H2("C.2 Quality checklist"),
    L.Tbl(["Check", "Modules", "Creatures"], [
      ["Background is transparent", "yes", "yes"],
      ["No text, numbers, frames, grid lines", "yes", "yes"],
      ["Fills the template shape / safe area", "the dark shape, edge to edge", "the dashed safe area, feet on the ground line"],
      ["Cell type readable", "gear = brass, spark = blue glow, blood = bone and ichor", "—"],
      ["Matches the previous image", "—", "phase 2 and silhouettes match the first combat art"],
      ["Readable small", "at 64 px per cell", "silhouette at 96 px"],
    ], [1.6, 2, 2]),
    L.Tbl(["Check", "Icons"], [
      ["One image per set, grid as in the layout guide, catalog order, same size, gaps", "yes"],
      ["Symbol icons readable at 32 px (squint test)", "yes"],
      ["Only one accent colour, and only where it means something", "yes"],
      ["Rank badges have an empty centre — no letters", "yes"],
    ], [3, 1]),
    L.Note("If ChatGPT keeps adding a background, add: \"The background must be fully transparent (alpha 0). Do not draw parchment, a table or a floor.\"", "Tip"),
  ];
}

const MARGIN = 1134;
const A4 = { width: 11906, height: 16838 };
L.setWidth(A4.width - 2 * MARGIN);
const title = [
  new Paragraph({ spacing: { before: 2400 }, alignment: AlignmentType.CENTER, children: [new TextRun({ text: "BLOODY VOICE", font: L.FONT.head, size: 64, bold: true, color: L.C.accent })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 300 }, children: [new TextRun({ text: "Art Prompts: Weapon Modules, Creatures and Icons", font: L.FONT.head, size: 34, color: L.C.head })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: `${MODULES.length} modules in ${Object.keys(SHAPES).filter((k) => !k.startsWith("_")).length} cell shapes · ${MONSTERS.length} creatures × 4 images · ${ICONS.reduce((a, x) => a + x.icons.length, 0)} icons`, size: 22, color: L.C.muted })] }),
  new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 1600 }, children: [new TextRun({ text: "Prompts for ChatGPT image generation, built from the game data", italics: true, size: 22, color: L.C.muted })] }),
  L.H1nb("How to use this document"),
  ...L.Num([
    "One chat per set: one chat for all modules, one chat per creature, one chat per icon style. The model keeps the style inside a chat.",
    "Always paste the STYLE BLOCK first (plus the MODULE STYLE or ICON STYLE the prompt names), then the prompt.",
    "Attach the files named in the prompt: templates from `docs/assets/templates/`, references from `art/ui/` and `assets/ui/`.",
    "When a result is good, attach it as a style reference for the next one.",
    "Save with the exact file name, then run the import (section C).",
  ]),
  L.P("The prompts are generated from `data/gear/*.json` and `data/monsters/*.json`. When the data changes, rebuild this file: `python tools/art_prompts/refs.py` then `node tools/art_prompts/build.js`."),
  new Paragraph({ children: [new PageBreak()] }),
  new Paragraph({ children: [new TextRun({ text: "Contents", font: L.FONT.head, size: 36, bold: true, color: L.C.accent })], spacing: { after: 200 } }),
  new TableOfContents("Contents", { hyperlink: true, headingStyleRange: "1-2" }),
];
const footer = { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [
  new TextRun({ text: "Bloody Voice — Art Prompts   ·   ", size: 16, color: L.C.muted }),
  new TextRun({ children: [PageNumber.CURRENT], size: 16, color: L.C.muted })] })] }) };
const header = { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
  border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: L.C.border, space: 2 } },
  children: [new TextRun({ text: "MODULES · CREATURES · ICONS", size: 15, color: L.C.muted })] })] }) };

const doc = new Document({
  creator: "Bloody Voice team", title: "Bloody Voice — Art Prompts (Modules, Creatures, Icons)",
  styles: L.styles, numbering: L.numbering, features: { updateFields: true },
  sections: [{
    properties: { page: { size: A4, margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN } } },
    headers: header, footers: footer,
    children: [...title, ...moduleSection(), ...creatureSection(), ...iconSection(), ...finishSection()].flat(Infinity),
  }],
});
const out = path.join(ROOT, "Bloody Voice - Art Prompts (Modules, Creatures, Icons).docx");
Packer.toBuffer(doc).then((buf) => { fs.writeFileSync(out, buf); console.log("written", out, buf.length); });
