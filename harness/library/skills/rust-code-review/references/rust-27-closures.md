---
name: rust-27-closures
description: Rust rules module 27: Closures. 5 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `closure-`
---

# Closures

Priority: MEDIUM. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `closure-fn-trait-bounds` - Require the least restrictive `Fn` trait a callback needs (`FnOnce` ⊇ `FnMut` ⊇ `Fn`)
- `closure-impl-fn-return` - Return closures as `impl Fn`/`FnMut`/`FnOnce`, not `Box<dyn Fn>`
- `closure-move-capture` - Use `move` for closures that outlive the current scope; clone before `move` to keep the original
- `closure-static-vs-dyn` - Accept `impl Fn` (generic) for hot callbacks; use `&dyn Fn`/`Box<dyn Fn>` to cut code size or to store them
- `closure-disjoint-capture` - Capture only what you use; lean on edition-2021 disjoint closure captures

---

## closure-fn-trait-bounds

> Require the least restrictive `Fn` trait a callback needs (`FnOnce` ⊇ `FnMut` ⊇ `Fn`)

### Why It Matters

`FnOnce` is implemented by every closure — it may consume its captures and can only be called once. `FnMut` is implemented by closures that mutate captures, and implies `FnOnce`. `Fn` is the strictest: it only reads captures and can be called any number of times concurrently. Bounding a parameter with the weakest trait the body actually requires accepts the widest set of callers. Requiring `Fn` when you only call the closure once needlessly rejects move-consuming closures.

### Bad

```rust
// F: Fn is too strict — the closure is only called once,
// so move-consuming closures are unnecessarily rejected.
fn run_once_bad<F: Fn() -> String>(f: F) -> String {
    f()
}

fn demo_bad() {
    let s = String::from("hello");
    // This closure consumes `s`, so it only implements FnOnce, not Fn.
    // run_once_bad(move || s) // compile error: `s` moved in closure
    let _ = run_once_bad(|| String::from("ok")); // forced to use non-consuming closure
}
```

### Good

```rust
// Use FnOnce when you call the closure exactly once.
fn run_once<F: FnOnce() -> String>(f: F) -> String {
    f()
}

// Use FnMut when you call the closure multiple times and it may mutate state.
fn retry<F: FnMut() -> bool>(mut f: F, attempts: usize) -> bool {
    for _ in 0..attempts {
        if f() {
            return true;
        }
    }
    false
}

// Use Fn when you call the closure multiple times and need it shareable/re-entrant.
fn for_each<T, F: Fn(&T)>(items: &[T], f: F) {
    for item in items {
        f(item);
    }
}

fn demo() {
    // FnOnce: move-consuming closure is accepted
    let s = String::from("hello");
    let result = run_once(move || s.to_uppercase());
    assert_eq!(result, "HELLO");

    // FnMut: closure mutates a counter
    let mut count = 0usize;
    let found = retry(
        || {
            count += 1;
            count == 3
        },
        5,
    );
    assert!(found);

    // Fn: read-only closure, called once per element
    let nums = vec![1, 2, 3];
    for_each(&nums, |n| println!("{n}"));
}
```

### Key Points

| Trait | Captures | Calls | Accepts |
|-------|----------|-------|---------|
| `FnOnce` | may consume | exactly once | all closures |
| `FnMut` | may mutate | multiple | non-consuming |
| `Fn` | read-only | multiple / shared | pure closures |

- `FnMut` requires `mut f` at the call site (the parameter or binding must be `mut`).
- `Fn: FnMut: FnOnce` — a `Fn` closure satisfies an `FnOnce` bound, not the other way around.
- Standard library examples: `Iterator::map` uses `FnMut`; `thread::spawn` uses `FnOnce + Send + 'static`.

Related: `closure-static-vs-dyn`, `closure-move-capture`

## closure-impl-fn-return

> Return closures as `impl Fn`/`FnMut`/`FnOnce`, not `Box<dyn Fn>`

### Why It Matters

`impl Fn` in return position names the closure's concrete (but unnameable) type and enables static dispatch with no heap allocation. `Box<dyn Fn>` adds an allocation and a virtual call every time the closure is invoked. The opaque `impl Trait` syntax was designed precisely for this use case. Reach for `Box<dyn Fn>` only when the function must return *different* closure types depending on runtime conditions, or when the closure must be stored in a struct field or collection.

### Bad

```rust
// Allocates on the heap for no benefit — single concrete closure type.
fn adder_bad(n: i32) -> Box<dyn Fn(i32) -> i32> {
    Box::new(move |x| x + n)
}

fn multiplier_bad(n: i32) -> Box<dyn Fn(i32) -> i32> {
    Box::new(move |x| x * n)
}
```

### Good

```rust
// Zero allocation, statically dispatched.
fn adder(n: i32) -> impl Fn(i32) -> i32 {
    move |x| x + n
}

fn multiplier(n: i32) -> impl Fn(i32) -> i32 {
    move |x| x * n
}

fn apply(f: impl Fn(i32) -> i32, value: i32) -> i32 {
    f(value)
}

fn demo() {
    let add5 = adder(5);
    let mul3 = multiplier(3);

    assert_eq!(apply(add5, 10), 15);
    assert_eq!(apply(mul3, 10), 30);
}
```

### Key Points

**When `Box<dyn Fn>` is required:**

Different `if`/`match` arms return distinct closure types, so `impl Fn` cannot unify them:

```rust
fn make_transform(double: bool) -> Box<dyn Fn(i32) -> i32> {
    if double {
        Box::new(|x| x * 2)   // one concrete type
    } else {
        Box::new(|x| x + 100) // different concrete type
    }
    // `impl Fn` would fail: "expected closure, found a different closure"
}

// Storing heterogeneous closures also requires boxing:
struct Pipeline {
    steps: Vec<Box<dyn Fn(i32) -> i32>>,
}

impl Pipeline {
    fn new() -> Self {
        Self { steps: Vec::new() }
    }

    fn add_step(&mut self, f: impl Fn(i32) -> i32 + 'static) {
        self.steps.push(Box::new(f));
    }

    fn run(&self, mut value: i32) -> i32 {
        for step in &self.steps {
            value = step(value);
        }
        value
    }
}

fn demo_pipeline() {
    let mut p = Pipeline::new();
    p.add_step(|x| x + 1);
    p.add_step(|x| x * 3);
    assert_eq!(p.run(4), 15);
}
```

**Returning `FnMut`:** The binding at the call site must be `mut`.

```rust
fn counter(start: i32) -> impl FnMut() -> i32 {
    let mut n = start;
    move || {
        let current = n;
        n += 1;
        current
    }
}

fn demo_counter() {
    let mut next = counter(0);
    assert_eq!(next(), 0);
    assert_eq!(next(), 1);
}
```

Related: `anti-type-erasure`, `closure-static-vs-dyn`

## closure-move-capture

> Use `move` for closures that outlive the current scope; clone before `move` to keep the original

### Why It Matters

A closure that borrows its environment can only live as long as that environment. When a closure escapes — passed to a new thread, stored in a struct, or returned from a function — it must own its captures and typically must be `'static`. The `move` keyword transfers ownership of every captured variable into the closure. If you need the value in both the closure and the surrounding code, clone it first and move the clone.

### Bad

```rust
fn make_greeter_bad(name: String) -> impl Fn() {
    // `name` is borrowed, but the closure outlives the function frame —
    // the compiler rejects this with a lifetime error.
    // || println!("hello, {name}")  // error: `name` does not live long enough
    move || println!("hello, {name}") // must be move — shown here to illustrate the fix
}

fn spawn_bad() {
    let data = vec![1, 2, 3];
    // Borrowing `data` across a thread boundary is rejected:
    // std::thread::spawn(|| println!("{data:?}")); // error: borrowed value does not live long enough
    let _ = data; // suppress unused warning
}
```

### Good

```rust
fn process(data: &[i32]) -> i32 {
    data.iter().sum()
}

// Return a closure that owns its capture via `move`.
fn make_greeter(name: String) -> impl Fn() {
    move || println!("hello, {name}")
}

// Clone before `move` when you need the value in both places.
fn spawn_and_keep(data: Vec<i32>) -> std::thread::JoinHandle<i32> {
    let data_for_thread = data.clone(); // clone goes into the closure
    let handle = std::thread::spawn(move || process(&data_for_thread));
    // `data` is still available here
    println!("original still owned: {data:?}");
    handle
}

fn demo() {
    let greet = make_greeter(String::from("world"));
    greet(); // prints: hello, world

    let nums = vec![10, 20, 30];
    let handle = spawn_and_keep(nums);
    let sum = handle.join().unwrap();
    assert_eq!(sum, 60);
}
```

### Key Points

- **Thread closures** passed to `std::thread::spawn` must be `'static`, which `move` enables when all captured types are `'static + Send`.
- **Clone selectively:** clone only what the closure needs, not the whole owning struct — see [closure-disjoint-capture](closure-disjoint-capture.md).
- **Async tasks** follow the same rule: `tokio::spawn(async move { … })` takes ownership; clone shared data before the `async move` block.
- A `move` closure can still implement `Fn` or `FnMut` — `move` only controls *how* captures are taken, not how many times the closure can be called.

Related: `async-clone-before-await`, `own-move-large`, `closure-disjoint-capture`

## closure-static-vs-dyn

> Accept `impl Fn` (generic) for hot callbacks; use `&dyn Fn`/`Box<dyn Fn>` to cut code size or to store them

### Why It Matters

A generic parameter `F: Fn(…) -> …` (or `impl Fn`) monomorphizes at each call site: the compiler emits a specialized copy of the function, enabling inlining and zero-cost dispatch. The trade-off is binary bloat when many different closure types are substituted. `&dyn Fn`/`Box<dyn Fn>` share a single compiled copy via a vtable, which reduces code size and is the only option for storing heterogeneous closures (e.g. an event handler registry). Choose by profiling requirements, not habit.

### Bad

```rust
// Storing closures generically in a struct is impossible — the struct
// would need a type parameter per handler, making it unusable.
struct BadRegistry<F: Fn(&str)> {
    // Can only hold ONE concrete closure type — defeats the purpose.
    handler: F,
}

// Equally, using Box<dyn Fn> on a hot, single-call-site inner loop
// pays a vtable cost for no benefit.
fn transform_slow(xs: &[i32], f: &dyn Fn(i32) -> i32) -> Vec<i32> {
    xs.iter().map(|&x| f(x)).collect()
}
```

### Good

```rust
// Generic / static dispatch: preferred for hot paths — inlinable, zero allocation.
fn transform<F: Fn(i32) -> i32>(xs: &[i32], f: F) -> Vec<i32> {
    xs.iter().map(|&x| f(x)).collect()
}

// Dynamic dispatch: required when storing heterogeneous closures.
struct Registry {
    handlers: Vec<Box<dyn Fn(&str)>>,
}

impl Registry {
    fn new() -> Self {
        Self { handlers: Vec::new() }
    }

    fn register(&mut self, handler: impl Fn(&str) + 'static) {
        self.handlers.push(Box::new(handler));
    }

    fn dispatch(&self, event: &str) {
        for handler in &self.handlers {
            handler(event);
        }
    }
}

fn demo() {
    // Static dispatch — the compiler may inline the closure entirely.
    let doubled = transform(&[1, 2, 3], |x| x * 2);
    assert_eq!(doubled, vec![2, 4, 6]);

    // Dynamic dispatch — one compiled copy, heterogeneous handlers.
    let mut reg = Registry::new();
    reg.register(|e| println!("logger: {e}"));
    reg.register(|e| println!("metrics: {e}"));
    reg.dispatch("user_signup");
}
```

### Decision Table

| Situation | Use |
|-----------|-----|
| Hot inner loop, single call site | `impl Fn` / generic `F: Fn` |
| Callback stored in a struct field | `Box<dyn Fn>` |
| Collection of mixed closures | `Vec<Box<dyn Fn(…)>>` |
| Pass-through, one level deep, not stored | `&dyn Fn` (avoids allocation) |
| Called across an `await` point | `Box<dyn Fn + Send>` |

**Note:** `&dyn Fn` is useful to avoid an allocation when you only need to borrow the closure for one call and do not store it. Pass `&closure` (reference to a stack-allocated closure) rather than boxing.

```rust
fn call_once_dyn(f: &dyn Fn() -> i32) -> i32 {
    f()
}

fn demo_ref() {
    let x = 7;
    let result = call_once_dyn(&|| x + 1);
    assert_eq!(result, 8);
}
```

Related: `anti-type-erasure`, `type-generic-bounds`, `closure-fn-trait-bounds`

## closure-disjoint-capture

> Capture only what you use; lean on edition-2021 disjoint closure captures

### Why It Matters

Before the 2021 edition, a closure captured entire variables — using `config.threshold` pulled in the whole `config` struct, preventing other code from using any other field of `config` concurrently. Since Rust 2021, closures capture individual fields (`config.threshold` only), so sibling fields remain independently accessible. Take advantage of this: write closures that reference only the specific fields or values they need, and add `move` only when ownership is genuinely required. When you do need to `move` a single field, bind it to a local first so the rest of the struct stays usable.

### Bad

```rust
struct Config {
    threshold: i32,
    label: String,
}

fn demo_bad() {
    let config = Config { threshold: 10, label: String::from("demo") };

    // In pre-2021 editions the whole `config` is captured, blocking access
    // to `config.label` below. In 2021 this compiles, but the pattern of
    // capturing the whole struct via `move` is the real footgun:
    let threshold = config.threshold; // copy out the field first
    let check = move || threshold > 0; // now `config` is NOT fully moved

    // If instead you wrote: let check = move || config.threshold > 0;
    // `config` would be moved in, making `config.label` inaccessible afterwards.
    // Demonstrate the problematic pattern (commented out to allow compilation):
    // let check2 = move || config.threshold > 0;
    // println!("{}", config.label); // error: use of moved value

    println!("label still accessible: {}", config.label);
    assert!(check());
}
```

### Good

```rust
struct Config {
    threshold: i32,
    label: String,
}

fn demo_good() {
    let config = Config { threshold: 10, label: String::from("active") };

    // Edition 2021: the closure captures only `config.threshold` (a Copy field).
    // `config.label` is NOT captured, so it remains accessible.
    let check = || config.threshold > 0;

    // Both are usable simultaneously.
    println!("label: {}", config.label);  // fine — not captured by `check`
    assert!(check());
}

// When you need `move` for one field, bind it first.
fn make_checker(config: Config) -> (impl Fn() -> bool, String) {
    // Bind the field to a local, then move only that local into the closure.
    let threshold = config.threshold;
    let checker = move || threshold > 0; // moves `threshold` (i32, Copy), not `config`

    // `config.label` is still available here.
    (checker, config.label)
}

fn demo_bind_first() {
    let cfg = Config { threshold: 5, label: String::from("info") };
    let (check, label) = make_checker(cfg);
    println!("label returned: {label}");
    assert!(check());
}
```

### Key Points

- **Edition 2021 rule:** closures capture the *minimal* path used — `foo.bar` rather than `foo`. This reduces spurious borrow conflicts.
- **`move` captures the whole named place.** Writing `move || self.field` inside a method moves `*self`, not just `self.field`. Bind to a local to narrow the capture.
- **Copy types** (integers, booleans) are copied into the closure rather than moved, so the original remains valid even with `move`.
- **Borrow by reference first:** only escalate to `move` when the closure must outlive the scope (see [closure-move-capture](closure-move-capture.md)).

Related: `own-borrow-over-clone`, `closure-move-capture`
