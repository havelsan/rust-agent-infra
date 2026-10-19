#!/usr/bin/env bash
# rtk_setup.sh
usage() { echo "Usage: rtk_setup.sh [--dry-run]  (verifies rtk keeps exit codes, then enables it for the scripts)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
MARK="$KDIR/memory/rtk.ok"
if ! command -v rtk >/dev/null 2>&1; then
  rm -f "$MARK"; FAILED=1
  add_step rtk fail "rtk is not installed: brew install rtk-ai/tap/rtk  or  cargo install --git https://github.com/rtk-ai/rtk"
  finish rtk_setup.sh
fi
add_step version pass "$(rtk --version 2>&1 | head -n 1)"
if [ "$DRY_RUN" = 1 ]; then add_step verify skipped "dry-run"; finish rtk_setup.sh; fi
if ! command -v cargo >/dev/null 2>&1; then
  rm -f "$MARK"
  add_step verify skipped "cargo not found, exit codes unverified; rtk stays off in the scripts (KCTX_RTK=1 forces it)"
  finish rtk_setup.sh
fi
T=$(mktemp -d); mkdir -p "$T/src"
printf '[package]\nname = "rtk_probe"\nversion = "0.0.0"\nedition = "2021"\n' > "$T/Cargo.toml"
printf 'fn main() { let x: u32 = "not a number"; }\n' > "$T/src/main.rs"
( cd "$T" && rtk cargo build >/dev/null 2>&1 ); rc=$?
rm -rf "$T"
if [ "$rc" -ne 0 ]; then
  date > "$MARK"; add_step verify pass "rtk cargo build kept the failing exit code ($rc); rtk enabled in the scripts"
else
  rm -f "$MARK"; FAILED=1; add_step verify fail "rtk cargo build returned 0 for a failing build; rtk stays off in the scripts"
fi
add_step gain info "$(rtk gain 2>&1 | head -n 3 | tr '\n' ' ')"
finish rtk_setup.sh
