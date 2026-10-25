---
name: rust-25-pattern-matching
description: Rust rules module 25: Pattern Matching. 5 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `pat-`
---

# Pattern Matching

Priority: MEDIUM. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `pat-let-else` - Use `let ... else` for early-return pattern extraction
- `pat-matches-macro` - Use `matches!()` for boolean pattern tests
- `pat-if-let-chains` - Use `if let` chains to combine pattern bindings and conditions
- `pat-exhaustive-enum` - Match owned enums exhaustively; avoid catch-all `_` that hides new variants
- `pat-at-bindings` - Use `@` bindings to capture a value while matching it against a pattern

---

## pat-let-else

> Use `let ... else` for early-return pattern extraction

### Why It Matters

`let ... else` (stable since Rust 1.65) binds a pattern in the success path or diverges in the `else` branch. It keeps the happy path at the top indentation level and eliminates rightward drift that accumulates when nesting multiple `if let` blocks. The `else` block must diverge via `return`, `continue`, `break`, or a macro like `panic!` or `bail!`.

### Bad

```rust
fn process(input: Option<String>) -> Option<u32> {
    if let Some(s) = input {
        if let Ok(n) = s.trim().parse::<u32>() {
            if n > 0 {
                return Some(n * 2);
            } else {
                return None;
            }
        } else {
            return None;
        }
    } else {
        return None;
    }
}
```

### Good

```rust
fn process(input: Option<String>) -> Option<u32> {
    let Some(s) = input else { return None; };
    let Ok(n) = s.trim().parse::<u32>() else { return None; };
    if n == 0 {
        return None;
    }
    Some(n * 2)
}
```

Multiple extractions stay flat, each guarding against one failure mode before the next line runs.

### Using with `anyhow` / `bail!`

The `else` block can use any diverging expression, including macros:

```rust
use anyhow::{bail, Result};

fn get_id(map: &std::collections::HashMap<String, u64>, key: &str) -> Result<u64> {
    let Some(&id) = map.get(key) else {
        bail!("key '{}' not found", key);
    };
    Ok(id)
}
```

### Notes

- The bound variable is in scope **after** the `let` statement, not inside the `else` block.
- Prefer `?` when the `else` branch would just propagate an error; `let ... else` shines when the divergence is a `return`, `continue`, or `break`.
- Clippy lint `clippy::manual_let_else` flags patterns that can be converted.

Related: `err-question-mark`, `anti-unwrap-abuse`, `pat-exhaustive-enum`

## pat-matches-macro

> Use `matches!()` for boolean pattern tests

### Why It Matters

`matches!(value, Pattern)` is the idiomatic way to ask "does this value match a pattern?" in a boolean context. Spelling it out as a `match` that returns `true`/`false` is noisy and distracts the reader from the intent. Clippy flags the verbose form with `clippy::match_like_matches_macro`. The macro also supports optional guards, making it useful for range checks and filtered option tests without introducing a binding.

### Bad

```rust
enum Status {
    Active,
    Pending,
    Closed,
}

fn is_active(s: &Status) -> bool {
    match s {
        Status::Active => true,
        _ => false,
    }
}

fn is_small_digit(n: u32) -> bool {
    match n {
        1..=9 => true,
        _ => false,
    }
}

fn is_positive(opt: Option<i32>) -> bool {
    match opt {
        Some(v) if v > 0 => true,
        _ => false,
    }
}
```

### Good

```rust
enum Status {
    Active,
    Pending,
    Closed,
}

fn is_active(s: &Status) -> bool {
    matches!(s, Status::Active)
}

fn is_small_digit(n: u32) -> bool {
    matches!(n, 1..=9)
}

fn is_positive(opt: Option<i32>) -> bool {
    matches!(opt, Some(v) if v > 0)
}
```

### Combining Multiple Variants

`matches!` accepts alternation with `|`, making multi-variant checks concise:

```rust
fn is_terminal(s: &Status) -> bool {
    matches!(s, Status::Closed | Status::Pending)
}
```

### Good for `is_*` Helper Methods

`matches!` pairs especially well with the `is_`/`has_`/`can_` naming convention for boolean predicate methods:

```rust
impl Status {
    pub fn is_active(&self) -> bool {
        matches!(self, Self::Active)
    }

    pub fn is_terminal(&self) -> bool {
        matches!(self, Self::Closed | Self::Pending)
    }
}
```

### Asserting a Match in Tests

For tests, `assert_matches!` (and `debug_assert_matches!`) — stabilized in Rust 1.96 — checks a value against a pattern and panics with the value's `Debug` output on failure, which is more informative than `assert!(matches!(...))`. They are not in the prelude, so import them:

```rust
use std::assert_matches::assert_matches;

let result = parse("42");
assert_matches!(result, Ok(n) if n == 42);
```

### Notes

- Enable `#![warn(clippy::match_like_matches_macro)]` (included in `clippy::style`) to catch existing verbose patterns automatically.
- When you need to bind the matched value or branch on it further, a real `match` or `if let` is still the right tool.

Related: `pat-exhaustive-enum`, `name-is-has-bool`

## pat-if-let-chains

> Use `if let` chains to combine pattern bindings and conditions

### Why It Matters

If-let chains (stabilized in Rust 1.88 under the 2024 edition) let you write a single `if` header that binds multiple patterns and tests arbitrary boolean conditions, all with `&&`. Without chains, each additional binding requires another level of nesting, pushing the happy-path body further right and forcing the reader to track multiple scopes. With chains, all preconditions read left-to-right at the same indentation level.

### Prerequisite

If-let chains require the **2024 edition**. Set it in `Cargo.toml`:

```toml
[package]
edition = "2024"
```

### Bad

```rust
fn handle(input: Option<String>, limit: Option<u32>) -> Option<String> {
    if let Some(s) = input {
        if let Ok(n) = s.trim().parse::<u32>() {
            if let Some(max) = limit {
                if n <= max {
                    return Some(format!("valid: {n}"));
                }
            }
        }
    }
    None
}
```

### Good

```rust
fn handle(input: Option<String>, limit: Option<u32>) -> Option<String> {
    if let Some(s) = input
        && let Ok(n) = s.trim().parse::<u32>()
        && let Some(max) = limit
        && n <= max
    {
        return Some(format!("valid: {n}"));
    }
    None
}
```

Each `&&` clause is evaluated in order; short-circuit semantics still apply, so later clauses only run if earlier ones succeed.

### Mixing Patterns and Boolean Guards

Chains can freely interleave `let` bindings with plain boolean expressions:

```rust
struct Config {
    debug: bool,
    timeout: Option<u64>,
}

fn effective_timeout(cfg: &Config) -> Option<u64> {
    if cfg.debug
        && let Some(t) = cfg.timeout
        && t > 0
    {
        Some(t)
    } else {
        None
    }
}
```

### When to Prefer `let ... else`

Use `let ... else` when the goal is early return on failure; use if-let chains when you have a richer condition that combines multiple optional bindings with a positive body to execute.

Related: `pat-let-else`, `pat-matches-macro`

## pat-exhaustive-enum

> Match owned enums exhaustively; avoid catch-all `_` that hides new variants

### Why It Matters

A `_ =>` wildcard arm silently absorbs any variant added to an enum you own, converting what should be a compile-time error into a silent runtime no-op. Exhaustive matches let the compiler act as a checklist: add a variant, get a build failure everywhere it is unhandled. Reserve `_` and `..` for **foreign** `#[non_exhaustive]` enums, where the language requires a catch-all, and document why it is necessary.

### Bad

```rust
#[derive(Debug)]
enum Status {
    Active,
    Pending,
    Closed,
}

fn describe(s: &Status) -> &'static str {
    match s {
        Status::Active => "active",
        _ => "inactive", // hides Status::Pending silently; adding a new variant goes unnoticed
    }
}
```

If `Status::Suspended` is later added, `describe` compiles and silently returns `"inactive"` for it — a logic bug the compiler never catches.

### Good

```rust
#[derive(Debug)]
enum Status {
    Active,
    Pending,
    Closed,
}

fn describe(s: &Status) -> &'static str {
    match s {
        Status::Active => "active",
        Status::Pending => "pending",
        Status::Closed => "closed",
        // Adding Status::Suspended now causes a compile error here — intended.
    }
}
```

### Grouping Variants with `|`

When several variants share the same handling, list them explicitly rather than falling back to `_`:

```rust
fn is_terminal(s: &Status) -> bool {
    match s {
        Status::Closed | Status::Pending => true,
        Status::Active => false,
    }
}
```

### When `_` Is Required: Foreign `#[non_exhaustive]` Enums

External crates may mark enums `#[non_exhaustive]`, which means the compiler *forces* a wildcard. Document the intent:

```rust
// From a hypothetical external crate:
// #[non_exhaustive]
// pub enum TheirEvent { Click, Hover, /* ... future variants */ }

fn handle_event(event: &some_crate::TheirEvent) {
    match event {
        some_crate::TheirEvent::Click => { /* ... */ }
        some_crate::TheirEvent::Hover => { /* ... */ }
        // required by #[non_exhaustive]; intentionally a no-op for unknown variants
        _ => {}
    }
}
```

### Clippy Lint

`clippy::wildcard_enum_match_arm` (part of `clippy::restriction`) warns when a wildcard arm in a match on a non-`#[non_exhaustive]` enum could be replaced with explicit variants. Enabling it catches drift over time.

Related: `api-non-exhaustive`, `type-enum-states`, `pat-matches-macro`

## pat-at-bindings

> Use `@` bindings to capture a value while matching it against a pattern

### Why It Matters

The `name @ pattern` syntax binds the matched value to `name` and simultaneously tests it against `pattern` in a single arm. Without `@`, you either re-access the original expression (verbose) or add a guard that repeats the condition and re-extracts the value (redundant). `@` bindings make the constraint and the binding a single, readable unit.

### Bad

```rust
fn classify(n: u32) -> String {
    match n {
        1..=9 => format!("single digit: {n}"), // fine here — n is Copy and in scope
        10..=99 => {
            let tens = n; // no real benefit; contrived but shows the pattern
            format!("two digits: {tens}")
        }
        _ => String::from("large"),
    }
}

// More revealing: nested struct field — must re-access after matching range
#[derive(Debug)]
enum Command {
    Move { x: i32, y: i32 },
}

fn validate_move(cmd: &Command) {
    match cmd {
        Command::Move { x, y } if *x >= 0 && *x <= 100 => {
            // x is already bound, so this is fine, but the guard duplicates the range
            println!("valid move to x={x}, y={y}");
        }
        _ => println!("invalid command"),
    }
}
```

### Good

```rust
fn classify(n: u32) -> String {
    match n {
        id @ 1..=9 => format!("single digit: {id}"),
        id @ 10..=99 => format!("two digits: {id}"),
        _ => String::from("large"),
    }
}

// Nested struct field with @ binding
#[derive(Debug)]
enum Command {
    Move { x: i32, y: i32 },
}

fn validate_move(cmd: &Command) {
    match cmd {
        Command::Move { x: x_pos @ 0..=100, y } => {
            println!("valid move to x={x_pos}, y={y}");
        }
        _ => println!("invalid command"),
    }
}
```

`x: x_pos @ 0..=100` destructures the `x` field, checks that it falls in `0..=100`, and binds the value to `x_pos` — all in one expression.

### Binding an Enum Variant While Inspecting Its Payload

```rust
#[derive(Debug, Clone)]
enum Packet {
    Data(Vec<u8>),
    Control(u8),
}

fn log_data(packet: &Packet) {
    match packet {
        whole @ Packet::Data(bytes) if !bytes.is_empty() => {
            println!("non-empty packet: {whole:?}");
        }
        Packet::Data(_) => println!("empty data packet"),
        Packet::Control(code) => println!("control: {code}"),
    }
}
```

`whole` captures the entire `Packet::Data(...)` value while the guard checks the payload — no need to reconstruct the variant for logging.

### Notes

- `@` bindings work in all pattern positions: `match`, `if let`, `while let`, `let ... else`, and function parameters.
- Clippy lint `clippy::bind_instead_of_map` is unrelated but similarly reduces redundant re-access patterns.

Related: `pat-exhaustive-enum`, `type-enum-states`
