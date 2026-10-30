---
name: rust-17-compiler-opt-1of2
description: Rust rules module 17: Compiler Optimization (part 1 of 2). 6 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `opt-`
---

# Compiler Optimization (part 1/2)

Priority: HIGH. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `opt-inline-small` - Use `#[inline]` for small hot functions
- `opt-inline-always-rare` - Use `#[inline(always)]` sparingly—only for critical hot paths proven by profiling
- `opt-inline-never-cold` - Use `#[inline(never)]` and `#[cold]` for error paths and rarely-executed code
- `opt-cold-unlikely` - Mark unlikely code paths with `#[cold]` to help compiler optimization
- `opt-likely-hint` - Use code structure to hint at likely branches; use intrinsics on nightly
- `opt-lto-release` - Enable LTO in release builds

---

## opt-inline-small

> Use `#[inline]` for small hot functions

### Why It Matters

Function call overhead (stack frame setup, register saves, jumps) can dominate small functions. Inlining eliminates this overhead and enables further optimizations by the compiler. The compiler often inlines automatically, but hints help for cross-crate calls.

### Bad

```rust
// Small hot function without inline hint
// May not be inlined across crate boundaries
fn is_ascii_digit(b: u8) -> bool {
    b >= b'0' && b <= b'9'
}

// Called millions of times
for byte in data {
    if is_ascii_digit(*byte) {  // Function call overhead
        count += 1;
    }
}
```

### Good

```rust
#[inline]
fn is_ascii_digit(b: u8) -> bool {
    b >= b'0' && b <= b'9'
}

// Now the compiler will inline this
for byte in data {
    if is_ascii_digit(*byte) {  // Inlined, no call overhead
        count += 1;
    }
}
```

### Inline Attributes

```rust
// No attribute - compiler decides (usually good for same-crate)
fn auto_decide() { }

// Suggest inlining - helps cross-crate
#[inline]
fn suggest_inline() { }

// Strongly suggest inlining - almost always inlined
#[inline(always)]
fn force_inline() { }

// Strongly suggest NOT inlining - for large/cold code
#[inline(never)]
fn prevent_inline() { }
```

### When to Use Each

```rust
// #[inline] - Small functions, especially in libraries
#[inline]
pub fn len(&self) -> usize {
    self.inner.len()
}

// #[inline(always)] - Critical hot path, verified by profiling
#[inline(always)]
fn hot_inner_loop_helper(x: u32) -> u32 {
    x.wrapping_mul(0x9E3779B9)
}

// #[inline(never)] - Error handlers, cold paths
#[inline(never)]
fn handle_error(err: Error) -> ! {
    eprintln!("Fatal: {}", err);
    std::process::exit(1);
}

// No attribute - large functions, infrequent calls
fn complex_processing(data: &mut Data) {
    // Many lines of code...
}
```

### Evidence from ripgrep

```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/printer/src/standard.rs

#[inline(always)]
fn write_prelude(
    &self,
    absolute_byte_offset: u64,
    line_number: Option<u64>,
    column: Option<u64>,
) -> io::Result<()> {
    // Hot path in printing matches
}

#[inline(always)]
fn write_line(&self, line: &[u8]) -> io::Result<()> {
    // Called for every line
}
```

### Generic Functions

```rust
// Generic functions are already candidates for per-monomorphization inlining
// But #[inline] helps ensure it across crates

#[inline]
pub fn min<T: Ord>(a: T, b: T) -> T {
    if a < b { a } else { b }
}
```

### Cautions

```rust
// DON'T inline large functions - hurts instruction cache
#[inline(always)]  // BAD for large function
fn large_complex_function(data: &mut [u8]) {
    // 100+ lines of code
    // Inlining bloats every call site
}

// DON'T assume inlining always helps - measure!
// Sometimes the compiler makes better decisions

// Cross-crate inlining requires #[inline] on each function
// Without LTO, a function body is not available to other crates unless
// it carries #[inline]. Within a single crate (or with LTO enabled),
// the compiler may still inline `inner` transitively after inlining
// `outer`, but this is not guaranteed — verify hot code with assembly.
#[inline]
fn outer() {
    inner();
}

fn inner() { }  // May not be inlined at outer's call sites across crate boundaries without #[inline]
```

### Verifying Inlining

```bash
# Check if function was inlined using Cachegrind
# Non-inlined functions show entry/exit counts

# Or examine assembly
cargo rustc --release -- --emit=asm
# Look for call instructions vs inlined code
```

Related: `opt-inline-always-rare`, `opt-inline-never-cold`, `opt-cold-unlikely`, `opt-lto-release`

## opt-inline-always-rare

> Use `#[inline(always)]` sparingly—only for critical hot paths proven by profiling

### Why It Matters

`#[inline(always)]` forces the compiler to inline a function regardless of heuristics. Overuse increases binary size, hurts instruction cache, and can slow down code. The compiler is usually smarter about inlining than humans. Reserve this for measured hot paths where benchmarks prove a benefit.

### Bad

```rust
// Annotating everything - trusting intuition over data
#[inline(always)]
pub fn get_name(&self) -> &str {
    &self.name
}

#[inline(always)]
pub fn calculate_tax(amount: f64) -> f64 {
    amount * 0.1
}

#[inline(always)]
fn helper(x: i32) -> i32 {
    x + 1
}

// Result: bloated binary, poor cache utilization
```

### Good

```rust
// Let compiler decide for most functions
pub fn get_name(&self) -> &str {
    &self.name
}

pub fn calculate_tax(amount: f64) -> f64 {
    amount * 0.1
}

// Only force inline for proven hot paths
impl Hasher for MyHasher {
    // Hasher::write is called millions of times in tight loops
    // Profiling showed 15% improvement from forced inlining
    #[inline(always)]
    fn write(&mut self, bytes: &[u8]) {
        // Very small, very hot
        self.state = self.state.wrapping_add(bytes.len() as u64);
    }
}
```

### When #[inline(always)] Helps

```rust
// ✅ Tiny functions in hot inner loops
#[inline(always)]
fn fast_hash(a: u64, b: u64) -> u64 {
    a.wrapping_mul(b).wrapping_add(a)
}

// ✅ Generic functions that benefit from monomorphization
#[inline(always)]
fn swap<T>(a: &mut T, b: &mut T) {
    std::mem::swap(a, b);
}

// ✅ Iterator adapters and closures
#[inline(always)]
fn apply<T, F: Fn(T) -> T>(f: F, x: T) -> T {
    f(x)
}

// ✅ SIMD/vectorization helpers
#[inline(always)]
fn add_simd(a: &[f32], b: &[f32], out: &mut [f32]) {
    // ...
}
```

### Inline Variants

```rust
// #[inline] - hint to inline, compiler may ignore
#[inline]
fn suggested_inline(x: i32) -> i32 { x + 1 }

// #[inline(always)] - force inline (almost always)
#[inline(always)]
fn force_inline(x: i32) -> i32 { x + 1 }

// #[inline(never)] - prevent inlining (for profiling, code size)
#[inline(never)]
fn no_inline(x: i32) -> i32 { x + 1 }

// No annotation - compiler decides based on heuristics
fn compiler_decides(x: i32) -> i32 { x + 1 }
```

### Measuring Inline Impact

```rust
// Use criterion to benchmark
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_with_inline(c: &mut Criterion) {
    c.bench_function("hot_path_inline", |b| {
        b.iter(|| hot_loop())
    });
}

// Compare binary sizes
// cargo bloat --release --crates

// Check if function was inlined
// cargo asm --rust my_crate::hot_function
```

### Generic Functions

```rust
// Generic functions across crate boundaries often need #[inline]
// Because the generic code is compiled in the calling crate

// In library crate:
#[inline]  // Allow inlining in downstream crates
pub fn generic_function<T: Display>(x: T) {
    println!("{}", x);
}

// Without #[inline], the generic function can't be inlined
// across crate boundaries even if beneficial
```

Related: `opt-inline-small`, `opt-inline-never-cold`, `perf-profile-first`

## opt-inline-never-cold

> Use `#[inline(never)]` and `#[cold]` for error paths and rarely-executed code

### Why It Matters

Inlining error handling code into hot paths wastes instruction cache space and can prevent other optimizations. `#[inline(never)]` keeps cold code out of the hot path. `#[cold]` tells the compiler this branch is unlikely, enabling better branch prediction hints and code layout.

### Bad

```rust
fn process_data(data: &[u8]) -> Result<Output, Error> {
    if data.is_empty() {
        // Error path inlined into hot function
        return Err(Error::Empty {
            context: format!("Expected data, got empty slice"),
            suggestions: vec!["Check input", "Validate before calling"],
        });
    }
    
    // Hot path - now polluted with error construction code
    do_processing(data)
}
```

### Good

```rust
fn process_data(data: &[u8]) -> Result<Output, Error> {
    if data.is_empty() {
        return Err(empty_data_error());  // Cold path stays small
    }
    
    do_processing(data)
}

#[cold]
#[inline(never)]
fn empty_data_error() -> Error {
    Error::Empty {
        context: format!("Expected data, got empty slice"),
        suggestions: vec!["Check input", "Validate before calling"],
    }
}
```

### #[cold] for Unlikely Branches

```rust
fn parse_value(input: &str) -> Result<i32, ParseError> {
    match input.parse() {
        Ok(n) => Ok(n),
        Err(e) => cold_parse_error(input, e),
    }
}

#[cold]
fn cold_parse_error(input: &str, e: std::num::ParseIntError) -> Result<i32, ParseError> {
    Err(ParseError {
        input: input.to_string(),
        source: e,
    })
}
```

### Panic Paths

```rust
fn get_index(&self, idx: usize) -> &T {
    if idx >= self.len {
        cold_out_of_bounds(idx, self.len);
    }
    unsafe { self.ptr.add(idx).as_ref().unwrap() }
}

#[cold]
#[inline(never)]
fn cold_out_of_bounds(idx: usize, len: usize) -> ! {
    panic!("index {} out of bounds for length {}", idx, len);
}
```

### Error Construction Functions

```rust
// Keep error construction out of hot path
impl MyError {
    #[cold]
    pub fn io_error(source: std::io::Error, path: &Path) -> Self {
        MyError::Io {
            source,
            path: path.to_path_buf(),
            context: get_context(),
        }
    }
    
    #[cold]
    pub fn validation_error(msg: &str, field: &str) -> Self {
        MyError::Validation {
            message: msg.to_string(),
            field: field.to_string(),
        }
    }
}

fn read_config(path: &Path) -> Result<Config, MyError> {
    std::fs::read_to_string(path)
        .map_err(|e| MyError::io_error(e, path))?
        .parse()
        .map_err(|e| MyError::parse_error(e))
}
```

### likely/unlikely Hints

```rust
// Nightly: std::hint likely/unlikely branch hints (still unstable as of Rust 1.96)
// (std::hint::cold_path() is stable since 1.95 for marking the rare branch)
#![feature(likely_unlikely)]
use std::hint::{likely, unlikely};

fn process(data: Option<&Data>) -> Result<Output, Error> {
    if unlikely(data.is_none()) {
        return cold_none_error();
    }
    
    let data = data.unwrap();
    
    if likely(data.is_valid()) {
        fast_process(data)
    } else {
        slow_validate_and_process(data)
    }
}

// Stable alternative: structure code so hot path is "fall through"
fn process(data: Option<&Data>) -> Result<Output, Error> {
    let data = match data {
        Some(d) => d,
        None => return cold_none_error(),  // Early return = unlikely hint
    };
    
    // Compiler assumes code after early returns is "hot"
    fast_process(data)
}
```

### Pattern: Extract Cold Code

```rust
// Before: cold code inline
fn hot_function(x: i32) -> i32 {
    if x < 0 {
        log::error!("Negative value: {}", x);
        eprintln!("Debug info: {:?}", std::backtrace::Backtrace::capture());
        return 0;
    }
    x * 2
}

// After: cold code extracted
fn hot_function(x: i32) -> i32 {
    if x < 0 {
        return handle_negative(x);
    }
    x * 2
}

#[cold]
#[inline(never)]
fn handle_negative(x: i32) -> i32 {
    log::error!("Negative value: {}", x);
    eprintln!("Debug info: {:?}", std::backtrace::Backtrace::capture());
    0
}
```

Related: `opt-inline-small`, `opt-inline-always-rare`, `err-result-over-panic`

## opt-cold-unlikely

> Mark unlikely code paths with `#[cold]` to help compiler optimization

### Why It Matters

The `#[cold]` attribute tells the compiler that a function is rarely called. The compiler uses this to optimize code layout—keeping cold code away from hot code improves instruction cache utilization. Combined with branch layout optimization, this can measurably improve performance.

### Bad

```rust
// All branches treated equally
fn validate(input: &str) -> Result<Data, ValidationError> {
    if input.is_empty() {
        return Err(ValidationError::Empty);  // Rare
    }
    
    if input.len() > 1000 {
        return Err(ValidationError::TooLong);  // Rare  
    }
    
    if !input.is_ascii() {
        return Err(ValidationError::NonAscii);  // Rare
    }
    
    // This is the common case
    Ok(parse_data(input))
}
```

### Good

```rust
fn validate(input: &str) -> Result<Data, ValidationError> {
    if input.is_empty() {
        return cold_empty_error();
    }
    
    if input.len() > 1000 {
        return cold_too_long_error();
    }
    
    if !input.is_ascii() {
        return cold_non_ascii_error();
    }
    
    Ok(parse_data(input))
}

#[cold]
fn cold_empty_error() -> Result<Data, ValidationError> {
    Err(ValidationError::Empty)
}

#[cold]
fn cold_too_long_error() -> Result<Data, ValidationError> {
    Err(ValidationError::TooLong)
}

#[cold]
fn cold_non_ascii_error() -> Result<Data, ValidationError> {
    Err(ValidationError::NonAscii)
}
```

### What #[cold] Does

1. **Code placement**: Cold functions are placed in separate code sections, away from hot code
2. **Branch prediction**: Compiler generates branch hints favoring the non-cold path
3. **Inlining decisions**: Cold functions are not inlined into hot paths
4. **Optimization budget**: Compiler spends less effort optimizing cold code

### Common Cold Patterns

```rust
// Error handling
#[cold]
fn handle_error<E: std::fmt::Display>(e: E) -> ! {
    eprintln!("Fatal error: {}", e);
    std::process::exit(1);
}

// Logging rare events
#[cold]
fn log_rare_event(event: &Event) {
    log::warn!("Rare event occurred: {:?}", event);
}

// Fallback paths
#[cold]
fn slow_fallback(data: &Data) -> Output {
    // This path should rarely be taken
    compute_slowly(data)
}

// Panic handlers
#[cold]
fn panic_invalid_state(state: &State) -> ! {
    panic!("Invalid state: {:?}", state);
}
```

### Assertions and Invariants

```rust
fn get_unchecked(&self, index: usize) -> &T {
    if index >= self.len {
        cold_bounds_panic(index, self.len);
    }
    unsafe { &*self.ptr.add(index) }
}

#[cold]
#[inline(never)]
fn cold_bounds_panic(index: usize, len: usize) -> ! {
    panic!("index out of bounds: the len is {} but the index is {}", len, index);
}
```

### Combining with #[inline(never)]

```rust
// Usually combine both for maximum effect
#[cold]
#[inline(never)]
fn error_path() -> Error {
    // Complex error construction stays out of hot code
    Error {
        backtrace: Backtrace::capture(),
        context: gather_context(),
    }
}
```

### Measuring Impact

```rust
// Check code layout with objdump
// objdump -d target/release/binary | less

// Look for .cold sections
// nm target/release/binary | grep cold

// Profile to verify improvement
// perf stat -e cache-misses,cache-references ./binary
```

Related: `opt-inline-never-cold`, `opt-likely-hint`, `err-result-over-panic`

## opt-likely-hint

> Use code structure to hint at likely branches; use intrinsics on nightly

### Why It Matters

Modern CPUs predict branches to speculatively execute code. Mispredictions cause pipeline stalls (10-20 cycles). Helping the compiler understand which branches are likely allows it to generate optimal code layout and branch hints, improving performance in hot paths.

### Stable Rust: Code Structure Hints

```rust
// Pattern 1: Early returns for unlikely cases
fn process(data: Option<&Data>) -> i32 {
    // Compiler assumes early return is "unlikely"
    let data = match data {
        None => return 0,  // Unlikely
        Some(d) => d,
    };
    
    // Hot path continues here
    complex_processing(data)
}

// Pattern 2: if-else ordering
fn calculate(x: i32) -> i32 {
    if x >= 0 {
        // Put likely case in "if" branch
        x * 2
    } else {
        // Unlikely case in "else"
        handle_negative(x)
    }
}

// Pattern 3: Cold function extraction
fn hot_path(data: &[u8]) -> Result<(), Error> {
    if data.is_empty() {
        return cold_empty_error();  // Extracted = unlikely
    }
    
    process_fast(data)
}

#[cold]
fn cold_empty_error() -> Result<(), Error> {
    Err(Error::EmptyInput)
}
```

### Nightly: std::hint

```rust
// Requires nightly; still unstable as of Rust 1.96
#![feature(likely_unlikely)]
use std::hint::{likely, unlikely};

fn process(data: &Data) -> i32 {
    if unlikely(data.is_corrupted()) {
        return handle_corruption(data);
    }
    
    if likely(data.is_cached()) {
        return fast_cached_path(data);
    }
    
    slow_uncached_path(data)
}
```

### Boolean Likely Wrapper (Nightly)

```rust
// Requires nightly; still unstable as of Rust 1.96
#![feature(likely_unlikely)]

#[inline(always)]
fn likely(b: bool) -> bool {
    std::hint::likely(b)
}

#[inline(always)]
fn unlikely(b: bool) -> bool {
    std::hint::unlikely(b)
}

// Usage
if likely(x > 0) {
    hot_path(x)
} else {
    cold_path(x)
}
```

### Stable: std::hint::cold_path

`std::hint::cold_path()` (stable since Rust 1.95) marks the enclosing code path as unlikely so the optimizer can deprioritize it — a stable substitute for nightly `unlikely`. Call it inside the rarely-taken branch:

```rust
fn process(data: &Data) -> i32 {
    if data.is_corrupted() {
        std::hint::cold_path(); // tell the optimizer this branch is rare
        return handle_corruption(data);
    }
    fast_path(data)
}
```

### Stable: likely-stable Crate

```rust
use likely_stable::{likely, unlikely};

fn check(value: i32) -> bool {
    if unlikely(value < 0) {
        handle_negative()
    } else if likely(value < 1000) {
        handle_common()
    } else {
        handle_large()
    }
}
```

### Loop Optimization

```rust
fn search(data: &[i32], target: i32) -> Option<usize> {
    for (i, &item) in data.iter().enumerate() {
        // Assume most iterations DON'T find the target
        if unlikely(item == target) {
            return Some(i);
        }
    }
    None
}

// Alternative: structure for likely case
fn search_common(data: &[i32], target: i32) -> Option<usize> {
    // If target is usually found
    for (i, &item) in data.iter().enumerate() {
        if likely(item == target) {
            return Some(i);
        }
    }
    None
}
```

### Match Arm Ordering

```rust
// Put most common variants first
fn process_message(msg: Message) {
    match msg {
        // Most common - listed first
        Message::Data(d) => handle_data(d),
        Message::Heartbeat => (), // Second most common
        
        // Rare cases last
        Message::Error(e) => handle_error(e),
        Message::Shutdown => shutdown(),
    }
}
```

### Benchmark-Driven Hints

```rust
// Profile first to know which branches are actually likely!
fn speculative(x: i32) -> i32 {
    // DON'T GUESS - measure with profiling
    // perf record / perf report
    // cargo flamegraph
    
    if x > threshold {  // Is this actually common?
        path_a(x)
    } else {
        path_b(x)
    }
}
```

Related: `opt-cold-unlikely`, `opt-inline-never-cold`, `perf-profile-first`

## opt-lto-release

> Enable LTO in release builds

### Why It Matters

Link-Time Optimization (LTO) enables optimizations across crate boundaries that aren't possible during normal compilation. This includes cross-crate inlining, dead code elimination, and devirtualization. Typically provides 5-20% performance improvement.

### Bad

```toml
# Cargo.toml - default release profile
[profile.release]
opt-level = 3
# No LTO = missed optimization opportunities
```

### Good

```toml
# Cargo.toml - optimized release profile
[profile.release]
opt-level = 3
lto = "fat"          # Maximum optimization
codegen-units = 1    # Better optimization (single codegen unit)
panic = "abort"      # Smaller binary, no unwind tables
strip = true         # Remove symbols for smaller binary
```

### LTO Options Explained

```toml
# No LTO (default)
lto = false

# Thin LTO - fast compilation, most benefits
lto = "thin"

# Fat LTO - slowest compilation, maximum optimization
lto = "fat"
# Equivalent to:
lto = true

# Thin-local - LTO within each crate only
lto = "off"
```

### Trade-offs

| Setting | Compile Time | Binary Size | Performance |
|---------|--------------|-------------|-------------|
| `lto = false` | Fast | Larger | Baseline |
| `lto = "thin"` | Medium | Smaller | +5-15% |
| `lto = "fat"` | Slow | Smallest | +10-20% |

### Evidence from Production

Many production crates enable fat LTO and `codegen-units = 1` in their release
profiles for maximum performance. For example, ripgrep ships a `release-lto`
profile (see the Cargo Book for profile documentation:
<https://doc.rust-lang.org/cargo/reference/profiles.html>):

```toml
# A common pattern in performance-critical crates
[profile.release]
overflow-checks = true
lto = "fat"
codegen-units = 1

# Named profile for explicit LTO builds (e.g. ripgrep's release-lto)
[profile.release-lto]
inherits = "release"
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
strip = "symbols"
```

### Complete Optimized Profile

```toml
[profile.release]
opt-level = 3        # Maximum optimization
lto = "fat"          # Link-time optimization
codegen-units = 1    # Single codegen unit for better optimization
panic = "abort"      # Remove panic unwinding code
strip = true         # Strip symbols
debug = false        # No debug info

# For benchmarking (need some debug info for profiling)
[profile.bench]
inherits = "release"
debug = true
strip = false

# Fast dev builds with optimized dependencies
[profile.dev]
opt-level = 0
debug = true

[profile.dev.package."*"]
opt-level = 3        # Optimize dependencies even in dev
```

### When to Use Each

| Situation | LTO Setting |
|-----------|-------------|
| Development | `false` (fast compiles) |
| CI builds | `"thin"` (balance) |
| Release binaries | `"fat"` (max perf) |
| Libraries (crates.io) | `false` (users choose) |

### Measuring Impact

```bash
# Build without LTO
cargo build --release
hyperfine ./target/release/myapp

# Build with LTO
# (after adding lto = "fat" to Cargo.toml)
cargo build --release
hyperfine ./target/release/myapp

# Compare binary sizes
ls -la target/release/myapp
```

Related: `opt-codegen-units`, `opt-pgo-profile`, `perf-release-profile`
