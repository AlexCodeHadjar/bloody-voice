# assets/ — source art drop folder

Put generated or drawn source images here (PNG/WEBP), using the naming rule
`<CODE>__<kind>__<state>.<ext>` (e.g. `NORDHAL__tile__normal.png`).

This folder is **not** imported by Godot (`.gdignore`) and **not** committed (too large).
Run `python tools/import_art.py` to convert and copy the art the game uses into `art/`.

Subfolders: `districts`, `map`, `ui`, `modules`, `monsters`, `icons`. The same folders inside `assets/png/`
are read the same way. Icons come either as one sheet per set (`icons/STATUS__sheet.png`, cut by the grid in
`data/ui/icons.json`) or one file per icon (`icons/STATUS__bleed.png`, trimmed and centred on a 256 px square).
