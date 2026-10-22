---
name: rust-06-memory-2of3
description: Rust rules module 06: Memory Optimization (part 2 of 3). 5 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `mem-`
---

# Memory Optimization (part 2/3)

Priority: CRITICAL. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `mem-clone-from` - Use `clone_from()` to reuse allocations when repeatedly cloning
- `mem-reuse-collections` - Clear and reuse collections instead of creating new ones in loops
- `mem-avoid-format` - Avoid `format!()` when string literals work
- `mem-write-over-format` - Use `write!()` into existing buffers instead of `format!()` allocations
- `mem-arena-allocator` - Use arena allocators for batch allocations

---

## mem-clone-from

> Use `clone_from()` to reuse allocations when repeatedly cloning

### Why It Matters

`x = y.clone()` drops x's allocation and creates a new one from y. `x.clone_from(&y)` reuses x's existing allocation if possible, avoiding the allocation overhead. For repeatedly cloning into the same variable (loops, buffers), this can significantly reduce allocator pressure.

### Bad

```rust
let mut buffer = String::with_capacity(1024);

for source in sources {
    buffer = source.clone();  // Drops old allocation, allocates new
    process(&buffer);
}

// Each iteration:
// 1. Drops buffer's 1024-byte allocation
// 2. Allocates new memory for source.clone()
// Allocator thrashing!
```

### Good

```rust
let mut buffer = String::with_capacity(1024);

for source in sources {
    buffer.clone_from(source);  // Reuses allocation if capacity sufficient
    process(&buffer);
}

// If source.len() <= 1024, no allocation happens
// Just copies bytes into existing buffer
```

### How clone_from Works

```rust
impl Clone for String {
    fn clone(&self) -> Self {
        // Always allocates new memory
        String::from(self.as_str())
    }
    
    fn clone_from(&mut self, source: &Self) {
        // Reuse existing capacity if possible
        self.clear();
        self.push_str(source);  // Only reallocates if capacity insufficient
    }
}
```

### Types That Benefit

```rust
// String - reuses capacity
let mut s = String::with_capacity(100);
s.clone_from(&other_string);

// Vec<T> - reuses capacity
let mut v: Vec<u8> = Vec::with_capacity(1000);
v.clone_from(&other_vec);

// HashMap - reuses buckets
let mut map = HashMap::with_capacity(100);
map.clone_from(&other_map);

// PathBuf - reuses capacity
let mut path = PathBuf::with_capacity(256);
path.clone_from(&other_path);
```

### Benchmarking the Difference

```rust
use criterion::{black_box, criterion_group, Criterion};

fn bench_clone_patterns(c: &mut Criterion) {
    let source = "x".repeat(1000);
    
    c.bench_function("clone assignment", |b| {
        let mut buffer = String::new();
        b.iter(|| {
            buffer = black_box(&source).clone();
        });
    });
    
    c.bench_function("clone_from", |b| {
        let mut buffer = String::with_capacity(1000);
        b.iter(|| {
            buffer.clone_from(black_box(&source));
        });
    });
}
// clone_from is typically 2-3x faster for this pattern
```

### Custom Implementations

When implementing Clone for your types:

```rust
#[derive(Debug)]
struct Buffer {
    data: Vec<u8>,
    metadata: Metadata,
}

impl Clone for Buffer {
    fn clone(&self) -> Self {
        Buffer {
            data: self.data.clone(),
            metadata: self.metadata.clone(),
        }
    }
    
    // Optimize clone_from to reuse vec capacity
    fn clone_from(&mut self, source: &Self) {
        self.data.clone_from(&source.data);  // Reuses allocation
        self.metadata = source.metadata.clone();
    }
}
```

### When NOT Needed

```rust
// Single clone - no benefit
let copy = original.clone();  // Can't reuse, no prior allocation

// Small Copy types - no allocation anyway
let x: i32 = y;  // Not even Clone, just Copy

// Immutable context
fn process(data: &String) {
    // Can't use clone_from - would need &mut self
}
```

Related: `mem-with-capacity`, `mem-reuse-collections`, `own-clone-explicit`

## mem-reuse-collections

> Clear and reuse collections instead of creating new ones in loops

### Why It Matters

Creating new `Vec`, `String`, or `HashMap` instances in hot loops generates significant allocator pressure. Clearing a collection and reusing it keeps the existing capacity, avoiding repeated allocation/deallocation cycles. This is especially impactful for frequently-executed code paths.

### Bad

```rust
fn process_batches(batches: &[Batch]) -> Vec<Result> {
    let mut results = Vec::new();
    
    for batch in batches {
        let mut temp = Vec::new();  // Allocates every iteration
        
        for item in &batch.items {
            temp.push(transform(item));
        }
        
        results.push(aggregate(&temp));
        // temp dropped here, deallocation
    }
    
    results
}

fn format_lines(items: &[Item]) -> String {
    let mut output = String::new();
    
    for item in items {
        let line = format!("{}: {}", item.name, item.value);  // Allocates
        output.push_str(&line);
        output.push('\n');
    }
    
    output
}
```

### Good

```rust
fn process_batches(batches: &[Batch]) -> Vec<Result> {
    let mut results = Vec::with_capacity(batches.len());
    let mut temp = Vec::new();  // Allocate once outside loop
    
    for batch in batches {
        temp.clear();  // Reuse allocation, just reset length
        
        for item in &batch.items {
            temp.push(transform(item));
        }
        
        results.push(aggregate(&temp));
        // temp keeps its capacity for next iteration
    }
    
    results
}

fn format_lines(items: &[Item]) -> String {
    use std::fmt::Write;
    
    let mut output = String::new();
    let mut line = String::new();  // Reusable buffer
    
    for item in items {
        line.clear();
        write!(&mut line, "{}: {}", item.name, item.value).unwrap();
        output.push_str(&line);
        output.push('\n');
    }
    
    output
}
```

### Clear vs Drain vs New

```rust
let mut vec = vec![1, 2, 3, 4, 5];

// clear(): keeps capacity, O(n) for Drop types
vec.clear();
assert_eq!(vec.len(), 0);
assert!(vec.capacity() >= 5);

// drain(): returns iterator, clears after iteration
let drained: Vec<_> = vec.drain(..).collect();

// truncate(): keeps first n elements
vec.truncate(2);

// Creating new: loses all capacity
vec = Vec::new();  // Capacity gone
```

### HashMap Reuse

```rust
use std::collections::HashMap;

fn count_words_per_line(lines: &[&str]) -> Vec<HashMap<String, usize>> {
    let mut results = Vec::with_capacity(lines.len());
    let mut counts = HashMap::new();  // Reuse across iterations
    
    for line in lines {
        counts.clear();  // Keeps bucket allocation
        
        for word in line.split_whitespace() {
            *counts.entry(word.to_string()).or_insert(0) += 1;
        }
        
        results.push(counts.clone());
    }
    
    results
}
```

### BufWriter Pattern

```rust
use std::io::{BufWriter, Write};

fn write_many_records(records: &[Record], mut output: impl Write) -> std::io::Result<()> {
    // BufWriter reuses its internal buffer
    let mut writer = BufWriter::with_capacity(8192, &mut output);
    let mut line = String::with_capacity(256);  // Reusable formatting buffer
    
    for record in records {
        line.clear();
        format_record(record, &mut line);
        writer.write_all(line.as_bytes())?;
        writer.write_all(b"\n")?;
    }
    
    writer.flush()
}
```

### When to Create Fresh

```rust
// When ownership transfer is needed
fn produce_results() -> Vec<Vec<Item>> {
    let mut results = Vec::new();
    
    for batch in batches {
        let processed: Vec<Item> = batch.process();  // Ownership transferred
        results.push(processed);  // Moved into results
    }
    
    results  // Each inner Vec is independent
}

// When thread safety requires it
std::thread::scope(|s| {
    for _ in 0..4 {
        s.spawn(|| {
            let local_buffer = Vec::new();  // Thread-local, can't share
            // ...
        });
    }
});
```

Related: `mem-with-capacity`, `mem-clone-from`, `mem-write-over-format`

## mem-avoid-format

> Avoid `format!()` when string literals work

### Why It Matters

`format!()` always allocates a new String, even for constant text. In hot paths, these allocations add up. Use string literals, `write!()`, or pre-allocated buffers instead.

### Bad

```rust
// Allocates every time, even for static text
fn get_error_message() -> String {
    format!("An error occurred")  // Unnecessary allocation!
}

// Allocates in a loop
for item in items {
    log::info!("{}", format!("Processing item: {}", item));  // Double work!
}

// format! in hot path
fn classify(n: i32) -> String {
    if n > 0 {
        format!("positive")  // Allocates!
    } else if n < 0 {
        format!("negative")  // Allocates!
    } else {
        format!("zero")      // Allocates!
    }
}
```

### Good

```rust
// Return &'static str for constants
fn get_error_message() -> &'static str {
    "An error occurred"  // No allocation
}

// Use format args directly
for item in items {
    log::info!("Processing item: {}", item);  // No intermediate String
}

// Return Cow for mixed static/dynamic
use std::borrow::Cow;

fn classify(n: i32) -> Cow<'static, str> {
    if n > 0 {
        Cow::Borrowed("positive")  // No allocation
    } else if n < 0 {
        Cow::Borrowed("negative")  // No allocation
    } else {
        Cow::Borrowed("zero")      // No allocation
    }
}

// Or just &'static str if always static
fn classify_str(n: i32) -> &'static str {
    if n > 0 { "positive" }
    else if n < 0 { "negative" }
    else { "zero" }
}
```

### Use write!() for Output

```rust
use std::io::Write;

// Bad: Allocate then write
fn bad_log(writer: &mut impl Write, msg: &str, code: u32) {
    let formatted = format!("[ERROR {}] {}", code, msg);  // Allocation!
    writer.write_all(formatted.as_bytes()).unwrap();
}

// Good: Write directly
fn good_log(writer: &mut impl Write, msg: &str, code: u32) {
    write!(writer, "[ERROR {}] {}", code, msg).unwrap();  // No allocation!
}
```

### Pre-allocate for Multiple Appends

```rust
// Bad: Multiple allocations
fn build_message(parts: &[&str]) -> String {
    let mut result = String::new();
    for part in parts {
        result = format!("{}{}\n", result, part);  // Allocates each iteration!
    }
    result
}

// Good: Pre-allocate
fn build_message(parts: &[&str]) -> String {
    let total_len: usize = parts.iter().map(|p| p.len() + 1).sum();
    let mut result = String::with_capacity(total_len);
    for part in parts {
        result.push_str(part);
        result.push('\n');
    }
    result
}

// Good: Use join
fn build_message(parts: &[&str]) -> String {
    parts.join("\n")
}
```

### CompactString for Small Strings

```rust
use compact_str::CompactString;

// Stack-allocated for strings <= 24 bytes
fn format_code(code: u32) -> CompactString {
    compact_str::format_compact!("ERR-{:04}", code)
    // Stack-allocated if result is small enough
}
```

### When format!() Is Fine

```rust
// Rare/cold paths - clarity over micro-optimization
fn log_startup_message() {
    println!("{}", format!("Starting {} v{}", APP_NAME, VERSION));
}

// When you need an owned String anyway
fn create_user_greeting(name: &str) -> String {
    format!("Hello, {}!", name)  // Need owned String
}

// Error messages (already on error path)
return Err(format!("Invalid value: {}", value).into());
```

Related: `mem-write-over-format`, `mem-with-capacity`, `own-cow-conditional`

## mem-write-over-format

> Use `write!()` into existing buffers instead of `format!()` allocations

### Why It Matters

`format!()` always allocates a new `String`. In hot paths or loops, these allocations add up. `write!()` writes directly into an existing buffer, reusing its capacity. For high-frequency formatting operations, this can eliminate significant allocator overhead.

### Bad

```rust
fn log_event(event: &Event, output: &mut Vec<u8>) {
    // format! allocates a new String every call
    let line = format!(
        "[{}] {}: {}\n",
        event.timestamp,
        event.level,
        event.message
    );
    output.extend_from_slice(line.as_bytes());
}

fn build_response(items: &[Item]) -> String {
    let mut result = String::new();
    
    for item in items {
        // format! allocates for each item
        result.push_str(&format!("{}: {}\n", item.name, item.value));
    }
    
    result
}
```

### Good

```rust
use std::fmt::Write;

fn log_event(event: &Event, output: &mut Vec<u8>) {
    use std::io::Write;
    // write! to Vec<u8> directly, no intermediate allocation
    write!(
        output,
        "[{}] {}: {}\n",
        event.timestamp,
        event.level,
        event.message
    ).unwrap();
}

fn build_response(items: &[Item]) -> String {
    use std::fmt::Write;
    
    let mut result = String::with_capacity(items.len() * 64);
    
    for item in items {
        // write! into existing String, reuses capacity
        write!(&mut result, "{}: {}\n", item.name, item.value).unwrap();
    }
    
    result
}
```

### Write Trait Varieties

```rust
// std::fmt::Write - for String, &mut String
use std::fmt::Write as FmtWrite;
let mut s = String::new();
write!(&mut s, "Hello {}", 42).unwrap();

// std::io::Write - for Vec<u8>, File, TcpStream, etc.
use std::io::Write as IoWrite;
let mut v: Vec<u8> = Vec::new();
write!(&mut v, "Hello {}", 42).unwrap();

// Both can fail in principle, but String/Vec never fail
// Still need .unwrap() due to Result return type
```

### Reusable Formatting Buffer

```rust
use std::fmt::Write;

struct Formatter {
    buffer: String,
}

impl Formatter {
    fn new() -> Self {
        Self { buffer: String::with_capacity(1024) }
    }
    
    fn format_event(&mut self, event: &Event) -> &str {
        self.buffer.clear();  // Reuse allocation
        write!(
            &mut self.buffer, 
            "[{}] {}",
            event.timestamp, 
            event.message
        ).unwrap();
        &self.buffer
    }
}

// Usage
let mut formatter = Formatter::new();
for event in events {
    let formatted = formatter.format_event(event);
    send_log(formatted);
}
```

### writeln! for Lines

```rust
use std::fmt::Write;

let mut output = String::new();

// writeln! adds newline automatically
writeln!(&mut output, "Line 1: {}", value1).unwrap();
writeln!(&mut output, "Line 2: {}", value2).unwrap();

// Equivalent to
write!(&mut output, "Line 1: {}\n", value1).unwrap();
```

### When format! Is Fine

```rust
// One-time formatting, not in loop
let message = format!("Starting server on port {}", port);
log::info!("{}", message);

// Return value (can't return reference to local buffer)
fn describe(item: &Item) -> String {
    format!("{}: {}", item.name, item.value)  // Must allocate
}

// Debug/error paths (not hot)
if condition {
    panic!("Unexpected: {}", format!("details: {:?}", debug_info));
}
```

### Benchmark Difference

Writing into a pre-allocated buffer avoids per-call heap allocation and is
consistently faster than `format!()` in tight loops. The exact difference
depends on string length, allocator, and hardware — measure with
[criterion](https://crates.io/crates/criterion) in your own workload.

```rust
use std::fmt::Write; // brings the write! target trait into scope

// format! in loop: new heap allocation on every iteration
for i in 0..1000 {
    let s = format!("item-{}", i);
    process(&s);
}

// write! with reuse: no allocation after the first iteration
let mut buf = String::with_capacity(32);
for i in 0..1000 {
    buf.clear();
    write!(&mut buf, "item-{}", i).unwrap();
    process(&buf);
}
```

Related: `mem-avoid-format`, `mem-reuse-collections`, `mem-with-capacity`

## mem-arena-allocator

> Use arena allocators for batch allocations

### Why It Matters

Arena allocators (bump allocators) allocate memory from a contiguous region, making allocation extremely fast (just bump a pointer). All allocations are freed at once when the arena is dropped. Perfect for request-scoped or parse-tree allocations.

### Bad

```rust
// Many small allocations during parsing
fn parse(input: &str) -> Vec<Node> {
    let mut nodes = Vec::new();
    for token in tokenize(input) {
        nodes.push(Box::new(Node::new(token)));  // Heap alloc per node!
    }
    nodes
}

// Per-request allocations add up
fn handle_request(req: Request) -> Response {
    let headers = parse_headers(&req);      // Allocates
    let body = parse_body(&req);            // Allocates
    let response = generate_response();     // Allocates
    // All freed individually at end
    response
}
```

### Good

```rust
use bumpalo::Bump;

// All nodes allocated from same arena
fn parse<'a>(input: &str, arena: &'a Bump) -> Vec<&'a Node> {
    let mut nodes = Vec::new();
    for token in tokenize(input) {
        let node = arena.alloc(Node::new(token));  // Fast bump!
        nodes.push(node);
    }
    nodes
}  // Arena freed all at once

// Per-request arena
fn handle_request(req: Request) -> Response {
    let arena = Bump::new();
    
    let headers = parse_headers(&req, &arena);
    let body = parse_body(&req, &arena);
    let response = generate_response(&arena);
    
    // Convert to owned response before arena drops
    response.to_owned()
}  // All request memory freed instantly
```

### Thread-Local Scratch Arena Pattern

```rust
use bumpalo::Bump;
use std::cell::RefCell;

thread_local! {
    static SCRATCH: RefCell<Bump> = RefCell::new(Bump::with_capacity(4 * 1024));
}

fn with_scratch<T>(f: impl FnOnce(&Bump) -> T) -> T {
    SCRATCH.with(|scratch| {
        let arena = scratch.borrow();
        let result = f(&arena);
        result
    })
}

fn reset_scratch() {
    SCRATCH.with(|scratch| {
        scratch.borrow_mut().reset();
    });
}

// Usage
fn process_batch(items: &[Item]) -> Vec<Output> {
    with_scratch(|arena| {
        let temp_data: Vec<&TempData> = items
            .iter()
            .map(|item| arena.alloc(compute_temp(item)))
            .collect();
        
        // Use temp_data...
        let result = finalize(&temp_data);
        
        reset_scratch();  // Reuse arena memory
        result
    })
}
```

### Evidence from ROC Compiler

```rust
// https://github.com/roc-lang/roc/blob/main/crates/compiler/solve/src/to_var.rs
std::thread_local! {
    static SCRATCHPAD: RefCell<Option<bumpalo::Bump>> = 
        RefCell::new(Some(bumpalo::Bump::with_capacity(4 * 1024)));
}

fn take_scratchpad() -> bumpalo::Bump {
    SCRATCHPAD.with(|f| f.take().unwrap())
}

fn put_scratchpad(scratchpad: bumpalo::Bump) {
    SCRATCHPAD.with(|f| {
        f.replace(Some(scratchpad));
    });
}
```

### Bumpalo Collections

```rust
use bumpalo::Bump;
use bumpalo::collections::{Vec, String};

fn process<'a>(arena: &'a Bump, input: &str) -> Vec<'a, String<'a>> {
    let mut results = Vec::new_in(arena);
    
    for word in input.split_whitespace() {
        let mut s = String::new_in(arena);
        s.push_str(word);
        s.push_str("_processed");
        results.push(s);
    }
    
    results  // All allocated in arena
}
```

### When to Use Arenas

| Situation | Use Arena? |
|-----------|-----------|
| Parsing (AST nodes) | Yes |
| Request handling | Yes |
| Batch processing | Yes |
| Long-lived data | No |
| Data escaping scope | No (or copy out) |
| Simple programs | Overkill |

### Performance Impact

Arena/bump allocation removes per-allocation metadata overhead and can be
substantially faster than the global allocator — often an order of magnitude in
microbenchmarks — but the actual speedup depends on the allocator, workload,
and allocation size. Arena reset is O(1) regardless of how many allocations
were made. Measure with [criterion](https://crates.io/crates/criterion) to
confirm the benefit in your specific use case.

```rust
// Memory trade-off:
// - Arena wastes some memory (unused capacity at the end)
// - But eliminates per-allocation metadata overhead
// - Frees everything in O(1) with a single bump reset
```

Related: `mem-with-capacity`, `mem-reuse-collections`, `opt-profile-first`
