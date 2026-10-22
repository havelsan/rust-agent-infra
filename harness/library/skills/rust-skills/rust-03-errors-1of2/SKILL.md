---
name: rust-03-errors-1of2
description: Rust rules module 03: Error Handling (part 1 of 2). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `err-`
---

# Error Handling (part 1/2)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `err-thiserror-lib` - Use `thiserror` for library error types
- `err-anyhow-app` - Use `anyhow` for application error handling
- `err-result-over-panic` - Return `Result<T, E>` instead of panicking for recoverable errors
- `err-context-chain` - Add context with `.context()` or `.with_context()`
- `err-no-unwrap-prod` - Avoid `unwrap()` in production code; use `?`, `expect()`, or handle errors
- `err-expect-bugs-only` - Use `expect()` only for invariants that indicate bugs, not user errors

---

## err-thiserror-lib

> Use `thiserror` for library error types

### Why It Matters

Libraries should expose typed, matchable errors so users can handle specific error conditions. `thiserror` generates `Error` trait implementations with minimal boilerplate, creating ergonomic error types that are easy to match against.

### Bad

```rust
// String errors - not matchable
fn parse(input: &str) -> Result<Data, String> {
    Err("parse error".to_string())
}

// Box<dyn Error> - not matchable
fn load(path: &Path) -> Result<Data, Box<dyn std::error::Error>> {
    Err(Box::new(std::io::Error::new(std::io::ErrorKind::NotFound, "file not found")))
}

// Manual implementation - verbose
#[derive(Debug)]
enum MyError {
    Io(std::io::Error),
    Parse(String),
}

impl std::fmt::Display for MyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MyError::Io(e) => write!(f, "io error: {}", e),
            MyError::Parse(s) => write!(f, "parse error: {}", s),
        }
    }
}

impl std::error::Error for MyError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            MyError::Io(e) => Some(e),
            MyError::Parse(_) => None,
        }
    }
}
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ParseError {
    #[error("invalid syntax at line {line}: {message}")]
    Syntax { line: usize, message: String },
    
    #[error("unexpected end of file")]
    UnexpectedEof,
    
    #[error("invalid utf-8 encoding")]
    Utf8(#[from] std::str::Utf8Error),
    
    #[error("io error reading input")]
    Io(#[from] std::io::Error),
}

// Usage
fn parse(input: &str) -> Result<Ast, ParseError> {
    if input.is_empty() {
        return Err(ParseError::UnexpectedEof);
    }
    // ...
}

// Users can match specific errors
match parse(input) {
    Ok(ast) => process(ast),
    Err(ParseError::Syntax { line, message }) => {
        eprintln!("Syntax error on line {}: {}", line, message);
    }
    Err(ParseError::UnexpectedEof) => {
        eprintln!("File ended unexpectedly");
    }
    Err(e) => eprintln!("Error: {}", e),
}
```

### Key Attributes

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MyError {
    // Simple message
    #[error("operation failed")]
    Failed,
    
    // Interpolated fields
    #[error("invalid value: {0}")]
    InvalidValue(String),
    
    // Named fields
    #[error("connection to {host}:{port} failed")]
    Connection { host: String, port: u16 },
    
    // Automatic From impl with #[from]
    #[error("database error")]
    Database(#[from] sqlx::Error),
    
    // Source without From (manual conversion needed)
    #[error("validation failed")]
    Validation {
        #[source]
        cause: ValidationError,
        field: String,
    },
    
    // Transparent - delegates Display and source to inner
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
```

### Error Chaining

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ConfigError {
    #[error("failed to read config file")]
    Read(#[source] std::io::Error),
    
    #[error("failed to parse config")]
    Parse(#[source] toml::de::Error),
    
    #[error("invalid config value for '{key}'")]
    InvalidValue {
        key: String,
        #[source]
        cause: ValueError,
    },
}

// Error chain is preserved
fn load_config(path: &Path) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(ConfigError::Read)?;
    
    let config: Config = toml::from_str(&content)
        .map_err(ConfigError::Parse)?;
    
    Ok(config)
}
```

### Library vs Application

| Context | Crate | Why |
|---------|-------|-----|
| Library | `thiserror` | Typed errors users can match |
| Application | `anyhow` | Easy error handling with context |
| Both | `thiserror` for public API, `anyhow` internally | Best of both |

Related: `err-anyhow-app`, `err-from-impl`, `err-source-chain`

## err-anyhow-app

> Use `anyhow` for application error handling

### Why It Matters

Applications often don't need typed errors - they just need to report what went wrong with good context. `anyhow` provides easy error handling with context chaining, backtraces, and conversion from any error type.

### Bad

```rust
// Tedious type management
fn load_config() -> Result<Config, Box<dyn std::error::Error>> {
    let path = find_config()?;  // Returns FindError
    let content = std::fs::read_to_string(&path)?;  // Returns io::Error
    let config: Config = toml::from_str(&content)?;  // Returns toml::Error
    validate(&config)?;  // Returns ValidationError
    Ok(config)
}

// No context - hard to debug
fn process() -> Result<(), Box<dyn std::error::Error>> {
    let data = fetch()?;  // Which fetch failed?
    transform(data)?;     // What was being transformed?
    save()?;              // Where was it saving to?
    Ok(())
}
```

### Good

```rust
use anyhow::{Context, Result};

fn load_config() -> Result<Config> {
    let path = find_config()
        .context("failed to locate config file")?;
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    
    let config: Config = toml::from_str(&content)
        .context("failed to parse config as TOML")?;
    
    validate(&config)
        .context("config validation failed")?;
    
    Ok(config)
}

// Error message: "config validation failed: field 'port' must be > 0"
// Full chain preserved for debugging
```

### Key Features

```rust
use anyhow::{anyhow, bail, ensure, Context, Result};

fn example() -> Result<()> {
    // Create ad-hoc errors
    let err = anyhow!("something went wrong");
    
    // Early return with error
    bail!("aborting due to {}", reason);
    
    // Assert with error
    ensure!(condition, "condition was false");
    
    // Add context to any error
    risky_operation()
        .context("risky operation failed")?;
    
    // Dynamic context
    fetch(url)
        .with_context(|| format!("failed to fetch {}", url))?;
    
    Ok(())
}
```

### Main Function Pattern

```rust
use anyhow::Result;

fn main() -> Result<()> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}

// Or with custom exit handling
fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);  // Pretty-print with causes
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    // Application logic
    Ok(())
}
```

### Error Display Formats

```rust
use anyhow::Result;

fn show_error(err: anyhow::Error) {
    // Just the top-level message
    println!("{}", err);
    // "config validation failed"
    
    // With cause chain (# alternate format)
    println!("{:#}", err);
    // "config validation failed: field 'port' must be > 0"
    
    // Debug format with backtrace
    println!("{:?}", err);
    // Full backtrace if RUST_BACKTRACE=1
    
    // Iterate through cause chain
    for cause in err.chain() {
        println!("Caused by: {}", cause);
    }
}
```

### Combining with thiserror

```rust
// In your library crate - typed errors
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("rate limited")]
    RateLimited,
    #[error("not found: {0}")]
    NotFound(String),
}

// In your application - anyhow for handling
use anyhow::{Context, Result};

fn fetch_user(id: u64) -> Result<User> {
    api::get_user(id)
        .with_context(|| format!("failed to fetch user {}", id))
}

// Can still downcast if needed
fn handle_error(err: anyhow::Error) {
    if let Some(api_err) = err.downcast_ref::<ApiError>() {
        match api_err {
            ApiError::RateLimited => wait_and_retry(),
            ApiError::NotFound(id) => log_missing(id),
        }
    }
}
```

### When to Use Which

| Situation | Use |
|-----------|-----|
| Library public API | `thiserror` |
| Application code | `anyhow` |
| CLI tools | `anyhow` |
| Internal library code | Either |
| Need to match error variants | `thiserror` |
| Just need to report errors | `anyhow` |

Related: `err-thiserror-lib`, `err-context-chain`

## err-result-over-panic

> Return `Result<T, E>` instead of panicking for recoverable errors

### Why It Matters

Panics unwind the stack and crash the thread (or program). They're unrecoverable from the caller's perspective. `Result<T, E>` gives callers the ability to decide how to handle errors—retry, fallback, propagate, or log. Libraries should almost never panic; applications should minimize panics to truly unrecoverable situations.

### Bad

```rust
fn parse_config(path: &str) -> Config {
    let content = std::fs::read_to_string(path)
        .expect("Failed to read config");  // Crashes on missing file
    
    serde_json::from_str(&content)
        .expect("Invalid config format")   // Crashes on bad JSON
}

fn divide(a: i32, b: i32) -> i32 {
    if b == 0 {
        panic!("Division by zero!");  // Crashes the program
    }
    a / b
}
```

Caller has no chance to recover or provide a fallback.

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file: {0}")]
    Io(#[from] std::io::Error),
    #[error("Invalid config format: {0}")]
    Parse(#[from] serde_json::Error),
}

fn parse_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)?;
    let config = serde_json::from_str(&content)?;
    Ok(config)
}

fn divide(a: i32, b: i32) -> Result<i32, &'static str> {
    if b == 0 {
        return Err("Division by zero");
    }
    Ok(a / b)
}

// Caller decides how to handle
match parse_config("app.json") {
    Ok(config) => run_app(config),
    Err(e) => {
        eprintln!("Using default config: {}", e);
        run_app(Config::default())
    }
}
```

### When Panic IS Appropriate

```rust
// 1. Bug in the program (invariant violation)
fn get_cached_value(&self, key: &str) -> &Value {
    self.cache.get(key).expect("BUG: key was verified to exist")
}

// 2. Setup/initialization that can't reasonably fail
fn main() {
    let config = Config::load().expect("Failed to load required config");
    // Can't run without config, panic is reasonable
}

// 3. Tests
#[test]
fn test_parse() {
    let result = parse("valid input").unwrap(); // unwrap OK in tests
    assert_eq!(result, expected);
}

// 4. Examples and prototypes
fn main() {
    // Quick prototype, panic is fine
    let data = fetch_data().unwrap();
}
```

### Panic vs Result Decision Guide

| Situation | Use |
|-----------|-----|
| File not found | `Result` |
| Network error | `Result` |
| Invalid user input | `Result` |
| Parse error | `Result` |
| Index out of bounds (from user data) | `Result` |
| Index out of bounds (internal bug) | Panic |
| Violated internal invariant | Panic |
| Unimplemented code path | Panic (`unimplemented!()`) |
| Impossible state reached | Panic (`unreachable!()`) |

### Library vs Application

```rust
// Library: NEVER panic on user input
pub fn parse(input: &str) -> Result<Ast, ParseError> {
    // Always return Result
}

// Application: Can panic at top level for critical failures
fn main() {
    if let Err(e) = run() {
        eprintln!("Fatal error: {}", e);
        std::process::exit(1);
    }
}
```

Related: `err-thiserror-lib`, `err-anyhow-app`, `err-no-unwrap-prod`, `anti-unwrap-abuse`

## err-context-chain

> Add context with `.context()` or `.with_context()`

### Why It Matters

Raw errors often lack information about what operation failed. Adding context creates an error chain that tells the full story: what you were trying to do, and why it failed.

### Bad

```rust
// Raw error - no context
fn load_user(id: u64) -> Result<User, Error> {
    let path = format!("users/{}.json", id);
    let content = std::fs::read_to_string(&path)?;
    Ok(serde_json::from_str(&content)?)
}

// Error message: "No such file or directory (os error 2)"
// Which file? What were we doing?
```

### Good

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let path = format!("users/{}.json", id);
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read user file: {}", path))?;
    
    let user: User = serde_json::from_str(&content)
        .with_context(|| format!("failed to parse user {} JSON", id))?;
    
    Ok(user)
}

// Error: "failed to parse user 42 JSON"
// Caused by: "expected ':' at line 5 column 12"
```

### context() vs with_context()

```rust
// context() - static string (slight allocation)
fs::read_to_string(path)
    .context("failed to read config")?;

// with_context() - lazy evaluation (only allocates on error)
fs::read_to_string(path)
    .with_context(|| format!("failed to read {}", path))?;

// Use with_context() when:
// - Message includes runtime data (format!)
// - Computing the message is expensive
// - Error path is cold (most of the time)
```

### Building Context Chains

```rust
fn process_order(order_id: u64) -> Result<()> {
    let order = fetch_order(order_id)
        .with_context(|| format!("failed to fetch order {}", order_id))?;
    
    let user = load_user(order.user_id)
        .with_context(|| format!("failed to load user for order {}", order_id))?;
    
    let payment = process_payment(&order, &user)
        .context("payment processing failed")?;
    
    ship_order(&order, &payment)
        .context("shipping failed")?;
    
    Ok(())
}

// Full error chain:
// "shipping failed"
// Caused by: "carrier API returned 503"
// Caused by: "connection refused"
```

### Displaying Error Chains

```rust
fn main() {
    if let Err(e) = run() {
        // Just top-level message
        eprintln!("Error: {}", e);
        
        // Full chain with alternate format
        eprintln!("Error: {:#}", e);
        
        // Debug format (includes backtrace if enabled)
        eprintln!("Error: {:?}", e);
        
        // Iterate through chain
        for (i, cause) in e.chain().enumerate() {
            eprintln!("  {}: {}", i, cause);
        }
    }
}
```

### With thiserror

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("failed to load config from {path}")]
    ConfigLoad {
        path: String,
        #[source]
        cause: std::io::Error,
    },
    
    #[error("failed to connect to database")]
    Database {
        #[source]
        cause: sqlx::Error,
    },
}

// Usage
fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| AppError::ConfigLoad {
            path: path.to_string(),
            cause: e,
        })?;
    // ...
}
```

Related: `err-anyhow-app`, `err-source-chain`, `err-question-mark`

## err-no-unwrap-prod

> Avoid `unwrap()` in production code; use `?`, `expect()`, or handle errors

### Why It Matters

`unwrap()` panics on `None` or `Err` without any context about what went wrong. In production, this creates cryptic crash messages that are hard to debug. Either propagate errors with `?`, use `expect()` with a message explaining the invariant, or handle the error explicitly.

### Bad

```rust
fn process_request(req: Request) -> Response {
    let user_id = req.headers.get("X-User-Id").unwrap();  // Why did it fail?
    let user = database.find_user(user_id).unwrap();       // Which operation?
    let data = user.preferences.get("theme").unwrap();     // No context
    
    Response::new(data)
}

// Crash message: "called `Option::unwrap()` on a `None` value"
// Where? Why? No idea.
```

### Good

```rust
// Option 1: Propagate with ?
fn process_request(req: Request) -> Result<Response, AppError> {
    let user_id = req.headers
        .get("X-User-Id")
        .ok_or(AppError::MissingHeader("X-User-Id"))?;
    
    let user = database.find_user(user_id)?;
    
    let data = user.preferences
        .get("theme")
        .ok_or(AppError::MissingPreference("theme"))?;
    
    Ok(Response::new(data))
}

// Option 2: expect() for invariants (not user input)
fn get_config_value(&self, key: &str) -> &str {
    self.config
        .get(key)
        .expect("BUG: required config key missing after validation")
}

// Option 3: Provide defaults
fn get_theme(user: &User) -> &str {
    user.preferences
        .get("theme")
        .unwrap_or(&"default")
}

// Option 4: Match for complex handling
fn process_optional(value: Option<Data>) -> ProcessedData {
    match value {
        Some(data) => process(data),
        None => {
            log::warn!("No data provided, using fallback");
            ProcessedData::default()
        }
    }
}
```

### `expect()` vs `unwrap()`

```rust
// Bad: no context
let port = config.get("port").unwrap();

// Better: explains the invariant
let port = config.get("port")
    .expect("config must contain 'port' after validation");

// Best: propagate if it's not truly an invariant
let port = config.get("port")
    .ok_or_else(|| ConfigError::MissingKey("port"))?;
```

### Alternatives to unwrap()

| Situation | Use Instead |
|-----------|-------------|
| Can propagate error | `?` operator |
| Has sensible default | `unwrap_or()`, `unwrap_or_default()` |
| Default requires computation | `unwrap_or_else(\|\| ...)` |
| Internal invariant | `expect("explanation")` |
| Need to handle both cases | `match` or `if let` |

### Clippy Lints

```toml
# Cargo.toml
[lints.clippy]
unwrap_used = "warn"      # Warn on unwrap()
expect_used = "warn"       # Also warn on expect() (stricter)
```

```rust
// Allow in specific places where it's justified
#[allow(clippy::unwrap_used)]
fn definitely_safe() {
    // Unwrap is safe here because...
    let x = Some(5).unwrap();
}
```

Related: `err-result-over-panic`, `err-expect-bugs-only`, `anti-unwrap-abuse`

## err-expect-bugs-only

> Use `expect()` only for invariants that indicate bugs, not user errors

### Why It Matters

`expect()` is better than `unwrap()` because it provides context, but it still panics. Reserve it for situations where failure indicates a bug in your code—a violated invariant, not a user error or external failure. The message should explain why the invariant should hold, helping future developers understand and fix the bug.

### Bad

```rust
// User input can legitimately fail - don't expect
fn parse_user_input(input: &str) -> Config {
    serde_json::from_str(input)
        .expect("Invalid JSON")  // User error, not a bug!
}

// Network can fail - don't expect
fn fetch_data(url: &str) -> Data {
    reqwest::get(url)
        .expect("Network request failed")  // External failure!
        .json()
        .expect("Invalid response")
}

// File might not exist - don't expect
fn load_config() -> Config {
    let content = fs::read_to_string("config.json")
        .expect("Config file missing");  // Environment issue!
}
```

### Good

```rust
// Invariant: after insert, key exists
fn cache_and_get(&mut self, key: String, value: Value) -> &Value {
    self.cache.insert(key.clone(), value);
    self.cache.get(&key)
        .expect("BUG: key must exist immediately after insert")
}

// Invariant: regex is compile-time constant
fn create_parser() -> Regex {
    Regex::new(r"^\d{4}-\d{2}-\d{2}$")
        .expect("BUG: date regex is invalid - this is a compile-time constant")
}

// Invariant: already validated
fn process_validated(data: ValidatedData) -> Result<Output, ProcessError> {
    let value = data.required_field
        .expect("BUG: ValidatedData guarantees required_field is Some");
    // ...
}

// Invariant: type system guarantees
fn get_first<T>(vec: Vec<T>) -> T 
where 
    Vec<T>: NonEmpty,  // Hypothetical trait
{
    vec.into_iter().next()
        .expect("BUG: NonEmpty Vec cannot be empty")
}
```

### expect() Message Guidelines

Messages should:
1. Start with "BUG:" or similar to indicate it's an invariant
2. Explain WHY the invariant should hold
3. Help developers fix the issue

```rust
// ❌ Bad messages
.expect("failed")                    // No context
.expect("should not be None")        // Doesn't explain why
.expect("Invalid state")             // Vague

// ✅ Good messages
.expect("BUG: HashMap entry exists after insert")
.expect("BUG: validated input must parse - validation is broken")
.expect("BUG: static regex compilation failed - regex syntax error in source")
```

### Pattern: Validate Once, expect() After

```rust
struct ValidatedEmail(String);

impl ValidatedEmail {
    pub fn new(email: &str) -> Result<Self, EmailError> {
        // Validation happens here, returns Result
        if !is_valid_email(email) {
            return Err(EmailError::Invalid);
        }
        Ok(ValidatedEmail(email.to_string()))
    }
    
    pub fn domain(&self) -> &str {
        // After validation, expect() is fine
        self.0.split('@').nth(1)
            .expect("BUG: ValidatedEmail must contain @")
    }
}
```

### Alternatives When expect() Is Wrong

```rust
// Don't: expect on user data
let port: u16 = input.parse().expect("Invalid port");

// Do: Return Result
let port: u16 = input.parse().map_err(|_| ConfigError::InvalidPort)?;

// Do: Provide default
let port: u16 = input.parse().unwrap_or(8080);

// Do: Handle explicitly
let port: u16 = match input.parse() {
    Ok(p) => p,
    Err(_) => {
        log::warn!("Invalid port '{}', using default", input);
        8080
    }
};
```

Related: `err-no-unwrap-prod`, `err-result-over-panic`, `api-parse-dont-validate`
