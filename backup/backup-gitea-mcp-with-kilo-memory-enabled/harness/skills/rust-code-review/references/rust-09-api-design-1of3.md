---
name: rust-09-api-design-1of3
description: Rust rules module 09: API Design (part 1 of 3). 5 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `api-`
---

# API Design (part 1/3)

Priority: HIGH. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `api-builder-pattern` - Use Builder pattern for complex construction
- `api-builder-must-use` - Mark builder methods with `#[must_use]` to prevent silent drops
- `api-newtype-safety` - Use newtypes to prevent mixing semantically different values
- `api-typestate` - Use typestate pattern to encode state machine invariants in the type system
- `api-sealed-trait` - Use sealed traits to prevent external implementations while allowing use

---

## api-builder-pattern

> Use Builder pattern for complex construction

### Why It Matters

When a type has many optional parameters or complex initialization, the Builder pattern provides a clear, flexible API. It avoids constructors with many parameters (which are error-prone) and makes the code self-documenting.

### Bad

```rust
// Constructor with many parameters - hard to read, easy to get wrong
let client = Client::new(
    "https://api.example.com",  // Which is which?
    30,                          // Timeout? Retries?
    true,                        // What does this mean?
    None,
    Some("auth_token"),
    false,
);

// Or many Option fields
struct Client {
    url: String,
    timeout: Option<Duration>,
    retries: Option<u32>,
    // ... 10 more optional fields
}
```

### Good

```rust
#[derive(Default)]
#[must_use = "builders do nothing unless you call build()"]
pub struct ClientBuilder {
    base_url: Option<String>,
    timeout: Option<Duration>,
    max_retries: u32,
    auth_token: Option<String>,
}

impl ClientBuilder {
    pub fn new() -> Self {
        Self::default()
    }
    
    /// Sets the base URL for all requests.
    pub fn base_url(mut self, url: impl Into<String>) -> Self {
        self.base_url = Some(url.into());
        self
    }
    
    /// Sets the request timeout. Default is 30 seconds.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }
    
    /// Sets the maximum number of retries. Default is 3.
    pub fn max_retries(mut self, n: u32) -> Self {
        self.max_retries = n;
        self
    }
    
    /// Sets the authentication token.
    pub fn auth_token(mut self, token: impl Into<String>) -> Self {
        self.auth_token = Some(token.into());
        self
    }
    
    /// Builds the client with the configured options.
    pub fn build(self) -> Result<Client, BuilderError> {
        let base_url = self.base_url
            .ok_or(BuilderError::MissingBaseUrl)?;
        
        Ok(Client {
            base_url,
            timeout: self.timeout.unwrap_or(Duration::from_secs(30)),
            max_retries: self.max_retries,
            auth_token: self.auth_token,
        })
    }
}

// Usage - clear and self-documenting
let client = ClientBuilder::new()
    .base_url("https://api.example.com")
    .timeout(Duration::from_secs(10))
    .max_retries(5)
    .auth_token("secret")
    .build()?;
```

### Builder Variations

```rust
// 1. Infallible builder (build() returns T, not Result)
impl WidgetBuilder {
    pub fn build(self) -> Widget {
        Widget {
            color: self.color.unwrap_or(Color::Black),
            size: self.size.unwrap_or(Size::Medium),
        }
    }
}

// 2. Typestate builder (compile-time required field checking)
pub struct ClientBuilder<Url> {
    url: Url,
    timeout: Option<Duration>,
}

pub struct NoUrl;
pub struct HasUrl(String);

impl ClientBuilder<NoUrl> {
    pub fn new() -> Self {
        Self { url: NoUrl, timeout: None }
    }
    
    pub fn url(self, url: String) -> ClientBuilder<HasUrl> {
        ClientBuilder { url: HasUrl(url), timeout: self.timeout }
    }
}

impl ClientBuilder<HasUrl> {
    pub fn build(self) -> Client {
        // url is guaranteed to be set
        Client { url: self.url.0, timeout: self.timeout }
    }
}

// 3. Consuming vs borrowing (consuming is more common)
// Consuming (takes self)
pub fn timeout(mut self, t: Duration) -> Self { ... }

// Borrowing (takes &mut self, allows reuse)
pub fn timeout(&mut self, t: Duration) -> &mut Self { ... }
```

### Evidence from reqwest

```rust
// https://github.com/seanmonstar/reqwest/blob/master/src/async_impl/client.rs

#[must_use]
pub struct ClientBuilder {
    config: Config,
}

impl ClientBuilder {
    pub fn new() -> ClientBuilder {
        ClientBuilder {
            config: Config::default(),
        }
    }
    
    pub fn timeout(mut self, timeout: Duration) -> ClientBuilder {
        self.config.timeout = Some(timeout);
        self
    }
    
    pub fn build(self) -> Result<Client, Error> {
        // Validation and construction
    }
}
```

### Key Attributes

```rust
#[derive(Default)]  // Enables MyBuilder::default()
#[must_use = "builders do nothing unless you call build()"]
pub struct MyBuilder { ... }

impl MyBuilder {
    #[must_use]  // Each method should have this
    pub fn option(mut self, value: T) -> Self { ... }
}
```

Related: `api-builder-must-use`, `api-typestate`, `api-impl-into`

## api-builder-must-use

> Mark builder methods with `#[must_use]` to prevent silent drops

### Why It Matters

Builder pattern methods return a modified builder. Without `#[must_use]`, calling a builder method and ignoring the return value silently does nothing—the builder is dropped, and the configuration is lost. This creates confusing bugs where code appears correct but has no effect.

### Bad

```rust
struct RequestBuilder {
    url: String,
    timeout: Option<Duration>,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    fn timeout(mut self, duration: Duration) -> Self {
        self.timeout = Some(duration);
        self
    }
    
    fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_string(), value.to_string()));
        self
    }
}

// Bug: builder methods are ignored - no warning!
let request = RequestBuilder::new("https://api.example.com");
request.timeout(Duration::from_secs(30));  // Dropped silently!
request.header("Authorization", "Bearer token");  // Dropped silently!
let response = request.send();  // Sends with no timeout or headers
```

### Good

```rust
struct RequestBuilder {
    url: String,
    timeout: Option<Duration>,
    headers: Vec<(String, String)>,
}

impl RequestBuilder {
    #[must_use = "builder methods return modified builder - chain or assign"]
    fn timeout(mut self, duration: Duration) -> Self {
        self.timeout = Some(duration);
        self
    }
    
    #[must_use = "builder methods return modified builder - chain or assign"]
    fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_string(), value.to_string()));
        self
    }
}

// Now warns: unused return value that must be used
let request = RequestBuilder::new("https://api.example.com");
request.timeout(Duration::from_secs(30));  // Warning!

// Correct: chain methods
let response = RequestBuilder::new("https://api.example.com")
    .timeout(Duration::from_secs(30))
    .header("Authorization", "Bearer token")
    .send();
```

### Apply to Entire Type

```rust
#[must_use = "builders do nothing unless consumed"]
struct ConfigBuilder {
    log_level: Level,
    max_connections: usize,
}

// Now all methods returning Self warn if ignored
impl ConfigBuilder {
    fn log_level(mut self, level: Level) -> Self {
        self.log_level = level;
        self
    }
    
    fn max_connections(mut self, n: usize) -> Self {
        self.max_connections = n;
        self
    }
    
    fn build(self) -> Config {
        Config {
            log_level: self.log_level,
            max_connections: self.max_connections,
        }
    }
}
```

### Message Guidelines

```rust
// Descriptive message helps users understand
#[must_use = "builder methods return modified builder"]
fn with_foo(self, foo: Foo) -> Self { ... }

#[must_use = "this creates a new String and does not modify the original"]
fn to_uppercase(&self) -> String { ... }

#[must_use = "iterator adaptors are lazy - use .collect() to consume"]
fn map<F>(self, f: F) -> Map<Self, F> { ... }
```

### Clippy Lint

```toml
[lints.clippy]
must_use_candidate = "warn"  # Suggests where #[must_use] would help
return_self_not_must_use = "warn"  # Specifically for -> Self methods
```

### Standard Library Examples

```rust
// std::Option - must_use on map, and, or
let x: Option<i32> = Some(5);
x.map(|v| v * 2);  // Warning: unused return value

// std::Result - must_use on the type itself
#[must_use = "this `Result` may be an `Err` variant, which should be handled"]
pub enum Result<T, E> { ... }

// Iterator adaptors
let v = vec![1, 2, 3];
v.iter().map(|x| x * 2);  // Warning: iterators are lazy
```

Related: `api-builder-pattern`, `api-must-use`, `err-result-over-panic`

## api-newtype-safety

> Use newtypes to prevent mixing semantically different values

### Why It Matters

Raw primitives like `u64` or `String` carry no semantic meaning. A function taking `(u64, u64)` can easily be called with arguments swapped. Newtypes wrap primitives in distinct types, making the compiler catch mistakes at compile time rather than runtime.

### Bad

```rust
struct User {
    id: u64,
    group_id: u64,
    created_at: u64,  // Unix timestamp
}

fn add_user_to_group(user_id: u64, group_id: u64) { ... }

// Bug: arguments swapped - compiles fine, fails at runtime
let user = User { id: 100, group_id: 5, created_at: 1234567890 };
add_user_to_group(user.group_id, user.id);  // Silent bug!

// Bug: wrong field used - timestamp passed as ID
add_user_to_group(user.created_at, user.group_id);  // Compiles fine!
```

### Good

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct GroupId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct Timestamp(u64);

struct User {
    id: UserId,
    group_id: GroupId,
    created_at: Timestamp,
}

fn add_user_to_group(user_id: UserId, group_id: GroupId) { ... }

// Compile error: expected UserId, found GroupId
let user = User { ... };
add_user_to_group(user.group_id, user.id);  // Error!

// Compile error: expected UserId, found Timestamp
add_user_to_group(user.created_at, user.group_id);  // Error!
```

### Derive Common Traits

```rust
// Minimal: just enough for your use case
#[derive(Debug, Clone, Copy)]
struct MeterId(u32);

// Full ID type: hashable, comparable, displayable
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct OrderId(u64);

impl std::fmt::Display for OrderId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "ORD-{:08}", self.0)
    }
}

// With serde for serialization
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]  // Serializes as raw u64
struct ProductId(u64);
```

### Constructor Patterns

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct Email(String);

impl Email {
    /// Creates a new Email, validating the format.
    pub fn new(s: &str) -> Result<Self, EmailError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(EmailError::InvalidFormat)
        }
    }
    
    /// Returns the email as a string slice.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// Usage enforces validation
let email = Email::new("user@example.com")?;  // Must go through validation
```

### Zero-Cost Abstraction

```rust
use std::mem::size_of;

#[derive(Clone, Copy)]
struct Miles(f64);

#[derive(Clone, Copy)]
struct Kilometers(f64);

// Same size as raw f64
assert_eq!(size_of::<Miles>(), size_of::<f64>());
assert_eq!(size_of::<Kilometers>(), size_of::<f64>());

// But can't accidentally mix them
fn drive(distance: Miles) { ... }

let km = Kilometers(100.0);
drive(km);  // Error: expected Miles, found Kilometers

// Explicit conversion
impl From<Kilometers> for Miles {
    fn from(km: Kilometers) -> Self {
        Miles(km.0 * 0.621371)
    }
}

drive(km.into());  // Explicit, visible conversion
```

### When Newtypes Help Most

```rust
// ✅ IDs that could be confused
fn transfer(from: AccountId, to: AccountId, amount: Money) { ... }

// ✅ Units that shouldn't mix
struct Celsius(f64);
struct Fahrenheit(f64);

// ✅ Validated strings
struct Username(String);  // Validated alphanumeric
struct Password(String);  // Never logged

// ✅ Different meanings of same type
struct Milliseconds(u64);
struct Seconds(u64);

// ❌ Overkill: single use, no confusion possible
struct X(i32);  // Just use i32
```

Related: `type-newtype-ids`, `api-parse-dont-validate`, `own-copy-small`

## api-typestate

> Use typestate pattern to encode state machine invariants in the type system

### Why It Matters

State machines with runtime state checks ("are we connected?", "is the transaction started?") can have invalid transitions. The typestate pattern uses different types for each state, making invalid state transitions compile errors. The compiler enforces your state machine.

### Bad

```rust
struct Connection {
    state: ConnectionState,
    socket: Option<TcpStream>,
}

enum ConnectionState {
    Disconnected,
    Connected,
    Authenticated,
}

impl Connection {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> {
        // Runtime check - can fail if called in wrong state
        if self.state != ConnectionState::Authenticated {
            return Err(Error::NotAuthenticated);
        }
        self.socket.as_mut().unwrap().write_all(data)?;
        Ok(())
    }
    
    fn authenticate(&mut self, password: &str) -> Result<(), Error> {
        // Runtime check - can fail
        if self.state != ConnectionState::Connected {
            return Err(Error::NotConnected);
        }
        // ...
    }
}

// Bug: forgot to authenticate
let mut conn = Connection::new();
conn.connect()?;
conn.send(b"data")?;  // Runtime error: NotAuthenticated
```

### Good

```rust
// Different types for each state
struct Disconnected;
struct Connected { socket: TcpStream }
struct Authenticated { socket: TcpStream, session: Session }

struct Connection<State> {
    state: State,
}

impl Connection<Disconnected> {
    fn new() -> Self {
        Connection { state: Disconnected }
    }
    
    fn connect(self, addr: &str) -> Result<Connection<Connected>, Error> {
        let socket = TcpStream::connect(addr)?;
        Ok(Connection { state: Connected { socket } })
    }
}

impl Connection<Connected> {
    fn authenticate(self, password: &str) -> Result<Connection<Authenticated>, Error> {
        let session = do_auth(&self.state.socket, password)?;
        Ok(Connection {
            state: Authenticated { socket: self.state.socket, session }
        })
    }
}

impl Connection<Authenticated> {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> {
        // No runtime check needed - type guarantees we're authenticated
        self.state.socket.write_all(data)?;
        Ok(())
    }
}

// Bug: forgot to authenticate
let conn = Connection::new();
let conn = conn.connect("server:8080")?;
conn.send(b"data");  // Compile error! send() not available on Connection<Connected>

// Correct usage
let conn = Connection::new();
let conn = conn.connect("server:8080")?;
let mut conn = conn.authenticate("secret")?;
conn.send(b"data")?;  // Works - type is Connection<Authenticated>
```

### Builder Typestate

```rust
// Enforce required fields via typestate
struct BuilderNoUrl;
struct BuilderWithUrl { url: String }

struct RequestBuilder<State> {
    state: State,
    timeout: Option<Duration>,
}

impl RequestBuilder<BuilderNoUrl> {
    fn new() -> Self {
        RequestBuilder {
            state: BuilderNoUrl,
            timeout: None,
        }
    }
    
    fn url(self, url: &str) -> RequestBuilder<BuilderWithUrl> {
        RequestBuilder {
            state: BuilderWithUrl { url: url.to_string() },
            timeout: self.timeout,
        }
    }
}

impl RequestBuilder<BuilderWithUrl> {
    fn timeout(mut self, t: Duration) -> Self {
        self.timeout = Some(t);
        self
    }
    
    // Only available once URL is set
    fn build(self) -> Request {
        Request {
            url: self.state.url,
            timeout: self.timeout,
        }
    }
}

// Compile error: build() not available
let bad = RequestBuilder::new().build();

// Correct: must set URL first
let good = RequestBuilder::new()
    .url("https://example.com")
    .timeout(Duration::from_secs(30))
    .build();
```

### Transaction Example

```rust
struct NotStarted;
struct InProgress { tx_id: u64 }
struct Committed;

struct Transaction<State> {
    conn: Connection,
    state: State,
}

impl Transaction<NotStarted> {
    fn begin(conn: Connection) -> Result<Transaction<InProgress>, Error> {
        let tx_id = conn.execute("BEGIN")?;
        Ok(Transaction {
            conn,
            state: InProgress { tx_id },
        })
    }
}

impl Transaction<InProgress> {
    fn execute(&mut self, sql: &str) -> Result<(), Error> {
        self.conn.execute(sql)
    }
    
    fn commit(self) -> Result<Transaction<Committed>, Error> {
        self.conn.execute("COMMIT")?;
        Ok(Transaction {
            conn: self.conn,
            state: Committed,
        })
    }
    
    fn rollback(self) -> Connection {
        let _ = self.conn.execute("ROLLBACK");
        self.conn
    }
}
```

Related: `api-builder-pattern`, `api-parse-dont-validate`, `api-sealed-trait`

## api-sealed-trait

> Use sealed traits to prevent external implementations while allowing use

### Why It Matters

Public traits can be implemented by anyone, which may be undesirable when you need to guarantee behavior or add methods in future versions. A sealed trait can be used by external code but not implemented by it, giving you control over implementations while maintaining a usable API.

### Bad

```rust
// Anyone can implement this trait
pub trait DatabaseDriver {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
}

// External crate implements it incorrectly
impl DatabaseDriver for MyBadDriver {
    fn connect(&self, url: &str) -> Connection {
        // Buggy implementation that doesn't handle errors
        unsafe { force_connect(url) }
    }
}

// Later, you want to add a required method - BREAKING CHANGE
pub trait DatabaseDriver {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
    fn transaction(&self) -> Transaction;  // External impls now broken!
}
```

### Good

```rust
// Create a private module with a private trait
mod private {
    pub trait Sealed {}
}

// Public trait requires the private trait
pub trait DatabaseDriver: private::Sealed {
    fn connect(&self, url: &str) -> Connection;
    fn execute(&self, query: &str) -> Result<Rows, Error>;
}

// Only your crate can implement Sealed, thus DatabaseDriver
pub struct PostgresDriver;
impl private::Sealed for PostgresDriver {}
impl DatabaseDriver for PostgresDriver {
    fn connect(&self, url: &str) -> Connection { ... }
    fn execute(&self, query: &str) -> Result<Rows, Error> { ... }
}

pub struct MySqlDriver;
impl private::Sealed for MySqlDriver {}
impl DatabaseDriver for MySqlDriver {
    fn connect(&self, url: &str) -> Connection { ... }
    fn execute(&self, query: &str) -> Result<Rows, Error> { ... }
}

// External crate cannot implement - private::Sealed is not accessible
// impl DatabaseDriver for ExternalDriver { }  // Error!

// But external code CAN use the trait
fn use_driver(driver: &impl DatabaseDriver) {
    let conn = driver.connect("postgres://localhost");
}
```

### Full Pattern

```rust
pub mod db {
    mod private {
        pub trait Sealed {}
    }
    
    /// Database driver trait.
    /// 
    /// This trait is sealed and cannot be implemented outside this crate.
    pub trait Driver: private::Sealed {
        /// Connects to the database.
        fn connect(&self, url: &str) -> Result<Connection, Error>;
        
        /// Executes a query.
        fn execute(&self, sql: &str) -> Result<Rows, Error>;
    }
    
    pub struct Postgres;
    impl private::Sealed for Postgres {}
    impl Driver for Postgres { ... }
    
    pub struct Sqlite;
    impl private::Sealed for Sqlite {}
    impl Driver for Sqlite { ... }
}

// Usage works fine
use db::{Driver, Postgres};

fn query(driver: &impl Driver) {
    driver.execute("SELECT 1")?;
}

query(&Postgres);
```

### Benefits of Sealing

```rust
// 1. Add methods without breaking changes
pub trait Format: private::Sealed {
    fn format(&self) -> String;
    
    // Added later - not breaking because no external impls exist
    fn format_pretty(&self) -> String {
        self.format()  // Default implementation
    }
}

// 2. Guarantee invariants
pub trait SafeBuffer: private::Sealed {
    // You control all implementations, so you know they're all correct
    fn get(&self, index: usize) -> Option<&u8>;
}

// 3. Use as marker traits
pub trait ValidConfig: private::Sealed {}
// Only validated configs implement this
```

### Partially Sealed

```rust
// Allow implementing some methods but not all
mod private {
    pub trait SealedCore {}
}

pub trait Plugin: private::SealedCore {
    // Sealed - only we implement
    fn initialize(&self);
    fn shutdown(&self);
    
    // Open - users can override
    fn name(&self) -> &str { "unnamed" }
}

// Only we can add new required sealed methods
// Users can customize open methods
```

### When to Seal

| Seal When | Don't Seal When |
|-----------|-----------------|
| API stability is critical | You want extension points |
| Implementation correctness is hard | Users need custom implementations |
| You'll add methods later | Trait is simple and stable |
| Safety invariants required | Standard patterns (Iterator, etc.) |

Related: `api-non-exhaustive`, `api-extension-trait`, `api-typestate`
