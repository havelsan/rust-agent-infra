#!/usr/bin/env bash
# Shared helpers for .kilo/skills/scripts/*.sh
# Exit codes: 0 ok | 1 check failed | 2 usage error | 3 not implemented (scaffold)

DRY_RUN=0
ARGS=()
STEPS_JSON=""
FAILED=0
KDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # the .kilo directory
RTK_USED=false

json_str() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n")))' <<<"$1"
}

emit_text() {   # usage: printf '%s' "$text" | emit_text <script> <status> <source>
  python3 -c 'import json,sys; t=sys.stdin.read(); print(json.dumps({"script":sys.argv[1],"status":sys.argv[2] if t.strip() else "no-match","source":sys.argv[3],"text":t}))' "$1" "$2" "$3"
}

# rtk (Rust Token Killer) filters command output. It is used only when installed AND verified
# (kctx doctor / rtk_setup.sh writes .kilo/memory/rtk.ok after proving exit codes are kept),
# or when forced with KCTX_RTK=1. Disable with KCTX_RTK=0.
rtk_on() {
  command -v rtk >/dev/null 2>&1 || return 1
  case "${KCTX_RTK:-auto}" in 1|on) return 0 ;; 0|off) return 1 ;; esac
  [ -f "$KDIR/memory/rtk.ok" ]
}

rtk_wrap_ok() {   # only wrap commands that rtk is documented to filter
  case "$1 $2" in
    "cargo build"|"cargo test"|"cargo clippy"|"cargo check"|"git status"|"git diff"|"git log") return 0 ;;
  esac
  case "$1" in ls|find|grep) return 0 ;; esac
  return 1
}

parse_flags() {
  local a
  for a in "$@"; do
    case "$a" in
      --dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      *) ARGS+=("$a") ;;
    esac
  done
}

add_step() {
  local item
  item=$(printf '{"step":%s,"result":%s,"detail":%s}' "$(json_str "$1")" "$(json_str "$2")" "$(json_str "$3")")
  STEPS_JSON="${STEPS_JSON:+$STEPS_JSON,}$item"
}

run_step() {
  local name="$1"; shift
  if rtk_on && rtk_wrap_ok "$1" "${2:-}"; then set -- rtk "$@"; RTK_USED=true; fi
  if [ "$DRY_RUN" = 1 ]; then
    add_step "$name" "skipped" "dry-run: $*"
    return 0
  fi
  local out
  if out=$("$@" 2>&1); then
    add_step "$name" "pass" ""
  else
    FAILED=1
    add_step "$name" "fail" "$(printf '%s' "$out" | tail -n 20)"
  fi
}

finish() {
  local status=pass
  [ "$FAILED" = 1 ] && status=fail
  [ "$DRY_RUN" = 1 ] && status=dry-run
  printf '{"script":%s,"status":%s,"rtk":%s,"steps":[%s]}\n' "$(json_str "$1")" "$(json_str "$status")" "$RTK_USED" "$STEPS_JSON"
  [ "$FAILED" = 1 ] && exit 1
  exit 0
}

not_implemented() {
  local args_json dry=false
  args_json=$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1:]))' "${ARGS[@]}")
  [ "$DRY_RUN" = 1 ] && dry=true
  printf '{"script":%s,"status":"not_implemented","dry_run":%s,"args":%s,"note":"scaffold - implement this script before relying on it"}\n' "$(json_str "$1")" "$dry" "$args_json"
  exit 3
}
