---
name: rust-44-anti-patterns-2of2
description: Rust rules module 44: Anti-patterns (part 2 of 2). 7 rules, priority REFERENCE. Load on its own to review or write Rust code against this topic only. Rule prefixes: `anti-`
---

# Anti-patterns (part 2/2)

Priority: REFERENCE. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `anti-empty-catch` - Don't silently ignore errors
- `anti-over-abstraction` - Don't over-abstract with excessive generics
- `anti-premature-optimize` - Don't optimize before profiling
- `anti-type-erasure` - Don't use Box<dyn Trait> when impl Trait works
- `anti-format-hot-path` - Don't use format! in hot paths
- `anti-collect-intermediate` - Don't collect intermediate iterators
- `anti-stringly-typed` - Don't use strings where enums or newtypes would provide type safety

---

## anti-empty-catch

> Don't silently ignore errors

### Why It Matters

Empty error handling (`if let Err(_) = ...`, `let _ = result`, `.ok()`) silently discards errors. Failures go unnoticed, bugs hide, and debugging becomes impossible. Every error deserves acknowledgment—even if just logging.

### Bad

```rust
// Silently ignores errors
let _ = write_to_file(data);

// Discards error completely
if let Err(_) = send_notification() {
    // Nothing - error vanishes
}

// Converts Result to Option, losing error info
let value = risky_operation().ok();

// Match with empty arm
match database.save(record) {
    Ok(_) => println!("saved"),
    Err(_) => {}  // Silent failure
}

// Ignored in loop
for item in items {
    let _ = process(item);  // Failures unnoticed
}
```

### Good

```rust
// Log the error
if let Err(e) = write_to_file(data) {
    error!("failed to write file: {}", e);
}

// Propagate if possible
send_notification()?;

// Or handle explicitly
match send_notification() {
    Ok(_) => info!("notification sent"),
    Err(e) => warn!("notification failed: {}", e),
}

// Collect errors in batch operations
let (successes, failures): (Vec<_>, Vec<_>) = items
    .into_iter()
    .map(process)
    .partition(Result::is_ok);

if !failures.is_empty() {
    warn!("{} items failed to process", failures.len());
}

// Explicit documentation when ignoring
// Intentionally ignored: cleanup failure is not critical
let _ = cleanup_temp_file();  // Add comment explaining why
```

### Acceptable Ignoring (Documented)

```rust
// Close errors often ignored, but document it
// INTENTIONAL: TCP close errors are not actionable
let _ = stream.shutdown(Shutdown::Both);

// Mutex poisoning recovery
// INTENTIONAL: We'll reset the state anyway
let guard = mutex.lock().unwrap_or_else(|e| e.into_inner());
```

### Pattern: Collect and Report

```rust
fn process_batch(items: Vec<Item>) -> BatchResult {
    let mut errors = Vec::new();
    
    for item in items {
        if let Err(e) = process_item(&item) {
            errors.push((item.id, e));
        }
    }
    
    if errors.is_empty() {
        BatchResult::AllSucceeded
    } else {
        BatchResult::PartialFailure(errors)
    }
}
```

### Pattern: Best-Effort Operations

```rust
// Metrics/telemetry can fail without affecting main flow
fn report_metric(name: &str, value: f64) {
    if let Err(e) = metrics_client.record(name, value) {
        // Log but don't propagate - metrics are not critical
        debug!("failed to record metric {}: {}", name, e);
    }
}
```

### Clippy Lint

```toml
[lints.clippy]
let_underscore_drop = "warn"
ignored_unit_patterns = "warn"
```

### Decision Guide

| Situation | Action |
|-----------|--------|
| Critical operation | `?` or handle explicitly |
| Non-critical, debugging needed | Log the error |
| Truly ignorable (rare) | `let _ =` with comment |
| Batch operation | Collect errors, report |

Related: `err-result-over-panic`, `err-context-chain`, `anti-unwrap-abuse`

## anti-over-abstraction

> Don't over-abstract with excessive generics

### Why It Matters

Generics and traits are powerful but come at a cost: compile times, binary size, and cognitive load. Over-abstraction—making everything generic "for flexibility"—often adds complexity without benefit. Start concrete; generalize when you have real use cases.

### Bad

```rust
// Overly generic for a simple function
fn add<T, U, R>(a: T, b: U) -> R
where
    T: Into<R>,
    U: Into<R>,
    R: std::ops::Add<Output = R>,
{
    a.into() + b.into()
}

// Just call add(1, 2) - why make it this complex?

// Trait explosion
trait Readable {}
trait Writable {}
trait ReadWritable: Readable + Writable {}
trait AsyncReadable {}
trait AsyncWritable {}
trait AsyncReadWritable: AsyncReadable + AsyncWritable {}

// Abstract factory pattern (Java flashback)
trait Factory<T> {
    fn create(&self) -> T;
}
trait FactoryFactory<F: Factory<T>, T> {
    fn create_factory(&self) -> F;
}
```

### Good

```rust
// Concrete implementation - clear and simple
fn add_i32(a: i32, b: i32) -> i32 {
    a + b
}

// Generic when actually needed (e.g., library code)
fn add<T: std::ops::Add<Output = T>>(a: T, b: T) -> T {
    a + b
}

// Simple traits for actual polymorphism needs
trait Storage {
    fn save(&self, key: &str, value: &[u8]) -> Result<(), Error>;
    fn load(&self, key: &str) -> Result<Vec<u8>, Error>;
}

// Concrete types first
struct FileStorage { path: PathBuf }
struct MemoryStorage { data: HashMap<String, Vec<u8>> }
```

### Signs of Over-Abstraction

| Sign | Symptom |
|------|---------|
| Single implementation | Generic trait with only one impl |
| Type parameter soup | `T, U, V, W` everywhere |
| Marker traits | Traits with no methods |
| Deep trait bounds | `where T: A + B + C + D + E` |
| Phantom generics | Type parameters not used meaningfully |

### When to Generalize

Generalize when:
- You have 2+ concrete types that share behavior
- You're writing library code for public consumption
- Performance requires static dispatch
- The abstraction simplifies the API

Don't generalize when:
- You "might need it later" (YAGNI)
- Only one type will ever implement it
- It makes code harder to understand

### Rule of Three

Wait until you have three similar concrete implementations before abstracting:

```rust
// Version 1: Just FileStorage
struct FileStorage { /* ... */ }

// Version 2: Added MemoryStorage, similar interface
struct MemoryStorage { /* ... */ }

// Version 3: Now Redis too - time to abstract
trait Storage {
    fn save(&self, key: &str, value: &[u8]) -> Result<()>;
    fn load(&self, key: &str) -> Result<Vec<u8>>;
}
```

### Prefer Concrete Types in Private Code

```rust
// Internal function - concrete type is fine
fn process_orders(db: &PostgresDb, orders: Vec<Order>) { }

// Public API - might benefit from abstraction
pub fn process_orders<S: Storage>(storage: &S, orders: Vec<Order>) { }
```

Related: `type-generic-bounds`, `api-sealed-trait`, `anti-type-erasure`

## anti-premature-optimize

> Don't optimize before profiling

### Why It Matters

Premature optimization wastes time, complicates code, and often targets the wrong bottlenecks. Most code isn't performance-critical; the hot 10% matters. Profile first, then optimize the actual bottlenecks with data-driven decisions.

### Bad

```rust
// "Optimizing" without measurement
fn sum(data: &[i32]) -> i32 {
    // Using unsafe "for performance" without profiling
    unsafe {
        let mut sum = 0;
        for i in 0..data.len() {
            sum += *data.get_unchecked(i);
        }
        sum
    }
}

// Complex caching with no evidence it's needed
lazy_static! {
    static ref CACHE: RwLock<HashMap<String, Arc<Result>>> = 
        RwLock::new(HashMap::new());
}

// Hand-rolled data structures "for speed"
struct MyVec<T> {
    ptr: *mut T,
    len: usize,
    cap: usize,
}
```

### Good

```rust
// Simple, idiomatic - let compiler optimize
fn sum(data: &[i32]) -> i32 {
    data.iter().sum()
}

// Profile, then optimize if needed
fn sum_optimized(data: &[i32]) -> i32 {
    // After profiling showed this is a bottleneck,
    // we measured that manual SIMD gives 3x speedup
    #[cfg(target_arch = "x86_64")]
    {
        // a hand-written SIMD path would go here (measured ~3x faster);
        // fall back to the iterator version as a placeholder
        data.iter().sum()
    }
    #[cfg(not(target_arch = "x86_64"))]
    {
        data.iter().sum()
    }
}

// Use standard library - it's well-optimized
let cache: HashMap<String, Result> = HashMap::new();
```

### Profiling Workflow

```bash
# 1. Write correct code first
cargo build --release

# 2. Profile with real workloads
cargo flamegraph --bin my_app -- --real-args
# or
cargo bench

# 3. Identify hotspots (top 10% of time)

# 4. Measure before optimizing
# 5. Optimize ONE thing
# 6. Measure after - verify improvement
# 7. Repeat if still slow
```

### Optimization Principles

| Do | Don't |
|----|-------|
| Profile first | Guess at bottlenecks |
| Optimize hotspots | Optimize everything |
| Measure improvement | Assume it's faster |
| Keep it simple | Add complexity speculatively |
| Trust the compiler | Outsmart the compiler |

### When to Optimize

```rust
// AFTER profiling shows this is 40% of runtime
#[inline]
fn hot_function(data: &[u8]) -> u64 {
    // Optimized implementation justified by benchmarks
}

// Clear, measurable benefit documented
/// Pre-allocated buffer for repeated formatting.
/// Benchmarks show 3x speedup for >1000 calls/sec workloads.
struct FormatterPool {
    buffers: Vec<String>,
}
```

### Common Premature Optimizations

| Premature | Reality |
|-----------|---------|
| `#[inline(always)]` everywhere | Compiler usually knows better |
| `unsafe` for bounds check removal | Iterator does this safely |
| Custom allocator | Default is usually fine |
| Object pooling | Allocator is fast enough |
| Manual SIMD | Auto-vectorization works |

### Profile Tools

```bash
# Sampling profiler
perf record ./target/release/app && perf report

# Flamegraph
cargo install flamegraph
cargo flamegraph

# Criterion benchmarks
cargo bench

# Memory profiling
valgrind --tool=massif ./target/release/app
```

### Document Optimizations

```rust
/// Lookup table for fast character classification.
/// 
/// # Performance
/// 
/// Benchmarked with criterion (benchmarks/char_class.rs):
/// - Table lookup: 2.3ns/op
/// - Match statement: 8.7ns/op
/// 
/// Justified for hot path in parser (called 10M+ times).
static CHAR_CLASS: [CharClass; 256] = [/* ... */];
```

Related: `perf-profile-first`, `test-criterion-bench`, `opt-inline-small`

## anti-type-erasure

> Don't use Box<dyn Trait> when impl Trait works

### Why It Matters

`Box<dyn Trait>` (type erasure) introduces heap allocation and dynamic dispatch overhead. When you have a single concrete type or can use generics, `impl Trait` provides the same flexibility with zero overhead through monomorphization.

### Bad

```rust
// Unnecessary type erasure
fn get_iterator() -> Box<dyn Iterator<Item = i32>> {
    Box::new((0..10).map(|x| x * 2))
}

// Boxing for no reason
fn make_handler() -> Box<dyn Fn(i32) -> i32> {
    Box::new(|x| x + 1)
}

// Vec of boxed trait objects when one type would do
fn get_validators() -> Vec<Box<dyn Validator>> {
    vec![
        Box::new(LengthValidator),
        Box::new(RegexValidator),
    ]
}
```

### Good

```rust
// impl Trait - zero overhead, inlined
fn get_iterator() -> impl Iterator<Item = i32> {
    (0..10).map(|x| x * 2)
}

// impl Fn - no boxing
fn make_handler() -> impl Fn(i32) -> i32 {
    |x| x + 1
}

// When mixed types are genuinely needed, Box is OK
fn get_validators() -> Vec<Box<dyn Validator>> {
    // Actually different types at runtime - Box is appropriate
    config.validators.iter()
        .map(|v| v.create_validator())
        .collect()
}
```

### When to Use Box<dyn Trait>

Type erasure IS appropriate when:

```rust
// Heterogeneous collection of different types
let handlers: Vec<Box<dyn Handler>> = vec![
    Box::new(LogHandler),
    Box::new(MetricsHandler),
    Box::new(AuthHandler),
];

// Type cannot be known at compile time
fn create_from_config(config: &Config) -> Box<dyn Database> {
    match config.db_type {
        DbType::Postgres => Box::new(PostgresDb::new()),
        DbType::Sqlite => Box::new(SqliteDb::new()),
    }
}

// Recursive types
struct Node {
    value: i32,
    children: Vec<Box<dyn NodeTrait>>,
}

// Breaking cycles in complex ownership
struct EventLoop {
    handlers: Vec<Box<dyn EventHandler>>,
}
```

### Comparison

| Approach | Allocation | Dispatch | Binary Size |
|----------|------------|----------|-------------|
| `impl Trait` | Stack/inline | Static | Larger (monomorphization) |
| `Box<dyn Trait>` | Heap | Dynamic | Smaller |
| Generics `<T>` | Stack/inline | Static | Larger |

### impl Trait Positions

```rust
// Return position - caller doesn't need to know concrete type
fn process() -> impl Future<Output = Result> { }

// Argument position - like generics but simpler
fn handle(handler: impl Handler) { }

// Return-position impl Trait in traits (RPITIT) is stable since Rust 1.75
trait Processor {
    // Use impl Trait when callers don't need to name the return type:
    fn process(&self) -> impl Display;  // stable, idiomatic (Rust 1.75+)

    // Use an associated type when callers need to name or constrain the type:
    type Output: Display;
    fn process_named(&self) -> Self::Output;
}
```

### Pattern: Enum Instead of dyn

```rust
// Instead of Box<dyn Shape>
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Triangle { base: f64, height: f64 },
}

impl Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle { base, height } => 0.5 * base * height,
        }
    }
}
```

Related: `anti-over-abstraction`, `type-generic-bounds`, `mem-box-large-variant`, `trait-dyn-vs-generic`, `closure-static-vs-dyn`

## anti-format-hot-path

> Don't use format! in hot paths

### Why It Matters

`format!()` allocates a new `String` every call. In hot paths (loops, frequently called functions), this creates allocation churn that impacts performance. Pre-allocate, reuse buffers, or use `write!()` to an existing buffer.

### Bad

```rust
// format! in loop - allocates every iteration
fn log_events(events: &[Event]) {
    for event in events {
        let message = format!("[{}] {}: {}", event.level, event.source, event.message);
        logger.log(&message);
    }
}

// format! for building parts
fn build_url(base: &str, path: &str, params: &[(&str, &str)]) -> String {
    let mut url = format!("{}{}", base, path);
    for (key, value) in params {
        url = format!("{}{}={}&", url, key, value);  // New allocation each time
    }
    url
}

// format! for simple concatenation
fn greet(name: &str) -> String {
    format!("Hello, {}!", name)  // Fine for one-off, bad if called 1M times
}
```

### Good

```rust
use std::fmt::Write;

// Reuse buffer across iterations
fn log_events(events: &[Event]) {
    let mut buffer = String::with_capacity(256);
    for event in events {
        buffer.clear();
        write!(buffer, "[{}] {}: {}", event.level, event.source, event.message).unwrap();
        logger.log(&buffer);
    }
}

// Build incrementally in single buffer
fn build_url(base: &str, path: &str, params: &[(&str, &str)]) -> String {
    let mut url = String::with_capacity(base.len() + path.len() + params.len() * 20);
    url.push_str(base);
    url.push_str(path);
    for (key, value) in params {
        write!(url, "{}={}&", key, value).unwrap();
    }
    url
}

// For truly hot paths, avoid allocation entirely
fn greet_to_buf(name: &str, buffer: &mut String) {
    buffer.clear();
    buffer.push_str("Hello, ");
    buffer.push_str(name);
    buffer.push('!');
}
```

### Comparison

| Approach | Allocations | Performance |
|----------|-------------|-------------|
| `format!()` in loop | N | Slow |
| `write!()` to reused buffer | 1 | Fast |
| `push_str()` + `push()` | 1 | Fastest |
| Pre-sized `String::with_capacity()` | 1 (no realloc) | Fast |

### When format! Is Fine

```rust
// One-time initialization
let config_path = format!("{}/config.toml", home_dir);

// Error messages (not hot path)
return Err(format!("invalid input: {}", input));

// Debug output
println!("Debug: {:?}", value);
```

### Pattern: Formatter Buffer Pool

```rust
use std::cell::RefCell;
use std::fmt::Write; // for write! into the String buffer

thread_local! {
    static BUFFER: RefCell<String> = RefCell::new(String::with_capacity(256));
}

fn format_event(event: &Event) -> String {
    BUFFER.with(|buf| {
        let mut buf = buf.borrow_mut();
        buf.clear();
        write!(buf, "[{}] {}", event.level, event.message).unwrap();
        buf.clone()  // Still one allocation per call, but no parsing
    })
}
```

### Pattern: Display Implementation

```rust
use std::fmt::Write; // for the caller's write! into a String

struct Event {
    level: Level,
    message: String,
}

impl std::fmt::Display for Event {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{}] {}", self.level, self.message)
    }
}

// Caller controls allocation
let mut buf = String::new();
write!(buf, "{}", event)?;
```

### Clippy Lint

```toml
[lints.clippy]
format_in_format_args = "warn"
```

Related: `mem-avoid-format`, `mem-write-over-format`, `mem-reuse-collections`

## anti-collect-intermediate

> Don't collect intermediate iterators

### Why It Matters

Each `.collect()` allocates a new collection. Collecting intermediate results in a chain creates unnecessary allocations and prevents iterator fusion. Keep the chain lazy; collect only at the end.

### Bad

```rust
// Three allocations, three passes
fn process(data: Vec<i32>) -> Vec<i32> {
    let step1: Vec<_> = data.into_iter()
        .filter(|x| *x > 0)
        .collect();
    
    let step2: Vec<_> = step1.into_iter()
        .map(|x| x * 2)
        .collect();
    
    step2.into_iter()
        .filter(|x| *x < 100)
        .collect()
}

// Collecting just to check length
fn has_valid_items(items: &[Item]) -> bool {
    let valid: Vec<_> = items.iter()
        .filter(|i| i.is_valid())
        .collect();
    !valid.is_empty()
}

// Collecting to iterate again
fn sum_valid(items: &[Item]) -> i64 {
    let valid: Vec<_> = items.iter()
        .filter(|i| i.is_valid())
        .collect();
    valid.iter().map(|i| i.value).sum()
}
```

### Good

```rust
// Single allocation, single pass
fn process(data: Vec<i32>) -> Vec<i32> {
    data.into_iter()
        .filter(|x| *x > 0)
        .map(|x| x * 2)
        .filter(|x| *x < 100)
        .collect()
}

// No allocation - iterator short-circuits
fn has_valid_items(items: &[Item]) -> bool {
    items.iter().any(|i| i.is_valid())
}

// No intermediate allocation
fn sum_valid(items: &[Item]) -> i64 {
    items.iter()
        .filter(|i| i.is_valid())
        .map(|i| i.value)
        .sum()
}
```

### When Collection Is Needed

```rust
// Need to iterate twice
let valid: Vec<_> = items.iter()
    .filter(|i| i.is_valid())
    .collect();
let count = valid.len();
for item in &valid {
    process(item);
}

// Need to sort (requires concrete collection)
let mut sorted: Vec<_> = items.iter()
    .filter(|i| i.is_active())
    .collect();
sorted.sort_by_key(|i| i.priority);

// Need random access
let indexed: Vec<_> = items.iter().collect();
let middle = indexed.get(indexed.len() / 2);
```

### Iterator Methods That Avoid Collection

| Instead of Collecting to... | Use |
|-----------------------------|-----|
| Check if empty | `.any(|_| true)` or `.next().is_some()` |
| Check if any match | `.any(predicate)` |
| Check if all match | `.all(predicate)` |
| Count elements | `.count()` |
| Sum elements | `.sum()` |
| Find first | `.find(predicate)` |
| Get first | `.next()` |
| Get last | `.last()` |

### Pattern: Deferred Collection

```rust
// Return iterator, let caller collect if needed
fn valid_items(items: &[Item]) -> impl Iterator<Item = &Item> {
    items.iter().filter(|i| i.is_valid())
}

// Caller decides
let count = valid_items(&items).count();  // No collection
let vec: Vec<_> = valid_items(&items).collect();  // Collection when needed
```

### Comparison

| Pattern | Allocations | Passes |
|---------|-------------|--------|
| `.collect()` each step | N | N |
| Single chain, one `.collect()` | 1 | 1 |
| No collection (streaming) | 0 | 1 |

Related: `perf-collect-once`, `perf-iter-lazy`, `perf-iter-over-index`

## anti-stringly-typed

> Don't use strings where enums or newtypes would provide type safety

### Why It Matters

Strings are the most primitive way to represent data—they accept any value, provide no validation, and offer no IDE support. When you have a fixed set of valid values or a semantic type, use enums or newtypes. The compiler catches mistakes at compile time instead of runtime.

### Bad

```rust
fn process_order(status: &str, priority: &str) {
    // What are valid statuses? "pending"? "Pending"? "PENDING"?
    // What are valid priorities? "high"? "1"? "urgent"?
    match status {
        "pending" => { ... }
        "completed" => { ... }
        _ => panic!("unknown status"),  // Runtime error
    }
}

struct User {
    email: String,    // Any string, even "not an email"
    phone: String,    // Any string, even "hello"
    user_id: String,  // Could be confused with other string IDs
}

// Easy to make mistakes
process_order("complete", "high");  // Typo: "complete" vs "completed"
process_order("high", "pending");   // Swapped arguments - compiles!
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum OrderStatus {
    Pending,
    Processing,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Priority {
    Low,
    Medium,
    High,
    Critical,
}

fn process_order(status: OrderStatus, priority: Priority) {
    match status {
        OrderStatus::Pending => { ... }
        OrderStatus::Processing => { ... }
        OrderStatus::Completed => { ... }
        OrderStatus::Cancelled => { ... }
    }  // Exhaustive - compiler checks all cases
}

// Validated newtypes
struct Email(String);
struct PhoneNumber(String);
struct UserId(u64);

impl Email {
    pub fn new(s: &str) -> Result<Self, ValidationError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(ValidationError::InvalidEmail)
        }
    }
}

struct User {
    email: Email,       // Must be valid email
    phone: PhoneNumber, // Must be valid phone
    user_id: UserId,    // Can't confuse with other IDs
}

// Compile errors catch mistakes
process_order(OrderStatus::Completed, Priority::High);  // Clear and correct
process_order(Priority::High, OrderStatus::Pending);    // Compile error!
```

### Parsing Strings to Types

```rust
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
enum OrderStatus {
    Pending,
    Processing,
    Completed,
    Cancelled,
}

impl FromStr for OrderStatus {
    type Err = ParseError;
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "pending" => Ok(OrderStatus::Pending),
            "processing" => Ok(OrderStatus::Processing),
            "completed" => Ok(OrderStatus::Completed),
            "cancelled" | "canceled" => Ok(OrderStatus::Cancelled),
            _ => Err(ParseError::UnknownStatus(s.to_string())),
        }
    }
}

// Parse at boundary, use types internally
fn handle_request(status_str: &str) -> Result<(), Error> {
    let status: OrderStatus = status_str.parse()?;  // Validate once
    process_order(status);  // Type-safe from here
    Ok(())
}
```

### With Serde

```rust
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum Status {
    Pending,
    InProgress,
    Completed,
}

// JSON: {"status": "in_progress"}
// Deserialization validates automatically
```

### Error Messages

```rust
#[derive(Debug, Clone, Copy)]
enum Color {
    Red,
    Green,
    Blue,
}

impl std::fmt::Display for Color {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Color::Red => write!(f, "red"),
            Color::Green => write!(f, "green"),
            Color::Blue => write!(f, "blue"),
        }
    }
}

// Type-safe and displayable
println!("Selected color: {}", Color::Red);
```

Related: `api-newtype-safety`, `api-parse-dont-validate`, `type-newtype-ids`
