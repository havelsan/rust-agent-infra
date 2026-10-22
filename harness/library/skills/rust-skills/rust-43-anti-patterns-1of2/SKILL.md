---
name: rust-43-anti-patterns-1of2
description: Rust rules module 43: Anti-patterns (part 1 of 2). 8 rules, priority REFERENCE. Load on its own to review or write Rust code against this topic only. Rule prefixes: `anti-`
---

# Anti-patterns (part 1/2)

Priority: REFERENCE. 8 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `anti-unwrap-abuse` - Don't use `.unwrap()` in production code
- `anti-expect-lazy` - Don't use expect for recoverable errors
- `anti-clone-excessive` - Don't clone when borrowing works
- `anti-lock-across-await` - Don't hold locks across await points
- `anti-string-for-str` - Don't accept &String when &str works
- `anti-vec-for-slice` - Don't accept &Vec<T> when &[T] works
- `anti-index-over-iter` - Don't use indexing when iterators work
- `anti-panic-expected` - Don't panic on expected or recoverable errors

---

## anti-unwrap-abuse

> Don't use `.unwrap()` in production code

### Why It Matters

`.unwrap()` panics on `None` or `Err`, crashing your program. In production, this means lost data, failed requests, and unhappy users. It also makes debugging harder since panic messages often lack context.

### Bad

```rust
// Crashes if file doesn't exist
let content = std::fs::read_to_string("config.toml").unwrap();

// Crashes on invalid input
let num: i32 = user_input.parse().unwrap();

// Crashes if key missing
let value = map.get("key").unwrap();

// Crashes if channel closed
let msg = receiver.recv().unwrap();
```

### Good

```rust
// Propagate with ?
fn load_config() -> Result<Config, Error> {
    let content = std::fs::read_to_string("config.toml")?;
    Ok(toml::from_str(&content)?)
}

// Provide default
let num: i32 = user_input.parse().unwrap_or(0);

// Handle missing key
let value = map.get("key").ok_or(Error::MissingKey)?;

// Or use if-let
if let Some(value) = map.get("key") {
    process(value);
}

// Channel with proper handling
match receiver.recv() {
    Ok(msg) => handle(msg),
    Err(_) => break,  // Channel closed
}
```

### When unwrap() Is Acceptable

```rust
// 1. Tests - panics are expected failures
#[test]
fn test_parse() {
    let result = parse("valid").unwrap();  // OK in tests
    assert_eq!(result, expected);
}

// 2. Const/static initialization (compile-time guaranteed)
static REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^\d+$").unwrap()  // Known-valid pattern
});

// 3. After a check that guarantees success
if map.contains_key("key") {
    let value = map.get("key").unwrap();  // Just checked
}
// Better: use if-let or entry API instead

// 4. Truly impossible cases with proof comment
let last = vec.pop().unwrap();  
// OK only if you just checked !vec.is_empty()
// Better: use last() or pattern match
```

### Alternatives to unwrap()

```rust
// unwrap_or - provide default
let x = opt.unwrap_or(default);

// unwrap_or_default - use Default trait
let x = opt.unwrap_or_default();

// unwrap_or_else - compute default lazily
let x = opt.unwrap_or_else(|| expensive_default());

// ? operator - propagate errors
let x = opt.ok_or(Error::Missing)?;

// if let - handle Some/Ok case
if let Some(x) = opt {
    use_x(x);
}

// match - handle all cases
match opt {
    Some(x) => use_x(x),
    None => handle_none(),
}

// map - transform if present
let y = opt.map(|x| x + 1);

// and_then - chain fallible operations
let z = opt.and_then(|x| x.checked_add(1));
```

### expect() Is Slightly Better

```rust
// unwrap() - no context
let file = File::open(path).unwrap();
// Panics with: "called `Result::unwrap()` on an `Err` value: Os { code: 2, ... }"

// expect() - adds context
let file = File::open(path)
    .expect("config file should exist at startup");
// Panics with: "config file should exist at startup: Os { code: 2, ... }"

// But still use only for invariants, not error handling
```

### Clippy Lint

```rust
// Enable these lints to catch unwrap usage:
#![warn(clippy::unwrap_used)]
#![warn(clippy::expect_used)]  // Stricter

// Or per-function:
#[allow(clippy::unwrap_used)]
fn tests_only() { }
```

Related: `err-question-mark`, `err-result-over-panic`, `anti-expect-lazy`

## anti-expect-lazy

> Don't use expect for recoverable errors

### Why It Matters

`.expect()` panics with a custom message, but it's still a panic. Using it for errors that could reasonably occur in production (network failures, file not found, invalid input) crashes the program instead of handling the error gracefully.

Reserve `.expect()` for programming errors where panic is appropriate.

### Bad

```rust
// Network failures are expected - don't panic
let response = client.get(url).await.expect("failed to fetch");

// Files might not exist
let config = fs::read_to_string("config.toml").expect("config not found");

// User input can be invalid
let age: u32 = input.parse().expect("invalid age");

// Database queries can fail
let user = db.find_user(id).await.expect("user not found");
```

### Good

```rust
// Handle recoverable errors properly
let response = client.get(url).await
    .context("failed to fetch URL")?;

// Return error if file doesn't exist
let config = fs::read_to_string("config.toml")
    .context("failed to read config file")?;

// Validate and return error
let age: u32 = input.parse()
    .map_err(|_| Error::InvalidInput("age must be a number"))?;

// Handle missing data
let user = db.find_user(id).await?
    .ok_or(Error::NotFound("user"))?;
```

### When expect() Is Appropriate

Use `.expect()` for invariants that indicate bugs:

```rust
// Mutex poisoning indicates a bug elsewhere
let guard = mutex.lock().expect("mutex poisoned");

// Regex is known valid at compile time
let re = Regex::new(r"^\d{4}$").expect("invalid regex");

// Thread spawn failure is unrecoverable
let handle = thread::spawn(|| work()).expect("failed to spawn thread");

// Static data that must be valid
let config: Config = toml::from_str(EMBEDDED_CONFIG)
    .expect("embedded config is invalid");
```

### Pattern: expect() vs unwrap()

```rust
// unwrap: no context, hard to debug
let x = option.unwrap();

// expect: gives context, still panics
let x = option.expect("value should exist after validation");

// ?: proper error handling
let x = option.ok_or(Error::MissingValue)?;
```

### Decision Guide

| Situation | Use |
|-----------|-----|
| User input | `?` with error |
| File/network I/O | `?` with error |
| Database operations | `?` with error |
| Parsed constants | `.expect()` |
| Thread/mutex operations | `.expect()` |
| After validation check | `.expect()` with explanation |
| Never expected to fail | `.expect()` documenting invariant |

Related: `err-expect-bugs-only`, `err-no-unwrap-prod`, `anti-unwrap-abuse`

## anti-clone-excessive

> Don't clone when borrowing works

### Why It Matters

`.clone()` allocates memory and copies data. When you only need to read data, borrowing (`&T`) is free. Excessive cloning wastes memory, CPU cycles, and often indicates misunderstanding of ownership.

### Bad

```rust
// Cloning to pass to a function that only reads
fn print_name(name: String) {  // Takes ownership
    println!("{}", name);
}
let name = "Alice".to_string();
print_name(name.clone());  // Unnecessary clone
print_name(name);          // Could have just done this

// Cloning in a loop
for item in items.clone() {  // Clones entire Vec
    process(&item);
}

// Cloning for comparison
if input.clone() == expected {  // Pointless clone
    // ...
}

// Cloning struct fields
fn get_name(&self) -> String {
    self.name.clone()  // Caller might not need ownership
}
```

### Good

```rust
// Accept reference if only reading
fn print_name(name: &str) {
    println!("{}", name);
}
let name = "Alice".to_string();
print_name(&name);  // Borrow, no clone

// Iterate by reference
for item in &items {
    process(item);
}

// Compare by reference
if input == expected {
    // ...
}

// Return reference when possible
fn get_name(&self) -> &str {
    &self.name
}
```

### When to Clone

```rust
// Need owned data for async move
let name = name.clone();
tokio::spawn(async move {
    process(name).await;
});

// Storing in a new struct
struct Cache {
    data: String,
}
impl Cache {
    fn store(&mut self, data: &str) {
        self.data = data.to_string();  // Must own
    }
}

// Multiple owners (use Arc instead if frequent)
let shared = data.clone();
thread::spawn(move || use_data(shared));
```

### Alternatives to Clone

| Instead of | Use |
|------------|-----|
| `s.clone()` for reading | `&s` |
| `vec.clone()` for iteration | `&vec` or `vec.iter()` |
| `Clone` for shared ownership | `Arc<T>` |
| Clone in hot loop | Move outside loop |
| `s.to_string()` from `&str` | Accept `&str` if possible |

### Pattern: Clone on Write

```rust
use std::borrow::Cow;

fn process(input: Cow<str>) -> Cow<str> {
    if needs_modification(&input) {
        Cow::Owned(modify(&input))  // Clone only if needed
    } else {
        input  // No clone
    }
}
```

### Detecting Excessive Clones

```toml
# Cargo.toml
[lints.clippy]
clone_on_copy = "warn"
clone_on_ref_ptr = "warn"
redundant_clone = "warn"
```

Related: `own-borrow-over-clone`, `own-cow-conditional`, `own-arc-shared`

## anti-lock-across-await

> Don't hold locks across await points

### Why It Matters

Holding a `Mutex` or `RwLock` guard across an `.await` causes the lock to be held while the task is suspended. Other tasks waiting for the lock block indefinitely. With `std::sync::Mutex`, this is even worse—it can deadlock the entire runtime.

### Bad

```rust
use std::sync::Mutex;
use tokio::sync::Mutex as AsyncMutex;

// DEADLOCK RISK: std::sync::Mutex held across await
async fn bad_std_mutex(data: &Mutex<Vec<i32>>) {
    let mut guard = data.lock().unwrap();
    do_async_work().await;  // Lock held during await!
    guard.push(42);
}

// BLOCKS OTHER TASKS: tokio Mutex held across await
async fn bad_async_mutex(data: &AsyncMutex<Vec<i32>>) {
    let mut guard = data.lock().await;
    slow_network_call().await;  // Lock held for entire call!
    guard.push(42);
}
```

### Good

```rust
use std::sync::Mutex;
use tokio::sync::Mutex as AsyncMutex;

// Release lock before await
async fn good_approach(data: &Mutex<Vec<i32>>) {
    let value = {
        let guard = data.lock().unwrap();
        guard.last().copied()  // Extract what you need
    };  // Lock released here
    
    let result = do_async_work(value).await;
    
    {
        let mut guard = data.lock().unwrap();
        guard.push(result);
    }
}

// Minimize lock scope with async mutex
async fn good_async_mutex(data: &AsyncMutex<Vec<i32>>, item: i32) {
    // Quick lock, quick release
    data.lock().await.push(item);
    
    // Async work without lock
    let result = slow_network_call().await;
    
    // Quick lock again
    data.lock().await.push(result);
}
```

### Pattern: Clone Before Await

```rust
async fn process(data: &AsyncMutex<Config>) -> Result<()> {
    // Clone inside lock scope
    let config = data.lock().await.clone();
    
    // Now use config freely across awaits
    let result = fetch_data(&config.url).await?;
    process_result(&config, result).await?;
    
    Ok(())
}
```

### Pattern: Restructure to Avoid Lock

```rust
// Instead of locking a shared map
struct Service {
    data: AsyncMutex<HashMap<String, Data>>,
}

// Use channels or owned data
struct BetterService {
    // Each task owns its data via channels
    sender: mpsc::Sender<Request>,
}

impl BetterService {
    async fn request(&self, key: String) -> Data {
        let (tx, rx) = oneshot::channel();
        self.sender.send(Request { key, respond: tx }).await?;
        rx.await?
    }
}
```

### What Can Cross Await

| Type | Safe Across Await? |
|------|--------------------|
| `std::sync::Mutex` guard | **NO** - can deadlock |
| `std::sync::RwLock` guard | **NO** - can deadlock |
| `tokio::sync::Mutex` guard | Allowed but blocks tasks |
| `tokio::sync::RwLock` guard | Allowed but blocks tasks |
| Owned values | Yes |
| `Arc<T>` | Yes |
| References | Depends on lifetime |

### Detection

```toml
# Cargo.toml
[lints.clippy]
await_holding_lock = "deny"
await_holding_refcell_ref = "deny"
```

Related: `async-no-lock-await`, `async-clone-before-await`, `own-mutex-interior`

## anti-string-for-str

> Don't accept &String when &str works

### Why It Matters

`&String` is strictly less flexible than `&str`. A `&str` can be created from `String`, `&str`, literals, and slices. A `&String` requires exactly a `String`. This forces callers to allocate when they might not need to.

### Bad

```rust
// Forces callers to have a String
fn greet(name: &String) {
    println!("Hello, {}", name);
}

// Caller must allocate
greet(&"Alice".to_string());  // Unnecessary allocation
greet(&name);                 // Only works if name is String

// In struct
struct Config {
    name: String,
}

impl Config {
    fn set_name(&mut self, name: &String) {  // Too restrictive
        self.name = name.clone();
    }
}
```

### Good

```rust
// Accept &str - works with String, &str, literals
fn greet(name: &str) {
    println!("Hello, {}", name);
}

// All these work
greet("Alice");           // String literal
greet(&name);             // &String coerces to &str
greet(name.as_str());     // Explicit &str

// In struct
impl Config {
    fn set_name(&mut self, name: &str) {
        self.name = name.to_string();
    }
    
    // Or accept owned String if caller usually has one
    fn set_name_owned(&mut self, name: String) {
        self.name = name;
    }
    
    // Or be generic
    fn set_name_into(&mut self, name: impl Into<String>) {
        self.name = name.into();
    }
}
```

### Deref Coercion

`String` implements `Deref<Target = str>`, so `&String` automatically coerces to `&str`:

```rust
fn takes_str(s: &str) { }

let owned = String::from("hello");
takes_str(&owned);  // &String -> &str via Deref
```

### When to Accept &String

Rarely. Maybe if you need `String`-specific methods:

```rust
fn needs_capacity(s: &String) -> usize {
    s.capacity()  // Only String has capacity()
}
```

But usually you'd take `&str` and let the caller manage the `String`.

### Pattern: Flexible APIs

```rust
// Most flexible: accept anything that can become &str
fn process(input: impl AsRef<str>) {
    let s: &str = input.as_ref();
    // ...
}

process("literal");
process(String::from("owned"));
process(&some_string);
```

### Similar Anti-patterns

| Anti-pattern | Better |
|--------------|--------|
| `&String` | `&str` |
| `&Vec<T>` | `&[T]` |
| `&Box<T>` | `&T` |
| `&PathBuf` | `&Path` |
| `&OsString` | `&OsStr` |

### Clippy Detection

```toml
[lints.clippy]
ptr_arg = "warn"  # Catches &String, &Vec, &PathBuf
```

Related: `anti-vec-for-slice`, `own-slice-over-vec`, `api-impl-asref`

## anti-vec-for-slice

> Don't accept &Vec<T> when &[T] works

### Why It Matters

`&Vec<T>` is strictly less flexible than `&[T]`. A slice can be created from `Vec`, arrays, and other slice-like types. Accepting `&Vec<T>` forces callers to have exactly a `Vec`, preventing them from using arrays, slices, or other collections.

### Bad

```rust
// Forces callers to have a Vec
fn sum(numbers: &Vec<i32>) -> i32 {
    numbers.iter().sum()
}

// Caller must allocate
let arr = [1, 2, 3, 4, 5];
sum(&arr.to_vec());  // Unnecessary allocation

// Slice won't work
let slice: &[i32] = &[1, 2, 3];
// sum(slice);  // Error: expected &Vec<i32>
```

### Good

```rust
// Accept slice - works with Vec, arrays, slices
fn sum(numbers: &[i32]) -> i32 {
    numbers.iter().sum()
}

// All these work
sum(&[1, 2, 3, 4, 5]);        // Array
sum(&vec![1, 2, 3]);          // Vec
sum(&numbers[1..3]);          // Slice of slice
sum(numbers.as_slice());      // Explicit slice
```

### Deref Coercion

`Vec<T>` implements `Deref<Target = [T]>`, so `&Vec<T>` automatically coerces to `&[T]`:

```rust
fn takes_slice(s: &[i32]) { }

let vec = vec![1, 2, 3];
takes_slice(&vec);  // &Vec<i32> -> &[i32] via Deref
```

### Mutable Slices

Same applies to `&mut`:

```rust
// Bad
fn double(numbers: &mut Vec<i32>) {
    for n in numbers.iter_mut() {
        *n *= 2;
    }
}

// Good
fn double(numbers: &mut [i32]) {
    for n in numbers.iter_mut() {
        *n *= 2;
    }
}
```

### When to Accept &Vec<T>

Rarely. Only when you need Vec-specific operations:

```rust
fn needs_capacity(v: &Vec<i32>) -> usize {
    v.capacity()  // Only Vec has capacity
}

fn might_grow(v: &mut Vec<i32>) {
    v.push(42);  // Slice can't push
}
```

### Pattern: Accepting Multiple Types

```rust
// Accept anything that can be viewed as a slice
fn process<T: AsRef<[u8]>>(data: T) {
    let bytes: &[u8] = data.as_ref();
    // ...
}

process(&[1u8, 2, 3]);       // Array
process(vec![1u8, 2, 3]);    // Vec
process(&some_vec);          // &Vec
process(b"bytes");           // Byte string
```

### Similar Anti-patterns

| Anti-pattern | Better |
|--------------|--------|
| `&Vec<T>` | `&[T]` |
| `&String` | `&str` |
| `&PathBuf` | `&Path` |
| `&Box<T>` | `&T` |

### Clippy Detection

```toml
[lints.clippy]
ptr_arg = "warn"  # Catches &Vec, &String, &PathBuf
```

Related: `anti-string-for-str`, `own-slice-over-vec`, `api-impl-asref`

## anti-index-over-iter

> Don't use indexing when iterators work

### Why It Matters

Manual indexing (`for i in 0..len`) requires bounds checks on every access, prevents SIMD optimization, and introduces off-by-one error risks. Iterators eliminate these issues and are more idiomatic Rust.

### Bad

```rust
// Manual indexing - bounds checked every access
fn sum_squares(data: &[i32]) -> i64 {
    let mut result = 0i64;
    for i in 0..data.len() {
        result += (data[i] as i64) * (data[i] as i64);
    }
    result
}

// Index-based with multiple arrays
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len().min(b.len()) {
        sum += a[i] * b[i];
    }
    sum
}

// Mutation with indices
fn normalize(data: &mut [f64]) {
    let max = data.iter().cloned().fold(0.0, f64::max);
    for i in 0..data.len() {
        data[i] /= max;
    }
}
```

### Good

```rust
// Iterator - no bounds checks, SIMD-friendly
fn sum_squares(data: &[i32]) -> i64 {
    data.iter()
        .map(|&x| (x as i64) * (x as i64))
        .sum()
}

// Zip - handles length mismatch automatically
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(&x, &y)| x * y)
        .sum()
}

// Mutable iteration
fn normalize(data: &mut [f64]) {
    let max = data.iter().cloned().fold(0.0, f64::max);
    for x in data.iter_mut() {
        *x /= max;
    }
}
```

### When Indices Are Needed

Sometimes you genuinely need indices:

```rust
// Need index in output
for (i, item) in items.iter().enumerate() {
    println!("{}: {}", i, item);
}

// Non-sequential access
for i in (0..len).step_by(2) {
    swap(&mut data[i], &mut data[i + 1]);
}

// Multi-dimensional iteration
for i in 0..rows {
    for j in 0..cols {
        matrix[i][j] = i * cols + j;
    }
}
```

### Comparison

| Pattern | Bounds Checks | SIMD | Safety |
|---------|---------------|------|--------|
| `for i in 0..len { data[i] }` | Every access | Limited | Off-by-one risk |
| `for x in &data` | None | Good | Safe |
| `for x in data.iter()` | None | Good | Safe |
| `data.iter().enumerate()` | None | Good | Safe |

### Common Conversions

| Index Pattern | Iterator Pattern |
|---------------|------------------|
| `for i in 0..v.len()` | `for x in &v` |
| `v[0]` | `v.first()` |
| `v[v.len()-1]` | `v.last()` |
| `for i in 0..a.len() { a[i] + b[i] }` | `a.iter().zip(&b)` |
| `for i in 0..v.len() { v[i] *= 2 }` | `for x in &mut v { *x *= 2 }` |

### Performance Note

```rust
// Iterator version can auto-vectorize
let sum: i32 = data.iter().sum();

// Manual indexing prevents vectorization
let mut sum = 0;
for i in 0..data.len() {
    sum += data[i];
}
```

Related: `perf-iter-over-index`, `opt-bounds-check`, `perf-iter-lazy`

## anti-panic-expected

> Don't panic on expected or recoverable errors

### Why It Matters

Panics crash the program. They're for unrecoverable situations—bugs, corrupted state, invariant violations. Using panic for expected conditions (network failures, file not found, invalid input) makes programs fragile and forces callers to catch panics or die.

Use `Result` for recoverable errors.

### Bad

```rust
// Network failures are expected
fn fetch_data(url: &str) -> Data {
    let response = reqwest::blocking::get(url)
        .expect("network error");  // Crashes on timeout
    response.json().expect("invalid json")  // Crashes on bad response
}

// User input is often invalid
fn parse_config(input: &str) -> Config {
    toml::from_str(input).expect("invalid config")  // Crashes on typo
}

// Files may not exist
fn load_settings() -> Settings {
    let content = fs::read_to_string("settings.json")
        .expect("settings not found");  // Crashes if missing
    serde_json::from_str(&content).expect("invalid settings")
}

// Custom panic for validation
fn process_age(age: i32) {
    if age < 0 {
        panic!("age cannot be negative");  // Should return error
    }
}
```

### Good

```rust
// Return errors for expected failures
fn fetch_data(url: &str) -> Result<Data, FetchError> {
    let response = reqwest::blocking::get(url)
        .context("failed to connect")?;
    let data = response.json()
        .context("failed to parse response")?;
    Ok(data)
}

// Validate and return Result
fn parse_config(input: &str) -> Result<Config, ConfigError> {
    toml::from_str(input).map_err(ConfigError::Parse)
}

// Handle missing files gracefully
fn load_settings() -> Result<Settings, SettingsError> {
    let content = fs::read_to_string("settings.json")?;
    let settings = serde_json::from_str(&content)?;
    Ok(settings)
}

// Return error for validation failure
fn process_age(age: i32) -> Result<(), ValidationError> {
    if age < 0 {
        return Err(ValidationError::NegativeAge);
    }
    Ok(())
}
```

### When to Panic

Panic IS appropriate for:

```rust
// Bug detection - invariant violated
fn get_unchecked(&self, index: usize) -> &T {
    assert!(index < self.len(), "index out of bounds - this is a bug");
    unsafe { self.data.get_unchecked(index) }
}

// Unrecoverable state
fn init() {
    if !CAN_PROCEED {
        panic!("system requirements not met");
    }
}

// Tests
#[test]
fn test_fails() {
    panic!("expected panic in test");
}
```

### Decision Guide

| Condition | Action |
|-----------|--------|
| Invalid user input | Return `Err` |
| Network failure | Return `Err` |
| File not found | Return `Err` |
| Malformed data | Return `Err` |
| Bug/impossible state | `panic!` or `unreachable!` |
| Failed assertion in test | `panic!` |
| Unrecoverable init failure | `panic!` |

### Anti-pattern: panic! for Control Flow

```rust
// BAD: Using panic for control flow
fn find_or_die(items: &[Item], id: u64) -> &Item {
    items.iter()
        .find(|i| i.id == id)
        .unwrap_or_else(|| panic!("item {} not found", id))
}

// GOOD: Return Option or Result
fn find(items: &[Item], id: u64) -> Option<&Item> {
    items.iter().find(|i| i.id == id)
}
```

Related: `err-result-over-panic`, `anti-unwrap-abuse`, `err-expect-bugs-only`
