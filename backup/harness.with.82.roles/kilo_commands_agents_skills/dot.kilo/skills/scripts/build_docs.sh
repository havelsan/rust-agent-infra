#!/usr/bin/env bash
# build_docs.sh
usage() { echo "Usage: build_docs.sh [--dry-run] [workspace-dir]  (cargo doc, mdbook if book.toml exists)"; }
source "$(dirname "$0")/_lib.sh"
parse_flags "$@"
cd "${ARGS[0]:-.}" || { echo '{"status":"fail","detail":"cannot enter workspace dir"}'; exit 2; }
run_step rustdoc env RUSTDOCFLAGS=-Dwarnings cargo doc --workspace --no-deps
if [ -f book.toml ]; then run_step mdbook mdbook build; fi
finish build_docs.sh
