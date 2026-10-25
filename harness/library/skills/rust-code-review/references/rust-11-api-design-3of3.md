---
name: rust-11-api-design-3of3
description: Rust rules module 11: API Design (part 3 of 3). 6 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `api-`
---

# API Design (part 3/3)

Priority: HIGH. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `api-from-not-into` - Implement `From<T>`, not `Into<U>` - From gives you Into for free
- `api-default-impl` - Implement `Default` for types with sensible default values
- `api-common-traits` - Implement standard traits (Debug, Clone, PartialEq, etc.) for public types
- `api-serde-optional` - Make serde a feature flag, not a hard dependency for library crates
- `api-impl-fromiterator` - Implement `FromIterator` and `Extend` for collection types, and `IntoIterator` for all three reference forms
- `api-operator-overload` - Overload operators only when the semantics are natural and unsurprising

---

## api-from-not-into

> Implement `From<T>`, not `Into<U>` - From gives you Into for free

### Why It Matters

The standard library has a blanket implementation: `impl<T, U> Into<U> for T where U: From<T>`. This means implementing `From<T> for U` automatically gives you `Into<U> for T`. Implementing `Into` directly bypasses this and is considered non-idiomatic. Always implement `From`.

### Bad

```rust
struct UserId(u64);

// Non-idiomatic: implementing Into directly
impl Into<UserId> for u64 {
    fn into(self) -> UserId {
        UserId(self)
    }
}

// Works, but now you can't use From syntax
let id = UserId::from(42);  // Error: From not implemented
let id: UserId = 42.into(); // Works, but limited
```

### Good

```rust
struct UserId(u64);

// Idiomatic: implement From
impl From<u64> for UserId {
    fn from(id: u64) -> Self {
        UserId(id)
    }
}

// Now both work automatically
let id = UserId::from(42);   // From syntax
let id: UserId = 42.into();  // Into syntax (via blanket impl)

// And Into bound works in generics
fn process(id: impl Into<UserId>) {
    let id: UserId = id.into();
}
process(42u64);  // Works!
```

### Blanket Implementation

```rust
// This is in std, you don't write it
impl<T, U> Into<U> for T
where
    U: From<T>,
{
    fn into(self) -> U {
        U::from(self)
    }
}

// So when you implement From:
impl From<String> for MyType { ... }

// You automatically get:
// impl Into<MyType> for String { ... }
```

### Multiple From Implementations

```rust
struct Email(String);

impl From<String> for Email {
    fn from(s: String) -> Self {
        Email(s)
    }
}

impl From<&str> for Email {
    fn from(s: &str) -> Self {
        Email(s.to_string())
    }
}

// All of these work
let e1 = Email::from("test@example.com");
let e2 = Email::from(String::from("test@example.com"));
let e3: Email = "test@example.com".into();
let e4: Email = String::from("test@example.com").into();
```

### TryFrom for Fallible Conversions

```rust
use std::convert::TryFrom;

struct PositiveInt(u32);

// Fallible conversion
impl TryFrom<i32> for PositiveInt {
    type Error = &'static str;
    
    fn try_from(value: i32) -> Result<Self, Self::Error> {
        if value > 0 {
            Ok(PositiveInt(value as u32))
        } else {
            Err("value must be positive")
        }
    }
}

// Usage
let pos = PositiveInt::try_from(42)?;   // From-style
let pos: PositiveInt = 42.try_into()?;  // Into-style (via blanket)
```

### Clippy Lint

```toml
[lints.clippy]
from_over_into = "warn"  # Warns when implementing Into instead of From
```

```rust
// Clippy will warn:
impl Into<Bar> for Foo {  // Warning: prefer From
    fn into(self) -> Bar { ... }
}
```

### When Into IS Needed (Rare)

```rust
// Only when implementing for external types in specific trait bounds
// This is very rare and usually indicates a design issue

// Example: you can't implement From<ExternalA> for ExternalB
// because of orphan rules. But you usually shouldn't need to.
```

Related: `api-impl-into`, `err-from-impl`, `api-newtype-safety`, `conv-tryfrom-fallible`, `conv-fromstr-parsing`

## api-default-impl

> Implement `Default` for types with sensible default values

### Why It Matters

`Default` is a standard trait that provides a canonical way to create a default instance. It integrates with many ecosystem patterns: `Option::unwrap_or_default()`, `#[derive(Default)]`, struct update syntax `..Default::default()`, and generic code that requires `T: Default`. Implementing it makes your types more ergonomic.

### Bad

```rust
struct Config {
    timeout: Duration,
    retries: u32,
    verbose: bool,
}

impl Config {
    // Custom constructor - works but non-standard
    fn new() -> Self {
        Config {
            timeout: Duration::from_secs(30),
            retries: 3,
            verbose: false,
        }
    }
}

// Can't use with standard patterns
let config: Config = Default::default();  // Error: Default not implemented
let timeout = settings.get("timeout").unwrap_or_default();  // Won't work
```

### Good

```rust
use std::time::Duration;

// Simple case: derive uses each field type's Default (Duration::ZERO, 0, false)
#[derive(Default)]
struct Config {
    timeout: Duration,
    retries: u32,
    verbose: bool,
}
```

For a non-zero default, implement `Default` by hand instead of deriving. (Per-field defaults like `timeout: Duration = Duration::from_secs(30)` require the nightly `default_field_values` feature.)

```rust
use std::time::Duration;

struct Config {
    timeout: Duration,
    retries: u32,
    verbose: bool,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            timeout: Duration::from_secs(30),
            retries: 3,
            verbose: false,
        }
    }
}

// Now works with all standard patterns
let config = Config::default();
let config = Config { retries: 5, ..Default::default() };
let value = map.get("key").cloned().unwrap_or_default();
```

### Derive vs Manual

```rust
// Derive: all fields use their own Default
#[derive(Default)]
struct Simple {
    count: u32,      // 0
    name: String,    // ""
    items: Vec<i32>, // []
}

// Manual: when you need custom defaults
struct Connection {
    host: String,
    port: u16,
    timeout: Duration,
}

impl Default for Connection {
    fn default() -> Self {
        Connection {
            host: "localhost".to_string(),
            port: 8080,
            timeout: Duration::from_secs(30),
        }
    }
}
```

### Builder with Default

```rust
#[derive(Default)]
struct ServerBuilder {
    host: String,
    port: u16,
    workers: usize,
}

impl ServerBuilder {
    fn host(mut self, host: impl Into<String>) -> Self {
        self.host = host.into();
        self
    }
    
    fn port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }
}

// Clean initialization
let server = ServerBuilder::default()
    .host("0.0.0.0")
    .port(3000)
    .build();
```

### Default with Required Fields

```rust
// When some fields have no sensible default, don't implement Default
struct User {
    id: UserId,       // No sensible default
    name: String,     // Could default to ""
}

// Instead, provide a constructor
impl User {
    fn new(id: UserId, name: impl Into<String>) -> Self {
        User { id, name: name.into() }
    }
}

// Or use builder with required fields
struct UserBuilder {
    id: Option<UserId>,
    name: String,
}

impl Default for UserBuilder {
    fn default() -> Self {
        UserBuilder {
            id: None,
            name: String::new(),
        }
    }
}
```

### Generic Default

```rust
// Require Default in generic bounds when needed
fn create_or_default<T: Default>(opt: Option<T>) -> T {
    opt.unwrap_or_default()
}

// PhantomData is Default regardless of T
use std::marker::PhantomData;
struct Wrapper<T> {
    _marker: PhantomData<T>,
}

impl<T> Default for Wrapper<T> {
    fn default() -> Self {
        Wrapper { _marker: PhantomData }
    }
}
```

Related: `api-builder-pattern`, `api-common-traits`, `api-from-not-into`

## api-common-traits

> Implement standard traits (Debug, Clone, PartialEq, etc.) for public types

### Why It Matters

Standard traits make your types interoperable with the Rust ecosystem. `Debug` enables `println!("{:?}")` and error messages. `Clone` allows explicit duplication. `PartialEq` enables `==`. Without these, users can't use your types in common patterns like testing, collections, or debugging.

### Bad

```rust
// Bare struct - severely limited usability
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Can't debug
println!("{:?}", point);  // Error: Debug not implemented

// Can't compare
if point1 == point2 { }  // Error: PartialEq not implemented

// Can't use in HashMap
let mut map: HashMap<Point, Value> = HashMap::new();  // Error: Hash not implemented

// Can't clone
let copy = point.clone();  // Error: Clone not implemented
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

// Now everything works
println!("{:?}", point);
assert_eq!(point1, point2);
let copy = point;  // Copy, not just Clone

// For hashable types
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct UserId(u64);

let mut map: HashMap<UserId, User> = HashMap::new();
```

### Trait Derivation Guide

| Trait | Derive When | Requirements |
|-------|-------------|--------------|
| `Debug` | Always for public types | All fields implement Debug |
| `Clone` | Type can be duplicated | All fields implement Clone |
| `Copy` | Small, simple types | All fields implement Copy, no Drop |
| `PartialEq` | Comparison makes sense | All fields implement PartialEq |
| `Eq` | Total equality | PartialEq, no floating-point fields |
| `Hash` | Used as HashMap/HashSet key | Eq, consistent with PartialEq |
| `Default` | Sensible default exists | All fields implement Default |
| `PartialOrd` | Ordering makes sense | PartialEq, all fields implement PartialOrd |
| `Ord` | Total ordering | Eq + PartialOrd, no floating-point |

### Common Trait Bundles

```rust
// ID types
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct EntityId(u64);

// Value types
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub struct Vector2 { x: f32, y: f32 }

// Configuration
#[derive(Debug, Clone, PartialEq, Default)]
pub struct Config {
    name: String,
    options: HashMap<String, String>,
}

// Error types
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    InvalidSyntax(String),
    UnexpectedToken(Token),
}
```

### Manual Implementations

```rust
// When derive doesn't do what you want
struct CaseInsensitiveString(String);

impl PartialEq for CaseInsensitiveString {
    fn eq(&self, other: &Self) -> bool {
        self.0.to_lowercase() == other.0.to_lowercase()
    }
}

impl Eq for CaseInsensitiveString {}

impl Hash for CaseInsensitiveString {
    fn hash<H: Hasher>(&self, state: &mut H) {
        // Must be consistent with PartialEq
        self.0.to_lowercase().hash(state);
    }
}

// Custom Debug for sensitive data
struct Password(String);

impl Debug for Password {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Password([REDACTED])")
    }
}
```

### Serde Traits

```rust
use serde::{Serialize, Deserialize};

// For serializable types
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ApiResponse {
    pub status: String,
    pub data: Vec<Item>,
}

// With custom serialization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default)]
    pub verbose: bool,
    
    #[serde(skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,
}
```

### Minimum Recommended

```rust
// At minimum, public types should have:
#[derive(Debug, Clone, PartialEq)]
pub struct MyType { ... }

// Add based on use case:
// + Eq, Hash       → for HashMap keys
// + Ord, PartialOrd → for BTreeMap, sorting
// + Default        → for Option::unwrap_or_default()
// + Copy           → for small value types
// + Serialize      → for serialization
```

Related: `own-copy-small`, `api-default-impl`, `doc-examples-section`, `type-display-vs-debug`

## api-serde-optional

> Make serde a feature flag, not a hard dependency for library crates

### Why It Matters

Not all users of your library need serialization. Making serde a required dependency adds compile time and binary size for everyone. Feature flags let users opt-in to serde support only when needed, following Rust's philosophy of zero-cost abstractions and minimal dependencies.

### Bad

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }

// lib.rs
use serde::{Serialize, Deserialize};

// Every user pays for serde, even if they don't need it
#[derive(Serialize, Deserialize)]
pub struct Config {
    pub name: String,
    pub value: i32,
}
```

### Good

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"], optional = true }

[features]
default = []
serde = ["dep:serde"]

// lib.rs
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Users opt-in:
// my_crate = { version = "1.0", features = ["serde"] }
```

### Macro Pattern

```rust
// Reusable macro for serde derives
#[cfg(feature = "serde")]
macro_rules! impl_serde {
    ($($t:ty),*) => {
        $(
            impl serde::Serialize for $t {
                // ...
            }
            impl<'de> serde::Deserialize<'de> for $t {
                // ...
            }
        )*
    };
}

#[cfg(not(feature = "serde"))]
macro_rules! impl_serde {
    ($($t:ty),*) => {};
}

// Or use cfg_attr for derived impls
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Point {
    pub x: f64,
    pub y: f64,
}
```

### Feature Documentation

```rust
// lib.rs

//! # Features
//!
//! - `serde`: Enables `Serialize` and `Deserialize` implementations for all types.
//!
//! # Example with serde
//!
//! ```toml
//! [dependencies]
//! my_crate = { version = "1.0", features = ["serde"] }
//! ```

#![cfg_attr(docsrs, feature(doc_cfg))]

/// A configuration type.
/// 
/// When the `serde` feature is enabled, this type implements
/// `Serialize` and `Deserialize`.
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(docsrs, doc(cfg(feature = "serde")))]
pub struct Config {
    pub name: String,
}
```

### Multiple Optional Dependencies

```rust
// Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"], optional = true }
rkyv = { version = "0.7", optional = true }
borsh = { version = "0.10", optional = true }

[features]
default = []
serde = ["dep:serde"]
rkyv = ["dep:rkyv"]
borsh = ["dep:borsh"]

// lib.rs
#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
#[cfg_attr(feature = "rkyv", derive(rkyv::Archive, rkyv::Serialize, rkyv::Deserialize))]
#[cfg_attr(feature = "borsh", derive(borsh::BorshSerialize, borsh::BorshDeserialize))]
pub struct Message {
    pub id: u64,
    pub content: String,
}
```

### Testing with Features

```bash
# Test without serde
cargo test

# Test with serde
cargo test --features serde

# Test all feature combinations
cargo test --all-features
```

```rust
// Test serde round-trip when feature enabled
#[cfg(feature = "serde")]
#[test]
fn test_serde_roundtrip() {
    let config = Config { name: "test".into() };
    let json = serde_json::to_string(&config).unwrap();
    let parsed: Config = serde_json::from_str(&json).unwrap();
    assert_eq!(config, parsed);
}
```

### When to Make Serde Required

```rust
// ✅ Required: Library is about serialization
// (e.g., json-schema, config-file parser)
[dependencies]
serde = "1.0"

// ✅ Required: Domain heavily uses serde
// (e.g., API client, data format library)

// ❌ Optional: General-purpose utility library
// ❌ Optional: Math/algorithm library
// ❌ Optional: Most libraries!
```

Related: `proj-lib-main-split`, `api-common-traits`, `lint-deny-correctness`, `serde-try-from-validate`, `serde-rename-all`

## api-impl-fromiterator

> Implement `FromIterator` and `Extend` for collection types, and `IntoIterator` for all three reference forms

### Why It Matters

The Rust API Guidelines (C-COLLECT) require that collection types implement `FromIterator<T>` so that `iter.collect::<MyCollection<T>>()` works. Pairing it with `Extend<T>` enables efficient batch insertion — the standard library uses `Extend` internally in `collect` when extending an existing collection. Implementing `IntoIterator` for the type itself, for `&Type`, and for `&mut Type` rounds out the contract and lets the collection participate in `for` loops and iterator adapter chains. Skipping these traits forces callers into awkward manual loops and breaks generic code.

### Bad

```rust
struct Bag<T>(Vec<T>);

impl<T> Bag<T> {
    fn new() -> Self { Bag(Vec::new()) }

    fn push(&mut self, item: T) { self.0.push(item); }
}

fn main() {
    // Callers must loop manually — no collect(), no extend(), no for loop
    let mut b = Bag::new();
    for x in [1, 2, 3] {
        b.push(x);
    }
}
```

### Good

```rust
struct Bag<T>(Vec<T>);

impl<T> Bag<T> {
    fn new() -> Self { Bag(Vec::new()) }

    fn push(&mut self, item: T) { self.0.push(item); }

    fn len(&self) -> usize { self.0.len() }

    fn is_empty(&self) -> bool { self.0.is_empty() }
}

// 1. FromIterator — enables .collect::<Bag<T>>()
impl<T> FromIterator<T> for Bag<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> Self {
        Bag(iter.into_iter().collect())
    }
}

// 2. Extend — enables .extend(iter) and is used internally by collect
impl<T> Extend<T> for Bag<T> {
    fn extend<I: IntoIterator<Item = T>>(&mut self, iter: I) {
        self.0.extend(iter);
    }
}

// 3a. IntoIterator for owned Bag (consuming)
impl<T> IntoIterator for Bag<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<T>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}

// 3b. IntoIterator for &Bag (borrowing)
impl<'a, T> IntoIterator for &'a Bag<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.iter()
    }
}

// 3c. IntoIterator for &mut Bag (mutable borrowing)
impl<'a, T> IntoIterator for &'a mut Bag<T> {
    type Item = &'a mut T;
    type IntoIter = std::slice::IterMut<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.iter_mut()
    }
}

fn main() {
    // collect works
    let b: Bag<i32> = [1, 2, 3].into_iter().collect();
    assert_eq!(b.len(), 3);

    // extend works
    let mut b2 = Bag::new();
    b2.extend([4, 5, 6]);
    assert_eq!(b2.len(), 3);

    // for loop works on &Bag
    for x in &b {
        let _ = x;
    }

    // map/filter chains work via IntoIterator
    let doubled: Bag<i32> = b.into_iter().map(|x| x * 2).collect();
    assert_eq!(doubled.len(), 3);
}
```

### Notes

- If your collection wraps an existing standard container, delegate `from_iter` and `extend` to the inner container's own implementations for maximum efficiency.
- `FromIterator` + `Extend` enable `collect` to call `extend` on a pre-allocated collection when possible, avoiding extra allocations.

Related: `name-iter-convention`, `perf-collect-once`, `api-common-traits`

## api-operator-overload

> Overload operators only when the semantics are natural and unsurprising

### Why It Matters

Rust allows operator overloading through traits in `std::ops` (`Add`, `Sub`, `Mul`, `Index`, `Neg`, etc.). The Rust API Guidelines (C-OVERLOAD) permit this — but only when the operator meaning is immediately obvious to any reader. Natural fits: arithmetic on numeric newtypes, vector/matrix math, set union/intersection with `+`/`|`, duration arithmetic. Surprising overloads — `+` that mutates state, `*` that performs a network call, `Index` that panics unconditionally — mislead readers and violate the principle of least surprise. When in doubt, name a method instead. Also implement the operator for references to avoid forcing callers to clone.

### Bad

```rust
use std::ops::Add;

struct Logger(Vec<String>);

// Anti-pattern: + mutates internal state and has a side effect
impl Add<String> for Logger {
    type Output = Logger;

    fn add(mut self, msg: String) -> Logger {
        self.0.push(msg.clone());
        println!("logged: {msg}"); // side effect in an operator
        self
    }
}
```

### Good

```rust
use std::ops::{Add, Neg};

#[derive(Debug, Clone, Copy, PartialEq)]
struct Vector2 {
    x: f64,
    y: f64,
}

impl Vector2 {
    pub fn new(x: f64, y: f64) -> Self {
        Vector2 { x, y }
    }

    pub fn dot(self, other: Vector2) -> f64 {
        self.x * other.x + self.y * other.y
    }
}

// Add for owned values
impl Add for Vector2 {
    type Output = Vector2;

    fn add(self, rhs: Vector2) -> Vector2 {
        Vector2::new(self.x + rhs.x, self.y + rhs.y)
    }
}

// Also implement for references — avoids forcing callers to clone
impl Add for &Vector2 {
    type Output = Vector2;

    fn add(self, rhs: &Vector2) -> Vector2 {
        Vector2::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl Neg for Vector2 {
    type Output = Vector2;

    fn neg(self) -> Vector2 {
        Vector2::new(-self.x, -self.y)
    }
}

fn main() {
    let a = Vector2::new(1.0, 2.0);
    let b = Vector2::new(3.0, 4.0);

    let c = a + b;               // owned
    let d = &a + &b;             // borrowed — no clone needed
    let e = -a;

    assert_eq!(c, Vector2::new(4.0, 6.0));
    assert_eq!(d, Vector2::new(4.0, 6.0));
    assert_eq!(e, Vector2::new(-1.0, -2.0));
}
```

### Decision Guide

| Situation | Verdict |
|-----------|---------|
| Arithmetic on a numeric newtype or geometric type | Implement |
| Set operations (`|` for union, `&` for intersection) | Implement |
| String concatenation on a custom string type | Implement |
| `Index`/`IndexMut` on a container that holds items | Implement |
| `+` or `*` with visible side effects | Never |
| Operator meaning depends on context not captured by types | Use a named method |

### Notes

- Always implement the corresponding assignment operator (`AddAssign`, `SubAssign`, etc.) when you implement the binary op.
- Prefer implementing for both owned and `&` forms to give callers flexibility without extra copies.
- Consider `std::ops::Mul<f64> for Vector2` (scalar multiply) alongside `Mul<Vector2>` — real-world numeric types often need several rhs types.

Related: `type-newtype-ids`, `api-common-traits`
