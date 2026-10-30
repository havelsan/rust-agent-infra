---
name: rust-40-project-structure-2of2
description: Rust rules module 40: Project Structure (part 2 of 2). 7 rules, priority LOW. Load on its own to review or write Rust code against this topic only. Rule prefixes: `proj-`
---

# Project Structure (part 2/2)

Priority: LOW. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `proj-prelude-module` - Create prelude module for common imports
- `proj-bin-dir` - Put multiple binaries in src/bin/
- `proj-workspace-large` - Use workspaces for large projects
- `proj-workspace-deps` - Use workspace dependency inheritance for consistent versions across crates
- `proj-feature-additive` - Design Cargo features to be strictly additive
- `proj-msrv-declare` - Declare `rust-version` (MSRV) in Cargo.toml and test it in CI
- `proj-build-rs-minimal` - Keep `build.rs` minimal, deterministic, and idempotent

---

## proj-prelude-module

> Create prelude module for common imports

### Why It Matters

A `prelude` module collects the most commonly used types and traits for glob import. Users write `use my_crate::prelude::*` instead of many individual imports. This follows the pattern established by `std::prelude`.

### Bad

```rust
// Users must import everything individually
use my_crate::Client;
use my_crate::Config;
use my_crate::Error;
use my_crate::Request;
use my_crate::Response;
use my_crate::traits::Handler;
use my_crate::traits::Middleware;
use my_crate::types::Method;
```

### Good

```rust
// src/lib.rs
pub mod prelude {
    pub use crate::{
        Client,
        Config,
        Error,
        Request,
        Response,
    };
    pub use crate::traits::{Handler, Middleware};
    pub use crate::types::Method;
}

// Users write:
use my_crate::prelude::*;
```

### What to Include

| Include | Don't Include |
|---------|---------------|
| Core types users always need | Rarely-used types |
| Common traits | Implementation details |
| Error types | Internal helpers |
| Extension traits | Feature-gated items (usually) |
| Type aliases | Everything |

### Example: Web Framework Prelude

```rust
pub mod prelude {
    // Core request/response
    pub use crate::{Request, Response, Body};
    
    // Error handling
    pub use crate::Error;
    
    // Common traits
    pub use crate::traits::{FromRequest, IntoResponse};
    
    // Routing
    pub use crate::Router;
    
    // HTTP types
    pub use crate::http::{Method, StatusCode};
}
```

### Example: Database Library Prelude

```rust
pub mod prelude {
    // Connection and pool
    pub use crate::{Connection, Pool};
    
    // Query building
    pub use crate::query::{Query, Select, Insert, Update, Delete};
    
    // Traits for custom types
    pub use crate::traits::{FromRow, ToSql};
    
    // Error type
    pub use crate::Error;
}
```

### Pattern: Tiered Preludes

```rust
// Minimal prelude
pub mod prelude {
    pub use crate::{Client, Config, Error};
}

// Full prelude for power users
pub mod full_prelude {
    pub use crate::prelude::*;
    pub use crate::advanced::*;
    pub use crate::extensions::*;
}
```

### Pattern: Feature-Gated Prelude Items

```rust
pub mod prelude {
    pub use crate::{Client, Error};
    
    #[cfg(feature = "async")]
    pub use crate::async_client::AsyncClient;
    
    #[cfg(feature = "serde")]
    pub use crate::serde::{Serialize, Deserialize};
}
```

### Guidelines

1. **Be conservative** - Only include truly common items
2. **Avoid conflicts** - Don't include names that might clash (e.g., `Error`)
3. **Document it** - List what's included in module docs
4. **Stay stable** - Removing items is breaking change

### Documenting the Prelude

```rust
//! Common imports for convenient glob importing.
//!
//! # Usage
//!
//! ```
//! use my_crate::prelude::*;
//! ```
//!
//! # Contents
//!
//! This prelude re-exports:
//! - [`Client`] - The main API client
//! - [`Config`] - Client configuration
//! - [`Error`] - Error type
pub mod prelude {
    // ...
}
```

Related: `proj-pub-use-reexport`, `api-extension-trait`, `doc-module-inner`

## proj-bin-dir

> Put multiple binaries in src/bin/

### Why It Matters

When a crate produces multiple binaries, placing them in `src/bin/` keeps the project organized. Each file becomes a separate binary target automatically, without manual `Cargo.toml` configuration.

### Bad

```
my-project/
├── Cargo.toml        # Complex [[bin]] sections for each binary
├── src/
│   ├── main.rs       # Which binary is this?
│   ├── server.rs     # Is this a module or binary?
│   ├── cli.rs        # Unclear
│   └── lib.rs
```

```toml
# Cargo.toml - verbose and error-prone
[[bin]]
name = "server"
path = "src/server.rs"

[[bin]]
name = "cli"
path = "src/cli.rs"
```

### Good

```
my-project/
├── Cargo.toml        # Clean, no [[bin]] needed
├── src/
│   ├── lib.rs        # Shared library code
│   └── bin/
│       ├── server.rs # Binary: my-project-server (or just server)
│       └── cli.rs    # Binary: my-project-cli (or just cli)
```

Each file in `src/bin/` automatically becomes a binary named after the file.

### Running Binaries

```bash
# Run specific binary
cargo run --bin server
cargo run --bin cli

# Build specific binary
cargo build --bin server

# Build all binaries
cargo build --bins
```

### Pattern: Binary with Multiple Files

For complex binaries, use directories:

```
src/
├── lib.rs
└── bin/
    ├── server/
    │   ├── main.rs      # Entry point
    │   ├── config.rs    # Server-specific module
    │   └── handlers.rs
    └── cli/
        ├── main.rs
        └── commands.rs
```

### Pattern: Shared Library Code

```rust
// src/lib.rs - Shared code
pub mod config;
pub mod database;
pub mod models;

// src/bin/server.rs - Server binary
use my_project::{config, database, models};

fn main() {
    let config = config::load();
    let db = database::connect(&config);
    // ...
}

// src/bin/cli.rs - CLI binary
use my_project::{config, models};

fn main() {
    let config = config::load();
    // CLI logic using shared code
}
```

### Binary Naming

| File Path | Binary Name |
|-----------|-------------|
| `src/main.rs` | `my-project` (crate name) |
| `src/bin/server.rs` | `server` |
| `src/bin/my-cli.rs` | `my-cli` |
| `src/bin/server/main.rs` | `server` |

### Explicit Configuration

When you need custom settings:

```toml
[[bin]]
name = "my-server"
path = "src/bin/server.rs"
required-features = ["server"]

[[bin]]
name = "my-cli"
path = "src/bin/cli.rs"
```

### Pattern: Default Binary

```toml
# src/main.rs is the default binary
# Additional binaries in src/bin/

[package]
name = "my-tool"
default-run = "my-tool"  # Or specify another
```

Related: `proj-lib-main-split`, `proj-workspace-large`, `proj-flat-small`

## proj-workspace-large

> Use workspaces for large projects

### Why It Matters

Cargo workspaces manage multiple related crates under one repository. They share a single `Cargo.lock`, build cache, and can be versioned together. For large projects, workspaces improve build times, enforce modularity, and simplify dependency management.

### Bad

```
# Separate repositories for each crate
my-app-core/
my-app-cli/
my-app-server/
my-app-common/

# Each has its own Cargo.lock
# Dependencies may drift
# Cross-crate development is painful
```

### Good

```
my-app/
├── Cargo.toml          # Workspace root
├── Cargo.lock          # Shared lock file
├── crates/
│   ├── core/
│   │   ├── Cargo.toml
│   │   └── src/
│   ├── cli/
│   │   ├── Cargo.toml
│   │   └── src/
│   ├── server/
│   │   ├── Cargo.toml
│   │   └── src/
│   └── common/
│       ├── Cargo.toml
│       └── src/
└── README.md
```

### Workspace Cargo.toml

```toml
# Root Cargo.toml
[workspace]
resolver = "3"  # default for the 2024 edition; use "2" for 2021
members = [
    "crates/core",
    "crates/cli",
    "crates/server",
    "crates/common",
]

# Shared dependencies - all crates use same versions
[workspace.dependencies]
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
tracing = "0.1"
anyhow = "1.0"

# Shared lints
[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
all = "warn"
```

### Member Crate Cargo.toml

```toml
# crates/core/Cargo.toml
[package]
name = "my-app-core"
version = "0.1.0"
edition = "2021"

[dependencies]
# Inherit from workspace
tokio = { workspace = true }
serde = { workspace = true }

# Crate-specific dependencies
uuid = "1.0"

# Internal dependency
my-app-common = { path = "../common" }

[lints]
workspace = true  # Inherit workspace lints
```

### When to Use Workspaces

| Scenario | Recommendation |
|----------|----------------|
| Single binary/library | No workspace needed |
| Library + CLI | Maybe, depends on size |
| Multiple related crates | Yes |
| Shared internal libraries | Yes |
| Microservices mono-repo | Yes |
| Plugin architecture | Yes |

### Benefits

| Aspect | Single Crate | Workspace |
|--------|--------------|-----------|
| Build cache | Crate only | Shared across all |
| Dependency versions | Per-crate | Synchronized |
| Compile times | Full rebuild | Incremental |
| Modularity | Files/modules | Crate boundaries |
| Publishing | Single crate | Independent |

### Commands

```bash
# Build all crates
cargo build --workspace

# Build specific crate
cargo build -p my-app-core

# Test all crates
cargo test --workspace

# Run specific binary
cargo run -p my-app-cli

# Check all
cargo check --workspace
```

### Pattern: Virtual Workspace

Root Cargo.toml is workspace-only (no `[package]`):

```toml
[workspace]
members = ["crates/*"]

[workspace.dependencies]
# ...
```

### Pattern: Crate Interdependencies

```toml
# crates/server/Cargo.toml
[dependencies]
my-app-core = { path = "../core" }
my-app-common = { path = "../common" }
```

Related: `proj-workspace-deps`, `proj-bin-dir`, `proj-lib-main-split`

## proj-workspace-deps

> Use workspace dependency inheritance for consistent versions across crates

### Why It Matters

Multi-crate workspaces often have dependency version drift—different crates using different versions of the same dependency. Workspace dependency inheritance (Rust 1.64+) lets you declare dependencies once in the workspace `Cargo.toml` and inherit them in member crates, ensuring consistency.

### Bad

```toml
# crate-a/Cargo.toml
[dependencies]
serde = "1.0.150"
tokio = "1.25"

# crate-b/Cargo.toml  
[dependencies]
serde = "1.0.188"  # Different version!
tokio = "1.32"     # Different version!

# Version drift leads to:
# - Larger binaries (multiple versions)
# - Compilation time increase
# - Subtle behavior differences
```

### Good

```toml
# Root Cargo.toml
[workspace]
members = ["crate-a", "crate-b", "crate-c"]

[workspace.dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = { version = "1.32", features = ["full"] }
thiserror = "1.0"
anyhow = "1.0"
tracing = "0.1"

# crate-a/Cargo.toml
[dependencies]
serde.workspace = true
tokio.workspace = true

# crate-b/Cargo.toml
[dependencies]
serde.workspace = true
tokio.workspace = true
thiserror.workspace = true
```

### Override Features

```toml
# Root Cargo.toml
[workspace.dependencies]
tokio = { version = "1.32", features = ["rt-multi-thread"] }

# crate-a/Cargo.toml - add extra features
[dependencies]
tokio = { workspace = true, features = ["net", "io-util"] }
# Gets both workspace features AND local features

# crate-b/Cargo.toml - minimal features
[dependencies]
tokio = { workspace = true }  # Just workspace features
```

### Dev and Build Dependencies

```toml
# Root Cargo.toml
[workspace.dependencies]
criterion = "0.5"
proptest = "1.0"
trybuild = "1.0"
cc = "1.0"

# crate-a/Cargo.toml
[dev-dependencies]
criterion.workspace = true
proptest.workspace = true

[build-dependencies]
cc.workspace = true
```

### Internal Crate Dependencies

```toml
# Root Cargo.toml
[workspace.dependencies]
# Internal crates
my-core = { path = "crates/core" }
my-utils = { path = "crates/utils" }
my-derive = { path = "crates/derive" }

# External crates
serde = "1.0"

# crate-a/Cargo.toml
[dependencies]
my-core.workspace = true
my-utils.workspace = true
serde.workspace = true
```

### Optional Dependencies

```toml
# Root Cargo.toml
[workspace.dependencies]
serde = { version = "1.0", optional = true }  # Won't work!

# Optional must be set in member, not workspace
[workspace.dependencies]
serde = "1.0"

# crate-a/Cargo.toml
[dependencies]
serde = { workspace = true, optional = true }

[features]
serde = ["dep:serde"]
```

### Complete Workspace Example

```toml
# Root Cargo.toml
[workspace]
members = ["crates/*"]
resolver = "3"  # default for the 2024 edition; use "2" for 2021

[workspace.package]
version = "0.1.0"
edition = "2021"
license = "MIT"
repository = "https://github.com/user/repo"

[workspace.dependencies]
# Internal
my-core = { path = "crates/core", version = "0.1" }

# Async
tokio = { version = "1.32", features = ["full"] }
futures = "0.3"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Error handling
thiserror = "1.0"
anyhow = "1.0"

# Logging
tracing = "0.1"
tracing-subscriber = "0.3"

# Testing
proptest = "1.0"
criterion = { version = "0.5", features = ["html_reports"] }

# crates/core/Cargo.toml
[package]
name = "my-core"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]
serde.workspace = true
thiserror.workspace = true

[dev-dependencies]
proptest.workspace = true
```

Related: `proj-lib-main-split`, `api-serde-optional`, `lint-deny-correctness`

## proj-feature-additive

> Design Cargo features to be strictly additive

### Why It Matters

Cargo unifies features across the dependency graph: if any crate in the build enables a feature, every consumer of that crate gets it. A feature that removes or changes existing behavior will break crates that depend on the baseline behavior the moment a third dependency enables it. Features must only add capability — new trait impls, additional dependencies, optional integrations — never subtract. Mutually exclusive features are an anti-pattern in the Cargo model.

### Bad

```toml
[features]
# "no_std" disables std — enabling it REMOVES behavior
no_std = []

[dependencies]
# and somewhere in lib.rs:
# #[cfg(not(feature = "no_std"))]
# use std::collections::HashMap;
```

```rust
// lib.rs — toggling off std via a feature is non-additive
#[cfg(not(feature = "no_std"))]
use std::vec::Vec;

#[cfg(feature = "no_std")]
use alloc::vec::Vec;
```

### Good

```toml
[features]
# "std" ADDS std support; no_std is the baseline
default = ["std"]
std = []

# Optional integrations — purely additive
serde = ["dep:serde"]
tokio = ["dep:tokio"]

[dependencies]
serde = { version = "1", optional = true }
tokio = { version = "1", optional = true }
```

```rust
// lib.rs — std is opt-in, no_std is the default baseline
#![cfg_attr(not(feature = "std"), no_std)]

#[cfg(feature = "std")]
use std::vec::Vec;

#[cfg(not(feature = "std"))]
use alloc::vec::Vec;
```

### Rules for Additive Features

- A feature may add new items, trait impls, or dependencies — never gate-away existing ones.
- If you ship a `no_std` crate, make `std` a feature in `default`, not the other way around.
- Mutually exclusive features (e.g. `backend-a` vs `backend-b`) cannot be enforced by Cargo; emit a compile-time error via `compile_error!` if both are set, and document the limitation clearly.
- Use `dep:` syntax (`dep:serde`) to keep optional dependency names out of the feature namespace.

Related: `api-serde-optional`, `proj-workspace-deps`, `lint-cfg-check`

## proj-msrv-declare

> Declare `rust-version` (MSRV) in Cargo.toml and test it in CI

### Why It Matters

Setting `package.rust-version` causes Cargo to emit a clear, actionable error when the installed toolchain is too old, instead of a cryptic type or feature error deep inside your code. The 2024-edition resolver (resolver = "3", the default for edition 2024) is MSRV-aware: it will avoid selecting dependency versions whose own `rust-version` field exceeds yours, preventing accidental MSRV breakage from transitive upgrades. Without a declared MSRV, you have no contract with downstream users and no CI gate to catch regressions.

### Bad

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
# no rust-version — users get cryptic errors on old toolchains,
# and nothing prevents a dep bump from silently raising the floor
```

### Good

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2024"
rust-version = "1.80"  # oldest toolchain you commit to supporting

[workspace]
resolver = "3"  # default for edition 2024; enables MSRV-aware dep resolution
```

CI job pinning the MSRV toolchain (GitHub Actions example):

```yaml
# .github/workflows/msrv.yml
- name: Install MSRV toolchain
  uses: dtolnay/rust-toolchain@master
  with:
    toolchain: "1.80"

- name: Check MSRV
  run: cargo check --all-features
```

### Choosing and Maintaining MSRV

- Pick the oldest stable toolchain your users are realistically running (check distro packages, embedded targets, corporate freeze windows).
- Do not go lower than needed — a lower MSRV widens the set of eligible dependency versions and can force you onto older, buggier releases.
- When you bump MSRV, treat it as a semver-minor change (for libraries) and document it in your changelog.
- Run `cargo msrv` (the `cargo-msrv` tool) to find the actual floor automatically.

Related: `proj-workspace-deps`, `lint-cargo-metadata`, `doc-cargo-metadata`

## proj-build-rs-minimal

> Keep `build.rs` minimal, deterministic, and idempotent

### Why It Matters

Build scripts run on every Cargo invocation that touches their crate. Cargo decides whether to re-run a build script based on `cargo::rerun-if-changed` and `cargo::rerun-if-env-changed` directives: if you emit none, Cargo re-runs the script on every build; if you emit overly broad ones, you force unnecessary recompiles. Non-determinism (timestamps, UUIDs, network fetches) breaks reproducible builds, caching, and offline workflows. Parsing `rustc --version` strings to detect capabilities is fragile; the `autocfg` crate performs capability probes safely by compiling small snippets against the actual toolchain.

### Bad

```rust
// build.rs — overly broad, non-deterministic, network-dependent
use std::process::Command;

fn main() {
    // re-runs on every build because no rerun directives are emitted
    // (Cargo default: re-run if ANY file changes)

    // fragile: parses version string instead of probing capability
    let output = Command::new("rustc").arg("--version").output().unwrap();
    let version = String::from_utf8(output.stdout).unwrap();
    if version.contains("1.8") {
        println!("cargo::rustc-cfg=has_feature");
    }

    // network access breaks offline/reproducible builds
    let _resp = reqwest::blocking::get("https://example.com/schema.json").unwrap();
}
```

### Good

```rust
// build.rs — narrow directives, capability probe via autocfg, no network
fn main() {
    // Only re-run when these specific files change
    println!("cargo::rerun-if-changed=build.rs");
    println!("cargo::rerun-if-changed=src/generated.rs");
    println!("cargo::rerun-if-env-changed=MY_BUILD_FLAG");

    // Probe actual compiler capability instead of parsing version strings
    let ac = autocfg::new();
    // Emit cfg if the compiler supports the feature we need
    ac.emit_has_type("std::collections::BTreeMap");

    // Conditional cfg from env var
    if std::env::var("MY_BUILD_FLAG").is_ok() {
        println!("cargo::rustc-cfg=my_feature");
    }
}
```

```toml
[build-dependencies]
autocfg = "1"
```

### Guidelines

- Always emit at least `println!("cargo::rerun-if-changed=build.rs")` so the script only re-runs when it or its tracked inputs change.
- List every file the script reads: source files, schema files, code-gen templates. Missing a file means stale output; listing too many causes spurious rebuilds.
- Never make network calls. Download assets in advance and check them into the repo or use a `vendored` feature that ships them.
- Prefer `autocfg` or `rustversion` crates over parsing `rustc --version` for conditional compilation.
- Keep build scripts short. If codegen is complex, extract it into a library crate used by `build.rs`, not into `build.rs` itself.
- Avoid writing outside `OUT_DIR` (the directory Cargo provides for build output); writing elsewhere breaks sandboxed build environments.

Related: `proj-feature-additive`, `lint-cfg-check`
