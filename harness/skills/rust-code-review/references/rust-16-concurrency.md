---
name: rust-16-concurrency
description: Rust rules module 16: Concurrency. 4 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `conc-`
---

# Concurrency

Priority: HIGH. 4 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `conc-rayon-par-iter` - Use rayon's `par_iter()` for CPU-bound data parallelism
- `conc-scoped-threads` - Use `std::thread::scope` to borrow stack data across threads
- `conc-atomic-ordering` - Use the weakest correct memory `Ordering` for every atomic operation
- `conc-thread-local` - Prefer `thread_local!` with `Cell`/`RefCell` over `static mut`

---

## conc-rayon-par-iter

> Use rayon's `par_iter()` for CPU-bound data parallelism

### Why It Matters

Rayon's work-stealing scheduler parallelizes data-parallel workloads with an API nearly identical to standard iterators — often a one-word change from `.iter()` to `.par_iter()` yields near-linear speedup across cores. It automatically balances load across threads, handles chunking, and composes with the full iterator adapter chain. For IO-bound concurrency, use async instead; rayon is strictly for CPU-bound computation.

### Bad

```rust
// single-threaded — wastes available cores on a CPU-bound workload
fn sum_squares(data: &[f64]) -> f64 {
    data.iter().map(|x| x * x).sum()
}

fn normalize(data: &mut [f64]) {
    let max = data.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    data.iter_mut().for_each(|x| *x /= max);
}
```

### Good

```rust
use rayon::prelude::*;

fn sum_squares(data: &[f64]) -> f64 {
    data.par_iter().map(|x| x * x).sum()
}

fn normalize(data: &mut [f64]) {
    let max = data.par_iter().cloned().reduce(|| f64::NEG_INFINITY, f64::max);
    data.par_iter_mut().for_each(|x| *x /= max);
}

fn keep_positive(data: &[f64]) -> Vec<f64> {
    data.par_iter().copied().filter(|&x| x > 0.0).collect()
}

fn sort_large(data: &mut [f64]) {
    // parallel unstable sort — faster than std sort for large slices
    data.par_sort_unstable_by(|a, b| a.partial_cmp(b).unwrap());
}
```

### Key Points

| Concern | Guidance |
|---------|----------|
| Import | `use rayon::prelude::*;` enables `.par_iter()` on slices and most collections |
| IO-bound work | Use async (`tokio`, `async-std`), not rayon — rayon threads block |
| Small collections | Sequential is often faster due to thread-spawn overhead; profile first |
| Minimum chunk size | Rayon's `with_min_len()` / `with_max_len()` tune granularity |
| Shared state | Use `Mutex` or atomic operations; rayon does not prevent data races |

### When to Use

- Processing large arrays, slices, or collections (image pixels, number crunching, parsing batches)
- CPU-bound transformations: map, filter, fold, sort
- When the per-element work is non-trivial (at least a few hundred nanoseconds)

Related: `conc-scoped-threads`, `perf-iter-over-index`, `async-spawn-blocking`

## conc-scoped-threads

> Use `std::thread::scope` to borrow stack data across threads

### Why It Matters

Scoped threads (stable since Rust 1.63) guarantee that all threads spawned inside the scope join before `thread::scope` returns. This lifetime guarantee lets spawned threads borrow non-`'static` data from the enclosing stack frame — no `Arc`, no cloning, no heap allocation required. For short parallel tasks that need to read or write local data, scoped threads are simpler and cheaper than wrapping everything in `Arc<Mutex<...>>`.

### Bad

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn parallel_sum(data: &[i64]) -> i64 {
    // Arc + clone just to share a slice — heap overhead, boilerplate
    let data = Arc::new(data.to_vec()); // unnecessary clone of entire slice
    let mid = data.len() / 2;

    let data1 = Arc::clone(&data);
    let h1 = thread::spawn(move || data1[..mid].iter().sum::<i64>());

    let data2 = Arc::clone(&data);
    let h2 = thread::spawn(move || data2[mid..].iter().sum::<i64>());

    h1.join().unwrap() + h2.join().unwrap()
}
```

### Good

```rust
use std::thread;

fn parallel_sum(data: &[i64]) -> i64 {
    let mid = data.len() / 2;
    let (left, right) = data.split_at(mid);

    thread::scope(|s| {
        let h1 = s.spawn(|| left.iter().sum::<i64>());
        let h2 = s.spawn(|| right.iter().sum::<i64>());
        h1.join().unwrap() + h2.join().unwrap()
    })
}

// Mutable borrows work too — as long as they don't alias
fn parallel_fill(left: &mut [u8], right: &mut [u8]) {
    thread::scope(|s| {
        s.spawn(|| left.fill(0xAA));
        s.spawn(|| right.fill(0xBB));
    });
    // both halves have been written; scope guarantees completion
}
```

### Key Points

- The closure passed to `thread::scope` receives a `Scope<'env, '_>` handle; threads spawned via `s.spawn(...)` can borrow anything alive in `'env`.
- All threads are joined automatically when the scope returns — even on panic.
- A panicking child thread causes `thread::scope` itself to panic after joining all remaining children.
- For CPU-bound data-parallel work over large collections, prefer rayon's `par_iter()`, which handles chunking and work-stealing automatically.

### When to Use

- Short-lived parallel tasks that share read-only or non-overlapping mutable references to local data
- You need explicit thread control (pinning, priority) that rayon doesn't expose
- Parallelizing a fixed number of distinct sub-tasks (not a homogeneous collection)

Related: `own-arc-shared`, `conc-rayon-par-iter`, `async-spawn-blocking`

## conc-atomic-ordering

> Use the weakest correct memory `Ordering` for every atomic operation

### Why It Matters

Defaulting to `SeqCst` (sequentially consistent) on every atomic is a common correctness-first shortcut, but it carries real cost: on x86 the difference is small, but on ARM and RISC-V weaker orderings map to cheaper instructions while `SeqCst` requires full memory barriers. More importantly, choosing the wrong ordering — even a weaker one — is a correctness bug that causes data races the compiler won't catch. Understanding the four practical levels lets you write both correct and efficient concurrent code.

### Bad

```rust
use std::sync::atomic::{AtomicU64, AtomicBool, Ordering};

static COUNTER: AtomicU64 = AtomicU64::new(0);
static READY: AtomicBool = AtomicBool::new(false);
static mut DATA: u64 = 0;

// SeqCst everywhere — correct, but unnecessarily expensive
fn increment() {
    COUNTER.fetch_add(1, Ordering::SeqCst);
}

fn producer() {
    unsafe { DATA = 42; }
    READY.store(true, Ordering::SeqCst); // overkill for a single flag
}

fn consumer() -> Option<u64> {
    if READY.load(Ordering::SeqCst) {
        Some(unsafe { DATA })
    } else {
        None
    }
}
```

### Good

```rust
use std::sync::atomic::{AtomicU64, AtomicBool, Ordering};

static COUNTER: AtomicU64 = AtomicU64::new(0);

// Relaxed: no ordering relative to other memory — fine for independent counters
fn increment() {
    COUNTER.fetch_add(1, Ordering::Relaxed);
}

fn total() -> u64 {
    COUNTER.load(Ordering::Relaxed)
}

// Acquire/Release: paired handoff — producer writes data THEN sets flag (Release);
// consumer loads flag (Acquire) and is guaranteed to see the preceding write.
static READY: AtomicBool = AtomicBool::new(false);
static VALUE: AtomicU64 = AtomicU64::new(0);

fn producer(value: u64) {
    VALUE.store(value, Ordering::Relaxed);   // write payload first
    READY.store(true, Ordering::Release);    // publish with Release
}

fn consumer() -> Option<u64> {
    if READY.load(Ordering::Acquire) {       // synchronize with Release store
        Some(VALUE.load(Ordering::Relaxed))  // payload visible after Acquire
    } else {
        None
    }
}

// SeqCst: only when you need a single total order across *multiple* atomics.
// Example: Dekker-style mutual exclusion involving two independent flags.
```

### Ordering Quick Reference

| Ordering | Use when |
|----------|----------|
| `Relaxed` | Operation is atomic but needs no ordering relative to other memory (counters, stats) |
| `Acquire` | Load that must see all stores preceding a matching `Release` on another thread |
| `Release` | Store that must be visible before a matching `Acquire` load on another thread |
| `AcqRel` | Read-modify-write (e.g. `compare_exchange`) acting as both Acquire and Release |
| `SeqCst` | Need a single global order observed by all threads across multiple atomic variables |

### Verification with loom

Use the `loom` crate to exhaustively verify ordering choices for small concurrent units — it explores all interleavings the C11 memory model permits:

```rust
#[cfg(loom)]
use loom::sync::atomic::{AtomicBool, Ordering};

#[cfg(loom)]
#[test]
fn test_handoff() {
    loom::model(|| {
        // ... spawn threads, assert invariants
    });
}
```

Related: `own-mutex-interior`, `test-loom-concurrency`, `conc-scoped-threads`

## conc-thread-local

> Prefer `thread_local!` with `Cell`/`RefCell` over `static mut`

### Why It Matters

`static mut` requires `unsafe` at every access and is undefined behavior if any two threads touch it simultaneously — the compiler cannot rule that out. In Rust 2024, taking a shared or mutable reference to a `static mut` is a hard error (`static_mut_refs`). `thread_local!` gives each thread its own independent copy of the value, accessed through safe APIs via `Cell` (for `Copy` types) or `RefCell` (for anything else), with no synchronization overhead and no unsafe code needed.

### Bad

```rust
// Rust 2024: referencing static mut is a hard error (static_mut_refs lint)
static mut BUFFER: Vec<u8> = Vec::new();

fn append_to_buffer(data: &[u8]) {
    // UB if called from multiple threads; hard error in 2024 edition
    unsafe {
        BUFFER.extend_from_slice(data);
    }
}

fn flush_buffer() -> Vec<u8> {
    unsafe {
        std::mem::take(&mut BUFFER) // still requires unsafe
    }
}
```

### Good

```rust
use std::cell::RefCell;

thread_local! {
    static BUFFER: RefCell<Vec<u8>> = RefCell::new(Vec::with_capacity(4096));
}

fn append_to_buffer(data: &[u8]) {
    BUFFER.with_borrow_mut(|buf| buf.extend_from_slice(data));
}

fn flush_buffer() -> Vec<u8> {
    BUFFER.with_borrow_mut(|buf| std::mem::take(buf))
}
```

For `Copy` types, `Cell` is simpler (no borrow overhead):

```rust
use std::cell::Cell;

thread_local! {
    static CALL_COUNT: Cell<u32> = Cell::new(0);
}

fn record_call() {
    CALL_COUNT.with(|c| c.set(c.get() + 1));
}

fn get_call_count() -> u32 {
    CALL_COUNT.with(|c| c.get())
}
```

### Key Points

- `with_borrow` / `with_borrow_mut` are stable convenience methods (since 1.73) on `LocalKey<RefCell<T>>` — prefer them over the longer `with(|v| v.borrow_mut())` form.
- Thread-local destructors run when the thread exits, so cleanup happens automatically.
- Avoid storing thread-locals in types that are sent across threads; the value is strictly per-thread and is not visible to other threads.
- For read-only global constants shared across threads, use `static` with an immutable type instead.

### When to Use

- Scratch buffers, caches, or accumulators that are logically per-thread and don't need to be shared
- Reusing allocations across calls within a single thread (e.g., formatting buffers, temporary vecs)
- Replacing `unsafe static mut` with a safe alternative

Related: `own-refcell-interior`, `own-mutex-interior`
