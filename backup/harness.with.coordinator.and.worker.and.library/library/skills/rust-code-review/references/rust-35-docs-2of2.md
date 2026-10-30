---
name: rust-35-docs-2of2
description: Rust rules module 35: Documentation (part 2 of 2). 6 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `doc-`
---

# Documentation (part 2/2)

Priority: MEDIUM. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `doc-question-mark` - Use `?` in examples, not `.unwrap()`
- `doc-hidden-setup` - Use `# ` prefix to hide example setup code
- `doc-intra-links` - Use intra-doc links to reference types and items
- `doc-link-types` - Use intra-doc links to connect related types and functions
- `doc-cargo-metadata` - Fill `Cargo.toml` metadata for published crates
- `doc-crate-readme` - Unify the README and crate root docs with `#![doc = include_str!("../README.md")]`

---

## doc-question-mark

> Use `?` in examples, not `.unwrap()`

### Why It Matters

Doc examples should model best practices. Using `.unwrap()` teaches users to ignore errors, while `?` demonstrates proper error propagation. Examples with `?` also fail the doctest if an error occurs, catching bugs in documentation.

Rust doctests wrap examples in a function that returns `Result<(), E>` by default when you use `?`, making this pattern easy to adopt.

### Bad

```rust
/// Reads a configuration file.
///
/// # Examples
///
/// ```
/// let config = Config::from_file("config.toml").unwrap();
/// println!("{:?}", config.database_url);
/// ```
pub fn from_file(path: &str) -> Result<Config, Error> {
    // ...
}

/// Fetches data from the API.
///
/// # Examples
///
/// ```
/// let client = Client::new();
/// let response = client.get("https://api.example.com").unwrap();
/// let data: Data = response.json().unwrap();
/// ```
pub async fn get(&self, url: &str) -> Result<Response, Error> {
    // ...
}
```

### Good

```rust
/// Reads a configuration file.
///
/// # Examples
///
/// ```
/// # use my_crate::{Config, Error};
/// # fn main() -> Result<(), Error> {
/// let config = Config::from_file("config.toml")?;
/// println!("{:?}", config.database_url);
/// # Ok(())
/// # }
/// ```
pub fn from_file(path: &str) -> Result<Config, Error> {
    // ...
}

/// Fetches data from the API.
///
/// # Examples
///
/// ```no_run
/// # use my_crate::{Client, Data, Error};
/// # async fn example() -> Result<(), Error> {
/// let client = Client::new();
/// let response = client.get("https://api.example.com").await?;
/// let data: Data = response.json().await?;
/// # Ok(())
/// # }
/// ```
pub async fn get(&self, url: &str) -> Result<Response, Error> {
    // ...
}
```

### Doctest Wrapper Pattern

Rust wraps doc examples in a function. You can make this explicit:

```rust
/// # Examples
///
/// ```
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// let value = parse_config("key=value")?;
/// assert_eq!(value.key, "value");
/// # Ok(())
/// # }
/// ```
```

Or use the implicit wrapper (Rust 2021+):

```rust
/// # Examples
///
/// ```
/// # use my_crate::parse_config;
/// let value = parse_config("key=value")?;
/// assert_eq!(value.key, "value");
/// # Ok::<(), my_crate::Error>(())
/// ```
```

### When to Use `.unwrap()`

There are specific cases where `.unwrap()` is acceptable in examples:

```rust
/// # Examples
///
/// ```
/// // Static regex that is known at compile time to be valid
/// let re = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
///
/// // Parsing a literal that cannot fail
/// let n: i32 = "42".parse().unwrap();
/// ```
```

But still prefer `?` when demonstrating error handling patterns.

### Comparison

| Pattern | Behavior on Error | Teaches |
|---------|-------------------|---------|
| `.unwrap()` | Panics with generic message | Bad habits |
| `.expect()` | Panics with custom message | Slightly better |
| `?` | Propagates error, test fails | Best practices |

Related: `doc-examples-section`, `doc-hidden-setup`, `err-question-mark`

## doc-hidden-setup

> Use `# ` prefix to hide example setup code

### Why It Matters

Doc examples often require setup code (imports, struct initialization, mock data) that distracts from the main point. The `# ` prefix hides lines from rendered documentation while keeping them in the compiled test, showing users only the relevant code.

This keeps examples focused and readable while ensuring they still compile and run.

### Bad

```rust
/// Processes a batch of items.
///
/// # Examples
///
/// ```
/// use my_crate::{Processor, Config, Item};
/// use std::sync::Arc;
/// 
/// let config = Config {
///     batch_size: 100,
///     timeout_ms: 5000,
///     retry_count: 3,
/// };
/// let processor = Processor::new(Arc::new(config));
/// let items = vec![
///     Item::new("a"),
///     Item::new("b"),
///     Item::new("c"),
/// ];
/// 
/// // This is the actual example - buried after 15 lines of setup
/// let results = processor.process_batch(&items)?;
/// assert!(results.all_succeeded());
/// # Ok::<(), my_crate::Error>(())
/// ```
pub fn process_batch(&self, items: &[Item]) -> Result<Results, Error> {
    // ...
}
```

### Good

```rust
/// Processes a batch of items.
///
/// # Examples
///
/// ```
/// # use my_crate::{Processor, Config, Item, Error};
/// # use std::sync::Arc;
/// # let config = Config { batch_size: 100, timeout_ms: 5000, retry_count: 3 };
/// # let processor = Processor::new(Arc::new(config));
/// # let items = vec![Item::new("a"), Item::new("b"), Item::new("c")];
/// let results = processor.process_batch(&items)?;
/// assert!(results.all_succeeded());
/// # Ok::<(), Error>(())
/// ```
pub fn process_batch(&self, items: &[Item]) -> Result<Results, Error> {
    // ...
}
```

Users see only:

```rust
let results = processor.process_batch(&items)?;
assert!(results.all_succeeded());
```

### What to Hide

| Hide | Show |
|------|------|
| `use` statements | Core API usage |
| Type definitions | Method calls |
| Mock/test data setup | Key parameters |
| Error handling boilerplate | Return value handling |
| `Ok(())` return | Assertions (sometimes) |

### Pattern: Hiding Multi-Line Setup

```rust
/// # Examples
///
/// ```
/// # use my_crate::{Client, Request};
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// # let client = Client::builder()
/// #     .timeout(30)
/// #     .retry(3)
/// #     .build()?;
/// let response = client.send(Request::get("/users"))?;
/// println!("Status: {}", response.status());
/// # Ok(())
/// # }
/// ```
```

### Pattern: Showing Setup When Relevant

Sometimes setup IS the point—don't hide it:

```rust
/// Creates a new client with custom configuration.
///
/// # Examples
///
/// ```
/// use my_crate::Client;
///
/// // Configuration IS the example - show it
/// let client = Client::builder()
///     .base_url("https://api.example.com")
///     .timeout_secs(30)
///     .max_retries(3)
///     .build()?;
/// # Ok::<(), my_crate::Error>(())
/// ```
```

### Pattern: `ignore` and `no_run`

For examples that shouldn't run in tests:

```rust
/// # Examples
///
/// ```no_run
/// # use my_crate::Server;
/// // This would actually start a server - don't run in tests
/// let server = Server::bind("0.0.0.0:8080").await?;
/// server.run().await?;
/// # Ok::<(), my_crate::Error>(())
/// ```

/// ```ignore
/// // Pseudocode or incomplete example
/// let magic = do_something_undefined();
/// ```
```

Related: `doc-examples-section`, `doc-question-mark`, `test-doctest-examples`

## doc-intra-links

> Use intra-doc links to reference types and items

### Why It Matters

Intra-doc links (`[TypeName]`, `[method](Self::method)`) create clickable references in generated documentation. They're verified at doc-build time, catching broken links early. Unlike URL links, they automatically update when items are renamed or moved.

### Bad

```rust
/// Returns the length of the buffer.
/// 
/// See also `capacity()` for the allocated size, and the
/// `Buffer` struct for more details.
pub fn len(&self) -> usize {
    self.data.len()
}

/// Parses the input using std::str::FromStr trait.
/// Check the Error enum for possible failures.
pub fn parse<T: FromStr>(input: &str) -> Result<T, Error> {
    // ...
}
```

### Good

```rust
/// Returns the length of the buffer.
/// 
/// See also [`capacity()`](Self::capacity) for the allocated size, and
/// [`Buffer`] for more details.
pub fn len(&self) -> usize {
    self.data.len()
}

/// Parses the input using [`FromStr`] trait.
/// Check [`Error`] for possible failures.
///
/// [`FromStr`]: std::str::FromStr
pub fn parse<T: FromStr>(input: &str) -> Result<T, Error> {
    // ...
}
```

### Link Syntax

| Syntax | Links To | Example |
|--------|----------|---------|
| `[Name]` | Item in scope | `[Vec]`, `[Option]` |
| `[path::Name]` | Fully qualified item | `[std::vec::Vec]` |
| `[Self::method]` | Method on current type | `[Self::new]` |
| `[Type::method]` | Method on other type | `[String::new]` |
| `[Type::CONST]` | Associated constant | `[usize::MAX]` |
| `[text](path)` | Custom text | `[see here](Self::len)` |

### Common Patterns

#### Linking to Self Members

```rust
impl Buffer {
    /// Creates an empty buffer.
    ///
    /// Use [`with_capacity`](Self::with_capacity) if you know the size.
    pub fn new() -> Self { /* ... */ }
    
    /// Creates a buffer with pre-allocated capacity.
    ///
    /// See [`new`](Self::new) for the default constructor.
    pub fn with_capacity(cap: usize) -> Self { /* ... */ }
}
```

#### Linking to Trait Methods

```rust
/// Converts to a string representation.
///
/// This is the implementation of [`Display::fmt`](std::fmt::Display::fmt).
impl Display for MyType {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        // ...
    }
}
```

#### Disambiguation

When names conflict, use suffixes:

```rust
/// See [`foo()`](fn@foo) for the function and [`foo`](mod@foo) for the module.

/// Works with [`Error`](struct@Error) struct or [`Error`](trait@Error) trait.
```

| Suffix | Item Type |
|--------|-----------|
| `fn@` | Function |
| `mod@` | Module |
| `struct@` | Struct |
| `enum@` | Enum |
| `trait@` | Trait |
| `type@` | Type alias |
| `const@` | Constant |
| `macro@` | Macro |

#### Reference-Style Links

For repeated links or long paths:

```rust
/// Parses using [`serde`] with [`Deserialize`] trait.
/// Returns a [`Result`] that may contain [`Error`].
///
/// [`serde`]: https://serde.rs
/// [`Deserialize`]: serde::Deserialize
/// [`Result`]: std::result::Result
/// [`Error`]: crate::Error
```

### Verification

Enable link checking in CI:

```bash
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps
```

This fails if any intra-doc links are broken.

Related: `doc-all-public`, `doc-examples-section`, `doc-errors-section`

## doc-link-types

> Use intra-doc links to connect related types and functions

### Why It Matters

Intra-doc links (`[`TypeName`]`) create clickable references in generated documentation. They enable navigation between related items, verify that referenced items exist at compile time, and update automatically when items are renamed. Plain text references become stale and unclickable.

### Bad

```rust
/// Parses input and returns a ParseResult.
/// 
/// See also: ParseError for error types.
/// Uses the Tokenizer internally.
pub fn parse(input: &str) -> ParseResult {
    // "ParseResult", "ParseError", "Tokenizer" are not clickable
    // No verification they exist
}
```

### Good

```rust
/// Parses input and returns a [`ParseResult`].
///
/// # Errors
///
/// Returns [`ParseError::InvalidSyntax`] if the input contains invalid tokens.
/// Returns [`ParseError::UnexpectedEof`] if the input ends prematurely.
///
/// # Related
///
/// - [`Tokenizer`] - The underlying tokenizer used by this parser
/// - [`parse_file`] - Convenience function for parsing files
/// - [`ParseOptions`] - Configuration options for parsing
pub fn parse(input: &str) -> ParseResult {
    // All links are clickable and verified
}
```

### Link Syntax

```rust
/// Basic link to type in same module
/// See [`MyType`] for details.

/// Link to method
/// Use [`MyType::new`] to create instances.

/// Link to associated type
/// Returns [`Iterator::Item`].

/// Link to module
/// See the [`parser`] module.

/// Link to external crate type
/// Works with [`std::collections::HashMap`].

/// Link with custom text
/// See [the parser][`parse`] for details.

/// Link to module item
/// See [`crate::utils::helper`].

/// Link to parent module item
/// See [`super::Parent`].
```

### Common Patterns

```rust
/// A configuration builder.
///
/// # Example
///
/// ```
/// use my_crate::Config;
///
/// let config = Config::builder()
///     .timeout(30)
///     .build()?;
/// ```
///
/// # Methods
///
/// - [`Config::builder`] - Create a new builder
/// - [`Config::default`] - Create with defaults
///
/// # Related Types
///
/// - [`ConfigBuilder`] - The builder returned by [`Config::builder`]
/// - [`ConfigError`] - Errors that can occur when building
pub struct Config { ... }

impl Config {
    /// Creates a new [`ConfigBuilder`].
    ///
    /// This is equivalent to [`ConfigBuilder::new`].
    pub fn builder() -> ConfigBuilder { ... }
}
```

### Linking to Trait Items

```rust
/// Implements [`Iterator`] for lazy evaluation.
///
/// The [`Iterator::next`] method advances the cursor.
/// 
/// For parallel iteration, see [`rayon::ParallelIterator`].
pub struct MyIterator { ... }

impl Iterator for MyIterator {
    /// Advances and returns the next value.
    ///
    /// See also [`Iterator::nth`] for skipping elements.
    fn next(&mut self) -> Option<Self::Item> { ... }
}
```

### Broken Link Detection

```bash
# Catch broken intra-doc links
RUSTDOCFLAGS="-D warnings" cargo doc

# Or in CI
cargo doc --no-deps 2>&1 | grep "warning: unresolved link"
```

```toml
# Cargo.toml - deny broken links
[lints.rustdoc]
broken_intra_doc_links = "deny"
```

### Module-Level Documentation

```rust
//! # Parser Module
//!
//! This module provides parsing utilities.
//!
//! ## Main Types
//!
//! - [`Parser`] - The main parser struct
//! - [`Token`] - Tokens produced by tokenization
//! - [`Ast`] - The abstract syntax tree
//!
//! ## Functions
//!
//! - [`parse`] - Parse a string
//! - [`parse_file`] - Parse a file
//!
//! ## Errors
//!
//! All functions return [`ParseError`] on failure.

pub struct Parser { ... }
pub enum Token { ... }
pub struct Ast { ... }
```

Related: `doc-examples-section`, `err-doc-errors`, `lint-deny-correctness`

## doc-cargo-metadata

> Fill `Cargo.toml` metadata for published crates

### Why It Matters

Cargo.toml metadata appears on crates.io, in search results, and helps users evaluate your crate. Missing metadata makes your crate look unprofessional, harder to find, and harder to trust. Complete metadata improves discoverability and adoption.

### Bad

```toml
[package]
name = "my-awesome-crate"
version = "0.1.0"
edition = "2021"

[dependencies]
# ...
```

### Good

```toml
[package]
name = "my-awesome-crate"
version = "0.1.0"
edition = "2021"
rust-version = "1.70"

# Required for crates.io
description = "A fast, ergonomic HTTP client for Rust"
license = "MIT OR Apache-2.0"
repository = "https://github.com/username/my-awesome-crate"

# Highly recommended
documentation = "https://docs.rs/my-awesome-crate"
readme = "README.md"
keywords = ["http", "client", "async", "networking"]
categories = ["network-programming", "web-programming::http-client"]
authors = ["Your Name <you@example.com>"]
homepage = "https://my-awesome-crate.dev"

# Optional but helpful
include = ["src/**/*", "Cargo.toml", "LICENSE*", "README.md"]
exclude = ["tests/fixtures/*", ".github/*"]

[badges]
maintenance = { status = "actively-developed" }

[dependencies]
# ...
```

### Required Fields for Publishing

| Field | Purpose |
|-------|---------|
| `name` | Crate name on crates.io |
| `version` | Semver version |
| `license` or `license-file` | SPDX license identifier |
| `description` | One-line summary (≤256 chars) |

### Recommended Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `repository` | Link to source code | `https://github.com/user/repo` |
| `documentation` | Link to docs | `https://docs.rs/crate` |
| `readme` | Path to README | `README.md` |
| `keywords` | Search terms (max 5) | `["http", "async"]` |
| `categories` | crates.io categories | `["network-programming"]` |
| `rust-version` | MSRV | `"1.70"` |

### Keywords Best Practices

```toml
# Good: specific, searchable terms
keywords = ["json", "serialization", "serde", "parsing"]

# Bad: too generic or redundant
keywords = ["rust", "library", "awesome", "fast", "best"]
```

### Categories

Choose from [crates.io categories](https://crates.io/category_slugs):

```toml
categories = [
    "network-programming",
    "web-programming::http-client",
    "asynchronous",
]
```

### License Patterns

```toml
# Single license
license = "MIT"

# Dual license (common in Rust ecosystem)
license = "MIT OR Apache-2.0"

# Custom license file
license-file = "LICENSE"
```

### Include/Exclude

Control what gets published:

```toml
# Explicit include (whitelist)
include = [
    "src/**/*",
    "Cargo.toml",
    "LICENSE*",
    "README.md",
    "CHANGELOG.md",
]

# Or exclude (blacklist)
exclude = [
    "tests/fixtures/large-file.bin",
    ".github/*",
    "benches/*",
]
```

### Verification

Check your package before publishing:

```bash
# See what will be included
cargo package --list

# Check metadata
cargo publish --dry-run
```

Related: `doc-module-inner`, `lint-cargo-metadata`, `proj-workspace-deps`

## doc-crate-readme

> Unify the README and crate root docs with `#![doc = include_str!("../README.md")]`

### Why It Matters

Maintaining a `README.md` and a separate crate-level doc comment in `lib.rs` leads to inevitable drift: the README gets updated for GitHub/crates.io visitors while the rustdoc front page grows stale, or vice versa. The `include_str!` attribute macro (stable since Rust 1.54) makes the README the single source of truth for both surfaces. Set `readme = "README.md"` in `Cargo.toml` so crates.io also picks up the same file. The result: one file, three consistent rendering targets — GitHub, crates.io, and docs.rs.

### Bad

```rust
// src/lib.rs — separate doc comment that will drift from README.md
//! # my-crate
//!
//! A library for doing things. (duplicate, will get out of date)
//!
//! ## Usage
//! ...

pub fn do_thing() {}
```

```toml
# Cargo.toml — readme field absent; crates.io shows nothing
[package]
name = "my-crate"
version = "0.1.0"
edition = "2024"
```

### Good

```rust
// src/lib.rs — README is the single source of truth
#![doc = include_str!("../README.md")]

pub fn do_thing() {}
```

```toml
# Cargo.toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2024"
readme = "README.md"          # crates.io landing page
documentation = "https://docs.rs/my-crate"
```

### Handling Non-Rust Code Blocks in README

When the README contains code blocks that are not valid Rust, rustdoc will try to compile them as doc-tests and fail. Fix this by tagging those blocks:

````markdown
```bash
cargo add my-crate
```

```text
output that should not be compiled
```

```rust,no_run
// example that should be shown but not executed
let x = long_running_operation();
```
````

For TOML or shell blocks already tagged with their language (` ```toml `, ` ```bash `), rustdoc ignores them automatically — no extra annotation needed.

Related: `doc-module-inner`, `doc-cargo-metadata`, `doc-all-public`
