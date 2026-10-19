#!/usr/bin/env bash
# release_gate.sh [PROJECT_DIR]
# Final quality gate before packaging. Prints PASS/FAIL/WARN per check. Exit code = number of FAILs.
set -uo pipefail
cd "${1:-.}" || exit 1
fail=0
ok()   { echo "PASS  $1"; }
bad()  { echo "FAIL  $1"; fail=$((fail+1)); }
warn() { echo "WARN  $1"; }
check() { local name="$1"; shift; if "$@" >/tmp/release_gate.log 2>&1; then ok "$name"; else bad "$name"; sed -n '1,20p' /tmp/release_gate.log; fi; }

RT="${RUST_AGENT_INFRA_DIR:-}/harness/base-skills/lean-shell/scripts/rt.sh"; [ -x "$RT" ] || RT=""
command -v cargo >/dev/null || { echo "error: cargo not found" >&2; exit 127; }

if git rev-parse --git-dir >/dev/null 2>&1; then
  if [ -z "$(git status --porcelain)" ]; then ok "git working tree clean"; else bad "git working tree has uncommitted changes"; fi
else warn "not a git repository"; fi

ver=$(grep -m1 -E '^version\s*=' Cargo.toml | sed -E 's/.*"([^"]+)".*/\1/')
if [ -n "${ver:-}" ] && [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then ok "version $ver"; else bad "no semantic version in Cargo.toml (workspace.package.version counts only for members)"; fi

check "cargo fmt --check" cargo fmt --all -- --check
check "cargo clippy -D warnings" $RT cargo clippy --workspace --all-targets -- -D warnings
check "cargo test --release" $RT cargo test --workspace --release
check "cargo build --release" $RT cargo build --workspace --release
if cargo audit --version >/dev/null 2>&1; then check "cargo audit" cargo audit; else warn "cargo audit not installed"; fi

todo=$(grep -rEn --include='*.rs' 'TODO|FIXME|todo!\(|unimplemented!\(' . 2>/dev/null | grep -v '/target/' | wc -l)
if [ "$todo" -eq 0 ]; then ok "no TODO/FIXME/todo!"; else bad "$todo TODO/FIXME/todo! marker(s) in code"; fi
for f in LICENSE LICENSE-MIT LICENSE-APACHE COPYING; do [ -f "$f" ] && have_license=1; done
[ "${have_license:-0}" = 1 ] && ok "license file present" || warn "no license file at project root"
[ -f README.md ] && ok "README.md present" || warn "no README.md"
[ -f CHANGELOG.md ] && { grep -q "$ver" CHANGELOG.md && ok "CHANGELOG mentions $ver" || bad "CHANGELOG has no entry for $ver"; } || warn "no CHANGELOG.md"

echo
[ $fail -eq 0 ] && echo "RELEASE GATE: PASS" || echo "RELEASE GATE: $fail failure(s)"
exit $fail
