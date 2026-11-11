---
name: rust-13-async-2of4
description: Rust rules module 13: Async/Await (part 2 of 4). 4 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `async-`
---

# Async/Await (part 2/4)

Priority: HIGH. 4 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `async-join-parallel` - Use `join!` or `try_join!` for concurrent independent futures
- `async-try-join` - Use `try_join!` for concurrent fallible operations with early return on error
- `async-select-racing` - Use `select!` to race futures and handle the first to complete
- `async-bounded-channel` - Use bounded channels to apply backpressure and prevent unbounded memory growth

---

## async-join-parallel

> Use `join!` or `try_join!` for concurrent independent futures

### Why It Matters

Awaiting futures sequentially takes the sum of their durations. `join!` runs futures concurrently, taking only as long as the slowest one. For independent operations like multiple API calls or parallel file reads, this can dramatically reduce latency.

### Bad

```rust
async fn fetch_data() -> (User, Posts, Comments) {
    // Sequential: 300ms total (100 + 100 + 100)
    let user = fetch_user().await;        // 100ms
    let posts = fetch_posts().await;      // 100ms  
    let comments = fetch_comments().await; // 100ms
    
    (user, posts, comments)
}

async fn read_configs() -> Result<(Config, Settings)> {
    // Sequential: 20ms + 20ms = 40ms
    let config = fs::read_to_string("config.toml").await?;
    let settings = fs::read_to_string("settings.json").await?;
    
    Ok((parse_config(&config)?, parse_settings(&settings)?))
}
```

### Good

```rust
use tokio::join;

async fn fetch_data() -> (User, Posts, Comments) {
    // Concurrent: ~100ms total (max of all three)
    let (user, posts, comments) = join!(
        fetch_user(),
        fetch_posts(),
        fetch_comments(),
    );
    
    (user, posts, comments)
}

use tokio::try_join;

async fn read_configs() -> Result<(Config, Settings)> {
    // Concurrent: ~20ms total
    let (config_str, settings_str) = try_join!(
        fs::read_to_string("config.toml"),
        fs::read_to_string("settings.json"),
    )?;
    
    Ok((parse_config(&config_str)?, parse_settings(&settings_str)?))
}
```

### join! vs try_join!

```rust
// join! - all futures run to completion, returns tuple
let (a, b, c) = join!(future_a, future_b, future_c);

// try_join! - short-circuits on first error
let (a, b, c) = try_join!(fallible_a, fallible_b, fallible_c)?;
// If fallible_b fails, returns Err immediately
// Other futures may still be running (cancellation is async)
```

### futures::join_all for Dynamic Collections

```rust
use futures::future::join_all;

async fn fetch_all_users(ids: &[u64]) -> Vec<User> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    join_all(futures).await
}

// With fallible futures
use futures::future::try_join_all;

async fn fetch_all_users(ids: &[u64]) -> Result<Vec<User>> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    try_join_all(futures).await
}
```

### Limiting Concurrency

```rust
use futures::stream::{self, StreamExt};

async fn fetch_with_limit(ids: &[u64]) -> Vec<Result<User>> {
    stream::iter(ids)
        .map(|id| fetch_user(*id))
        .buffer_unordered(10)  // Max 10 concurrent requests
        .collect()
        .await
}

// Or with tokio::sync::Semaphore
use tokio::sync::Semaphore;

async fn fetch_with_semaphore(ids: &[u64]) -> Vec<User> {
    let semaphore = Arc::new(Semaphore::new(10));
    
    let futures: Vec<_> = ids.iter().map(|id| {
        let semaphore = semaphore.clone();
        async move {
            let _permit = semaphore.acquire().await.unwrap();
            fetch_user(*id).await
        }
    }).collect();
    
    join_all(futures).await
}
```

### When NOT to Use join!

```rust
// ❌ Dependent futures - must be sequential
async fn create_and_populate() -> Result<()> {
    let db = create_database().await?;   // Must complete first
    populate_tables(&db).await?;          // Depends on db
    Ok(())
}

// ❌ Short-circuiting logic
async fn find_first() -> Option<Data> {
    // Want to stop when one succeeds
    // Use select! instead
}

// ❌ Shared mutable state
async fn bad_shared_state() {
    let counter = Arc::new(Mutex::new(0));
    // This might work but can cause contention
    join!(
        increment(counter.clone()),
        increment(counter.clone()),
    );
}
```

Related: `async-try-join`, `async-select-racing`, `async-joinset-structured`

## async-try-join

> Use `try_join!` for concurrent fallible operations with early return on error

### Why It Matters

When running multiple fallible operations concurrently, `try_join!` returns `Err` as soon as any future fails, without waiting for the others. This provides fail-fast behavior while still running operations in parallel. For many operations, use `futures::future::try_join_all`.

### Bad

```rust
// Sequential - slow and no early return benefit
async fn fetch_all() -> Result<(A, B, C)> {
    let a = fetch_a().await?;  // If this fails, we wait for nothing
    let b = fetch_b().await?;  // But if this fails, we waited for A
    let c = fetch_c().await?;
    Ok((a, b, c))
}

// join! ignores errors
async fn fetch_all() -> (Result<A>, Result<B>, Result<C>) {
    let (a, b, c) = join!(fetch_a(), fetch_b(), fetch_c());
    // All complete even if first one failed
    (a, b, c)  // Now we have to handle three Results
}
```

### Good

```rust
use tokio::try_join;

async fn fetch_all() -> Result<(A, B, C)> {
    // Concurrent AND fail-fast
    let (a, b, c) = try_join!(
        fetch_a(),
        fetch_b(),
        fetch_c(),
    )?;
    
    Ok((a, b, c))
}

// For dynamic collections
use futures::future::try_join_all;

async fn fetch_users(ids: &[u64]) -> Result<Vec<User>> {
    let futures: Vec<_> = ids.iter()
        .map(|id| fetch_user(*id))
        .collect();
    
    try_join_all(futures).await
}
```

### Error Handling Patterns

```rust
// Different error types - need common error type
async fn mixed_operations() -> Result<(A, B), Error> {
    let (a, b) = try_join!(
        fetch_a().map_err(Error::from),  // Convert errors
        fetch_b().map_err(Error::from),
    )?;
    Ok((a, b))
}

// Collect all results, then handle errors
async fn all_or_nothing(ids: &[u64]) -> Result<Vec<User>> {
    try_join_all(ids.iter().map(|id| fetch_user(*id))).await
}

// Collect successes, log failures
async fn best_effort(ids: &[u64]) -> Vec<User> {
    let results = futures::future::join_all(
        ids.iter().map(|id| fetch_user(*id))
    ).await;
    
    results.into_iter()
        .filter_map(|r| match r {
            Ok(user) => Some(user),
            Err(e) => {
                log::warn!("Failed to fetch user: {}", e);
                None
            }
        })
        .collect()
}
```

### Cancellation Behavior

```rust
// try_join! cancels remaining futures on error
async fn with_cancellation() -> Result<()> {
    // If fetch_a() fails, fetch_b() and fetch_c() are dropped
    // But "dropped" != "immediately stopped"
    // They stop at their next .await point
    
    try_join!(
        async {
            fetch_a().await?;
            cleanup_a().await;  // May not run if other future fails
            Ok::<_, Error>(())
        },
        async {
            fetch_b().await?;
            cleanup_b().await;  // May not run if other future fails
            Ok::<_, Error>(())
        },
    )?;
    
    Ok(())
}

// For guaranteed cleanup, use Drop guards or explicit handling
```

### With Timeout

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout() -> Result<(A, B)> {
    timeout(
        Duration::from_secs(10),
        try_join!(fetch_a(), fetch_b())
    )
    .await
    .map_err(|_| Error::Timeout)?
}

// Per-operation timeout
async fn individual_timeouts() -> Result<(A, B)> {
    try_join!(
        timeout(Duration::from_secs(5), fetch_a())
            .map_err(|_| Error::Timeout)
            .and_then(|r| async { r }),
        timeout(Duration::from_secs(5), fetch_b())
            .map_err(|_| Error::Timeout)
            .and_then(|r| async { r }),
    )
}
```

### try_join! vs FuturesUnordered

```rust
use futures::stream::{FuturesUnordered, StreamExt};

// try_join!: wait for all, fail fast
let (a, b, c) = try_join!(fa, fb, fc)?;

// FuturesUnordered: process as they complete
let mut futures = FuturesUnordered::new();
futures.push(fetch_a());
futures.push(fetch_b());
futures.push(fetch_c());

while let Some(result) = futures.next().await {
    match result {
        Ok(data) => process(data),
        Err(e) => return Err(e),  // Can fail fast manually
    }
}
```

Related: `async-join-parallel`, `async-select-racing`, `err-question-mark`

## async-select-racing

> Use `select!` to race futures and handle the first to complete

### Why It Matters

Sometimes you need the first result from multiple futures—timeout vs operation, cancellation vs work, or competing alternatives. `tokio::select!` lets you race futures and handle whichever completes first, while properly cancelling the others.

### Bad

```rust
// Can't express "whichever finishes first"
async fn fetch_with_fallback() -> Data {
    match fetch_primary().await {
        Ok(data) => data,
        Err(_) => fetch_fallback().await.unwrap(),  // Sequential, not racing
    }
}

// Manual timeout is error-prone
async fn fetch_with_timeout() -> Option<Data> {
    let start = Instant::now();
    loop {
        if start.elapsed() > Duration::from_secs(5) {
            return None;
        }
        // How do we check timeout while awaiting?
    }
}
```

### Good

```rust
use tokio::select;

async fn fetch_with_timeout() -> Result<Data, Error> {
    select! {
        result = fetch_data() => result,
        _ = tokio::time::sleep(Duration::from_secs(5)) => {
            Err(Error::Timeout)
        }
    }
}

async fn fetch_with_fallback() -> Data {
    select! {
        result = fetch_primary() => {
            match result {
                Ok(data) => data,
                Err(_) => fetch_fallback().await.unwrap()
            }
        }
        _ = tokio::time::sleep(Duration::from_secs(1)) => {
            // Primary too slow, use fallback
            fetch_fallback().await.unwrap()
        }
    }
}
```

### select! Syntax

```rust
select! {
    // Pattern = future => handler
    result = async_operation() => {
        // Handle result
        println!("Got: {:?}", result);
    }
    
    // Can bind with pattern matching
    Ok(data) = fallible_operation() => {
        process(data);
    }
    
    // Conditional branches with if guards
    msg = channel.recv(), if should_receive => {
        handle_message(msg);
    }
    
    // else branch for when all futures are disabled
    else => {
        println!("All branches disabled");
    }
}
```

### Cancellation Behavior

```rust
async fn select_example() {
    select! {
        _ = operation_a() => {
            println!("A completed first");
            // operation_b() is dropped/cancelled
        }
        _ = operation_b() => {
            println!("B completed first");
            // operation_a() is dropped/cancelled
        }
    }
}

// Futures are cancelled at their next .await point
// For immediate cancellation, futures must be cancel-safe
```

### Biased Selection

```rust
// By default, select! randomly picks when multiple are ready
// Use biased mode for deterministic priority
select! {
    biased;  // Check branches in order
    
    msg = high_priority.recv() => handle_high(msg),
    msg = low_priority.recv() => handle_low(msg),
}

// Without biased, both channels have equal chance
// when both have messages ready
```

### Loop with select!

```rust
async fn event_loop(
    mut commands: mpsc::Receiver<Command>,
    shutdown: CancellationToken,
) {
    loop {
        select! {
            _ = shutdown.cancelled() => {
                println!("Shutting down");
                break;
            }
            Some(cmd) = commands.recv() => {
                process_command(cmd).await;
            }
            else => {
                // commands channel closed
                break;
            }
        }
    }
}
```

### Racing Multiple of Same Type

```rust
// Race multiple servers for fastest response
async fn fastest_response(servers: &[String]) -> Result<Response> {
    let futures = servers.iter()
        .map(|s| fetch_from(s))
        .collect::<Vec<_>>();
    
    // select! requires static branches, use select_all for dynamic
    let (result, _index, _remaining) = 
        futures::future::select_all(futures).await;
    
    result
}
```

### Common Patterns

```rust
// Timeout
select! {
    result = operation() => result,
    _ = sleep(Duration::from_secs(5)) => Err(Timeout),
}

// Cancellation
select! {
    result = operation() => result,
    _ = cancel_token.cancelled() => Err(Cancelled),
}

// Interval with cancellation
let mut interval = tokio::time::interval(Duration::from_secs(1));
loop {
    select! {
        _ = shutdown.cancelled() => break,
        _ = interval.tick() => {
            do_periodic_work().await;
        }
    }
}
```

Related: `async-cancellation-token`, `async-join-parallel`, `async-bounded-channel`

## async-bounded-channel

> Use bounded channels to apply backpressure and prevent unbounded memory growth

### Why It Matters

Unbounded channels grow without limit when producers outpace consumers. In production, this leads to memory exhaustion. Bounded channels apply backpressure—producers wait when the channel is full, naturally throttling the system. This prevents OOM and makes resource usage predictable.

### Bad

```rust
use tokio::sync::mpsc;

// Unbounded channel - can grow forever
let (tx, mut rx) = mpsc::unbounded_channel::<Message>();

// Fast producer, slow consumer = unbounded memory growth
tokio::spawn(async move {
    loop {
        let msg = generate_message();
        tx.send(msg).unwrap();  // Never blocks, never fails (until OOM)
    }
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        slow_process(msg).await;  // Can't keep up
    }
});
// Memory grows unboundedly until crash
```

### Good

```rust
use tokio::sync::mpsc;

// Bounded channel - backpressure when full
let (tx, mut rx) = mpsc::channel::<Message>(100);  // Max 100 items

// Producer waits when channel full
tokio::spawn(async move {
    loop {
        let msg = generate_message();
        // Blocks if channel is full - natural backpressure
        tx.send(msg).await.unwrap();
    }
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        slow_process(msg).await;
    }
});
// Memory usage capped at ~100 messages
```

### Choosing Buffer Size

```rust
// Too small: frequent blocking, reduced throughput
let (tx, rx) = mpsc::channel::<Item>(1);

// Too large: delayed backpressure, memory waste
let (tx, rx) = mpsc::channel::<Item>(1_000_000);

// Guidelines:
// - Start with expected burst size
// - Measure actual usage in production
// - Err on the smaller side initially

// Small items, high throughput
let (tx, rx) = mpsc::channel::<u64>(1000);

// Large items, moderate throughput  
let (tx, rx) = mpsc::channel::<LargeStruct>(100);

// Low latency requirement
let (tx, rx) = mpsc::channel::<Command>(10);
```

### Handling Full Channel

```rust
use tokio::sync::mpsc;
use tokio::time::{timeout, Duration};

let (tx, mut rx) = mpsc::channel::<Message>(100);

// Option 1: Wait indefinitely (default)
tx.send(msg).await?;

// Option 2: Try send, fail if full
match tx.try_send(msg) {
    Ok(()) => println!("Sent"),
    Err(TrySendError::Full(msg)) => {
        println!("Channel full, dropping message");
    }
    Err(TrySendError::Closed(msg)) => {
        println!("Receiver dropped");
    }
}

// Option 3: Timeout
match timeout(Duration::from_secs(1), tx.send(msg)).await {
    Ok(Ok(())) => println!("Sent"),
    Ok(Err(_)) => println!("Channel closed"),
    Err(_) => println!("Timeout - channel full for too long"),
}

// Option 4: send with permit reservation
let permit = tx.reserve().await?;
permit.send(msg);  // Guaranteed to succeed
```

### Channel Types

```rust
// mpsc: many producers, single consumer
let (tx, rx) = mpsc::channel::<Message>(100);
let tx2 = tx.clone();  // Can clone sender

// oneshot: single value, one producer, one consumer
let (tx, rx) = oneshot::channel::<Response>();
tx.send(response);  // Can only send once

// broadcast: multiple consumers, each gets all messages
let (tx, _) = broadcast::channel::<Event>(100);
let mut rx1 = tx.subscribe();
let mut rx2 = tx.subscribe();

// watch: single latest value, multiple consumers
let (tx, rx) = watch::channel::<State>(initial);
// Receivers see latest value, not all values
```

### Worker Pool Pattern

```rust
async fn process_with_workers(items: Vec<Item>) -> Vec<Result> {
    let (tx, rx) = mpsc::channel(100);
    let rx = Arc::new(Mutex::new(rx));
    
    // Spawn worker pool
    let workers: Vec<_> = (0..4).map(|_| {
        let rx = rx.clone();
        tokio::spawn(async move {
            loop {
                let item = {
                    let mut rx = rx.lock().await;
                    rx.recv().await
                };
                match item {
                    Some(item) => process(item).await,
                    None => break,
                }
            }
        })
    }).collect();
    
    // Send items
    for item in items {
        tx.send(item).await.unwrap();
    }
    drop(tx);  // Signal workers to stop
    
    futures::future::join_all(workers).await;
}
```

Related: `async-mpsc-queue`, `async-oneshot-response`, `async-watch-latest`
