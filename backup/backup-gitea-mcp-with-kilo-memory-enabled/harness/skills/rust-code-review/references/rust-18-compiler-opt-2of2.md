---
name: rust-18-compiler-opt-2of2
description: Rust rules module 18: Compiler Optimization (part 2 of 2). 6 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `opt-`
---

# Compiler Optimization (part 2/2)

Priority: HIGH. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `opt-codegen-units` - Set `codegen-units = 1` for maximum optimization in release builds
- `opt-pgo-profile` - Use Profile-Guided Optimization (PGO) for maximum performance
- `opt-target-cpu` - Use `target-cpu=native` for maximum performance on known deployment targets
- `opt-bounds-check` - Use iterators and patterns that eliminate bounds checks in hot paths
- `opt-simd-portable` - Use portable SIMD for vectorized operations across architectures
- `opt-cache-friendly` - Organize data for cache-efficient access patterns

---

## opt-codegen-units

> Set `codegen-units = 1` for maximum optimization in release builds

### Why It Matters

By default, Cargo splits code into multiple codegen units for parallel compilation. This speeds up builds but prevents some cross-unit optimizations. Setting `codegen-units = 1` allows LLVM to optimize across the entire crate, potentially improving runtime performance by 5-20% at the cost of slower builds.

### Bad

```toml
# Cargo.toml - default settings
[profile.release]
# codegen-units defaults to 16
# Fast to compile, but misses optimization opportunities
```

### Good

```toml
# Cargo.toml - optimized for runtime performance
[profile.release]
codegen-units = 1  # Single unit = better optimization
lto = true         # Link-time optimization
opt-level = 3      # Maximum optimization
```

### What codegen-units Affects

| Codegen Units | Compile Time | Runtime Performance | Memory Use |
|---------------|--------------|---------------------|------------|
| 16 (default)  | Faster       | Baseline            | Lower      |
| 4-8           | Moderate     | Slightly better     | Moderate   |
| 1             | Slower       | Best                | Higher     |

### How It Works

```rust
// With codegen-units = 16:
// - Crate split into 16 independent compilation units
// - Compiled in parallel
// - Limited visibility between units for optimization

// With codegen-units = 1:
// - Entire crate in single unit
// - LLVM sees all code at once
// - Can inline across module boundaries
// - Better dead code elimination
// - Better constant propagation
```

### Full Release Profile

```toml
[profile.release]
# Maximum runtime performance
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"      # Smaller binary, slight perf gain
strip = true         # Smaller binary

[profile.release-with-debug]
# Performance with debugging ability
inherits = "release"
debug = true         # Keep debug symbols
strip = false

[profile.bench]
# For benchmarking
inherits = "release"
```

### Build Time Trade-offs

```bash
# Default release build (fast compile)
cargo build --release
# Time: ~30s

# Optimized release build (slow compile, fast runtime)
# With codegen-units = 1, lto = "fat"
cargo build --release
# Time: ~2-5min, but potentially 10-20% faster binary
```

### Per-Profile Configuration

```toml
# Fast debug builds
[profile.dev]
codegen-units = 256  # Maximum parallelism

# Fast CI builds
[profile.ci]
inherits = "release"
codegen-units = 16   # Balance compile time vs runtime
lto = "thin"         # Faster than "fat"

# Production release
[profile.production]
inherits = "release"
codegen-units = 1
lto = "fat"
```

### When to Use What

```rust
// codegen-units = 16 (default)
// - Development builds
// - CI where compile time matters
// - When runtime performance isn't critical

// codegen-units = 1
// - Production deployments
// - Performance-critical applications
// - Final releases
// - Benchmarking
```

### Measuring Impact

```bash
# Build with different settings
cargo build --release

# Benchmark
cargo bench

# Compare binary sizes
ls -lh target/release/my_binary

# Profile runtime
perf stat ./target/release/my_binary
```

Related: `opt-lto-release`, `opt-pgo-profile`, `opt-target-cpu`

## opt-pgo-profile

> Use Profile-Guided Optimization (PGO) for maximum performance

### Why It Matters

PGO uses real runtime behavior to guide compiler optimization decisions. By profiling actual workloads, the compiler learns which code paths are hot, optimizing them aggressively while deprioritizing cold paths. This can yield 10-30% performance improvements beyond standard optimizations.

### The PGO Process

1. **Instrument**: Build with profiling instrumentation
2. **Profile**: Run representative workloads
3. **Optimize**: Rebuild using collected profile data

### Step-by-Step

```bash
# Step 1: Build instrumented binary
RUSTFLAGS="-Cprofile-generate=/tmp/pgo-data" \
    cargo build --release

# Step 2: Run representative workloads
./target/release/my_app < test_data_1.txt
./target/release/my_app < test_data_2.txt
./target/release/my_app < typical_workload.txt

# Step 3: Merge profile data
llvm-profdata merge -o /tmp/pgo-data/merged.profdata /tmp/pgo-data

# Step 4: Build optimized binary using profile
RUSTFLAGS="-Cprofile-use=/tmp/pgo-data/merged.profdata" \
    cargo build --release
```

### Cargo Configuration

```toml
# Cargo.toml
[profile.release]
lto = "fat"
codegen-units = 1
opt-level = 3

# PGO flags set via RUSTFLAGS environment variable
```

### Build Script

```bash
#!/bin/bash
set -e

PGO_DIR=/tmp/pgo-$(date +%s)

# Clean
cargo clean

# Instrumented build
echo "Building instrumented binary..."
RUSTFLAGS="-Cprofile-generate=$PGO_DIR" cargo build --release

# Run workloads
echo "Collecting profile data..."
./target/release/my_app --benchmark-mode
./target/release/my_app < test_fixtures/typical.txt
./target/release/my_app < test_fixtures/stress.txt

# Merge profiles
echo "Merging profile data..."
llvm-profdata merge -o $PGO_DIR/merged.profdata $PGO_DIR

# Optimized build
echo "Building optimized binary..."
RUSTFLAGS="-Cprofile-use=$PGO_DIR/merged.profdata" cargo build --release

echo "Done! Optimized binary at target/release/my_app"
```

### Representative Workloads

```rust
// Create benchmarks that match real usage patterns

// Good: actual data samples
fn profile_workload() {
    for file in real_customer_data_samples() {
        process_file(&file);
    }
}

// Good: synthetic but realistic
fn profile_synthetic() {
    for _ in 0..10000 {
        let data = generate_realistic_data();
        process(&data);
    }
}

// Bad: artificial microbenchmarks
fn profile_bad() {
    for _ in 0..1000000 {
        small_operation();  // Doesn't reflect real hot paths
    }
}
```

### BOLT Post-Link Optimization

For even more gains, combine PGO with BOLT:

```bash
# After PGO build, apply BOLT
llvm-bolt target/release/my_app \
    -o target/release/my_app.bolt \
    -data=perf.data \
    -reorder-blocks=ext-tsp \
    -reorder-functions=hfsort

# BOLT can add another 5-15% on top of PGO
```

### CI/CD Integration

```yaml
# GitHub Actions example
jobs:
  pgo-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install LLVM tools
        run: sudo apt-get install llvm
      
      - name: Instrumented build
        run: RUSTFLAGS="-Cprofile-generate=/tmp/pgo" cargo build --release
      
      - name: Run profiling workloads
        run: ./scripts/run_profiling_workloads.sh
      
      - name: Merge profiles
        run: llvm-profdata merge -o /tmp/pgo/merged.profdata /tmp/pgo
      
      - name: Optimized build
        run: RUSTFLAGS="-Cprofile-use=/tmp/pgo/merged.profdata" cargo build --release
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: optimized-binary
          path: target/release/my_app
```

### When to Use PGO

| Use PGO | Skip PGO |
|---------|----------|
| Production deployments | Development builds |
| Performance-critical apps | Libraries (users can PGO) |
| Stable workload patterns | Highly variable workloads |
| Sufficient profiling data | Quick iteration cycles |

Related: `opt-lto-release`, `opt-codegen-units`, `perf-profile-first`

## opt-target-cpu

> Use `target-cpu=native` for maximum performance on known deployment targets

### Why It Matters

By default, Rust compiles for a generic x86-64 baseline (roughly Sandy Bridge era). Modern CPUs have SIMD extensions (AVX2, AVX-512), improved instructions, and micro-architectural optimizations that go unused. `target-cpu=native` enables all features of your current CPU, potentially unlocking significant speedups.

### Bad

```toml
# Cargo.toml - compiles for generic x86-64
[profile.release]
# No target-cpu specified
# Binary works everywhere but uses only SSE2
```

### Good

```toml
# .cargo/config.toml - for known deployment target
[build]
rustflags = ["-C", "target-cpu=native"]

# Or specific CPU for cross-compilation
# rustflags = ["-C", "target-cpu=skylake"]
```

### Via Environment

```bash
# Build with native optimizations
RUSTFLAGS="-C target-cpu=native" cargo build --release

# Check what features are enabled
rustc --print cfg -C target-cpu=native | grep target_feature
```

### Common Target CPUs

```bash
# x86-64 targets
target-cpu=native          # Current machine
target-cpu=x86-64          # Baseline (SSE2)
target-cpu=x86-64-v2       # SSE4.2, POPCNT
target-cpu=x86-64-v3       # AVX2, BMI2
target-cpu=x86-64-v4       # AVX-512

# Intel specific
target-cpu=skylake         # 6th gen Core
target-cpu=alderlake       # 12th gen Core

# AMD specific
target-cpu=znver3          # Zen 3
target-cpu=znver4          # Zen 4

# ARM
target-cpu=apple-m1        # Apple Silicon
target-cpu=neoverse-n1     # AWS Graviton2
```

### Feature Detection at Runtime

```rust
// For portable binaries that use native features when available
#[cfg(target_arch = "x86_64")]
fn process_fast(data: &[u8]) -> u64 {
    if is_x86_feature_detected!("avx2") {
        // SAFETY: only reached after avx2 is detected at runtime
        unsafe { process_avx2(data) }
    } else {
        process_generic(data)
    }
}

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx2")]
unsafe fn process_avx2(data: &[u8]) -> u64 {
    // an AVX2-optimized path would go here; delegate to the scalar version
    process_generic(data)
}

fn process_generic(data: &[u8]) -> u64 {
    data.iter().map(|&b| u64::from(b)).sum()
}
```

### Multi-Architecture Builds

```bash
# Build multiple binaries
RUSTFLAGS="-C target-cpu=x86-64" cargo build --release
mv target/release/app target/release/app-generic

RUSTFLAGS="-C target-cpu=x86-64-v3" cargo build --release
mv target/release/app target/release/app-avx2

# Select at runtime
if supports_avx2; then
    ./app-avx2
else
    ./app-generic
fi
```

### Cargo Configuration

```toml
# .cargo/config.toml

# Native builds for development
[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=native"]

# AWS deployment (Graviton2)
[target.aarch64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=neoverse-n1"]

# Intel server deployment
[target.x86_64-unknown-linux-gnu.deployment]
rustflags = ["-C", "target-cpu=skylake-avx512"]
```

### What Changes

```rust
// With AVX2 enabled:
// - 256-bit SIMD operations
// - Better autovectorization
// - FMA (fused multiply-add)
// - BMI (bit manipulation)

// Example: sum of squares
fn sum_squares(data: &[f64]) -> f64 {
    data.iter().map(|x| x * x).sum()
}
// Generic: scalar loop
// AVX2: processes 4 f64s per iteration
```

### Checking Enabled Features

```bash
# What's enabled for native?
rustc --print cfg -C target-cpu=native | grep feature

# Compare generic vs native
rustc --print cfg -C target-cpu=x86-64 | grep feature
rustc --print cfg -C target-cpu=native | grep feature

# View generated assembly
cargo asm --rust --release my_crate::hot_function
```

Related: `opt-lto-release`, `opt-simd-portable`, `opt-codegen-units`

## opt-bounds-check

> Use iterators and patterns that eliminate bounds checks in hot paths

### Why It Matters

Rust's safety guarantees require bounds checking on array/slice indexing. In tight loops, these checks can cause measurable overhead (branch mispredictions, preventing vectorization). Patterns like iterators, `get_unchecked`, and index splitting can eliminate these checks while maintaining safety.

### Bad

```rust
fn sum_products(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len() {
        sum += a[i] * b[i];  // Two bounds checks per iteration
    }
    sum
}

fn apply_filter(data: &mut [u8], kernel: &[u8; 3]) {
    for i in 1..data.len() - 1 {
        // Three bounds checks per iteration
        data[i] = (data[i - 1] + data[i] + data[i + 1]) / 3;
    }
}
```

### Good

```rust
fn sum_products(a: &[f64], b: &[f64]) -> f64 {
    // Iterator zips - no bounds checks, vectorizes well
    a.iter().zip(b.iter()).map(|(x, y)| x * y).sum()
}

fn apply_filter(data: &mut [u8]) {
    // Windows pattern - no bounds checks
    for window in data.windows(3) {
        // window[0], window[1], window[2] are all valid
    }
    
    // Or use chunks
    for chunk in data.chunks_exact(4) {
        process_simd(chunk);
    }
}
```

### Iterator Patterns

```rust
// These give the compiler much better opportunities to eliminate bounds checks
// (and often do in practice), but elimination is not guaranteed — verify hot
// code with generated assembly (e.g. cargo-show-asm):

// zip - parallel iteration
for (a, b) in xs.iter().zip(ys.iter()) { ... }

// enumerate - index + value  
for (i, x) in data.iter().enumerate() { ... }

// windows - sliding window
for window in data.windows(3) { ... }

// chunks - fixed-size groups
for chunk in data.chunks(4) { ... }
for chunk in data.chunks_exact(4) { ... }  // Guarantees exact size

// split_at - divide slice
let (left, right) = data.split_at(mid);
```

### Split for Parallel Access

```rust
fn parallel_sum(data: &[i32]) -> i32 {
    // Split into independent chunks
    let (left, right) = data.split_at(data.len() / 2);
    
    // Process chunks without bounds checks
    let sum_left: i32 = left.iter().sum();
    let sum_right: i32 = right.iter().sum();
    
    sum_left + sum_right
}
```

### get_unchecked for Proven Safety

```rust
fn matrix_multiply(a: &[f64], b: &[f64], c: &mut [f64], n: usize) {
    assert!(a.len() >= n * n);
    assert!(b.len() >= n * n);
    assert!(c.len() >= n * n);
    
    for i in 0..n {
        for j in 0..n {
            let mut sum = 0.0;
            for k in 0..n {
                // SAFETY: bounds verified by asserts above
                unsafe {
                    sum += a.get_unchecked(i * n + k) 
                         * b.get_unchecked(k * n + j);
                }
            }
            // SAFETY: bounds verified by asserts above
            unsafe {
                *c.get_unchecked_mut(i * n + j) = sum;
            }
        }
    }
}
```

### Slice Patterns

```rust
fn process_header(data: &[u8]) -> Option<Header> {
    // Slice pattern - single length check, no per-field checks
    let [a, b, c, d, rest @ ..] = data else {
        return None;
    };
    
    Some(Header {
        magic: *a,
        version: *b,
        flags: u16::from_le_bytes([*c, *d]),
        payload: rest,
    })
}
```

### Verify Bounds Check Elimination

```bash
# Check generated assembly
cargo asm --release my_crate::hot_function

# Look for 'cmp' and 'ja'/'jbe' instructions near array access
# If eliminated, you'll see direct memory access
```

### When to Accept Bounds Checks

```rust
// Random access patterns - checks unavoidable
fn random_lookup(data: &[u8], indices: &[usize]) -> Vec<u8> {
    indices.iter()
        .filter_map(|&i| data.get(i).copied())  // Checked, but necessary
        .collect()
}

// Infrequent access - overhead negligible
fn get_config(&self, key: &str) -> Option<&Value> {
    self.config.get(key)  // Fine, not hot path
}
```

Related: `opt-simd-portable`, `opt-cache-friendly`, `perf-profile-first`

## opt-simd-portable

> Use portable SIMD for vectorized operations across architectures

### Why It Matters

SIMD (Single Instruction, Multiple Data) processes multiple values per instruction—4x, 8x, or more speedup for suitable algorithms. Rust's portable SIMD (nightly) and crates like `wide` provide cross-platform vectorization without architecture-specific intrinsics. For stable Rust, let LLVM auto-vectorize or use platform-specific crates.

### Autovectorization (Stable)

```rust
// LLVM often vectorizes simple patterns automatically
fn sum(data: &[f32]) -> f32 {
    data.iter().sum()  // May vectorize to SIMD
}

fn add_arrays(a: &[f32], b: &[f32], out: &mut [f32]) {
    for ((x, y), o) in a.iter().zip(b).zip(out.iter_mut()) {
        *o = x + y;  // Often vectorizes
    }
}

// Help autovectorization:
// 1. Use iterators over indexing
// 2. Avoid early exits in loops
// 3. Use chunks_exact for aligned access
```

### Portable SIMD (Nightly)

```rust
#![feature(portable_simd)]
use std::simd::*;

fn sum_simd(data: &[f32]) -> f32 {
    let (prefix, middle, suffix) = data.as_simd::<8>();
    
    // Handle unaligned prefix
    let mut sum = prefix.iter().sum::<f32>();
    
    // SIMD loop - 8 floats at a time
    let mut simd_sum = f32x8::splat(0.0);
    for chunk in middle {
        simd_sum += *chunk;
    }
    sum += simd_sum.reduce_sum();
    
    // Handle unaligned suffix
    sum += suffix.iter().sum::<f32>();
    
    sum
}

fn dot_product(a: &[f32], b: &[f32]) -> f32 {
    assert_eq!(a.len(), b.len());
    
    let (a_pre, a_mid, a_suf) = a.as_simd::<8>();
    let (b_pre, b_mid, b_suf) = b.as_simd::<8>();
    
    let scalar: f32 = a_pre.iter().zip(b_pre).map(|(x, y)| x * y).sum();
    
    let mut simd_sum = f32x8::splat(0.0);
    for (av, bv) in a_mid.iter().zip(b_mid) {
        simd_sum += *av * *bv;
    }
    
    let suffix: f32 = a_suf.iter().zip(b_suf).map(|(x, y)| x * y).sum();
    
    scalar + simd_sum.reduce_sum() + suffix
}
```

### wide Crate (Stable)

```rust
use wide::*;

fn process_simd(data: &mut [f32]) {
    // Process 8 floats at a time
    for chunk in data.chunks_exact_mut(8) {
        let v = f32x8::from(chunk);
        let result = v * f32x8::splat(2.0) + f32x8::splat(1.0);
        chunk.copy_from_slice(&result.to_array());
    }
}

fn blend_images(a: &[u8], b: &[u8], alpha: f32, out: &mut [u8]) {
    let alpha_v = f32x8::splat(alpha);
    let one_minus = f32x8::splat(1.0 - alpha);
    
    for ((a_chunk, b_chunk), out_chunk) in 
        a.chunks_exact(8).zip(b.chunks_exact(8)).zip(out.chunks_exact_mut(8)) 
    {
        let av = f32x8::from([
            a_chunk[0] as f32, a_chunk[1] as f32, /* ... */
        ]);
        let bv = f32x8::from([
            b_chunk[0] as f32, b_chunk[1] as f32, /* ... */
        ]);
        
        let result = av * one_minus + bv * alpha_v;
        // Convert back to u8...
    }
}
```

### Platform-Specific (When Needed)

```rust
#[cfg(target_arch = "x86_64")]
use std::arch::x86_64::*;

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx2")]
unsafe fn sum_avx2(data: &[f32]) -> f32 {
    let mut acc = _mm256_setzero_ps();
    let mut chunks = data.chunks_exact(8);
    for chunk in &mut chunks {
        let v = _mm256_loadu_ps(chunk.as_ptr());
        acc = _mm256_add_ps(acc, v);
    }

    // store the 8 lanes, then finish the reduction (and the remainder) in scalar
    let mut lanes = [0.0f32; 8];
    _mm256_storeu_ps(lanes.as_mut_ptr(), acc);
    lanes.iter().sum::<f32>() + chunks.remainder().iter().sum::<f32>()
}
```

### Choosing an Approach

| Approach | Stability | Portability | Control |
|----------|-----------|-------------|---------|
| Autovectorization | Stable | Excellent | Low |
| `wide` crate | Stable | Good | Medium |
| Portable SIMD | Nightly | Excellent | High |
| Intrinsics | Stable | None | Maximum |

Related: `opt-target-cpu`, `opt-bounds-check`, `perf-profile-first`

## opt-cache-friendly

> Organize data for cache-efficient access patterns

### Why It Matters

Cache misses are expensive—a L3 cache miss costs ~100+ cycles vs ~4 cycles for L1 hit. Data layout and access patterns determine cache efficiency. Arrays of structs (AoS) vs structs of arrays (SoA), memory locality, and access patterns can make order-of-magnitude performance differences.

### Bad

```rust
// Array of Structs (AoS) - poor cache use when accessing one field
struct Particle {
    position: [f32; 3],  // 12 bytes
    velocity: [f32; 3],  // 12 bytes
    mass: f32,           // 4 bytes
    id: u64,             // 8 bytes
    flags: u8,           // 1 byte + padding
    // Total: 40 bytes per particle
}

fn update_positions(particles: &mut [Particle], dt: f32) {
    for p in particles {
        // Access position and velocity - 24 bytes
        // But loads 40-byte struct per particle
        // 16 bytes wasted per cache line load
        p.position[0] += p.velocity[0] * dt;
        p.position[1] += p.velocity[1] * dt;
        p.position[2] += p.velocity[2] * dt;
    }
}
```

### Good

```rust
// Struct of Arrays (SoA) - cache-efficient for field access
struct Particles {
    positions_x: Vec<f32>,
    positions_y: Vec<f32>,
    positions_z: Vec<f32>,
    velocities_x: Vec<f32>,
    velocities_y: Vec<f32>,
    velocities_z: Vec<f32>,
    masses: Vec<f32>,
    ids: Vec<u64>,
    flags: Vec<u8>,
}

fn update_positions(p: &mut Particles, dt: f32) {
    // Access contiguous memory - perfect cache utilization
    for (px, vx) in p.positions_x.iter_mut().zip(&p.velocities_x) {
        *px += vx * dt;
    }
    for (py, vy) in p.positions_y.iter_mut().zip(&p.velocities_y) {
        *py += vy * dt;
    }
    for (pz, vz) in p.positions_z.iter_mut().zip(&p.velocities_z) {
        *pz += vz * dt;
    }
}
```

### Hot/Cold Splitting

```rust
// Separate frequently and rarely accessed fields
struct EntityHot {
    position: [f32; 3],
    velocity: [f32; 3],
    // Hot data - accessed every frame
}

struct EntityCold {
    name: String,
    creation_time: Instant,
    metadata: HashMap<String, Value>,
    // Cold data - rarely accessed
}

struct Entities {
    hot: Vec<EntityHot>,
    cold: Vec<EntityCold>,
}

// Hot loop touches only hot data
fn update(entities: &mut Entities, dt: f32) {
    for e in &mut entities.hot {
        e.position[0] += e.velocity[0] * dt;
        // Cold data stays out of cache
    }
}
```

### Prefetching

```rust
// Process in cache-line-sized chunks
const CACHE_LINE: usize = 64;

fn process_with_prefetch(data: &mut [u8]) {
    for chunk in data.chunks_mut(CACHE_LINE) {
        // Prefetch next chunk while processing current
        // (automatic in many cases, manual for complex patterns)
        process_chunk(chunk);
    }
}

// Matrix multiplication - block for cache
fn matmul_blocked(a: &[f64], b: &[f64], c: &mut [f64], n: usize) {
    const BLOCK: usize = 32;  // Fits in L1 cache
    
    for i0 in (0..n).step_by(BLOCK) {
        for j0 in (0..n).step_by(BLOCK) {
            for k0 in (0..n).step_by(BLOCK) {
                // Process BLOCK x BLOCK tile
                for i in i0..min(i0 + BLOCK, n) {
                    for j in j0..min(j0 + BLOCK, n) {
                        // Inner loop operates on cached data
                    }
                }
            }
        }
    }
}
```

### Avoid Pointer Chasing

```rust
// Bad: linked list - random memory access
struct Node {
    value: i32,
    next: Option<Box<Node>>,
}

fn sum_linked(head: &Node) -> i32 {
    // Each node is a cache miss
}

// Good: contiguous vector
fn sum_vector(data: &[i32]) -> i32 {
    data.iter().sum()  // Sequential access, prefetcher happy
}

// Good: if graph needed, use indices
struct Graph {
    values: Vec<i32>,
    edges: Vec<usize>,  // Indices into values
}
```

### Memory Layout Attributes

```rust
// Ensure cache-line alignment
#[repr(C, align(64))]
struct CacheAligned {
    data: [u8; 64],
}

// Prevent false sharing in concurrent code
#[repr(C, align(64))]
struct PaddedCounter {
    value: AtomicU64,
    _pad: [u8; 56],
}
```

### Measuring Cache Performance

```bash
# Linux perf
perf stat -e cache-references,cache-misses ./my_program

# Detailed cache analysis
perf stat -e L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses ./my_program

# Cachegrind
valgrind --tool=cachegrind ./my_program
```

Related: `mem-smaller-integers`, `mem-box-large-variant`, `opt-bounds-check`
