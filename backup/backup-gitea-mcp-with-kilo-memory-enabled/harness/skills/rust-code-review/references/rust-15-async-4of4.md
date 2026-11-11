---
name: rust-15-async-4of4
description: Rust rules module 15: Async/Await (part 4 of 4). 5 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `async-`
---

# Async/Await (part 4/4)

Priority: HIGH. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `async-joinset-structured` - Use `JoinSet` for managing dynamic collections of spawned tasks
- `async-clone-before-await` - Clone Arc/Rc data before await points to avoid holding references across suspension
- `async-fn-in-trait` - Use native `async fn` in traits (stable 1.75) instead of the `async_trait` macro
- `async-async-fn-bounds` - Use `AsyncFn`/`AsyncFnMut`/`AsyncFnOnce` bounds instead of `F: Fn() -> Fut, Fut: Future`
- `async-cancel-safety` - Ensure futures used in `tokio::select!` branches are cancellation-safe

---

## async-joinset-structured

> Use `JoinSet` for managing dynamic collections of spawned tasks

### Why It Matters

When spawning a variable number of tasks, collecting `JoinHandle`s in a `Vec` and using `join_all` works but lacks flexibility. `JoinSet` provides a better abstraction: add/remove tasks dynamically, get results as they complete, and abort all on drop. It's the idiomatic way to manage task collections.

### Bad

```rust
// Manual handle management
let mut handles: Vec<JoinHandle<Result<Data>>> = Vec::new();

for url in urls {
    handles.push(tokio::spawn(fetch(url)));
}

// Wait for all, in order (not as they complete)
let results = futures::future::join_all(handles).await;

// No easy way to cancel all, handle errors progressively, or add more tasks
```

### Good

```rust
use tokio::task::JoinSet;

let mut set = JoinSet::new();

for url in urls {
    set.spawn(fetch(url.clone()));
}

// Process results as they complete
while let Some(result) = set.join_next().await {
    match result {
        Ok(Ok(data)) => process(data),
        Ok(Err(e)) => log::error!("Task failed: {}", e),
        Err(e) => log::error!("Task panicked: {}", e),
    }
}

// All tasks done, set is empty
```

### Dynamic Task Addition

```rust
use tokio::task::JoinSet;

async fn worker_pool(mut rx: mpsc::Receiver<Task>) {
    let mut set = JoinSet::new();
    let max_concurrent = 10;
    
    loop {
        tokio::select! {
            // Accept new tasks if under limit
            Some(task) = rx.recv(), if set.len() < max_concurrent => {
                set.spawn(process_task(task));
            }
            
            // Process completed tasks
            Some(result) = set.join_next() => {
                handle_result(result);
            }
            
            // Exit when no tasks and channel closed
            else => break,
        }
    }
}
```

### Abort on Drop

```rust
use tokio::task::JoinSet;

{
    let mut set = JoinSet::new();
    set.spawn(long_running_task());
    set.spawn(another_task());
    
    // Early exit
    return;
}  // JoinSet dropped here - all tasks are aborted!

// Explicit abort
let mut set = JoinSet::new();
set.spawn(task());
set.abort_all();  // Cancel all tasks
```

### Error Handling Pattern

```rust
use tokio::task::JoinSet;

async fn fetch_all(urls: &[String]) -> Vec<Result<Data, Error>> {
    let mut set = JoinSet::new();
    let mut results = Vec::new();
    
    for url in urls {
        set.spawn(fetch(url.clone()));
    }
    
    while let Some(join_result) = set.join_next().await {
        let result = match join_result {
            Ok(task_result) => task_result,
            Err(join_error) => {
                if join_error.is_panic() {
                    Err(Error::TaskPanicked)
                } else {
                    Err(Error::TaskCancelled)
                }
            }
        };
        results.push(result);
    }
    
    results
}
```

### With Cancellation

```rust
use tokio::task::JoinSet;
use tokio_util::sync::CancellationToken;

async fn run_workers(shutdown: CancellationToken) {
    let mut set = JoinSet::new();
    
    for i in 0..4 {
        let token = shutdown.child_token();
        set.spawn(async move {
            loop {
                tokio::select! {
                    _ = token.cancelled() => break,
                    _ = do_work(i) => {}
                }
            }
        });
    }
    
    // Wait for shutdown
    shutdown.cancelled().await;
    
    // Abort remaining tasks
    set.abort_all();
    
    // Wait for all to finish (drain aborted tasks)
    while set.join_next().await.is_some() {}
}
```

### Spawning with Context

```rust
use tokio::task::JoinSet;

let mut set: JoinSet<(usize, Result<Data, Error>)> = JoinSet::new();

for (index, url) in urls.iter().enumerate() {
    let url = url.clone();
    set.spawn(async move {
        (index, fetch(&url).await)
    });
}

// Results include their index
while let Some(result) = set.join_next().await {
    if let Ok((index, data)) = result {
        results[index] = Some(data);
    }
}
```

### JoinSet vs join_all

| Feature | JoinSet | join_all |
|---------|---------|----------|
| Add tasks dynamically | Yes | No |
| Results as-completed | Yes | No (all at once) |
| Abort all on drop | Yes | No |
| Cancel individual | Yes | No |
| Memory efficient | Yes | Pre-allocates |

Related: `async-join-parallel`, `async-cancellation-token`, `async-try-join`

## async-clone-before-await

> Clone Arc/Rc data before await points to avoid holding references across suspension

### Why It Matters

References held across `.await` points extend the future's lifetime and can cause borrow checker issues or prevent `Send` bounds. Cloning `Arc`/`Rc` before the await ensures the future only holds owned data, making it `Send` and avoiding lifetime complications.

### Bad

```rust
use std::sync::Arc;

async fn process(data: Arc<Data>) {
    // Borrow extends across await - future is not Send
    let slice = &data.items[..];  // Borrow of Arc contents
    
    expensive_async_operation().await;  // Await with active borrow
    
    use_slice(slice);  // Still using the borrow
}

// Error: future cannot be sent between threads safely
// because `&[Item]` cannot be sent between threads safely
tokio::spawn(process(data));
```

### Good

```rust
use std::sync::Arc;

async fn process(data: Arc<Data>) {
    // Clone what you need before await
    let items = data.items.clone();  // Owned Vec
    
    expensive_async_operation().await;
    
    use_items(&items);  // Using owned data
}

// Or clone the Arc itself
async fn share_data(data: Arc<Data>) {
    let data = data.clone();  // Another Arc handle
    
    some_async_work().await;
    
    process(&data);  // Safe - we own the Arc
}
```

### The Send Problem

```rust
// Futures must be Send to spawn on multi-threaded runtime
async fn not_send() {
    let rc = Rc::new(42);  // Rc is !Send
    
    tokio::time::sleep(Duration::from_secs(1)).await;
    
    println!("{}", rc);  // rc held across await
}

tokio::spawn(not_send());  // ERROR: future is not Send

// Fix: use Arc or don't hold across await
async fn is_send() {
    let arc = Arc::new(42);  // Arc is Send
    
    tokio::time::sleep(Duration::from_secs(1)).await;
    
    println!("{}", arc);
}

tokio::spawn(is_send());  // OK
```

### Minimizing Clones

```rust
// Bad: clone everything eagerly
async fn wasteful(data: Arc<LargeData>) {
    let data = (*data).clone();  // Clones entire LargeData
    async_work().await;
    use_one_field(&data.small_field);
}

// Good: clone only what you need
async fn efficient(data: Arc<LargeData>) {
    let small = data.small_field.clone();  // Clone only needed field
    async_work().await;
    use_one_field(&small);
}

// Good: if you need the whole thing, keep the Arc
async fn arc_efficient(data: Arc<LargeData>) {
    let data = data.clone();  // Cheap Arc clone
    async_work().await;
    use_data(&data);  // Access through Arc
}
```

### Spawn Pattern

```rust
// Common pattern: clone for spawned task
let shared = Arc::new(SharedState::new());

for i in 0..10 {
    let shared = shared.clone();  // Clone before moving into spawn
    tokio::spawn(async move {
        // Task owns its Arc clone
        shared.do_something(i).await;
    });
}
```

### Scope-Based Approach

```rust
// Limit borrow scope to before await
async fn scoped(data: Arc<Data>) {
    // Scope 1: borrow, compute, drop borrow
    let computed = {
        let slice = &data.items[..];  // Borrow
        compute_something(slice)       // Use
    };  // Borrow ends here
    
    // Now safe to await
    expensive_async_operation().await;
    
    use_computed(computed);
}
```

### MutexGuard Across Await

```rust
use tokio::sync::Mutex;

// BAD: holding guard across await
async fn bad(mutex: Arc<Mutex<Data>>) {
    let mut guard = mutex.lock().await;
    guard.value += 1;
    
    slow_operation().await;  // Guard held during await!
    
    guard.value += 1;
}

// GOOD: release before await
async fn good(mutex: Arc<Mutex<Data>>) {
    {
        let mut guard = mutex.lock().await;
        guard.value += 1;
    }  // Guard released
    
    slow_operation().await;
    
    {
        let mut guard = mutex.lock().await;
        guard.value += 1;
    }
}
```

Related: `async-no-lock-await`, `own-arc-shared`, `async-spawn-blocking`

## async-fn-in-trait

> Use native `async fn` in traits (stable 1.75) instead of the `async_trait` macro

### Why It Matters

Since Rust 1.75, you can write `async fn` directly inside trait definitions (AFIT — async functions in traits). This eliminates the `#[async_trait]` proc-macro dependency and removes the hidden `Box<dyn Future>` allocation it inserts on every call. Fewer allocations, no macro expansion overhead, and no extra crate to audit. However, native async fn in traits carries two precise caveats you must understand before migrating.

### Bad

```rust
// requires async_trait crate; boxes every future on the heap
use async_trait::async_trait;

#[async_trait]
trait Repo {
    async fn get(&self, id: u64) -> anyhow::Result<String>;
    async fn save(&self, value: String) -> anyhow::Result<()>;
}

struct PgRepo;

#[async_trait]
impl Repo for PgRepo {
    async fn get(&self, id: u64) -> anyhow::Result<String> {
        Ok(format!("row-{id}"))
    }

    async fn save(&self, value: String) -> anyhow::Result<()> {
        let _ = value;
        Ok(())
    }
}
```

### Good

```rust
// native async fn in traits — no macro, no boxing
trait Repo {
    async fn get(&self, id: u64) -> anyhow::Result<String>;
    async fn save(&self, value: String) -> anyhow::Result<()>;
}

struct PgRepo;

impl Repo for PgRepo {
    async fn get(&self, id: u64) -> anyhow::Result<String> {
        Ok(format!("row-{id}"))
    }

    async fn save(&self, value: String) -> anyhow::Result<()> {
        let _ = value;
        Ok(())
    }
}
```

### Caveats

**Caveat 1 — not dyn-compatible.** Native async fn in traits is not yet object-safe. You cannot write `Box<dyn Repo>` with the definition above. For dynamic dispatch you have two options:

- Keep `#[async_trait]` (it boxes the future, which makes the trait object-safe).
- Use the `trait-variant` crate's `#[trait_variant::make]` macro, which generates a boxed-future variant alongside your native async trait.

```rust
// using trait-variant to get both a static and a dyn-compatible variant
#[trait_variant::make(RepoSend: Send)]
trait Repo {
    async fn get(&self, id: u64) -> anyhow::Result<String>;
}

// `RepoSend` is the Send-bounded version; it IS dyn-compatible via boxing
fn make_repo() -> Box<dyn RepoSend> {
    // ...
    # unimplemented!()
}
```

**Caveat 2 — futures are not `Send` by default.** On a multi-threaded Tokio runtime, spawned tasks require `Send` futures. The auto-generated future from a native `async fn` in a trait captures `&self` but does not promise `Send`. If you need `Send`, either:

- Use `#[trait_variant::make(TraitNameSend: Send)]` from the `trait-variant` crate to generate a `Send`-bounded variant.
- Bound the return type explicitly: `fn get(&self, id: u64) -> impl Future<Output = anyhow::Result<String>> + Send`.

```rust
// explicit Send bound on the return future
trait Repo {
    fn get(&self, id: u64) -> impl Future<Output = anyhow::Result<String>> + Send;
}
```

### When to Use Each Approach

| Scenario | Recommended approach |
|---|---|
| Static dispatch only (generics, `impl Trait`) | Native `async fn` in trait |
| Need `dyn Trait` | `#[async_trait]` or `trait-variant` |
| Multi-threaded Tokio, spawned tasks | `trait-variant` `Send` variant or explicit `+ Send` |
| Single-threaded runtime / `LocalSet` | Native `async fn` in trait (no `Send` needed) |

Related: `anti-type-erasure`, `async-async-fn-bounds`, `async-tokio-runtime`

## async-async-fn-bounds

> Use `AsyncFn`/`AsyncFnMut`/`AsyncFnOnce` bounds instead of `F: Fn() -> Fut, Fut: Future`

### Why It Matters

The `AsyncFn`, `AsyncFnMut`, and `AsyncFnOnce` traits stabilized in Rust 1.85 (February 2025). They let you express higher-order async function bounds in a single, readable constraint — and, critically, they handle lifetime capture correctly. The old two-generic pattern `F: Fn() -> Fut, Fut: Future<Output = T>` cannot accept `async ||` closures that borrow from their environment, because the future's lifetime is not linked to the closure's call. `AsyncFn` solves this structurally.

### Bad

```rust
use std::future::Future;

// two-generic pattern: verbose, and cannot accept async closures
// that borrow from their environment across the call
async fn retry<F, Fut, T, E>(times: usize, f: F) -> Result<T, E>
where
    F: Fn() -> Fut,
    Fut: Future<Output = Result<T, E>>,
{
    let mut last_err;
    let mut i = 0;
    loop {
        match f().await {
            Ok(v) => return Ok(v),
            Err(e) => {
                last_err = e;
                i += 1;
                if i >= times {
                    return Err(last_err);
                }
            }
        }
    }
}
```

### Good

```rust
// AsyncFn bound: concise, correct lifetime semantics, accepts async closures
async fn retry<F, T, E>(times: usize, f: F) -> Result<T, E>
where
    F: AsyncFn() -> Result<T, E>,
{
    let mut last_err;
    let mut i = 0;
    loop {
        match f().await {
            Ok(v) => return Ok(v),
            Err(e) => {
                last_err = e;
                i += 1;
                if i >= times {
                    return Err(last_err);
                }
            }
        }
    }
}

// callers can pass plain async functions or async closures
async fn fetch_data() -> Result<String, std::io::Error> {
    Ok("data".to_owned())
}

async fn example() {
    // async function reference
    let _ = retry(3, fetch_data).await;

    // async closure (impossible with the old F: Fn() -> Fut pattern
    // when the closure borrows a local across calls)
    let prefix = "prefix".to_owned();
    let _ = retry(3, async || {
        Ok::<_, std::io::Error>(format!("{prefix}-data"))
    })
    .await;
}
```

### The Three Variants

| Bound | Receiver | Use when |
|---|---|---|
| `AsyncFn()` | `&self` | callable multiple times, no mutation |
| `AsyncFnMut()` | `&mut self` | callable multiple times, may mutate captured state |
| `AsyncFnOnce()` | `self` | callable exactly once, may consume captured state |

These mirror `Fn` / `FnMut` / `FnOnce` semantics, so the same rules apply: prefer `AsyncFn` first; fall back to `AsyncFnMut` or `AsyncFnOnce` when needed.

### Key Points

- `AsyncFn()` desugars the bound `F: AsyncFn<(), Output = T>` — the call syntax mirrors `Fn()`.
- Plain `async fn` items (not closures) automatically implement `AsyncFn` when their signature matches.
- `AsyncFn` is in `std::ops` but the traits are brought in scope automatically in the 2024 edition; in older editions you may need `use std::ops::AsyncFn;`.
- The compiler still infers `Send`-ness from the closure body; if you need `Send` futures (Tokio multi-threaded), add `+ Send` to the bound or use a `Send` wrapper.

Related: `async-fn-in-trait`, `async-tokio-runtime`

## async-cancel-safety

> Ensure futures used in `tokio::select!` branches are cancellation-safe

### Why It Matters

`tokio::select!` polls multiple futures concurrently and, the moment one branch completes, it **drops every other branch** — including any state those futures held. A future that was halfway through reading bytes into a local buffer, or halfway through draining a channel into a `Vec`, loses that progress silently. This is not a compiler error; it compiles fine and the bug only surfaces under concurrent load. Tokio documents which of its primitives are cancellation-safe; everything else must be treated with care.

### Bad

```rust
use tokio::io::{AsyncReadExt, BufReader};
use tokio::net::TcpStream;
use tokio::sync::mpsc;

// Non-cancel-safe: `read_exact` owns an internal buffer inside the future.
// If select! drops this branch, the partially-read bytes are gone.
async fn bad_example(stream: &mut BufReader<TcpStream>, rx: &mut mpsc::Receiver<u8>) {
    let mut buf = [0u8; 1024];
    tokio::select! {
        // BUG: if the `recv` branch fires first, the bytes already read
        // into buf inside `read_exact` are silently discarded
        result = stream.read_exact(&mut buf) => {
            println!("read {} bytes", result.unwrap());
        }
        msg = rx.recv() => {
            println!("got message: {:?}", msg);
        }
    }
}
```

### Good

```rust
use tokio::io::{AsyncReadExt, BufReader};
use tokio::net::TcpStream;
use tokio::sync::mpsc;

// Cancel-safe: the buffer lives OUTSIDE the select loop.
// If the recv branch fires, buf retains whatever was already read,
// and the next iteration continues filling it.
async fn good_example(
    stream: &mut BufReader<TcpStream>,
    rx: &mut mpsc::Receiver<u8>,
) -> std::io::Result<()> {
    let mut buf = [0u8; 1024];
    let mut filled = 0;

    loop {
        tokio::select! {
            n = stream.read(&mut buf[filled..]) => {
                // `read` (not `read_exact`) is cancel-safe: it either
                // reads some bytes or returns immediately with 0.
                filled += n?;
                if filled == buf.len() {
                    println!("buffer full: {:?}", &buf[..]);
                    filled = 0;
                }
            }
            msg = rx.recv() => {
                println!("got message: {:?}", msg);
            }
        }
    }
}
```

### What Is and Is Not Cancel-Safe

| Operation | Cancel-safe? | Notes |
|---|---|---|
| `mpsc::Receiver::recv()` | Yes | drops nothing on cancel |
| `broadcast::Receiver::recv()` | Yes | position tracked in receiver |
| `watch::Receiver::changed()` | Yes | no data consumed on cancel |
| `oneshot::Receiver` | Yes | message remains in channel |
| `tokio::time::sleep` | Yes | timer resets cleanly |
| `AsyncRead::read()` | Yes | partial reads surfaced to caller |
| `AsyncRead::read_exact()` | **No** | partially filled buffer is lost |
| `AsyncRead::read_to_end()` | **No** | accumulation is inside the future |
| `Mutex::lock()` | Yes | lock not acquired if dropped |
| collecting into a `Vec` inside a future | **No** | partial state is inside the future |

### Patterns for Non-Cancel-Safe Operations

1. **Move state outside `select!`** — keep the accumulation buffer or partial result as a local variable in the surrounding scope, not inside the future passed to `select!`.

2. **Use a pinned future held across iterations** — pin the future once and reuse it:

```rust
use std::pin::pin;
use tokio::io::AsyncReadExt;

async fn pinned_read_example<R: AsyncReadExt + Unpin>(mut reader: R) {
    let mut buf = vec![0u8; 64];
    // pin the future so it survives across select iterations
    let read_fut = pin!(reader.read_to_end(&mut buf));
    // ... use read_fut inside select! across multiple iterations
    // When the future completes it won't be cancelled mid-way
    let _ = read_fut.await;
}
```

3. **Use `tokio_util::io::poll_read_buf`** or similar cancel-safe adapters from `tokio-util`.

4. **Wrap in a `JoinHandle`** — spawn the operation as a task; the task keeps running even if `select!` drops the handle, and the handle itself is cancel-safe.

Related: `async-select-racing`, `async-bounded-channel`, `async-no-lock-await`
