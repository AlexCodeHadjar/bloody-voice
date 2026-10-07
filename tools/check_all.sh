#!/usr/bin/env bash
# One-stop project check (run from the project root in Git Bash):
#   tools/check_all.sh                 import + tests
#   tools/check_all.sh --balance       + bot balance report (200 fights per creature)
#   tools/check_all.sh --shots <dir>   + auto-screenshots into <dir> (absolute path)
# Exit code is non-zero if import, tests (any failure or script error) or the balance run fail.
set -u
G="${GODOT:-/d/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.." || exit 2

balance=0
shots=""
while [ $# -gt 0 ]; do
	case "$1" in
		--balance) balance=1 ;;
		--shots)
			[ $# -ge 2 ] || { echo "--shots needs an absolute folder"; exit 2; }
			shift
			shots="$1"
			;;
		*) echo "unknown option: $1"; exit 2 ;;
	esac
	shift
done

echo "== import"
timeout 600 "$G" --headless --path . --import >/dev/null 2>&1 || { echo "IMPORT FAILED"; exit 1; }

echo "== tests"
out=$(timeout 600 "$G" --headless --path . -s res://tests/run_tests.gd 2>&1)
rc=$?
echo "$out" | grep -E "FAIL|SCRIPT ERROR|Parse Error|tests, [0-9]+ failures" || true
if [ $rc -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
	echo "TESTS FAILED"
	exit 1
fi

if [ $balance -eq 1 ]; then
	echo "== balance"
	timeout 900 "$G" --headless --path . -s res://tests/bot/autoplay.gd -- --fights=200 2>&1 | grep -v "^Godot\|^\s*$"
	[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "BALANCE RUN FAILED"; exit 1; }
fi

if [ -n "$shots" ]; then
	echo "== screenshots -> $shots"
	timeout 300 "$G" --path . --resolution 1920x1080 -- --shots="$shots" 2>&1 | grep -iE "error" || true
	ls "$shots"
fi
echo "== OK"
