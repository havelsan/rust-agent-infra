---
name: rust-26-macros
description: Rust rules module 26: Macros. 8 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `macro-`
---

# Macros

Priority: MEDIUM. 8 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `macro-prefer-functions` - Reach for a macro only when a function or generic cannot express it
- `macro-rules-hygiene` - Rely on `macro_rules!` hygiene and use `$crate` for paths to your crate's items
- `macro-fragment-specifiers` - Capture with precise fragment specifiers, not raw `:tt`, where you can
- `macro-export-crate-path` - Export declarative macros with `#[macro_export]` and a clean import path
- `macro-private-helpers` - Hide macro-generated helper items behind a `#[doc(hidden)] pub mod __private`
- `macro-proc-two-crate` - Put procedural macros in a dedicated `proc-macro = true` crate and re-export from the facade
- `macro-proc-syn-quote` - Build procedural macros with `syn`, `quote`, and `proc-macro2`
- `macro-proc-error-spans` - Report proc-macro errors as spanned compile errors, never by panicking

---

## macro-prefer-functions

> Reach for a macro only when a function or generic cannot express it

### Why It Matters

Macros operate on token streams before type checking, so they bypass type inference, resist IDE navigation, and produce opaque error messages. They also slow incremental compilation and cannot be passed as values. A generic function is almost always clearer, better-optimized by the compiler, and easier for contributors to reason about.

Reach for a macro only when you genuinely need one of: variadic argument counts, a DSL with non-Rust syntax, blanket trait impls across an open-ended set of types, compile-time format/string checks, or eliminating mechanically repetitive boilerplate that a function truly cannot handle.

### Bad

```rust
// Nothing here requires a macro — no variadic args, no DSL, no trait impl.
macro_rules! double {
    ($x:expr) => {
        $x * 2
    };
}

fn main() {
    let n = double!(21);
    println!("{n}");
}
```

### Good

```rust
// A generic function is clearer, debuggable, and just as efficient.
#[inline]
fn double<T>(x: T) -> T
where
    T: std::ops::Mul<Output = T> + Copy,
{
    x * x  // or x + x for integer-like types
}

fn main() {
    let n = double(21_i32);
    println!("{n}");
}
```

### When to Reach for a Macro

| Situation | Use a macro? |
|-----------|-------------|
| Fixed argument count, any types | No — use generics |
| Truly variadic argument list (`vec![]`, `println!`) | Yes |
| Implementing a trait for many unrelated types | Yes — `macro_rules!` impl block |
| DSL / embedded syntax (SQL, HTML, regex literals) | Yes — proc-macro |
| Compile-time format string validation | Yes — `format_args!` style |
| Boilerplate a derive could generate | Yes — `#[derive(...)]` proc-macro |
| Simple computation or type conversion | No — use a function or trait |

Related: `anti-over-abstraction`, `type-generic-bounds`, `macro-rules-hygiene`

## macro-rules-hygiene

> Rely on `macro_rules!` hygiene and use `$crate` for paths to your crate's items

### Why It Matters

`macro_rules!` is hygienic for local bindings: identifiers introduced inside the macro (with `let`, loop labels, etc.) live in their own namespace and cannot shadow or clash with the caller's identifiers. This protects callers from surprising capture bugs.

Item paths, however, are not automatically resolved. If your macro calls `crate::helper()`, it silently breaks when the macro is used from a different crate. Use `$crate::helper()` instead — `$crate` expands to the defining crate regardless of call site, so the macro works correctly even when re-exported.

### Bad

```rust
// lib.rs
pub fn log_value(v: &str) {
    println!("[log] {v}");
}

#[macro_export]
macro_rules! log {
    ($val:expr) => {
        // WRONG: `crate::` resolves relative to the *caller's* crate,
        // not to the crate that defined this macro.
        crate::log_value(&format!("{:?}", $val));
    };
}
```

```rust
// consumer/src/main.rs
use mylib::log;

fn main() {
    log!(42); // compile error: `crate::log_value` not found in consumer
}
```

### Good

```rust
// lib.rs
pub fn log_value(v: &str) {
    println!("[log] {v}");
}

#[macro_export]
macro_rules! log {
    ($val:expr) => {
        // `$crate` always expands to the crate that defined this macro.
        $crate::log_value(&format!("{:?}", $val));
    };
}
```

```rust
// consumer/src/main.rs
use mylib::log;

fn main() {
    log!(42); // correctly calls mylib::log_value
}
```

### Hygiene for Local Bindings

Hygiene means that `let` bindings introduced inside a macro are invisible to the caller:

```rust
macro_rules! swap {
    ($a:expr, $b:expr) => {{
        // `tmp` here does NOT interfere with any `tmp` in the caller's scope.
        let tmp = $a;
        $a = $b;
        $b = tmp;
    }};
}

fn main() {
    let tmp = "outer";        // unrelated to the macro's `tmp`
    let (mut x, mut y) = (1, 2);
    swap!(x, y);
    assert_eq!((x, y), (2, 1));
    assert_eq!(tmp, "outer"); // still intact
}
```

### Key Points

- Always use `$crate::` for any path to items in the defining crate.
- `$crate` works even when the macro is re-exported through another crate.
- Hygiene does NOT protect against identifier tokens you pass as `$name:ident` — those come from the caller's scope intentionally.
- For items meant to be called from generated code, combine `$crate::` with a `#[doc(hidden)] pub mod __private` to avoid polluting the public API (see `macro-private-helpers`).

Related: `macro-export-crate-path`, `macro-private-helpers`, `macro-prefer-functions`

## macro-fragment-specifiers

> Capture with precise fragment specifiers, not raw `:tt`, where you can

### Why It Matters

Fragment specifiers tell the compiler — and readers — exactly what syntactic category a macro arm expects. They produce targeted error messages ("expected expression" instead of "no rules expected token"), enable better IDE tooling, and prevent ambiguous parses. Using raw `:tt` (token tree) forces you to re-parse or validate by hand and leaks implementation details into error messages.

Note the **follow-set restriction**: after `:expr`, `:ty`, `:pat`, and a few others, only a limited set of tokens may appear — most commonly `=>`, `,`, `;`, `|`, or another fragment. Plan your separator tokens accordingly.

### Bad

```rust
// Slurping everything as :tt, then trying to use $e as if it were an expression.
macro_rules! debug_val {
    ($($t:tt)*) => {
        println!("{} = {:?}", stringify!($($t)*), $($t)*);
        //                                          ^^^^^^^^ re-expanding :tt soup
    };
}

fn main() {
    debug_val!(1 + 2);      // works by accident
    debug_val!(let x = 1);  // accepted by the macro; blows up at expansion
}
```

### Good

```rust
macro_rules! debug_val {
    // :expr captures a single expression; the follow-set allows `=>` and `,` after it.
    ($e:expr) => {
        println!("{} = {:?}", stringify!($e), $e);
    };
}

fn main() {
    debug_val!(1 + 2);
    // debug_val!(let x = 1); // now correctly rejected at the macro call site
}
```

### Fragment Specifier Reference

| Specifier | Matches | Common uses |
|-----------|---------|-------------|
| `:expr` | An expression | Values, arithmetic, closures |
| `:ty` | A type | Generic helpers, type aliases |
| `:ident` | An identifier | Field names, variable names |
| `:pat` | A pattern | `match` arm patterns |
| `:pat_param` | A pattern (no `|` at top level) | Fn param patterns |
| `:path` | A path (`a::b::c`) | Trait bounds, type paths |
| `:literal` | A literal (`42`, `"hi"`) | Constant values |
| `:block` | A `{ ... }` block | Inline code injection |
| `:stmt` | A statement | Statement-level macros |
| `:meta` | A meta item | `#[derive(Clone)]` content |
| `:vis` | A visibility qualifier | `pub`, `pub(crate)` |
| `:lifetime` | A lifetime (`'a`) | Generic lifetime params |
| `:tt` | Any single token tree | Last resort; combinators |

### Trailing-Comma Pattern

Allow an optional trailing comma in repetitions without requiring a follow-set workaround:

```rust
macro_rules! my_vec {
    ($($e:expr),* $(,)?) => {
        // $(,)? consumes an optional trailing comma, which is legal after :expr
        // because it appears as a separator/terminator, not in follow position.
        vec![$($e),*]
    };
}

let v = my_vec![1, 2, 3,]; // trailing comma accepted
```

Related: `macro-rules-hygiene`, `macro-prefer-functions`

## macro-export-crate-path

> Export declarative macros with `#[macro_export]` and a clean import path

### Why It Matters

`#[macro_export]` lifts a macro to the crate root, making it importable like any other item. Combined with `$crate::` paths (see `macro-rules-hygiene`), the macro works regardless of how callers import it. Since Rust 2018, callers can use ordinary path imports (`use mycrate::my_macro;`) rather than the legacy `#[macro_use] extern crate mycrate;`, which polluted the global namespace and depended on item ordering.

### Bad

```rust
// lib.rs — legacy style
// Requires callers to write `#[macro_use] extern crate mylib;`
// and dumps all macros into the caller's global scope.
macro_rules! greet {
    ($name:expr) => {
        println!("hello, {}", $name);
    };
}
```

```rust
// consumer/src/main.rs — legacy
#[macro_use]
extern crate mylib; // order-sensitive; pollutes namespace

fn main() {
    greet!("world");
}
```

### Good

```rust
// lib.rs — modern style
#[macro_export]
macro_rules! greet {
    ($name:expr) => {
        $crate::__private::print_greeting($name);
    };
}

// Re-export so `use mylib::greet;` resolves through the crate's public path.
// (The re-export is implicit when using #[macro_export]; this is just for clarity
// or when you want to place it under a module path.)
pub use greet;
```

```rust
// consumer/src/main.rs — modern
use mylib::greet;

fn main() {
    greet!("world");
}
```

### Placing Macros in Modules

`#[macro_export]` always places the macro at the crate root regardless of where the `macro_rules!` definition appears. To expose it under a module path, use a `pub use` re-export:

```rust
// lib.rs
pub mod macros {
    // The macro is defined at crate root by #[macro_export], but we
    // also re-export it here so `use mycrate::macros::greet;` works.
    pub use crate::greet;
}

#[macro_export]
macro_rules! greet {
    ($name:expr) => { println!("hello, {}", $name); };
}
```

### Key Points

- Prefer `use mycrate::my_macro;` — it is explicit and plays well with `rustfmt` and IDEs.
- Avoid `#[macro_use]` in new code; it is required only when supporting pre-2018 edition consumers.
- If the macro calls internal helpers, pair `#[macro_export]` with `$crate::__private::...` paths.
- Document macros with `///` just like any other public item.

Related: `macro-rules-hygiene`, `macro-private-helpers`, `proj-workspace-deps`

## macro-private-helpers

> Hide macro-generated helper items behind a `#[doc(hidden)] pub mod __private`

### Why It Matters

Exported macros often need to call helper functions, use types, or invoke traits at the call site. Placing those helpers directly in the crate's public API pollutes the surface with implementation details and freezes them under semver — any rename or removal becomes a breaking change. Routing all generated references through a `#[doc(hidden)] pub mod __private` keeps the public API clean while letting you evolve internals freely.

This is the pattern used by `serde`, `thiserror`, and many derive crates.

### Bad

```rust
// lib.rs — helper leaks into the public API
pub fn __format_value(v: &dyn std::fmt::Debug) -> String {
    format!("{v:?}")
}

#[macro_export]
macro_rules! debug_print {
    ($val:expr) => {
        println!("{}", $crate::__format_value(&$val));
    };
}
```

```text
// A user sees `__format_value` in the docs and may depend on it.
// Removing it later is a semver-breaking change.
```

### Good

```rust
// lib.rs

#[doc(hidden)]
pub mod __private {
    // Everything re-exported here is technically public (required for
    // macro call sites), but hidden from rendered docs and clearly
    // marked as an unstable implementation detail.
    pub use crate::helpers::format_value;
}

// Internal module — not public.
mod helpers {
    pub fn format_value(v: &dyn std::fmt::Debug) -> String {
        format!("{v:?}")
    }
}

#[macro_export]
macro_rules! debug_print {
    ($val:expr) => {
        // Reference through __private; never through the bare crate root.
        println!("{}", $crate::__private::format_value(&$val));
    };
}
```

### With a Derive Macro

The same pattern applies when a derive crate generates code that needs helpers from the facade crate:

```rust
// mycrate/src/lib.rs

#[doc(hidden)]
pub mod __private {
    // Traits and functions the generated `impl` blocks will call.
    pub use crate::runtime::{Describe, describe_fields};
}

// Re-export the derive macro so users write `use mycrate::Describe;`
pub use mycrate_derive::Describe;
```

```rust
// Generated by the derive macro (inside mycrate-derive):
impl ::mycrate::__private::Describe for MyStruct {
    fn describe(&self) -> String {
        ::mycrate::__private::describe_fields(&[/* ... */])
    }
}
```

### Key Points

- Name the module `__private` (double-underscore) — it signals "not part of the public API" by convention across the ecosystem.
- Always pair with `#[doc(hidden)]` so the module is invisible in rendered documentation.
- Reference items as `$crate::__private::...` inside macros — never as bare paths.
- Document in your crate's CHANGELOG or README that `__private` is exempt from semver guarantees.

Related: `macro-rules-hygiene`, `macro-proc-two-crate`, `doc-all-public`

## macro-proc-two-crate

> Put procedural macros in a dedicated `proc-macro = true` crate and re-export from the facade

### Why It Matters

A crate marked `proc-macro = true` in `Cargo.toml` compiles for the host (the build machine) and can **only** export procedural macros — no regular types, traits, or functions. If your library needs both a derive/attribute macro and ordinary APIs, you must split into two crates: a `mycrate-derive` (or `mycrate-macros`) proc-macro crate and a `mycrate` facade crate that re-exports everything.

The facade approach ensures:
- Users add only `mycrate` as a dependency.
- Generated code refers to types through `::mycrate::__private::...`, so the impl crate version is invisible.
- Workspace dependency inheritance keeps both crates locked to the same version without repetition.

### Bad

```rust
// A single crate with `proc-macro = true` in Cargo.toml that also tries
// to export regular items:
#[proc_macro_derive(Greet)]
pub fn derive_greet(input: TokenStream) -> TokenStream { /* ... */ }

pub trait Greet { fn greet(&self) -> String; } // error: a proc-macro crate
pub struct Config;                              // can only export proc-macros
```

### Good

Split into a `proc-macro = true` crate plus a facade that re-exports it (full manifests and code below):

```rust
// users depend only on `mycrate`:
use mycrate::Greet;        // the trait
#[derive(mycrate::Greet)]  // the derive, re-exported from mycrate-derive
struct Robot;
```

### Crate Layout

```
my-workspace/
├── Cargo.toml          # workspace manifest
├── mycrate/
│   ├── Cargo.toml
│   └── src/lib.rs
└── mycrate-derive/
    ├── Cargo.toml
    └── src/lib.rs
```

### Cargo.toml Files

```toml
# my-workspace/Cargo.toml
[workspace]
members = ["mycrate", "mycrate-derive"]
resolver = "3"   # default for the 2024 edition; use "2" for 2021

[workspace.dependencies]
mycrate-derive = { path = "mycrate-derive", version = "0.1" }
syn  = { version = "2", features = ["derive"] }
quote = "1"
proc-macro2 = "1"
```

```toml
# mycrate-derive/Cargo.toml
[package]
name = "mycrate-derive"
version = "0.1.0"
edition = "2024"

[lib]
proc-macro = true   # required — makes this a proc-macro crate

[dependencies]
syn.workspace   = true
quote.workspace = true
proc-macro2.workspace = true
```

```toml
# mycrate/Cargo.toml
[package]
name = "mycrate"
version = "0.1.0"
edition = "2024"

[dependencies]
mycrate-derive.workspace = true
```

### Re-export from the Facade

```rust
// mycrate/src/lib.rs

// Re-export the derive macro so users write `use mycrate::Greet;`
// or `#[derive(mycrate::Greet)]`.
pub use mycrate_derive::Greet;

/// The trait that `#[derive(Greet)]` implements.
pub trait Greet {
    fn greet(&self) -> String;
}

#[doc(hidden)]
pub mod __private {
    // Helpers referenced by generated `impl` blocks.
    pub fn format_greeting(name: &str) -> String {
        format!("hello, {name}")
    }
}
```

```rust
// mycrate-derive/src/lib.rs
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(Greet)]
pub fn derive_greet(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let name_str = name.to_string();

    quote! {
        impl ::mycrate::Greet for #name {
            fn greet(&self) -> String {
                ::mycrate::__private::format_greeting(#name_str)
            }
        }
    }
    .into()
}
```

Related: `macro-proc-syn-quote`, `macro-private-helpers`, `proj-workspace-deps`, `err-thiserror-lib`

## macro-proc-syn-quote

> Build procedural macros with `syn`, `quote`, and `proc-macro2`

### Why It Matters

Writing a proc-macro by hand-parsing `proc_macro::TokenStream` is fragile and verbose. The standard ecosystem trio — `syn` (parsing), `quote` (code generation), and `proc-macro2` (span-aware token types) — gives you a typed AST, readable quasi-quoting, and the ability to unit-test your macro logic outside the compiler.

Enable only the `syn` features you actually use. The `full` feature parses all Rust syntax but adds compile time; `derive` is sufficient for most `#[proc_macro_derive]` implementations.

### Bad

```rust
// Manually iterating tokens to find a struct name — brittle and hard to read.
use proc_macro::TokenStream;

#[proc_macro_derive(Hello)]
pub fn derive_hello(input: TokenStream) -> TokenStream {
    let mut iter = input.into_iter();
    // skip `struct`, grab the next ident... error-prone and breaks on generics
    iter.next(); // "struct"
    let name = iter.next().unwrap().to_string();
    format!("impl Hello for {name} {{ fn hello(&self) {{ println!(\"hello\"); }} }}")
        .parse()
        .unwrap()
}
```

### Good

```toml
# Cargo.toml for the derive crate
[dependencies]
syn  = { version = "2", features = ["derive"] }
quote = "1"
proc-macro2 = "1"
```

```rust
// src/lib.rs
use proc_macro::TokenStream;
use proc_macro2::Span;
use quote::{quote, quote_spanned};
use syn::{parse_macro_input, spanned::Spanned, DeriveInput};

#[proc_macro_derive(Hello)]
pub fn derive_hello(input: TokenStream) -> TokenStream {
    // parse_macro_input! gives a typed DeriveInput or emits a compile error.
    let input = parse_macro_input!(input as DeriveInput);
    let name = &input.ident;
    let (impl_generics, ty_generics, where_clause) = input.generics.split_for_impl();

    // quote! quasi-quotes Rust tokens; `#name` splices the identifier.
    let expanded = quote! {
        impl #impl_generics Hello for #name #ty_generics #where_clause {
            fn hello(&self) {
                println!("hello from {}", stringify!(#name));
            }
        }
    };

    expanded.into()
}
```

### Using `quote_spanned!` for Better Diagnostics

Attaching generated code to a meaningful span makes errors point at the right location in user code:

```rust
use syn::{spanned::Spanned, Field};
use quote::quote_spanned;

fn require_named_field(field: &Field) -> proc_macro2::TokenStream {
    let span = field.span();
    let name = field.ident.as_ref().expect("named field");

    // Any error from the generated code will point at the field declaration.
    quote_spanned! { span =>
        let _ = &self.#name; // generated access to prove the field exists
    }
}
```

### Unit Testing with `proc-macro2`

Because `proc-macro2::TokenStream` is usable outside the compiler, you can test generation logic in regular `#[test]` functions:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use quote::quote;
    use syn::parse_quote;

    #[test]
    fn generates_impl_for_unit_struct() {
        let input: DeriveInput = parse_quote! { struct Foo; };
        // Call the internal generation function (not the proc_macro entry point).
        let tokens = generate_hello_impl(&input);
        let code = tokens.to_string();
        assert!(code.contains("impl Hello for Foo"));
    }
}
```

Related: `macro-proc-two-crate`, `macro-proc-error-spans`

## macro-proc-error-spans

> Report proc-macro errors as spanned compile errors, never by panicking

### Why It Matters

A `panic!`, `.unwrap()`, or `.expect()` inside a proc-macro produces an opaque compiler message — "proc macro panicked" — with no source location. The user sees no indication of which part of their code triggered the error. Returning a `syn::Error` converted to a token stream instead gives a diagnostic that points directly at the offending span, exactly like an ordinary compiler error.

### Bad

```rust
use proc_macro::TokenStream;
use syn::{parse_macro_input, Data, DeriveInput};

#[proc_macro_derive(MyTrait)]
pub fn derive_my_trait(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);

    let fields = match input.data {
        Data::Struct(ref s) => &s.fields,
        _ => panic!("MyTrait can only be derived on structs"), // WRONG
    };

    // `.unwrap()` here gives "called `Option::unwrap()` on a `None` value"
    // with no location info in user code.
    let first = fields.iter().next().unwrap();
    let name = first.ident.as_ref().unwrap();

    quote::quote! {
        impl MyTrait for #name {}
    }
    .into()
}
```

```text
error: proc macro panicked
  --> src/main.rs:3:10
   |
 3 | #[derive(MyTrait)]
   |          ^^^^^^^
   |
   = help: message: MyTrait can only be derived on structs
```

### Good

```rust
use proc_macro::TokenStream;
use proc_macro2::TokenStream as TokenStream2;
use quote::quote;
use syn::{parse_macro_input, spanned::Spanned, Data, DeriveInput, Error};

#[proc_macro_derive(MyTrait)]
pub fn derive_my_trait(input: TokenStream) -> TokenStream {
    derive_my_trait_inner(input).unwrap_or_else(|e| e.to_compile_error().into())
}

fn derive_my_trait_inner(input: TokenStream) -> Result<TokenStream, Error> {
    let input = parse_macro_input!(input as DeriveInput);

    let fields = match &input.data {
        Data::Struct(s) => &s.fields,
        Data::Enum(e) => {
            return Err(Error::new_spanned(
                &input.ident,
                "MyTrait can only be derived on structs, not enums",
            ));
        }
        Data::Union(u) => {
            return Err(Error::new_spanned(
                &input.ident,
                "MyTrait can only be derived on structs, not unions",
            ));
        }
    };

    let first = fields.iter().next().ok_or_else(|| {
        Error::new_spanned(&input.ident, "MyTrait requires at least one field")
    })?;

    let field_name = first.ident.as_ref().ok_or_else(|| {
        // Attach the error to the field's span, not the struct name.
        Error::new_spanned(first, "MyTrait requires named fields")
    })?;

    let struct_name = &input.ident;
    Ok(quote! {
        impl MyTrait for #struct_name {
            fn first_field_name() -> &'static str {
                stringify!(#field_name)
            }
        }
    }
    .into())
}
```

```text
error: MyTrait requires named fields
  --> src/main.rs:7:5
   |
 7 |     u8,   // tuple struct field
   |     ^^
```

### Key Points

- Wrap proc-macro logic in a `fn(...) -> Result<TokenStream2, syn::Error>` helper and convert at the entry point with `.unwrap_or_else(|e| e.to_compile_error().into())`.
- Use `Error::new_spanned(tokens, "message")` to attach the error to a specific part of the input AST.
- Use `Error::new(span, "message")` when you only have a `Span`, not a token.
- Combine multiple errors with `Error::combine` rather than returning early, so the user sees all problems at once.
- Error messages: lowercase, no trailing punctuation (consistent with Rust compiler style).

Related: `macro-proc-syn-quote`, `err-thiserror-lib`
