---
name: rust-28-collections
description: Rust rules module 28: Collections. 4 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `coll-`
---

# Collections

Priority: MEDIUM. 4 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `coll-binaryheap` - Use `BinaryHeap` for a priority queue or repeated max-extraction
- `coll-map-choice` - Pick the map by access pattern: `HashMap` (fast, unordered), `BTreeMap` (sorted / range queries), `IndexMap` (insertion order)
- `coll-seq-choice` - Default to `Vec`; use `VecDeque` for queue/deque behaviour; avoid `LinkedList`
- `coll-set-membership` - Use `HashSet`/`BTreeSet` for membership tests and dedup, not linear `Vec::contains`

---

## coll-binaryheap

> Use `BinaryHeap` for a priority queue or repeated max-extraction

### Why It Matters

`std::collections::BinaryHeap<T>` is a max-heap with O(log n) `push` and `pop` (extract-max) and O(1) `peek`. When you repeatedly need the largest (or smallest) element from a growing or shrinking set, it beats sorting a `Vec` after every insertion — sorting is O(n log n) each time, while a heap amortises that cost to O(log n) per operation. For a **min-heap**, wrap your values in `std::cmp::Reverse<T>`; the heap's ordering flips, and the smallest value is extracted first.

### Bad

```rust
fn top_priority_task(tasks: &mut Vec<(u32, String)>) -> Option<String> {
    if tasks.is_empty() {
        return None;
    }
    // O(n) scan to find the max, then O(n) shift to remove it — O(n) per call.
    let max_idx = tasks
        .iter()
        .enumerate()
        .max_by_key(|(_, (p, _))| *p)
        .map(|(i, _)| i)?;
    Some(tasks.remove(max_idx).1)
}

fn main() {
    let mut tasks = vec![
        (3, "low priority".to_string()),
        (10, "urgent".to_string()),
        (7, "medium priority".to_string()),
    ];
    // Repeated calls become O(n²) overall.
    while let Some(task) = top_priority_task(&mut tasks) {
        println!("running: {task}");
    }
}
```

### Good

```rust
use std::cmp::Reverse;
use std::collections::BinaryHeap;

#[derive(Eq, PartialEq, Ord, PartialOrd)]
struct Task {
    priority: u32, // higher = more urgent
    name: String,
}

fn run_scheduler(tasks: impl IntoIterator<Item = (u32, &'static str)>) {
    // BinaryHeap: O(log n) push and pop — max-priority task extracted first.
    let mut heap: BinaryHeap<Task> = tasks
        .into_iter()
        .map(|(priority, name)| Task {
            priority,
            name: name.to_string(),
        })
        .collect();

    while let Some(task) = heap.pop() {
        println!("running [priority={}]: {}", task.priority, task.name);
    }
}

fn top_k_largest(values: &[i32], k: usize) -> Vec<i32> {
    // Min-heap of size k using Reverse<i32>: keeps the k largest elements.
    let mut min_heap: BinaryHeap<Reverse<i32>> = BinaryHeap::with_capacity(k + 1);
    for &v in values {
        min_heap.push(Reverse(v));
        if min_heap.len() > k {
            min_heap.pop(); // discard the current minimum
        }
    }
    // Drain from min to max for a sorted result.
    let mut result: Vec<i32> = min_heap.into_iter().map(|Reverse(v)| v).collect();
    result.sort_unstable_by(|a, b| b.cmp(a));
    result
}

fn main() {
    run_scheduler([
        (3, "low priority task"),
        (10, "urgent task"),
        (7, "medium priority task"),
        (10, "equally urgent task"),
    ]);
    // Output order: urgent, equally urgent, medium, low

    let top3 = top_k_largest(&[4, 1, 9, 2, 7, 5, 8], 3);
    println!("top 3: {top3:?}"); // [9, 8, 7]
}
```

### Max-heap vs Min-heap at a glance

| Want | How |
|---|---|
| Largest item first (max-heap) | `BinaryHeap<T>` directly |
| Smallest item first (min-heap) | `BinaryHeap<Reverse<T>>` |
| Peek without removing | `.peek()` — O(1) |
| Drain in sorted order | `.into_sorted_vec()` — O(n log n) |

**Note:** `BinaryHeap` does not support efficient arbitrary removal or priority updates. If you need those, consider a third-party crate like `keyed_priority_queue` or restructure with lazy deletion.

Related: `coll-seq-choice`, `perf-iter-over-index`

## coll-map-choice

> Pick the map by access pattern: `HashMap` (fast, unordered), `BTreeMap` (sorted / range queries), `IndexMap` (insertion order)

### Why It Matters

`HashMap` is the right default: O(1) average lookup and insertion with no ordering overhead. `BTreeMap` keeps keys sorted in a B-tree, enabling efficient range queries and ordered iteration at the cost of O(log n) operations. The `indexmap` crate's `IndexMap` preserves insertion order with O(1) average lookup — valuable for deterministic output, config files, or any API where output order must match input order. Choosing the wrong map wastes CPU cycles on sorting you don't need or forces you to sort after the fact.

### Bad

```rust
use std::collections::HashMap;

fn word_counts(text: &str) -> HashMap<&str, usize> {
    let mut counts = HashMap::new();
    for word in text.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    counts
    // Iterating this for a report produces random order every run.
    // Caller has to sort externally — meaning repeated, avoidable work.
}

fn main() {
    let counts = word_counts("the quick brown fox jumps over the lazy dog");
    // Non-deterministic output: order changes between runs.
    for (word, count) in &counts {
        println!("{word}: {count}");
    }
}
```

### Good

```rust
// --- 1. HashMap: default, fast, unordered ---
use std::collections::HashMap;

fn total_scores<'a>(records: &[(&'a str, u32)]) -> HashMap<&'a str, u32> {
    let mut scores: HashMap<&'a str, u32> = HashMap::new();
    for &(name, score) in records {
        *scores.entry(name).or_insert(0) += score;
    }
    scores
}

// --- 2. BTreeMap: sorted keys, range queries ---
use std::collections::BTreeMap;

fn events_in_range(
    log: &BTreeMap<u64, String>,
    start: u64,
    end: u64,
) -> Vec<(&u64, &String)> {
    // range() is only possible because BTreeMap keeps keys sorted.
    log.range(start..=end).collect()
}

fn build_log() -> BTreeMap<u64, String> {
    let mut log = BTreeMap::new();
    log.insert(1_000, "server started".to_string());
    log.insert(2_000, "request received".to_string());
    log.insert(3_000, "response sent".to_string());
    log
}

// --- 3. IndexMap: insertion order + O(1) lookup ---
use indexmap::IndexMap;

fn parse_config(pairs: &[(&str, &str)]) -> IndexMap<String, String> {
    // Keys iterated in the order they were inserted — deterministic output.
    pairs
        .iter()
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect()
}

fn main() {
    // BTreeMap range query
    let log = build_log();
    let window = events_in_range(&log, 1_000, 2_500);
    for (ts, msg) in window {
        println!("{ts}: {msg}");
    }

    // IndexMap preserves insertion order
    let cfg = parse_config(&[("host", "localhost"), ("port", "8080"), ("debug", "true")]);
    for (k, v) in &cfg {
        println!("{k} = {v}"); // always: host, port, debug
    }
}
```

### Which to Use

| Requirement | Choose |
|---|---|
| Fast lookup, order irrelevant | `HashMap` |
| Sorted iteration or range queries | `BTreeMap` |
| Insertion-order iteration + fast lookup | `IndexMap` (indexmap crate) |
| Tiny map (≤ 8 entries), no heap | consider an array of tuples |

**Note on hashing:** The default `HashMap` uses SipHash-1-3, which is DOS-resistant but not the fastest. For non-adversarial hot paths, see `perf-ahash` for a faster hasher that drops in as a type parameter.

Related: `perf-ahash`, `perf-entry-api`, `coll-seq-choice`

## coll-seq-choice

> Default to `Vec`; use `VecDeque` for queue/deque behaviour; avoid `LinkedList`

### Why It Matters

`Vec<T>` is a contiguous growable array — the right sequence type for almost every use case. Contiguous layout means the CPU prefetcher works in your favour and each element is a single pointer dereference away. `VecDeque<T>` is a ring buffer with O(1) amortised push and pop at **both** ends; reach for it when you need a FIFO queue or a sliding window. `LinkedList<T>` is heap-allocated per node and pointer-chased on every access; in practice it is almost always slower than `Vec` or `VecDeque` for real workloads, and the standard library itself discourages its use.

### Bad

```rust
fn process_queue(items: Vec<String>) {
    let mut queue = items;
    while !queue.is_empty() {
        // O(n): every element shifts left after removal.
        let item = queue.remove(0);
        println!("processing: {item}");
    }
}

fn main() {
    process_queue(vec![
        "first".to_string(),
        "second".to_string(),
        "third".to_string(),
    ]);
}
```

`remove(0)` on a `Vec` is O(n) because it must shift every remaining element. A loop of n items becomes O(n²).

### Good

```rust
use std::collections::VecDeque;

fn process_queue(items: impl IntoIterator<Item = String>) {
    // VecDeque: O(1) pop_front — the right tool for a FIFO queue.
    let mut queue: VecDeque<String> = items.into_iter().collect();
    while let Some(item) = queue.pop_front() {
        println!("processing: {item}");
    }
}

fn sliding_window_max(values: &[i32], k: usize) -> Vec<i32> {
    // VecDeque also shines as a fixed-size sliding window.
    let mut window: VecDeque<i32> = VecDeque::with_capacity(k);
    let mut result = Vec::with_capacity(values.len().saturating_sub(k) + 1);

    for &v in values {
        window.push_back(v);
        if window.len() > k {
            window.pop_front();
        }
        if window.len() == k {
            result.push(*window.iter().max().unwrap());
        }
    }
    result
}

fn main() {
    process_queue(["alpha".to_string(), "beta".to_string(), "gamma".to_string()]);

    let maxima = sliding_window_max(&[3, 1, 2, 5, 4], 3);
    println!("{maxima:?}"); // [3, 5, 5]
}
```

### Which to Use

| Requirement | Choose |
|---|---|
| General-purpose growable list | `Vec<T>` |
| FIFO queue, deque, or sliding window | `VecDeque<T>` |
| Need O(1) split/splice at arbitrary positions | consider `VecDeque<T>` or rethink the design |
| Linked list (almost never) | `LinkedList<T>` — only if profiling proves it faster |

**Conversion:** `Vec` and `VecDeque` convert cheaply into each other via `From`/`Into` when you need to switch representation.

Related: `mem-with-capacity`, `perf-drain-reuse`, `coll-map-choice`

## coll-set-membership

> Use `HashSet`/`BTreeSet` for membership tests and dedup, not linear `Vec::contains`

### Why It Matters

`Vec::contains` is O(n) per call. When you check membership for m items against a list of n items in a loop, the total cost is O(n × m) — quadratic. A `HashSet` reduces each check to O(1) average, making the same loop O(n + m). Use `BTreeSet` when you also need sorted iteration or range queries. Keep a `Vec` only when order matters, duplicates are intentional, or the collection is so small (say, ≤ 8 items) that the overhead of hashing outweighs the savings.

Deduplication follows the same rule: collecting into a `HashSet` is one line and O(n), while repeatedly removing duplicates from a sorted `Vec` is more code and no faster.

### Bad

```rust
fn find_common(all_users: &[String], active_ids: &[String]) -> Vec<String> {
    let mut common = Vec::new();
    for user in all_users {
        // O(n) per iteration → O(n * m) total
        if active_ids.contains(user) {
            common.push(user.clone());
        }
    }
    common
}

fn deduplicate(items: Vec<String>) -> Vec<String> {
    let mut seen: Vec<String> = Vec::new();
    for item in items {
        // O(n) per item — quadratic overall
        if !seen.contains(&item) {
            seen.push(item);
        }
    }
    seen
}
```

### Good

```rust
use std::collections::{BTreeSet, HashSet};

// O(n + m): build the set once, then test each user in O(1).
fn find_common(all_users: &[String], active_ids: &[String]) -> Vec<String> {
    let active: HashSet<&String> = active_ids.iter().collect();
    all_users
        .iter()
        .filter(|u| active.contains(u))
        .cloned()
        .collect()
}

// Dedup while preserving order: track seen items in a HashSet.
fn deduplicate_ordered(items: Vec<String>) -> Vec<String> {
    let mut seen = HashSet::with_capacity(items.len());
    items.into_iter().filter(|s| seen.insert(s.clone())).collect()
}

// Dedup into a sorted, unique collection — use BTreeSet.
fn unique_sorted(items: Vec<String>) -> Vec<String> {
    items.into_iter().collect::<BTreeSet<_>>().into_iter().collect()
}

fn main() {
    let users = vec!["alice".to_string(), "bob".to_string(), "carol".to_string()];
    let active = vec!["bob".to_string(), "carol".to_string(), "dave".to_string()];
    println!("{:?}", find_common(&users, &active)); // ["bob", "carol"]

    let raw = vec!["x".to_string(), "y".to_string(), "x".to_string(), "z".to_string()];
    println!("{:?}", deduplicate_ordered(raw)); // ["x", "y", "z"]
}
```

### Which to Use

| Requirement | Choose |
|---|---|
| Fast membership test, no ordering needed | `HashSet<T>` |
| Membership test + sorted iteration | `BTreeSet<T>` |
| Tiny set (≤ 8 items) | `Vec<T>` with `.contains` may be fine |
| Keep duplicates or care about insertion order | `Vec<T>` |

**Tip:** when building a `HashSet` that will be queried many times, call `HashSet::with_capacity(n)` upfront to avoid rehashing. See `mem-with-capacity`.

Related: `coll-map-choice`, `perf-ahash`
