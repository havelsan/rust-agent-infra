---
name: rust-08-unsafe
description: Rust rules module 08: Unsafe Code. 7 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `unsafe-`
---

# Unsafe Code

Priority: CRITICAL. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `unsafe-safety-comment` - Write a `// SAFETY:` comment above every `unsafe` block and a `# Safety` section in every `unsafe fn`.
- `unsafe-minimize-scope` - Keep `unsafe` blocks as small as possible — mark only the operation that requires unsafety, not the surrounding safe code.
- `unsafe-miri-ci` - Run `cargo miri test` in CI for every crate that contains `unsafe` code.
- `unsafe-maybeuninit` - Use `MaybeUninit<T>` for uninitialized memory; never use `mem::uninitialized()` or `mem::zeroed()` for types with validity invariants.
- `unsafe-extern-block` - In Rust 2024, wrap `extern` blocks in `unsafe extern { }` and annotate each item as `safe` or `unsafe`.
- `unsafe-send-sync-manual` - Document the invariants when manually implementing `Send` or `Sync`; prefer letting the compiler derive them automatically.
- `unsafe-no-mangle-unsafe` - In Rust 2024, write `#[unsafe(no_mangle)]`, `#[unsafe(export_name = "...")]`, and `#[unsafe(link_section = "...")]` — not the bare attribute forms.

---

## unsafe-safety-comment

> Write a `// SAFETY:` comment above every `unsafe` block and a `# Safety` section in every `unsafe fn`.

### Why It Matters

Unsafe blocks are unauditable without justification. A reviewer cannot verify invariants they cannot read. The `clippy::undocumented_unsafe_blocks` lint enforces this mechanically. The standard library, tokio, and bevy all require both forms before merging unsafe code.

There are two distinct levels of documentation:

1. **`# Safety` in a doc comment on an `unsafe fn`** — describes the *caller's* obligations (preconditions that must hold for the call to be sound).
2. **`// SAFETY:` inline comment above each `unsafe {}` block** — explains why *this specific operation* upholds the required invariants at the call site.

Both are required. Omitting either leaves an auditor unable to verify soundness.

### Bad

```rust
// unsafe fn with no # Safety section — caller has no idea what's required
pub unsafe fn read_at(ptr: *const u8, offset: usize) -> u8 {
    // no SAFETY comment — why is this dereference sound?
    unsafe { *ptr.add(offset) }
}

// standalone block with no justification
fn process(slice: &[u8]) -> u8 {
    unsafe { *slice.as_ptr().add(10) }
}
```

### Good

```rust
/// Returns the byte at `ptr + offset`.
///
/// # Safety
///
/// - `ptr` must be valid for reads for at least `offset + 1` bytes.
/// - `ptr` must not be null and must be properly aligned for `u8`.
/// - The memory must not be mutated for the duration of this call.
pub unsafe fn read_at(ptr: *const u8, offset: usize) -> u8 {
    // SAFETY: caller guarantees ptr is valid for at least offset + 1 bytes,
    // so ptr.add(offset) is in bounds and dereferenceable.
    unsafe { *ptr.add(offset) }
}

fn process(slice: &[u8]) -> Option<u8> {
    if slice.len() > 10 {
        // SAFETY: we just checked that slice has at least 11 elements,
        // so index 10 is within bounds.
        Some(unsafe { *slice.as_ptr().add(10) })
    } else {
        None
    }
}
```

### Key Points

- A `# Safety` doc section and a `// SAFETY:` inline comment serve different audiences: the doc section targets *callers*, the inline comment targets *auditors* of the implementation.
- Enable the lint explicitly to catch omissions:
  ```rust
  #![warn(clippy::undocumented_unsafe_blocks)]
  ```
- When an unsafe block spans multiple operations, write one `// SAFETY:` comment that addresses each distinct invariant, or split into multiple smaller blocks (see `unsafe-minimize-scope`).
- In an `unsafe fn`, the body still requires `// SAFETY:` comments for each inner `unsafe {}` block under the 2024 edition's `unsafe_op_in_unsafe_fn` lint.

Related: `unsafe-minimize-scope`, `lint-unsafe-doc`, `doc-safety-section`

## unsafe-minimize-scope

> Keep `unsafe` blocks as small as possible — mark only the operation that requires unsafety, not the surrounding safe code.

### Why It Matters

When an entire function is marked `unsafe fn`, every line inside appears equally suspect to an auditor. Shrinking unsafe blocks to the minimum isolates exactly which operation violates Rust's safety invariants, making reviews tractable and bugs easier to find. The Rust 2024 edition enforces this with the `unsafe_op_in_unsafe_fn` lint: unsafe operations inside an `unsafe fn` now require their own explicit `unsafe {}` block rather than inheriting the function's unsafety implicitly.

### Bad

```rust
// Entire function body marked unsafe — safe arithmetic, bounds checks,
// and the single unsafe dereference are all equally "dangerous" to a reader.
unsafe fn sum_at(ptr: *const i32, len: usize, index: usize) -> i32 {
    let adjusted_len = len.saturating_sub(1); // safe — but looks unsafe
    assert!(index <= adjusted_len);           // safe — but looks unsafe
    let value = *ptr.add(index);              // the only actually unsafe op
    value + 1                                 // safe — but looks unsafe
}
```

```rust
// Huge unsafe block wrapping safe logic inside an unsafe fn (2024 edition
// now requires unsafe {} here anyway, but large blocks are still bad style).
pub unsafe fn process(ptr: *const u8, len: usize) -> Vec<u8> {
    unsafe {
        let mut result = Vec::with_capacity(len); // safe
        for i in 0..len {                         // safe
            result.push(*ptr.add(i));             // unsafe — buried in noise
        }
        result
    }
}
```

### Good

```rust
// Safe wrapper: the single unsafe operation is clearly isolated.
fn sum_at(ptr: *const i32, len: usize, index: usize) -> i32 {
    assert!(index < len, "index out of bounds");
    // SAFETY: index < len guarantees ptr.add(index) is within the allocation.
    let value = unsafe { *ptr.add(index) };
    value + 1
}
```

```rust
// In a genuinely unsafe fn, 2024 edition still requires unsafe {} per op.
/// # Safety
///
/// `ptr` must be valid for reads for `len` bytes and properly aligned.
pub unsafe fn process(ptr: *const u8, len: usize) -> Vec<u8> {
    let mut result = Vec::with_capacity(len); // safe — outside any unsafe block
    for i in 0..len {
        // SAFETY: caller guarantees ptr is valid for len bytes; i < len.
        let byte = unsafe { *ptr.add(i) };
        result.push(byte);
    }
    result
}
```

### Key Points

- **2024 edition `unsafe_op_in_unsafe_fn`**: even inside an `unsafe fn`, each unsafe operation now needs its own `unsafe {}`. This is a hard error in Rust 2024.
- A safe wrapper around a small `unsafe {}` is almost always preferable to exposing the entire function as `unsafe fn`.
- Each small unsafe block needs its own `// SAFETY:` comment (see `unsafe-safety-comment`).
- If multiple consecutive lines are all unsafe for the *same* invariant reason, a single block covering only those lines is acceptable.

### When a Larger Block Is Acceptable

If two unsafe operations share the *exact same precondition* and separating them would require re-stating the identical justification, a single block covering both is fine — but it should still be the minimum necessary scope.

Related: `unsafe-safety-comment`, `unsafe-send-sync-manual`

## unsafe-miri-ci

> Run `cargo miri test` in CI for every crate that contains `unsafe` code.

### Why It Matters

Miri is the only tool that *dynamically* detects undefined behavior in Rust programs at test time. It catches out-of-bounds memory accesses, use-after-free, reads of uninitialized memory, invalid pointer provenance, data races in `unsafe` multithreaded code, and violations of the Stacked Borrows / Tree Borrows aliasing models. The Rust standard library, tokio, serde, and many foundational crates all run Miri in CI before merging changes that touch unsafe code.

Static analysis and code review can miss subtle UB that only manifests at specific memory layouts; Miri's interpreted execution catches it unconditionally.

### Bad

```yaml
# CI that tests but never runs Miri — unsafe code ships unverified.
- name: Test
  run: cargo test --all-features
```

### Good

```yaml
# .github/workflows/miri.yml
name: Miri

on: [push, pull_request]

jobs:
  miri:
    name: Miri (nightly)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install nightly toolchain with Miri
        run: |
          rustup toolchain install nightly --component miri
          rustup override set nightly
          cargo miri setup

      - name: Run Miri
        env:
          MIRIFLAGS: "-Zmiri-strict-provenance"
        run: cargo miri test --all-features
```

### Key Points

- **Nightly only**: Miri requires a nightly toolchain. Pin a specific nightly date in `rust-toolchain.toml` if you need reproducible CI.
- **Slow**: Miri interprets rather than compiles, so test suites run 100–1000× slower than normal. Run Miri on a reduced set of tests or on a separate slower CI job if the full suite is prohibitive.
- **`MIRIFLAGS`**: `-Zmiri-strict-provenance` enables stricter pointer provenance checks, catching casts that violate the provenance model. Add `-Zmiri-tree-borrows` to opt into the newer Tree Borrows model.
- **Stacked Borrows**: Miri's default aliasing model. It catches violations of Rust's borrow rules at the pointer level — invaluable for raw-pointer and FFI code.
- **Setup command**: `cargo miri setup` pre-builds the Miri sysroot so the first test run is not cold. Run it once per CI cache key.
- Only crates with `unsafe` blocks need Miri coverage. Pure-safe crates gain nothing from it.

### When It's Acceptable to Skip

- Crates with zero `unsafe` code (safe-only crates get no benefit).
- Generated code or proc-macro output you do not control (audit the generator instead).
- Very large integration tests that make Miri impractical — run a targeted unit-test subset instead.

Related: `unsafe-maybeuninit`, `unsafe-safety-comment`, `test-criterion-bench`

## unsafe-maybeuninit

> Use `MaybeUninit<T>` for uninitialized memory; never use `mem::uninitialized()` or `mem::zeroed()` for types with validity invariants.

### Why It Matters

`mem::uninitialized()` was deprecated in Rust 1.39 and is immediate undefined behavior for any type whose bit patterns have validity invariants — `bool` (only `0` and `1` are valid), `&T` (must be non-null and aligned), `NonZeroU32`, `char`, and enum types. Even `mem::zeroed()` triggers UB for references and `NonZero*` types. `MaybeUninit<T>` is the correct abstraction: it wraps uninitialized memory without ever producing an invalid `T`, and the compiler cannot optimize around it incorrectly. The standard library uses `MaybeUninit` pervasively for its data structures.

### Bad

```rust
use std::mem;

// Instant UB: `bool` has validity invariants; uninitialized bits are not
// guaranteed to be 0 or 1. The optimizer may miscompile code that follows.
let b: bool = unsafe { mem::uninitialized() };

// Also UB for references — a zero reference is immediately invalid.
let r: &u32 = unsafe { mem::zeroed() };

// Uninitialized array the wrong way — triggers UB during construction.
let mut buf: [u8; 1024] = unsafe { mem::uninitialized() };
```

### Good

```rust
use std::mem::MaybeUninit;

// ---- 1. Single value ----
let mut x = MaybeUninit::<u32>::uninit();
x.write(42);
// SAFETY: we just wrote a valid u32 via `write`, so the value is initialized.
let value: u32 = unsafe { x.assume_init() };

// ---- 2. Array initialization (manual, element-by-element) ----
// `[const { MaybeUninit::uninit() }; N]` works for any `T` (no `Copy` bound).
let mut buf: [MaybeUninit<u8>; 1024] = [const { MaybeUninit::uninit() }; 1024];
for elem in &mut buf {
    elem.write(0u8);
}
// SAFETY: every element was written above.
// `From<[MaybeUninit<T>; N]> for MaybeUninit<[T; N]>` is stable since Rust 1.95.
let buf: [u8; 1024] = unsafe {
    MaybeUninit::<[u8; 1024]>::from(buf).assume_init()
};

// ---- 3. Growing a Vec into spare capacity ----
fn fill_vec(v: &mut Vec<u8>, extra: usize) {
    v.reserve(extra);
    let spare = v.spare_capacity_mut(); // &mut [MaybeUninit<u8>]
    for slot in spare.iter_mut().take(extra) {
        slot.write(0u8);
    }
    // SAFETY: we initialized `extra` elements in the spare capacity.
    unsafe { v.set_len(v.len() + extra) };
}
```

### Key Points

- **`assume_init` is only sound after every byte is initialized** via `write`, an FFI call that fills the buffer, or another provably complete initialization path. Calling it on partially initialized memory is UB.
- Create arrays of uninitialized memory with `[const { MaybeUninit::uninit() }; N]` (works for any `T`). Convert a fully-initialized `[MaybeUninit<T>; N]` to `[T; N]` via `MaybeUninit::<[T; N]>::from(arr)` then `assume_init()` — these `From` conversions are stable since Rust 1.95. The `MaybeUninit::array_assume_init` helper remains nightly-only (feature `maybe_uninit_array_assume_init`).
- `Vec::spare_capacity_mut` returns `&mut [MaybeUninit<T>]` — the idiomatic way to write into Vec capacity before extending its length.
- For zeroed memory where zero is a valid bit pattern for all fields (e.g. `u8`, `i32`, plain C structs with no references), `mem::zeroed()` is technically sound but `MaybeUninit` is still preferred for clarity.
- `mem::uninitialized` is not just deprecated — it is `#[deprecated(since = "1.39.0")]` and has no safe migration; replace every usage with `MaybeUninit`.

Related: `unsafe-safety-comment`, `mem-with-capacity`

## unsafe-extern-block

> In Rust 2024, wrap `extern` blocks in `unsafe extern { }` and annotate each item as `safe` or `unsafe`.

### Why It Matters

Before Rust 2024, every function declared inside an `extern "C" { }` block was implicitly unsafe to call — but the block itself carried no `unsafe` keyword. This made it easy to forget that the FFI contract (correct types, valid pointers, no aliasing violations) was entirely the programmer's responsibility. Rust 2024 makes this explicit: the block must be `unsafe extern`, which signals that the *programmer* is asserting the declarations are accurate. Individual items can then be marked `safe` (callable without an `unsafe` block by the caller) or `unsafe` (the default — caller must use `unsafe {}`).

This change makes FFI boundaries auditable at a glance and lets wrappers expose a safe API while keeping raw declarations accurate.

### Bad

```rust
// Rust 2021 style — compiles but forbidden in 2024 edition
extern "C" {
    fn strlen(s: *const std::ffi::c_char) -> usize;
    fn memcpy(dst: *mut u8, src: *const u8, n: usize) -> *mut u8;
    static errno: std::ffi::c_int;
}
```

### Good

```rust
// Rust 2024 style
unsafe extern "C" {
    // `strlen` is genuinely unsafe: caller must pass a null-terminated pointer.
    pub unsafe fn strlen(s: *const std::ffi::c_char) -> usize;

    // `memcpy` is unsafe: caller must ensure non-overlapping, valid regions.
    pub unsafe fn memcpy(dst: *mut u8, src: *const u8, n: usize) -> *mut u8;

    // A function that is always safe to call (hypothetical pure query).
    pub safe fn rust_version_major() -> u32;

    // Statics are unsafe to access unless you can guarantee no data races.
    pub unsafe static errno: std::ffi::c_int;
}

// Call sites remain unchanged for `unsafe` items:
fn copy_bytes(dst: *mut u8, src: *const u8, n: usize) {
    // SAFETY: dst and src are non-overlapping, both valid for n bytes.
    unsafe { memcpy(dst, src, n) };
}

// Call sites for `safe` items need no unsafe block:
fn show_version() {
    println!("major: {}", rust_version_major());
}
```

### Migration from 2021

| 2021 | 2024 |
|------|------|
| `extern "C" { fn foo(); }` | `unsafe extern "C" { unsafe fn foo(); }` |
| `extern "C" { fn bar(); }` (safe to call) | `unsafe extern "C" { safe fn bar(); }` |
| `extern "C" { static X: i32; }` | `unsafe extern "C" { unsafe static X: i32; }` |

Run `cargo fix --edition` to apply the mechanical part of this migration automatically. Review each item afterward to decide whether `safe` is warranted.

### Key Points

- The `unsafe` on the block means "I assert these declarations faithfully describe the external ABI". It does not make calls to the items safe by itself.
- Marking an item `safe` is a promise: if that item is actually unsafe to call, adding `safe` is itself unsound — the compiler will not catch a wrong annotation.
- `bindgen` (0.70+) and `cbindgen` have been updated to emit `unsafe extern` blocks for Rust 2024 output. Update your code generator if you use one.
- The `extern "Rust"` ABI for cross-crate `#[no_mangle]` functions follows the same rules (see `unsafe-no-mangle-unsafe`).

Related: `unsafe-no-mangle-unsafe`, `type-repr-transparent`

## unsafe-send-sync-manual

> Document the invariants when manually implementing `Send` or `Sync`; prefer letting the compiler derive them automatically.

### Why It Matters

`Send` and `Sync` are `unsafe` auto-traits. The compiler derives them automatically and correctly for most types — manual implementations signal that the borrow checker cannot verify the invariant on its own. Get it wrong and you introduce data races that are impossible to catch with safe code. A manual `unsafe impl Send` without a clear justification is a liability: the next person to modify the type's fields may silently break the invariant without realizing the impl is load-bearing.

### Bad

```rust
use std::cell::Cell;
use std::sync::Arc;

// Cell<T> is !Sync because it allows non-atomic interior mutation.
// This manual impl removes that protection with no explanation.
struct SharedCounter {
    value: Cell<u32>,
}

unsafe impl Sync for SharedCounter {} // data race waiting to happen — no SAFETY comment
unsafe impl Send for SharedCounter {} // likewise
```

```rust
// Wrapping a raw pointer but forgetting to opt out of auto-Send/Sync.
struct MyBuffer {
    ptr: *mut u8,
    len: usize,
}
// *mut u8 is already !Send + !Sync, so the compiler correctly withholds
// auto-impls — but if you blindly add unsafe impls without justification,
// you may send the pointer to another thread while something else mutates it.
unsafe impl Send for MyBuffer {}  // no SAFETY: comment — why is this sound?
```

### Good

```rust
use std::marker::PhantomData;

// ---- 1. Opt OUT of Send/Sync using PhantomData ----
// If your type logically owns a *const T (e.g. an intrusive pointer),
// use PhantomData to prevent the compiler from auto-deriving Send/Sync.
struct IntrinsiveRef<T> {
    ptr: *const T,
    // PhantomData<*const T> makes this type !Send + !Sync automatically,
    // matching the semantics of a raw non-owning pointer.
    _marker: PhantomData<*const T>,
}
// No unsafe impl needed — the compiler correctly withholds Send/Sync.

// ---- 2. Opt IN with a documented unsafe impl ----
use std::sync::Mutex;

/// A buffer owned exclusively by one thread at a time.
/// The raw pointer always points to a heap allocation this struct owns;
/// no other reference to that allocation exists outside this struct.
struct OwnedBuffer {
    ptr: *mut u8,
    len: usize,
}

// SAFETY: OwnedBuffer owns its allocation exclusively (no aliasing),
// and access is protected by the caller's Mutex<OwnedBuffer> at usage sites.
// The pointer is valid for the entire lifetime of OwnedBuffer.
unsafe impl Send for OwnedBuffer {}

// SAFETY: OwnedBuffer exposes no shared mutation — all methods require &mut self.
// Concurrent & references cannot mutate the buffer.
unsafe impl Sync for OwnedBuffer {}

// ---- 3. Prefer newtype wrappers around Arc for sharing ----
// Instead of manual Sync, wrap in Arc<Mutex<T>> so the compiler handles it.
use std::sync::Arc;

struct SafeCounter {
    value: Mutex<u32>,
}

// Arc<Mutex<u32>> is Send + Sync automatically — no manual impl required.
fn make_shared() -> Arc<SafeCounter> {
    Arc::new(SafeCounter { value: Mutex::new(0) })
}
```

### Key Points

- **Auto-derive first**: if your type consists entirely of `Send`/`Sync` fields, the compiler derives the traits for free. Only reach for manual impls when raw pointers, `Cell`, or other non-auto types are involved.
- **`PhantomData<*const T>`** is the canonical way to make a type `!Send + !Sync` — `*const T` is already `!Send + !Sync`, so the marker propagates without any `unsafe impl`.
- **`PhantomData<*mut T>`** makes a type `!Send + !Sync` and also marks it as if it mutably borrows a `T` (useful for invariance over `T`).
- Every `unsafe impl Send`/`unsafe impl Sync` must carry a `// SAFETY:` comment explaining which invariant the programmer is upholding and why it holds.
- Adding `unsafe impl Send` to a type that contains a `Rc<T>` or `Cell<T>` is almost certainly unsound — prefer `Arc<T>` and `Mutex<T>` instead.

Related: `unsafe-safety-comment`, `type-phantom-marker`, `own-arc-shared`

## unsafe-no-mangle-unsafe

> In Rust 2024, write `#[unsafe(no_mangle)]`, `#[unsafe(export_name = "...")]`, and `#[unsafe(link_section = "...")]` — not the bare attribute forms.

### Why It Matters

`#[no_mangle]`, `#[export_name]`, and `#[link_section]` were reclassified as unsafe in Rust 2024 because they can cause undefined behavior without any `unsafe` block at the call site. If two items in the same binary share the same exported symbol name, the linker silently picks one and discards the other — the "winning" symbol may have a completely different type, signature, or semantics. The result is type-level UB with no diagnostic from the compiler or linker. Requiring `#[unsafe(...)]` makes this footgun visible and auditable.

### Bad

```rust
// Rust 2021 — bare attributes accepted, no warning about linker UB
#[no_mangle]
pub extern "C" fn init() {
    // ...
}

#[export_name = "plugin_entry"]
pub fn plugin_main() {
    // ...
}

#[link_section = ".init_array"]
static INIT: extern "C" fn() = init;
```

### Good

```rust
// Rust 2024 — unsafe(...) wrapper makes the risk explicit
#[unsafe(no_mangle)]
pub extern "C" fn init() {
    // ...
}

#[unsafe(export_name = "plugin_entry")]
pub fn plugin_main() {
    // ...
}

#[unsafe(link_section = ".init_array")]
static INIT: extern "C" fn() = init;
```

### Migration

| Rust 2021 | Rust 2024 |
|-----------|-----------|
| `#[no_mangle]` | `#[unsafe(no_mangle)]` |
| `#[export_name = "sym"]` | `#[unsafe(export_name = "sym")]` |
| `#[link_section = ".sec"]` | `#[unsafe(link_section = ".sec")]` |

Run `cargo fix --edition` when migrating to the 2024 edition — it rewrites bare attribute forms to `#[unsafe(...)]` automatically. Review each one afterward: confirm that the exported symbol name is unique across the binary.

### Key Points

- The `unsafe(...)` wrapper does **not** require an `unsafe {}` block at the call site; it marks the *attribute itself* as load-bearing for safety. The annotation documents that the programmer accepted responsibility for symbol uniqueness and ABI correctness.
- Symbol collisions are especially dangerous in plugin architectures, `cdylib` crates, embedded firmware with custom linker scripts, and any codebase that links multiple Rust crates into a single binary.
- These attributes interact with `unsafe extern` blocks (see `unsafe-extern-block`): external symbols you import and symbols you export follow the same 2024-edition safety rules.
- The bare forms (`#[no_mangle]` without `unsafe`) are a hard error in Rust 2024 edition code. They still compile in earlier editions but emit a deprecation warning with `--warn future-incompatible`.

Related: `unsafe-extern-block`, `type-repr-transparent`
