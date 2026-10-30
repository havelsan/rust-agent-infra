---
name: rust-42-linting-2of2
description: Rust rules module 42: Clippy & Linting (part 2 of 2). 7 rules, priority LOW. Load on its own to review or write Rust code against this topic only. Rule prefixes: `lint-`
---

# Clippy & Linting (part 2/2)

Priority: LOW. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `lint-missing-docs` - Warn on missing documentation for public items
- `lint-unsafe-doc` - Require documentation for unsafe blocks
- `lint-cargo-metadata` - Enable clippy::cargo for published crates
- `lint-rustfmt-check` - Run cargo fmt --check in CI
- `lint-workspace-lints` - Configure lints at workspace level for consistent enforcement
- `lint-cfg-check` - Enable `unexpected_cfgs` and declare known cfgs to catch feature-gate typos
- `lint-clippy-nursery-selected` - Enable high-value `clippy::nursery` lints selectively, not the whole group

---

## lint-missing-docs

> Warn on missing documentation for public items

### Why It Matters

The `missing_docs` lint ensures all public API items are documented. For libraries, documentation IS the user interface. Missing docs mean users can't understand your API without reading source code.

### Configuration

```rust
// In lib.rs
#![warn(missing_docs)]
```

Or in `Cargo.toml`:

```toml
[lints.rust]
missing_docs = "warn"
```

For strict enforcement:

```rust
#![deny(missing_docs)]
```

### What It Catches

```rust
#![warn(missing_docs)]

pub struct User {  // WARN: missing documentation for a struct
    pub name: String,  // WARN: missing documentation for a field
    pub age: u32,      // WARN: missing documentation for a field
}

pub fn process() { }  // WARN: missing documentation for a function

pub trait Handler {  // WARN: missing documentation for a trait
    fn handle(&self);  // WARN: missing documentation for a method
}
```

### Good

```rust
#![warn(missing_docs)]

//! User management module.

/// Represents a registered user in the system.
pub struct User {
    /// The user's display name.
    pub name: String,
    /// The user's age in years.
    pub age: u32,
}

/// Processes pending user requests.
///
/// # Examples
///
/// ```
/// process();
/// ```
pub fn process() { }

/// Handler trait for request processing.
pub trait Handler {
    /// Handle an incoming request.
    fn handle(&self);
}
```

### Private Items

`missing_docs` only applies to `pub` items. Private items don't trigger warnings:

```rust
#![warn(missing_docs)]

struct Internal { }  // No warning - private

pub struct Public { }  // WARN - public, needs docs
```

### Allow for Specific Items

```rust
#![warn(missing_docs)]

/// Documented module.
pub mod api {
    /// Documented struct.
    pub struct Config { }
    
    #[allow(missing_docs)]
    pub mod internal {
        // Internal API, docs not required
        pub struct Helper { }
    }
}
```

### Gradual Adoption

For existing codebases, start with `warn` and fix incrementally:

```rust
// Phase 1: Warn, fix critical items
#![warn(missing_docs)]

// Phase 2: After cleanup, deny
#![deny(missing_docs)]
```

### Combining with doc Attributes

```rust
#![warn(missing_docs)]
#![warn(rustdoc::broken_intra_doc_links)]
#![warn(rustdoc::private_intra_doc_links)]
```

### Workspace Configuration

```toml
# In workspace Cargo.toml
[workspace.lints.rust]
missing_docs = "warn"

# Member crates inherit
[lints]
workspace = true
```

### What to Document

| Item | Doc Focus |
|------|-----------|
| Structs | Purpose, usage example |
| Struct fields | What it represents |
| Enums | When to use each variant |
| Functions | What it does, params, return |
| Traits | Contract and expectations |
| Modules | What the module provides |

Related: `doc-all-public`, `lint-unsafe-doc`, `doc-examples-section`

## lint-unsafe-doc

> Require documentation for unsafe blocks

### Why It Matters

The `undocumented_unsafe_blocks` lint ensures every unsafe block has a `// SAFETY:` comment explaining why the operation is sound. Unsafe code is the source of most memory safety bugs—documenting invariants catches mistakes and helps reviewers.

### Configuration

```rust
#![warn(clippy::undocumented_unsafe_blocks)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
undocumented_unsafe_blocks = "warn"
```

For strict enforcement:

```toml
[lints.clippy]
undocumented_unsafe_blocks = "deny"
```

### Bad

```rust
pub fn read_data(ptr: *const u8, len: usize) -> &[u8] {
    unsafe {
        std::slice::from_raw_parts(ptr, len)  // WARN: undocumented
    }
}

impl Buffer {
    pub fn get_unchecked(&self, index: usize) -> &u8 {
        unsafe { self.data.get_unchecked(index) }  // WARN
    }
}
```

### Good

```rust
pub fn read_data(ptr: *const u8, len: usize) -> &[u8] {
    // SAFETY: Caller guarantees:
    // - ptr is valid for reads of len bytes
    // - ptr is properly aligned for u8
    // - the memory is initialized
    // - no mutable references exist to this memory
    unsafe {
        std::slice::from_raw_parts(ptr, len)
    }
}

impl Buffer {
    pub fn get_unchecked(&self, index: usize) -> &u8 {
        debug_assert!(index < self.len(), "index out of bounds");
        // SAFETY: We verified index < len in debug builds.
        // Callers must ensure index is within bounds.
        unsafe { self.data.get_unchecked(index) }
    }
}
```

### SAFETY Comment Format

```rust
// SAFETY: <explanation of why this is sound>
unsafe {
    // ...
}
```

The comment should explain:
1. **What invariants are upheld** - preconditions that make this safe
2. **Why the invariants hold** - how you know they're satisfied
3. **What could go wrong** - if invariants are violated

### Examples by Category

#### Pointer Operations

```rust
// SAFETY: ptr was obtained from Box::into_raw, so it's valid
// and properly aligned. We're taking back ownership.
let boxed = unsafe { Box::from_raw(ptr) };
```

#### Unchecked Operations

```rust
// SAFETY: We just checked that i < self.len() above.
// The bounds check cannot be elided by the optimizer
// because len() is not inlined.
unsafe { self.data.get_unchecked(i) }
```

#### FFI Calls

```rust
// SAFETY: libc::getenv is safe to call with a null-terminated
// string. We ensure null termination with CString::new.
// The returned pointer is valid for the lifetime of the environment.
let value = unsafe { libc::getenv(key.as_ptr()) };
```

#### Trait Implementations

```rust
// SAFETY: MyType contains no pointers or interior mutability,
// and all bit patterns are valid MyType values.
unsafe impl Send for MyType {}
unsafe impl Sync for MyType {}
```

### Related Lints

```toml
[lints.clippy]
undocumented_unsafe_blocks = "warn"
# Also consider:
multiple_unsafe_ops_per_block = "warn"  # One operation per block
```

Related: `doc-safety-section`, `lint-deny-correctness`, `type-repr-transparent`

## lint-cargo-metadata

> Enable clippy::cargo for published crates

### Why It Matters

The `clippy::cargo` lint group checks Cargo.toml for issues that affect publishing and dependency management. For crates intended for crates.io, these checks help ensure a professional, well-configured package.

### Configuration

```toml
# Cargo.toml
[lints.clippy]
cargo = "warn"
```

Or in code:

```rust
#![warn(clippy::cargo)]
```

### What It Catches

#### Missing Metadata

```toml
# WARN: missing package.description
# WARN: missing package.license or package.license-file
# WARN: missing package.repository
[package]
name = "my-crate"
version = "0.1.0"
```

#### Dependency Issues

```toml
# WARN: feature used but not defined
# WARN: dependency version not specified
[dependencies]
serde = "*"  # Bad: any version
tokio = { git = "..." }  # WARN for published crates
```

#### Feature Issues

```toml
# WARN: negative_feature_names
[features]
no-std = []  # Should be: std = [] (opt-out vs opt-in)

# WARN: redundant_feature_names
[features]
default = ["feature-a"]
feature-a = []  # Feature name matches crate name
```

### Notable Lints

| Lint | Issue |
|------|-------|
| `cargo_common_metadata` | Missing description/license/repository |
| `multiple_crate_versions` | Same crate at different versions |
| `negative_feature_names` | Features like `no-std` instead of `std` |
| `redundant_feature_names` | Feature same as crate name |
| `wildcard_dependencies` | Using `*` for version |

### Complete Cargo.toml

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.70"

# Required for cargo lint satisfaction
description = "A short description of what this crate does"
license = "MIT OR Apache-2.0"
repository = "https://github.com/user/my-crate"

# Recommended
documentation = "https://docs.rs/my-crate"
readme = "README.md"
keywords = ["keyword1", "keyword2"]
categories = ["category-slug"]

[dependencies]
# Specific versions, not wildcards
serde = "1.0"
tokio = { version = "1.0", features = ["full"] }

[features]
default = ["std"]
std = []  # Opt-out, not no-std opt-in

[lints.clippy]
cargo = "warn"
```

### Multiple Crate Versions

```
# WARN: multiple versions of `syn` in dependency tree
# syn v1.0.109
# syn v2.0.48
```

Fix by updating dependencies or using `[patch]`:

```toml
[patch.crates-io]
old-dep = { git = "...", branch = "syn-2" }
```

### When to Disable

For internal/unpublished crates:

```toml
[lints.clippy]
cargo = "allow"  # Not publishing, metadata not needed
```

Or selectively:

```toml
[lints.clippy]
cargo = "warn"
multiple_crate_versions = "allow"  # Acceptable in this project
```

Related: `doc-cargo-metadata`, `proj-workspace-deps`, `lint-deny-correctness`

## lint-rustfmt-check

> Run cargo fmt --check in CI

### Why It Matters

Consistent formatting eliminates style debates and makes diffs cleaner. Running `cargo fmt --check` in CI ensures all code follows the same format. This catches formatting issues before merge, not after.

### CI Configuration

#### GitHub Actions

```yaml
name: CI

on: [push, pull_request]

jobs:
  fmt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --all --check
```

#### GitLab CI

```yaml
fmt:
  image: rust:latest
  script:
    - rustup component add rustfmt
    - cargo fmt --all --check
```

#### Pre-commit Hook

```bash
#!/bin/sh
# .git/hooks/pre-commit
cargo fmt --all --check
```

### Configuration

Create `rustfmt.toml` for custom settings:

```toml
# rustfmt.toml
edition = "2021"
max_width = 100
use_small_heuristics = "Max"
imports_granularity = "Module"
group_imports = "StdExternalCrate"
reorder_imports = true
```

### Common Options

| Option | Default | Description |
|--------|---------|-------------|
| `max_width` | 100 | Maximum line width |
| `tab_spaces` | 4 | Spaces per indent |
| `edition` | "2015" | Rust edition |
| `use_small_heuristics` | "Default" | Layout heuristics |
| `imports_granularity` | "Preserve" | Import grouping |
| `group_imports` | "Preserve" | Import ordering |

### Running Locally

```bash
# Check formatting (doesn't modify files)
cargo fmt --all --check

# Apply formatting
cargo fmt --all

# Format specific file
cargo fmt -- src/main.rs

# Check with verbose output
cargo fmt --all --check -- --verbose
```

### Workspace Formatting

```bash
# Format all workspace members
cargo fmt --all

# Format specific package
cargo fmt -p my-package
```

### Ignoring Files

In `rustfmt.toml`:

```toml
# Skip generated files
ignore = [
    "src/generated/*",
    "build.rs",
]
```

Or in code:

```rust
#[rustfmt::skip]
mod generated_code;

#[rustfmt::skip]
const MATRIX: [[i32; 4]; 4] = [
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1],
];
```

### Nightly Features

Some options require nightly:

```toml
# rustfmt.toml (nightly only)
unstable_features = true
imports_granularity = "Crate"
wrap_comments = true
format_code_in_doc_comments = true
```

```bash
# Use nightly rustfmt
cargo +nightly fmt
```

### IDE Integration

Most IDEs format on save. Configure to use project `rustfmt.toml`:

```json
// VS Code settings.json
{
  "rust-analyzer.rustfmt.extraArgs": ["--config-path", "./rustfmt.toml"]
}
```

Related: `lint-warn-style`, `lint-pedantic-selective`, `name-funcs-snake`

## lint-workspace-lints

> Configure lints at workspace level for consistent enforcement

### Why It Matters

Without centralized lint configuration, each crate develops its own standards (or none). Workspace-level lints (Rust 1.74+) ensure consistent code quality across all crates. Denied lints catch issues in CI before they reach production.

### Bad

```toml
# crate-a/Cargo.toml - strict
[lints.clippy]
unwrap_used = "deny"

# crate-b/Cargo.toml - lenient
# No lint config

# crate-c/Cargo.toml - different
[lints.clippy]
unwrap_used = "warn"

# Inconsistent enforcement, some issues slip through
```

### Good

```toml
# Root Cargo.toml
[workspace.lints.rust]
unsafe_code = "deny"
missing_docs = "warn"

[workspace.lints.clippy]
# Correctness
unwrap_used = "deny"
expect_used = "warn"
panic = "deny"

# Style
needless_pass_by_value = "warn"
redundant_clone = "warn"

# Complexity
cognitive_complexity = "warn"

[workspace.lints.rustdoc]
broken_intra_doc_links = "deny"

# crate-a/Cargo.toml
[lints]
workspace = true

# crate-b/Cargo.toml
[lints]
workspace = true
```

### Recommended Lint Configuration

```toml
# Root Cargo.toml
[workspace.lints.rust]
# Safety
unsafe_code = "deny"
missing_debug_implementations = "warn"

# Quality
unused_results = "warn"
unused_qualifications = "warn"

[workspace.lints.clippy]
# === Correctness (deny) ===
correctness = { level = "deny", priority = -1 }

# === Suspicious (deny) ===
suspicious = { level = "deny", priority = -1 }

# === Style (warn) ===
style = { level = "warn", priority = -1 }

# === Complexity (warn) ===
complexity = { level = "warn", priority = -1 }

# === Perf (warn) ===
perf = { level = "warn", priority = -1 }

# === Pedantic (selective) ===
# Not all pedantic lints are useful
doc_markdown = "warn"
needless_pass_by_value = "warn"
redundant_closure_for_method_calls = "warn"
semicolon_if_nothing_returned = "warn"

# === Nursery (selective) ===
cognitive_complexity = "warn"
useless_let_if_seq = "warn"

# === Restriction (selective) ===
unwrap_used = "deny"
expect_used = "warn"
dbg_macro = "warn"
print_stdout = "warn"  # Use logging instead
todo = "warn"

[workspace.lints.rustdoc]
broken_intra_doc_links = "deny"
private_intra_doc_links = "warn"
```

### Per-Crate Overrides

```toml
# crate-with-binary/Cargo.toml
[lints]
workspace = true

# Binary entry point can use unwrap
[lints.clippy]
unwrap_used = "allow"

# test-utils/Cargo.toml
[lints]
workspace = true

# Test utilities can print
[lints.clippy]
print_stdout = "allow"
```

### CI Integration

```yaml
# .github/workflows/ci.yml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      
      - name: Clippy
        run: cargo clippy --workspace --all-targets -- -D warnings
      
      - name: Rustdoc
        run: RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps
```

### Lint Categories

```toml
# Category-level configuration
[workspace.lints.clippy]
# All lints in category at once
correctness = { level = "deny", priority = -1 }
suspicious = { level = "deny", priority = -1 }
style = { level = "warn", priority = -1 }
complexity = { level = "warn", priority = -1 }
perf = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }

# Then override specific lints (higher priority)
missing_errors_doc = "allow"  # Override pedantic
```

Related: `lint-deny-correctness`, `proj-workspace-deps`, `anti-unwrap-abuse`

## lint-cfg-check

> Enable `unexpected_cfgs` and declare known cfgs to catch feature-gate typos

### Why It Matters

A typo in a cfg expression — `#[cfg(feature = "serde_")]` instead of `"serde"`, or `#[cfg(tokio_unstable)]` with no declaration — compiles silently and produces dead code or an always-disabled feature. The `unexpected_cfgs` lint (stabilized in Rust 1.80) flags any cfg name or value not known to the compiler. Cargo automatically teaches the compiler about your declared feature names; for custom cfgs (well-known ones like `tokio_unstable`, or your own) you must declare them via `check-cfg` in the `[lints.rust]` table. This catches bugs at compile time that would otherwise be invisible.

### Bad

```rust
// Typo: "serde_" will never match the "serde" feature.
// Compiles with no warning — the block is silently dead.
#[cfg(feature = "serde_")]
impl serde::Serialize for MyType {}

// Custom cfg used without declaration — also silently ignored.
#[cfg(tokio_unstable)]
pub fn experimental() {}
```

### Good

```toml
# Cargo.toml — declare custom cfgs in the lints table
[lints.rust]
unexpected_cfgs = { level = "warn", check-cfg = [
    'cfg(tokio_unstable)',
    'cfg(coverage_nightly)',
] }
```

```rust
// Now "serde_" typo → compiler warning: unexpected `cfg` condition value
// and tokio_unstable is a known cfg, so it compiles cleanly.
#[cfg(feature = "serde")]      // correct
impl serde::Serialize for MyType {}

#[cfg(tokio_unstable)]         // declared above — no warning
pub fn experimental() {}
```

### Workspace Projects

Configure the lint once at the workspace level and inherit it in member crates:

```toml
# Cargo.toml (workspace root)
[workspace.lints.rust]
unexpected_cfgs = { level = "warn", check-cfg = [
    'cfg(tokio_unstable)',
] }

# member/Cargo.toml
[lints]
workspace = true
```

### Notes

- Feature names (`feature = "serde"`, `feature = "std"`) are registered automatically by Cargo — you do not need to list them in `check-cfg`.
- Values in `check-cfg` entries must be quoted cfg expressions: `'cfg(name)'` or `'cfg(name, values("v1", "v2"))'`.
- The lint fires at `warn` level; promote to `deny` in CI if you want hard failures.

Related: `lint-workspace-lints`, `proj-feature-additive`, `lint-warn-suspicious`

## lint-clippy-nursery-selected

> Enable high-value `clippy::nursery` lints selectively, not the whole group

### Why It Matters

The `clippy::nursery` group contains lints that are correct and useful but still being refined — their suggestions may be noisy or have edge cases that haven't been polished yet. Enabling the entire group (`#![warn(clippy::nursery)]`) floods you with false positives and creates churn as nursery lints graduate or change. Cherry-picking individual lints gives you the signal without the noise. Several nursery lints are especially valuable: `significant_drop_tightening` catches lock guards held across `.await` or longer than necessary, `redundant_clone` flags clones that could be moves, and `use_self` keeps type names DRY inside impl blocks.

### Bad

```toml
# Cargo.toml — enables every nursery lint, including noisy ones
[lints.clippy]
nursery = "warn"
```

### Good

```toml
# Cargo.toml — selectively enable high-value nursery lints
[lints.clippy]
# Catches lock/guard held longer than necessary (overlaps with async issues)
significant_drop_tightening = "warn"
# Flags .clone() calls that could be avoided by moving
redundant_clone = "warn"
# Replace TypeName with Self inside impl blocks
use_self = "warn"
# Avoid redundant else after a diverging if
redundant_else = "warn"
# Prefer or_default() over or(Default::default())
or_fun_call = "warn"
```

```rust
// significant_drop_tightening example — lint fires here:
fn process(state: &Mutex<Vec<u32>>) -> usize {
    let guard = state.lock().unwrap();
    let len = guard.len();
    drop(guard);          // lint suggests dropping earlier, before the return
    expensive_work();
    len
}

// use_self example — lint fires here:
impl MyStruct {
    fn new() -> MyStruct {   // should be -> Self
        MyStruct { value: 0 }
    }
}

// Correct:
impl MyStruct {
    fn new() -> Self {
        Self { value: 0 }
    }
}
```

### Suggested Starter Set

| Lint | What it catches |
|------|----------------|
| `significant_drop_tightening` | Guards/locks held longer than needed |
| `redundant_clone` | `.clone()` where a move suffices |
| `use_self` | Type name repeated inside `impl` block |
| `redundant_else` | `else` after diverging `if` branch |
| `or_fun_call` | `or(Default::default())` → `or_default()` |

Start with this set. Add more only after reviewing what they flag in your codebase.

Related: `lint-pedantic-selective`, `lint-warn-perf`, `anti-lock-across-await`
