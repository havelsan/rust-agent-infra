---
name: rust-36-observability
description: Rust rules module 36: Observability. 7 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `obs-`
---

# Observability

Priority: MEDIUM. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `obs-tracing-over-log` - Use `tracing` for structured, span-aware diagnostics instead of `println!` or bare `log`
- `obs-library-facade` - Libraries emit through the tracing/log facade and never install a subscriber
- `obs-structured-fields` - Record structured key-value fields, not values interpolated into the message string
- `obs-instrument-spans` - Use `#[tracing::instrument]` and spans to attach context to async tasks and requests
- `obs-levels-filter` - Use log levels meaningfully and filter with `EnvFilter` / `RUST_LOG`
- `obs-error-chain` - Log errors with their full source chain, and log each error exactly once
- `obs-no-sensitive-data` - Never log secrets or PII; redact or skip them

---

## obs-tracing-over-log

> Use `tracing` for structured, span-aware diagnostics instead of `println!` or bare `log`

### Why It Matters

`println!` and `eprintln!` have no concept of log levels, targets, or structured data — they cannot be silenced, filtered, or parsed by observability pipelines. The `log` facade improves this but emits only flat strings and has no notion of spans. `tracing` records both *events* (point-in-time observations) and *spans* (contextual scopes that automatically follow execution across `.await` points and threads), with structured key-value fields, level filtering, and target routing. It is also interoperable with the `log` ecosystem via `tracing`'s `log` feature flag.

### Bad

```rust
fn handle_login(id: u64) {
    println!("user {} logged in", id);
    // No level, no structure, no filtering, goes to stdout unconditionally
}

fn main() {
    handle_login(42);
}
```

### Good

```rust
use tracing::info;

fn handle_login(id: u64) {
    // Structured field: user.id is queryable in JSON/OpenTelemetry backends
    info!(user.id = %id, "user logged in");
}

fn main() {
    // One-time subscriber init belongs in the binary, not in libraries
    tracing_subscriber::fmt::init();
    handle_login(42);
}
```

### Key Points

| Approach | Levels | Structured | Async-aware spans | `log` compat |
|---|---|---|---|---|
| `println!` | No | No | No | No |
| `log` facade | Yes | No | No | Yes |
| `tracing` | Yes | Yes | Yes | Yes (via feature) |

- Add to `Cargo.toml`: `tracing = "0.1"` for all crates; `tracing-subscriber = { version = "0.3", features = ["env-filter"] }` for binaries only.
- The `%expr` sigil uses `Display`; `?expr` uses `Debug`; bare `field = value` records typed primitives.
- `tracing` ships a `log` compatibility bridge: set `tracing-subscriber`'s `log` feature or call `tracing_log::LogTracer::init()` to capture existing `log`-emitting dependencies.

Related: `obs-structured-fields`, `obs-instrument-spans`, `async-tokio-runtime`

## obs-library-facade

> Libraries emit through the tracing/log facade and never install a subscriber

### Why It Matters

Installing a global subscriber or logger is a one-time, process-wide operation. If a library calls `tracing_subscriber::fmt::init()` or `env_logger::init()`, it silently conflicts with any other library or the application binary that does the same — the second call panics or is silently ignored, and the caller loses all control over log format, destination, and level filtering. Libraries must only *emit* events and spans; the binary that owns `main` decides how to handle them. This is the same contract as `log` has always enforced and `tracing` carries forward.

### Bad

```rust
// In a library crate: mylib/src/lib.rs
use tracing::info;

pub fn connect(url: &str) {
    // BAD: library installs a subscriber — conflicts with the application
    tracing_subscriber::fmt::init();
    info!(url, "connecting");
}
```

```rust
// Also bad: using env_logger in a library
pub fn init_logging() {
    env_logger::init(); // steals the global logger from the application
}
```

### Good

```rust
// In a library crate: mylib/src/lib.rs
use tracing::info;

pub fn connect(url: &str) {
    // Good: just emit; the application owns subscriber setup
    info!(url, "connecting");
}
```

```rust
// In the binary: src/main.rs
fn main() {
    // The application initializes once, with full control
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    mylib::connect("postgres://localhost/app");
}
```

### Key Points

- **Library `Cargo.toml`**: depend on `tracing = "0.1"` only. Do **not** add `tracing-subscriber` or `env_logger` as non-`dev` dependencies.
- **Binary `Cargo.toml`**: add `tracing-subscriber = { version = "0.3", features = ["env-filter"] }` for the subscriber.
- If you need a subscriber in library tests, add it to `[dev-dependencies]` and call it inside `#[test]` functions using `tracing_subscriber::fmt::try_init()` (the `try_` variant does not panic on re-init).
- The `log` crate follows the same rule: libraries call `log::info!(...)`; applications call `env_logger::init()` or bridge via `tracing_log::LogTracer`.

```toml
# library Cargo.toml
[dependencies]
tracing = "0.1"

[dev-dependencies]
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
```

Related: `obs-tracing-over-log`, `obs-levels-filter`, `api-serde-optional`

## obs-structured-fields

> Record structured key-value fields, not values interpolated into the message string

### Why It Matters

When values are interpolated directly into the message string (e.g., `"processed 42 items for user 7 in 120ms"`), they become opaque text. Log aggregators (Loki, Elasticsearch, OpenTelemetry) cannot filter on `items = 42` or group by `user.id` because those values no longer exist as discrete fields. Structured fields keep data machine-parseable, filterable, and chart-able without regex post-processing. `tracing` supports three field sigils: `%expr` for `Display`, `?expr` for `Debug`, and bare `field = value` for typed primitives — the message string should only contain a stable, human-readable description.

### Bad

```rust
use tracing::info;

fn process_batch(user_id: u64, items: usize, elapsed_ms: u64) {
    // Values buried in the message string — unqueryable in aggregators
    info!("processed {} items for user {} in {}ms", items, user_id, elapsed_ms);
}
```

### Good

```rust
use tracing::info;

fn process_batch(user_id: u64, items: usize, elapsed_ms: u64) {
    // Structured: each value is a discrete, queryable field
    info!(
        user.id = user_id,
        items,
        elapsed_ms,
        "batch processed"
    );
}

#[derive(Debug)]
struct Request {
    path: String,
    method: String,
}

fn handle_request(req: &Request, status: u16) {
    // %req uses Display; ?req uses Debug; status is a primitive
    info!(
        request = ?req,   // Debug format for the whole struct
        status,
        "request complete"
    );
}
```

### Field Sigil Reference

| Syntax | Trait used | When to use |
|---|---|---|
| `field = value` | native (primitive) | integers, bools, floats |
| `field = %expr` | `Display` | strings, IDs, URLs, types with clean `Display` |
| `field = ?expr` | `Debug` | structs, enums, vecs — for diagnostics |
| `field` (shorthand) | same as `field = field` | when name matches variable |

### Key Points

- Keep the message string short, stable, and human-readable. It should make sense *without* the fields.
- Prefer `%` over `?` for values that have a clean `Display` (e.g., `%id`, `%path`) — JSON backends quote Debug output inconsistently.
- Use namespaced field names like `user.id`, `http.status`, `db.query` when aligning to OpenTelemetry semantic conventions.
- Avoid placing the same data in both the message and a field (redundant and noisy).

Related: `obs-tracing-over-log`, `obs-no-sensitive-data`, `obs-error-chain`

## obs-instrument-spans

> Use `#[tracing::instrument]` and spans to attach context to async tasks and requests

### Why It Matters

A span groups all events emitted during a logical operation (an HTTP request, a database call, a background job) and attaches structured context to every event within it. Without spans, log lines from concurrent async tasks interleave with no way to correlate them. The `#[tracing::instrument]` attribute creates a span automatically from the function's arguments as fields. There is one critical async pitfall: holding a span *entry guard* (`let _g = span.enter()`) across an `.await` point attaches the span to the wrong task when the executor resumes on a different thread — use `.instrument(span)` on the future instead.

### Bad

```rust
use tracing::{info, span, Level};

// BAD: holding an entry guard across .await corrupts span context
async fn fetch_user(user_id: u64) -> Result<String, String> {
    let span = span!(Level::INFO, "fetch_user", user_id);
    let _guard = span.enter(); // guard held here...

    let result = some_async_db_call(user_id).await; // ...across this await — wrong!
    info!("fetched user");
    result
}

async fn some_async_db_call(_id: u64) -> Result<String, String> {
    Ok("alice".to_string())
}
```

### Good

```rust
use tracing::{info, instrument, Instrument, info_span};

// GOOD: #[instrument] handles async correctly; skip large/sensitive args
#[instrument(skip(db), fields(user.id = user_id))]
async fn fetch_user(user_id: u64, db: &DbPool) -> Result<String, DbError> {
    info!("fetching user from database");
    let user = db.query_user(user_id).await?;
    info!(username = %user.name, "user fetched");
    Ok(user.name)
}

// GOOD: manual span + .instrument() for dynamic span names
async fn process_job(job_id: &str) {
    let span = info_span!("process_job", job.id = job_id);
    async move {
        info!("job started");
        do_work().await;
        info!("job complete");
    }
    .instrument(span)
    .await;
}

async fn do_work() {}

// Placeholder types for the example
struct DbPool;
#[derive(Debug)] struct DbUser { name: String }
#[derive(Debug)] struct DbError;

impl DbPool {
    async fn query_user(&self, _id: u64) -> Result<DbUser, DbError> {
        Ok(DbUser { name: "alice".to_string() })
    }
}
```

### Key Points

- **`#[instrument]`** is the preferred way to instrument async functions — it wraps the whole future in `.instrument(span)` under the hood.
- Use `skip(arg)` or `skip_all` to exclude large types (e.g., database pools, byte buffers) and sensitive values from auto-captured fields.
- Use `fields(key = value)` inside `#[instrument]` to add or rename fields beyond the auto-captured args.
- For manual spans, always attach with `.instrument(span).await`, never hold a guard across `.await`.
- Spans nest automatically: entering a child span inside a parent records the parent's context in traces, enabling waterfall views in tools like Jaeger or Tempo.

Related: `obs-structured-fields`, `obs-no-sensitive-data`, `async-no-lock-await`

## obs-levels-filter

> Use log levels meaningfully and filter with `EnvFilter` / `RUST_LOG`

### Why It Matters

Log levels exist to communicate urgency and to let operators tune verbosity without recompiling. Misusing them — emitting everything at `info!`, or leaving `debug!` output in hot paths in production — overwhelms aggregators and hides real signals. `tracing_subscriber::EnvFilter` reads the `RUST_LOG` environment variable and supports per-crate, per-target, and per-span directives, giving operators fine-grained control at runtime. For release builds, tracing's `max_level_*` Cargo features can compile out verbose levels entirely, eliminating even the call-site overhead.

### Bad

```rust
use tracing::info;

fn handle_request(path: &str, body: &[u8]) {
    // BAD: debug-level detail emitted at info — always noisy in production
    info!(path, body_len = body.len(), raw = ?body, "handling request");
    info!("entered handle_request");         // trace-level lifecycle noise
    info!("about to parse body");            // also trace-level
    // ... actual logic ...
    info!("done handling request");
}
```

### Good

```rust
use tracing::{debug, error, info, instrument, trace, warn};

#[instrument(skip(body))]
fn handle_request(path: &str, body: &[u8]) {
    trace!("entered handler");                          // very verbose — trace
    debug!(body_len = body.len(), "parsing body");      // diagnostic — debug
    info!(path, "request received");                    // lifecycle — info

    match parse_body(body) {
        Ok(parsed) => {
            info!(items = parsed.len(), "request processed");
        }
        Err(e) if is_client_error(&e) => {
            warn!(error = ?e, "malformed request from client");   // recoverable — warn
        }
        Err(e) => {
            error!(error = ?e, "unexpected parse failure");       // needs attention — error
        }
    }
}

fn parse_body(_body: &[u8]) -> Result<Vec<u8>, String> { Ok(vec![]) }
fn is_client_error(_e: &str) -> bool { false }
```

```rust
// In main: configure EnvFilter from RUST_LOG
fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,myapp=debug,hyper=warn".into()),
        )
        .init();
}
```

### Level Guidelines

| Level | Use for | Example |
|---|---|---|
| `error!` | Failures that need immediate attention | database connection lost |
| `warn!` | Recoverable anomalies, degraded state | retrying after timeout |
| `info!` | High-level lifecycle events | server started, request complete |
| `debug!` | Diagnostic detail for development | query parameters, cache status |
| `trace!` | Very verbose, per-iteration detail | loop counters, raw bytes |

### Key Points

- `RUST_LOG=info,mycrate=debug,hyper=warn` — comma-separated target=level pairs; the first token sets the global default.
- Compile out verbose levels in release with Cargo features: `tracing = { version = "0.1", features = ["max_level_debug", "release_max_level_info"] }`.
- Prefer `try_from_default_env()` with a fallback string over `from_default_env()` so the binary still starts when `RUST_LOG` is unset or malformed.

Related: `obs-tracing-over-log`, `obs-library-facade`

## obs-error-chain

> Log errors with their full source chain, and log each error exactly once

### Why It Matters

Logging only the top-level `Display` of an error silently drops the underlying cause chain — you see "request failed" but not *why*. The two common fixes are: use `?` format (`error = ?err`) to capture `Debug` output including the chain, or use `{:#}` on an `anyhow::Error` which formats the full cause chain. The second hazard is the log-and-return anti-pattern: logging the error at every propagation layer records the same failure multiple times with different amounts of context, polluting aggregators. Log once, at the boundary that *handles* the error; everywhere else, propagate with `?` and optionally add context.

### Bad

```rust
use tracing::error;

async fn fetch_data(id: u64) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let data = read_from_db(id).await.map_err(|e| {
        error!("{}", e);  // BAD: drops source chain, logs too early
        e
    })?;
    Ok(data)
}

async fn handle(id: u64) -> Result<(), Box<dyn std::error::Error>> {
    let data = fetch_data(id).await.map_err(|e| {
        error!("{}", e);  // BAD: logged again at every layer
        e
    })?;
    process(data);
    Ok(())
}

async fn read_from_db(_id: u64) -> Result<Vec<u8>, std::io::Error> {
    Err(std::io::Error::other("connection refused"))
}
fn process(_data: Vec<u8>) {}
```

### Good

```rust
use anyhow::{Context, Result};
use tracing::{error, instrument, warn};

// Propagate with context; do NOT log here
#[instrument]
async fn read_from_db(id: u64) -> Result<Vec<u8>> {
    inner_db_call(id)
        .await
        .with_context(|| format!("failed to read record {id} from database"))
    // No logging — just add context and propagate
}

// Also just propagates
#[instrument]
async fn fetch_data(id: u64) -> Result<Vec<u8>> {
    read_from_db(id).await.context("fetch_data failed")
}

// The handler boundary: this is where the error is HANDLED, so log it once
#[instrument]
async fn handle_request(id: u64) -> Result<(), String> {
    match fetch_data(id).await {
        Ok(data) => {
            process(data);
            Ok(())
        }
        Err(err) => {
            // {:#} on anyhow::Error prints the full cause chain
            error!(error = %format!("{err:#}"), "request failed");
            Err("internal error".to_string())
        }
    }
}

async fn inner_db_call(_id: u64) -> Result<Vec<u8>> {
    Err(anyhow::anyhow!("connection refused"))
}
fn process(_data: Vec<u8>) {}
```

### Key Points

- **`error = ?err`**: uses `Debug` — prints the error and its `source()` chain for types that implement it.
- **`format!("{err:#}")`** or `%format!(...)`: `anyhow::Error`'s alternate Display walks the full chain with `: ` separators.
- **Propagate, don't log**: use `?` and `.context()` / `.with_context()` at intermediate layers; log at the single handling boundary.
- If you *must* log at a non-handling layer (e.g., background task that discards the error), use `warn!` not `error!` to signal it was absorbed.
- The `tracing-error` crate provides `SpanTrace` to capture the span context at the error site and attach it to the error type.

Related: `err-context-chain`, `err-source-chain`, `anti-empty-catch`

## obs-no-sensitive-data

> Never log secrets or PII; redact or skip them

### Why It Matters

Logs and traces are routinely shipped to cloud aggregators (Datadog, Grafana Loki, Splunk) and retained for weeks or months. If a password, API token, session cookie, or piece of PII (email, SSN, health data) appears in a log line or span field, it leaks into systems with weaker access controls than your secrets manager, appears in support exports, and may violate GDPR/HIPAA/PCI-DSS. The fix is cheap: use `#[instrument(skip(...))]` or `skip_all` to exclude sensitive arguments, and wrap sensitive types in a redacting newtype or use the `secrecy` crate's `Secret<T>` which prints `[redacted]` from both `Debug` and `Display`.

### Bad

```rust
use tracing::instrument;

struct Credentials {
    username: String,
    password: String,   // secret
    api_key: String,    // secret
}

// BAD: instrument auto-captures all args as fields — password becomes a span field
#[instrument]
async fn authenticate(credentials: &Credentials) -> bool {
    // Also BAD: manual logging of the whole struct
    tracing::info!(?credentials, "authenticating user");
    true
}
```

### Good

```rust
use tracing::{info, instrument};

// A simple redacting newtype — implement for any sensitive type
#[derive(Clone)]
struct Secret(String);

impl std::fmt::Debug for Secret {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("[redacted]")
    }
}

impl std::fmt::Display for Secret {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("[redacted]")
    }
}

struct Credentials {
    username: String,
    password: Secret,   // redacts in Debug/Display
    api_key: Secret,    // redacts in Debug/Display
}

// GOOD: skip sensitive args by name
#[instrument(skip(credentials), fields(username = %credentials.username))]
async fn authenticate(credentials: &Credentials) -> bool {
    info!("authenticating user");
    // password and api_key never appear in any span field or log line
    verify_password(&credentials.username, &credentials.password)
}

fn verify_password(_username: &str, _password: &Secret) -> bool { true }
```

```rust
// Alternative: use the `secrecy` crate (Secret<T> implements Debug as "[redacted]")
// use secrecy::{Secret, ExposeSecret};
// struct Credentials { username: String, password: Secret<String> }
// credentials.password.expose_secret()  // only call site that reveals value
```

### Key Points

- **`skip(arg)`**: exclude a single argument from `#[instrument]` auto-captured fields.
- **`skip_all`**: exclude all arguments; then add only safe fields with `fields(key = value)`.
- **Redacting newtypes**: override `Debug` and `Display` to emit `"[redacted]"` — this protects against accidental `?arg` or `%arg` elsewhere in the codebase.
- **`secrecy` crate**: provides `Secret<T>` with a `[redacted]` `Debug` impl and an explicit `.expose_secret()` API so you know exactly where the value is revealed.
- **Do not log full request bodies** in production: they may contain tokens, credentials, or PII embedded in JSON payloads. Log only metadata (size, content-type, path).
- Audit existing spans with `RUST_LOG=trace` in a staging environment before shipping.

Related: `obs-instrument-spans`, `obs-structured-fields`, `err-thiserror-lib`
