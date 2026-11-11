---
name: rust-10-api-design-2of3
description: Rust rules module 10: API Design (part 2 of 3). 6 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `api-`
---

# API Design (part 2/3)

Priority: HIGH. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `api-extension-trait` - Use extension traits to add methods to external types
- `api-parse-dont-validate` - Parse into validated types at boundaries
- `api-impl-into` - Accept `impl Into<T>` for flexible APIs, implement `From<T>` for conversions
- `api-impl-asref` - Use `AsRef<T>` when you only need to borrow the inner data
- `api-must-use` - Mark types and functions with `#[must_use]` when ignoring results is likely a bug
- `api-non-exhaustive` - Use `#[non_exhaustive]` on public enums and structs for forward compatibility

---

## api-extension-trait

> Use extension traits to add methods to external types

### Why It Matters

Rust's orphan rules prevent implementing external traits on external types. Extension traits provide a workaround: define a new trait with your methods, then implement it for the external type. This pattern is used extensively in the ecosystem (e.g., `itertools::Itertools`, `tokio::AsyncReadExt`).

### Bad

```rust
// Can't add methods directly to external types
impl Vec<u8> {
    fn as_hex(&self) -> String {
        // Error: cannot define inherent impl for a type outside this crate
    }
}

// Can't implement external trait for external type
impl SomeExternalTrait for Vec<u8> {
    // Error: orphan rules violation
}
```

### Good

```rust
// Define an extension trait
pub trait ByteSliceExt {
    fn as_hex(&self) -> String;
    fn is_ascii_printable(&self) -> bool;
}

// Implement for the external type
impl ByteSliceExt for [u8] {
    fn as_hex(&self) -> String {
        self.iter()
            .map(|b| format!("{:02x}", b))
            .collect()
    }
    
    fn is_ascii_printable(&self) -> bool {
        self.iter().all(|b| b.is_ascii_graphic() || b.is_ascii_whitespace())
    }
}

// Usage: import the trait to use the methods
use my_crate::ByteSliceExt;

let data: &[u8] = b"hello";
println!("{}", data.as_hex());  // "68656c6c6f"
```

### Convention: Ext Suffix

```rust
// Standard naming: TypeExt for extending Type
pub trait OptionExt<T> {
    fn unwrap_or_log(self, msg: &str) -> Option<T>;
}

impl<T> OptionExt<T> for Option<T> {
    fn unwrap_or_log(self, msg: &str) -> Option<T> {
        if self.is_none() {
            log::warn!("{}", msg);
        }
        self
    }
}

// For generic extensions
pub trait ResultExt<T, E> {
    fn log_err(self) -> Self;
}

impl<T, E: std::fmt::Display> ResultExt<T, E> for Result<T, E> {
    fn log_err(self) -> Self {
        if let Err(ref e) = self {
            log::error!("{}", e);
        }
        self
    }
}
```

### Ecosystem Examples

```rust
// itertools::Itertools
use itertools::Itertools;
let groups = vec![1, 1, 2, 2, 3].into_iter().group_by(|x| *x);

// futures::StreamExt
use futures::StreamExt;
let next = stream.next().await;

// tokio::io::AsyncReadExt
use tokio::io::AsyncReadExt;
let mut buf = [0u8; 1024];
reader.read(&mut buf).await?;

// anyhow::Context
use anyhow::Context;
let content = std::fs::read_to_string(path)
    .with_context(|| format!("failed to read {}", path))?;
```

### Scoped Extensions

```rust
// Extension only visible where imported
mod string_utils {
    pub trait StringExt {
        fn truncate_ellipsis(&self, max_len: usize) -> String;
    }
    
    impl StringExt for str {
        fn truncate_ellipsis(&self, max_len: usize) -> String {
            if self.len() <= max_len {
                self.to_string()
            } else {
                format!("{}...", &self[..max_len.saturating_sub(3)])
            }
        }
    }
}

// Only available when explicitly imported
use string_utils::StringExt;
let short = "very long string".truncate_ellipsis(10);
```

### Generic Extensions with Bounds

```rust
pub trait VecExt<T> {
    fn push_if_unique(&mut self, item: T)
    where
        T: PartialEq;
}

impl<T> VecExt<T> for Vec<T> {
    fn push_if_unique(&mut self, item: T)
    where
        T: PartialEq,
    {
        if !self.contains(&item) {
            self.push(item);
        }
    }
}

// Works with any T: PartialEq
let mut v = vec![1, 2, 3];
v.push_if_unique(2);  // No-op
v.push_if_unique(4);  // Adds 4
```

Related: `api-sealed-trait`, `api-impl-into`, `name-as-free`, `trait-blanket-impl`

## api-parse-dont-validate

> Parse into validated types at boundaries

### Why It Matters

Instead of validating data and hoping you remember to check everywhere, parse it into a type that can only be constructed from valid data. The type system then guarantees validity - you can't forget to validate because invalid states are unrepresentable.

### Bad

```rust
// Validation scattered throughout codebase
fn send_email(email: &str) -> Result<(), Error> {
    // Did someone validate this already? Who knows!
    if !is_valid_email(email) {
        return Err(Error::InvalidEmail);
    }
    // Send email...
}

fn add_to_mailing_list(email: &str) -> Result<(), Error> {
    // Duplicate validation, or did we forget?
    if !is_valid_email(email) {
        return Err(Error::InvalidEmail);
    }
    // Add to list...
}

// Easy to forget validation
fn process_user_email(email: &str) {
    // Oops, no validation!
    database.store_email(email);
}
```

### Good

```rust
/// A validated email address.
/// Can only be constructed via `Email::parse()`.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Email(String);

impl Email {
    /// Parses and validates an email address.
    pub fn parse(s: impl Into<String>) -> Result<Self, EmailError> {
        let s = s.into();
        if Self::is_valid(&s) {
            Ok(Email(s))
        } else {
            Err(EmailError::Invalid)
        }
    }
    
    fn is_valid(s: &str) -> bool {
        s.contains('@') && s.len() > 3  // Simplified
    }
    
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// Now functions can accept Email - guaranteed valid!
fn send_email(email: &Email) -> Result<(), Error> {
    // No validation needed - Email is always valid
    smtp_send(email.as_str())
}

fn add_to_mailing_list(email: Email) {
    // No validation needed
    list.push(email);
}
```

### More Examples

```rust
// Port number (1-65535)
pub struct Port(u16);

impl Port {
    pub fn new(n: u16) -> Option<Self> {
        if n > 0 { Some(Port(n)) } else { None }
    }
    
    pub fn get(&self) -> u16 {
        self.0
    }
}

// Non-empty string
pub struct NonEmptyString(String);

impl NonEmptyString {
    pub fn new(s: impl Into<String>) -> Option<Self> {
        let s = s.into();
        if s.is_empty() { None } else { Some(Self(s)) }
    }
}

// Positive integer
pub struct PositiveI32(i32);

impl PositiveI32 {
    pub fn new(n: i32) -> Option<Self> {
        if n > 0 { Some(Self(n)) } else { None }
    }
}

// Bounded value
pub struct Percentage(u8);

impl Percentage {
    pub fn new(n: u8) -> Option<Self> {
        if n <= 100 { Some(Self(n)) } else { None }
    }
}
```

### Parsing at Boundaries

```rust
// Parse at the system boundary (API, CLI, config file)
fn handle_request(raw: RawRequest) -> Result<Response, Error> {
    // Parse ALL inputs upfront
    let email = Email::parse(&raw.email)?;
    let age = Age::parse(raw.age)?;
    let username = Username::parse(&raw.username)?;
    
    // Now work with validated types
    process_user(email, age, username)
}

fn process_user(email: Email, age: Age, username: Username) {
    // All inputs guaranteed valid - no checks needed
}
```

### Evidence from sqlx

```rust
// sqlx parses SQL at compile time, ensuring query validity
// https://github.com/launchbadge/sqlx/blob/master/src/macros/mod.rs

// The query! macro parses and validates SQL
let user = sqlx::query!("SELECT * FROM users WHERE id = ?", id)
    .fetch_one(&pool)
    .await?;

// If SQL is invalid, compilation fails - invalid state unrepresentable
```

### Combining with Display

```rust
use std::fmt;

pub struct Email(String);

impl Email {
    pub fn parse(s: &str) -> Result<Self, EmailError> { ... }
}

// Implement Display for easy printing
impl fmt::Display for Email {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

// Implement AsRef for easy borrowing
impl AsRef<str> for Email {
    fn as_ref(&self) -> &str {
        &self.0
    }
}
```

Related: `api-newtype-safety`, `type-newtype-validated`, `api-typestate`, `conv-tryfrom-fallible`, `serde-try-from-validate`

## api-impl-into

> Accept `impl Into<T>` for flexible APIs, implement `From<T>` for conversions

### Why It Matters

APIs that accept `impl Into<T>` are ergonomic—callers can pass the target type directly or any type that converts to it. This reduces boilerplate `.into()` calls at call sites. Implement `From<T>` rather than `Into<T>` because `From` implies `Into` through a blanket implementation.

### Bad

```rust
// Requires exact type - forces callers to convert
fn process_path(path: PathBuf) { ... }
fn set_name(name: String) { ... }

// Caller must convert explicitly
process_path(PathBuf::from("/path/to/file"));
process_path("/path/to/file".to_path_buf());  // Verbose
process_path("/path/to/file".into());          // Explicit

set_name(String::from("Alice"));
set_name("Alice".to_string());  // Verbose
```

### Good

```rust
// Accept anything that converts to the target type
fn process_path(path: impl Into<PathBuf>) {
    let path = path.into();  // Convert once inside
    // ...
}

fn set_name(name: impl Into<String>) {
    let name = name.into();
    // ...
}

// Callers are ergonomic
process_path("/path/to/file");    // &str converts automatically
process_path(PathBuf::from(".")); // PathBuf works too

set_name("Alice");                // &str
set_name(String::from("Alice"));  // String
set_name(format!("User-{}", id)); // String from format!
```

### Implement From, Not Into

```rust
struct UserId(u64);

// ✅ Implement From
impl From<u64> for UserId {
    fn from(id: u64) -> Self {
        UserId(id)
    }
}

// Into is automatically provided by blanket impl
let id: UserId = 42u64.into();  // Works!

// ❌ Don't implement Into directly
impl Into<UserId> for u64 {
    fn into(self) -> UserId {
        UserId(self)  // This works but is non-idiomatic
    }
}
```

### Common Conversions

```rust
// String-like types
fn log_message(msg: impl Into<String>) { ... }
log_message("literal");           // &str
log_message(String::from("own")); // String
log_message(Cow::from("cow"));    // Cow<str>

// Path-like types  
fn read_file(path: impl AsRef<Path>) { ... }  // AsRef for borrowed access
fn write_file(path: impl Into<PathBuf>) { ... }  // Into when storing

// Duration
fn set_timeout(duration: impl Into<Duration>) { ... }
set_timeout(Duration::from_secs(5));
// Note: no blanket impl for integers, would need custom wrapper
```

### AsRef vs Into

```rust
// AsRef<T>: borrow as &T, no conversion cost
fn count_bytes(data: impl AsRef<[u8]>) -> usize {
    data.as_ref().len()  // Just borrows, no allocation
}
count_bytes("hello");  // &str -> &[u8]
count_bytes(b"hello"); // &[u8] -> &[u8]
count_bytes(vec![1, 2, 3]);  // &Vec<u8> -> &[u8]

// Into<T>: convert to owned T, may allocate
fn store_data(data: impl Into<Vec<u8>>) {
    let owned: Vec<u8> = data.into();  // Takes ownership
    // ...
}
```

### When NOT to Use impl Into

```rust
// ❌ Trait objects need Sized
fn process(handler: impl Into<Box<dyn Handler>>) { }
// Better: just take Box<dyn Handler> directly

// ❌ Recursive types
struct Node {
    children: Vec<impl Into<Node>>,  // Error: impl Trait not allowed here
}

// ❌ Performance-critical hot paths (minor overhead of trait dispatch)
fn hot_path(value: impl Into<u64>) {
    // Consider taking u64 directly if called billions of times
}

// ❌ When you need to name the type
fn returns_impl() -> impl Into<String> { }  // Opaque, hard to use
```

### Builder Pattern with Into

```rust
struct Config {
    name: String,
    path: PathBuf,
}

impl Config {
    fn new(name: impl Into<String>) -> Self {
        Config {
            name: name.into(),
            path: PathBuf::new(),
        }
    }
    
    fn path(mut self, path: impl Into<PathBuf>) -> Self {
        self.path = path.into();
        self
    }
}

// Clean builder calls
let config = Config::new("myapp")
    .path("/etc/myapp");
```

Related: `api-impl-asref`, `api-from-not-into`, `err-from-impl`

## api-impl-asref

> Use `AsRef<T>` when you only need to borrow the inner data

### Why It Matters

`AsRef<T>` provides a cheap borrowed view of data without taking ownership or copying. Functions accepting `impl AsRef<T>` can work with multiple types that contain or represent `T`, making APIs flexible while avoiding unnecessary allocations. Use `AsRef` when you only need to read, `Into` when you need to own.

### Bad

```rust
// Forces callers to provide exact types
fn process_text(text: &str) { ... }
fn read_file(path: &Path) { ... }

// Can't call directly with owned types
let s = String::from("hello");
process_text(&s);  // Works but verbose

let p = PathBuf::from("/file");
read_file(&p);  // Works but verbose
read_file("/file");  // Error! &str != &Path
```

### Good

```rust
// Accept anything that can be viewed as the target type
fn process_text(text: impl AsRef<str>) {
    let s: &str = text.as_ref();
    println!("{}", s);
}

fn read_file(path: impl AsRef<Path>) -> io::Result<Vec<u8>> {
    std::fs::read(path.as_ref())
}

// All of these work:
process_text("literal");        // &str
process_text(String::from("owned"));  // String
process_text(Cow::from("cow")); // Cow<str>

read_file("/path/to/file");     // &str  
read_file(Path::new("/path"));  // &Path
read_file(PathBuf::from("/path")); // PathBuf
read_file(OsStr::new("/path")); // &OsStr
```

### AsRef vs Into vs Borrow

```rust
// AsRef<T>: cheap borrow, no ownership transfer
fn read(p: impl AsRef<Path>) {
    let path: &Path = p.as_ref();
}

// Into<T>: ownership transfer, may allocate
fn store(p: impl Into<PathBuf>) {
    let owned: PathBuf = p.into();
}

// Borrow<T>: like AsRef but with Eq/Hash consistency guarantee
use std::borrow::Borrow;
fn lookup<Q: ?Sized>(map: &HashMap<String, V>, key: &Q) -> Option<&V>
where
    String: Borrow<Q>,
    Q: Hash + Eq,
{
    map.get(key)
}
```

### Implement AsRef for Custom Types

```rust
struct Name(String);

impl AsRef<str> for Name {
    fn as_ref(&self) -> &str {
        &self.0
    }
}

impl AsRef<[u8]> for Name {
    fn as_ref(&self) -> &[u8] {
        self.0.as_bytes()
    }
}

// Now Name works with functions expecting AsRef<str>
fn greet(name: impl AsRef<str>) {
    println!("Hello, {}!", name.as_ref());
}

greet(Name("Alice".into()));
```

### Common AsRef Implementations

```rust
// Standard library provides many
impl AsRef<str> for String { ... }
impl AsRef<str> for str { ... }
impl AsRef<[u8]> for str { ... }
impl AsRef<[u8]> for String { ... }
impl AsRef<[u8]> for Vec<u8> { ... }
impl AsRef<Path> for str { ... }
impl AsRef<Path> for String { ... }
impl AsRef<Path> for PathBuf { ... }
impl AsRef<Path> for OsStr { ... }
impl AsRef<OsStr> for str { ... }
```

### When to Use Which

| Trait | Use When |
|-------|----------|
| `&T` | Single type, simple API |
| `AsRef<T>` | Read-only access, multiple input types |
| `Into<T>` | Need to store/own the value |
| `Borrow<T>` | HashMap/HashSet keys, Eq/Hash needed |
| `Deref<Target=T>` | Smart pointer semantics |

### Pattern: Optional AsRef Bound

```rust
// When T itself might be passed
fn process<T: AsRef<U>, U>(value: T) {
    let inner: &U = value.as_ref();
}

// More flexible: accept T or &T
fn process<T: AsRef<U> + ?Sized, U: ?Sized>(value: &T) {
    let inner: &U = value.as_ref();
}
```

Related: `api-impl-into`, `own-slice-over-vec`, `own-borrow-over-clone`

## api-must-use

> Mark types and functions with `#[must_use]` when ignoring results is likely a bug

### Why It Matters

Some return values should never be ignored—`Result`, locks, RAII guards, computed values that have no side effects. Without `#[must_use]`, silently discarding these values can introduce subtle bugs that are hard to detect. The attribute generates compiler warnings when the value is unused.

### Bad

```rust
// Result ignored - error silently dropped
fn send_email(to: &str, body: &str) -> Result<(), EmailError> { ... }

send_email("user@example.com", "Hello!");  // No warning if Result ignored!
// Email may have failed, but we don't know

// Computed value ignored - likely a bug
fn compute_checksum(data: &[u8]) -> u32 { ... }

let data = vec![1, 2, 3, 4];
compute_checksum(&data);  // Result discarded - pointless call
```

### Good

```rust
#[must_use = "this `Result` may be an `Err` that should be handled"]
fn send_email(to: &str, body: &str) -> Result<(), EmailError> { ... }

send_email("user@example.com", "Hello!");  
// Warning: unused `Result` that must be used

// Mark pure functions
#[must_use = "this returns a new value and does not modify the input"]
fn compute_checksum(data: &[u8]) -> u32 { ... }

compute_checksum(&data);
// Warning: unused return value of `compute_checksum` that must be used
```

### Apply to Types

```rust
// Mark the type itself when it should always be used
#[must_use = "futures do nothing unless polled"]
struct MyFuture<T> { ... }

// Mark RAII guards
#[must_use = "if unused, the lock will be immediately released"]
struct MutexGuard<'a, T> { ... }

// Mark results/errors
#[must_use = "errors should be handled"]
enum AppError { ... }
```

### Standard Library Examples

```rust
// Result and Option are #[must_use]
let v: Vec<i32> = vec![1, 2, 3];
v.first();  // Warning: unused Option

// Iterator adapters are #[must_use]
v.iter().map(|x| x * 2);  // Warning: iterators are lazy

// String methods that return new values
let s = "hello";
s.to_uppercase();  // Warning: unused String
```

### When to Apply

```rust
// ✅ Pure functions (no side effects)
#[must_use]
fn add(a: i32, b: i32) -> i32 { a + b }

// ✅ Builder methods returning Self
#[must_use = "builder methods return a new builder"]
fn with_timeout(self, t: Duration) -> Self { ... }

// ✅ Fallible operations
#[must_use]
fn try_parse(s: &str) -> Result<Data, ParseError> { ... }

// ✅ Iterators and futures (lazy)
#[must_use = "iterators are lazy and do nothing unless consumed"]
struct Map<I, F> { ... }

// ❌ Side-effecting functions where result is optional
fn log(msg: &str) -> Result<(), io::Error> { ... }  // Might be ok to ignore

// ❌ Methods with useful side effects
fn vec.push(item);  // Mutates vec, no return to use
```

### Custom Messages

```rust
#[must_use = "creating a guard does nothing without assignment"]
struct ScopeGuard { ... }

#[must_use = "this returns the old value"]
fn replace(&mut self, new: T) -> T { ... }

#[must_use = "use `.await` to execute the future"]
async fn fetch() -> Data { ... }
```

### Clippy Lints

```toml
[lints.clippy]
must_use_candidate = "warn"      # Suggests where to add #[must_use]
unused_must_use = "deny"          # Built-in, treat warnings as errors
double_must_use = "warn"          # Redundant #[must_use]
```

Related: `api-builder-must-use`, `err-result-over-panic`, `lint-deny-correctness`

## api-non-exhaustive

> Use `#[non_exhaustive]` on public enums and structs for forward compatibility

### Why It Matters

Adding a variant to a public enum or a field to a public struct is normally a breaking change—downstream code may match exhaustively or use struct literal syntax. `#[non_exhaustive]` forces external code to use wildcards in matches and constructors, allowing you to add variants/fields in minor versions without breaking callers.

### Bad

```rust
// Public enum - adding variant breaks downstream matches
pub enum ErrorKind {
    NotFound,
    PermissionDenied,
    TimedOut,
}

// Downstream code
match error.kind() {
    ErrorKind::NotFound => ...,
    ErrorKind::PermissionDenied => ...,
    ErrorKind::TimedOut => ...,
    // No wildcard - will break when you add ErrorKind::Interrupted
}

// Public struct - adding field breaks downstream construction
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Downstream code
let config = Config { name: "test".into(), value: 42 };
// Will break when you add `pub enabled: bool`
```

### Good

```rust
// Can add variants in minor versions
#[non_exhaustive]
pub enum ErrorKind {
    NotFound,
    PermissionDenied,
    TimedOut,
    // Future: can add Interrupted here without breaking changes
}

// Downstream code MUST have wildcard
match error.kind() {
    ErrorKind::NotFound => ...,
    ErrorKind::PermissionDenied => ...,
    ErrorKind::TimedOut => ...,
    _ => ...,  // Required by non_exhaustive
}

// Can add fields in minor versions
#[non_exhaustive]
pub struct Config {
    pub name: String,
    pub value: i32,
}

// Downstream CANNOT use struct literal syntax
// let config = Config { name: "test".into(), value: 42 };  // Error!

// Must use constructor
impl Config {
    pub fn new(name: impl Into<String>, value: i32) -> Self {
        Config { name: name.into(), value }
    }
}
```

### How It Works

```rust
#[non_exhaustive]
pub enum Status {
    Active,
    Inactive,
}

// Inside your crate: exhaustive match is allowed
fn internal(s: Status) {
    match s {
        Status::Active => {},
        Status::Inactive => {},
        // No wildcard needed inside defining crate
    }
}

// Outside your crate: wildcard required
fn external(s: my_crate::Status) {
    match s {
        my_crate::Status::Active => {},
        my_crate::Status::Inactive => {},
        _ => {},  // REQUIRED
    }
}
```

### Struct Usage

```rust
#[non_exhaustive]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    // Provide constructor
    pub fn new(x: f64, y: f64) -> Self {
        Point { x, y }
    }
}

// External code can read fields but not construct with literals
fn external(p: Point) {
    println!("x: {}, y: {}", p.x, p.y);  // Reading is fine
    
    // let p2 = Point { x: 1.0, y: 2.0 };  // Error!
    let p2 = Point::new(1.0, 2.0);  // Must use constructor
}
```

### Non-Exhaustive Variants

```rust
pub enum Message {
    // Specific variant is non-exhaustive
    #[non_exhaustive]
    Error { code: u32, message: String },
    
    Ok(Data),
}

// Can destructure Ok normally
// But Error requires `..` to handle future fields
match msg {
    Message::Ok(data) => {},
    Message::Error { code, message, .. } => {},  // `..` required
}
```

### When to Use

```rust
// ✅ Use for public API types that may evolve
#[non_exhaustive]
pub enum ApiError { ... }

#[non_exhaustive]
pub struct Options { ... }

// ✅ Use for error types
#[non_exhaustive]
pub enum MyError { ... }

// ❌ Don't use for internal types
enum InternalState { ... }  // Not public, no concern

// ❌ Don't use for stable, complete types
pub enum Ordering {  // Less, Equal, Greater is complete
    Less,
    Equal,
    Greater,
}
```

Related: `api-sealed-trait`, `err-custom-type`, `api-builder-pattern`
