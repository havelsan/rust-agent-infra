---
name: rust-12-async-1of4
description: Rust rules module 12: Async/Await (part 1 of 4). 5 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `async-`
---

# Async/Await (part 1/4)

Priority: HIGH. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `async-tokio-runtime` - Configure Tokio runtime appropriately for your workload
- `async-no-lock-await` - Never hold `Mutex`/`RwLock` across `.await`
- `async-spawn-blocking` - Use `spawn_blocking` for CPU-intensive work
- `async-tokio-fs` - Use `tokio::fs` instead of `std::fs` in async code
- `async-cancellation-token` - Use `CancellationToken` for graceful shutdown and task cancellation

---

## async-tokio-runtime

> Configure Tokio runtime appropriately for your workload

### Why It Matters

Tokio's default multi-threaded runtime isn't always optimal. CPU-bound work needs different configuration than IO-bound work. Incorrect configuration leads to poor performance, blocked workers, or resource exhaustion. Understanding runtime options lets you tune for your specific use case.

### Bad

```rust
// Default runtime for everything - not optimal
#[tokio::main]
async fn main() {
    // CPU-heavy work on async executor starves IO tasks
    for data in datasets {
        let result = heavy_computation(data).await;
    }
}

// Single-threaded when multi-threaded is needed
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Can't utilize multiple cores for concurrent tasks
    for _ in 0..1000 {
        tokio::spawn(async { /* IO work */ });
    }
}
```

### Good

```rust
// Multi-threaded for concurrent IO (default)
#[tokio::main]
async fn main() {
    // Good for many concurrent network connections
    let handles: Vec<_> = urls.iter()
        .map(|url| tokio::spawn(fetch(url.clone())))
        .collect();
    
    futures::future::join_all(handles).await;
}

// Current-thread for single-threaded scenarios
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Good for single-connection clients, simpler debugging
    let client = Client::new();
    client.run().await;
}

// Custom configuration
#[tokio::main(worker_threads = 4)]
async fn main() {
    // Limit to 4 worker threads
}

// Or manual setup for more control
fn main() {
    let runtime = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .thread_name("my-worker")
        .build()
        .unwrap();
    
    runtime.block_on(async_main());
}
```

### Runtime Types

| Runtime | Use Case | Configuration |
|---------|----------|---------------|
| Multi-thread | IO-bound, many connections | `#[tokio::main]` (default) |
| Current-thread | CLI tools, tests, single connection | `flavor = "current_thread"` |
| Custom | Fine-tuned performance | `Builder::new_*()` |

### Worker Thread Tuning

```rust
use tokio::runtime::Builder;

// std::thread::available_parallelism() is stable since Rust 1.59
// and respects cgroup CPU quotas (unlike the unmaintained num_cpus crate)
let parallelism = std::thread::available_parallelism()
    .map(|n| n.get())
    .unwrap_or(1);

// IO-bound: more threads than cores can help
let io_runtime = Builder::new_multi_thread()
    .worker_threads(parallelism * 2)  // IO can benefit from oversubscription
    .max_blocking_threads(32)         // For spawn_blocking calls
    .enable_io()
    .enable_time()
    .build()?;

// CPU-bound: match core count
let cpu_runtime = Builder::new_multi_thread()
    .worker_threads(parallelism)      // No benefit from more than cores
    .build()?;
```

### Multiple Runtimes

```rust
// Separate runtimes for different workloads
struct App {
    io_runtime: Runtime,
    cpu_runtime: Runtime,
}

impl App {
    fn new() -> Self {
        Self {
            io_runtime: Builder::new_multi_thread()
                .worker_threads(8)
                .thread_name("io-worker")
                .build()
                .unwrap(),
            cpu_runtime: Builder::new_multi_thread()
                .worker_threads(4)
                .thread_name("cpu-worker")
                .build()
                .unwrap(),
        }
    }
    
    fn spawn_io<F>(&self, future: F) 
    where F: Future + Send + 'static, F::Output: Send + 'static 
    {
        self.io_runtime.spawn(future);
    }
    
    fn spawn_cpu<F>(&self, task: F) 
    where F: FnOnce() + Send + 'static 
    {
        self.cpu_runtime.spawn_blocking(task);
    }
}
```

### Runtime in Tests

```rust
// Single test runtime
#[tokio::test]
async fn test_single() {
    assert!(true);
}

// Multi-threaded test
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_concurrent() {
    let (tx, rx) = tokio::sync::oneshot::channel();
    tokio::spawn(async move { tx.send(42).unwrap() });
    assert_eq!(rx.await.unwrap(), 42);
}

// Custom runtime in test
#[test]
fn test_with_custom_runtime() {
    let rt = Builder::new_current_thread().build().unwrap();
    rt.block_on(async {
        // test code
    });
}
```

Related: `async-spawn-blocking`, `async-no-lock-await`, `async-joinset-structured`

## async-no-lock-await

> Never hold `Mutex`/`RwLock` across `.await`

### Why It Matters

Holding a lock across an `.await` point can cause deadlocks and severely hurt performance. The task may be suspended while holding the lock, blocking all other tasks waiting for it - potentially indefinitely.

### Bad

```rust
use tokio::sync::Mutex;

async fn bad_update(state: &Mutex<State>) {
    let mut guard = state.lock().await;
    
    // BAD: Lock held across await!
    let data = fetch_from_network().await;
    
    guard.value = data;
}  // Lock finally released

// This can deadlock or starve other tasks
```

### Good

```rust
use tokio::sync::Mutex;

async fn good_update(state: &Mutex<State>) {
    // Fetch data BEFORE taking the lock
    let data = fetch_from_network().await;
    
    // Lock only for the quick update
    let mut guard = state.lock().await;
    guard.value = data;
}  // Lock released immediately

// Alternative: Clone data out, process, then update
async fn good_update_v2(state: &Mutex<State>) {
    // Extract what we need
    let id = {
        let guard = state.lock().await;
        guard.id.clone()
    };  // Lock released!
    
    // Do async work without lock
    let data = fetch_by_id(id).await;
    
    // Quick update
    state.lock().await.value = data;
}
```

### The Problem Visualized

```rust
// Task A:
let guard = mutex.lock().await;    // Acquires lock
expensive_io().await;              // Suspended, still holding lock!
// ... many milliseconds pass ...
drop(guard);                       // Finally releases

// Task B, C, D:
let guard = mutex.lock().await;    // All blocked waiting for A!
```

### Patterns for Extraction

```rust
use tokio::sync::Mutex;

// Pattern 1: Clone out, process, update
async fn pattern_clone(state: &Mutex<State>) {
    let config = state.lock().await.config.clone();
    let result = process_with_io(&config).await;
    state.lock().await.result = result;
}

// Pattern 2: Compute closure, apply
async fn pattern_closure(state: &Mutex<State>) {
    let update = compute_update().await;
    
    state.lock().await.apply(update);
}

// Pattern 3: Message passing
async fn pattern_message(
    state: &Mutex<State>,
    tx: mpsc::Sender<Update>,
) {
    let update = compute_update().await;
    tx.send(update).await.unwrap();
}

// Separate task handles updates
async fn state_manager(
    state: Arc<Mutex<State>>,
    mut rx: mpsc::Receiver<Update>,
) {
    while let Some(update) = rx.recv().await {
        state.lock().await.apply(update);
    }
}
```

### Using RwLock

```rust
use tokio::sync::RwLock;

async fn read_heavy(state: &RwLock<State>) {
    // Multiple readers OK, but still don't hold across await
    let value = {
        let guard = state.read().await;
        guard.value.clone()
    };
    
    // Process without lock
    let result = process(value).await;
    
    // Write lock for update
    state.write().await.result = result;
}
```

### std::sync::Mutex vs tokio::sync::Mutex

```rust
// Prefer std::sync::Mutex for work that does NOT span an .await —
// it is simpler, faster, and avoids the async overhead.
// Only reach for tokio::sync::Mutex when you genuinely must hold
// the lock across an .await point (rare; usually a sign to redesign).

// std::sync::Mutex in async (quick, non-awaiting operation — preferred):
async fn quick_update(state: &std::sync::Mutex<State>) {
    state.lock().unwrap().counter += 1;  // No await inside lock scope, OK
}

// tokio::sync::Mutex (only when the lock scope must span an .await):
async fn must_await_inside(state: &tokio::sync::Mutex<State>) {
    let mut guard = state.lock().await;
    // Only justified if you truly need the lock held across an async op
    // (usually you don't — extract data first, then release the lock)
}
```

Related: `async-spawn-blocking`, `async-clone-before-await`, `anti-lock-across-await`

## async-spawn-blocking

> Use `spawn_blocking` for CPU-intensive work

### Why It Matters

Async runtimes like Tokio use a small number of threads to handle many tasks. CPU-intensive or blocking operations on these threads starve other tasks. `spawn_blocking` moves such work to a dedicated thread pool.

### Bad

```rust
// BAD: Blocks the async runtime thread
async fn process_image(data: &[u8]) -> ProcessedImage {
    // CPU-intensive work on async thread!
    let resized = resize_image(data);      // Blocks!
    let compressed = compress(resized);     // Blocks!
    compressed
}

// BAD: Synchronous file I/O in async context
async fn read_large_file(path: &Path) -> Vec<u8> {
    std::fs::read(path).unwrap()  // Blocks the runtime!
}
```

### Good

```rust
use tokio::task;

// GOOD: Offload CPU work to blocking pool
async fn process_image(data: Vec<u8>) -> ProcessedImage {
    task::spawn_blocking(move || {
        let resized = resize_image(&data);
        compress(resized)
    })
    .await
    .expect("spawn_blocking failed")
}

// GOOD: Use async file I/O
async fn read_large_file(path: &Path) -> tokio::io::Result<Vec<u8>> {
    tokio::fs::read(path).await
}

// GOOD: Or spawn_blocking for unavoidable sync I/O
async fn read_with_sync_lib(path: PathBuf) -> Vec<u8> {
    task::spawn_blocking(move || {
        sync_library::read_file(&path)
    })
    .await
    .unwrap()
}
```

### What Counts as Blocking

```rust
// CPU-intensive operations
- Cryptographic operations (hashing, encryption)
- Image/video processing
- Compression/decompression
- Complex parsing
- Mathematical computations

// Blocking I/O
- std::fs operations
- Synchronous database drivers
- Synchronous HTTP clients
- Thread::sleep

// Example thresholds (rough guidelines):
// < 10µs: OK on async thread
// 10µs - 1ms: Consider spawn_blocking
// > 1ms: Definitely spawn_blocking
```

### Practical Examples

```rust
// Password hashing (CPU-intensive)
async fn hash_password(password: String) -> String {
    task::spawn_blocking(move || {
        bcrypt::hash(password, bcrypt::DEFAULT_COST).unwrap()
    })
    .await
    .unwrap()
}

// JSON parsing of large documents
async fn parse_large_json(data: String) -> serde_json::Value {
    task::spawn_blocking(move || {
        serde_json::from_str(&data).unwrap()
    })
    .await
    .unwrap()
}

// Compression
async fn compress_data(data: Vec<u8>) -> Vec<u8> {
    task::spawn_blocking(move || {
        let mut encoder = flate2::write::GzEncoder::new(
            Vec::new(),
            flate2::Compression::default(),
        );
        encoder.write_all(&data).unwrap();
        encoder.finish().unwrap()
    })
    .await
    .unwrap()
}
```

### spawn_blocking vs spawn

```rust
// spawn: Runs async code on runtime threads
tokio::spawn(async {
    // Async code here
    some_async_operation().await;
});

// spawn_blocking: Runs sync code on blocking thread pool
tokio::task::spawn_blocking(|| {
    // Synchronous, possibly CPU-intensive code
    heavy_computation();
});

// spawn_blocking returns JoinHandle that can be awaited
let result = tokio::task::spawn_blocking(|| {
    expensive_sync_operation()
}).await?;
```

### Rayon for Parallel CPU Work

```rust
// For parallel CPU work, consider Rayon inside spawn_blocking
async fn parallel_process(items: Vec<Item>) -> Vec<Output> {
    task::spawn_blocking(move || {
        use rayon::prelude::*;
        items.par_iter()
            .map(|item| cpu_intensive_transform(item))
            .collect()
    })
    .await
    .unwrap()
}
```

Related: `async-tokio-fs`, `async-no-lock-await`

## async-tokio-fs

> Use `tokio::fs` instead of `std::fs` in async code

### Why It Matters

`std::fs` operations are blocking—they stop the current thread until the syscall completes. In async code, this blocks the executor thread, preventing it from running other tasks. `tokio::fs` wraps filesystem operations in `spawn_blocking`, keeping the executor responsive.

### Bad

```rust
async fn process_files(paths: &[PathBuf]) -> Result<Vec<String>> {
    let mut contents = Vec::new();
    
    for path in paths {
        // BLOCKS the entire executor thread!
        let data = std::fs::read_to_string(path)?;
        contents.push(data);
    }
    
    Ok(contents)
}

// While reading a file, NO other tasks can run on this thread
```

### Good

```rust
use tokio::fs;

async fn process_files(paths: &[PathBuf]) -> Result<Vec<String>> {
    let mut contents = Vec::new();
    
    for path in paths {
        // Non-blocking: allows other tasks to run
        let data = fs::read_to_string(path).await?;
        contents.push(data);
    }
    
    Ok(contents)
}

// Even better: concurrent reads
async fn process_files_concurrent(paths: &[PathBuf]) -> Result<Vec<String>> {
    let futures: Vec<_> = paths.iter()
        .map(|path| fs::read_to_string(path))
        .collect();
    
    futures::future::try_join_all(futures).await
}
```

### tokio::fs API

```rust
use tokio::fs;

// Reading
let contents = fs::read_to_string("file.txt").await?;
let bytes = fs::read("file.bin").await?;

// Writing
fs::write("output.txt", "contents").await?;

// File operations
let file = fs::File::open("file.txt").await?;
let file = fs::File::create("new.txt").await?;

// Directory operations
fs::create_dir("new_dir").await?;
fs::create_dir_all("nested/dir/path").await?;
fs::remove_dir("empty_dir").await?;
fs::remove_dir_all("dir_with_contents").await?;

// Metadata
let metadata = fs::metadata("file.txt").await?;
let canonical = fs::canonicalize("./relative").await?;

// Rename/remove
fs::rename("old.txt", "new.txt").await?;
fs::remove_file("file.txt").await?;

// Read directory
let mut entries = fs::read_dir("some_dir").await?;
while let Some(entry) = entries.next_entry().await? {
    println!("{}", entry.path().display());
}
```

### Async File I/O

```rust
use tokio::fs::File;
use tokio::io::{AsyncReadExt, AsyncWriteExt, AsyncBufReadExt, BufReader};

// Read with buffer
let mut file = File::open("large.bin").await?;
let mut buffer = vec![0u8; 4096];
let bytes_read = file.read(&mut buffer).await?;

// Read all
let mut contents = Vec::new();
file.read_to_end(&mut contents).await?;

// Write
let mut file = File::create("output.bin").await?;
file.write_all(b"data").await?;
file.flush().await?;

// Buffered line reading
let file = File::open("lines.txt").await?;
let reader = BufReader::new(file);
let mut lines = reader.lines();

while let Some(line) = lines.next_line().await? {
    println!("{}", line);
}
```

### When std::fs is Acceptable

```rust
// Startup/initialization (before async runtime)
fn main() {
    let config = std::fs::read_to_string("config.toml")
        .expect("config file required");
    
    tokio::runtime::Runtime::new()
        .unwrap()
        .block_on(run_with_config(config));
}

// Single-threaded current_thread runtime (less impact)
#[tokio::main(flavor = "current_thread")]
async fn main() {
    // Still prefer tokio::fs, but impact is lower
}

// When file operations are rare and quick
// (e.g., reading small config once per hour)
```

### Performance Considerations

```rust
// tokio::fs uses spawn_blocking internally
// For many small files, the overhead adds up

// Batch operations when possible
let paths: Vec<_> = entries.iter()
    .map(|e| e.path())
    .collect();

let contents = futures::future::try_join_all(
    paths.iter().map(|p| fs::read_to_string(p))
).await?;

// For heavy I/O, consider memory-mapped files
// (requires unsafe or mmap crate)
```

Related: `async-spawn-blocking`, `async-tokio-runtime`, `err-context-chain`

## async-cancellation-token

> Use `CancellationToken` for graceful shutdown and task cancellation

### Why It Matters

Dropping a `JoinHandle` doesn't cancel the task—it just detaches it. For graceful shutdown, you need explicit cancellation. `tokio_util::sync::CancellationToken` provides a cooperative cancellation mechanism that tasks can check and respond to, enabling clean resource cleanup.

### Bad

```rust
// Dropping handle doesn't stop the task
let handle = tokio::spawn(async {
    loop {
        do_work().await;
    }
});

drop(handle);  // Task continues running in background!

// Using bool flag - not async-aware
let running = Arc::new(AtomicBool::new(true));

tokio::spawn({
    let running = running.clone();
    async move {
        while running.load(Ordering::Relaxed) {
            do_work().await;  // Can't wake up if blocked here
        }
    }
});

running.store(false, Ordering::Relaxed);
// Task won't stop until current do_work() completes
```

### Good

```rust
use tokio_util::sync::CancellationToken;

let token = CancellationToken::new();

let handle = tokio::spawn({
    let token = token.clone();
    async move {
        loop {
            tokio::select! {
                _ = token.cancelled() => {
                    println!("Shutting down gracefully");
                    cleanup().await;
                    break;
                }
                _ = do_work() => {
                    // Work completed
                }
            }
        }
    }
});

// Later: trigger cancellation
token.cancel();
handle.await?;  // Task completes cleanly
```

### CancellationToken API

```rust
use tokio_util::sync::CancellationToken;

// Create token
let token = CancellationToken::new();

// Clone for sharing (cheap Arc-based clone)
let token2 = token.clone();

// Check if cancelled (non-blocking)
if token.is_cancelled() {
    return;
}

// Wait for cancellation (async)
token.cancelled().await;

// Trigger cancellation
token.cancel();

// Child tokens - cancelled when parent is cancelled
let child = token.child_token();
```

### Hierarchical Cancellation

```rust
async fn run_server(shutdown: CancellationToken) {
    let listener = TcpListener::bind("0.0.0.0:8080").await?;
    
    loop {
        tokio::select! {
            _ = shutdown.cancelled() => {
                println!("Server shutting down");
                break;
            }
            result = listener.accept() => {
                let (socket, _) = result?;
                // Each connection gets child token
                let conn_token = shutdown.child_token();
                tokio::spawn(handle_connection(socket, conn_token));
            }
        }
    }
    
    // Child tokens auto-cancelled when we exit
}

async fn handle_connection(socket: TcpStream, token: CancellationToken) {
    loop {
        tokio::select! {
            _ = token.cancelled() => {
                // Connection cleanup
                break;
            }
            data = socket.read() => {
                // Handle data
            }
        }
    }
}
```

### Graceful Shutdown Pattern

```rust
use tokio::signal;

async fn main() -> Result<()> {
    let shutdown = CancellationToken::new();
    
    // Spawn signal handler
    let shutdown_trigger = shutdown.clone();
    tokio::spawn(async move {
        signal::ctrl_c().await.expect("failed to listen for Ctrl+C");
        println!("Received Ctrl+C, initiating shutdown...");
        shutdown_trigger.cancel();
    });
    
    // Run application with shutdown token
    run_app(shutdown).await
}

async fn run_app(shutdown: CancellationToken) -> Result<()> {
    let mut tasks = JoinSet::new();
    
    tasks.spawn(worker_task(shutdown.child_token()));
    tasks.spawn(server_task(shutdown.child_token()));
    
    // Wait for shutdown or task completion
    tokio::select! {
        _ = shutdown.cancelled() => {
            println!("Shutdown requested, waiting for tasks...");
        }
        Some(result) = tasks.join_next() => {
            // A task completed/failed
            result??;
        }
    }
    
    // Wait for remaining tasks with timeout
    tokio::time::timeout(
        Duration::from_secs(30),
        async { while tasks.join_next().await.is_some() {} }
    ).await.ok();
    
    Ok(())
}
```

### DropGuard Pattern

```rust
use tokio_util::sync::CancellationToken;

// Auto-cancel on drop
let token = CancellationToken::new();
let guard = token.clone().drop_guard();

tokio::spawn({
    let token = token.clone();
    async move {
        token.cancelled().await;
        println!("Cancelled!");
    }
});

drop(guard);  // Automatically calls token.cancel()
```

Related: `async-joinset-structured`, `async-select-racing`, `async-tokio-runtime`
