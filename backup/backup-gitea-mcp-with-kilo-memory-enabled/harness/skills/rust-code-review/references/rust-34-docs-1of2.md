---
name: rust-34-docs-1of2
description: Rust rules module 34: Documentation (part 1 of 2). 6 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `doc-`
---

# Documentation (part 1/2)

Priority: MEDIUM. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `doc-all-public` - Document all public items with `///` doc comments
- `doc-module-inner` - Use `//!` for module-level documentation
- `doc-examples-section` - Include `# Examples` with runnable code
- `doc-errors-section` - Include `# Errors` section for fallible functions
- `doc-panics-section` - Include `# Panics` section for functions that can panic
- `doc-safety-section` - Include `# Safety` section for unsafe functions

---

## doc-all-public

> Document all public items with `///` doc comments

### Why It Matters

Public items define your crate's API contract. Without documentation, users must read source code to understand how to use your library. Well-documented APIs reduce support burden, improve adoption, and serve as the primary reference for users.

Rust's `cargo doc` generates beautiful HTML documentation from doc comments, but only if you write them.

### Bad

```rust
pub struct Config {
    pub timeout: Duration,
    pub retries: u32,
    pub base_url: String,
}

pub fn connect(config: Config) -> Result<Connection, Error> {
    // ...
}

pub enum Status {
    Pending,
    Active,
    Failed,
}
```

### Good

```rust
/// Configuration for establishing a connection to the service.
///
/// # Examples
///
/// ```
/// use my_crate::Config;
/// use std::time::Duration;
///
/// let config = Config {
///     timeout: Duration::from_secs(30),
///     retries: 3,
///     base_url: "https://api.example.com".to_string(),
/// };
/// ```
pub struct Config {
    /// Maximum time to wait for a response before timing out.
    pub timeout: Duration,
    
    /// Number of retry attempts for failed requests.
    pub retries: u32,
    
    /// Base URL for all API requests.
    pub base_url: String,
}

/// Establishes a connection using the provided configuration.
///
/// # Errors
///
/// Returns an error if the connection cannot be established
/// or if the configuration is invalid.
pub fn connect(config: Config) -> Result<Connection, Error> {
    // ...
}

/// Represents the current status of a job.
pub enum Status {
    /// Job is waiting to be processed.
    Pending,
    /// Job is currently being processed.
    Active,
    /// Job has failed and will not be retried.
    Failed,
}
```

### What to Document

| Item Type | Required Content |
|-----------|------------------|
| Structs | Purpose, usage example |
| Struct fields | What the field represents |
| Enums | When to use each variant |
| Enum variants | What state it represents |
| Functions | What it does, parameters, return value |
| Traits | Contract and expected behavior |
| Trait methods | Default implementation behavior |
| Type aliases | Why the alias exists |
| Constants | What the value represents |

### Enforcement

Enable the `missing_docs` lint to catch undocumented public items:

```rust
#![warn(missing_docs)]
```

Or in `Cargo.toml` for workspace-wide enforcement:

```toml
[workspace.lints.rust]
missing_docs = "warn"
```

Related: `doc-module-inner`, `doc-examples-section`, `lint-missing-docs`

## doc-module-inner

> Use `//!` for module-level documentation

### Why It Matters

Inner doc comments (`//!`) document the module itself, not the next item. They appear at the top of module files and describe the module's purpose, contents, and usage patterns. This helps users understand what a module provides before diving into individual items.

Module docs are the first thing users see in `cargo doc` when navigating to a module.

### Bad

```rust
// This module handles authentication
// It provides JWT and session-based auth

mod auth;

pub use auth::*;
```

```rust
// auth.rs
/// Authentication utilities  // Wrong: this documents nothing useful
use std::collections::HashMap;

pub struct Session { /* ... */ }
```

### Good

```rust
//! Authentication and authorization utilities.
//!
//! This module provides multiple authentication strategies:
//!
//! - [`JwtAuth`] - JSON Web Token based authentication
//! - [`SessionAuth`] - Cookie-based session authentication
//! - [`ApiKeyAuth`] - API key authentication for services
//!
//! # Examples
//!
//! ```
//! use my_crate::auth::{JwtAuth, Authenticator};
//!
//! let auth = JwtAuth::new("secret-key");
//! let token = auth.generate_token(&user)?;
//! ```
//!
//! # Feature Flags
//!
//! - `jwt` - Enables JWT authentication (enabled by default)
//! - `sessions` - Enables session-based authentication

use std::collections::HashMap;

pub struct Session { /* ... */ }
```

### Where to Use Inner Docs

| Location | Purpose |
|----------|---------|
| `lib.rs` | Crate-level documentation (appears on crate root) |
| `mod.rs` | Module documentation for directory modules |
| `module.rs` | Module documentation for single-file modules |

### Crate Root Example

```rust
//! # My Awesome Crate
//!
//! `my_crate` provides utilities for handling complex workflows.
//!
//! ## Quick Start
//!
//! ```rust
//! use my_crate::prelude::*;
//!
//! let workflow = Workflow::builder()
//!     .add_step(Step::new("fetch"))
//!     .add_step(Step::new("process"))
//!     .build();
//! ```
//!
//! ## Modules
//!
//! - [`workflow`] - Core workflow engine
//! - [`steps`] - Built-in workflow steps
//! - [`prelude`] - Common imports
//!
//! ## Feature Flags
//!
//! | Feature | Description |
//! |---------|-------------|
//! | `async` | Async workflow execution |
//! | `serde` | Serialization support |

pub mod workflow;
pub mod steps;
pub mod prelude;
```

### Key Sections for Module Docs

1. **Brief description** - One-line summary
2. **Overview** - What the module provides
3. **Examples** - How to use it
4. **Feature flags** - Optional functionality
5. **See Also** - Related modules

Related: `doc-all-public`, `doc-examples-section`, `doc-cargo-metadata`

## doc-examples-section

> Include `# Examples` with runnable code

### Why It Matters

Examples are the most valuable part of documentation. They show users exactly how to use your API. Rust's doc tests ensure examples stay correct as code evolves.

### Bad

```rust
/// Parses a string into a Foo.
pub fn parse(s: &str) -> Result<Foo, Error> {
    // No examples - users have to guess usage
}

/// A widget for doing things.
/// 
/// This widget is very useful.
pub struct Widget {
    // Still no examples
}
```

### Good

```rust
/// Parses a string into a Foo.
///
/// # Examples
///
/// ```
/// use my_crate::parse;
///
/// let foo = parse("hello").unwrap();
/// assert_eq!(foo.name(), "hello");
/// ```
///
/// Handles empty strings:
///
/// ```
/// use my_crate::parse;
///
/// let foo = parse("").unwrap();
/// assert!(foo.is_empty());
/// ```
pub fn parse(s: &str) -> Result<Foo, Error> {
    // ...
}
```

### Use ? Not unwrap()

```rust
/// Loads configuration from a file.
///
/// # Examples
///
/// ```
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// use my_crate::Config;
///
/// let config = Config::load("config.toml")?;
/// println!("Port: {}", config.port);
/// # Ok(())
/// # }
/// ```
pub fn load(path: &str) -> Result<Config, Error> {
    // ...
}
```

### Hide Setup Code

```rust
/// Processes items from a database.
///
/// # Examples
///
/// ```
/// # use my_crate::{Database, Item};
/// # fn get_db() -> Database { Database::mock() }
/// let db = get_db();
/// let items = db.process_items()?;
/// assert!(!items.is_empty());
/// # Ok::<(), my_crate::Error>(())
/// ```
pub fn process_items(&self) -> Result<Vec<Item>, Error> {
    // ...
}
```

### Multiple Examples

```rust
/// Creates a new buffer with the specified capacity.
///
/// # Examples
///
/// Basic usage:
///
/// ```
/// use my_crate::Buffer;
///
/// let buf = Buffer::with_capacity(1024);
/// assert_eq!(buf.capacity(), 1024);
/// ```
///
/// Zero capacity creates an empty buffer:
///
/// ```
/// use my_crate::Buffer;
///
/// let buf = Buffer::with_capacity(0);
/// assert!(buf.is_empty());
/// ```
pub fn with_capacity(cap: usize) -> Self {
    // ...
}
```

### Show Error Cases

```rust
/// Divides two numbers.
///
/// # Examples
///
/// ```
/// use my_crate::divide;
///
/// assert_eq!(divide(10, 2), Ok(5));
/// ```
///
/// Division by zero returns an error:
///
/// ```
/// use my_crate::{divide, MathError};
///
/// assert_eq!(divide(10, 0), Err(MathError::DivisionByZero));
/// ```
pub fn divide(a: i32, b: i32) -> Result<i32, MathError> {
    // ...
}
```

### Running Doc Tests

```bash
# Run all doc tests
cargo test --doc

# Run doc tests for specific item
cargo test --doc my_function
```

Related: `doc-question-mark`, `doc-hidden-setup`, `doc-errors-section`

## doc-errors-section

> Include `# Errors` section for fallible functions

### Why It Matters

Functions returning `Result` can fail in specific, documented ways. The `# Errors` section tells users exactly when and why a function might return an error, enabling them to handle failures appropriately without reading source code.

This is especially critical for library code where users cannot easily inspect implementation details.

### Bad

```rust
/// Opens a file and reads its contents.
pub fn read_file(path: &Path) -> Result<String, Error> {
    // Users have no idea what errors to expect
}

/// Connects to the database.
pub async fn connect(url: &str) -> Result<Connection, DbError> {
    // Multiple failure modes, none documented
}
```

### Good

```rust
/// Opens a file and reads its contents as a UTF-8 string.
///
/// # Errors
///
/// Returns an error if:
/// - The file does not exist ([`Error::NotFound`])
/// - The process lacks permission to read the file ([`Error::PermissionDenied`])
/// - The file contains invalid UTF-8 ([`Error::InvalidUtf8`])
pub fn read_file(path: &Path) -> Result<String, Error> {
    // ...
}

/// Establishes a connection to the database.
///
/// # Errors
///
/// This function will return an error if:
/// - The URL is malformed ([`DbError::InvalidUrl`])
/// - The database server is unreachable ([`DbError::ConnectionFailed`])
/// - Authentication fails ([`DbError::AuthenticationFailed`])
/// - The connection pool is exhausted ([`DbError::PoolExhausted`])
pub async fn connect(url: &str) -> Result<Connection, DbError> {
    // ...
}
```

### Error Documentation Patterns

#### Simple Single Error

```rust
/// Parses a string as an integer.
///
/// # Errors
///
/// Returns [`ParseIntError`] if the string is not a valid integer.
pub fn parse_int(s: &str) -> Result<i64, ParseIntError> {
    s.parse()
}
```

#### Multiple Error Variants

```rust
/// Sends an HTTP request and returns the response.
///
/// # Errors
///
/// | Error | Condition |
/// |-------|-----------|
/// | [`HttpError::Timeout`] | Request exceeded timeout duration |
/// | [`HttpError::InvalidUrl`] | URL could not be parsed |
/// | [`HttpError::ConnectionRefused`] | Server refused connection |
/// | [`HttpError::TlsError`] | TLS handshake failed |
pub fn send(request: Request) -> Result<Response, HttpError> {
    // ...
}
```

#### Propagated Errors

```rust
/// Loads configuration from a file.
///
/// # Errors
///
/// Returns an error if:
/// - The configuration file cannot be read (IO error)
/// - The file contains invalid TOML syntax
/// - Required fields are missing from the configuration
///
/// The underlying error is wrapped with context about which
/// configuration file failed to load.
pub fn load_config(path: &Path) -> Result<Config, anyhow::Error> {
    // ...
}
```

### Linking to Error Types

Use intra-doc links to connect error variants to their definitions:

```rust
/// # Errors
///
/// Returns [`ValidationError::TooShort`] if the input is less than
/// the minimum length, or [`ValidationError::InvalidChars`] if it
/// contains forbidden characters.
```

Related: `doc-panics-section`, `err-doc-errors`, `doc-intra-links`

## doc-panics-section

> Include `# Panics` section for functions that can panic

### Why It Matters

Panics are exceptional conditions that crash the program (or unwind the stack). Users need to know when a function might panic so they can ensure preconditions are met or avoid the function in contexts where panics are unacceptable (e.g., `no_std`, embedded, FFI).

If a function can panic, document exactly when.

### Bad

```rust
/// Returns the element at the given index.
pub fn get(index: usize) -> &T {
    &self.data[index]  // Panics if out of bounds - not documented!
}

/// Divides two numbers.
pub fn divide(a: i32, b: i32) -> i32 {
    a / b  // Panics on division by zero - not documented!
}
```

### Good

```rust
/// Returns the element at the given index.
///
/// # Panics
///
/// Panics if `index` is out of bounds (i.e., `index >= self.len()`).
///
/// # Examples
///
/// ```
/// let v = vec![1, 2, 3];
/// assert_eq!(v.get(1), &2);
/// ```
pub fn get(&self, index: usize) -> &T {
    &self.data[index]
}

/// Divides two numbers.
///
/// # Panics
///
/// Panics if `divisor` is zero.
///
/// For a non-panicking version, use [`checked_divide`].
pub fn divide(dividend: i32, divisor: i32) -> i32 {
    dividend / divisor
}

/// Divides two numbers, returning `None` if the divisor is zero.
pub fn checked_divide(dividend: i32, divisor: i32) -> Option<i32> {
    if divisor == 0 {
        None
    } else {
        Some(dividend / divisor)
    }
}
```

### Common Panic Conditions

| Operation | Panic Condition |
|-----------|-----------------|
| Index access `[i]` | Index out of bounds |
| Division `/`, `%` | Division by zero |
| `.unwrap()` | `None` or `Err` value |
| `.expect()` | `None` or `Err` value |
| `slice::split_at(mid)` | `mid > len` |
| `Vec::remove(i)` | `i >= len` |
| Overflow (debug) | Integer overflow |

### Pattern: Panic vs Return Error

Document why you chose to panic vs return `Result`:

```rust
/// Creates a new buffer with the given capacity.
///
/// # Panics
///
/// Panics if `capacity` is zero. A buffer must have at least
/// one byte of capacity.
///
/// This panics rather than returning an error because a zero-capacity
/// buffer represents a programming error, not a runtime condition.
pub fn new(capacity: usize) -> Self {
    assert!(capacity > 0, "capacity must be non-zero");
    // ...
}
```

### Pattern: Debug-Only Panics

```rust
/// Adds an item to the collection.
///
/// # Panics
///
/// In debug builds, panics if the collection is at capacity.
/// In release builds, this is a no-op when at capacity.
pub fn push(&mut self, item: T) {
    debug_assert!(self.len < self.capacity, "collection at capacity");
    // ...
}
```

### Provide Non-Panicking Alternatives

When documenting a panicking function, point to safe alternatives:

```rust
/// # Panics
///
/// Panics if the index is out of bounds.
///
/// For a non-panicking version, use [`get`] which returns `Option<&T>`.
```

Related: `doc-errors-section`, `doc-safety-section`, `err-result-over-panic`

## doc-safety-section

> Include `# Safety` section for unsafe functions

### Why It Matters

Unsafe functions require callers to uphold invariants that the compiler cannot verify. The `# Safety` section documents exactly what the caller must guarantee for the function to be sound. Without this, users cannot safely call the function.

This is not optional—it's a requirement for sound unsafe code.

### Bad

```rust
/// Reads a value from a raw pointer.
pub unsafe fn read_ptr<T>(ptr: *const T) -> T {
    // What guarantees must the caller provide? Unknown!
    ptr.read()
}

/// Creates a string from raw parts.
pub unsafe fn string_from_raw(ptr: *mut u8, len: usize, cap: usize) -> String {
    String::from_raw_parts(ptr, len, cap)
}
```

### Good

```rust
/// Reads a value from a raw pointer.
///
/// # Safety
///
/// The caller must ensure that:
/// - `ptr` is valid for reads of `size_of::<T>()` bytes
/// - `ptr` is properly aligned for type `T`
/// - `ptr` points to a properly initialized value of type `T`
/// - The memory referenced by `ptr` is not mutated during this call
pub unsafe fn read_ptr<T>(ptr: *const T) -> T {
    ptr.read()
}

/// Creates a `String` from raw parts.
///
/// # Safety
///
/// The caller must guarantee that:
/// - `ptr` was allocated by the same allocator that `String` uses
/// - `len` is less than or equal to `cap`
/// - The first `len` bytes at `ptr` are valid UTF-8
/// - `cap` is the capacity that `ptr` was allocated with
/// - No other code will use `ptr` after this call (ownership is transferred)
///
/// Violating these requirements leads to undefined behavior including
/// memory corruption, use-after-free, or invalid UTF-8 in strings.
pub unsafe fn string_from_raw(ptr: *mut u8, len: usize, cap: usize) -> String {
    String::from_raw_parts(ptr, len, cap)
}
```

### Key Elements of Safety Documentation

| Element | Description |
|---------|-------------|
| **Preconditions** | What must be true before calling |
| **Pointer validity** | Alignment, null-ness, lifetime |
| **Memory ownership** | Who owns what, transfer semantics |
| **Invariants** | Type invariants that must hold |
| **Consequences** | What happens if violated |

### Pattern: Unsafe Trait Implementations

```rust
/// A type that can be safely zeroed.
///
/// # Safety
///
/// Implementing this trait guarantees that:
/// - All bit patterns of zeros represent a valid value of this type
/// - The type has no padding bytes that could leak data
/// - The type contains no references or pointers
pub unsafe trait Zeroable {
    fn zeroed() -> Self;
}

// SAFETY: u32 is a primitive integer type where all zero bits
// represent a valid value (0).
unsafe impl Zeroable for u32 {
    fn zeroed() -> Self {
        0
    }
}
```

### Pattern: Unsafe Blocks in Safe Functions

When a safe function contains unsafe blocks, document the invariants:

```rust
/// Returns a reference to the element at the given index.
///
/// Returns `None` if the index is out of bounds.
pub fn get(&self, index: usize) -> Option<&T> {
    if index < self.len {
        // SAFETY: We just verified that index < len, so this
        // access is within bounds.
        Some(unsafe { self.data.get_unchecked(index) })
    } else {
        None
    }
}
```

### Common Safety Requirements

```rust
/// # Safety
///
/// - Pointer must be non-null
/// - Pointer must be aligned to `align_of::<T>()`
/// - Pointer must be valid for reads/writes of `size_of::<T>()` bytes
/// - Pointer must point to an initialized value of `T`
/// - The referenced memory must not be accessed through any other pointer
///   for the duration of the returned reference
/// - The total size must not exceed `isize::MAX`
```

Related: `doc-panics-section`, `lint-unsafe-doc`, `doc-errors-section`
