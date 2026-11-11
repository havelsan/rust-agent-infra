---
name: rust-02-ownership-2of2
description: Rust rules module 02: Ownership & Borrowing (part 2 of 2). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `own-`
---

# Ownership & Borrowing (part 2/2)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `own-mutex-interior` - Use `Mutex<T>` for interior mutability across threads
- `own-rwlock-readers` - Use `RwLock<T>` when reads significantly outnumber writes
- `own-copy-small` - Implement `Copy` for small, simple types
- `own-clone-explicit` - Use explicit `Clone` for types where copying has meaningful cost
- `own-move-large` - Move large types instead of copying; use `Box` if moves are expensive
- `own-lifetime-elision` - Rely on lifetime elision rules; add explicit lifetimes only when required

---

## own-mutex-interior

> Use `Mutex<T>` for interior mutability across threads

### Why It Matters

When you need shared mutable state across threads, `Mutex<T>` provides safe interior mutability with synchronization. Unlike `RefCell`, `Mutex` is `Send + Sync` and uses OS-level locking to ensure only one thread can access the data at a time.

### Bad

```rust
use std::cell::RefCell;
use std::sync::Arc;

// RefCell is !Sync - this won't compile
let shared = Arc::new(RefCell::new(vec![]));

// ERROR: RefCell cannot be shared between threads safely
std::thread::spawn({
    let shared = shared.clone();
    move || shared.borrow_mut().push(1)
});
```

### Good

```rust
use std::sync::{Arc, Mutex};

let shared = Arc::new(Mutex::new(vec![]));

let handles: Vec<_> = (0..10).map(|i| {
    let shared = shared.clone();
    std::thread::spawn(move || {
        let mut data = shared.lock().unwrap();
        data.push(i);
    })
}).collect();

for handle in handles {
    handle.join().unwrap();
}

println!("{:?}", shared.lock().unwrap()); // All values present
```

### Mutex Poisoning

If a thread panics while holding a lock, the mutex becomes "poisoned":

```rust
use std::sync::{Arc, Mutex};

let mutex = Arc::new(Mutex::new(0));

// Handle poisoning gracefully
match mutex.lock() {
    Ok(guard) => println!("Value: {}", *guard),
    Err(poisoned) => {
        // Recover the data anyway
        let guard = poisoned.into_inner();
        println!("Recovered value: {}", *guard);
    }
}

// Or ignore poisoning (use with caution)
let guard = mutex.lock().unwrap_or_else(|e| e.into_inner());
```

### Prefer parking_lot::Mutex

For better performance, consider `parking_lot::Mutex`:

```rust
use parking_lot::Mutex;
use std::sync::Arc;

let shared = Arc::new(Mutex::new(vec![]));

// No poisoning, no Result to unwrap
let mut data = shared.lock();
data.push(42);
// Lock automatically released when guard drops
```

Benefits of `parking_lot`:
- No poisoning (returns guard directly)
- Smaller size (1 byte vs 40+ bytes)
- Better performance under contention
- Fair locking option available

### When to Use What

| Type | Threading | Overhead | Use Case |
|------|-----------|----------|----------|
| `RefCell<T>` | Single | Minimal | Interior mutability, same thread |
| `Mutex<T>` | Multi | Locking | Shared mutable state across threads |
| `RwLock<T>` | Multi | Locking | Many readers, few writers |
| `parking_lot::Mutex` | Multi | Less | Drop-in std::Mutex replacement |

Related: `own-rwlock-readers`, `own-refcell-interior`, `async-no-lock-await`, `conc-atomic-ordering`

## own-rwlock-readers

> Use `RwLock<T>` when reads significantly outnumber writes

### Why It Matters

`Mutex<T>` allows only one thread to access data at a time, even for reads. `RwLock<T>` allows multiple concurrent readers OR one exclusive writer. For read-heavy workloads, this dramatically improves throughput by eliminating unnecessary serialization of read operations.

### Bad

```rust
use std::sync::{Arc, Mutex};

// Configuration rarely changes but is read constantly
let config = Arc::new(Mutex::new(Config::load()));

// Every read blocks other reads unnecessarily
fn get_setting(config: &Mutex<Config>, key: &str) -> String {
    let guard = config.lock().unwrap();
    guard.get(key).to_string()
}

// 100 threads reading = serialized, one at a time
```

### Good

```rust
use std::sync::{Arc, RwLock};

// Multiple readers can proceed concurrently
let config = Arc::new(RwLock::new(Config::load()));

fn get_setting(config: &RwLock<Config>, key: &str) -> String {
    let guard = config.read().unwrap(); // Multiple threads can hold read lock
    guard.get(key).to_string()
}

fn update_setting(config: &RwLock<Config>, key: &str, value: &str) {
    let mut guard = config.write().unwrap(); // Exclusive access for writes
    guard.set(key, value);
}

// 100 threads reading = parallel execution
```

### parking_lot::RwLock

Prefer `parking_lot::RwLock` for better performance:

```rust
use parking_lot::RwLock;
use std::sync::Arc;

let data = Arc::new(RwLock::new(HashMap::new()));

// Read - no unwrap needed
let value = data.read().get("key").cloned();

// Write
data.write().insert("key".to_string(), "value".to_string());

// Upgradeable read lock (unique to parking_lot)
let upgradeable = data.upgradable_read();
if upgradeable.get("key").is_none() {
    let mut write = parking_lot::RwLockUpgradableReadGuard::upgrade(upgradeable);
    write.insert("key".to_string(), "default".to_string());
}
```

### When RwLock Hurts

RwLock has overhead for tracking readers. It can be slower than Mutex when:

| Scenario | Better Choice |
|----------|---------------|
| Writes are frequent (>20% of operations) | `Mutex` |
| Lock held very briefly | `Mutex` |
| Single-threaded | `RefCell` |
| Reads dominate, lock held longer | `RwLock` |

### Write Starvation

Standard `RwLock` may starve writers if readers are continuous. `parking_lot::RwLock` is fair by default.

```rust
// parking_lot is writer-fair, preventing starvation
use parking_lot::RwLock;

// Or use std with explicit fairness (nightly)
// #![feature(rwlock_downgrade)]
```

### Real-World Pattern: Cached Computation

```rust
use parking_lot::RwLock;
use std::sync::Arc;

struct CachedData {
    cache: RwLock<Option<ExpensiveResult>>,
}

impl CachedData {
    fn get(&self) -> ExpensiveResult {
        // Fast path: read lock
        if let Some(cached) = self.cache.read().as_ref() {
            return cached.clone();
        }
        
        // Slow path: compute and cache
        let result = compute_expensive();
        *self.cache.write() = Some(result.clone());
        result
    }
}
```

Related: `own-mutex-interior`, `async-no-lock-await`

## own-copy-small

> Implement `Copy` for small, simple types

### Why It Matters

Types that implement `Copy` are implicitly duplicated on assignment instead of moved. This eliminates the need for explicit `.clone()` calls and makes the code more ergonomic. For small types (generally ≤16 bytes), copying is as fast or faster than moving a pointer.

### Bad

```rust
// Small type without Copy - requires explicit clone
#[derive(Clone, Debug)]
struct Point {
    x: f64,
    y: f64,
}

fn distance(p1: Point, p2: Point) -> f64 {
    ((p2.x - p1.x).powi(2) + (p2.y - p1.y).powi(2)).sqrt()
}

let origin = Point { x: 0.0, y: 0.0 };
let target = Point { x: 3.0, y: 4.0 };

let d1 = distance(origin.clone(), target.clone()); // Tedious
let d2 = distance(origin.clone(), target.clone()); // Every use needs clone
// origin and target still usable but verbose
```

### Good

```rust
// Small type with Copy - implicit duplication
#[derive(Clone, Copy, Debug)]
struct Point {
    x: f64,
    y: f64,
}

fn distance(p1: Point, p2: Point) -> f64 {
    ((p2.x - p1.x).powi(2) + (p2.y - p1.y).powi(2)).sqrt()
}

let origin = Point { x: 0.0, y: 0.0 };
let target = Point { x: 3.0, y: 4.0 };

let d1 = distance(origin, target); // Implicitly copied
let d2 = distance(origin, target); // Still works!
// origin and target remain valid
```

### Copy Requirements

A type can implement `Copy` only if:
1. All fields implement `Copy`
2. No custom `Drop` implementation
3. No heap-allocated data (`String`, `Vec`, `Box`, etc.)

```rust
// ✅ Can be Copy
#[derive(Clone, Copy)]
struct Color {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

// ❌ Cannot be Copy - contains String
#[derive(Clone)]
struct Person {
    name: String,  // String is not Copy
    age: u32,
}

// ❌ Cannot be Copy - has Drop
struct FileHandle {
    fd: i32,
}
impl Drop for FileHandle {
    fn drop(&mut self) { /* close file */ }
}
```

### Size Guidelines

| Size | Recommendation |
|------|----------------|
| ≤ 16 bytes | Implement `Copy` |
| 17-64 bytes | Consider `Copy`, benchmark if critical |
| > 64 bytes | Probably don't, prefer references |

```rust
use std::mem::size_of;

#[derive(Clone, Copy)]
struct SmallId(u64); // 8 bytes ✅

#[derive(Clone, Copy)]
struct Rect { x: f32, y: f32, w: f32, h: f32 } // 16 bytes ✅

#[derive(Clone)] // No Copy - 72 bytes
struct Transform {
    matrix: [[f64; 3]; 3], // 72 bytes, too large
}
```

### Common Copy Types

Standard library types that are `Copy`:
- All primitives: `i32`, `f64`, `bool`, `char`, etc.
- Shared references: `&T` (note: `&mut T` is NOT `Copy` — copying a mutable reference would alias it, so it is reborrowed instead)
- Raw pointers: `*const T`, `*mut T`
- Function pointers: `fn(T) -> U`
- Tuples of `Copy` types: `(i32, f64)`
- Arrays of `Copy` types: `[u8; 32]`
- `Option<T>` where `T: Copy`
- `PhantomData<T>`

Related: `own-clone-explicit`, `type-newtype-ids`

## own-clone-explicit

> Use explicit `Clone` for types where copying has meaningful cost

### Why It Matters

Unlike `Copy` which is implicit and "free," `Clone` requires an explicit `.clone()` call, signaling that duplication has a cost. This makes heap allocations and deep copies visible in code, helping developers reason about performance. Types with heap data (`String`, `Vec`, `Box`) should implement `Clone` but not `Copy`.

### Bad

```rust
// Hiding expensive operations
fn process_data(data: Vec<u32>) -> Vec<u32> {
    let backup = data; // Moved, not copied - but unclear at call site
    transform(backup)
}

let my_data = vec![1, 2, 3, 4, 5];
let result = process_data(my_data);
// my_data is moved - surprise if you expected it to still exist
```

### Good

```rust
fn process_data(data: Vec<u32>) -> Vec<u32> {
    let backup = data; 
    transform(backup)
}

let my_data = vec![1, 2, 3, 4, 5];
let result = process_data(my_data.clone()); // Explicit: "I know this allocates"
// my_data still available

// Or better - take reference if you don't need ownership
fn process_data_ref(data: &[u32]) -> Vec<u32> {
    transform(data)
}
let result = process_data_ref(&my_data); // No clone needed
```

### Custom Clone Implementation

For types with mixed cheap/expensive fields, implement `Clone` manually:

```rust
#[derive(Debug)]
struct Document {
    id: u64,              // Cheap to copy
    content: String,      // Expensive to clone
    metadata: Metadata,   // Moderate cost
}

impl Clone for Document {
    fn clone(&self) -> Self {
        Self {
            id: self.id,
            content: self.content.clone(),
            metadata: self.metadata.clone(),
        }
    }
    
    // Optimization: reuse existing allocations
    fn clone_from(&mut self, source: &Self) {
        self.id = source.id;
        self.content.clone_from(&source.content); // Reuses capacity
        self.metadata.clone_from(&source.metadata);
    }
}
```

### clone_from Optimization

`clone_from` can reuse existing allocations:

```rust
let mut buffer = String::with_capacity(1000);

// Bad: drops old allocation, creates new one
buffer = source.clone();

// Good: reuses existing capacity if sufficient
buffer.clone_from(&source);
```

### Derive vs Manual Clone

```rust
// Derive when all fields need cloning
#[derive(Clone)]
struct Simple {
    data: Vec<u8>,
    name: String,
}

// Manual when you need special behavior
struct CachedValue {
    value: i32,
    cache: RefCell<Option<ExpensiveComputation>>,
}

impl Clone for CachedValue {
    fn clone(&self) -> Self {
        Self {
            value: self.value,
            cache: RefCell::new(None), // Don't clone cache, let it rebuild
        }
    }
}
```

### When to Avoid Clone

```rust
// Instead of cloning, consider:

// 1. References
fn process(data: &MyType) { } // Borrow instead of clone

// 2. Cow for conditional cloning
fn process(data: Cow<'_, str>) { } // Clone only if mutation needed

// 3. Arc for shared ownership
let shared = Arc::new(expensive_data);
let handle = shared.clone(); // Cheap: just increments counter

// 4. Passing by value when caller is done with it
fn consume(data: MyType) { } // Caller moves, no clone
```

Related: `own-copy-small`, `own-cow-conditional`, `mem-clone-from`

## own-move-large

> Move large types instead of copying; use `Box` if moves are expensive

### Why It Matters

In Rust, "moving" a value means copying its bytes to a new location and invalidating the old one. For large types (hundreds of bytes), this memcpy can be expensive. Boxing large types reduces move cost to copying a single pointer (8 bytes), making moves cheap regardless of the actual data size.

### Bad

```rust
// Large struct moved repeatedly = expensive memcpy each time
struct GameState {
    board: [[Cell; 100]; 100],  // 10,000 cells
    history: [Move; 1000],       // 1,000 moves
    players: [Player; 4],        // Player data
    // Total: potentially tens of KB
}

fn process_state(state: GameState) -> GameState {
    // Moving ~40KB+ of data
    let mut new_state = state;  // Memcpy here
    new_state.apply_rules();
    new_state  // Memcpy on return
}

let state = GameState::new();
let state = process_state(state);  // Two large memcpys
```

### Good

```rust
// Box reduces move cost to 8 bytes
struct GameState {
    board: Box<[[Cell; 100]; 100]>,  // Pointer to heap
    history: Vec<Move>,               // Already heap-allocated
    players: [Player; 4],
}

fn process_state(mut state: GameState) -> GameState {
    // Moving just pointers + small inline data
    state.apply_rules();
    state  // Cheap move
}

// Or use Box at call site for one-off cases
fn process_large(state: Box<LargeStruct>) -> Box<LargeStruct> {
    // 8-byte move regardless of LargeStruct size
    state
}
```

### When to Box

| Type Size | Move Frequency | Recommendation |
|-----------|----------------|----------------|
| < 128 bytes | Any | Don't box |
| 128-512 bytes | Rare | Probably don't box |
| 128-512 bytes | Frequent | Consider boxing |
| > 512 bytes | Any | Box or use references |
| > 4KB | Any | Definitely box |

### Stack vs Heap Tradeoffs

```rust
// Stack: fast allocation, limited size, moves copy bytes
struct StackHeavy {
    data: [u8; 4096],  // 4KB on stack
}

// Heap: allocation cost, unlimited size, moves copy pointer
struct HeapLight {
    data: Box<[u8; 4096]>,  // 8 bytes on stack, 4KB on heap
}

// Measure with size_of
use std::mem::size_of;
assert_eq!(size_of::<StackHeavy>(), 4096);
assert_eq!(size_of::<HeapLight>(), 8);
```

### Alternative: References

When you don't need ownership transfer, use references:

```rust
// Best: no move at all
fn analyze_state(state: &GameState) -> Analysis {
    // Borrows state, no copying
    compute_analysis(state)
}

// Mutable borrow for in-place modification
fn update_state(state: &mut GameState) {
    state.tick();
}
```

### Pattern: Builder Returns Boxed

```rust
impl LargeConfig {
    pub fn builder() -> ConfigBuilder {
        ConfigBuilder::default()
    }
}

impl ConfigBuilder {
    // Return boxed to avoid large move
    pub fn build(self) -> Box<LargeConfig> {
        Box::new(LargeConfig {
            // ... fields from builder
        })
    }
}
```

### Profile First

Don't prematurely optimize. Use tools to identify if moves are actually a bottleneck:

```rust
// Check type sizes
println!("Size of GameState: {}", std::mem::size_of::<GameState>());

// Profile with cargo flamegraph or perf to find hot memcpys
```

Related: `own-copy-small`, `mem-box-large-variant`, `perf-profile-first`

## own-lifetime-elision

> Rely on lifetime elision rules; add explicit lifetimes only when required

### Why It Matters

Rust's lifetime elision rules handle most common borrowing patterns automatically. Adding explicit lifetimes where they're not needed clutters code without adding clarity. However, understanding when elision applies helps you know when explicit lifetimes are truly necessary.

### Bad

```rust
// Unnecessary explicit lifetimes - elision handles these
fn first_word<'a>(s: &'a str) -> &'a str {
    s.split_whitespace().next().unwrap_or("")
}

fn get_name<'a>(person: &'a Person) -> &'a str {
    &person.name
}

impl<'a> Display for Wrapper<'a> {
    fn fmt<'b>(&'b self, f: &'b mut Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### Good

```rust
// Let elision do its job
fn first_word(s: &str) -> &str {
    s.split_whitespace().next().unwrap_or("")
}

fn get_name(person: &Person) -> &str {
    &person.name
}

impl Display for Wrapper<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}
```

### The Three Elision Rules

1. **Each input reference gets its own lifetime:**
   ```rust
   fn foo(x: &str, y: &str) 
   // becomes
   fn foo<'a, 'b>(x: &'a str, y: &'b str)
   ```

2. **One input reference → output gets same lifetime:**
   ```rust
   fn foo(x: &str) -> &str
   // becomes  
   fn foo<'a>(x: &'a str) -> &'a str
   ```

3. **Method with `&self`/`&mut self` → output gets self's lifetime:**
   ```rust
   fn foo(&self, x: &str) -> &str
   // becomes
   fn foo<'a, 'b>(&'a self, x: &'b str) -> &'a str
   ```

### When Explicit Lifetimes ARE Required

```rust
// Multiple input references, output could come from either
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}

// Struct holding references
struct Parser<'input> {
    source: &'input str,
    position: usize,
}

// Multiple distinct lifetimes needed
struct Context<'s, 'c> {
    source: &'s str,
    cache: &'c mut Cache,
}

// Static lifetime for constants
fn get_default() -> &'static str {
    "default"
}
```

### Anonymous Lifetime `'_`

Use `'_` to let the compiler infer while being explicit about the presence of a lifetime:

```rust
// In struct definitions
impl Iterator for Parser<'_> {
    type Item = Token;
    fn next(&mut self) -> Option<Self::Item> { ... }
}

// In function signatures where it adds clarity
fn parse(input: &str) -> Result<Ast<'_>, Error> { ... }

// Especially useful in trait bounds
fn process(data: &impl AsRef<str>) -> Cow<'_, str> { ... }
```

### Common Patterns

```rust
// ✅ Elision works
fn trim(s: &str) -> &str { s.trim() }
fn first(v: &[i32]) -> Option<&i32> { v.first() }
fn name(&self) -> &str { &self.name }

// ❌ Elision fails - multiple inputs, ambiguous output
fn pick(a: &str, b: &str, first: bool) -> &str // Error!

// ✅ Fixed with explicit lifetime
fn pick<'a>(a: &'a str, b: &'a str, first: bool) -> &'a str {
    if first { a } else { b }
}
```

Related: `own-borrow-over-clone`, `api-impl-asref`
