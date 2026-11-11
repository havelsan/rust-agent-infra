#!/usr/bin/env bash
# build_packages.sh [--crate-dir DIR] [--package NAME] [--out DIR]
# Build the release binary, then the .deb and .rpm packages, and print checksums.
# Needs: cargo, cargo-deb, cargo-generate-rpm. Metadata: see references/cargo-metadata.md.
set -euo pipefail
crate_dir="."; package=""; out="dist"
while [ $# -gt 0 ]; do
  case "$1" in
    --crate-dir) crate_dir="$2"; shift 2;;
    --package) package="$2"; shift 2;;
    --out) out="$2"; shift 2;;
    *) echo "usage: $0 [--crate-dir DIR] [--package NAME] [--out DIR]" >&2; exit 64;;
  esac
done
RT="${RUST_AGENT_INFRA_DIR:-}/harness/base-skills/lean-shell/scripts/rt.sh"; [ -x "$RT" ] || RT=""
command -v cargo >/dev/null || { echo "error: cargo not found" >&2; exit 127; }
cargo deb --version >/dev/null 2>&1 || { echo "error: cargo-deb missing. Run: cargo install cargo-deb" >&2; exit 1; }
cargo generate-rpm --version >/dev/null 2>&1 || { echo "error: cargo-generate-rpm missing. Run: cargo install cargo-generate-rpm" >&2; exit 1; }

mkdir -p "$out"
pkgarg=(); [ -n "$package" ] && pkgarg=(-p "$package")

echo "== release build"
$RT cargo build --release "${pkgarg[@]}"
echo "== deb"
cargo deb --no-build "${pkgarg[@]}" --output "$out/"
echo "== rpm"
cargo generate-rpm -p "$crate_dir" -o "$out/"

echo "== results"
ls -l "$out"
( cd "$out" && sha256sum ./*.deb ./*.rpm | tee SHA256SUMS )
command -v dpkg-deb >/dev/null && for f in "$out"/*.deb; do dpkg-deb --info "$f" | head -12; done || true
command -v rpm >/dev/null && for f in "$out"/*.rpm; do rpm -qpi "$f" | head -12; done || true
