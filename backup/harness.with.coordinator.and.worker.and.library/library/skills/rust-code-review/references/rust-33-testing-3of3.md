---
name: rust-33-testing-3of3
description: Rust rules module 33: Testing (part 3 of 3). 5 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `test-`
---

# Testing (part 3/3)

Priority: MEDIUM. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `test-should-panic` - Use `#[should_panic]` to test that code panics as expected
- `test-criterion-bench` - Use `criterion` for benchmarking
- `test-doctest-examples` - Keep documentation examples as executable doctests
- `test-loom-concurrency` - Use `loom` to exhaustively test lock-free and concurrent code
- `test-snapshot-testing` - Use snapshot testing (insta) for complex or serialized output

---

## test-should-panic

> Use `#[should_panic]` to test that code panics as expected

### Why It Matters

Some code should panic on invalid inputs or invariant violations. `#[should_panic]` verifies the panic occurs, optionally checking the panic message. This ensures defensive panics work correctly and documents expected panic conditions.

### Bad

```rust
#[test]
fn test_panic() {
    // Just calling panicking code makes test fail
    divide(1, 0);  // Test fails with panic
}

// Using catch_unwind is verbose
#[test]
fn test_panic_manual() {
    let result = std::panic::catch_unwind(|| divide(1, 0));
    assert!(result.is_err());
}
```

### Good

```rust
#[test]
#[should_panic]
fn divide_by_zero_panics() {
    divide(1, 0);  // Test passes when this panics
}

// With expected message
#[test]
#[should_panic(expected = "division by zero")]
fn divide_by_zero_panics_with_message() {
    divide(1, 0);  // Panics with "division by zero"
}

// Partial message match
#[test]
#[should_panic(expected = "index out of bounds")]
fn index_panic_contains_message() {
    let v = vec![1, 2, 3];
    let _ = v[100];  // Message contains "index out of bounds"
}
```

### Testing Invariants

```rust
struct NonEmpty<T>(Vec<T>);

impl<T> NonEmpty<T> {
    fn new(items: Vec<T>) -> Self {
        assert!(!items.is_empty(), "NonEmpty cannot be empty");
        NonEmpty(items)
    }
}

#[test]
#[should_panic(expected = "NonEmpty cannot be empty")]
fn non_empty_rejects_empty_vec() {
    NonEmpty::new(Vec::<i32>::new());
}

#[test]
fn non_empty_accepts_non_empty_vec() {
    let ne = NonEmpty::new(vec![1, 2, 3]);
    assert_eq!(ne.0.len(), 3);
}
```

### With expect() Messages

```rust
fn get_config_value(key: &str) -> String {
    CONFIG.get(key)
        .expect(&format!("missing required config: {}", key))
        .to_string()
}

#[test]
#[should_panic(expected = "missing required config: DATABASE_URL")]
fn missing_config_panics_with_key() {
    get_config_value("DATABASE_URL");
}
```

### When NOT to Use should_panic

```rust
// ❌ For recoverable errors - use Result
#[test]
#[should_panic]  // Wrong: this should return Err, not panic
fn invalid_input_panics() {
    parse_config("invalid");  // Should return Err, not panic
}

// ✅ Return Result and test the error
#[test]
fn invalid_input_returns_error() {
    let result = parse_config("invalid");
    assert!(result.is_err());
}
```

### Combining with Result

```rust
#[test]
#[should_panic]
fn test_panics() -> Result<(), Error> {
    // Can combine with Result for setup
    let data = setup_test_data()?;
    
    // This should panic
    process_invalid(&data);
    
    Ok(())  // Never reached
}
```

Related: `err-result-over-panic`, `err-expect-bugs-only`, `test-descriptive-names`

## test-criterion-bench

> Use `criterion` for benchmarking

### Why It Matters

Criterion provides statistically rigorous benchmarking with warmup, multiple iterations, outlier detection, and comparison between runs. It's far more reliable than simple timing with `Instant::now()`.

### Setup

```toml
# Cargo.toml
[dev-dependencies]
criterion = "0.5"

[[bench]]
name = "my_benchmark"
harness = false
```

### Basic Benchmark

```rust
// benches/my_benchmark.rs
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 => 0,
        1 => 1,
        n => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn bench_fibonacci(c: &mut Criterion) {
    c.bench_function("fib 20", |b| {
        b.iter(|| fibonacci(black_box(20)))
    });
}

criterion_group!(benches, bench_fibonacci);
criterion_main!(benches);
```

### black_box is Critical

```rust
// BAD: Compiler may optimize away the computation
b.iter(|| fibonacci(20));  // Result unused, might be eliminated

// GOOD: black_box prevents optimization
b.iter(|| fibonacci(black_box(20)));

// Also wrap the result if needed
b.iter(|| black_box(fibonacci(black_box(20))));
```

### Comparing Implementations

```rust
fn bench_comparison(c: &mut Criterion) {
    let mut group = c.benchmark_group("String concat");
    
    let data = "hello";
    
    group.bench_function("format!", |b| {
        b.iter(|| format!("{}{}", black_box(data), " world"))
    });
    
    group.bench_function("push_str", |b| {
        b.iter(|| {
            let mut s = String::from(black_box(data));
            s.push_str(" world");
            s
        })
    });
    
    group.bench_function("concat", |b| {
        b.iter(|| [black_box(data), " world"].concat())
    });
    
    group.finish();
}
```

### Parameterized Benchmarks

```rust
fn bench_vec_push(c: &mut Criterion) {
    let mut group = c.benchmark_group("Vec::push");
    
    for size in [100, 1000, 10000].iter() {
        group.bench_with_input(
            BenchmarkId::from_parameter(size),
            size,
            |b, &size| {
                b.iter(|| {
                    let mut v = Vec::new();
                    for i in 0..size {
                        v.push(black_box(i));
                    }
                    v
                });
            },
        );
    }
    
    group.finish();
}
```

### Throughput Measurement

```rust
use criterion::Throughput;

fn bench_parse(c: &mut Criterion) {
    let input = "a]ong string to parse...";
    
    let mut group = c.benchmark_group("Parser");
    group.throughput(Throughput::Bytes(input.len() as u64));
    
    group.bench_function("parse", |b| {
        b.iter(|| parse(black_box(input)))
    });
    
    group.finish();
}
```

### Running Benchmarks

```bash
# Run all benchmarks
cargo bench

# Run specific benchmark
cargo bench -- fib

# Save baseline for comparison
cargo bench -- --save-baseline main

# Compare against baseline
cargo bench -- --baseline main
```

### Evidence from tokio

```rust
// https://github.com/tokio-rs/tokio/blob/master/benches/sync_mpsc.rs
use criterion::{criterion_group, criterion_main, Criterion};

fn send_data<T: Default, const SIZE: usize>(
    g: &mut BenchmarkGroup<WallTime>, 
    prefix: &str
) {
    let rt = rt();
    g.bench_function(format!("{prefix}_{SIZE}"), |b| {
        b.iter(|| {
            let (tx, mut rx) = mpsc::channel::<T>(SIZE);
            rt.block_on(tx.send(T::default())).unwrap();
            rt.block_on(rx.recv()).unwrap();
        })
    });
}
```

Related: `perf-profile-first`, `perf-black-box-bench`

## test-doctest-examples

> Keep documentation examples as executable doctests

### Why It Matters

Doctests are examples in documentation that are automatically tested. They serve dual purposes: demonstrating usage to readers and verifying the examples compile and work. When your API changes, failing doctests catch outdated documentation.

### Bad

```rust
/// Parses a number from a string.
/// 
/// Example:
/// let n = parse("42");  // Not tested!
/// assert_eq!(n, 42);
pub fn parse(s: &str) -> i32 {
    s.parse().unwrap()
}

// Documentation can become outdated:
/// Adds two numbers.
/// 
/// ```
/// let sum = add(1, 2, 3);  // Wrong number of args - not caught!
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### Good

```rust
/// Parses a number from a string.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::parse;
/// 
/// let n = parse("42");
/// assert_eq!(n, 42);
/// ```
pub fn parse(s: &str) -> i32 {
    s.parse().unwrap()
}

/// Adds two numbers.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::add;
/// 
/// let sum = add(1, 2);
/// assert_eq!(sum, 3);
/// ```
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### Hiding Setup Code

```rust
/// Processes data from a file.
/// 
/// # Examples
/// 
/// ```
/// # use std::io::Write;
/// # let mut file = tempfile::NamedTempFile::new().unwrap();
/// # writeln!(file, "test data").unwrap();
/// # let path = file.path();
/// use my_crate::process_file;
/// 
/// let result = process_file(path)?;
/// assert!(!result.is_empty());
/// # Ok::<(), Box<dyn std::error::Error>>(())
/// ```
pub fn process_file(path: &Path) -> Result<String, Error> {
    std::fs::read_to_string(path).map_err(Error::from)
}
```

### Showing Error Handling

```rust
/// Parses and validates an email address.
/// 
/// # Examples
/// 
/// ```
/// use my_crate::Email;
/// 
/// let email = Email::parse("user@example.com")?;
/// assert_eq!(email.domain(), "example.com");
/// # Ok::<(), my_crate::EmailError>(())
/// ```
/// 
/// # Errors
/// 
/// Returns error for invalid format:
/// 
/// ```
/// use my_crate::Email;
/// 
/// assert!(Email::parse("not-an-email").is_err());
/// ```
pub fn parse(s: &str) -> Result<Email, EmailError> {
    // ...
}
```

### no_run and ignore

```rust
/// Starts the server.
/// 
/// ```no_run
/// use my_crate::Server;
/// 
/// // This compiles but doesn't run (would block forever)
/// Server::new().run();
/// ```
pub fn run(&self) { ... }

/// Platform-specific example.
/// 
/// ```ignore
/// // This might not compile on all platforms
/// use windows_specific::Feature;
/// ```
```

### compile_fail

```rust
/// This type is not Clone.
/// 
/// ```compile_fail
/// use my_crate::UniqueHandle;
/// 
/// let a = UniqueHandle::new();
/// let b = a.clone();  // Error: Clone not implemented
/// ```
pub struct UniqueHandle { ... }
```

### Running Doctests

```bash
# Run all tests including doctests
cargo test

# Run only doctests
cargo test --doc

# Run doctests for specific item
cargo test --doc my_function
```

Related: `doc-examples-section`, `doc-hidden-setup`, `doc-question-mark`

## test-loom-concurrency

> Use `loom` to exhaustively test lock-free and concurrent code

### Why It Matters

Probabilistic stress tests can run millions of iterations and still miss a race condition that only manifests under a specific thread interleaving. `loom` systematically explores every thread scheduling and memory-reordering permitted by the C11 memory model, turning "we ran it a lot and it seemed fine" into a proof of correctness for the interleavings that exist within the model bounds. Tokio uses loom to verify its internal synchronization primitives.

### Bad

```rust
// Stress test: might pass a billion times, still doesn't prove correctness
#[test]
fn stress_test_flag() {
    use std::sync::{Arc, atomic::{AtomicBool, Ordering}};
    let flag = Arc::new(AtomicBool::new(false));
    for _ in 0..1_000_000 {
        let flag = Arc::clone(&flag);
        std::thread::spawn(move || {
            flag.store(true, Ordering::Relaxed);
        });
    }
    // races may never surface under the OS scheduler used here
}
```

### Good

Gate concurrent primitives behind `#[cfg(loom)]` so the same code runs with loom's instrumented types during model checking and with std types in production:

```rust
// src/flag.rs
#[cfg(loom)]
use loom::sync::atomic::{AtomicBool, Ordering};
#[cfg(not(loom))]
use std::sync::atomic::{AtomicBool, Ordering};

pub struct Flag(AtomicBool);

impl Flag {
    pub const fn new() -> Self {
        Self(AtomicBool::new(false))
    }

    pub fn set(&self) {
        self.0.store(true, Ordering::Release);
    }

    pub fn is_set(&self) -> bool {
        self.0.load(Ordering::Acquire)
    }
}
```

```rust
// tests/loom_flag.rs  (or inside a #[cfg(loom)] mod in the crate)
#[cfg(loom)]
mod tests {
    use loom::sync::Arc;
    use super::Flag;

    #[test]
    fn flag_set_visible_to_other_thread() {
        loom::model(|| {
            let flag = Arc::new(Flag::new());

            let flag2 = Arc::clone(&flag);
            let writer = loom::thread::spawn(move || {
                flag2.set();
            });

            // All interleavings: either writer runs first or reader does.
            // loom verifies the Acquire/Release pair holds in both cases.
            let seen = flag.is_set();
            writer.join().unwrap();

            // After join, writer must have completed; flag must be set.
            assert!(flag.is_set(), "flag must be set after join");
            // 'seen' may be false if reader ran before writer — that is valid.
            let _ = seen;
        });
    }
}
```

Run loom tests with the feature flag:

```bash
RUSTFLAGS="--cfg loom" cargo test --test loom_flag
```

### Key Points

- Keep loom model closures **small**: combinatorial explosion grows with the number of atomic operations and threads. Test one primitive or algorithm at a time.
- loom replaces `std::sync::atomic`, `std::sync::Mutex`, `std::thread`, and `std::cell` with instrumented equivalents — import from `loom::` under `#[cfg(loom)]`.
- Use `loom::model(|| { ... })` as the entry point; loom runs the closure repeatedly under different schedules.
- loom checks the C11 model — it does not detect logical bugs unrelated to concurrency.

Related: `conc-atomic-ordering`, `test-criterion-bench`

## test-snapshot-testing

> Use snapshot testing (insta) for complex or serialized output

### Why It Matters

Asserting large structured output — pretty-printed structs, rendered error messages, JSON responses, generated code, CLI output — with hand-written `assert_eq!` is verbose, brittle, and hard to update when output intentionally changes. The `insta` crate records an approved snapshot on first run and diffs against it on subsequent runs; when output changes legitimately, `cargo insta review` presents a diff and lets you accept it in one keystroke. Snapshots are committed to the repo and reviewed in PRs, making output changes visible and deliberate rather than silent.

### Bad

```rust
#[test]
fn test_render_error() {
    let err = AppError::NotFound { id: 42 };
    // Fragile: must manually maintain this string forever
    assert_eq!(
        format!("{err}"),
        "resource with id 42 was not found in the database and could not be retrieved"
    );
}

#[test]
fn test_config_serialization() {
    let config = Config::default();
    let json = serde_json::to_string_pretty(&config).unwrap();
    // Hard to read, hard to update, easy to get wrong
    assert_eq!(json, "{\n  \"timeout\": 30,\n  \"retries\": 3\n}");
}
```

### Good

```toml
[dev-dependencies]
insta = { version = "1", features = ["json", "yaml"] }
```

```rust
use insta::assert_debug_snapshot;
use insta::assert_json_snapshot;

#[test]
fn test_render_error() {
    let err = AppError::NotFound { id: 42 };
    // On first run: creates snapshots/test_render_error.snap
    // On subsequent runs: diffs against the saved snapshot
    assert_debug_snapshot!(err);
}

#[test]
fn test_config_serialization() {
    let config = Config::default();
    // Snapshot stored as pretty-printed JSON for easy review
    assert_json_snapshot!(config);
}

#[test]
fn test_cli_output() {
    let output = run_cli(&["--help"]);
    // Named snapshot for clarity
    assert_debug_snapshot!("cli_help_output", output);
}
```

### Workflow

1. Run tests for the first time: `cargo test` — insta creates `.snap.new` files.
2. Review and accept: `cargo insta review` — interactive diff; press `a` to accept.
3. Commit the `.snap` files alongside your code changes.
4. In CI, run `cargo test` and `cargo insta test --check` (or set `INSTA_UPDATE=unseen`) to fail if any snapshot is new or changed without being committed.

```bash
# CI: fail on any unapproved snapshots
INSTA_UPDATE=no cargo test
```

### When to Use Snapshots vs assert_eq!

| Situation | Prefer |
|-----------|--------|
| Short, simple values (`true`, `42`, `"ok"`) | `assert_eq!` |
| Multi-line or structured output | `assert_debug_snapshot!` |
| JSON/YAML serialization | `assert_json_snapshot!` / `assert_yaml_snapshot!` |
| Rendered error messages | `assert_snapshot!` |
| Compiler-error-style output | `assert_snapshot!` |

Related: `test-arrange-act-assert`, `test-proptest-properties`, `test-doctest-examples`
