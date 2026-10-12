"""Copy the sounds the game uses from the owner's sound kit into audio/ (committed), under game names.

Run from the project root:
  python tools/import_audio.py ["<path to Bloody Voice - Sound Kit>"]
Default kit path: assets/audio_kit (a copy of the kit), else the folder on the owner's desktop.

The whole kit is CC0 / Public Domain (its SOURCES_AND_LICENSES.md; credits in docs/credits.md). Only what is listed
here is copied; data/audio/sounds.json says which file plays on which game event (GDD 24).
Godot plays OGG, WAV and MP3 (not FLAC), so only those are taken.
"""
from __future__ import annotations

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "audio"
DEFAULT_KITS = [ROOT / "assets" / "audio_kit", Path.home() / "OneDrive" / "Рабочий стол" / "Bloody Voice - Sound Kit"]
MONSTER_EVENTS = ["select_01", "select_02", "attack_01", "attack_02", "hit_01", "hit_02", "idle_01", "idle_02", "phase2_01"]

# kit-relative source -> audio/-relative destination
FILES = {
    "01_Music/graveyard_theme/Kokopelli's Graveyard.ogg": "music/MUSIC__graveyard.ogg",
    "01_Music/investigation_music/Unsolved-Investigation-isaiah658_0.ogg": "music/MUSIC__investigation.ogg",
    "01_Music/horror_atmosphere/Juhani Junkala - Post Apocalyptic Wastelands [Loop Ready].ogg": "music/MUSIC__horror.ogg",
    "01_Music/deep_humidity/deep-humidity.ogg": "music/MUSIC__deep_humidity.ogg",
    "02_Ambience/rain_thunder/Dark_Rainy_Night(ambience).ogg": "ambience/AMB__rain_night.ogg",
    "02_Ambience/dungeon/dungeon_ambient_1_0.ogg": "ambience/AMB__dungeon.ogg",
    "02_Ambience/dark_cavern/dark_cavern_ambient_001.ogg": "ambience/AMB__cavern.ogg",
    "02_Ambience/wind_chimes/Free Wind Chimes Ogg/wind_chimes_loop_1.ogg": "ambience/AMB__wind_chimes.ogg",
    "05_Creatures_and_Body/heartbeat/heartbeat_fast_0.wav": "sfx/BODY__heartbeat.wav",
    "05_Creatures_and_Body/crow/crow_caw.wav": "sfx/WORLD__crow.wav",
}


def kit_path() -> Path:
    if len(sys.argv) > 1:
        return Path(sys.argv[1])
    for p in DEFAULT_KITS:
        if p.exists():
            return p
    raise SystemExit("sound kit not found; pass its folder as the argument")


def plan(kit: Path) -> dict[Path, Path]:
    out: dict[Path, Path] = {}
    for f in sorted((kit / "00_START_HERE").iterdir()):
        if f.suffix.lower() in (".ogg", ".wav", ".mp3"):
            out[f] = OUT / "sfx" / f.name
    for d in sorted((kit / "07_Monsters" / "Monsters").iterdir()):
        for ev in MONSTER_EVENTS:
            src = d / f"{d.name}__{ev}.ogg"
            if src.exists():
                out[src] = OUT / "monsters" / d.name / src.name
    for rel, dst in FILES.items():
        out[kit / rel] = OUT / dst
    return out


def main() -> None:
    kit = kit_path()
    copied = missing = 0
    for src, dst in plan(kit).items():
        if not src.exists():
            print("MISSING", src.relative_to(kit))
            missing += 1
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if not dst.exists() or dst.stat().st_size != src.stat().st_size:
            shutil.copy2(src, dst)
            copied += 1
    print(f"audio: {copied} copied, {missing} missing ->", OUT)
    raise SystemExit(1 if missing else 0)


if __name__ == "__main__":
    main()
