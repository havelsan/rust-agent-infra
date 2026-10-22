---
name: rust-30-naming-2of2
description: Rust rules module 30: Naming Conventions (part 2 of 2). 7 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `name-`
---

# Naming Conventions (part 2/2)

Priority: MEDIUM. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `name-no-get-prefix` - Omit get_ prefix for simple getters
- `name-is-has-bool` - Use `is_`, `has_`, `can_`, `should_` prefixes for boolean-returning methods
- `name-iter-convention` - Use iter/iter_mut/into_iter for iterator methods
- `name-iter-method` - Name iterator methods `iter()`, `iter_mut()`, and `into_iter()` consistently
- `name-iter-type-match` - Name iterator types after their source method
- `name-acronym-word` - Treat acronyms as words in identifiers: `HttpServer`, not `HTTPServer`
- `name-crate-no-rs` - Don't suffix crate names with `-rs` or `-rust`

---

## name-no-get-prefix

> Omit get_ prefix for simple getters

### Why It Matters

Rust convention omits the `get_` prefix for simple field access. Methods like `len()`, `name()`, `value()` are cleaner than `get_len()`, `get_name()`, `get_value()`. This follows the principle of making the common case concise.

The `get` prefix is reserved for methods that DO something beyond simple field access.

### Bad

```rust
struct User {
    name: String,
    age: u32,
}

impl User {
    fn get_name(&self) -> &str {      // Verbose
        &self.name
    }
    
    fn get_age(&self) -> u32 {         // Verbose
        self.age
    }
    
    fn get_is_adult(&self) -> bool {   // Doubly verbose
        self.age >= 18
    }
}

let name = user.get_name();
let age = user.get_age();
```

### Good

```rust
struct User {
    name: String,
    age: u32,
}

impl User {
    fn name(&self) -> &str {           // Clean
        &self.name
    }
    
    fn age(&self) -> u32 {             // Clean
        self.age
    }
    
    fn is_adult(&self) -> bool {       // Boolean uses is_ prefix
        self.age >= 18
    }
}

let name = user.name();
let age = user.age();
```

### When get_ IS Appropriate

Use `get` when the method does more than simple access:

```rust
impl HashMap<K, V> {
    // Returns Option - not just field access
    fn get(&self, key: &K) -> Option<&V> { }
    
    // Mutable variant
    fn get_mut(&mut self, key: &K) -> Option<&mut V> { }
}

impl Vec<T> {
    // Returns Option - bounds checked
    fn get(&self, index: usize) -> Option<&T> { }
}

impl Context {
    // Does computation/lookup, not just field access
    fn get_config(&self) -> Config {
        self.configs.get(&self.current_env).cloned().unwrap_or_default()
    }
}
```

### Standard Library Examples

```rust
// No get_ prefix
String::len()
Vec::len()
Vec::capacity()
Vec::is_empty()
Path::file_name()
Option::is_some()
Result::is_ok()

// With get - returns Option or does lookup
Vec::get(index)
HashMap::get(key)
BTreeMap::get(key)
```

### Pattern: Getter/Setter Pairs

```rust
impl Config {
    // Getter: no prefix
    fn timeout(&self) -> Duration {
        self.timeout
    }
    
    // Setter: use set_ prefix
    fn set_timeout(&mut self, timeout: Duration) {
        self.timeout = timeout;
    }
}
```

### Pattern: Builder Methods

```rust
impl ConfigBuilder {
    // Builder methods: no get_, no set_
    fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }
    
    fn retries(mut self, retries: u32) -> Self {
        self.retries = retries;
        self
    }
}
```

### Decision Guide

| Pattern | Naming |
|---------|--------|
| Simple field access | `name()`, `value()`, `len()` |
| Boolean property | `is_valid()`, `has_items()` |
| Fallible access | `get()`, `get_mut()` |
| Setter | `set_name()`, `set_value()` |
| Builder | `name()`, `value()` (consuming self) |

Related: `name-is-has-bool`, `name-is-has-bool`, `api-builder-pattern`

## name-is-has-bool

> Use `is_`, `has_`, `can_`, `should_` prefixes for boolean-returning methods

### Why It Matters

Boolean methods answer yes/no questions. Prefixes like `is_`, `has_`, `can_` make the question explicit, so code reads naturally: `if user.is_active()`, `if buffer.has_remaining()`. Without prefixes, boolean methods are ambiguous and require reading documentation.

### Bad

```rust
impl User {
    // Unclear: does this check or set?
    fn active(&self) -> bool { ... }
    
    // Unclear: does this delete or check?
    fn deleted(&self) -> bool { ... }
    
    // Unclear return type
    fn admin(&self) -> bool { ... }
}

// Reading code is confusing
if user.active() { ... }  // Is this checking or activating?
```

### Good

```rust
impl User {
    // Clear: answers "is the user active?"
    fn is_active(&self) -> bool { ... }
    
    // Clear: answers "is the user deleted?"
    fn is_deleted(&self) -> bool { ... }
    
    // Clear: answers "is the user an admin?"
    fn is_admin(&self) -> bool { ... }
    
    // Clear: answers "does the user have permission X?"
    fn has_permission(&self, perm: Permission) -> bool { ... }
    
    // Clear: answers "can the user edit?"
    fn can_edit(&self) -> bool { ... }
}

// Reads naturally
if user.is_active() && user.has_permission(Permission::Write) {
    // ...
}
```

### Common Prefixes

| Prefix | Use For | Example |
|--------|---------|---------|
| `is_` | State/property check | `is_empty()`, `is_valid()`, `is_some()` |
| `has_` | Possession/containment | `has_key()`, `has_children()`, `has_remaining()` |
| `can_` | Capability/permission | `can_read()`, `can_write()`, `can_execute()` |
| `should_` | Recommendation/policy | `should_retry()`, `should_cache()` |
| `needs_` | Requirement | `needs_update()`, `needs_auth()` |
| `will_` | Future action | `will_block()`, `will_overflow()` |

### Standard Library Examples

```rust
// is_ prefix
vec.is_empty()
option.is_some()
option.is_none()
result.is_ok()
result.is_err()
char.is_alphabetic()
str.is_ascii()
path.is_file()
path.is_dir()

// has_ prefix (less common in std)
iterator.has_next()  // conceptual

// Checking methods
str.contains("foo")      // Not is_ because takes argument
str.starts_with("bar")   // Descriptive verb phrase
str.ends_with("baz")
```

### Negation

```rust
// Prefer positive form with caller negation
if !user.is_active() { ... }

// Rather than negative method
if user.is_inactive() { ... }  // Avoid double negatives: !is_inactive()

// Exception: when negative is the common case
fn is_empty(&self) -> bool { ... }     // Checking for empty is common
fn is_not_empty(&self) -> bool { ... } // Rarely needed, use !is_empty()
```

### Boolean Fields

```rust
struct Config {
    // Field names can omit prefix
    enabled: bool,
    verbose: bool,
    debug: bool,
}

impl Config {
    // But methods should have prefix
    fn is_enabled(&self) -> bool {
        self.enabled
    }
    
    fn is_verbose(&self) -> bool {
        self.verbose
    }
}
```

Related: `name-no-get-prefix`, `name-funcs-snake`, `api-must-use`

## name-iter-convention

> Use iter/iter_mut/into_iter for iterator methods

### Why It Matters

Rust has a standard convention for iterator method names that signals ownership semantics. Following this convention makes APIs predictable and enables the `for item in collection` syntax to work correctly.

### The Three Iterator Methods

| Method | Returns | Ownership |
|--------|---------|-----------|
| `iter()` | `impl Iterator<Item = &T>` | Borrows collection |
| `iter_mut()` | `impl Iterator<Item = &mut T>` | Mutably borrows |
| `into_iter()` | `impl Iterator<Item = T>` | Consumes collection |

### Implementation

```rust
struct MyCollection<T> {
    items: Vec<T>,
}

impl<T> MyCollection<T> {
    /// Returns an iterator over references.
    fn iter(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    /// Returns an iterator over mutable references.
    fn iter_mut(&mut self) -> impl Iterator<Item = &mut T> {
        self.items.iter_mut()
    }
}

// IntoIterator trait for into_iter()
impl<T> IntoIterator for MyCollection<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.into_iter()
    }
}

// Also implement for references
impl<'a, T> IntoIterator for &'a MyCollection<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

impl<'a, T> IntoIterator for &'a mut MyCollection<T> {
    type Item = &'a mut T;
    type IntoIter = std::slice::IterMut<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter_mut()
    }
}
```

### Usage

```rust
let collection = MyCollection { items: vec![1, 2, 3] };

// Explicit methods
for x in collection.iter() { }     // Borrows
for x in collection.iter_mut() { } // Mutably borrows

// IntoIterator enables for loop syntax
for x in &collection { }      // Calls (&collection).into_iter()
for x in &mut collection { }  // Calls (&mut collection).into_iter()
for x in collection { }       // Consumes, calls collection.into_iter()
```

### Bad

```rust
impl MyCollection<T> {
    // Non-standard names
    fn elements(&self) -> impl Iterator<Item = &T> { }      // Should be iter()
    fn get_items(&self) -> impl Iterator<Item = &T> { }     // Should be iter()
    fn iterate(&self) -> impl Iterator<Item = &T> { }       // Should be iter()
    fn as_iter(&self) -> impl Iterator<Item = &T> { }       // Should be iter()
}
```

### Additional Iterator Methods

```rust
impl MyCollection<T> {
    // Filter by predicate
    fn iter_valid(&self) -> impl Iterator<Item = &T> {
        self.iter().filter(|x| x.is_valid())
    }
    
    // Specific slice
    fn iter_range(&self, start: usize, end: usize) -> impl Iterator<Item = &T> {
        self.items[start..end].iter()
    }
}
```

### Standard Library Examples

```rust
// Vec, slice, arrays
vec.iter()      // &T
vec.iter_mut()  // &mut T
vec.into_iter() // T

// HashMap
map.iter()      // (&K, &V)
map.iter_mut()  // (&K, &mut V)
map.into_iter() // (K, V)
map.keys()      // &K
map.values()    // &V
```

Related: `name-iter-type-match`, `name-iter-method`, `perf-iter-over-index`

## name-iter-method

> Name iterator methods `iter()`, `iter_mut()`, and `into_iter()` consistently

### Why It Matters

Rust has a strong convention for iterator method names. Following these conventions makes your types work predictably with `for` loops and iterator adapters. Users expect `iter()` for shared references, `iter_mut()` for mutable references, and `into_iter()` for owned iteration.

### Bad

```rust
struct Collection<T> {
    items: Vec<T>,
}

impl<T> Collection<T> {
    // Non-standard names - confusing
    fn elements(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    fn get_iterator(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    fn to_iter(self) -> impl Iterator<Item = T> {
        self.items.into_iter()
    }
}
```

### Good

```rust
struct Collection<T> {
    items: Vec<T>,
}

impl<T> Collection<T> {
    /// Returns an iterator over references.
    fn iter(&self) -> impl Iterator<Item = &T> {
        self.items.iter()
    }
    
    /// Returns an iterator over mutable references.
    fn iter_mut(&mut self) -> impl Iterator<Item = &mut T> {
        self.items.iter_mut()
    }
}

// Implement IntoIterator for for-loop support
impl<T> IntoIterator for Collection<T> {
    type Item = T;
    type IntoIter = std::vec::IntoIter<T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.into_iter()
    }
}

impl<'a, T> IntoIterator for &'a Collection<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

impl<'a, T> IntoIterator for &'a mut Collection<T> {
    type Item = &'a mut T;
    type IntoIter = std::slice::IterMut<'a, T>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.items.iter_mut()
    }
}
```

### Iterator Convention Summary

| Method | Receiver | Yields | Use Case |
|--------|----------|--------|----------|
| `iter()` | `&self` | `&T` | Read-only iteration |
| `iter_mut()` | `&mut self` | `&mut T` | In-place modification |
| `into_iter()` | `self` | `T` | Consuming iteration |

### For Loop Integration

```rust
let col = Collection { items: vec![1, 2, 3] };

// These all work with proper IntoIterator impls
for item in &col {           // Calls (&col).into_iter() -> iter()
    println!("{}", item);    // &i32
}

for item in &mut col {       // Calls (&mut col).into_iter() -> iter_mut()
    *item += 1;              // &mut i32
}

for item in col {            // Calls col.into_iter()
    process(item);           // i32, consumes col
}
```

### Additional Iterator Methods

```rust
impl<T> Collection<T> {
    // Domain-specific iterators follow similar patterns
    
    /// Iterates over keys (for map-like structures).
    fn keys(&self) -> impl Iterator<Item = &K> { ... }
    
    /// Iterates over values.
    fn values(&self) -> impl Iterator<Item = &V> { ... }
    
    /// Iterates over mutable values.
    fn values_mut(&mut self) -> impl Iterator<Item = &mut V> { ... }
    
    /// Drains elements, leaving container empty.
    fn drain(&mut self) -> impl Iterator<Item = T> { ... }
}
```

Related: `name-as-free`, `api-extension-trait`, `api-common-traits`

## name-iter-type-match

> Name iterator types after their source method

### Why It Matters

Iterator types should match the method that creates them. `iter()` returns `Iter`, `into_iter()` returns `IntoIter`, `keys()` returns `Keys`. This naming pattern is established by the standard library and makes types predictable.

### Standard Library Pattern

```rust
// Vec
impl<T> Vec<T> {
    fn iter(&self) -> Iter<'_, T> { }       // Returns Iter
    fn iter_mut(&mut self) -> IterMut<'_, T> { }  // Returns IterMut
}

impl<T> IntoIterator for Vec<T> {
    type IntoIter = IntoIter<T>;  // Returns IntoIter
}

// HashMap
impl<K, V> HashMap<K, V> {
    fn iter(&self) -> Iter<'_, K, V> { }
    fn keys(&self) -> Keys<'_, K, V> { }    // Returns Keys
    fn values(&self) -> Values<'_, K, V> { }  // Returns Values
    fn drain(&mut self) -> Drain<'_, K, V> { }  // Returns Drain
}
```

### Implementation

```rust
mod my_collection {
    pub struct MyCollection<T> {
        items: Vec<T>,
    }
    
    // Iterator types in same module
    pub struct Iter<'a, T> {
        inner: std::slice::Iter<'a, T>,
    }
    
    pub struct IterMut<'a, T> {
        inner: std::slice::IterMut<'a, T>,
    }
    
    pub struct IntoIter<T> {
        inner: std::vec::IntoIter<T>,
    }
    
    impl<T> MyCollection<T> {
        pub fn iter(&self) -> Iter<'_, T> {
            Iter { inner: self.items.iter() }
        }
        
        pub fn iter_mut(&mut self) -> IterMut<'_, T> {
            IterMut { inner: self.items.iter_mut() }
        }
    }
    
    impl<T> IntoIterator for MyCollection<T> {
        type Item = T;
        type IntoIter = IntoIter<T>;
        
        fn into_iter(self) -> IntoIter<T> {
            IntoIter { inner: self.items.into_iter() }
        }
    }
    
    // Implement Iterator for each type
    impl<'a, T> Iterator for Iter<'a, T> {
        type Item = &'a T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
    
    impl<'a, T> Iterator for IterMut<'a, T> {
        type Item = &'a mut T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
    
    impl<T> Iterator for IntoIter<T> {
        type Item = T;
        fn next(&mut self) -> Option<Self::Item> {
            self.inner.next()
        }
    }
}
```

### Naming Convention

| Method | Iterator Type |
|--------|---------------|
| `iter()` | `Iter` |
| `iter_mut()` | `IterMut` |
| `into_iter()` | `IntoIter` |
| `keys()` | `Keys` |
| `values()` | `Values` |
| `values_mut()` | `ValuesMut` |
| `drain()` | `Drain` |
| `chunks()` | `Chunks` |
| `windows()` | `Windows` |

### Custom Iterator Methods

```rust
impl Graph {
    // Method name -> Type name
    fn nodes(&self) -> Nodes<'_> { }        // Custom: Nodes
    fn edges(&self) -> Edges<'_> { }        // Custom: Edges
    fn neighbors(&self, node: NodeId) -> Neighbors<'_> { }  // Custom: Neighbors
}

pub struct Nodes<'a> { /* ... */ }
pub struct Edges<'a> { /* ... */ }
pub struct Neighbors<'a> { /* ... */ }
```

### Bad

```rust
// Mismatched names
impl MyCollection<T> {
    fn iter(&self) -> MyCollectionIterator<'_, T> { }  // Should be Iter
    fn keys(&self) -> KeyIterator<'_, K> { }           // Should be Keys
}

// Generic names that don't match method
pub struct Iterator<T>;  // Conflicts with std::iter::Iterator
pub struct I<T>;         // Too cryptic
```

Related: `name-iter-convention`, `name-iter-method`, `api-common-traits`

## name-acronym-word

> Treat acronyms as words in identifiers: `HttpServer`, not `HTTPServer`

### Why It Matters

When acronyms are written in ALL CAPS within identifiers, word boundaries become unclear: is `HTTPSHandler` "HTTPS Handler" or "HTTP SHandler"? Treating acronyms as words (`HttpsHandler`) maintains clear word boundaries and follows Rust convention. The standard library uses this consistently.

### Bad

```rust
// ALL CAPS acronyms - unclear word boundaries
struct HTTPServer { ... }      // HTTP + Server or H + TTP + Server?
struct TCPIPConnection { ... } // TCP + IP? Or other splits?
struct JSONParser { ... }
struct XMLHTTPRequest { ... }  // Very confusing

fn parseJSON(input: &str) { ... }
fn connectTCP(addr: &str) { ... }
```

### Good

```rust
// Acronyms as words - clear boundaries
struct HttpServer { ... }      // Http + Server
struct TcpIpConnection { ... } // Tcp + Ip + Connection
struct JsonParser { ... }
struct XmlHttpRequest { ... }

fn parse_json(input: &str) { ... }
fn connect_tcp(addr: &str) { ... }

// More examples
struct Uuid { ... }            // Not UUID
struct Uri { ... }             // Not URI
struct Url { ... }             // Not URL
struct Html { ... }            // Not HTML
struct Css { ... }             // Not CSS
struct Api { ... }             // Not API
```

### Standard Library Examples

```rust
// std uses acronyms as words
std::net::TcpStream            // Not TCPStream
std::net::TcpListener          // Not TCPListener
std::net::UdpSocket            // Not UDPSocket
std::net::IpAddr               // Not IPAddr
std::io::IoError               // Not IOError (though Io is acceptable too)
```

### Two-Letter Acronyms

```rust
// Two-letter acronyms can go either way
struct Io { ... }    // or IO - both acceptable
struct Id { ... }    // or ID - both acceptable

// Preference: treat as word for consistency
struct IoHandler { ... }     // Preferred
struct IdGenerator { ... }   // Preferred
```

### In snake_case

```rust
// Acronyms become lowercase in snake_case
fn parse_json() { ... }
fn connect_tcp() { ... }
fn generate_uuid() { ... }
fn fetch_http() { ... }
fn encode_url() { ... }

// Variables
let json_response = fetch_json();
let tcp_connection = connect_tcp();
let user_id = generate_uuid();
```

### Mixed Cases

```rust
// When acronym is part of compound
struct HttpsConnection { ... }   // Https (not HTTPS)
struct Utf8String { ... }        // Utf8 (not UTF8)
struct Base64Encoder { ... }     // Base64 as word

// Multiple acronyms
struct JsonApiClient { ... }     // Json + Api + Client
struct RestApiHandler { ... }    // Rest + Api + Handler
```

Related: `name-types-camel`, `name-funcs-snake`, `name-consts-screaming`

## name-crate-no-rs

> Don't suffix crate names with `-rs` or `-rust`

### Why It Matters

Adding `-rs` or `-rust` to crate names is redundant—you're already on crates.io, it's obviously Rust. These suffixes waste characters, clutter the namespace, and can make crate names harder to type. The Rust community discourages this pattern.

### Bad

```toml
# Cargo.toml
[package]
name = "json-parser-rs"    # Redundant -rs
name = "my-lib-rust"       # Redundant -rust
name = "http-client-rs"    # We know it's Rust
name = "rust-sqlite"       # rust- prefix equally bad
```

### Good

```toml
# Cargo.toml
[package]
name = "json-parser"
name = "my-lib"
name = "http-client"
name = "sqlite-wrapper"

# Real crate examples (no -rs):
# serde (not serde-rs)
# tokio (not tokio-rs)
# reqwest (not reqwest-rs)
# clap (not clap-rs)
```

### When Context Is Needed

```toml
# If you're porting a library from another language:
name = "python-ast"        # Describes what it's for, not what it's written in

# If you're providing bindings:
name = "openssl"           # The Rust crate IS the Rust interface

# Platform-specific:
name = "windows-sys"       # Platform, not language
```

### Repository Naming

```
# GitHub repos don't need -rs either
github.com/user/my-library      # Good
github.com/user/my-library-rs   # Unnecessary

# Though some do for disambiguation from other language versions
github.com/rust-lang/rust       # The rust repo itself uses "rust"
```

### Exceptions

```toml
# Rare cases where disambiguation matters:
# - If there's a widely-known non-Rust project with the same name
# - Official Rust project repositories (rust-lang org)

# But even then, consider alternatives:
name = "fancy-lib"           # Instead of fancy-rs
name = "better-json"         # Instead of json-rust
name = "my-serde-impl"       # Instead of serde-rs-fork
```

Related: `proj-workspace-deps`, `doc-cargo-metadata`, `name-funcs-snake`
