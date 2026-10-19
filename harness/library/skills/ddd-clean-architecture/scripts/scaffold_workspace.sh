#!/usr/bin/env bash
# scaffold_workspace.sh <project-name> [target-dir]
# Create a Cargo workspace with domain, application, infrastructure, and interface crates.
# It writes files only. It does not run cargo.
set -euo pipefail
if [ $# -lt 1 ]; then echo "usage: $0 <project-name> [target-dir]" >&2; exit 64; fi
name="$1"; dir="${2:-.}/$name"
id="${name//-/_}"
if [ -e "$dir" ]; then echo "error: $dir exists" >&2; exit 1; fi
mkdir -p "$dir/crates"/{domain,application,infrastructure,interface}/src

cat > "$dir/Cargo.toml" <<TOML
[workspace]
resolver = "2"
members = ["crates/domain", "crates/application", "crates/infrastructure", "crates/interface"]

[workspace.package]
version = "0.1.0"
edition = "2021"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
unwrap_used = "deny"
expect_used = "deny"
panic = "deny"
TOML

mk() { # crate, deps...
  local c="$1"; shift
  {
    echo "[package]"; echo "name = \"${id}_$c\""; echo "version.workspace = true"; echo "edition.workspace = true"; echo
    echo "[lints]"; echo "workspace = true"; echo
    echo "[dependencies]"
    for d in "$@"; do echo "${id}_$d = { path = \"../$d\" }"; done
  } > "$dir/crates/$c/Cargo.toml"
}
mk domain
mk application domain
mk infrastructure domain application
mk interface domain application infrastructure

cat > "$dir/crates/domain/src/lib.rs" <<'RS'
//! Domain layer: entities, value objects, domain rules, and ports. No I/O.
RS
cat > "$dir/crates/application/src/lib.rs" <<'RS'
//! Application layer: use cases that orchestrate the domain.
RS
cat > "$dir/crates/infrastructure/src/lib.rs" <<'RS'
//! Infrastructure layer: adapters that implement ports (storage, network, clock).
RS
cat > "$dir/crates/interface/src/main.rs" <<'RS'
//! Interface layer and composition root: wires adapters to use cases.
fn main() {
    println!("project started");
}
RS

cat > "$dir/layers.toml" <<TOML
order = ["domain", "application", "infrastructure", "interface"]

[crates]
${id}_domain = "domain"
${id}_application = "application"
${id}_infrastructure = "infrastructure"
${id}_interface = "interface"
TOML
echo "created $dir"
