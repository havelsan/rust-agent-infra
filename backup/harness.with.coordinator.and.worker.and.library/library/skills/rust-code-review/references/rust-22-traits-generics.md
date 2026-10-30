---
name: rust-22-traits-generics
description: Rust rules module 22: Trait & Generics Design. 6 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `trait-`
---

# Trait & Generics Design

Priority: MEDIUM. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `trait-associated-type-vs-generic` - Use an associated type when each impl has exactly one output type; use a generic parameter when a type can implement the trait for many input types
- `trait-blanket-impl` - Use a blanket impl `impl<T: Bound> Trait for T` to give behaviour to every type that satisfies a bound
- `trait-coherence-newtype` - Respect the orphan rule; wrap a foreign type in a newtype to implement a foreign trait on it
- `trait-default-methods` - Define a trait in terms of a few required methods plus defaulted ones built on top of them
- `trait-dyn-vs-generic` - Choose static dispatch (generics / `impl Trait`) vs dynamic dispatch (`dyn Trait`) deliberately
- `trait-object-safety` - Keep a trait dyn-compatible (object-safe) when you need `dyn Trait`

---

## trait-associated-type-vs-generic

> Use an associated type when each impl has exactly one output type; use a generic parameter when a type can implement the trait for many input types

### Why It Matters

The choice between `type Output;` and `<Rhs>` has two concrete consequences. First, an associated type is **part of the implementing type's identity**: callers never name it with turbofish because there is only one valid binding per impl. Second, a generic parameter allows **multiple simultaneous impls** on the same type — `impl Add<f64> for Vec2` and `impl Add<Vec2> for Vec2` can coexist, while `impl Iterator` can only define one `Item`. Using an associated type when multiple impls are needed makes those impls impossible; using a generic parameter when there is only one output forces every call site to write noisy turbofish or type annotations.

The Rust API Guidelines (rust-lang.github.io/api-guidelines/future-proofing.html) capture the rule: prefer associated types when there is a single natural output per implementor.

### Bad

```rust
// Using a generic parameter for a trait that has exactly one output per type.
// Callers must now write Parser<String, Output = Ast> or face ambiguity.
trait Parser<Output> {
    fn parse(&self, input: &str) -> Option<Output>;
}

struct JsonParser;

// Only one sensible Output ever exists for JsonParser, but the signature
// forces a type parameter that adds noise everywhere.
impl Parser<String> for JsonParser {
    fn parse(&self, input: &str) -> Option<String> {
        Some(input.to_owned())
    }
}

fn run<P: Parser<String>>(p: &P, s: &str) -> Option<String> {
    p.parse(s)
}
```

### Good

```rust
// ----- Associated type: one output per implementor -----
// Mirrors std::iter::Iterator { type Item; }

trait Parser {
    type Output;
    fn parse(&self, input: &str) -> Option<Self::Output>;
}

struct JsonParser;
struct NumberParser;

#[derive(Debug)]
struct JsonValue(String);

impl Parser for JsonParser {
    type Output = JsonValue;
    fn parse(&self, input: &str) -> Option<JsonValue> {
        Some(JsonValue(input.to_owned()))
    }
}

impl Parser for NumberParser {
    type Output = f64;
    fn parse(&self, input: &str) -> Option<f64> {
        input.trim().parse().ok()
    }
}

// No turbofish needed — `P::Output` is unambiguous.
fn run<P: Parser>(p: &P, s: &str) -> Option<P::Output> {
    p.parse(s)
}

// ----- Generic parameter: multiple impls on the same type -----
// Mirrors std::ops::Add<Rhs> and std::convert::From<T>.

#[derive(Debug, Clone, Copy)]
struct Vec2 { x: f64, y: f64 }

// One type implementing the same "add" concept for two different Rhs types.
impl std::ops::Add<Vec2> for Vec2 {
    type Output = Vec2;
    fn add(self, rhs: Vec2) -> Vec2 { Vec2 { x: self.x + rhs.x, y: self.y + rhs.y } }
}

impl std::ops::Add<f64> for Vec2 {
    type Output = Vec2;
    fn add(self, rhs: f64) -> Vec2 { Vec2 { x: self.x + rhs, y: self.y + rhs } }
}

fn demo() {
    let a = Vec2 { x: 1.0, y: 2.0 };
    let b = Vec2 { x: 3.0, y: 4.0 };
    let _ = a + b;       // Add<Vec2>
    let _ = a + 10.0;    // Add<f64>

    let p = NumberParser;
    if let Some(n) = run(&p, " 3.14 ") {
        println!("{n}");
    }
}
```

### Key Points

- `std::iter::Iterator`, `std::future::Future`, and `std::ops::Deref` all use associated types because there is exactly one `Item`/`Output`/`Target` per implementor.
- `std::ops::Add<Rhs>`, `std::convert::From<T>`, and `std::convert::Into<T>` use generic parameters because a single type can add to, or convert from, many others.
- When you need to constrain the associated type in a bound, write `P: Parser<Output = JsonValue>` — less noisy than a free generic parameter.

Related: `type-generic-bounds`, `trait-default-methods`, `api-impl-fromiterator`

## trait-blanket-impl

> Use a blanket impl `impl<T: Bound> Trait for T` to give behaviour to every type that satisfies a bound

### Why It Matters

A blanket impl extends an entire class of types at once without touching each one individually. The standard library uses this pervasively: `ToString` is blanket-implemented for every `T: Display`, so any type that implements `Display` automatically gets `.to_string()`. This avoids repetitive boilerplate and keeps extension traits composable. The trade-off is coherence: Rust's orphan rules allow at most one applicable impl per type, so a blanket impl can conflict with a more specific one if not designed carefully. Adding a blanket impl is also a **semver-breaking change** if it could overlap with impls that downstream crates provide.

### Bad

```rust
use std::fmt;

trait Describe {
    fn describe(&self) -> String;
}

// Manual impl for each type — tedious and doesn't scale.
impl Describe for i32 {
    fn describe(&self) -> String { format!("i32: {self}") }
}
impl Describe for f64 {
    fn describe(&self) -> String { format!("f64: {self}") }
}
impl Describe for bool {
    fn describe(&self) -> String { format!("bool: {self}") }
}
// ... repeated for every type that happens to implement Display
```

### Good

```rust
use std::fmt;

// Extension trait that any `Display` type receives automatically.
trait Describe {
    fn describe(&self) -> String;
}

// One blanket impl covers every T: Display — mirrors how std blanket-impls ToString.
impl<T: fmt::Display> Describe for T {
    fn describe(&self) -> String {
        format!("{} ({})", self, std::any::type_name::<T>())
    }
}

// ----- Downstream usage: zero extra code required -----

fn print_described(value: &impl Describe) {
    println!("{}", value.describe());
}

fn demo() {
    print_described(&42_i32);
    print_described(&3.14_f64);
    print_described(&true);
    print_described(&"hello");
}

// ----- You CANNOT also override it for one type -----
// Writing `impl Describe for MyType` while the blanket impl exists is a
// coherence conflict (E0119): stable Rust has no specialization, so a blanket
// impl and a specific impl can never overlap. If you need a per-type override,
// don't use a blanket impl — or wrap the type in a newtype (see See Also).
```

### Key Points

- The standard library blanket-impls `ToString` for all `T: Display`, `From<T> for T` (reflexive), and `impl<T: Error> From<T> for Box<dyn Error>`.
- Blanket impls live in the crate that owns the **trait** (not the type), satisfying the orphan rule.
- A blanket impl prevents any specific impl for a type it already covers — that overlap is a coherence error (E0119), because specialization is not stable. Use a newtype when you need a per-type override.
- Treat adding a public blanket impl as a **minor semver bump at minimum** (or major if it could break downstream).
- Pair blanket impls with sealed traits (`api-sealed-trait`) when you want the blanket behaviour but need to prevent external implementations.

Related: `api-extension-trait`, `api-sealed-trait`, `trait-coherence-newtype`

## trait-coherence-newtype

> Respect the orphan rule; wrap a foreign type in a newtype to implement a foreign trait on it

### Why It Matters

Rust's coherence rules — enforced by the orphan rule — require that for any `impl Trait for Type`, either `Trait` or `Type` must be defined in the current crate. This prevents two crates from providing conflicting implementations for the same (trait, type) pair, which would make the compiler unable to pick one. When you need to implement a trait you didn't define (e.g., `std::fmt::Display`) on a type you didn't define (e.g., `Vec<i32>`), the compiler rejects the impl outright. The solution is to wrap the foreign type in a local newtype struct, then implement the foreign trait on the wrapper. Marking the wrapper `#[repr(transparent)]` keeps it zero-cost and allows safe pointer casts where needed.

### Bad

```rust
use std::fmt;

// error[E0117]: only traits defined in the current crate can be implemented for
// types defined outside of the crate
// impl fmt::Display for Vec<i32> { ... }  // both `Display` and `Vec` are foreign
```

### Good

```rust
use std::fmt;

// A local newtype wrapping the foreign type.
// `#[repr(transparent)]` guarantees the same memory layout as Vec<i32>.
#[repr(transparent)]
struct CommaSeparated(Vec<i32>);

impl CommaSeparated {
    pub fn new(v: Vec<i32>) -> Self { Self(v) }

    // Provide access to the inner value.
    pub fn into_inner(self) -> Vec<i32> { self.0 }
    pub fn inner(&self) -> &Vec<i32> { &self.0 }
}

// Now both the trait (Display) is foreign and the type (CommaSeparated) is local —
// the orphan rule is satisfied because CommaSeparated is defined here.
impl fmt::Display for CommaSeparated {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let mut iter = self.0.iter().peekable();
        while let Some(n) = iter.next() {
            write!(f, "{n}")?;
            if iter.peek().is_some() {
                write!(f, ", ")?;
            }
        }
        Ok(())
    }
}

// Implement From/Into so conversion is ergonomic.
impl From<Vec<i32>> for CommaSeparated {
    fn from(v: Vec<i32>) -> Self { Self(v) }
}

impl From<CommaSeparated> for Vec<i32> {
    fn from(w: CommaSeparated) -> Self { w.0 }
}

fn demo() {
    let nums = CommaSeparated::new(vec![1, 2, 3, 4, 5]);
    println!("{nums}");   // "1, 2, 3, 4, 5"

    // Round-trip through the inner type.
    let v: Vec<i32> = nums.into();
    let again = CommaSeparated::from(v);
    println!("{again}");
}
```

### Key Points

- The orphan rule: `impl<T> ForeignTrait for ForeignType<T>` is always rejected, even with a type parameter.
- `#[repr(transparent)]` is mandatory for newtypes that need the same ABI as the inner type (e.g., FFI, pointer casts via `transmute`). For purely logical wrapping, it is optional but good practice.
- Provide `From`/`Into` conversions and an `inner()` / `into_inner()` accessor so callers can move in and out of the wrapper easily.
- The newtype pattern is described in the Rust API Guidelines under "Newtypes provide static distinctions" (rust-lang.github.io/api-guidelines/).
- Newtype wrappers are also the correct way to add trait impls to types from transitive dependencies that you do not control.

Related: `api-newtype-safety`, `type-repr-transparent`, `trait-blanket-impl`, `api-from-not-into`

## trait-default-methods

> Define a trait in terms of a few required methods plus defaulted ones built on top of them

### Why It Matters

A trait with only required methods places the full implementation burden on every consumer. Providing default method bodies — as `std::iter::Iterator` does, building `map`, `filter`, `fold`, and dozens more on a single required `next` — means implementors write only the essential logic and receive the rest for free. Defaults also act as documentation: they show the canonical relationship between methods. Implementors can still override a default for performance (e.g., `Iterator::count` overridden by `std::vec::IntoIter` to avoid iterating) without changing the observable contract.

### Bad

```rust
// Every implementor must manually implement all three methods,
// even though two of them are mechanical compositions of the first.
trait Summarise {
    fn sentences(&self) -> Vec<String>;
    fn first_sentence(&self) -> Option<String>;  // always just sentences().into_iter().next()
    fn word_count(&self) -> usize;               // always sentences().join(" ").split_whitespace().count()
}

struct Article { body: String }

impl Summarise for Article {
    fn sentences(&self) -> Vec<String> {
        self.body.split('.').map(str::trim).map(str::to_owned).collect()
    }
    // Duplicated logic — must be kept in sync across every implementor.
    fn first_sentence(&self) -> Option<String> {
        self.sentences().into_iter().next()
    }
    fn word_count(&self) -> usize {
        self.sentences().join(" ").split_whitespace().count()
    }
}
```

### Good

```rust
trait Summarise {
    // ----- Required: the only thing implementors must provide -----
    fn sentences(&self) -> Vec<String>;

    // ----- Defaulted: free for all implementors -----
    fn first_sentence(&self) -> Option<String> {
        self.sentences().into_iter().next()
    }

    fn word_count(&self) -> usize {
        self.sentences().join(" ").split_whitespace().count()
    }

    fn is_empty(&self) -> bool {
        self.sentences().is_empty()
    }
}

// Minimal impl — one method, three come for free.
struct Article { body: String }

impl Summarise for Article {
    fn sentences(&self) -> Vec<String> {
        self.body
            .split('.')
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(str::to_owned)
            .collect()
    }
}

// Override a default for performance when the default is provably slower.
struct PreSplit { parts: Vec<String> }

impl Summarise for PreSplit {
    fn sentences(&self) -> Vec<String> {
        self.parts.clone()
    }

    // Override: the parts are already split — no need to join and re-split.
    fn word_count(&self) -> usize {
        self.parts.iter().flat_map(|s| s.split_whitespace()).count()
    }
}

fn print_summary(item: &impl Summarise) {
    if item.is_empty() {
        println!("(empty)");
        return;
    }
    if let Some(first) = item.first_sentence() {
        println!("first: {first}");
    }
    println!("words: {}", item.word_count());
}

fn demo() {
    let a = Article { body: "Rust is fast. Rust is safe. Rust is fun.".to_owned() };
    print_summary(&a);

    let p = PreSplit { parts: vec!["hello world".to_owned(), "foo bar baz".to_owned()] };
    print_summary(&p);
}
```

### Key Points

- Keep required methods to the **minimum orthogonal set**: ideally one or two.
- Default implementations must only call other methods on `Self`, not external state.
- An override changes performance but must preserve the same observable semantics.
- Document which methods are required vs defaulted in the trait's module-level doc comment.
- The pattern is explicitly encouraged by the Rust API Guidelines under "Implement common traits from std" and is central to `std::iter::Iterator`, `std::io::Read`, and `std::io::Write`.

Related: `api-extension-trait`, `trait-associated-type-vs-generic`, `trait-blanket-impl`

## trait-dyn-vs-generic

> Choose static dispatch (generics / `impl Trait`) vs dynamic dispatch (`dyn Trait`) deliberately

### Why It Matters

Generic bounds and `impl Trait` monomorphize at compile time: each concrete type gets its own specialised copy that the compiler can inline and optimise, but every distinct type adds to binary size. `dyn Trait` stores a fat pointer (data + vtable) and dispatches at runtime, producing a single code path — necessary when you must store heterogeneous values or return erased types, at the cost of one pointer indirection per call. Choosing the wrong option either leaves performance on the table or prevents heterogeneous collections entirely. Default to generics for hot, simple code; reach for `dyn` when you need flexibility, heap storage, or cross-crate plug-ins.

### Bad

```rust
// Using `dyn` everywhere "to be flexible" — blocks inlining and
// forces heap allocation even for single, known types.
trait Shape {
    fn area(&self) -> f64;
}

struct Circle { radius: f64 }
impl Shape for Circle {
    fn area(&self) -> f64 { std::f64::consts::PI * self.radius * self.radius }
}

// Unnecessary boxing when only one concrete type is used.
fn total_area(shapes: &[Box<dyn Shape>]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}
```

### Good

```rust
use std::fmt;

trait Shape {
    fn area(&self) -> f64;
    fn name(&self) -> &str;
}

#[derive(Clone)]
struct Circle { radius: f64 }
#[derive(Clone)]
struct Rect { w: f64, h: f64 }

impl Shape for Circle {
    fn area(&self) -> f64 { std::f64::consts::PI * self.radius * self.radius }
    fn name(&self) -> &str { "circle" }
}
impl Shape for Rect {
    fn area(&self) -> f64 { self.w * self.h }
    fn name(&self) -> &str { "rect" }
}

// --- Static dispatch: use when the type is known and performance matters ---
// Monomorphized; the compiler can inline `area()`.
fn total_area_generic<S: Shape>(shapes: &[S]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

// Also fine with `impl Trait` in argument position (same monomorphization).
fn print_area(shape: &impl Shape) {
    println!("{}: {:.2}", shape.name(), shape.area());
}

// --- Dynamic dispatch: use for heterogeneous collections or plugin-like APIs ---
fn total_area_dyn(shapes: &[Box<dyn Shape>]) -> f64 {
    shapes.iter().map(|s| s.area()).sum()
}

fn demo() {
    // Homogeneous slice — zero boxing, static dispatch.
    let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
    println!("{:.2}", total_area_generic(&circles));

    // Heterogeneous collection — `dyn` is the right tool.
    let shapes: Vec<Box<dyn Shape>> = vec![
        Box::new(Circle { radius: 1.0 }),
        Box::new(Rect { w: 3.0, h: 4.0 }),
    ];
    println!("{:.2}", total_area_dyn(&shapes));
}
```

### Decision Table

| Situation | Prefer |
|---|---|
| Single known concrete type | `impl Trait` / generic |
| Hot path, inlining critical | Generic bound |
| Heterogeneous collection (`Vec<Box<dyn …>>`) | `dyn Trait` |
| Storing trait objects across calls | `dyn Trait` |
| Returning erased type from `fn` | `Box<dyn Trait>` or `impl Trait` (static) |
| Binary size matters, many monomorphisations | `dyn Trait` |
| Plug-in / callback registered at runtime | `dyn Trait` |

Related: `anti-type-erasure`, `type-generic-bounds`, `trait-object-safety`

## trait-object-safety

> Keep a trait dyn-compatible (object-safe) when you need `dyn Trait`

### Why It Matters

Only dyn-compatible traits can be used as `dyn Trait`. The Rust Reference defines dyn compatibility: every method must be dispatchable through a vtable, which means no generic type parameters on methods, no bare `Self` return or value position, and no associated constants. Violating these rules produces a hard compiler error at the `dyn` use site — often far from the trait definition. If you need both generic methods and `dyn Trait`, you can gate the non-dispatchable methods with `where Self: Sized`, which excludes them from the vtable while keeping the rest of the trait object-safe.

### Bad

```rust
trait Transformer {
    // Generic method — not dispatchable, makes the whole trait non-object-safe.
    fn transform<T: std::fmt::Debug>(&self, value: T) -> String;

    fn name(&self) -> &str;
}

struct Shout;
impl Transformer for Shout {
    fn transform<T: std::fmt::Debug>(&self, value: T) -> String {
        format!("{value:?}").to_uppercase()
    }
    fn name(&self) -> &str { "shout" }
}

// This fails to compile:
// error[E0038]: the trait `Transformer` cannot be made into an object
// fn apply(t: &dyn Transformer, x: i32) { ... }
```

### Good

```rust
trait Transformer {
    // Core dispatchable method — always in the vtable.
    fn transform_str(&self, value: &str) -> String;

    fn name(&self) -> &str;

    // Generic convenience method gated with `where Self: Sized`.
    // Callers can use it via a concrete type; it is excluded from `dyn Transformer`.
    fn transform_debug<T: std::fmt::Debug>(&self, value: T) -> String
    where
        Self: Sized,
    {
        self.transform_str(&format!("{value:?}"))
    }
}

// ----- Implementations -----

struct Shout;
impl Transformer for Shout {
    fn transform_str(&self, value: &str) -> String { value.to_uppercase() }
    fn name(&self) -> &str { "shout" }
}

struct Whisper;
impl Transformer for Whisper {
    fn transform_str(&self, value: &str) -> String { value.to_lowercase() }
    fn name(&self) -> &str { "whisper" }
}

// ----- Object-safe usage -----

fn apply_all(transformers: &[Box<dyn Transformer>], input: &str) {
    for t in transformers {
        println!("[{}] {}", t.name(), t.transform_str(input));
    }
}

// ----- Generic (static) usage — can call the `where Self: Sized` method -----

fn apply_generic<T: Transformer>(t: &T, value: i32) -> String {
    t.transform_debug(value)  // available because T: Sized
}

fn demo() {
    let ts: Vec<Box<dyn Transformer>> = vec![
        Box::new(Shout),
        Box::new(Whisper),
    ];
    apply_all(&ts, "Hello World");

    // Static dispatch path can use the generic helper.
    let result = apply_generic(&Shout, 42);
    println!("{result}");
}
```

### Dyn-Compatibility Rules (Quick Reference)

| Feature | Allowed in `dyn Trait`? |
|---|---|
| `&self` / `&mut self` methods | Yes |
| Methods returning `Self` by value | No — use `Box<Self>` or gate with `where Self: Sized` |
| Generic method parameters (`fn f<T>`) | No — gate with `where Self: Sized` |
| Associated constants | No |
| Associated types | Yes (type is erased but fixed per impl) |
| `where Self: Sized` methods | Excluded from vtable, safe to have |

See the Rust Reference — "Object Safety" — at doc.rust-lang.org/reference/items/traits.html#object-safety for the full rules.

Related: `trait-dyn-vs-generic`, `anti-type-erasure`, `api-sealed-trait`
