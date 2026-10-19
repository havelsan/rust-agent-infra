#!/usr/bin/env bash
# install.sh [--link] [--force] [RUST_AGENT_INFRA_DIR]
# Install the skills into $RUST_AGENT_INFRA_DIR/harness. Existing skills are kept unless --force.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode=copy; force=0; infra="${RUST_AGENT_INFRA_DIR:-}"
for arg in "$@"; do
  case "$arg" in
    --link) mode=link;;
    --force) force=1;;
    -h|--help) sed -n '2,3p' "$0"; exit 0;;
    *) infra="$arg";;
  esac
done
[ -n "$infra" ] || { echo "error: give RUST_AGENT_INFRA_DIR as argument or environment variable" >&2; exit 64; }
h="$infra/harness"
install_group() { # source-dir target-dir
  local src="$1" dst="$2"
  mkdir -p "$dst"
  for s in "$src"/*/; do
    local name; name="$(basename "$s")"
    if [ -e "$dst/$name" ] || [ -L "$dst/$name" ]; then
      if [ $force -eq 1 ]; then rm -rf "$dst/$name"; else echo "keep   $dst/$name (exists, use --force)"; continue; fi
    fi
    if [ "$mode" = link ]; then ln -s "${s%/}" "$dst/$name"; else cp -r "${s%/}" "$dst/$name"; fi
    echo "$mode   $dst/$name"
  done
}
install_group "$here/base-skills"        "$h/base-skills"
install_group "$here/coordinator-skills" "$h/coordinator-skills"
install_group "$here/worker-skills"      "$h/worker-skills"
install_group "$here/library/skills"     "$h/library/skills"
mkdir -p "$h/library/roles"
for f in "$here"/library/roles/*.md; do
  t="$h/library/roles/$(basename "$f")"
  if [ -e "$t" ] && [ $force -eq 0 ]; then echo "keep   $t (exists, use --force)"; else cp "$f" "$t"; echo "copy   $t"; fi
done
mkdir -p "$h/agents-md"
for r in coordinator worker; do mkdir -p "$h/agents-md/$r"; if [ -e "$h/agents-md/$r/AGENTS.md" ] && [ $force -eq 0 ]; then echo "keep   $h/agents-md/$r/AGENTS.md (exists, use --force)"; else cp "$here/agents-md/$r/AGENTS.md" "$h/agents-md/$r/AGENTS.md"; echo "copy   $h/agents-md/$r/AGENTS.md"; fi; done
find "$h" -path '*/scripts/*' -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
cat <<MSG

Done. Next steps:
 1. Add the linking and environment lines from README.md to start_agents.sh.
 2. Run once: python3 $h/base-skills/gitea-issues/scripts/gitea.py ensure-labels
MSG
