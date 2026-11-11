---
name: rust-01-ownership-1of2
description: Rust rules module 01: Ownership & Borrowing (part 1 of 2). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `own-`
---

# Ownership & Borrowing (part 1/2)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `own-borrow-over-clone` - Prefer `&T` borrowing over `.clone()`
- `own-slice-over-vec` - Accept `&[T]` not `&Vec<T>`, `&str` not `&String`
- `own-cow-conditional` - Use `Cow<'a, T>` for conditional ownership
- `own-arc-shared` - Use `Arc<T>` for thread-safe shared ownership
- `own-rc-single-thread` - Use `Rc<T>` for shared ownership in single-threaded contexts
- `own-refcell-interior` - Use `RefCell<T>` for interior mutability in single-threaded code

---

## own-borrow-over-clone

> Prefer `&T` borrowing over `.clone()`

### Why It Matters

Cloning allocates new memory and copies data, while borrowing is free. Unnecessary clones can significantly impact performance, especially in hot paths or with large data structures.

### Bad

```rust
fn process(data: &String) {
    let local = data.clone();  // Unnecessary allocation!
    println!("{}", local);
}

fn count_words(text: &String) -> usize {
    let owned = text.clone();  // Why clone just to read?
    owned.split_whitespace().count()
}

// Clone in a loop - multiplied cost
fn process_all(items: &[String]) {
    for item in items {
        let copy = item.clone();  // N allocations!
        handle(&copy);
    }
}
```

### Good

```rust
fn process(data: &str) {  // Accept &str, more flexible
    println!("{}", data);  // No allocation needed
}

fn count_words(text: &str) -> usize {
    text.split_whitespace().count()  // Just borrow
}

// Borrow in a loop - zero allocations
fn process_all(items: &[String]) {
    for item in items {
        handle(item);  // Pass reference
    }
}
```

### When Clone Is Acceptable

```rust
// 1. Need owned data for storage
struct Cache {
    data: HashMap<String, String>,
}

impl Cache {
    fn insert(&mut self, key: &str, value: &str) {
        // Clone needed - we're storing owned data
        self.data.insert(key.to_string(), value.to_string());
    }
}

// 2. Need to send across threads
fn spawn_worker(data: &Config) {
    let owned = data.clone();  // Clone needed for 'static
    std::thread::spawn(move || {
        use_config(owned);
    });
}

// 3. Copy types (no heap allocation)
let x: i32 = 42;
let y = x;  // Copy, not clone - this is fine
```

### Evidence

From ripgrep's codebase - uses `Cow` to avoid clones:
```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/globset/src/pathutil.rs
pub(crate) fn file_name<'a>(path: &Cow<'a, [u8]>) -> Option<Cow<'a, [u8]>> {
    match *path {
        Cow::Borrowed(path) => Cow::Borrowed(&path[last_slash..]),
        Cow::Owned(ref path) => Cow::Owned(path.clone()),
    }
}
```

Related: `own-slice-over-vec`, `own-cow-conditional`, `mem-clone-from`, `mem-take-replace`

## own-slice-over-vec

> Accept `&[T]` not `&Vec<T>`, `&str` not `&String`

### Why It Matters

Accepting `&[T]` instead of `&Vec<T>` makes your function more flexible - it can accept slices from arrays, vectors, or other sources. Similarly, `&str` accepts string slices from `String`, `&'static str`, or substrings.

### Bad

```rust
// Overly restrictive - only accepts &Vec
fn sum(numbers: &Vec<i32>) -> i32 {
    numbers.iter().sum()
}

// Overly restrictive - only accepts &String
fn greet(name: &String) {
    println!("Hello, {}", name);
}

// Can't call with arrays or slices
let arr = [1, 2, 3];
// sum(&arr);  // ERROR: expected &Vec<i32>

let literal = "world";
// greet(&literal);  // ERROR: expected &String
```

### Good

```rust
// Flexible - accepts any slice-like thing
fn sum(numbers: &[i32]) -> i32 {
    numbers.iter().sum()
}

// Flexible - accepts any string-like thing
fn greet(name: &str) {
    println!("Hello, {}", name);
}

// Now all of these work:
let vec = vec![1, 2, 3];
let arr = [4, 5, 6];
let slice = &vec[0..2];

sum(&vec);    // Vec coerces to slice
sum(&arr);    // Array coerces to slice
sum(slice);   // Slice works directly

let string = String::from("Alice");
let literal = "Bob";

greet(&string);  // String coerces to &str
greet(literal);  // &str works directly
```

### The Deref Coercion Chain

```rust
// These coercions happen automatically:
// Vec<T>  -> &[T]   (via Deref)
// String  -> &str   (via Deref)
// Box<T>  -> &T     (via Deref)
// Arc<T>  -> &T     (via Deref)

fn process(data: &[u8]) { /* ... */ }

let vec: Vec<u8> = vec![1, 2, 3];
let boxed: Box<[u8]> = vec.into_boxed_slice();
let arc: Arc<[u8]> = Arc::from(&[1, 2, 3][..]);

process(&vec);    // Works
process(&boxed);  // Works
process(&arc);    // Works
```

### Path Types Too

```rust
// Bad
fn read_config(path: &PathBuf) -> Config { /* ... */ }

// Good - accepts &Path, &PathBuf, &str, &String
fn read_config(path: &Path) -> Config { /* ... */ }

// Even better - accept anything path-like
fn read_config(path: impl AsRef<Path>) -> Config {
    let path = path.as_ref();
    // ...
}
```

### When to Accept Owned Types

```rust
// Accept owned when you need to store it
struct Logger {
    prefix: String,  // Needs to own the string
}

impl Logger {
    // Take ownership - caller decides to clone or move
    fn new(prefix: String) -> Self {
        Self { prefix }
    }
    
    // Or use Into for flexibility
    fn with_prefix(prefix: impl Into<String>) -> Self {
        Self { prefix: prefix.into() }
    }
}
```

Related: `api-impl-asref`, `own-borrow-over-clone`

## own-cow-conditional

> Use `Cow<'a, T>` for conditional ownership

### Why It Matters

`Cow` (Clone-on-Write) lets you avoid allocations when you *might* need to own data but usually don't. It holds either a borrowed reference or an owned value, cloning only when mutation is needed.

### Bad

```rust
// Always allocates, even when input doesn't need modification
fn normalize_path(path: &str) -> String {
    if path.contains("//") {
        path.replace("//", "/")  // Allocation needed
    } else {
        path.to_string()  // Unnecessary allocation!
    }
}

// Always clones the error message
fn format_error(code: u32) -> String {
    match code {
        404 => "Not Found".to_string(),      // Unnecessary!
        500 => "Internal Error".to_string(), // Unnecessary!
        _ => format!("Error {}", code),      // This one needs allocation
    }
}
```

### Good

```rust
use std::borrow::Cow;

// Only allocates when needed
fn normalize_path(path: &str) -> Cow<'_, str> {
    if path.contains("//") {
        Cow::Owned(path.replace("//", "/"))  // Allocate
    } else {
        Cow::Borrowed(path)  // Zero-cost borrow
    }
}

// Static strings stay borrowed
fn format_error(code: u32) -> Cow<'static, str> {
    match code {
        404 => Cow::Borrowed("Not Found"),      // No allocation
        500 => Cow::Borrowed("Internal Error"), // No allocation
        _ => Cow::Owned(format!("Error {}", code)), // Allocate only for unknown
    }
}
```

### Real-World Example from ripgrep

```rust
// https://github.com/BurntSushi/ripgrep/blob/master/crates/globset/src/pathutil.rs
pub(crate) fn file_name<'a>(path: &Cow<'a, [u8]>) -> Option<Cow<'a, [u8]>> {
    let last_slash = path.rfind_byte(b'/').map(|i| i + 1).unwrap_or(0);
    match *path {
        Cow::Borrowed(path) => Some(Cow::Borrowed(&path[last_slash..])),
        Cow::Owned(ref path) => {
            let mut path = path.clone();
            path.drain_bytes(..last_slash);
            Some(Cow::Owned(path))
        }
    }
}
```

### Clone-on-Write Pattern

```rust
use std::borrow::Cow;

fn process_text(text: Cow<'_, str>) -> Cow<'_, str> {
    if text.contains("bad_word") {
        // to_mut() clones if borrowed, returns &mut if owned
        let mut owned = text.into_owned();
        owned = owned.replace("bad_word", "***");
        Cow::Owned(owned)
    } else {
        text  // Pass through unchanged
    }
}

// Usage
let borrowed: Cow<str> = Cow::Borrowed("hello world");
let result = process_text(borrowed);  // No allocation!

let with_bad: Cow<str> = Cow::Borrowed("hello bad_word");
let result = process_text(with_bad);  // Allocates only here
```

### Cow with Collections

```rust
use std::borrow::Cow;

// Mixed borrowed/owned in a collection
fn collect_errors<'a>(
    static_errors: &[&'static str],
    dynamic_errors: Vec<String>,
) -> Vec<Cow<'a, str>> {
    let mut errors: Vec<Cow<str>> = Vec::new();
    
    // Static strings - no allocation
    for &e in static_errors {
        errors.push(Cow::Borrowed(e));
    }
    
    // Dynamic strings - take ownership
    for e in dynamic_errors {
        errors.push(Cow::Owned(e));
    }
    
    errors
}
```

### When to Use Cow

| Situation | Use Cow? |
|-----------|----------|
| Usually borrow, sometimes own | Yes |
| Always need owned data | No, just use owned type |
| Always borrow | No, just use reference |
| Hot path, avoiding all allocations | Yes |
| Returning static strings or formatted | Yes |

Related: `own-borrow-over-clone`, `mem-avoid-format`

## own-arc-shared

> Use `Arc<T>` for thread-safe shared ownership

### Why It Matters

`Arc` (Atomic Reference Counted) provides shared ownership across threads. Unlike `Rc`, its reference count is updated atomically, making it safe for concurrent access. Use it when multiple threads need to read the same data.

### Bad

```rust
use std::rc::Rc;
use std::thread;

let data = Rc::new(vec![1, 2, 3]);
let data_clone = Rc::clone(&data);

// ERROR: Rc cannot be sent between threads safely
thread::spawn(move || {
    println!("{:?}", data_clone);
});
```

### Good

```rust
use std::sync::Arc;
use std::thread;

let data = Arc::new(vec![1, 2, 3]);
let data_clone = Arc::clone(&data);

thread::spawn(move || {
    println!("{:?}", data_clone);  // Safe!
});

println!("{:?}", data);  // Original still accessible
```

### Arc with Mutex for Mutable Shared State

```rust
use std::sync::{Arc, Mutex};
use std::thread;

let counter = Arc::new(Mutex::new(0));
let mut handles = vec![];

for _ in 0..10 {
    let counter = Arc::clone(&counter);
    let handle = thread::spawn(move || {
        let mut num = counter.lock().unwrap();
        *num += 1;
    });
    handles.push(handle);
}

for handle in handles {
    handle.join().unwrap();
}

println!("Result: {}", *counter.lock().unwrap());
```

### Arc vs Rc Decision Tree

```
Need shared ownership?
├── No → Use owned value or references
└── Yes → Will it cross thread boundaries?
    ├── No → Use Rc<T> (cheaper, no atomic ops)
    └── Yes → Use Arc<T>
        └── Need mutation?
            ├── No → Arc<T> is enough
            └── Yes → Arc<Mutex<T>> or Arc<RwLock<T>>
```

### Common Patterns

```rust
use std::sync::Arc;

// Shared configuration (read-only)
struct AppConfig {
    database_url: String,
    max_connections: u32,
}

fn setup_workers(config: Arc<AppConfig>) {
    for i in 0..4 {
        let config = Arc::clone(&config);
        std::thread::spawn(move || {
            println!("Worker {} using db: {}", i, config.database_url);
        });
    }
}

// Shared cache with interior mutability
use std::sync::RwLock;
use std::collections::HashMap;

type Cache = Arc<RwLock<HashMap<String, String>>>;

fn get_cached(cache: &Cache, key: &str) -> Option<String> {
    cache.read().unwrap().get(key).cloned()
}

fn set_cached(cache: &Cache, key: String, value: String) {
    cache.write().unwrap().insert(key, value);
}
```

### Performance Considerations

```rust
// Arc::clone is cheap - just increments atomic counter
let a = Arc::new(large_data);
let b = Arc::clone(&a);  // Fast! No data copied

// But atomic operations have overhead vs Rc
// Use Rc in single-threaded contexts for better performance

// Avoid cloning Arc in hot loops if possible
// Bad:
for item in items {
    let arc = Arc::clone(&shared);  // Atomic op each iteration
    process(arc, item);
}

// Better: Clone once outside loop if possible
let arc = Arc::clone(&shared);
for item in items {
    process(&arc, item);  // Pass reference
}
```

Related: `own-rc-single-thread`, `own-mutex-interior`, `async-clone-before-await`, `conc-scoped-threads`, `unsafe-send-sync-manual`

## own-rc-single-thread

> Use `Rc<T>` for shared ownership in single-threaded contexts

### Why It Matters

`Rc<T>` (Reference Counted) provides shared ownership without the atomic overhead of `Arc<T>`. In single-threaded code, `Rc` is faster because it uses non-atomic reference counting. Using `Arc` when you don't need thread-safety wastes CPU cycles on unnecessary synchronization.

### Bad

```rust
use std::sync::Arc;

// Single-threaded application using Arc unnecessarily
fn build_tree() -> Arc<Node> {
    let root = Arc::new(Node::new("root"));
    let child1 = Arc::new(Node::new("child1"));
    let child2 = Arc::new(Node::new("child2"));
    
    // All in same thread, but paying atomic overhead
    root.add_child(child1.clone());
    root.add_child(child2.clone());
    root
}
```

Atomic operations have measurable overhead even without contention.

### Good

```rust
use std::rc::Rc;

// Single-threaded: use Rc for zero atomic overhead
fn build_tree() -> Rc<Node> {
    let root = Rc::new(Node::new("root"));
    let child1 = Rc::new(Node::new("child1"));
    let child2 = Rc::new(Node::new("child2"));
    
    root.add_child(child1.clone());
    root.add_child(child2.clone());
    root
}

// Compiler enforces single-thread: Rc is !Send + !Sync
// Attempting to send across threads = compile error
```

### Decision Guide

| Scenario | Use |
|----------|-----|
| Single-threaded, shared ownership | `Rc<T>` |
| Multi-threaded, shared ownership | `Arc<T>` |
| Single owner, might need multiple later | Start with `Rc`, upgrade if needed |
| Library code, unknown threading model | `Arc<T>` (safer default) |

### Breaking Cycles with Weak

`Rc` never frees a value caught in a reference cycle — the strong count never reaches zero, so it leaks. Use `Weak<T>` for back-references (a child pointing at its parent): a `Weak` does not keep the value alive and is upgraded to an `Rc` only when needed.

```rust
use std::rc::{Rc, Weak};
use std::cell::RefCell;

struct Node {
    parent: RefCell<Weak<Node>>,        // back-reference: does not own the parent
    children: RefCell<Vec<Rc<Node>>>,
}

let parent = Rc::new(Node {
    parent: RefCell::new(Weak::new()),
    children: RefCell::new(vec![]),
});
let child = Rc::new(Node {
    parent: RefCell::new(Rc::downgrade(&parent)),
    children: RefCell::new(vec![]),
});
parent.children.borrow_mut().push(Rc::clone(&child));

// upgrade() yields Option<Rc<Node>> — None once the parent is dropped
let _maybe_parent: Option<Rc<Node>> = child.parent.borrow().upgrade();
```

### Key Points

- Prefer `Rc::clone(&x)` to `x.clone()`: it makes the cheap refcount bump explicit and visually distinct from a deep clone.
- `Rc<T>` gives shared *immutable* access; pair it with `RefCell<T>` (`Rc<RefCell<T>>`) for shared mutability in single-threaded code.
- `Rc::strong_count(&x)` / `Rc::weak_count(&x)` inspect the counts — handy in tests.
- `Rc` is `!Send` and `!Sync`, so the compiler rejects sending it across threads; switch to `Arc` (with `Mutex`/`RwLock`) at a thread boundary.

Related: `own-arc-shared`, `own-refcell-interior`, `conc-thread-local`, `mem-drop-order`

## own-refcell-interior

> Use `RefCell<T>` for interior mutability in single-threaded code

### Why It Matters

Rust's borrow checker enforces rules at compile time, but sometimes you need to mutate data through a shared reference. `RefCell<T>` moves borrow checking to runtime, allowing mutation through `&self`. This is essential for patterns like caches, lazy initialization, and observer patterns where compile-time borrowing is too restrictive.

### Bad

```rust
struct Cache {
    // Requires &mut self to update, breaking shared reference patterns
    data: HashMap<String, String>,
}

impl Cache {
    fn get_or_compute(&mut self, key: &str) -> &str {
        // Caller needs &mut Cache, can't share cache reference
        if !self.data.contains_key(key) {
            self.data.insert(key.to_string(), expensive_compute(key));
        }
        &self.data[key]
    }
}
```

This forces exclusive access even for logically shared operations.

### Good

```rust
use std::cell::RefCell;
use std::collections::HashMap;

struct Cache {
    data: RefCell<HashMap<String, String>>,
}

impl Cache {
    fn get_or_compute(&self, key: &str) -> String {
        // Can mutate through &self
        let mut data = self.data.borrow_mut();
        if !data.contains_key(key) {
            data.insert(key.to_string(), expensive_compute(key));
        }
        data[key].clone()
    }
}

// Multiple references can coexist
let cache = Cache::new();
let ref1 = &cache;
let ref2 = &cache;
ref1.get_or_compute("key1");
ref2.get_or_compute("key2");
```

### Common Pattern: Rc<RefCell<T>>

```rust
use std::rc::Rc;
use std::cell::RefCell;

// Shared mutable state in single-threaded code
type SharedState = Rc<RefCell<AppState>>;

fn create_handlers(state: SharedState) -> Vec<Box<dyn Fn()>> {
    vec![
        Box::new({
            let state = state.clone();
            move || state.borrow_mut().increment()
        }),
        Box::new({
            let state = state.clone();
            move || state.borrow_mut().decrement()
        }),
    ]
}
```

### Runtime Panics

`RefCell` panics if you violate borrowing rules at runtime:

```rust
let cell = RefCell::new(5);
let borrow1 = cell.borrow();
let borrow2 = cell.borrow_mut(); // PANIC: already borrowed
```

Use `try_borrow()` and `try_borrow_mut()` for fallible borrowing.

### Cell for Copy Types

For simple `Copy` values, `Cell<T>` is lighter than `RefCell<T>` — no runtime borrow flags, no panics. You `get()`/`set()`/`replace()` the value instead of borrowing it:

```rust
use std::cell::Cell;

struct Counter {
    count: Cell<u32>,
}

impl Counter {
    fn bump(&self) {
        self.count.set(self.count.get() + 1); // mutate through &self, never panics
    }
}
```

Related: `own-rc-single-thread`, `own-mutex-interior`, `conc-thread-local`
