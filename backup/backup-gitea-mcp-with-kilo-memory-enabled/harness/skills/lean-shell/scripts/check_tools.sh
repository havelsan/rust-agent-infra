#!/usr/bin/env bash
# check_tools.sh - show which optional token-saving tools are installed. All of them are optional.
ok()   { printf 'OK       %-10s %s\n' "$1" "$2"; }
miss() { printf 'MISSING  %-10s %s\n' "$1" "$2"; }

if command -v rtk >/dev/null 2>&1 && rtk gain >/dev/null 2>&1; then ok rtk "Rust Token Killer"
else miss rtk "install: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh   (or: cargo install --git https://github.com/rtk-ai/rtk). Do NOT use 'cargo install rtk'."; fi

if command -v graphify >/dev/null 2>&1; then ok graphify "$(ls graphify-out/graph.json 2>/dev/null || echo 'no graph yet: run graph.sh build')"
else miss graphify "install: uv tool install graphifyy   (or: pipx install graphifyy)"; fi

find_skill() { for d in .kilo/skills "$HOME/.kilo/skills" .claude/skills "$HOME/.claude/skills" .agents/skills; do [ -f "$d/$1/SKILL.md" ] && { echo "$d/$1"; return 0; }; done; return 1; }
if p=$(find_skill caveman); then ok caveman "$p"
else miss caveman "copy skills/caveman/SKILL.md from github.com/JuliusBrussee/caveman into .kilo/skills/caveman/ (AGENTS.md already holds the short rules)"; fi
if p=$(find_skill ponytail); then ok ponytail "$p"
else miss ponytail "copy the skills/ folders from github.com/DietrichGebert/ponytail into .kilo/skills/ (the minimal-build skill holds the short ladder)"; fi
exit 0
