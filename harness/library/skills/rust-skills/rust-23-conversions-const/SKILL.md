---
name: rust-23-conversions-const
description: Rust rules module 23: Conversions + Const & Compile-Time. 7 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `conv-`, `const-`
---

# Conversions + Const & Compile-Time

Priority: MEDIUM. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `conv-tryfrom-fallible` - Implement `TryFrom` for fallible conversions instead of ad-hoc conversion functions
- `conv-fromstr-parsing` - Implement `FromStr` to enable `str::parse` for string-to-type conversions
- `conv-asmut-mutable` - Accept `impl AsMut<T>` for flexible mutable borrowed inputs instead of concrete mutable references
- `const-block` - Use inline `const { }` blocks for compile-time evaluation and assertions
- `const-fn` - Make functions `const fn` when they can run at compile time
- `const-generics` - Parameterize over values with const generics `<const N: usize>`
- `const-vs-static` - Use `const` for an inlined value and `static` for a single addressed instance

---

## conv-tryfrom-fallible

> Implement `TryFrom` for fallible conversions instead of ad-hoc conversion functions

### Why It Matters

`TryFrom`/`TryInto` is the standard trait pair for conversions that can fail. Implementing `TryFrom<T>` automatically provides `TryInto` for callers (API Guidelines C-CONV-TRAITS), enabling ergonomic `.try_into()?` at call sites. It integrates naturally with the `?` operator, ecosystem crates, and generic bounds that constrain `T: TryFrom<U>`. Ad-hoc conversion functions scatter the conversion surface and deprive callers of these benefits.

### Bad

```rust
use std::io;

struct Port(u16);

// Bespoke function — callers must know its name, can't use `.try_into()`
fn port_from_u32(n: u32) -> Result<Port, String> {
    if n > u16::MAX as u32 {
        return Err(format!("port {} out of range", n));
    }
    Ok(Port(n as u16))
}

fn main() {
    let p = port_from_u32(8080).unwrap();
}
```

### Good

```rust
use std::fmt;

#[derive(Debug)]
struct Port(u16);

#[derive(Debug)]
struct PortError(u32);

impl fmt::Display for PortError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "port {} is out of range (0–65535)", self.0)
    }
}

impl std::error::Error for PortError {}

impl TryFrom<u32> for Port {
    type Error = PortError;

    fn try_from(value: u32) -> Result<Self, Self::Error> {
        u16::try_from(value)
            .map(Port)
            .map_err(|_| PortError(value))
    }
}

fn accept_port(n: u32) -> Result<Port, PortError> {
    // Callers use the standard `.try_into()?` idiom
    n.try_into()
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let p: Port = 8080_u32.try_into()?;
    println!("port: {}", p.0);
    Ok(())
}
```

### Notes

- Implement `TryFrom`, not `TryInto`; the blanket impl provides `TryInto` automatically (mirrors the `From`/`Into` relationship).
- Use a concrete error type, not `String` or `Box<dyn Error>`, so callers can match on it.
- When the conversion is truly infallible, implement `From` instead.

Related: `api-from-not-into`, `conv-fromstr-parsing`, `api-parse-dont-validate`

## conv-fromstr-parsing

> Implement `FromStr` to enable `str::parse` for string-to-type conversions

### Why It Matters

`FromStr` is the single standard hook for parsing a `&str` into a typed value. Implementing it unlocks the idiomatic `.parse::<T>()` call, integrates with CLI argument parsers (clap, argh), and is the expected interface for serde string-deserializable types. A bespoke `fn parse_foo(s: &str)` forces callers to learn a private name and breaks generic code that constrains `T: FromStr`.

### Bad

```rust
#[derive(Debug)]
enum Color { Red, Green, Blue }

// Callers must know this private name; no `.parse()` support
fn parse_color(s: &str) -> Result<Color, String> {
    match s {
        "red"   => Ok(Color::Red),
        "green" => Ok(Color::Green),
        "blue"  => Ok(Color::Blue),
        other   => Err(format!("unknown color: {other}")),
    }
}

fn main() {
    let c = parse_color("red").unwrap();
}
```

### Good

```rust
use std::str::FromStr;
use std::fmt;

#[derive(Debug, PartialEq)]
enum Color { Red, Green, Blue }

#[derive(Debug)]
struct ParseColorError(String);

impl fmt::Display for ParseColorError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "unknown color: {}", self.0)
    }
}

impl std::error::Error for ParseColorError {}

impl FromStr for Color {
    type Err = ParseColorError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "red"   => Ok(Color::Red),
            "green" => Ok(Color::Green),
            "blue"  => Ok(Color::Blue),
            other   => Err(ParseColorError(other.to_owned())),
        }
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Standard idiom — works with clap, config parsers, etc.
    let c: Color = "green".parse()?;
    assert_eq!(c, Color::Green);
    Ok(())
}
```

### Notes

- Use a concrete `Err` type, not `String`, so callers can pattern-match on parse failures.
- `FromStr` pairs naturally with `Display`: if you can parse it in, you should be able to print it out.
- For infallible string conversions (e.g., wrapping a `String` in a newtype), consider `From<&str>` or `From<String>` instead.
- CLI crates like `clap` detect `FromStr` automatically via the `value_parser` attribute macro.

Related: `conv-tryfrom-fallible`, `type-newtype-validated`, `api-parse-dont-validate`

## conv-asmut-mutable

> Accept `impl AsMut<T>` for flexible mutable borrowed inputs instead of concrete mutable references

### Why It Matters

`AsMut<T>` is the mutable mirror of `AsRef<T>`. Accepting `impl AsMut<[u8]>` instead of `&mut Vec<u8>` lets callers pass `&mut Vec<u8>`, `&mut [u8]`, or `&mut [u8; N]` arrays without any conversion overhead. This widens the function's usefulness without changing its implementation or runtime cost. Reserve it for genuinely generic write targets — not every `&mut T` parameter needs this treatment.

### Bad

```rust
// Only accepts &mut Vec<u8>; arrays and slices are excluded
fn fill_zeros(buf: &mut Vec<u8>) {
    for b in buf.iter_mut() {
        *b = 0;
    }
}

fn main() {
    let mut data = vec![1u8, 2, 3];
    fill_zeros(&mut data);

    // Compile error — cannot pass &mut [u8; 3] or &mut [u8]
    // let mut arr = [1u8, 2, 3];
    // fill_zeros(&mut arr);
}
```

### Good

```rust
// Accepts Vec<u8>, [u8; N], &mut [u8] — any type that lends &mut [u8]
fn fill_zeros(mut buf: impl AsMut<[u8]>) {
    for b in buf.as_mut().iter_mut() {
        *b = 0;
    }
}

fn verify(mut buf: impl AsMut<[u8]>) -> bool {
    buf.as_mut().iter().all(|&b| b == 0)
}

fn main() {
    let mut vec_buf = vec![1u8, 2, 3];
    fill_zeros(&mut vec_buf);
    assert!(verify(&mut vec_buf));

    let mut arr_buf = [1u8, 2, 3, 4];
    fill_zeros(&mut arr_buf);
    assert!(verify(&mut arr_buf));

    let mut slice_buf = [5u8, 6, 7];
    fill_zeros(slice_buf.as_mut());
    assert!(verify(slice_buf.as_mut()));
}
```

### When Not to Use

- If the function only ever receives `&mut SomeConcreteType`, keep the concrete type — generics add compile time and cognitive overhead for no gain.
- Avoid combining `AsMut` with `AsRef` on the same parameter unless the API genuinely needs both read and write access.
- Don't use `AsMut` as a substitute for a trait that captures domain semantics; name the abstraction properly.

Related: `api-impl-asref`, `own-slice-over-vec`

## const-block

> Use inline `const { }` blocks for compile-time evaluation and assertions

### Why It Matters

A `const { }` block (stabilized in Rust 1.79) forces the enclosed expression to be evaluated at compile time, even inside a regular function. This has three practical uses: compile-time assertions that fail the build rather than panicking at runtime; precomputed values inlined at the exact call site without a named `const` item; and initializing arrays of non-`Copy` types that require a per-element constant expression. Catching invariant violations at compile time gives a clearer error message and zero runtime cost.

### Bad

```rust
const SIZE: usize = 64;

fn process(buf: &[u8]) {
    // runtime panic — error surface is deferred until execution
    assert!(SIZE.is_power_of_two(), "SIZE must be a power of two");
    assert!(buf.len() <= SIZE);
}

// repeated magic number — easy to get out of sync
fn header() -> [u8; 4] {
    [0u8; 4]
}

// initializing array of non-Copy type requires unsafe or a workaround without const blocks
// std::array::from_fn is fine, but const blocks make the intent clearer for const values
```

### Good

```rust
const SIZE: usize = 64;

fn process(buf: &[u8]) {
    // compile-time assertion — build fails immediately if SIZE changes to a bad value
    const { assert!(SIZE.is_power_of_two(), "SIZE must be a power of two") };

    // runtime assertion for dynamic data still makes sense here
    assert!(buf.len() <= SIZE);
}

// inline const block used as a value — evaluated once, inlined at each use
fn magic_header() -> u32 {
    const { 0xDEAD_BEEFu32.swap_bytes() }
}

// compile-time bounds check on a type-level relationship
struct Packet<const HDR: usize, const BODY: usize>;

impl<const HDR: usize, const BODY: usize> Packet<HDR, BODY> {
    fn new() -> Self {
        // fails at compile time if the relationship is violated, not at runtime
        const { assert!(HDR + BODY <= 1500, "packet exceeds ethernet MTU") };
        Packet
    }
}

// array of non-Copy type using a const block per element
// (each element is its own const expression — legal since 1.79)
fn make_table() -> [u64; 4] {
    [
        const { u64::MAX / 1 },
        const { u64::MAX / 2 },
        const { u64::MAX / 3 },
        const { u64::MAX / 4 },
    ]
}
```

### Notes

`const { expr }` is an expression, so it can appear anywhere an expression is valid: in function bodies, match arms, array initializers, and as default values. It is distinct from a named `const ITEM: T = expr;` declaration — a `const` block is anonymous and scoped to its enclosing expression. For long-lived or widely shared values, prefer a named `const`; reach for `const { }` when you want a one-off compile-time guarantee or value inline.

Related: `const-fn`, `mem-assert-type-size`

## const-fn

> Make functions `const fn` when they can run at compile time

### Why It Matters

A `const fn` can be called in const contexts — array lengths, `const`/`static` initializers, const-generic arguments — as well as at runtime, so marking a pure, simple function `const` widens where it can be used at zero cost. The compiler evaluates calls in const contexts during compilation, eliminating the work entirely from the binary. Current stable Rust supports most arithmetic, bitwise ops, conditionals, and slice operations in `const fn`; the main restrictions are heap allocation and most trait method calls.

### Bad

```rust
// not const — cannot use result as an array length or const initializer
fn header_len() -> usize {
    4
}

fn magic_mask() -> u32 {
    0xFF00_FF00
}

fn make_buf() -> [u8; 8] {
    // runtime call — compiler cannot inline the length into the type
    [0u8; header_len()]  // error: `header_len` is not a `const fn`
}
```

### Good

```rust
const fn header_len() -> usize {
    4
}

const fn magic_mask() -> u32 {
    0xFF00_FF00
}

// usable as an array length — evaluated at compile time
let buf = [0u8; header_len()];

// usable in a const initializer
const MASK: u32 = magic_mask();

// usable in a static
static HEADER: [u8; header_len()] = [0u8; header_len()];

// const fn with logic — still fine on stable
const fn align_up(n: usize, align: usize) -> usize {
    (n + align - 1) & !(align - 1)
}

const ALIGNED: usize = align_up(13, 8); // 16, computed at compile time
```

### Notes

Adding `const` to a function is a backwards-compatible, non-breaking change for library authors. Start with `const fn` for any pure function without heap allocation or dynamic dispatch; you can always remove it if you later need a capability that is not yet `const`-stable. Avoid `const fn` for functions that call unstable `const` features not yet stabilized on the channel you target.

Related: `const-block`, `const-generics`, `opt-inline-small`

## const-generics

> Parameterize over values with const generics `<const N: usize>`

### Why It Matters

Const generics let a single type or function work for any array size — or other constant value — without macros, trait objects, or carrying a runtime length field. The compiler monomorphizes one copy per distinct value, so there is no indirection and no overhead compared to hand-writing the same code for each size. This is the idiomatic way to write generic array-based data structures and algorithms on stable Rust.

### Bad

```rust
// works only for one fixed size — must be copy-pasted per size
fn sum_4(arr: [i32; 4]) -> i32 {
    arr.iter().sum()
}

fn sum_8(arr: [i32; 8]) -> i32 {
    arr.iter().sum()
}

// carries runtime length — extra field, heap allocation, no compile-time bounds
struct Buffer {
    data: Vec<u8>,
    capacity: usize,
}
```

### Good

```rust
// one generic function works for any array size; N is inferred from the argument
fn sum<const N: usize>(arr: [i32; N]) -> i32 {
    arr.iter().sum()
}

let total = sum([1, 2, 3, 4]);       // N = 4, inferred
let total8 = sum([0i32; 8]);         // N = 8, inferred

// stack-allocated buffer parameterized by capacity — no heap, no runtime length
struct Buffer<const N: usize> {
    data: [u8; N],
    len: usize,
}

impl<const N: usize> Buffer<N> {
    const fn new() -> Self {
        Self { data: [0u8; N], len: 0 }
    }

    fn push(&mut self, byte: u8) -> bool {
        if self.len < N {
            self.data[self.len] = byte;
            self.len += 1;
            true
        } else {
            false
        }
    }

    fn as_slice(&self) -> &[u8] {
        &self.data[..self.len]
    }
}

// capacity is part of the type — mismatches caught at compile time
let mut small: Buffer<8> = Buffer::new();
let mut large: Buffer<1024> = Buffer::new();
small.push(42);
large.push(99);

// const generic used as an array length computed from another const
const BLOCK: usize = 16;
fn xor_block<const N: usize>(a: [u8; N], b: [u8; N]) -> [u8; N] {
    let mut out = [0u8; N];
    for i in 0..N {
        out[i] = a[i] ^ b[i];
    }
    out
}
let result = xor_block([0u8; BLOCK], [0xFF; BLOCK]);
```

### Notes

Rust 1.65+ stabilized const generic defaults (`struct Buf<const N: usize = 64>`), letting you provide a sensible default while still allowing callers to override it. Const generics currently support integer, bool, and char types; floating-point and custom types are not yet stable. Where N can be inferred from a function argument, you rarely need to write it explicitly.

Related: `const-fn`, `mem-assert-type-size`

## const-vs-static

> Use `const` for an inlined value and `static` for a single addressed instance

### Why It Matters

`const` items are substituted at each use site: the compiler copies the value inline, there is no fixed memory address, and the value counts against no storage. This is ideal for small configuration values, bitmasks, and magic numbers. `static` items live at a single address for the entire program lifetime and expose a `'static` reference — use them for large lookup tables you do not want duplicated, or when a `&'static T` is required. Avoid `static mut`: referencing it is a hard error in the 2024 edition. For mutable global state, use atomics (`AtomicUsize`, etc.) or `std::sync::OnceLock`/`std::sync::LazyLock`.

### Bad

```rust
// large table as `const` — potentially duplicated at every use site
const LOOKUP: [u8; 256] = [0u8; 256];

// `static mut` — unsafe to read and a hard error in edition 2024
static mut COUNTER: u64 = 0;

// `static` for a tiny value — needlessly takes an address
static TIMEOUT_MS: u64 = 5000;
```

### Good

```rust
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{LazyLock, OnceLock};

// small value: `const` — inlined at each use, no address needed
const MAX_RETRIES: u32 = 3;
const TIMEOUT_MS: u64 = 5_000;
const FLAG_MASK: u8 = 0b0000_1111;

// large data: `static` — one copy in the binary, shareable as `&'static`
static LOOKUP: [u8; 256] = [0u8; 256];

fn process(byte: u8) -> u8 {
    LOOKUP[byte as usize]
}

// `&'static str` requires a `static` (or a string literal)
static APP_NAME: &str = "my-app";

// mutable global state — use atomics, not `static mut`
static REQUEST_COUNT: AtomicU64 = AtomicU64::new(0);

fn record_request() {
    REQUEST_COUNT.fetch_add(1, Ordering::Relaxed);
}

// lazily initialized global — `LazyLock` (stable since 1.80)
static CONFIG_PATH: LazyLock<String> = LazyLock::new(|| {
    std::env::var("CONFIG_PATH").unwrap_or_else(|_| "/etc/app/config.toml".to_owned())
});

// single-assignment global — `OnceLock`
static GREETING: OnceLock<String> = OnceLock::new();

fn set_greeting(name: &str) {
    let _ = GREETING.set(format!("hello, {name}"));
}
```

### When to Prefer Which

| Situation | Use |
|-----------|-----|
| Small constant (number, bool, tiny array) | `const` |
| String literal | `const` or `static` (both work; prefer `const`) |
| Large lookup table | `static` |
| Need `&'static T` | `static` |
| Mutable counter / flag | `static AtomicXxx` |
| Lazily initialized value | `static LazyLock<T>` |
| Single-writer initialization | `static OnceLock<T>` |

Related: `name-consts-screaming`, `own-mutex-interior`
