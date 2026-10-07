# assets/ — source art drop folder

Put generated or drawn source images here (PNG/WEBP), using the naming rule
`<CODE>__<kind>__<state>.<ext>` (e.g. `NORDHAL__tile__normal.png`).

This folder is **not** imported by Godot (`.gdignore`) and **not** committed (too large).
Run `python tools/import_art.py` to convert and copy the art the game uses into `art/`.
