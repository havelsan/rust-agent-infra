---
name: rust-37-performance-1of2
description: Rust rules module 37: Performance Patterns (part 1 of 2). 7 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `perf-`
---

# Performance Patterns (part 1/2)

Priority: MEDIUM. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `perf-iter-over-index` - Prefer iterators over manual indexing
- `perf-iter-lazy` - Keep iterators lazy, collect only when needed
- `perf-collect-once` - Don't collect intermediate iterators
- `perf-entry-api` - Use entry API for map insert-or-update
- `perf-drain-reuse` - Use drain to reuse allocations
- `perf-extend-batch` - Use extend for batch insertions
- `perf-chain-avoid` - Avoid chain in hot loops

---

## perf-iter-over-index

> Prefer iterators over manual indexing

### Why It Matters

Iterators are the idiomatic way to traverse collections in Rust. They enable bounds check elimination, SIMD auto-vectorization, and cleaner code. Manual indexing (`for i in 0..len`) often prevents these optimizations and introduces off-by-one error risks.

### Bad

```rust
// Manual indexing - bounds checked every iteration
fn sum_squares(data: &[i32]) -> i64 {
    let mut sum = 0i64;
    for i in 0..data.len() {
        sum += (data[i] as i64) * (data[i] as i64);
    }
    sum
}

// Index-based iteration with multiple collections
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    let mut sum = 0.0;
    for i in 0..a.len().min(b.len()) {
        sum += a[i] * b[i];
    }
    sum
}

// Mutating with indices
fn double_values(data: &mut [i32]) {
    for i in 0..data.len() {
        data[i] *= 2;
    }
}
```

### Good

```rust
// Iterator - bounds checks eliminated, SIMD-friendly
fn sum_squares(data: &[i32]) -> i64 {
    data.iter()
        .map(|&x| (x as i64) * (x as i64))
        .sum()
}

// Zip iterators - no manual length handling
fn dot_product(a: &[f64], b: &[f64]) -> f64 {
    a.iter()
        .zip(b.iter())
        .map(|(&x, &y)| x * y)
        .sum()
}

// Mutable iteration
fn double_values(data: &mut [i32]) {
    for x in data.iter_mut() {
        *x *= 2;
    }
}
```

### When Indexing Is Needed

Sometimes you genuinely need indices:

```rust
// Need the index for output or processing
for (i, value) in data.iter().enumerate() {
    println!("Index {}: {}", i, value);
}

// Non-sequential access patterns
fn interleave(data: &mut [i32]) {
    let mid = data.len() / 2;
    for i in 0..mid {
        data.swap(i * 2, mid + i);
    }
}
```

### Performance Comparison

| Pattern | Bounds Checks | SIMD Potential | Clarity |
|---------|---------------|----------------|---------|
| `for i in 0..len` | Every access | Limited | Medium |
| `for &x in slice` | None | High | High |
| `.iter().enumerate()` | None | Medium | High |
| `get_unchecked` | None (unsafe) | High | Low |

### Iterator Advantages

```rust
// Chaining operations - single pass
let result: Vec<_> = data.iter()
    .filter(|x| **x > 0)
    .map(|x| x * 2)
    .collect();

// Early termination optimized
let found = data.iter().any(|&x| x == target);

// Parallel iteration (with rayon)
use rayon::prelude::*;
let sum: i64 = data.par_iter().map(|&x| x as i64).sum();
```

Related: `perf-iter-lazy`, `opt-bounds-check`, `anti-index-over-iter`, `conc-rayon-par-iter`

## perf-iter-lazy

> Keep iterators lazy, collect only when needed

### Why It Matters

Rust iterators are lazy—they compute values on demand. This enables single-pass processing, avoids intermediate allocations, and allows short-circuiting. Calling `.collect()` too early forces evaluation and allocates unnecessarily.

### Bad

```rust
// Collects intermediate results unnecessarily
fn process(data: Vec<i32>) -> Vec<i32> {
    let filtered: Vec<_> = data.into_iter()
        .filter(|x| *x > 0)
        .collect();  // Unnecessary allocation
    
    let mapped: Vec<_> = filtered.into_iter()
        .map(|x| x * 2)
        .collect();  // Another unnecessary allocation
    
    mapped.into_iter()
        .take(10)
        .collect()
}

// Collects before checking existence
fn has_positive(data: &[i32]) -> bool {
    let positives: Vec<_> = data.iter()
        .filter(|&&x| x > 0)
        .collect();  // Allocates entire filtered result
    
    !positives.is_empty()
}
```

### Good

```rust
// Single chain, single collect
fn process(data: Vec<i32>) -> Vec<i32> {
    data.into_iter()
        .filter(|x| *x > 0)
        .map(|x| x * 2)
        .take(10)
        .collect()
}

// Short-circuits on first match
fn has_positive(data: &[i32]) -> bool {
    data.iter().any(|&x| x > 0)
}
```

### Lazy Iterator Methods

These methods return iterators (lazy):

| Method | Description |
|--------|-------------|
| `.filter()` | Keep matching elements |
| `.map()` | Transform elements |
| `.take(n)` | Limit to n elements |
| `.skip(n)` | Skip first n elements |
| `.zip()` | Pair with another iterator |
| `.chain()` | Concatenate iterators |
| `.flat_map()` | Map and flatten |
| `.enumerate()` | Add index |

### Consuming Methods

These methods consume the iterator (evaluate immediately):

| Method | Description |
|--------|-------------|
| `.collect()` | Gather into collection |
| `.for_each()` | Execute side effect |
| `.count()` | Count elements |
| `.sum()` | Sum elements |
| `.fold()` | Accumulate value |
| `.any()` | Check if any match |
| `.all()` | Check if all match |
| `.find()` | Find first match |

### Short-Circuit Benefits

```rust
// Without lazy: processes ALL items
let found: Vec<_> = items.iter()
    .filter(|x| expensive_check(x))
    .collect();
let result = found.first();

// With lazy: stops at first match
let result = items.iter()
    .find(|x| expensive_check(x));
```

### Pattern: Process Without Collecting

```rust
// Print all matches without allocating
data.iter()
    .filter(|x| x.is_valid())
    .for_each(|x| println!("{}", x));

// Count without collecting
let count = data.iter()
    .filter(|x| x.is_valid())
    .count();

// Sum without intermediate collection
let total: i64 = data.iter()
    .filter(|x| x.is_valid())
    .map(|x| x.value as i64)
    .sum();
```

Related: `perf-collect-once`, `perf-iter-over-index`, `anti-collect-intermediate`

## perf-collect-once

> Don't collect intermediate iterators

### Why It Matters

Each `.collect()` allocates a new collection. Chaining multiple operations with intermediate collections wastes memory and CPU cycles. Keep iterator chains lazy and collect only once at the end.

### Bad

```rust
// Three allocations, three passes
fn process_users(users: Vec<User>) -> Vec<String> {
    let active: Vec<_> = users.into_iter()
        .filter(|u| u.is_active)
        .collect();
    
    let verified: Vec<_> = active.into_iter()
        .filter(|u| u.is_verified)
        .collect();
    
    verified.into_iter()
        .map(|u| u.name)
        .collect()
}

// Collecting to count
fn count_valid(items: &[Item]) -> usize {
    items.iter()
        .filter(|i| i.is_valid())
        .collect::<Vec<_>>()  // Unnecessary!
        .len()
}
```

### Good

```rust
// One allocation, one pass
fn process_users(users: Vec<User>) -> Vec<String> {
    users.into_iter()
        .filter(|u| u.is_active)
        .filter(|u| u.is_verified)
        .map(|u| u.name)
        .collect()
}

// No allocation needed
fn count_valid(items: &[Item]) -> usize {
    items.iter()
        .filter(|i| i.is_valid())
        .count()
}
```

### Pattern: Deferred Collection

```rust
// Create the iterator chain
fn prepare_data(raw: Vec<RawData>) -> impl Iterator<Item = ProcessedData> {
    raw.into_iter()
        .filter(|d| d.is_valid())
        .map(ProcessedData::from)
}

// Collect only when needed
let data: Vec<_> = prepare_data(input).collect();

// Or consume without collecting
prepare_data(input).for_each(|d| process(d));
```

### When Intermediate Collection Is Needed

```rust
// Need to iterate multiple times
let items: Vec<_> = data.iter()
    .filter(|x| x.is_valid())
    .collect();

let count = items.len();
let first = items.first();
for item in &items {
    process(item);
}

// Need to sort (requires concrete collection)
let mut sorted: Vec<_> = data.iter()
    .filter(|x| x.is_active)
    .collect();
sorted.sort_by_key(|x| x.priority);
```

### Comparison

| Approach | Allocations | Passes | Memory |
|----------|-------------|--------|--------|
| Multiple `.collect()` | N | N | O(N × data) |
| Single chain + `.collect()` | 1 | 1 | O(data) |
| No `.collect()` (streaming) | 0 | 1 | O(1) |

### Pattern: Collect with Capacity

When you must collect, pre-allocate:

```rust
// With estimated capacity
let mut result = Vec::with_capacity(items.len());
result.extend(
    items.iter()
        .filter(|x| x.is_valid())
        .map(|x| x.clone())
);
```

Related: `perf-iter-lazy`, `mem-with-capacity`, `anti-collect-intermediate`

## perf-entry-api

> Use entry API for map insert-or-update

### Why It Matters

The entry API performs a single lookup for insert-or-update operations. Without it, you lookup twice: once to check existence, once to insert. For `HashMap` and `BTreeMap`, the entry API is both faster and more idiomatic.

### Bad

```rust
use std::collections::HashMap;

// Double lookup: contains_key + insert
fn increment(map: &mut HashMap<String, u32>, key: String) {
    if map.contains_key(&key) {
        *map.get_mut(&key).unwrap() += 1;
    } else {
        map.insert(key, 1);
    }
}

// Double lookup with get + insert
fn get_or_insert(map: &mut HashMap<String, Vec<i32>>, key: String) -> &mut Vec<i32> {
    if !map.contains_key(&key) {
        map.insert(key.clone(), Vec::new());
    }
    map.get_mut(&key).unwrap()
}

// Triple lookup pattern
fn update_or_default(map: &mut HashMap<String, Config>, key: &str, value: i32) {
    match map.get(key) {
        Some(config) => {
            let mut new_config = config.clone();
            new_config.value = value;
            map.insert(key.to_string(), new_config);
        }
        None => {
            map.insert(key.to_string(), Config::default());
        }
    }
}
```

### Good

```rust
use std::collections::HashMap;
use std::collections::hash_map::Entry;

// Single lookup with entry
fn increment(map: &mut HashMap<String, u32>, key: String) {
    *map.entry(key).or_insert(0) += 1;
}

// Single lookup, returns mutable reference
fn get_or_insert(map: &mut HashMap<String, Vec<i32>>, key: String) -> &mut Vec<i32> {
    map.entry(key).or_insert_with(Vec::new)
}

// Single lookup with and_modify
fn update_or_default(map: &mut HashMap<String, Config>, key: String, value: i32) {
    map.entry(key)
        .and_modify(|config| config.value = value)
        .or_insert_with(Config::default);
}
```

### Entry API Methods

| Method | Behavior |
|--------|----------|
| `.or_insert(val)` | Insert `val` if empty |
| `.or_insert_with(f)` | Insert `f()` if empty (lazy) |
| `.or_default()` | Insert `Default::default()` if empty |
| `.and_modify(f)` | Apply `f` if occupied |
| `.or_insert_with_key(f)` | Insert `f(&key)` if empty |

### Pattern: Count Occurrences

```rust
fn word_count(text: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    counts
}
```

### Pattern: Group By

```rust
fn group_by_category(items: Vec<Item>) -> HashMap<Category, Vec<Item>> {
    let mut groups: HashMap<Category, Vec<Item>> = HashMap::new();
    for item in items {
        groups.entry(item.category.clone())
            .or_default()
            .push(item);
    }
    groups
}
```

### Pattern: Complex Entry Logic

```rust
match map.entry(key) {
    Entry::Occupied(mut entry) => {
        let value = entry.get_mut();
        if should_update(value) {
            *value = new_value;
        }
    }
    Entry::Vacant(entry) => {
        entry.insert(default_value);
    }
}
```

### Performance

| Pattern | Lookups | Hash Computations |
|---------|---------|-------------------|
| `contains_key` + `insert` | 2 | 2 |
| `get` + `insert` | 2 | 2 |
| `entry().or_insert()` | 1 | 1 |

Related: `perf-extend-batch`, `mem-with-capacity`, `perf-drain-reuse`, `coll-map-choice`

## perf-drain-reuse

> Use drain to reuse allocations

### Why It Matters

`drain()` removes elements from a collection while keeping its allocated capacity. This allows reusing the same allocation across iterations, avoiding repeated allocate/deallocate cycles in loops.

### Bad

```rust
// Allocates new Vec every iteration
fn process_batches(data: Vec<Item>) {
    let mut remaining = data;
    
    while !remaining.is_empty() {
        let batch: Vec<_> = remaining.drain(..100.min(remaining.len())).collect();
        process_batch(batch);
        // remaining keeps its capacity - good
        // but batch allocates new every time - bad
    }
}

// Clears and reallocates
fn reuse_buffer() {
    for _ in 0..1000 {
        let mut buffer = Vec::new();  // Allocates each iteration
        fill_buffer(&mut buffer);
        process(&buffer);
    }
}
```

### Good

```rust
// Reuses allocation with drain
fn process_batches(mut data: Vec<Item>) {
    let mut batch = Vec::with_capacity(100);
    
    while !data.is_empty() {
        batch.extend(data.drain(..100.min(data.len())));
        process_batch(&batch);
        batch.clear();  // Keeps capacity
    }
}

// Reuses buffer across iterations
fn reuse_buffer() {
    let mut buffer = Vec::new();
    
    for _ in 0..1000 {
        buffer.clear();  // Keeps capacity
        fill_buffer(&mut buffer);
        process(&buffer);
    }
}
```

### Drain Methods

| Collection | Method | Behavior |
|------------|--------|----------|
| `Vec<T>` | `.drain(range)` | Remove range, shift remaining |
| `Vec<T>` | `.drain(..)` | Remove all (like clear) |
| `VecDeque<T>` | `.drain(range)` | Remove range |
| `String` | `.drain(range)` | Remove char range |
| `HashMap<K,V>` | `.drain()` | Remove all entries |
| `HashSet<T>` | `.drain()` | Remove all elements |

### Pattern: Batch Processing

```rust
fn process_in_chunks(mut items: Vec<Item>, chunk_size: usize) {
    while !items.is_empty() {
        let chunk: Vec<_> = items.drain(..chunk_size.min(items.len())).collect();
        process_chunk(chunk);
    }
}
```

### Pattern: Transfer Between Collections

```rust
// Move all elements without reallocation
fn transfer_all(src: &mut Vec<Item>, dst: &mut Vec<Item>) {
    dst.extend(src.drain(..));
    // src is now empty but keeps capacity
}

// Move matching elements
fn transfer_matching(src: &mut Vec<Item>, dst: &mut Vec<Item>, predicate: impl Fn(&Item) -> bool) {
    let matching: Vec<_> = src.drain(..).filter(predicate).collect();
    dst.extend(matching);
}
```

### Pattern: HashMap Drain

```rust
use std::collections::HashMap;

fn process_and_clear(map: &mut HashMap<String, Value>) {
    // Process all entries, clearing the map
    for (key, value) in map.drain() {
        process(key, value);
    }
    // map is now empty but keeps capacity
}
```

### drain vs clear vs take

| Operation | Elements | Capacity | Returns |
|-----------|----------|----------|---------|
| `.clear()` | Removed | Kept | Nothing |
| `.drain(..)` | Removed | Kept | Iterator |
| `std::mem::take()` | Moved out | Reset to 0 | Owned collection |

```rust
// clear: just empty
vec.clear();

// drain: empty and iterate
for item in vec.drain(..) {
    process(item);
}

// take: swap with empty, get ownership
let old_vec = std::mem::take(&mut vec);
```

Related: `mem-reuse-collections`, `perf-extend-batch`, `mem-with-capacity`

## perf-extend-batch

> Use extend for batch insertions

### Why It Matters

`extend()` can pre-allocate capacity for the incoming elements and insert them in a single operation. Individual `push()` calls may trigger multiple reallocations as the collection grows. For adding multiple elements, `extend()` is both faster and clearer.

### Bad

```rust
// Multiple potential reallocations
fn collect_results(sources: Vec<Source>) -> Vec<Result> {
    let mut results = Vec::new();
    
    for source in sources {
        for result in source.get_results() {
            results.push(result);  // May reallocate
        }
    }
    results
}

// Loop with push for known data
fn build_list() -> Vec<i32> {
    let mut list = Vec::new();
    for i in 0..1000 {
        list.push(i);  // Many reallocations
    }
    list
}

// Appending another collection
fn combine(mut a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    for item in b {
        a.push(item);
    }
    a
}
```

### Good

```rust
// Single extend with size hint
fn collect_results(sources: Vec<Source>) -> Vec<Result> {
    let mut results = Vec::new();
    
    for source in sources {
        results.extend(source.get_results());
    }
    results
}

// Direct collection from iterator
fn build_list() -> Vec<i32> {
    (0..1000).collect()
}

// Extend for combining
fn combine(mut a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    a.extend(b);
    a
}
```

### Extend with Capacity

For best performance, combine with `reserve()`:

```rust
fn merge_all(chunks: Vec<Vec<Item>>) -> Vec<Item> {
    // Calculate total size
    let total: usize = chunks.iter().map(|c| c.len()).sum();
    
    let mut result = Vec::with_capacity(total);
    for chunk in chunks {
        result.extend(chunk);
    }
    result
}
```

### Extend Methods

| Method | Description |
|--------|-------------|
| `.extend(iter)` | Add all elements from iterator |
| `.extend_from_slice(&[T])` | Add from slice (for `Copy` types) |
| `.append(&mut Vec)` | Move all from another Vec |

### Pattern: Building Strings

```rust
// Bad: multiple allocations
fn build_message(parts: &[&str]) -> String {
    let mut result = String::new();
    for part in parts {
        result.push_str(part);  // May reallocate
    }
    result
}

// Good: extend with known parts
fn build_message(parts: &[&str]) -> String {
    let total_len: usize = parts.iter().map(|s| s.len()).sum();
    let mut result = String::with_capacity(total_len);
    for part in parts {
        result.push_str(part);
    }
    result
}

// Better: collect/join
fn build_message(parts: &[&str]) -> String {
    parts.concat()  // or parts.join("")
}
```

### HashMap/HashSet Extend

```rust
use std::collections::HashMap;

// Extend from iterator of tuples
fn merge_maps(mut base: HashMap<String, i32>, other: HashMap<String, i32>) -> HashMap<String, i32> {
    base.extend(other);  // Moves entries from other
    base
}

// Extend from iterator
let mut set = HashSet::new();
set.extend(items.iter().map(|i| i.id));
```

### Performance

| Operation | Allocations | Complexity |
|-----------|-------------|------------|
| N × `push()` | O(log N) | O(N) amortized |
| `extend(iter)` | O(1)* | O(N) |
| `with_capacity` + `extend` | 1 | O(N) |

*When iterator provides accurate `size_hint()`

Related: `mem-with-capacity`, `perf-drain-reuse`, `mem-reuse-collections`

## perf-chain-avoid

> Avoid chain in hot loops

### Why It Matters

`Iterator::chain()` adds overhead for checking which iterator is active on every `.next()` call. In hot loops, this branch prediction overhead can impact performance. For performance-critical code, prefer single iterators or pre-combined collections.

### Bad

```rust
// Chain in hot inner loop
fn process_hot_path(a: &[i32], b: &[i32]) -> i64 {
    let mut sum = 0i64;
    
    // Called millions of times
    for _ in 0..1_000_000 {
        for x in a.iter().chain(b.iter()) {  // Branch every iteration
            sum += *x as i64;
        }
    }
    sum
}

// Chaining multiple small slices in tight loop
fn combine_results(parts: &[&[u8]]) -> Vec<u8> {
    let mut result = Vec::new();
    for part in parts {
        for byte in std::iter::once(&0u8).chain(part.iter()) {
            result.push(*byte);
        }
    }
    result
}
```

### Good

```rust
// Separate loops - branch-free inner loops
fn process_hot_path(a: &[i32], b: &[i32]) -> i64 {
    let mut sum = 0i64;
    
    for _ in 0..1_000_000 {
        for x in a {
            sum += *x as i64;
        }
        for x in b {
            sum += *x as i64;
        }
    }
    sum
}

// Pre-combine outside hot loop
fn combine_results(parts: &[&[u8]]) -> Vec<u8> {
    let mut result = Vec::new();
    for part in parts {
        result.push(0u8);
        result.extend_from_slice(part);
    }
    result
}
```

### When Chain Is Fine

Chain is perfectly acceptable when:

```rust
// One-time iteration, not in hot path
fn collect_all(a: Vec<i32>, b: Vec<i32>) -> Vec<i32> {
    a.into_iter().chain(b).collect()
}

// Lazy evaluation with short-circuit
fn find_in_either(a: &[Item], b: &[Item], target: i32) -> Option<&Item> {
    a.iter().chain(b.iter()).find(|x| x.id == target)
}

// Small number of elements
fn get_prefixes() -> impl Iterator<Item = &'static str> {
    ["Mr.", "Mrs.", "Dr."].iter().copied()
        .chain(["Prof."].iter().copied())
}
```

### Alternative Patterns

#### Pre-allocate and Extend

```rust
fn merge_slices(slices: &[&[i32]]) -> Vec<i32> {
    let total: usize = slices.iter().map(|s| s.len()).sum();
    let mut result = Vec::with_capacity(total);
    for slice in slices {
        result.extend_from_slice(slice);
    }
    result
}
```

#### Use append for Vecs

```rust
fn combine_vecs(mut a: Vec<i32>, mut b: Vec<i32>) -> Vec<i32> {
    a.append(&mut b);  // Moves elements, no reallocation if a has capacity
    a
}
```

#### Flatten Instead of Chain

```rust
// Instead of: a.iter().chain(b.iter()).chain(c.iter())
let all = [a, b, c];
for item in all.iter().flat_map(|slice| slice.iter()) {
    process(item);
}
```

### Performance Impact

| Pattern | Per-Item Overhead |
|---------|-------------------|
| Single iterator | None |
| `chain(a, b)` | 1 branch per item |
| `chain(a, b, c)` | 2 branches per item |
| Nested chains | Compounds |
| Separate loops | None (but code duplication) |

Related: `perf-iter-over-index`, `perf-extend-batch`, `opt-cache-friendly`
