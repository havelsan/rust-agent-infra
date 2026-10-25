---
name: rust-04-errors-2of2
description: Rust rules module 04: Error Handling (part 2 of 2). 6 rules, priority CRITICAL. Load on its own to review or write Rust code against this topic only. Rule prefixes: `err-`
---

# Error Handling (part 2/2)

Priority: CRITICAL. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `err-question-mark` - Use `?` operator for clean propagation
- `err-from-impl` - Implement `From<E>` for error conversions to enable `?` operator
- `err-source-chain` - Preserve error chains with `#[source]` or `source()` method
- `err-lowercase-msg` - Start error messages lowercase, no trailing punctuation
- `err-doc-errors` - Document error conditions with `# Errors` section in doc comments
- `err-custom-type` - Define custom error types for domain-specific failures

---

## err-question-mark

> Use `?` operator for clean propagation

### Why It Matters

The `?` operator is Rust's idiomatic way to propagate errors. It's concise, readable, and automatically converts between compatible error types using `From`. It replaces verbose `match` or `unwrap()` calls.

### Bad

```rust
// Verbose match-based error handling
fn load_config() -> Result<Config, Error> {
    let content = match std::fs::read_to_string("config.toml") {
        Ok(c) => c,
        Err(e) => return Err(Error::Io(e)),
    };
    
    let config = match toml::from_str(&content) {
        Ok(c) => c,
        Err(e) => return Err(Error::Parse(e)),
    };
    
    Ok(config)
}

// Or worse - using unwrap
fn load_config_bad() -> Config {
    let content = std::fs::read_to_string("config.toml").unwrap();
    toml::from_str(&content).unwrap()
}
```

### Good

```rust
fn load_config() -> Result<Config, Error> {
    let content = std::fs::read_to_string("config.toml")?;
    let config = toml::from_str(&content)?;
    Ok(config)
}

// Even more concise
fn load_config() -> Result<Config, Error> {
    Ok(toml::from_str(&std::fs::read_to_string("config.toml")?)?)
}
```

### How ? Works

```rust
// This:
let x = expr?;

// Expands roughly to:
let x = match expr {
    Ok(val) => val,
    Err(err) => return Err(From::from(err)),
};
```

### Combining with Context

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let path = format!("users/{}.json", id);
    
    let content = std::fs::read_to_string(&path)
        .with_context(|| format!("failed to read user file: {}", path))?;
    
    let user: User = serde_json::from_str(&content)
        .context("failed to parse user JSON")?;
    
    Ok(user)
}
```

### ? with Option

```rust
fn get_first_word(text: &str) -> Option<&str> {
    let first_line = text.lines().next()?;
    let first_word = first_line.split_whitespace().next()?;
    Some(first_word)
}

// Convert Option to Result
fn get_required_config(key: &str) -> Result<String, Error> {
    config.get(key)
        .cloned()
        .ok_or_else(|| Error::MissingConfig(key.to_string()))
}
```

### Error Type Conversion

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum MyError {
    #[error("io error")]
    Io(#[from] std::io::Error),  // Auto From impl
    
    #[error("parse error")]
    Parse(#[from] serde_json::Error),  // Auto From impl
}

fn process() -> Result<(), MyError> {
    // ? automatically converts io::Error to MyError via From
    let content = std::fs::read_to_string("file.txt")?;
    
    // ? automatically converts serde_json::Error to MyError
    let data: Data = serde_json::from_str(&content)?;
    
    Ok(())
}
```

### In main()

```rust
// Option 1: Return Result from main
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}

// Option 2: Handle in main, exit on error
fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {:#}", e);
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<()> {
    let config = load_config()?;
    run_app(config)?;
    Ok(())
}
```

Related: `err-context-chain`, `err-from-impl`, `err-anyhow-app`

## err-from-impl

> Implement `From<E>` for error conversions to enable `?` operator

### Why It Matters

The `?` operator automatically converts errors using `From` trait. By implementing `From<SourceError> for YourError`, you enable seamless error propagation without explicit `.map_err()` calls. This makes error handling code cleaner and ensures consistent error wrapping throughout your codebase.

### Bad

```rust
#[derive(Debug)]
enum AppError {
    Io(std::io::Error),
    Parse(serde_json::Error),
    Database(diesel::result::Error),
}

fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| AppError::Io(e))?;  // Manual conversion everywhere
    
    let config: Config = serde_json::from_str(&content)
        .map_err(|e| AppError::Parse(e))?;  // Repeated boilerplate
    
    save_to_db(&config)
        .map_err(|e| AppError::Database(e))?;  // Gets tedious
    
    Ok(config)
}
```

### Good

```rust
#[derive(Debug)]
enum AppError {
    Io(std::io::Error),
    Parse(serde_json::Error),
    Database(diesel::result::Error),
}

// Implement From for each source error type
impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        AppError::Io(err)
    }
}

impl From<serde_json::Error> for AppError {
    fn from(err: serde_json::Error) -> Self {
        AppError::Parse(err)
    }
}

impl From<diesel::result::Error> for AppError {
    fn from(err: diesel::result::Error) -> Self {
        AppError::Database(err)
    }
}

fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)?;  // Auto-converts
    let config: Config = serde_json::from_str(&content)?;  // Clean!
    save_to_db(&config)?;
    Ok(config)
}
```

### Use thiserror for Automatic From

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum AppError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),  // Auto-generates From impl
    
    #[error("Parse error: {0}")]
    Parse(#[from] serde_json::Error),  // #[from] does the work
    
    #[error("Database error: {0}")]
    Database(#[from] diesel::result::Error),
}

// Now ? just works
fn load_config(path: &str) -> Result<Config, AppError> {
    let content = std::fs::read_to_string(path)?;
    let config: Config = serde_json::from_str(&content)?;
    save_to_db(&config)?;
    Ok(config)
}
```

### From with Context

Sometimes you need to add context during conversion:

```rust
#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config from '{path}': {source}")]
    ReadFailed {
        path: String,
        #[source]
        source: std::io::Error,
    },
}

// Can't use #[from] when you need extra context
fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|source| ConfigError::ReadFailed {
            path: path.to_string(),
            source,
        })?;
    // ...
}

// Or use anyhow for ad-hoc context
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read config from '{}'", path))?;
    // ...
}
```

### Blanket From Implementations

Be careful with blanket implementations:

```rust
// ❌ Too broad - conflicts with other From impls
impl<E: std::error::Error> From<E> for AppError {
    fn from(err: E) -> Self {
        AppError::Other(err.to_string())
    }
}

// ✅ Specific implementations
impl From<std::io::Error> for AppError { ... }
impl From<ParseIntError> for AppError { ... }
```

Related: `err-thiserror-lib`, `err-source-chain`, `err-question-mark`, `conv-tryfrom-fallible`

## err-source-chain

> Preserve error chains with `#[source]` or `source()` method

### Why It Matters

Errors often have underlying causes. Preserving the error chain (via `source()` method) allows logging frameworks and error reporters to show the full context: "config parse failed → JSON syntax error at line 5 → unexpected token". Without chaining, you lose valuable debugging information.

### Bad

```rust
#[derive(Debug)]
enum ConfigError {
    ParseFailed(String),  // Lost the original serde_json::Error
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|e| ConfigError::ParseFailed(e.to_string()))?;  // Chain lost!
    
    serde_json::from_str(&content)
        .map_err(|e| ConfigError::ParseFailed(e.to_string()))?  // No source
}

// Error output: "Parse failed: invalid type: ..."
// Missing: which file? what line? what was the parent error?
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file '{path}'")]
    ReadFailed {
        path: String,
        #[source]  // Preserves the error chain
        source: std::io::Error,
    },
    
    #[error("Failed to parse config file '{path}'")]
    ParseFailed {
        path: String,
        #[source]  // Original parse error preserved
        source: serde_json::Error,
    },
}

fn load_config(path: &str) -> Result<Config, ConfigError> {
    let content = std::fs::read_to_string(path)
        .map_err(|source| ConfigError::ReadFailed {
            path: path.to_string(),
            source,  // Chain preserved
        })?;
    
    serde_json::from_str(&content)
        .map_err(|source| ConfigError::ParseFailed {
            path: path.to_string(),
            source,
        })
}
```

### Manual source() Implementation

```rust
use std::error::Error;

#[derive(Debug)]
struct MyError {
    message: String,
    source: Option<Box<dyn Error + Send + Sync>>,
}

impl std::fmt::Display for MyError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.message)
    }
}

impl Error for MyError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        self.source.as_ref().map(|e| e.as_ref() as &(dyn Error + 'static))
    }
}
```

### Walking the Error Chain

```rust
fn print_error_chain(error: &dyn std::error::Error) {
    eprintln!("Error: {}", error);
    
    let mut source = error.source();
    while let Some(err) = source {
        eprintln!("Caused by: {}", err);
        source = err.source();
    }
}

// With anyhow, use {:?} for full chain
let result: anyhow::Result<()> = do_something();
if let Err(e) = result {
    eprintln!("{:?}", e);  // Prints full chain with backtraces
}
```

### anyhow Context

```rust
use anyhow::{Context, Result};

fn load_config(path: &str) -> Result<Config> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("Failed to read '{}'", path))?;
    
    let config: Config = serde_json::from_str(&content)
        .with_context(|| format!("Failed to parse '{}'", path))?;
    
    Ok(config)
}

// Output:
// Error: Failed to parse 'config.json'
// Caused by: expected `:` at line 5 column 10
```

### #[from] vs #[source]

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum MyError {
    // #[from] = implements From + sets source
    #[error("IO error")]
    Io(#[from] std::io::Error),
    
    // #[source] = only sets source (no From impl)
    #[error("Parse error in file '{path}'")]
    Parse {
        path: String,
        #[source]
        source: serde_json::Error,
    },
}
```

Related: `err-thiserror-lib`, `err-context-chain`, `err-from-impl`

## err-lowercase-msg

> Start error messages lowercase, no trailing punctuation

### Why It Matters

Error messages are often chained, logged, or displayed with additional context. Consistent formatting—lowercase start, no trailing period—allows clean composition: "failed to load config: invalid JSON: unexpected token". Mixed case and punctuation create awkward output: "Failed to load config.: Invalid JSON.: Unexpected token.".

### Bad

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("Failed to read config file.")]  // Capital F, trailing period
    ReadFailed(#[from] std::io::Error),
    
    #[error("Invalid JSON format!")]  // Capital I, exclamation
    ParseFailed(#[from] serde_json::Error),
    
    #[error("The requested key was not found")]  // Reads like a sentence
    KeyNotFound(String),
}

// Chained output: "Config load error: Failed to read config file.: No such file"
// Awkward capitalization and punctuation
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ConfigError {
    #[error("failed to read config file")]  // lowercase, no period
    ReadFailed(#[from] std::io::Error),
    
    #[error("invalid JSON format")]  // lowercase, no period
    ParseFailed(#[from] serde_json::Error),
    
    #[error("key not found: {0}")]  // lowercase, data at end
    KeyNotFound(String),
}

// Chained output: "config load error: failed to read config file: no such file"
// Clean, consistent
```

### Rust Standard Library Convention

The standard library follows this convention:

```rust
// std::io::Error messages
"entity not found"
"permission denied"
"connection refused"

// std::num::ParseIntError
"invalid digit found in string"

// std::str::Utf8Error  
"invalid utf-8 sequence"
```

### Formatting Guidelines

| Do | Don't |
|----|-------|
| `"failed to parse config"` | `"Failed to parse config."` |
| `"invalid input: expected number"` | `"Invalid input - expected a number!"` |
| `"connection timed out after {0}s"` | `"Connection Timed Out After {0} seconds."` |
| `"key '{0}' not found"` | `"Key Not Found: {0}"` |

### Context Addition Pattern

```rust
use anyhow::{Context, Result};

fn load_user(id: u64) -> Result<User> {
    let data = fetch(id)
        .with_context(|| format!("failed to fetch user {}", id))?;
    
    parse_user(data)
        .with_context(|| "failed to parse user data")?
}

// Output: "failed to fetch user 42: connection refused"
// All lowercase, clean chain
```

### Display vs Debug

```rust
#[derive(Error, Debug)]
#[error("invalid configuration")]  // Display: for users/logs
pub struct ConfigError {
    path: PathBuf,
    source: io::Error,
}

// Debug output (for developers) can have more detail
// Display output (for users) should be clean
```

### When to Use Capitals

```rust
// Proper nouns / acronyms keep their case
#[error("invalid JSON syntax")]     // JSON is an acronym
#[error("OAuth token expired")]     // OAuth is a proper noun
#[error("HTTP request failed")]     // HTTP is an acronym

// Error codes can be uppercase
#[error("error code E0001: invalid input")]
```

Related: `err-thiserror-lib`, `err-context-chain`, `doc-examples-section`

## err-doc-errors

> Document error conditions with `# Errors` section in doc comments

### Why It Matters

Users of your API need to know what can go wrong and why. The `# Errors` documentation section is the standard Rust convention for describing when a function returns `Err`. Good error documentation helps callers handle errors appropriately and understand the contract of your API.

### Bad

```rust
/// Loads a configuration from the specified path.
pub fn load_config(path: &Path) -> Result<Config, ConfigError> {
    // No documentation of error conditions
    // Caller must read source code to understand what can fail
}

/// Parses and validates the input string.
/// 
/// Returns the parsed value.  // What about errors?
pub fn parse_input(input: &str) -> Result<Value, ParseError> {
    // ...
}
```

### Good

```rust
/// Loads a configuration from the specified path.
///
/// # Errors
///
/// Returns an error if:
/// - The file at `path` does not exist or cannot be read
/// - The file contents are not valid TOML
/// - Required configuration keys are missing
/// - Configuration values are out of valid ranges
///
/// # Examples
///
/// ```
/// # use mylib::{load_config, ConfigError};
/// # fn main() -> Result<(), ConfigError> {
/// let config = load_config("app.toml")?;
/// # Ok(())
/// # }
/// ```
pub fn load_config(path: &Path) -> Result<Config, ConfigError> {
    // ...
}

/// Parses and validates the input string as a positive integer.
///
/// # Errors
///
/// Returns [`ParseError::Empty`] if the input is empty.
/// Returns [`ParseError::InvalidFormat`] if the input contains non-digit characters.
/// Returns [`ParseError::Overflow`] if the value exceeds `i64::MAX`.
/// Returns [`ParseError::NotPositive`] if the value is zero or negative.
pub fn parse_positive_int(input: &str) -> Result<i64, ParseError> {
    // ...
}
```

### Linking to Error Variants

```rust
/// Attempts to connect to the database.
///
/// # Errors
///
/// This function will return an error if:
///
/// - [`DbError::ConnectionFailed`] - The database server is unreachable
/// - [`DbError::AuthenticationFailed`] - Invalid credentials
/// - [`DbError::Timeout`] - Connection attempt exceeded timeout
/// - [`DbError::TlsError`] - TLS handshake failed
///
/// See [`DbError`] for more details on each variant.
pub fn connect(config: &DbConfig) -> Result<Connection, DbError> {
    // ...
}
```

### Panic vs Error Documentation

```rust
/// Divides two numbers.
///
/// # Errors
///
/// Returns [`MathError::DivisionByZero`] if `divisor` is zero.
///
/// # Panics
///
/// Panics if called from a non-main thread (debug builds only).
pub fn divide(dividend: i64, divisor: i64) -> Result<i64, MathError> {
    // ...
}
```

### Error Section Format Options

```rust
// Style 1: Bullet list (good for multiple conditions)
/// # Errors
///
/// Returns an error if:
/// - The file does not exist
/// - The file cannot be read
/// - The content is invalid UTF-8

// Style 2: Returns statements (good for mapping to variants)
/// # Errors
///
/// Returns [`Error::NotFound`] if the item doesn't exist.
/// Returns [`Error::PermissionDenied`] if access is forbidden.

// Style 3: Prose (good for complex conditions)
/// # Errors
///
/// This function returns an error when the input fails validation.
/// Validation includes checking that all required fields are present,
/// that numeric fields are within allowed ranges, and that string
/// fields match their expected formats.
```

### Clippy Lint

```toml
# Cargo.toml - require error documentation
[lints.clippy]
missing_errors_doc = "warn"
```

```rust
// This will warn without # Errors section
pub fn might_fail() -> Result<(), Error> { Ok(()) }
```

Related: `doc-examples-section`, `err-thiserror-lib`, `api-must-use`

## err-custom-type

> Define custom error types for domain-specific failures

### Why It Matters

Generic errors like `String`, `Box<dyn Error>`, or catch-all enums obscure what can actually go wrong. Custom error types document failure modes in the type system, enable pattern matching for specific handling, and provide clear API contracts. They make your code self-documenting and help callers handle errors appropriately.

### Bad

```rust
// Generic string errors - no structure
fn validate_user(user: &User) -> Result<(), String> {
    if user.name.is_empty() {
        return Err("Name is empty".to_string());
    }
    if user.age > 150 {
        return Err("Age is invalid".to_string());
    }
    Ok(())
}

// Caller can't match on specific errors
match validate_user(&user) {
    Ok(()) => save(user),
    Err(msg) => {
        // Can only do string comparison - fragile!
        if msg.contains("Name") {
            prompt_for_name()
        }
    }
}
```

### Good

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ValidationError {
    #[error("name cannot be empty")]
    EmptyName,
    
    #[error("name exceeds maximum length of {max} characters")]
    NameTooLong { max: usize, actual: usize },
    
    #[error("invalid age {0}: must be between 0 and 150")]
    InvalidAge(u8),
    
    #[error("email format is invalid: {0}")]
    InvalidEmail(String),
}

fn validate_user(user: &User) -> Result<(), ValidationError> {
    if user.name.is_empty() {
        return Err(ValidationError::EmptyName);
    }
    if user.name.len() > 100 {
        return Err(ValidationError::NameTooLong { 
            max: 100, 
            actual: user.name.len() 
        });
    }
    if user.age > 150 {
        return Err(ValidationError::InvalidAge(user.age));
    }
    Ok(())
}

// Caller can match specifically
match validate_user(&user) {
    Ok(()) => save(user),
    Err(ValidationError::EmptyName) => prompt_for_name(),
    Err(ValidationError::InvalidAge(age)) => {
        show_error(&format!("Please enter a valid age (you entered {})", age))
    }
    Err(e) => show_error(&e.to_string()),
}
```

### Error Type Design Guidelines

```rust
// 1. Group related errors in domain-specific enums
#[derive(Error, Debug)]
pub enum AuthError {
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("account locked after {attempts} failed attempts")]
    AccountLocked { attempts: u32 },
    #[error("token expired")]
    TokenExpired,
}

#[derive(Error, Debug)]
pub enum PaymentError {
    #[error("insufficient funds: need {required}, have {available}")]
    InsufficientFunds { required: Decimal, available: Decimal },
    #[error("card declined: {reason}")]
    CardDeclined { reason: String },
}

// 2. Include relevant data for error handling/display
#[derive(Error, Debug)]
pub enum FileError {
    #[error("file not found: {path}")]
    NotFound { path: PathBuf },
    #[error("permission denied for {path}")]
    PermissionDenied { path: PathBuf },
}

// 3. Consider #[non_exhaustive] for public APIs
#[derive(Error, Debug)]
#[non_exhaustive]  // Allows adding variants without breaking changes
pub enum ApiError {
    #[error("rate limited")]
    RateLimited,
    #[error("not found")]
    NotFound,
}
```

### When to Use What

| Error Pattern | Use Case |
|---------------|----------|
| Custom enum | Library with specific failure modes |
| `thiserror` | Libraries needing `std::error::Error` |
| `anyhow::Error` | Applications, prototypes |
| Struct with source | Single error type with wrapped cause |

### Struct-Based Errors

For single error types with rich context:

```rust
#[derive(Error, Debug)]
#[error("query failed for table '{table}' with filter '{filter}'")]
pub struct QueryError {
    pub table: String,
    pub filter: String,
    #[source]
    pub source: DatabaseError,
}
```

Related: `err-thiserror-lib`, `err-anyhow-app`, `api-non-exhaustive`
