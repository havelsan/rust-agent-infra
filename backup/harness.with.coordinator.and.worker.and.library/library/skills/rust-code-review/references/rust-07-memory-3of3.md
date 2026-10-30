---
name: rust-07-memory-3of3
description: Rust rules module 07: Memory Optimization (part 3 of 3). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `mem-`
---

# Memory Optimization (part 3/3)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `mem-zero-copy` - Use zero-copy patterns with slices and `Bytes`
- `mem-compact-string` - Use compact string types for memory-constrained string storage
- `mem-smaller-integers` - Use appropriately-sized integers to reduce memory footprint
- `mem-assert-type-size` - Use static assertions to guard against accidental type size growth
- `mem-take-replace` - Use `mem::take` / `mem::replace` to move a value out of a `&mut` without cloning
- `mem-drop-order` - Know and control drop order: struct fields drop top-to-bottom, locals in reverse

---

## mem-zero-copy

> Use zero-copy patterns with slices and `Bytes`

### Why It Matters

Zero-copy means working with data without copying it. Instead of allocating new memory and copying bytes, you work with references to the original data. This dramatically reduces memory usage and improves performance, especially for large data.

### Bad

```rust
// Copies every line into a new String
fn get_lines(data: &str) -> Vec<String> {
    data.lines()
        .map(|line| line.to_string())  // Allocates!
        .collect()
}

// Copies the entire buffer
fn process_packet(buffer: &[u8]) -> Vec<u8> {
    let header = buffer[0..16].to_vec();  // Copy!
    let body = buffer[16..].to_vec();      // Copy!
    // Process...
    [header, body].concat()  // Another copy!
}
```

### Good

```rust
// Zero-copy: returns references to original data
fn get_lines(data: &str) -> Vec<&str> {
    data.lines().collect()  // Just pointers!
}

// Zero-copy with slices
fn process_packet(buffer: &[u8]) -> (&[u8], &[u8]) {
    let header = &buffer[0..16];  // Just a pointer + length
    let body = &buffer[16..];     // Just a pointer + length
    (header, body)
}
```

### Using bytes::Bytes

```rust
use bytes::Bytes;

// Bytes provides zero-copy slicing with reference counting
let data = Bytes::from("hello world");

// Slicing doesn't copy - just increments refcount
let hello = data.slice(0..5);   // Zero-copy!
let world = data.slice(6..11); // Zero-copy!

// Both hello and world share the underlying allocation
// Memory is freed when all references are dropped
```

### Common Pattern: Cow for Static Strings

A common pattern — seen in HTTP servers and similar code — returns
`Cow<'static, str>` to avoid allocating for well-known static values:

```rust
fn method_to_cow(method: &http::Method) -> Cow<'static, str> {
    match *method {
        Method::GET => Cow::Borrowed("GET"),      // Zero-copy
        Method::POST => Cow::Borrowed("POST"),    // Zero-copy
        Method::PUT => Cow::Borrowed("PUT"),      // Zero-copy
        _ => Cow::Owned(method.to_string()),      // Only copies for rare methods
    }
}
```

### Zero-Copy Parsing

```rust
// Bad: Copies each parsed field
struct ParsedBad {
    name: String,
    value: String,
}

fn parse_bad(input: &str) -> ParsedBad {
    let (name, value) = input.split_once('=').unwrap();
    ParsedBad {
        name: name.to_string(),   // Copy!
        value: value.to_string(), // Copy!
    }
}

// Good: References into original string
struct Parsed<'a> {
    name: &'a str,
    value: &'a str,
}

fn parse_good(input: &str) -> Parsed<'_> {
    let (name, value) = input.split_once('=').unwrap();
    Parsed { name, value }  // Zero-copy!
}
```

### Combining with Cow

```rust
use std::borrow::Cow;

// Zero-copy when possible, copy when needed
fn normalize<'a>(input: &'a str) -> Cow<'a, str> {
    if input.contains('\t') {
        // Must copy to modify
        Cow::Owned(input.replace('\t', "    "))
    } else {
        // Zero-copy reference
        Cow::Borrowed(input)
    }
}
```

### memchr for Fast Searching

```rust
use memchr::memchr;

// Fast byte search using SIMD
fn find_newline(data: &[u8]) -> Option<usize> {
    memchr(b'\n', data)  // SIMD-accelerated, no allocation
}

// Find all occurrences
use memchr::memchr_iter;

fn count_newlines(data: &[u8]) -> usize {
    memchr_iter(b'\n', data).count()
}
```

### When Zero-Copy Isn't Possible

```rust
// Need to modify data - must copy
fn uppercase(s: &str) -> String {
    s.to_uppercase()  // Creates new String
}

// Need data to outlive source
fn store_for_later(s: &str) -> String {
    s.to_string()  // Must copy for ownership
}

// Cross-thread transfer (without Arc)
fn send_to_thread(data: &[u8]) {
    let owned = data.to_vec();  // Must copy
    std::thread::spawn(move || {
        process(&owned);
    });
}
```

Related: `own-cow-conditional`, `own-borrow-over-clone`, `mem-arena-allocator`

## mem-compact-string

> Use compact string types for memory-constrained string storage

### Why It Matters

Standard `String` is 24 bytes (pointer + length + capacity). For applications storing millions of short strings, this overhead dominates. Compact string libraries like `compact_str`, `smartstring`, or `ecow` store small strings inline (no heap allocation) and use optimized layouts for larger strings.

### Bad

```rust
struct User {
    id: u64,
    // Most usernames are < 24 chars, but String is always 24 bytes + heap
    username: String,
    email: String,
}

// 1 million users = 24 bytes * 2 * 1M = 48MB just for String metadata
// Plus all the heap allocations for actual content
```

### Good

```rust
use compact_str::CompactString;

struct User {
    id: u64,
    // CompactString: 24 bytes, but strings ≤ 23 bytes are inline (no heap)
    username: CompactString,
    email: CompactString,
}

// Most usernames fit inline = zero heap allocations
// Same memory footprint as String but way fewer allocations
```

### Compact String Libraries

#### compact_str

```rust
use compact_str::CompactString;

// Inline storage for strings ≤ 23 bytes
let small: CompactString = "hello".into();  // No heap allocation

// Automatic heap fallback for larger strings
let large: CompactString = "x".repeat(100).into();

// String-like API
let mut s = CompactString::new("hello");
s.push_str(" world");
assert_eq!(s.as_str(), "hello world");

// Format macro
use compact_str::format_compact;
let s = format_compact!("value: {}", 42);
```

#### smartstring

```rust
use smartstring::{SmartString, LazyCompact};

// Default is LazyCompact: 24 bytes inline capacity
let s: SmartString<LazyCompact> = "short string".into();

// Compact mode: 23 bytes inline on 64-bit
use smartstring::Compact;
let s: SmartString<Compact> = "hello".into();
```

#### ecow (copy-on-write)

```rust
use ecow::EcoString;

// Clone is O(1) - shares underlying data
let s1: EcoString = "shared data".into();
let s2 = s1.clone();  // Cheap, shares allocation

// Copy-on-write: only allocates on mutation
let mut s3 = s1.clone();
s3.push_str(" modified");  // Now allocates
```

### Memory Comparison

```rust
use std::mem::size_of;

// All 24 bytes, but different inline capacities
assert_eq!(size_of::<String>(), 24);
assert_eq!(size_of::<compact_str::CompactString>(), 24);
assert_eq!(size_of::<smartstring::SmartString>(), 24);
assert_eq!(size_of::<ecow::EcoString>(), 16);  // Even smaller!
```

### Inline Capacity

| Type | Size | Inline Capacity |
|------|------|-----------------|
| `String` | 24 | 0 (always heap) |
| `CompactString` | 24 | 23 bytes [^1] |
| `SmartString<LazyCompact>` | 24 | 23 bytes |
| `EcoString` | 16 | 15 bytes |

[^1]: CompactString reserves the final byte of its 24-byte representation for a length tag, so the maximum inline string length is 23 bytes.

### When to Use

```rust
// ✅ Good: Many short strings in memory
struct Dictionary {
    words: Vec<CompactString>,  // Millions of short words
}

// ✅ Good: Frequently cloned strings
struct Template {
    parts: Vec<EcoString>,  // O(1) clone
}

// ❌ Don't: Hot path string manipulation
fn transform(s: &str) -> String {
    // Standard String is optimized for manipulation
    s.to_uppercase()
}

// ❌ Don't: API boundaries (prefer &str or String for interop)
pub fn public_api(input: CompactString) { }  // Forces dependency
pub fn public_api(input: impl Into<String>) { }  // Better
```

### Cargo.toml

```toml
[dependencies]
compact_str = "0.9"
# or
smartstring = "1.0"
# or
ecow = "0.2"
```

Related: `mem-boxed-slice`, `own-cow-conditional`, `mem-smallvec`

## mem-smaller-integers

> Use appropriately-sized integers to reduce memory footprint

### Why It Matters

Using `i64` when `i16` suffices wastes 6 bytes per value. In arrays, vectors, and structs with millions of instances, this waste compounds dramatically. Choosing the smallest integer type that fits your domain reduces memory usage and improves cache utilization.

### Bad

```rust
struct Pixel {
    r: u64,  // Color channels 0-255 = 8 bits needed
    g: u64,  // Using 64 bits = 8x waste
    b: u64,
    a: u64,
}
// Size: 32 bytes per pixel

struct HttpStatus {
    code: i32,      // HTTP codes 100-599 = 10 bits needed
    version: i32,   // HTTP 1.0, 1.1, 2, 3 = 2 bits needed
}
// Size: 8 bytes per status

struct GeoPoint {
    lat: f64,   // -90 to 90
    lon: f64,   // -180 to 180
}
// Often f32 precision is sufficient for display
```

### Good

```rust
struct Pixel {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}
// Size: 4 bytes per pixel (8x smaller!)

struct HttpStatus {
    code: u16,      // 100-599 fits in u16
    version: u8,    // 1, 2, 3 fits in u8
}
// Size: 3 bytes (+ 1 padding = 4 bytes)

struct GeoPoint {
    lat: f32,   // ~7 decimal digits precision
    lon: f32,   // Sufficient for most geo applications
}
// Size: 8 bytes vs 16 bytes
```

### Integer Size Reference

| Type | Range | Use For |
|------|-------|---------|
| `u8` | 0 to 255 | Bytes, small counts, flags |
| `i8` | -128 to 127 | Small signed values |
| `u16` | 0 to 65,535 | Port numbers, small indices |
| `i16` | -32,768 to 32,767 | Audio samples |
| `u32` | 0 to 4 billion | Array indices, timestamps (seconds) |
| `i32` | ±2 billion | General integers, file offsets |
| `u64` | 0 to 18 quintillion | Large counts, nanosecond timestamps |
| `usize` | Platform-dependent | Array indexing (required by Rust) |

### Struct Packing

```rust
use std::mem::size_of;

// Poor ordering - 24 bytes due to padding
struct Wasteful {
    a: u8,    // 1 byte + 7 padding
    b: u64,   // 8 bytes
    c: u8,    // 1 byte + 7 padding
}
assert_eq!(size_of::<Wasteful>(), 24);

// Better ordering - 16 bytes
struct Efficient {
    b: u64,   // 8 bytes (aligned)
    a: u8,    // 1 byte
    c: u8,    // 1 byte + 6 padding
}
assert_eq!(size_of::<Efficient>(), 16);

// Even better with smaller types - 10 bytes
struct Compact {
    b: u32,   // 4 bytes (if u32 suffices)
    a: u8,    // 1 byte
    c: u8,    // 1 byte
}
assert_eq!(size_of::<Compact>(), 8);  // With padding
```

### Conversion Safety

```rust
// Safe: always succeeds (widening)
let small: u8 = 42;
let big: u32 = small.into();

// Fallible: may overflow (narrowing)
let big: u32 = 1000;
let small: u8 = big.try_into().expect("value out of range");

// Or use checked conversion
if let Ok(small) = u8::try_from(big) {
    use_small(small);
} else {
    handle_overflow();
}
```

### Bitflags for Boolean Sets

```rust
use bitflags::bitflags;

// Instead of 8 separate bool fields (8 bytes minimum)
bitflags! {
    struct Permissions: u8 {
        const READ    = 0b0000_0001;
        const WRITE   = 0b0000_0010;
        const EXECUTE = 0b0000_0100;
        const DELETE  = 0b0000_1000;
    }
}
// All 8 flags in 1 byte!

let perms = Permissions::READ | Permissions::WRITE;
if perms.contains(Permissions::READ) {
    // ...
}
```

### NonZero Types for Option Optimization

```rust
use std::num::NonZeroU64;

// Option<u64> = 16 bytes (no null pointer optimization)
assert_eq!(size_of::<Option<u64>>(), 16);

// Option<NonZeroU64> = 8 bytes (0 represents None)
assert_eq!(size_of::<Option<NonZeroU64>>(), 8);

let id: Option<NonZeroU64> = NonZeroU64::new(42);
```

Related: `mem-box-large-variant`, `mem-assert-type-size`, `type-newtype-ids`, `num-nonzero`, `num-cast-try-from`

## mem-assert-type-size

> Use static assertions to guard against accidental type size growth

### Why It Matters

Adding a field to a frequently-instantiated struct can silently bloat memory usage. Static size assertions catch this at compile time, making size changes intentional rather than accidental. This is especially important for types stored in large collections or passed frequently by value.

### Bad

```rust
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
}

// Later, someone adds a field without realizing the impact
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
    metadata: String,  // Silently adds 24 bytes!
}

// 10 million events now use 240MB more memory
// No warning, no review trigger
```

### Good

```rust
struct Event {
    timestamp: u64,
    kind: EventKind,
    payload: [u8; 32],
}

// Static assertion - breaks compile if size changes
const _: () = assert!(std::mem::size_of::<Event>() == 48);

// Or with static_assertions crate
use static_assertions::assert_eq_size;
assert_eq_size!(Event, [u8; 48]);

// Now adding metadata triggers compile error:
// error: assertion failed: std::mem::size_of::<Event>() == 48
```

### static_assertions Crate

```rust
use static_assertions::{assert_eq_size, const_assert};

struct Critical {
    id: u64,
    flags: u32,
    data: [u8; 16],
}

// Exact size assertion
assert_eq_size!(Critical, [u8; 32]);

// Maximum size assertion
const_assert!(std::mem::size_of::<Critical>() <= 64);

// Alignment assertion
const_assert!(std::mem::align_of::<Critical>() == 8);

// Compare sizes
assert_eq_size!(Critical, [u64; 4]);
```

### Built-in Const Assertions

```rust
// No external crate needed (Rust 1.57+)
struct Packet {
    header: u32,
    payload: [u8; 60],
}

const _: () = assert!(
    std::mem::size_of::<Packet>() == 64,
    "Packet must be exactly 64 bytes for protocol compliance"
);

// Compile error shows custom message if assertion fails
```

### Documenting Size Constraints

```rust
/// Network protocol packet header.
/// 
/// # Size
/// 
/// This struct is guaranteed to be exactly 32 bytes to match
/// the network protocol specification. Any changes to fields
/// must maintain this size constraint.
#[repr(C)]  // Predictable layout for FFI
struct Header {
    version: u16,
    flags: u16,
    length: u32,
    checksum: u64,
    reserved: [u8; 16],
}

const _: () = assert!(std::mem::size_of::<Header>() == 32);
```

### Testing Size Stability

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn critical_types_have_expected_sizes() {
        // Document expected sizes in tests too
        assert_eq!(std::mem::size_of::<Event>(), 48);
        assert_eq!(std::mem::size_of::<Message>(), 64);
        assert_eq!(std::mem::size_of::<Header>(), 32);
    }
    
    #[test]
    fn cache_line_aligned() {
        // Verify cache-friendly sizing
        assert!(std::mem::size_of::<HotData>() <= 64);
    }
}
```

### When to Assert

```rust
// ✅ Types stored in large collections
struct Node { /* ... */ }
const _: () = assert!(std::mem::size_of::<Node>() <= 64);

// ✅ Types used in FFI / binary protocols
#[repr(C)]
struct WireFormat { /* ... */ }
const _: () = assert!(std::mem::size_of::<WireFormat>() == 256);

// ✅ Performance-critical types
struct HotPath { /* ... */ }
const _: () = assert!(std::mem::size_of::<HotPath>() <= 128);

// ❌ Skip for rarely-instantiated types
struct AppConfig { /* many fields */ }
// Size doesn't matter, only one instance
```

### Cargo.toml

```toml
[dependencies]
static_assertions = "1.1"
```

Related: `mem-smaller-integers`, `mem-box-large-variant`, `opt-cache-friendly`

## mem-take-replace

> Use `mem::take` / `mem::replace` to move a value out of a `&mut` without cloning

### Why It Matters

Rust's ownership rules prevent you from moving a field out of a `&mut self` reference — the compiler must guarantee the field is not left in an invalid state. The standard workaround many developers reach for is `.clone()`, but that allocates unnecessarily. `std::mem::take` swaps the field with `T::default()` and returns the original value; `std::mem::replace` swaps in an explicit value of your choosing. Both are zero-copy and work wherever you have `&mut T`.

### Bad

```rust
struct Processor {
    items: Vec<String>,
}

impl Processor {
    // clones the entire Vec just to drain it — unnecessary allocation
    fn flush(&mut self) -> Vec<String> {
        let v = self.items.clone();
        self.items.clear();
        v
    }
}
```

### Good

```rust
use std::mem;

struct Processor {
    items: Vec<String>,
}

impl Processor {
    // moves the Vec out in one step, leaving an empty Vec behind
    fn flush(&mut self) -> Vec<String> {
        mem::take(&mut self.items)
    }
}
```

`mem::take` is equivalent to `mem::replace(&mut self.items, Vec::new())` but shorter when the replacement value is `Default::default()`.

### State-Machine Transition with `mem::replace`

A common pattern in state machines and `Future::poll` implementations is replacing a field with an explicit next state rather than the default:

```rust
use std::mem;

#[derive(Debug)]
enum State {
    Idle,
    Loading { url: String },
    Done { body: String },
}

impl Default for State {
    fn default() -> Self {
        State::Idle
    }
}

struct Machine {
    state: State,
}

impl Machine {
    fn start_load(&mut self, url: String) {
        // replace Idle with Loading, getting Idle back (discarded here)
        let _prev = mem::replace(&mut self.state, State::Loading { url });
    }

    fn complete(&mut self, body: String) {
        // replace Loading with Done; capture old state if needed for logging
        match mem::replace(&mut self.state, State::Done { body }) {
            State::Loading { url } => {
                println!("finished loading {url}");
            }
            other => {
                // unexpected transition — put it back or handle the error
                self.state = other;
            }
        }
    }
}
```

### Consuming a Field in `Drop`

`mem::take` is also the idiomatic way to move out of a field inside `Drop`, where you only have `&mut self`:

```rust
use std::mem;

struct FileWriter {
    buffer: Vec<u8>,
    // imagine a real file handle here
}

impl Drop for FileWriter {
    fn drop(&mut self) {
        let data = mem::take(&mut self.buffer);
        // flush `data` to disk without an extra allocation
        let _ = data; // pretend this writes somewhere
    }
}
```

### Key Points

- `mem::take` requires `T: Default`. If `T` has no meaningful default, use `mem::replace` with an explicit sentinel value (e.g., an `Option<T>` field — `mem::take` an `Option<T>` yields `None`, which is often exactly right).
- Both functions are `#[inline]` and compile away to a few register moves with no heap involvement.
- `Option<T>` is a natural pairing: keep expensive values in `Option<T>` and call `self.field.take()` (the `Option::take` method, same idea) to move ownership out cleanly.

Related: `own-move-large`, `mem-clone-from`, `own-borrow-over-clone`

## mem-drop-order

> Know and control drop order: struct fields drop top-to-bottom, locals in reverse

### Why It Matters

Drop order is observable. RAII guards (mutex locks, file handles, database transactions, span guards) do meaningful work in their `Drop` implementations, and dropping them in the wrong order silently causes bugs: releasing a lock while a transaction that depends on it is still alive, closing a connection before its transaction has committed, or dropping a tracing span before the work it covers has finished. The rules are fixed and deterministic, but easy to overlook when fields and locals accumulate over time.

### The Rules

| Construct | Drop order |
|---|---|
| Struct fields | Declaration order: first field declared, first dropped |
| Tuple / array elements | In order: index 0, 1, 2, … |
| Local variables | Reverse declaration order: last declared, first dropped |
| Temporaries in a statement | End of the statement (with some exceptions) |
| Function arguments | Reverse order of the parameter list |

### Bad

```rust
use std::sync::{Mutex, MutexGuard};

struct DatabaseSession {
    // BUG: `guard` is declared first, so it drops FIRST.
    // But `guard` protects the connection — dropping the lock
    // before the transaction is committed lets another thread
    // see the connection in a partial state.
    guard: MutexGuard<'static, ()>,
    transaction: Transaction,
}

struct Transaction; // pretend this commits on drop

impl Drop for Transaction {
    fn drop(&mut self) {
        println!("transaction committed");
    }
}
```

In this struct, `guard` drops before `transaction`, releasing the mutex while the transaction is still in-flight.

### Good

```rust
use std::sync::{Mutex, MutexGuard};

struct Transaction; // commits on drop

impl Drop for Transaction {
    fn drop(&mut self) {
        println!("transaction committed");
    }
}

struct DatabaseSession {
    // CORRECT: `transaction` is declared first, so it drops first
    // (commit happens), THEN `guard` drops (lock released).
    transaction: Transaction,
    guard: MutexGuard<'static, ()>,
}
```

Fields drop in declaration order, so the field at the top of the struct drops first.

### Controlling Drop Order for Locals

Local variables drop in **reverse** declaration order, which is often what you want (last-in, first-out). When the natural order is wrong, use explicit `drop`:

```rust
fn process() {
    let conn = open_connection();   // dropped third (last to drop)
    let txn  = begin_transaction(); // dropped second
    let guard = acquire_lock();     // dropped first — WRONG if txn needs the lock

    // fix: drop guard explicitly before txn and conn drop naturally
    do_work(&txn);
    drop(guard); // lock released here
    txn.commit(); // runs before conn closes
} // conn drops here
# fn open_connection() -> () {}
# fn begin_transaction() -> () {}
# fn acquire_lock() -> () {}
# fn do_work(_: &()) {}
# trait Commit { fn commit(self); }
# impl Commit for () { fn commit(self) {} }
```

### `ManuallyDrop` for Full Control

When you need to opt completely out of automatic drop (e.g., in `unsafe` code, or to move a value out of a struct in `Drop`), use `std::mem::ManuallyDrop`:

```rust
use std::mem::ManuallyDrop;

struct ResourcePair {
    // child must be cleaned up before parent
    child: ManuallyDrop<Child>,
    parent: Parent,
}

impl Drop for ResourcePair {
    fn drop(&mut self) {
        // SAFETY: `child` is not accessed after this point
        unsafe { ManuallyDrop::drop(&mut self.child) };
        // `parent` drops automatically after this block
    }
}

struct Child;
struct Parent;
```

`ManuallyDrop<T>` inhibits the compiler from inserting automatic drop calls, giving you precise control.

### Key Points

- Reorder struct fields to encode the correct drop sequence — the declaration is the contract.
- Add a comment explaining the ordering when it is non-obvious: `// NOTE: drop order matters — transaction before connection`.
- Prefer explicit `drop(x)` calls in functions over relying on scope-exit order when the correct sequence is not immediately clear from the code.
- `std::mem::forget` drops nothing at all (leaks); only use it for FFI hand-off or when transferring ownership to unmanaged code.

Related: `test-fixture-raii`, `own-mutex-interior`, `mem-take-replace`
