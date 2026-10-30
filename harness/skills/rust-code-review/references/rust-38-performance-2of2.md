---
name: rust-38-performance-2of2
description: Rust rules module 38: Performance Patterns (part 2 of 2). 6 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `perf-`
---

# Performance Patterns (part 2/2)

Priority: MEDIUM. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `perf-collect-into` - Use collect_into for reusing containers
- `perf-black-box-bench` - Use black_box in benchmarks
- `perf-release-profile` - Optimize release profile settings
- `perf-profile-first` - Profile before optimizing
- `perf-ahash` - Use a faster hasher (`ahash` / `FxHashMap`) when DoS resistance is not needed
- `perf-io-buffering` - Wrap `Read`/`Write` in `BufReader`/`BufWriter` for many small operations

---

## perf-collect-into

> Use collect_into for reusing containers

### Why It Matters

`collect_into()` allows collecting iterator results into an existing collection, reusing its allocation. This avoids the allocation that `collect()` would make for a new collection.

> **Note:** `collect_into` is currently **nightly-only** (requires `#![feature(iter_collect_into)]`, tracking issue [#94780](https://github.com/rust-lang/rust/issues/94780)). On stable Rust, use `extend()` instead — see the Stable Alternative section below.

### Bad

```rust
// Allocates new Vec each time
fn process_batches(batches: Vec<Vec<i32>>) -> Vec<Vec<i32>> {
    batches.into_iter()
        .map(|batch| {
            batch.into_iter()
                .filter(|x| *x > 0)
                .collect::<Vec<_>>()  // New allocation per batch
        })
        .collect()
}

// Can't reuse cleared buffer
fn filter_loop(data: &[Vec<i32>]) {
    for batch in data {
        let filtered: Vec<_> = batch.iter()
            .filter(|&&x| x > 0)
            .copied()
            .collect();  // New allocation each iteration
        process(&filtered);
    }
}
```

### Good (Stable: extend)

```rust
// Stable approach: reuse buffer with extend
fn filter_loop(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();  // Keep allocation
        buffer.extend(
            batch.iter()
                .filter(|&&x| x > 0)
                .copied()
        );
        process(&buffer);
    }
}
```

### Nightly: collect_into

```rust
#![feature(iter_collect_into)]

// Reuse buffer with collect_into (nightly only)
fn filter_loop_nightly(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();  // Keep allocation
        batch.iter()
            .filter(|&&x| x > 0)
            .copied()
            .collect_into(&mut buffer);
        process(&buffer);
    }
}

```

### Stable Alternative: extend

On stable Rust, `extend()` is equivalent and idiomatic:

```rust
fn reuse_buffer(data: &[Vec<i32>]) {
    let mut buffer = Vec::new();
    
    for batch in data {
        buffer.clear();
        buffer.extend(batch.iter().filter(|&&x| x > 0).copied());
        process(&buffer);
    }
}
```

### Pattern: Transform and Reuse

```rust
fn transform_batches(batches: &[Vec<RawData>]) -> Vec<ProcessedData> {
    let mut temp = Vec::new();
    let mut all_results = Vec::new();
    
    for batch in batches {
        temp.clear();
        batch.iter()
            .map(ProcessedData::from)
            .collect_into(&mut temp);
        
        // Process temp, append to results
        all_results.extend(temp.drain(..).filter(|p| p.is_valid()));
    }
    
    all_results
}
```

### Supported Collections

`collect_into()` works with any type implementing `Extend`:

```rust
use std::collections::{HashSet, HashMap, VecDeque};

let mut vec = Vec::new();
let mut set = HashSet::new();
let mut deque = VecDeque::new();

(0..10).collect_into(&mut vec);
(0..10).collect_into(&mut set);
(0..10).collect_into(&mut deque);
```

### Comparison

| Method | Allocation | Buffer Reuse |
|--------|------------|--------------|
| `.collect()` | New each time | No |
| `.collect_into(&mut buf)` | Reuses buffer | Yes |
| `buf.extend(iter)` | Reuses buffer | Yes |

Related: `perf-drain-reuse`, `mem-reuse-collections`, `perf-extend-batch`

## perf-black-box-bench

> Use black_box in benchmarks

### Why It Matters

The compiler aggressively optimizes code, potentially eliminating computations whose results aren't used. In benchmarks, this can lead to measuring nothing instead of the actual code. `std::hint::black_box()` prevents the compiler from optimizing away values, ensuring accurate measurements.

### Bad

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_bad(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| {
            let result = expensive_computation(42);
            // Result unused - compiler may eliminate the call!
        });
    });
}

fn benchmark_also_bad(c: &mut Criterion) {
    let input = 42;  // Constant - compiler may precompute
    
    c.bench_function("compute", |b| {
        b.iter(|| {
            expensive_computation(input)
            // Return value may still be optimized away
        });
    });
}
```

### Good

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn benchmark_good(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| {
            // black_box on input prevents constant folding
            let result = expensive_computation(black_box(42));
            // black_box on output prevents dead code elimination
            black_box(result)
        });
    });
}

// Or simpler with Criterion's built-in support
fn benchmark_simpler(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| expensive_computation(black_box(42)))
    });
}
```

### What black_box Does

| Without black_box | With black_box |
|-------------------|----------------|
| Input may be constant-folded | Input treated as unknown |
| Result may be eliminated | Result must be computed |
| Loops may be optimized away | Each iteration runs |
| Functions may be inlined | Call semantics preserved |

### Standard Library Usage

```rust
use std::hint::black_box;

fn main() {
    // In std since Rust 1.66
    let result = black_box(compute_something(black_box(input)));
}
```

### Criterion's black_box

Criterion re-exports `std::hint::black_box`:

```rust
use criterion::black_box;

// Equivalent to std::hint::black_box
```

### Pattern: Benchmark with Setup

```rust
fn benchmark_with_setup(c: &mut Criterion) {
    c.bench_function("process_data", |b| {
        // Setup outside iter - not measured
        let data = generate_test_data(1000);
        
        b.iter(|| {
            // black_box the input reference
            let result = process(black_box(&data));
            black_box(result)
        });
    });
}
```

### Pattern: Benchmark Multiple Inputs

```rust
fn benchmark_sizes(c: &mut Criterion) {
    let mut group = c.benchmark_group("scaling");
    
    for size in [100, 1000, 10000] {
        let data = generate_data(size);
        
        group.bench_with_input(
            BenchmarkId::from_parameter(size),
            &data,
            |b, data| {
                b.iter(|| process(black_box(data)))
            },
        );
    }
    group.finish();
}
```

### Common Mistakes

```rust
// WRONG: black_box inside loop does nothing useful
for _ in 0..1000 {
    black_box(());  // Doesn't help
    compute();
}

// RIGHT: black_box the computation result
for _ in 0..1000 {
    black_box(compute());
}

// WRONG: Only blocking output, not input
let x = 42;  // Constant, may be optimized
black_box(expensive(x));

// RIGHT: Block both
black_box(expensive(black_box(42)));
```

Related: `test-criterion-bench`, `perf-profile-first`, `perf-release-profile`

## perf-release-profile

> Optimize release profile settings

### Why It Matters

The default release profile prioritizes compile speed over runtime performance. For production binaries, tuning the release profile can yield significant performance improvements (10-40% in some cases) at the cost of longer compile times.

### Default Profile

```toml
[profile.release]
opt-level = 3
debug = false
lto = false
codegen-units = 16
```

### Optimized Profile

```toml
[profile.release]
opt-level = 3          # Maximum optimization
lto = "fat"            # Full link-time optimization
codegen-units = 1      # Better optimization, slower compile
panic = "abort"        # Smaller binary, no unwinding
strip = true           # Remove symbols

[profile.release.package."*"]
# Keep dependencies optimized even if main crate changes
opt-level = 3
```

### Profile Options

| Option | Values | Effect |
|--------|--------|--------|
| `opt-level` | 0-3, "s", "z" | Optimization level |
| `lto` | false, "thin", "fat" | Link-time optimization |
| `codegen-units` | 1-256 | Parallel compilation units |
| `panic` | "unwind", "abort" | Panic behavior |
| `strip` | true, false, "symbols", "debuginfo" | Binary stripping |
| `debug` | true, false, 0-2 | Debug info level |

### Optimization Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `0` | No optimization | Debug builds |
| `1` | Basic optimization | Fast compile |
| `2` | Most optimizations | Balanced |
| `3` | All optimizations | Maximum performance |
| `"s"` | Optimize for size | Embedded |
| `"z"` | Minimize size | Smallest binary |

### LTO Options

| Option | Compile Time | Performance | Binary Size |
|--------|--------------|-------------|-------------|
| `false` | Fast | Baseline | Larger |
| `"thin"` | Medium | Good | Smaller |
| `"fat"` | Slow | Best | Smallest |

### Custom Profiles

```toml
# Fast release builds for development
[profile.release-dev]
inherits = "release"
lto = false
codegen-units = 16

# Maximum performance for production
[profile.release-prod]
inherits = "release"
lto = "fat"
codegen-units = 1
strip = true

# Profiling with symbols
[profile.profiling]
inherits = "release"
debug = true
strip = false
```

Use with: `cargo build --profile release-prod`

### Dev Dependencies Optimization

Speed up tests and dev builds:

```toml
[profile.dev]
opt-level = 0

# Optimize dependencies even in dev
[profile.dev.package."*"]
opt-level = 3
```

### Benchmarking Profile

```toml
[profile.bench]
inherits = "release"
debug = true      # For profiling
strip = false     # Keep symbols for flamegraphs
lto = "fat"       # Consistent with release-prod
```

### Size vs Speed Trade-offs

```toml
# Smallest binary
[profile.min-size]
inherits = "release"
opt-level = "z"
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true

# Balance size and speed
[profile.balanced]
inherits = "release"
opt-level = "s"
lto = "thin"
```

### Workspace Configuration

```toml
# In workspace Cargo.toml
[profile.release]
lto = "fat"
codegen-units = 1

# Override for specific package
[profile.release.package.fast-compile-lib]
lto = false
codegen-units = 16
```

Related: `opt-lto-release`, `opt-codegen-units`, `opt-pgo-profile`

## perf-profile-first

> Profile before optimizing

### Why It Matters

Intuition about performance is often wrong. The code you think is slow frequently isn't, while actual bottlenecks hide in unexpected places. Profiling shows you exactly where time is spent, preventing wasted effort on optimizations that don't matter.

### Bad

```rust
// Optimizing without measuring
fn process(data: &[Item]) -> Vec<Output> {
    // "I bet this clone is slow..."
    let cloned: Vec<_> = data.iter().cloned().collect();
    
    // Actually, 99% of time is spent here:
    cloned.iter().map(|x| expensive_computation(x)).collect()
}

// Over-engineering rarely-called code
#[inline(always)]
fn rarely_called() {
    // This runs once at startup...
}
```

### Good

```rust
// 1. Profile first
// cargo flamegraph --bin myapp
// cargo instruments -t time --bin myapp (macOS)

// 2. Find the actual bottleneck
// Flamegraph shows expensive_computation takes 95% of time

// 3. Optimize the hot spot
fn process(data: &[Item]) -> Vec<Output> {
    // Clone is fine - only 1% of time
    let cloned: Vec<_> = data.iter().cloned().collect();
    
    // Focus optimization HERE
    cloned.par_iter()  // Parallelize the expensive part
        .map(|x| expensive_computation(x))
        .collect()
}
```

### Profiling Tools

#### Flamegraphs (Recommended Start)

```bash
# Install
cargo install flamegraph

# Profile
cargo flamegraph --bin myapp -- <args>

# Opens flamegraph.svg showing call stacks by time
```

#### perf (Linux)

```bash
# Record
perf record -g cargo run --release

# Report
perf report

# Or generate flamegraph
perf script | inferno-collapse-perf | inferno-flamegraph > flamegraph.svg
```

#### Instruments (macOS)

```bash
# Install cargo-instruments
cargo install cargo-instruments

# Time profiler
cargo instruments -t time --release

# Allocations profiler
cargo instruments -t alloc --release
```

#### DHAT (Heap Profiling)

```bash
# In your code
#[global_allocator]
static ALLOC: dhat::Alloc = dhat::Alloc;

fn main() {
    let _profiler = dhat::Profiler::new_heap();
    // ... your code
}

# Run and get allocation report
cargo run --release
```

#### criterion (Micro-benchmarks)

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};

fn bench_my_function(c: &mut Criterion) {
    c.bench_function("my_function", |b| {
        b.iter(|| my_function(black_box(input)))
    });
}

criterion_group!(benches, bench_my_function);
criterion_main!(benches);
```

### What to Look For

```
Flamegraph Reading:
├── Width = time spent
├── Height = call stack depth
└── Look for:
    ├── Wide bars (time hogs)
    ├── malloc/free (allocation heavy)
    ├── memcpy (copying data)
    └── Unexpected functions taking time
```

### Common Findings

```rust
// Finding: HashMap operations are slow
// Fix: Use FxHashMap or AHashMap for non-crypto hashing

// Finding: String allocation in hot loop
// Fix: Pre-allocate with capacity, use &str

// Finding: Clone in hot path
// Fix: Use references or Cow

// Finding: Bounds checks visible in profile
// Fix: Use iterators instead of indexing

// Finding: Lock contention
// Fix: Reduce critical section, use RwLock, or partition data
```

### Optimization Workflow

```
1. Write correct code first
2. Write benchmarks for hot paths
3. Profile under realistic load
4. Identify actual bottlenecks
5. Optimize ONE thing
6. Measure improvement
7. Repeat if needed
```

### Evidence: Rust Performance Book

> "The biggest performance improvements often come from changes to algorithms or data structures, rather than low-level optimizations."

> "It is worth understanding which Rust data structures and operations cause allocations, because avoiding them can greatly improve performance."

Related: `opt-lto-release`, `test-criterion-bench`, `anti-premature-optimize`

## perf-ahash

> Use a faster hasher (`ahash` / `FxHashMap`) when DoS resistance is not needed

### Why It Matters

Rust's default `HashMap` uses SipHash-1-3, which is DoS-resistant (hash flooding attacks on external input are not viable) but roughly 2–4× slower than non-cryptographic hashers on typical integer and short-string keys. For internal maps keyed by compiler-generated IDs, integer handles, or other trusted data, switching to a faster hasher can meaningfully reduce CPU time in hot map-heavy code. The wrong choice here is a security bug, not just a performance one — never use a non-DoS-resistant hasher for maps keyed by untrusted external input (user-supplied strings, network data, file paths from untrusted sources).

### Bad

```rust
use std::collections::HashMap;

// Using the default SipHash hasher for compiler-internal integer keys —
// DoS resistance is wasted cost here.
fn build_id_map(ids: &[(u32, String)]) -> HashMap<u32, String> {
    ids.iter().cloned().collect()
}
```

### Good

```rust
// ahash: randomized seed per process, DoS-resistant, ~2x faster than SipHash.
// Good default replacement for most use cases.
use ahash::AHashMap;

fn build_id_map_ahash(ids: &[(u32, String)]) -> AHashMap<u32, String> {
    ids.iter().cloned().collect()
}

// FxHashMap (rustc-hash): fastest option, but uses a predictable hash function.
// Only for trusted integer or pointer keys where hash flooding is not a concern
// (e.g., compiler internals, in-process caches keyed by integer IDs).
use rustc_hash::FxHashMap;

type NodeMap<V> = FxHashMap<u32, V>;

fn build_node_map(nodes: &[(u32, String)]) -> NodeMap<String> {
    let mut map = NodeMap::with_capacity_and_hasher(
        nodes.len(),
        Default::default(),
    );
    map.extend(nodes.iter().cloned());
    map
}

// Convenient type aliases to avoid repeating the hasher parameter
use std::collections::HashMap;
use rustc_hash::FxBuildHasher;

type FastMap<K, V> = HashMap<K, V, FxBuildHasher>;

fn fast_map_example() -> FastMap<u32, u64> {
    FastMap::with_capacity_and_hasher(64, FxBuildHasher)
}
```

### Hasher Selection Guide

| Hasher | Crate | DoS-resistant | Speed | Use when |
|--------|-------|--------------|-------|----------|
| `SipHash-1-3` | std (default) | Yes | Baseline | Keys from untrusted external input |
| `ahash` | `ahash` | Yes (randomized) | ~2× faster | General-purpose replacement; safe default upgrade |
| `FxHash` | `rustc-hash` | No | Fastest | Trusted integer/pointer keys, compiler internals |
| `gxhash` | `gxhash` | Optional | Very fast (SIMD) | Throughput-critical, homogeneous key types |

### Key Points

- **Profile first**: switch hashers only after confirming map operations appear in profiler output.
- `ahash::AHashMap` is a drop-in replacement for `HashMap` and is the safest upgrade — it uses a random per-process seed.
- `FxHashMap` is what rustc uses internally; it is predictable, so never expose it to externally-supplied keys.
- Pass `with_capacity` when the final size is known — it applies regardless of hasher choice.

Related: `perf-entry-api`, `perf-profile-first`, `mem-with-capacity`

## perf-io-buffering

> Wrap `Read`/`Write` in `BufReader`/`BufWriter` for many small operations

### Why It Matters

Every unbuffered read or write to a file or socket is a syscall. Calling `read()` byte-by-byte or line-by-line without buffering can issue millions of syscalls per second, each with kernel-transition overhead that dwarfs the actual data transfer. `BufReader` and `BufWriter` batch those operations into large internal buffer reads and writes, cutting syscall count by orders of magnitude. This is one of the highest-impact, lowest-effort performance fixes available for IO-heavy code.

### Bad

```rust
use std::fs::File;
use std::io::{Read, Write};

// Every read call goes to the OS — catastrophic for line-by-line processing
fn count_lines_slow(path: &str) -> std::io::Result<usize> {
    let file = File::open(path)?;
    let mut count = 0usize;
    let mut byte = [0u8; 1];
    loop {
        match file.read(&mut byte) { // one syscall per byte
            Ok(0) => break,
            Ok(_) => {
                if byte[0] == b'\n' {
                    count += 1;
                }
            }
            Err(e) => return Err(e),
        }
    }
    Ok(count)
}

// Writing many small records without buffering — each write is a syscall
fn write_records_slow(path: &str, records: &[String]) -> std::io::Result<()> {
    let mut file = File::create(path)?;
    for record in records {
        file.write_all(record.as_bytes())?; // one syscall per record
        file.write_all(b"\n")?;             // another syscall
    }
    Ok(())
}
```

### Good

```rust
use std::fs::File;
use std::io::{self, BufRead, BufReader, BufWriter, Write};

// BufReader batches OS reads; lines() iterates safely without extra allocation per line
fn count_lines_fast(path: &str) -> io::Result<usize> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let mut count = 0usize;
    for line in reader.lines() {
        line?; // propagate IO errors
        count += 1;
    }
    Ok(count)
}

// BufWriter batches writes; explicit flush() surfaces errors that drop() would swallow
fn write_records_fast(path: &str, records: &[String]) -> io::Result<()> {
    let file = File::create(path)?;
    let mut writer = BufWriter::new(file);
    for record in records {
        writer.write_all(record.as_bytes())?;
        writer.write_all(b"\n")?;
    }
    writer.flush()?; // MUST flush explicitly — drop() swallows flush errors
    Ok(())
}

// Custom buffer size when the default 8 KiB isn't optimal
fn process_large_file(path: &str) -> io::Result<()> {
    let file = File::open(path)?;
    let reader = BufReader::with_capacity(64 * 1024, file); // 64 KiB buffer
    for line in reader.lines() {
        let _line = line?;
        // process...
    }
    Ok(())
}
```

### Key Points

- `BufWriter::flush()?` must be called explicitly. When a `BufWriter` is dropped, it attempts to flush, but any resulting error is **silently discarded**. Always flush before the writer goes out of scope.
- The default buffer size for both `BufReader` and `BufWriter` is 8 KiB. For sequential reads of large files, a larger buffer (32–512 KiB) can improve throughput by reducing the number of `read` syscalls further.
- `BufReader` implements `BufRead`, which provides `lines()`, `read_line()`, and `read_until()` — use these instead of reading bytes manually.
- Network streams (`TcpStream`, etc.) benefit equally from buffering, since each `write` on an unbuffered stream may send a tiny TCP segment.
- If you wrap a type that is already internally buffered (e.g., `tokio::io::BufWriter` in async code), adding another layer is redundant.

Related: `mem-with-capacity`, `perf-profile-first`
