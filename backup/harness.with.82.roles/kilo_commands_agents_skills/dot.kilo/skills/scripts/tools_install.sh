#!/usr/bin/env bash
# tools_install.sh
usage() { echo "Usage: tools_install.sh [--dry-run] [--yes] [--only rtk|graphify|caveman|ponytail]"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
YES=0; ONLY=""
i=0
while [ $i -lt ${#ARGS[@]} ]; do
  case "${ARGS[$i]}" in --yes) YES=1 ;; --only) i=$((i+1)); ONLY="${ARGS[$i]}" ;; esac
  i=$((i+1))
done
want() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }
try_install() {   # name  check-command  install-command
  if bash -c "$2" >/dev/null 2>&1; then add_step "$1" present ""; return; fi
  if [ "$YES" = 1 ] && [ "$DRY_RUN" = 0 ]; then
    if out=$(bash -c "$3" 2>&1); then add_step "$1" installed-now ""; else FAILED=1; add_step "$1" fail "$(printf '%s' "$out" | tail -n 5)"; fi
  else
    add_step "$1" missing "install: $3"
  fi
}
if want rtk; then
  if command -v brew >/dev/null 2>&1; then C="brew install rtk-ai/tap/rtk"; else C="cargo install --git https://github.com/rtk-ai/rtk"; fi
  try_install rtk "command -v rtk" "$C"
fi
if want graphify; then
  if command -v uv >/dev/null 2>&1; then C="uv tool install graphifyy"; elif command -v pipx >/dev/null 2>&1; then C="pipx install graphifyy"; else C="pip install graphifyy"; fi
  try_install graphify "command -v graphify" "$C"
fi
if want caveman; then
  if [ "$ONLY" = caveman ]; then
    try_install caveman "ls ~/.claude/skills/caveman .claude/skills/caveman ~/.agents/skills/caveman .kilo/skills/caveman 2>/dev/null | grep -q ." "npx --yes skills add JuliusBrussee/caveman"
  else
    add_step caveman skipped "not installed by default: the official skill adds about 1-1.5k input tokens per turn. The pack applies built-in style rules instead (budget.json style.caveman). Install explicitly with --only caveman"
  fi
fi
if want ponytail; then
  add_step ponytail built-in "the ladder is built into step prompts for dev roles and skill ponytail-ladder; official plugin for Claude Code: /plugin install ponytail@ponytail"
fi
finish tools_install.sh
