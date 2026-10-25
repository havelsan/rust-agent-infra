---
name: rust-41-linting-1of2
description: Rust rules module 41: Clippy & Linting (part 1 of 2). 6 rules, priority LOW. Load on its own to review or write Rust code against this topic only. Rule prefixes: `lint-`
---

# Clippy & Linting (part 1/2)

Priority: LOW. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `lint-deny-correctness` - `#![deny(clippy::correctness)]`
- `lint-warn-suspicious` - Enable clippy::suspicious for likely bugs
- `lint-warn-style` - Enable clippy::style for idiomatic code
- `lint-warn-complexity` - Enable clippy::complexity for simpler code
- `lint-warn-perf` - Enable clippy::perf for performance improvements
- `lint-pedantic-selective` - Enable clippy::pedantic selectively

---

## lint-deny-correctness

> `#![deny(clippy::correctness)]`

### Why It Matters

Clippy's correctness lints catch code that is outright wrong - logic errors, undefined behavior, or code that doesn't do what you think. These should always be errors, not warnings.

### Setup

```rust
// At the top of lib.rs or main.rs
#![deny(clippy::correctness)]

// Or in Cargo.toml for workspace-wide
[lints.clippy]
correctness = "deny"
```

### What It Catches

```rust
// Infinite loop (iter::repeat without take)
for x in std::iter::repeat(1) {  // ERROR: infinite iterator
    println!("{}", x);
}

// Comparison to NaN (always false)
if x == f64::NAN {  // ERROR: NaN != NaN always
    // This never executes
}

// Use after free patterns
let r;
{
    let x = 5;
    r = &x;  // ERROR: x dropped here
}
println!("{}", r);

// Wrong equality check
if x = 5 {  // ERROR: assignment in condition (should be ==)
}

// Useless comparisons
if x >= 0 && x < 0 {  // ERROR: impossible condition
}
```

### Important Correctness Lints

```rust
// approx_constant - using imprecise PI, E values
let pi = 3.14;  // Use std::f64::consts::PI

// invalid_regex - regex that won't compile
let re = Regex::new("[");  // Invalid regex

// iter_next_loop - using .next() in for loop incorrectly
for x in iter.next() {  // Should be: for x in iter

// never_loop - loop that never actually loops
loop {
    break;  // Always breaks immediately
}

// nonsensical_open_options - impossible file options
File::options().read(false).write(false).open("f");

// unit_cmp - comparing unit type ()
if foo() == bar() { }  // Both return (), always true
```

### Full Recommended Lints

```rust
#![deny(clippy::correctness)]
#![warn(clippy::suspicious)]
#![warn(clippy::style)]
#![warn(clippy::complexity)]
#![warn(clippy::perf)]

// For published crates
#![warn(missing_docs)]
#![warn(clippy::cargo)]
```

### Running Clippy

```bash
# Basic check
cargo clippy

# With all warnings as errors
cargo clippy -- -D warnings

# Check specific lint category
cargo clippy -- -W clippy::correctness

# In CI (fail on warnings)
cargo clippy -- -D warnings -D clippy::correctness
```

Related: `lint-warn-suspicious`, `lint-warn-perf`

## lint-warn-suspicious

> Enable clippy::suspicious for likely bugs

### Why It Matters

The `clippy::suspicious` lint group catches code patterns that are syntactically valid but almost always wrong. These are potential bugs that deserve investigation. Enabling this group as a warning helps catch mistakes early.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::suspicious)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
suspicious = "warn"
```

Or in `clippy.toml`:

```toml
warn = ["clippy::suspicious"]
```

### What It Catches

#### Suspicious Arithmetic

```rust
// WARN: Suspicious use of + in a << expression
let bits = 1 << 4 + 1;  // Probably meant (1 << 4) + 1 or 1 << (4 + 1)

// WARN: Suspicious use of | in a + expression
let value = x | 1 + y;  // Probably meant (x | 1) + y or x | (1 + y)
```

#### Suspicious Comparisons

```rust
// WARN: Almost swapped operands in a comparison
if 5 < x && x < 3 { }  // Impossible condition

// WARN: Suspicious assignment in a condition
if (x = 5) { }  // Probably meant x == 5
```

#### Suspicious Method Calls

```rust
// WARN: Suspicious map usage
let _: Vec<_> = vec.iter().map(|x| { 
    println!("{}", x);  // Side effect in map
    x
}).collect();  // Use for_each instead

// WARN: Suspicious string formatting
let s = format!("{}", format!("{}", x));  // Redundant nested format
```

#### Suspicious Casts

```rust
// WARN: Suspicious use of not on a bool
let inverted = !x as i32;  // Did you mean (!x) as i32 or !(x as i32)?

// WARN: Cast of float to int may lose precision
let n = 3.14_f64 as i32;  // May want .round() first
```

### Notable Lints in This Group

| Lint | Description |
|------|-------------|
| `suspicious_arithmetic_impl` | Unusual operator in arithmetic trait |
| `suspicious_assignment_formatting` | Looks like typo in assignment |
| `suspicious_else_formatting` | Else on wrong line |
| `suspicious_map` | Map with side effects |
| `suspicious_op_assign_impl` | Unusual op-assign implementation |
| `suspicious_splitn` | splitn that can't produce n parts |
| `suspicious_unary_op_formatting` | Confusing unary operator spacing |

### Example Catches

```rust
// Caught: Suspicious double negation
let value = --x;  // In Rust, this is -(-x), not pre-decrement

// Caught: Suspicious modulo
let remainder = x % 1;  // Always 0 for integers

// Caught: Suspicious else formatting
if condition {
    do_something();
}
else {  // Weird formatting, might be a mistake
    do_other();
}
```

### When to Allow

Rarely. If you need to suppress, document why:

```rust
#[allow(clippy::suspicious_arithmetic_impl)]
impl Mul for Matrix {
    // Custom matrix multiplication using + for reduction step
    fn mul(self, rhs: Self) -> Self::Output {
        // ...
    }
}
```

Related: `lint-deny-correctness`, `lint-warn-style`, `lint-warn-complexity`

## lint-warn-style

> Enable clippy::style for idiomatic code

### Why It Matters

The `clippy::style` lint group enforces idiomatic Rust patterns. While not bugs, style violations make code harder to read and maintain. Consistent style helps teams work together and makes code easier to review.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::style)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
style = "warn"
```

### What It Catches

#### Redundant Code

```rust
// WARN: Redundant clone on Copy type
let x = 5;
let y = x.clone();  // Just use: let y = x;

// WARN: Redundant closure
iter.map(|x| foo(x))  // Just use: iter.map(foo)

// WARN: Redundant pattern matching
match result {
    Ok(x) => Ok(x),
    Err(e) => Err(e),
}  // Just return result
```

#### Non-Idiomatic Patterns

```rust
// WARN: Should use if let
match option {
    Some(x) => do_something(x),
    None => {},
}
// Better: if let Some(x) = option { do_something(x) }

// WARN: Should use or_else
let value = if option.is_some() {
    option.unwrap()
} else {
    default()
};
// Better: option.unwrap_or_else(default)

// WARN: Collapsible if statements
if condition1 {
    if condition2 {
        do_something();
    }
}
// Better: if condition1 && condition2 { do_something() }
```

#### Naming Issues

```rust
// WARN: Function should not start with 'is_' returning non-bool
fn is_valid() -> i32 { 0 }  // Misleading name

// WARN: Method should not be named 'new' without returning Self
impl Foo {
    fn new() -> Bar { Bar }  // Confusing
}
```

### Notable Lints in This Group

| Lint | Better Pattern |
|------|---------------|
| `len_zero` | Use `is_empty()` instead of `len() == 0` |
| `redundant_field_names` | Use shorthand `{ x }` not `{ x: x }` |
| `unused_unit` | Remove `-> ()` and trailing `()` |
| `collapsible_if` | Combine nested ifs with `&&` |
| `single_match` | Use `if let` instead |
| `match_like_matches_macro` | Use `matches!()` macro |
| `needless_return` | Remove explicit `return` at end |
| `question_mark` | Use `?` instead of `match` |

### Examples

```rust
// Before (style warnings)
fn process(data: Vec<i32>) -> Option<i32> {
    if data.len() == 0 {
        return None;
    }
    let first = match data.first() {
        Some(x) => x,
        None => return None,
    };
    return Some(*first);
}

// After (idiomatic)
fn process(data: Vec<i32>) -> Option<i32> {
    if data.is_empty() {
        return None;
    }
    let first = data.first()?;
    Some(*first)
}
```

### Selective Allowance

Some style lints may conflict with team preferences:

```rust
// If your team prefers explicit returns
#[allow(clippy::needless_return)]
fn explicit_return() -> i32 {
    return 42;
}
```

Related: `lint-warn-suspicious`, `lint-warn-complexity`, `lint-rustfmt-check`

## lint-warn-complexity

> Enable clippy::complexity for simpler code

### Why It Matters

The `clippy::complexity` lint group identifies unnecessarily complex code that can be simplified. Complex code is harder to read, maintain, and often hides bugs. Clippy suggests cleaner alternatives.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::complexity)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
complexity = "warn"
```

### What It Catches

#### Unnecessary Complexity

```rust
// WARN: Overly complex boolean expression
if !(x == 0) { }  // Use: if x != 0 { }

// WARN: Manual implementation of Option::map
match option {
    Some(x) => Some(x + 1),
    None => None,
}  // Use: option.map(|x| x + 1)

// WARN: Unnecessary filter before count
iter.filter(|x| predicate(x)).count()  // Could simplify if only counting
```

#### Redundant Operations

```rust
// WARN: Redundant allocation
let s = format!("literal");  // Use: "literal".to_string() or just "literal"

// WARN: Unnecessarily complicated match
match result {
    Ok(ok) => Ok(ok),
    Err(err) => Err(err),
}  // Just use: result

// WARN: Box::new in return position
fn make_error() -> Box<dyn Error> {
    Box::new(MyError)  // Could use: MyError.into()
}
```

#### Overly Verbose Code

```rust
// WARN: bind_instead_of_map
option.and_then(|x| Some(x + 1))  // Use: option.map(|x| x + 1)

// WARN: clone_on_copy
let y = x.clone();  // Where x is Copy type, just use: let y = x;

// WARN: useless_let_if_seq
let result;
if condition {
    result = 1;
} else {
    result = 2;
}
// Use: let result = if condition { 1 } else { 2 };
```

### Notable Lints in This Group

| Lint | Simplification |
|------|---------------|
| `bind_instead_of_map` | Use `map` instead of `and_then(Some(...))` |
| `bool_comparison` | `if x == true` → `if x` |
| `clone_on_copy` | Remove `.clone()` for Copy types |
| `filter_next` | Use `.find()` instead |
| `option_map_unit_fn` | Use `if let` instead |
| `search_is_some` | Use `.any()` or `.contains()` |
| `unnecessary_cast` | Remove redundant casts |
| `useless_conversion` | Remove `.into()` when types match |

### Examples

```rust
// Before (complexity warnings)
fn find_positive(nums: &[i32]) -> Option<i32> {
    let filtered: Vec<_> = nums.iter()
        .cloned()
        .filter(|x| *x > 0)
        .collect();
    if filtered.len() == 0 {
        None
    } else {
        Some(filtered[0])
    }
}

// After (simplified)
fn find_positive(nums: &[i32]) -> Option<i32> {
    nums.iter()
        .copied()
        .find(|&x| x > 0)
}
```

### Cognitive Load

Complex code isn't just longer—it's harder to understand:

```rust
// High cognitive load
let value = if x.is_some() { x.unwrap() } else { y.unwrap_or(z) };

// Lower cognitive load
let value = x.unwrap_or_else(|| y.unwrap_or(z));
```

Related: `lint-warn-style`, `lint-warn-perf`, `lint-pedantic-selective`

## lint-warn-perf

> Enable clippy::perf for performance improvements

### Why It Matters

The `clippy::perf` lint group catches performance anti-patterns—inefficient allocations, unnecessary copies, suboptimal API usage. While not all performance issues are critical, avoiding obvious inefficiencies is good practice.

### Configuration

```rust
// In lib.rs or main.rs
#![warn(clippy::perf)]
```

Or in `Cargo.toml`:

```toml
[lints.clippy]
perf = "warn"
```

### What It Catches

#### Unnecessary Allocations

```rust
// WARN: Unnecessary to_string before into
fn take_string(s: impl Into<String>) { }
take_string("hello".to_string());  // Just use: "hello"

// WARN: Box::new in return with deref coercion
fn make_trait() -> Box<dyn Trait> {
    Box::new(concrete)  // Could use Into
}

// WARN: Unnecessary vec! for iteration
for x in vec![1, 2, 3] { }  // Use array: [1, 2, 3]
```

#### Inefficient Operations

```rust
// WARN: Single-character string patterns
s.starts_with("x")  // Use char: 'x'
s.contains("a")     // Use char: 'a'

// WARN: iter().nth(0) instead of first()
iter.nth(0)  // Use: iter.first() or iter.next()

// WARN: Manual saturating arithmetic
if x > i32::MAX - y { i32::MAX } else { x + y }
// Use: x.saturating_add(y)
```

#### Collection Inefficiencies

```rust
// WARN: extend with a single element
vec.extend(std::iter::once(item));  // Use: vec.push(item)

// WARN: Inefficient to_vec
slice.iter().cloned().collect::<Vec<_>>()  // Use: slice.to_vec()

// WARN: Manual string concatenation
let s = format!("{}{}", a, b);  // When both are &str, use: a.to_owned() + b
```

### Notable Lints in This Group

| Lint | Improvement |
|------|-------------|
| `box_collection` | Use `Vec<T>` not `Box<Vec<T>>` |
| `iter_nth` | Use `.get(n)` or `.next()` |
| `large_enum_variant` | Box large variants |
| `manual_memcpy` | Use slice copy methods |
| `redundant_allocation` | Remove double boxing |
| `single_char_pattern` | Use `char` not `&str` |
| `slow_vector_initialization` | Use `vec![0; n]` |
| `unnecessary_to_owned` | Remove redundant `.to_owned()` |

### Examples

```rust
// Before (perf warnings)
fn process(input: &str) -> String {
    let parts: Vec<_> = input.split(",").collect();
    let mut result = String::new();
    for part in parts.iter() {
        if part.starts_with(" ") {
            result = result + &part.trim().to_string();
        }
    }
    result
}

// After (optimized)
fn process(input: &str) -> String {
    input.split(',')
        .filter(|part| part.starts_with(' '))
        .map(str::trim)
        .collect()
}
```

### Allocation Patterns

```rust
// Unnecessary allocation
let vec: Vec<i32> = vec![];  // Creates capacity
let vec: Vec<i32> = Vec::new();  // No allocation

// Pre-allocation
let mut vec = Vec::with_capacity(100);  // One allocation
for i in 0..100 {
    vec.push(i);  // No reallocation
}
```

### String Patterns

```rust
// Slow: str pattern
s.contains("x");
s.find("y");

// Fast: char pattern
s.contains('x');
s.find('y');
```

Related: `lint-warn-complexity`, `mem-with-capacity`, `perf-profile-first`

## lint-pedantic-selective

> Enable clippy::pedantic selectively

### Why It Matters

The `clippy::pedantic` group contains opinionated lints that aren't universally applicable. Enabling it wholesale produces noise; selectively enabling useful pedantic lints improves code quality without false positives.

### Bad

```rust
// Too noisy - will fight you constantly
#![warn(clippy::pedantic)]
```

### Good

```toml
# Cargo.toml - cherry-pick useful pedantic lints
[lints.clippy]
# Enable pedantic as baseline
pedantic = "warn"

# Disable noisy ones
missing_errors_doc = "allow"      # Document errors separately
missing_panics_doc = "allow"      # Document panics separately
module_name_repetitions = "allow" # Allow Foo::FooError pattern
too_many_lines = "allow"          # Function length varies
must_use_candidate = "allow"      # Too many suggestions
```

### Recommended Pedantic Lints

| Lint | Why Enable |
|------|-----------|
| `doc_markdown` | Catch unmarked code in docs |
| `match_wildcard_for_single_variants` | Explicit variant matching |
| `semicolon_if_nothing_returned` | Consistent semicolons |
| `string_add_assign` | Use `+=` for string concatenation |
| `unnested_or_patterns` | Simplify match patterns |
| `unused_self` | Catch methods that should be functions |
| `used_underscore_binding` | Warn on using `_var` |
| `wildcard_imports` | Avoid glob imports |

### Often Disabled

| Lint | Why Disable |
|------|-------------|
| `missing_errors_doc` | Handle with `#[doc]` policy |
| `missing_panics_doc` | Handle with `#[doc]` policy |
| `module_name_repetitions` | Sometimes intentional |
| `must_use_candidate` | Too aggressive |
| `too_many_lines` | Arbitrary threshold |
| `struct_excessive_bools` | Valid for config structs |

### Full Configuration

```toml
# Cargo.toml
[lints.clippy]
# Start with pedantic
pedantic = "warn"

# Keep these
doc_markdown = "warn"
match_wildcard_for_single_variants = "warn"
semicolon_if_nothing_returned = "warn"
unused_self = "warn"
wildcard_imports = "warn"

# Disable these
missing_errors_doc = "allow"
missing_panics_doc = "allow"
module_name_repetitions = "allow"
must_use_candidate = "allow"
too_many_lines = "allow"
similar_names = "allow"
struct_excessive_bools = "allow"
```

### Alternative: Explicit Opt-in

```toml
# Only enable specific lints, not the group
[lints.clippy]
# From pedantic, only these:
doc_markdown = "warn"
semicolon_if_nothing_returned = "warn"
unused_self = "warn"
wildcard_imports = "warn"
```

### Module-Level Overrides

```rust
// Allow specific lint for a module
#![allow(clippy::module_name_repetitions)]

// Or for specific items
#[allow(clippy::too_many_arguments)]
fn complex_function(/* many args */) { }
```

### Team Consensus

Pedantic lints are style choices. Agree as a team:

1. Enable `pedantic` as baseline
2. Run `cargo clippy` on codebase
3. Discuss each warning category
4. Disable ones that don't fit your style
5. Document decisions in `clippy.toml`

Related: `lint-warn-style`, `lint-warn-complexity`, `lint-deny-correctness`
