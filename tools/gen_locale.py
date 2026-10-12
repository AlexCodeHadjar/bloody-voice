"""Keep locale/strings.csv (keys, ru, en) in step with the game data (GDD 22.5).

Run from the project root:  python tools/gen_locale.py

- adds a row for every content text found in data/*.json (card names and texts, creatures with their parts, moves and
  phases, weapons, modules, mechanisms, armor, shapes, districts with their areas, district maps: landmarks, streets, zones;
  creature sign tags, petition letters of contracts, rumor witnesses and gossip, skill web nodes, factions, district events, affixes, the story); the en column is refreshed from
  the JSON (the English working name), the ru column is kept;
- keeps every other row (ui.*, effect.*, status.*, log.*) as it is;
- prints the keys that still have no Russian text (tests/test_locale.gd fails on them).
The key scheme must match core/content/content_loc.gd (the test checks both sides).
"""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV = ROOT / "locale" / "strings.csv"
DATA = ROOT / "data"
KEEP_EN = None  # the JSON has no English text for this key: keep the en column of the table as it is


def _json(rel: str):
    return json.loads((DATA / rel).read_text(encoding="utf-8"))


def content_rows() -> dict[str, str]:
    """key -> English text, in a stable order."""
    rows: dict[str, str] = {}
    for f in sorted((DATA / "cards").glob("*.json")):
        for c in json.loads(f.read_text(encoding="utf-8")):
            rows[f"card.{c['id']}.name"] = c["name"]
            rows[f"card.{c['id']}.text"] = c["text"]
    for f in sorted((DATA / "monsters").glob("*.json")):
        data = json.loads(f.read_text(encoding="utf-8"))
        for m in data["monsters"] if isinstance(data, dict) else data:
            base = f"monster.{m['id']}"
            rows[f"{base}.name"] = m["name"]
            for p in m.get("parts", []):
                rows[f"{base}.part.{p['id']}"] = p["name"]
            for mv in m.get("moves", []):
                rows[f"{base}.move.{mv['id']}"] = mv["name"]
            for i, ph in enumerate(m.get("phases", [])):
                rows[f"{base}.phase.{i}"] = ph["name"]
    for w in _json("gear/weapons.json"):
        rows[f"weapon.{w['id']}.name"] = w["name"]
        for s in w.get("sections", []):
            rows[f"weapon.{w['id']}.section.{s['id']}"] = s["name"]
    for kind, rel in (("module", "gear/modules.json"), ("mechanism", "gear/mechanisms.json")):
        for x in _json(rel):
            rows[f"{kind}.{x['id']}.name"] = x["name"]
            rows[f"{kind}.{x['id']}.effect"] = x["effect"]
            for i, t in enumerate(x.get("tiers", [])):
                rows[f"{kind}.{x['id']}.tier.{i + 2}.effect"] = t["effect"]
    for a in _json("gear/armor.json"):
        rows[f"armor.{a['id']}.name"] = a["name"]
    for sid, s in _json("gear/shapes.json").items():
        if not sid.startswith("_"):
            rows[f"shape.{sid}.name"] = s["name"]
    for d in _json("city/districts.json"):
        base = f"district.{d['id']}"
        for field in ("name", "class", "controller", "danger", "look"):
            rows[f"{base}.{field}"] = d[field]
        for a in d.get("areas", []):
            rows[f"{base}.area.{a['id']}"] = a["name"]
    for f in sorted((DATA / "city" / "district_maps").glob("*.json")):
        m = json.loads(f.read_text(encoding="utf-8"))
        base = f"district_map.{m['district']}"
        for lm in m.get("landmarks", []):
            rows[f"{base}.landmark.{lm['id']}.name"] = lm["name"]
            rows[f"{base}.landmark.{lm['id']}.desc"] = lm.get("desc", KEEP_EN)
        for st in m.get("streets", []):
            rows[f"{base}.street.{st['id']}"] = st["name"]
        for z in m.get("zones", []):
            rows[f"{base}.zone.{z['id']}"] = z.get("name", KEEP_EN)
    for tid, t in _json("contracts/tags.json").items():
        if not tid.startswith("_"):
            rows[f"tag.{tid}"] = t["name"]
    for pe in _json("contracts/petitions.json"):
        rows[f"petition.{pe['id']}.from"] = pe["from"]
        rows[f"petition.{pe['id']}.text"] = pe["text"]
    for wi in _json("rumors/rumors.json")["witnesses"]:
        rows[f"rumor_witness.{wi['id']}.text"] = wi["text"]
    for f in sorted((DATA / "skills").glob("*.json")):
        web = json.loads(f.read_text(encoding="utf-8"))
        for nd in web["nodes"]:
            rows[f"skill.{web['web']}.{nd['id']}.name"] = nd["name"]
            rows[f"skill.{web['web']}.{nd['id']}.text"] = nd["text"]
    st = _json("story/grey.json")
    rows["story.end.end_from"] = st["end"]["from"]
    rows["story.end.end_text"] = st["end"]["text"]
    for s in st["steps"]:
        rows[f"story.{s['id']}.after_from"] = s["after"]["from"]
        rows[f"story.{s['id']}.after_text"] = s["after"]["text"]
        for c in s.get("choices", []):
            rows[f"story.{s['id']}.choice.{c['id']}.text"] = c["text"]
    for af in _json("affixes/affixes.json")["affixes"]:
        rows[f"affix.{af['id']}"] = af["name"]
        rows[f"affix.{af['id']}.move"] = af["move"]["name"]
    for ev in _json("city/events.json")["events"]:
        for k in ("name", "news", "end_news"):
            rows[f"event.{ev['id']}.{k}"] = ev[k]
    for fa in _json("factions/factions.json")["factions"]:
        rows[f"faction.{fa['id']}.name"] = fa["name"]
        rows[f"faction.{fa['id']}.text"] = fa["text"]
    for g in _json("rumors/rumors.json")["gossip"]:
        rows[f"rumor_gossip.{g['id']}.text"] = g["text"]
    return rows


def read_table() -> dict[str, list[str]]:
    if not CSV.exists():
        return {}
    with CSV.open(encoding="utf-8", newline="") as fh:
        reader = csv.reader(fh)
        next(reader, None)
        return {r[0]: [r[1] if len(r) > 1 else "", r[2] if len(r) > 2 else ""] for r in reader if r and r[0]}


def write_table(table: dict[str, list[str]]) -> None:
    CSV.parent.mkdir(parents=True, exist_ok=True)
    with CSV.open("w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["keys", "ru", "en"])
        for key, (ru, en) in table.items():
            w.writerow([key, ru, en])


def main() -> None:
    table = read_table()
    content = content_rows()
    merged = {k: v for k, v in table.items() if k not in content}
    for key, en in content.items():
        old = table.get(key, ["", ""])
        merged[key] = [old[0], old[1] if en is KEEP_EN else en]
    write_table(merged)
    missing = [k for k, (ru, _) in merged.items() if not ru]
    print(f"{len(merged)} keys, {len(missing)} without Russian text")
    for k in missing:
        print("  no ru:", k)


if __name__ == "__main__":
    main()
