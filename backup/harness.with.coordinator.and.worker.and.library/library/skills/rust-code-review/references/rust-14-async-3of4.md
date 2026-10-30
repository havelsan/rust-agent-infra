---
name: rust-14-async-3of4
description: Rust rules module 14: Async/Await (part 3 of 4). 4 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `async-`
---

# Async/Await (part 3/4)

Priority: HIGH. 4 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `async-mpsc-queue` - Use `mpsc` channels for async message queues between tasks
- `async-broadcast-pubsub` - Use `broadcast` channel for pub/sub where all subscribers receive all messages
- `async-watch-latest` - Use `watch` channel for sharing the latest value with multiple observers
- `async-oneshot-response` - Use `oneshot` channel for request-response patterns

---

## async-mpsc-queue

> Use `mpsc` channels for async message queues between tasks

### Why It Matters

`tokio::sync::mpsc` (multi-producer, single-consumer) is the workhorse channel for async Rust. It provides async send/receive, backpressure via bounded capacity, and efficient cloning of senders. It's the default choice for task-to-task communication.

### Bad

```rust
use std::sync::mpsc;  // Wrong! Blocks the async runtime

let (tx, rx) = std::sync::mpsc::channel();

tokio::spawn(async move {
    tx.send("hello").unwrap();  // Might block
});

tokio::spawn(async move {
    let msg = rx.recv().unwrap();  // BLOCKS the executor thread!
});
```

### Good

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<String>(100);

tokio::spawn(async move {
    tx.send("hello".to_string()).await.unwrap();
});

tokio::spawn(async move {
    while let Some(msg) = rx.recv().await {
        println!("Received: {}", msg);
    }
});
```

### Sender Cloning

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Event>(100);

// Multiple producers
for i in 0..10 {
    let tx = tx.clone();  // Cheap clone
    tokio::spawn(async move {
        tx.send(Event { source: i }).await.unwrap();
    });
}

// Drop original sender so channel closes when all clones dropped
drop(tx);

// Consumer
while let Some(event) = rx.recv().await {
    process(event);
}
// Loop exits when all senders dropped
```

### Message Handler Pattern

```rust
use tokio::sync::mpsc;

enum Command {
    Get { key: String, reply: oneshot::Sender<Option<Value>> },
    Set { key: String, value: Value },
    Delete { key: String },
}

async fn run_store(mut commands: mpsc::Receiver<Command>) {
    let mut store = HashMap::new();
    
    while let Some(cmd) = commands.recv().await {
        match cmd {
            Command::Get { key, reply } => {
                let _ = reply.send(store.get(&key).cloned());
            }
            Command::Set { key, value } => {
                store.insert(key, value);
            }
            Command::Delete { key } => {
                store.remove(&key);
            }
        }
    }
}

// Usage
async fn client(tx: mpsc::Sender<Command>) -> Option<Value> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Command::Get { 
        key: "foo".to_string(), 
        reply: reply_tx 
    }).await.unwrap();
    
    reply_rx.await.unwrap()
}
```

### Graceful Shutdown

```rust
async fn worker(mut rx: mpsc::Receiver<Task>, shutdown: CancellationToken) {
    loop {
        tokio::select! {
            _ = shutdown.cancelled() => {
                // Drain remaining messages
                while let Ok(task) = rx.try_recv() {
                    process(task).await;
                }
                break;
            }
            Some(task) = rx.recv() => {
                process(task).await;
            }
            else => break,  // Channel closed
        }
    }
}
```

### WeakSender for Optional Producers

```rust
use tokio::sync::mpsc;

let (tx, mut rx) = mpsc::channel::<Message>(100);
let weak = tx.downgrade();  // Doesn't keep channel alive

tokio::spawn(async move {
    // Strong sender - keeps channel alive
    tx.send("from strong".into()).await.unwrap();
});

tokio::spawn(async move {
    // Weak sender - may fail if strong senders dropped
    if let Some(tx) = weak.upgrade() {
        tx.send("from weak".into()).await.unwrap();
    }
});
```

### Permit Pattern

```rust
// Reserve slot before preparing message
let permit = tx.reserve().await?;

// Now we have guaranteed capacity
let message = expensive_to_create_message();
permit.send(message);  // Never fails

// Useful when message creation is expensive
// and you don't want to create it if channel is full
```

Related: `async-bounded-channel`, `async-oneshot-response`, `async-broadcast-pubsub`

## async-broadcast-pubsub

> Use `broadcast` channel for pub/sub where all subscribers receive all messages

### Why It Matters

Unlike `mpsc` where one consumer receives each message, `broadcast` delivers each message to all subscribers. This is ideal for event broadcasting, real-time notifications, or when multiple components need to react to the same events independently.

### Bad

```rust
use tokio::sync::mpsc;

// mpsc only delivers to ONE consumer
let (tx, mut rx) = mpsc::channel::<Event>(100);

// Only one of these receives each message!
let mut rx2 = ???;  // Can't clone receiver
```

### Good

```rust
use tokio::sync::broadcast;

// broadcast delivers to ALL subscribers
let (tx, _) = broadcast::channel::<Event>(100);

// Each subscriber gets ALL messages
let mut rx1 = tx.subscribe();
let mut rx2 = tx.subscribe();

tokio::spawn(async move {
    while let Ok(event) = rx1.recv().await {
        handle_in_logger(event);
    }
});

tokio::spawn(async move {
    while let Ok(event) = rx2.recv().await {
        handle_in_metrics(event);
    }
});

// Both subscribers receive this
tx.send(Event::UserLogin { user_id: 42 })?;
```

### Broadcast Semantics

```rust
use tokio::sync::broadcast;

let (tx, mut rx1) = broadcast::channel::<i32>(16);
let mut rx2 = tx.subscribe();

tx.send(1)?;
tx.send(2)?;

// Both receive all messages
assert_eq!(rx1.recv().await?, 1);
assert_eq!(rx1.recv().await?, 2);
assert_eq!(rx2.recv().await?, 1);
assert_eq!(rx2.recv().await?, 2);
```

### Handling Lagging Receivers

```rust
use tokio::sync::broadcast::{self, error::RecvError};

let (tx, mut rx) = broadcast::channel::<Event>(16);

loop {
    match rx.recv().await {
        Ok(event) => {
            process(event);
        }
        Err(RecvError::Lagged(count)) => {
            // Receiver couldn't keep up, missed `count` messages
            log::warn!("Missed {} events", count);
            // Continue receiving new messages
        }
        Err(RecvError::Closed) => {
            break;  // All senders dropped
        }
    }
}
```

### Event Bus Pattern

```rust
use tokio::sync::broadcast;

#[derive(Clone, Debug)]
enum AppEvent {
    UserLoggedIn { user_id: u64 },
    OrderCreated { order_id: u64 },
    SystemShutdown,
}

struct EventBus {
    tx: broadcast::Sender<AppEvent>,
}

impl EventBus {
    fn new() -> Self {
        let (tx, _) = broadcast::channel(1000);
        EventBus { tx }
    }
    
    fn publish(&self, event: AppEvent) {
        // Ignore error if no subscribers
        let _ = self.tx.send(event);
    }
    
    fn subscribe(&self) -> broadcast::Receiver<AppEvent> {
        self.tx.subscribe()
    }
}

// Usage
let bus = EventBus::new();

// Logger subscribes
let mut log_rx = bus.subscribe();
tokio::spawn(async move {
    while let Ok(event) = log_rx.recv().await {
        log::info!("Event: {:?}", event);
    }
});

// Metrics subscribes
let mut metrics_rx = bus.subscribe();
tokio::spawn(async move {
    while let Ok(event) = metrics_rx.recv().await {
        record_metric(&event);
    }
});

// Publish events
bus.publish(AppEvent::UserLoggedIn { user_id: 42 });
```

### Broadcast vs Watch

```rust
// broadcast: subscribers get ALL messages
// Good for: events, logs, notifications
let (tx, _) = broadcast::channel::<Event>(100);

// watch: subscribers get LATEST value only
// Good for: config changes, state updates
let (tx, _) = watch::channel(initial_state);

// If subscriber is slow:
// - broadcast: they receive old messages (or lag)
// - watch: they skip to latest (no history)
```

### Clone Requirement

```rust
// broadcast requires Clone because message is cloned to each receiver
use tokio::sync::broadcast;

#[derive(Clone)]  // Required for broadcast
struct Event {
    data: String,
}

let (tx, _) = broadcast::channel::<Event>(100);

// For non-Clone types, wrap in Arc
use std::sync::Arc;

let (tx, _) = broadcast::channel::<Arc<LargeNonClone>>(100);
```

Related: `async-mpsc-queue`, `async-watch-latest`, `async-bounded-channel`

## async-watch-latest

> Use `watch` channel for sharing the latest value with multiple observers

### Why It Matters

`watch` is optimized for scenarios where receivers only care about the most recent value, not the history of changes. Unlike `broadcast`, slow receivers don't lag—they simply skip intermediate values. This is perfect for configuration, state, or status that should always reflect the current situation.

### Bad

```rust
// Using broadcast when only latest value matters
let (tx, _) = broadcast::channel::<Config>(100);

// Receivers might process stale configs if they're slow
// And they waste time processing intermediate values

// Using mpsc with buffered stale values
let (tx, mut rx) = mpsc::channel::<Status>(100);
// Receiver might process outdated statuses
```

### Good

```rust
use tokio::sync::watch;

let (tx, rx) = watch::channel(Config::default());

// Multiple observers
let rx1 = rx.clone();
let rx2 = rx.clone();

// Observer 1: waits for changes
tokio::spawn(async move {
    let mut rx = rx1;
    while rx.changed().await.is_ok() {
        let config = rx.borrow();
        apply_config(&*config);
    }
});

// Observer 2: also sees all changes
tokio::spawn(async move {
    let mut rx = rx2;
    while rx.changed().await.is_ok() {
        let config = rx.borrow();
        log_config_change(&*config);
    }
});

// Update the value
tx.send(Config::new())?;
```

### watch Semantics

```rust
use tokio::sync::watch;

let (tx, mut rx) = watch::channel("initial");

// Immediate read - no waiting
assert_eq!(*rx.borrow(), "initial");

// Wait for change
tx.send("updated")?;
rx.changed().await?;
assert_eq!(*rx.borrow(), "updated");

// Multiple rapid updates - receiver sees latest
tx.send("v1")?;
tx.send("v2")?;
tx.send("v3")?;
rx.changed().await?;
assert_eq!(*rx.borrow(), "v3");  // Skipped v1, v2
```

### Configuration Reload Pattern

```rust
use tokio::sync::watch;
use std::sync::Arc;

struct AppConfig {
    log_level: Level,
    max_connections: usize,
}

async fn config_watcher(tx: watch::Sender<Arc<AppConfig>>) {
    loop {
        tokio::time::sleep(Duration::from_secs(60)).await;
        
        if let Ok(new_config) = reload_config_from_disk() {
            // Only notifies if value actually changed
            tx.send_if_modified(|current| {
                if *current != new_config {
                    *current = Arc::new(new_config);
                    true
                } else {
                    false
                }
            });
        }
    }
}

async fn worker(mut config_rx: watch::Receiver<Arc<AppConfig>>) {
    loop {
        tokio::select! {
            _ = config_rx.changed() => {
                let config = config_rx.borrow().clone();
                reconfigure(&config);
            }
            _ = do_work() => {}
        }
    }
}
```

### State Machine Updates

```rust
#[derive(Clone, PartialEq)]
enum ConnectionState {
    Disconnected,
    Connecting,
    Connected,
    Error(String),
}

struct Connection {
    state_tx: watch::Sender<ConnectionState>,
    state_rx: watch::Receiver<ConnectionState>,
}

impl Connection {
    async fn wait_connected(&mut self) -> Result<(), Error> {
        loop {
            let state = self.state_rx.borrow().clone();
            match state {
                ConnectionState::Connected => return Ok(()),
                ConnectionState::Error(e) => return Err(Error::Connection(e)),
                _ => {
                    self.state_rx.changed().await?;
                }
            }
        }
    }
}
```

### Borrow vs Clone

```rust
use tokio::sync::watch;

let (tx, rx) = watch::channel(vec![1, 2, 3]);

// borrow() returns Ref - must not hold across await
{
    let data = rx.borrow();
    println!("{:?}", *data);
}  // Ref dropped here

// For use across await, clone the data
let data = rx.borrow().clone();
some_async_operation().await;
use_data(&data);  // Safe

// Or use borrow_and_update() to mark as seen
let data = rx.borrow_and_update().clone();
```

### watch vs broadcast vs mpsc

| Feature | watch | broadcast | mpsc |
|---------|-------|-----------|------|
| Receivers | Multiple | Multiple | Single |
| Message delivery | Latest only | All messages | All messages |
| Slow receiver | Skips to latest | Lags/misses | Backpressure |
| Clone required | No | Yes | No |
| Best for | Config, status | Events | Work queues |

Related: `async-broadcast-pubsub`, `async-mpsc-queue`, `async-cancellation-token`

## async-oneshot-response

> Use `oneshot` channel for request-response patterns

### Why It Matters

When one task needs to send a request and wait for exactly one response, `oneshot` is the perfect fit. It's a single-use channel optimized for this pattern—no buffering, no clone overhead. Combined with `mpsc`, it enables clean actor-style message passing.

### Bad

```rust
// Using mpsc for single response - wasteful
let (tx, mut rx) = mpsc::channel::<Response>(1);
send_request().await;
let response = rx.recv().await.unwrap();
// Channel persists, could accidentally receive more

// Using shared state - complex
let result = Arc::new(Mutex::new(None));
send_request(result.clone()).await;
while result.lock().await.is_none() {
    tokio::time::sleep(Duration::from_millis(10)).await;  // Polling!
}
```

### Good

```rust
use tokio::sync::oneshot;

let (tx, rx) = oneshot::channel::<Response>();

// Send request with reply channel
send_request(Request { data, reply: tx }).await;

// Wait for response
let response = rx.await?;

// Channel is consumed - can't accidentally reuse
```

### Request-Response Pattern

```rust
use tokio::sync::{mpsc, oneshot};

enum Request {
    Get {
        key: String,
        reply: oneshot::Sender<Option<Value>>,
    },
    Set {
        key: String,
        value: Value,
        reply: oneshot::Sender<bool>,
    },
}

// Service handler
async fn service(mut rx: mpsc::Receiver<Request>) {
    let mut store = HashMap::new();
    
    while let Some(req) = rx.recv().await {
        match req {
            Request::Get { key, reply } => {
                let value = store.get(&key).cloned();
                let _ = reply.send(value);  // Ignore if receiver dropped
            }
            Request::Set { key, value, reply } => {
                store.insert(key, value);
                let _ = reply.send(true);
            }
        }
    }
}

// Client
async fn get_value(tx: &mpsc::Sender<Request>, key: &str) -> Option<Value> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Request::Get {
        key: key.to_string(),
        reply: reply_tx,
    }).await.ok()?;
    
    reply_rx.await.ok()?
}
```

### With Timeout

```rust
use tokio::time::{timeout, Duration};

async fn request_with_timeout(
    tx: &mpsc::Sender<Request>,
    key: &str,
) -> Result<Value, Error> {
    let (reply_tx, reply_rx) = oneshot::channel();
    
    tx.send(Request::Get {
        key: key.to_string(),
        reply: reply_tx,
    }).await.map_err(|_| Error::ServiceDown)?;
    
    timeout(Duration::from_secs(5), reply_rx)
        .await
        .map_err(|_| Error::Timeout)?
        .map_err(|_| Error::ServiceDown)?
        .ok_or(Error::NotFound)
}
```

### Error Handling

```rust
use tokio::sync::oneshot;

let (tx, rx) = oneshot::channel::<String>();

// Sender dropped without sending
drop(tx);
match rx.await {
    Ok(value) => println!("Got: {}", value),
    Err(oneshot::error::RecvError { .. }) => {
        println!("Sender dropped");
    }
}

// Receiver dropped before send
let (tx, rx) = oneshot::channel::<String>();
drop(rx);
match tx.send("hello".to_string()) {
    Ok(()) => println!("Sent"),
    Err(value) => println!("Receiver dropped, value: {}", value),
}
```

### Closed Detection

```rust
// Check if receiver is still waiting
let (tx, rx) = oneshot::channel::<i32>();

// In producer
if tx.is_closed() {
    println!("Receiver already gone, skip expensive computation");
} else {
    let result = expensive_computation();
    tx.send(result).ok();
}

// Async wait for close
let tx_clone = tx.clone();  // Note: can't actually clone, just showing concept
tokio::select! {
    _ = tx.closed() => println!("Receiver dropped"),
    result = compute() => { tx.send(result).ok(); }
}
```

### Response Type Wrapper

```rust
// Standardize request-response pattern
struct RpcRequest<Req, Res> {
    request: Req,
    reply: oneshot::Sender<Res>,
}

impl<Req, Res> RpcRequest<Req, Res> {
    fn new(request: Req) -> (Self, oneshot::Receiver<Res>) {
        let (tx, rx) = oneshot::channel();
        (RpcRequest { request, reply: tx }, rx)
    }
    
    fn respond(self, response: Res) {
        let _ = self.reply.send(response);
    }
}

// Usage
let (req, rx) = RpcRequest::new(GetUser { id: 42 });
tx.send(req).await?;
let user = rx.await?;
```

Related: `async-mpsc-queue`, `async-bounded-channel`, `async-select-racing`
