"""Apply a tuning table to a monsters file.

Usage (project root):
  python tools/tune_monsters.py data/monsters/mvp.json '{"lamplighter": {"hp": 62, "intents": 2, "grasp": [8]}, "rust_mantis": {"double_cut": [3, 2]}}'

Table: {monster_id: {"hp": n, "intents": n, <move_id>: [amount] or [amount, hits]}}.
For a move, the FIRST damage / block / heal / sanity effect gets the new amount (and hits, for damage).
Status stacks are edited by hand in the JSON. Move texts are not stored: the game builds them from
the effects (core/content/effect_text.gd), so they always match the numbers.
"""
import json
import sys

TUNABLE = ("damage", "block", "heal", "sanity")


def fail(message: str) -> None:
    sys.exit("tune_monsters: " + message)


def tune_move(monster_id: str, move: dict, spec) -> None:
    if not isinstance(spec, list) or not 1 <= len(spec) <= 2 or not all(type(v) is int for v in spec):
        fail(f"{monster_id}.{move['id']}: value must be [amount] or [amount, hits], got {spec!r}")
    for e in move["effects"]:
        if e["op"] in TUNABLE:
            e["amount"] = spec[0]
            if len(spec) == 2:
                if e["op"] != "damage":
                    fail(f"{monster_id}.{move['id']}: hits only apply to damage")
                e["hits"] = spec[1]
            return
    fail(f"{monster_id}.{move['id']}: no {'/'.join(TUNABLE)} effect to tune — edit the JSON by hand")


def main(path: str, table: dict) -> None:
    monsters = json.load(open(path, encoding="utf-8"))
    by_id = {m["id"]: m for m in monsters}
    for mid, changes in table.items():
        if mid not in by_id:
            fail(f"unknown monster '{mid}'")
        m = by_id[mid]
        moves = {mv["id"]: mv for mv in m["moves"]}
        for key, spec in changes.items():
            if key in ("hp", "intents"):
                if type(spec) is not int or spec < 1:
                    fail(f"{mid}.{key} must be a positive integer, got {spec!r}")
                m["hp" if key == "hp" else "intents_per_turn"] = spec
            elif key in moves:
                tune_move(mid, moves[key], spec)
            else:
                fail(f"{mid}: unknown move '{key}'")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(json.dumps(monsters, indent=1, ensure_ascii=False) + "\n")
    print("tuned", ", ".join(table))


if __name__ == "__main__":
    main(sys.argv[1], json.loads(sys.argv[2]))
