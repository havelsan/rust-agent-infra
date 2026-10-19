#!/usr/bin/env bash
# rt.sh <command...>   run a command with small output (rtk when installed, otherwise capped raw output)
# rt.sh grep PATTERN [PATH] | find GLOB [PATH] | ls [PATH]   compact search and listing
# rt.sh read <file>    print a file compactly (rtk read, otherwise first RT_MAX_CHARS characters)
# Env: RT_MAX_LINES (default 60), RT_MAX_CHARS (default 6000). Exit code = command exit code.
set -uo pipefail
[ $# -ge 1 ] || { echo "usage: rt.sh <command...> | rt.sh read <file>" >&2; exit 64; }
MAXL="${RT_MAX_LINES:-60}"; MAXC="${RT_MAX_CHARS:-6000}"

# The crate named "rtk" on crates.io can be a different tool. 'rtk gain' proves it is Rust Token Killer.
have_rtk=0
if command -v rtk >/dev/null 2>&1 && rtk gain >/dev/null 2>&1; then have_rtk=1; fi

if [ "$1" = "read" ]; then
  [ $# -eq 2 ] || { echo "usage: rt.sh read <file>" >&2; exit 64; }
  if [ $have_rtk = 1 ]; then rtk read "$2" | head -c "$MAXC"; else head -c "$MAXC" "$2"; fi
  [ "$(wc -c < "$2")" -gt "$MAXC" ] && printf '\n[cut at %s chars. Use mem.py slice for the rest]\n' "$MAXC"
  exit 0
fi

use_rtk=0
if [ $have_rtk = 1 ]; then
  case "${1:-} ${2:-}" in
    "cargo test"|"cargo build"|"cargo clippy"|"git status"|"git log"|"git diff"|"git add"|"git commit"|"git push"|"git pull") use_rtk=1;;
  esac
fi
case "$1" in
  grep) shift  # rt.sh grep PATTERN [PATH]
        pat="${1:?usage: rt.sh grep PATTERN [PATH]}"; path="${2:-.}"
        if [ $have_rtk = 1 ]; then out=$(rtk grep "$pat" "$path" 2>&1); rc=$?
        else out=$(grep -rn --exclude-dir=target --exclude-dir=.git -- "$pat" "$path" 2>&1); rc=$?; fi ;;
  find) shift  # rt.sh find GLOB [PATH]
        glob="${1:?usage: rt.sh find GLOB [PATH]}"; path="${2:-.}"
        if [ $have_rtk = 1 ]; then out=$(rtk find "$glob" "$path" 2>&1); rc=$?
        else out=$(find "$path" -name "$glob" -not -path '*/target/*' -not -path '*/.git/*' 2>&1); rc=$?; fi ;;
  ls)   shift
        if [ $have_rtk = 1 ]; then out=$(rtk ls "${1:-.}" 2>&1); rc=$?; else out=$(ls -la "${1:-.}" 2>&1); rc=$?; fi ;;
  *)    if [ $use_rtk = 1 ]; then out=$(rtk "$@" 2>&1); rc=$?; else out=$("$@" 2>&1); rc=$?; fi ;;
esac

n=$(printf '%s\n' "$out" | wc -l)
if [ "$n" -gt "$MAXL" ]; then
  h=$((MAXL / 2))
  printf '%s\n' "$out" | head -n "$h"
  echo "[... $((n - MAXL)) lines cut by rt.sh. Narrow the command, or set RT_MAX_LINES ...]"
  printf '%s\n' "$out" | tail -n "$h"
else
  printf '%s\n' "$out"
fi
exit $rc
