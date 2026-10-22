---
name: rust-05-memory-1of3
description: Rust rules module 05: Memory Optimization (part 1 of 3). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `mem-`
---

# Memory Optimization (part 1/3)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `mem-with-capacity` - Use `with_capacity()` when size is known
- `mem-smallvec` - Use `SmallVec` for usually-small collections
- `mem-arrayvec` - Use `ArrayVec<T, N>` for fixed-capacity collections that never heap-allocate
- `mem-box-large-variant` - Box large enum variants to reduce overall enum size
- `mem-boxed-slice` - Use `Box<[T]>` instead of `Vec<T>` for fixed-size heap data
- `mem-thinvec` - Use `ThinVec<T>` for nullable collections with minimal overhead

---

## mem-with-capacity

> Use `with_capacity()` when size is known

### Why It Matters

When you know (or can estimate) the final size of a collection, pre-allocating avoids multiple reallocations as it grows. Each reallocation copies all existing elements, so avoiding them can dramatically improve performance.

### Bad

```rust
// Vec starts at capacity 0, reallocates at 4, 8, 16, 32...
let mut results = Vec::new();
for i in 0..1000 {
    results.push(process(i));  // ~10 reallocations!
}

// String grows similarly
let mut output = String::new();
for word in words {
    output.push_str(word);
    output.push(' ');
}

// HashMap default capacity is small
let mut map = HashMap::new();
for (k, v) in pairs {  // Many reallocations
    map.insert(k, v);
}
```

### Good

```rust
// Pre-allocate exact size
let mut results = Vec::with_capacity(1000);
for i in 0..1000 {
    results.push(process(i));  // Zero reallocations!
}

// Or use collect with size hint (iterator provides capacity)
let results: Vec<_> = (0..1000).map(process).collect();

// Pre-allocate string
let estimated_len = words.iter().map(|w| w.len() + 1).sum();
let mut output = String::with_capacity(estimated_len);
for word in words {
    output.push_str(word);
    output.push(' ');
}

// Pre-allocate HashMap
let mut map = HashMap::with_capacity(pairs.len());
for (k, v) in pairs {
    map.insert(k, v);
}
```

### Collection Capacity Methods

```rust
// Vec
let mut v = Vec::with_capacity(100);
v.reserve(50);        // Ensure at least 50 more slots
v.reserve_exact(50);  // Ensure exactly 50 more (no extra)
v.shrink_to_fit();    // Release unused capacity

// String
let mut s = String::with_capacity(100);
s.reserve(50);

// HashMap / HashSet
let mut m = HashMap::with_capacity(100);
m.reserve(50);

// VecDeque
let mut d = VecDeque::with_capacity(100);
```

### Estimating Capacity

```rust
// From iterator length
fn collect_results(items: &[Item]) -> Vec<Output> {
    let mut results = Vec::with_capacity(items.len());
    for item in items {
        results.push(process(item));
    }
    results
}

// From filter estimate (if ~10% pass filter)
fn filter_valid(items: &[Item]) -> Vec<&Item> {
    let mut valid = Vec::with_capacity(items.len() / 10);
    for item in items {
        if item.is_valid() {
            valid.push(item);
        }
    }
    valid
}

// String from parts
fn join_with_sep(parts: &[&str], sep: &str) -> String {
    let total_len: usize = parts.iter().map(|p| p.len()).sum();
    let sep_len = if parts.is_empty() { 0 } else { sep.len() * (parts.len() - 1) };
    
    let mut result = String::with_capacity(total_len + sep_len);
    for (i, part) in parts.iter().enumerate() {
        if i > 0 {
            result.push_str(sep);
        }
        result.push_str(part);
    }
    result
}
```

### Evidence from Production Code

From fd (file finder):
```rust
// https://github.com/sharkdp/fd/blob/master/src/walk.rs
struct ReceiverBuffer<'a, W> {
    buffer: Vec<DirEntry>,
    // ...
}

impl<'a, W: Write> ReceiverBuffer<'a, W> {
    fn new(...) -> Self {
        Self {
            buffer: Vec::with_capacity(MAX_BUFFER_LENGTH),
            // ...
        }
    }
}
```

### When to Skip

```rust
// Unknown size, small expected
let mut small: Vec<i32> = Vec::new();  // OK for small collections

// Using collect() with good size_hint
let v: Vec<_> = iter.collect();  // collect() uses size_hint

// Capacity overhead exceeds benefit
let mut rarely_used = Vec::new();  // OK if rarely grown
```

Related: `mem-reuse-collections`, `mem-smallvec`, `perf-extend-batch`, `coll-seq-choice`

## mem-smallvec

> Use `SmallVec` for usually-small collections

### Why It Matters

`SmallVec<[T; N]>` stores up to N elements inline (on the stack), only allocating on the heap when the size exceeds N. This eliminates heap allocations for the common case while still allowing growth when needed.

### Bad

```rust
// Always heap-allocates, even for 1-2 elements
fn get_path_components(path: &str) -> Vec<&str> {
    path.split('/').collect()  // Usually 2-4 components
}

// Always heap-allocates for error list
fn validate(input: &Input) -> Vec<ValidationError> {
    let mut errors = Vec::new();  // Usually 0-3 errors
    // validation logic...
    errors
}
```

### Good

```rust
use smallvec::{smallvec, SmallVec};

// Stack-allocated for typical paths (1-8 components)
fn get_path_components(path: &str) -> SmallVec<[&str; 8]> {
    path.split('/').collect()
}

// Stack-allocated for typical error counts
fn validate(input: &Input) -> SmallVec<[ValidationError; 4]> {
    let mut errors = SmallVec::new();
    // validation logic...
    errors
}

// Using smallvec! macro
let v: SmallVec<[i32; 4]> = smallvec![1, 2, 3];
```

### Choosing Capacity N

```rust
// Measure your actual data distribution!
// Guidelines:

// Path components: 4-8 (most paths are shallow)
type PathParts<'a> = SmallVec<[&'a str; 8]>;

// Function arguments: 4-8 (most functions have few args)  
type Args = SmallVec<[Arg; 8]>;

// AST children: 2-4 (binary ops, if/else, etc.)
type Children = SmallVec<[Node; 4]>;

// Error accumulation: 2-4 (most inputs have few errors)
type Errors = SmallVec<[Error; 4]>;

// Attribute lists: 4-8 (most items have few attributes)
type Attrs = SmallVec<[Attribute; 8]>;
```

### Evidence from rust-analyzer

```rust
// https://github.com/rust-lang/rust/blob/main/compiler/rustc_expand/src/base.rs
macro_rules! make_stmts_default {
    ($me:expr) => {
        $me.make_expr().map(|e| {
            smallvec![ast::Stmt {
                id: ast::DUMMY_NODE_ID,
                span: e.span,
                kind: ast::StmtKind::Expr(e),
            }]
        })
    }
}
```

### Trade-offs

```rust
// SmallVec is slightly larger than Vec
use std::mem::size_of;
// Vec<i32>: 24 bytes (ptr + len + cap)
// SmallVec<[i32; 4]>: 32 bytes (inline storage + len + discriminant)

// SmallVec has branching overhead on every operation
// (must check if inline or heap)

// Profile to verify benefit!
```

### When to Use SmallVec vs Alternatives

| Situation | Use |
|-----------|-----|
| Usually small, sometimes large | `SmallVec<[T; N]>` |
| Always small, fixed max | `ArrayVec<T, N>` |
| Rarely grows past initial | `Vec::with_capacity` |
| No `unsafe` allowed | `TinyVec` |
| Often empty | `ThinVec` |

### ArrayVec Alternative

```rust
use arrayvec::ArrayVec;

// Fixed maximum capacity, never heap allocates
// Panics if you exceed capacity
fn parse_rgb(s: &str) -> ArrayVec<u8, 3> {
    let mut components = ArrayVec::new();
    for part in s.split(',').take(3) {
        components.push(part.parse().unwrap());
    }
    components
}
```

### TinyVec (No Unsafe)

```rust
use tinyvec::{tiny_vec, TinyVec};

// Same concept as SmallVec but 100% safe code
let v: TinyVec<[i32; 4]> = tiny_vec![1, 2, 3];
```

Related: `mem-arrayvec`, `mem-with-capacity`, `mem-thinvec`

## mem-arrayvec

> Use `ArrayVec<T, N>` for fixed-capacity collections that never heap-allocate

### Why It Matters

`ArrayVec` from the `arrayvec` crate provides Vec-like API with a compile-time maximum capacity, storing all elements inline on the stack. Unlike `SmallVec` which can spill to heap, `ArrayVec` guarantees no heap allocation—if you exceed capacity, it returns an error or panics. This is ideal for embedded systems, real-time code, or when you have a hard upper bound.

### Bad

```rust
// Vec always heap-allocates, even for small collections
fn parse_options(input: &str) -> Vec<Option> {
    let mut options = Vec::new();  // Heap allocation
    for part in input.split(',').take(8) {  // Know we never exceed 8
        options.push(parse_option(part));
    }
    options
}

// Or SmallVec when you truly can't exceed capacity
use smallvec::SmallVec;
fn get_flags() -> SmallVec<[Flag; 4]> {
    // SmallVec CAN heap-allocate if pushed beyond 4
    // That might be unexpected in no-alloc contexts
}
```

### Good

```rust
use arrayvec::ArrayVec;

// Guaranteed no heap allocation
fn parse_options(input: &str) -> ArrayVec<Option<u32>, 8> {
    let mut options = ArrayVec::new();
    for part in input.split(',') {
        if options.try_push(parse_option(part)).is_err() {
            break;  // Capacity reached, stop
        }
    }
    options
}

// For embedded/no_std contexts
#[no_std]
fn collect_readings() -> ArrayVec<SensorReading, 16> {
    let mut readings = ArrayVec::new();
    for sensor in SENSORS.iter() {
        readings.push(sensor.read());  // Panics if > 16
    }
    readings
}
```

### ArrayVec vs SmallVec vs Vec

| Type | Stack | Heap | Use When |
|------|-------|------|----------|
| `Vec<T>` | Never | Always | Unknown size, may grow indefinitely |
| `SmallVec<[T; N]>` | Up to N | Beyond N | Usually small, occasionally large |
| `ArrayVec<T, N>` | Always | Never | Hard limit, no heap allowed |

### API Patterns

```rust
use arrayvec::ArrayVec;

let mut arr: ArrayVec<i32, 4> = ArrayVec::new();

// Push with potential panic (like Vec)
arr.push(1);
arr.push(2);

// Safe push - returns Err if full
match arr.try_push(3) {
    Ok(()) => println!("Added"),
    Err(err) => println!("Full, couldn't add {}", err.element()),
}

// Check capacity
assert!(arr.len() < arr.capacity());

// Remaining capacity
let remaining = arr.remaining_capacity();

// Is it full?
if arr.is_full() {
    arr.pop();
}

// From iterator with limit
let arr: ArrayVec<_, 10> = (0..100)
    .filter(|x| x % 2 == 0)
    .take(10)  // Important: don't exceed capacity
    .collect();
```

### ArrayString for Stack Strings

```rust
use arrayvec::ArrayString;
use std::fmt::Write; // brings the write! target trait into scope

// Stack-allocated string with max capacity
let mut s: ArrayString<64> = ArrayString::new();
s.push_str("Hello, ");
s.push_str("world!");

// No heap allocation for small strings
fn format_code(code: u32) -> ArrayString<16> {
    let mut s = ArrayString::new();
    write!(&mut s, "CODE-{:04}", code).unwrap();
    s
}
```

### When NOT to Use ArrayVec

```rust
// ❌ When size varies widely
fn parse_json_array(json: &str) -> ArrayVec<Value, ???> {
    // What capacity? JSON arrays can be any size
}

// ❌ When capacity is very large
let big: ArrayVec<u8, 1_000_000> = ArrayVec::new();  // 1MB on stack = bad

// ✅ Use SmallVec or Vec instead for these cases
```

### Cargo.toml

```toml
[dependencies]
arrayvec = "0.7"
```

Related: `mem-smallvec`, `mem-with-capacity`, `own-move-large`

## mem-box-large-variant

> Box large enum variants to reduce overall enum size

### Why It Matters

An enum's size is determined by its largest variant. If one variant contains a large struct while others are small, every instance of the enum pays for the largest variant's size. Boxing the large variant puts that data on the heap, keeping the enum itself small. This can significantly reduce memory usage and improve cache performance.

### Bad

```rust
enum Message {
    Quit,                              // 0 bytes of data
    Move { x: i32, y: i32 },          // 8 bytes
    Text(String),                      // 24 bytes
    Image { 
        data: [u8; 1024],             // 1024 bytes - forces entire enum to ~1032 bytes!
        width: u32, 
        height: u32 
    },
}

// Every Message is ~1032 bytes, even Quit and Move
let messages: Vec<Message> = vec![
    Message::Quit,  // Wastes ~1032 bytes
    Message::Quit,  // Wastes ~1032 bytes
    Message::Move { x: 0, y: 0 },  // Wastes ~1024 bytes
];
```

### Good

```rust
struct ImageData {
    data: [u8; 1024],
    width: u32,
    height: u32,
}

enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Text(String),
    Image(Box<ImageData>),  // Now just 8 bytes (pointer)
}

// Message is now ~32 bytes (String variant is largest)
let messages: Vec<Message> = vec![
    Message::Quit,  // Uses ~32 bytes
    Message::Quit,  // Uses ~32 bytes  
    Message::Move { x: 0, y: 0 },  // Uses ~32 bytes
];
```

### Check Enum Sizes

```rust
use std::mem::size_of;

// Before boxing
enum BadEvent {
    Click { x: u32, y: u32 },           // 8 bytes
    KeyPress(char),                      // 4 bytes
    LargeData([u8; 256]),               // 256 bytes
}
println!("BadEvent: {} bytes", size_of::<BadEvent>());  // ~264 bytes

// After boxing
enum GoodEvent {
    Click { x: u32, y: u32 },
    KeyPress(char),
    LargeData(Box<[u8; 256]>),          // 8 bytes (pointer)
}
println!("GoodEvent: {} bytes", size_of::<GoodEvent>());  // ~16 bytes
```

### Clippy Lint

```toml
[lints.clippy]
large_enum_variant = "warn"  # Warns when variants differ significantly
```

```rust
// Clippy will suggest:
// warning: large size difference between variants
// help: consider boxing the large fields to reduce the total size
```

### When to Box

| Largest Variant | Other Variants | Action |
|-----------------|----------------|--------|
| < 64 bytes | Similar size | Don't box |
| > 128 bytes | Much smaller | Box the large variant |
| > 256 bytes | Any | Definitely box |

### Recursive Types Require Boxing

```rust
// Won't compile - infinite size
enum List {
    Cons(i32, List),
    Nil,
}

// Must box recursive variant
enum List {
    Cons(i32, Box<List>),  // Now finite size
    Nil,
}

// Same for ASTs
enum Expr {
    Number(i64),
    BinOp {
        op: Op,
        left: Box<Expr>,   // Recursive - must box
        right: Box<Expr>,
    },
}
```

### Pattern Matching with Boxed Variants

```rust
enum Event {
    Small(u32),
    Large(Box<LargeData>),
}

fn handle(event: Event) {
    match event {
        Event::Small(n) => println!("Small: {}", n),
        Event::Large(data) => {
            // data is Box<LargeData>, dereference to access
            println!("Large: {} bytes", data.size);
        }
    }
}

// Or match on reference
fn handle_ref(event: &Event) {
    match event {
        Event::Small(n) => println!("Small: {}", n),
        Event::Large(data) => {
            // data is &Box<LargeData>, auto-derefs
            println!("Large: {} bytes", data.size);
        }
    }
}
```

Related: `own-move-large`, `mem-smallvec`, `lint-deny-correctness`

## mem-boxed-slice

> Use `Box<[T]>` instead of `Vec<T>` for fixed-size heap data

### Why It Matters

`Vec<T>` stores three words: pointer, length, and capacity. When you know a collection won't grow, `Box<[T]>` stores only pointer and length (2 words), saving 8 bytes per instance. More importantly, it communicates intent: "this data is fixed-size." For large numbers of fixed collections, this adds up.

### Bad

```rust
struct Document {
    // Vec signals "might grow" but we never push after creation
    paragraphs: Vec<Paragraph>,  // 24 bytes: ptr + len + capacity
}

fn load_document(data: &[u8]) -> Document {
    let paragraphs: Vec<Paragraph> = parse_paragraphs(data);
    // paragraphs has capacity >= len, wasting the capacity field
    Document { paragraphs }
}
```

### Good

```rust
struct Document {
    // Box<[T]> signals "fixed size" - clear intent
    paragraphs: Box<[Paragraph]>,  // 16 bytes: ptr + len (as fat pointer)
}

fn load_document(data: &[u8]) -> Document {
    let paragraphs: Vec<Paragraph> = parse_paragraphs(data);
    Document { 
        paragraphs: paragraphs.into_boxed_slice()  // Shrinks + converts
    }
}
```

### Memory Layout

```rust
use std::mem::size_of;

// Vec: 24 bytes on 64-bit
assert_eq!(size_of::<Vec<u8>>(), 24);  // ptr(8) + len(8) + cap(8)

// Box<[T]>: 16 bytes (fat pointer)
assert_eq!(size_of::<Box<[u8]>>(), 16);  // ptr(8) + len(8)

// Savings per instance: 8 bytes
// For 1 million instances: 8 MB saved
```

### Conversion Patterns

```rust
// Vec to Box<[T]>
let vec: Vec<i32> = vec![1, 2, 3, 4, 5];
let boxed: Box<[i32]> = vec.into_boxed_slice();

// Box<[T]> back to Vec (if you need to grow)
let vec_again: Vec<i32> = boxed.into_vec();

// From iterator
let boxed: Box<[i32]> = (0..100).collect::<Vec<_>>().into_boxed_slice();

// Shrink Vec first if it has excess capacity
let mut vec = Vec::with_capacity(1000);
vec.extend(0..10);
vec.shrink_to_fit();  // Reduce capacity to length
let boxed = vec.into_boxed_slice();  // Now no wasted allocation
```

### When to Use What

| Type | Use When |
|------|----------|
| `Vec<T>` | Collection may grow/shrink |
| `Box<[T]>` | Fixed-size, heap-allocated, many instances |
| `[T; N]` | Fixed-size, stack-allocated, size known at compile time |
| `&[T]` | Borrowed view, don't need ownership |

### Box<str> for Immutable Strings

Same principle applies to strings:

```rust
use std::mem::size_of;

// String: 24 bytes (like Vec<u8>)
assert_eq!(size_of::<String>(), 24);

// Box<str>: 16 bytes
assert_eq!(size_of::<Box<str>>(), 16);

// For immutable strings
struct Name {
    value: Box<str>,  // Saves 8 bytes vs String
}

impl Name {
    fn new(s: &str) -> Self {
        Name { value: s.into() }  // &str -> Box<str>
    }
}

// Or from String
let s = String::from("hello");
let boxed: Box<str> = s.into_boxed_str();
```

### Real-World Example

```rust
// Cache with millions of entries
struct Cache {
    // 8 bytes saved per entry adds up
    entries: HashMap<Key, Box<[u8]>>,
}

impl Cache {
    fn insert(&mut self, key: Key, data: Vec<u8>) {
        // Convert to boxed slice for storage
        self.entries.insert(key, data.into_boxed_slice());
    }
    
    fn get(&self, key: &Key) -> Option<&[u8]> {
        // Returns regular slice reference
        self.entries.get(key).map(|b| b.as_ref())
    }
}
```

Related: `mem-with-capacity`, `own-slice-over-vec`, `mem-compact-string`

## mem-thinvec

> Use `ThinVec<T>` for nullable collections with minimal overhead

### Why It Matters

Standard `Vec<T>` is 24 bytes even when empty. `ThinVec` from Mozilla's `thin_vec` crate uses a single pointer (8 bytes), storing length and capacity inline with the heap allocation. For Option<Vec<T>> patterns or structs with many optional vecs, this significantly reduces memory overhead.

### Bad

```rust
struct TreeNode {
    value: i32,
    // Each node pays 24 bytes for children, even leaves
    children: Vec<TreeNode>,  // Most nodes are leaves with empty Vec
}

// Or using Option<Vec<T>>
struct SparseData {
    // Option<Vec> = 24 bytes (Vec is never null-pointer optimized)
    tags: Option<Vec<String>>,
    metadata: Option<Vec<Metadata>>,
    // 48 bytes for usually-None fields
}
```

### Good

```rust
use thin_vec::ThinVec;

struct TreeNode {
    value: i32,
    // Empty ThinVec is just a null pointer - 8 bytes
    children: ThinVec<TreeNode>,
}

struct SparseData {
    // ThinVec empty = 8 bytes each
    tags: ThinVec<String>,
    metadata: ThinVec<Metadata>,
    // 16 bytes vs 48 bytes
}
```

### Memory Layout

```rust
use std::mem::size_of;

// Standard Vec: always 24 bytes
assert_eq!(size_of::<Vec<u8>>(), 24);
assert_eq!(size_of::<Option<Vec<u8>>>(), 24);  // No NPO benefit

// ThinVec: 8 bytes (one pointer)
use thin_vec::ThinVec;
assert_eq!(size_of::<ThinVec<u8>>(), 8);
assert_eq!(size_of::<Option<ThinVec<u8>>>(), 8);  // Option is free!
```

### ThinVec vs Vec

| Feature | `Vec<T>` | `ThinVec<T>` |
|---------|----------|--------------|
| Size (empty) | 24 bytes | 8 bytes |
| Size (non-empty) | 24 bytes | 8 bytes (header on heap) |
| Option<T> optimization | No | Yes |
| Cache locality | Better (len/cap on stack) | Worse (len/cap on heap) |
| Iteration speed | Faster | Slightly slower |
| API compatibility | Full | Vec-like |

### When to Use ThinVec

```rust
// ✅ Good: Many instances, often empty
struct SparseGraph {
    nodes: Vec<Node>,
    // Most edges lists are empty or small
    edges: Vec<ThinVec<EdgeId>>,  // Saves 16 bytes per node
}

// ✅ Good: Nullable collection field
struct Document {
    content: String,
    attachments: ThinVec<Attachment>,  // Often empty
}

// ❌ Avoid: Hot loops, performance-critical iteration
fn process_hot_path(data: &ThinVec<Item>) {
    // Every length check goes through pointer indirection
    for item in data {  // Vec would be faster here
        process(item);
    }
}

// ❌ Avoid: Few instances
fn main() {
    let single_vec: ThinVec<i32> = ThinVec::new();
    // Saving 16 bytes once is meaningless
}
```

### API Compatibility

```rust
use thin_vec::{ThinVec, thin_vec};

// Constructor macro
let v: ThinVec<i32> = thin_vec![1, 2, 3];

// Familiar Vec-like API
let mut v = ThinVec::new();
v.push(1);
v.push(2);
v.extend([3, 4, 5]);
v.pop();

// Iteration
for item in &v {
    println!("{}", item);
}

// Slicing
let slice: &[i32] = &v[..];

// Conversion
let vec: Vec<i32> = v.into();
let thin: ThinVec<i32> = vec.into();
```

### Cargo.toml

```toml
[dependencies]
thin-vec = "0.2"
```

Related: `mem-smallvec`, `mem-boxed-slice`, `mem-with-capacity`
