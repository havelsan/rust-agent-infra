---
name: rust-29-naming-1of2
description: Rust rules module 29: Naming Conventions (part 1 of 2). 9 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `name-`
---

# Naming Conventions (part 1/2)

Priority: MEDIUM. 9 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `name-types-camel` - Use `UpperCamelCase` for types, traits, and enum names
- `name-variants-camel` - Use `UpperCamelCase` for enum variants
- `name-funcs-snake` - Use `snake_case` for functions, methods, variables, and modules
- `name-consts-screaming` - Use `SCREAMING_SNAKE_CASE` for constants and statics
- `name-lifetime-short` - Use short, conventional lifetime names: `'a`, `'b`, `'de`, `'src`
- `name-type-param-single` - Use single uppercase letters for type parameters: `T`, `E`, `K`, `V`
- `name-as-free` - `as_` prefix: free reference conversion
- `name-to-expensive` - Use `to_` prefix for expensive conversions that allocate or compute
- `name-into-ownership` - Use `into_` prefix for ownership-consuming conversions

---

## name-types-camel

> Use `UpperCamelCase` for types, traits, and enum names

### Why It Matters

Rust's naming conventions are enforced by the compiler and linter. Consistent naming makes code immediately recognizable—you know `HttpClient` is a type, `send_request` is a function. Violating conventions triggers warnings and makes code harder to read.

### Bad

```rust
// Lowercase types - compiler warns
struct http_client { ... }  // warning: type `http_client` should have an upper camel case name
trait serializable { ... }  // warning
enum response_type { ... }  // warning

// Screaming case for types
struct HTTP_CLIENT { ... }  // Not idiomatic
```

### Good

```rust
// UpperCamelCase for all types
struct HttpClient { ... }
trait Serializable { ... }
enum ResponseType { ... }

// Compound words
struct TcpConnection { ... }
struct IoError { ... }
struct FileReader { ... }

// Generic types
struct HashMap<K, V> { ... }
struct Result<T, E> { ... }
```

### Acronyms

```rust
// Treat acronyms as words (capitalize first letter only)
struct HttpServer { ... }      // Not HTTPServer
struct JsonParser { ... }      // Not JSONParser
struct Uuid { ... }            // Not UUID
struct TcpStream { ... }       // Not TCPStream

// Exception: Two-letter acronyms can be all caps
struct IOError { ... }         // Acceptable
struct IoError { ... }         // Also acceptable (preferred)
```

### Type Aliases

```rust
// Type aliases also use UpperCamelCase
type Result<T> = std::result::Result<T, Error>;
type BoxedFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;
```

Related: `name-variants-camel`, `name-funcs-snake`, `name-acronym-word`

## name-variants-camel

> Use `UpperCamelCase` for enum variants

### Why It Matters

Enum variants follow the same naming convention as types—`UpperCamelCase`. This distinguishes them from fields, variables, and functions. The compiler warns on violations, and consistent naming helps readers instantly recognize variant names.

### Bad

```rust
enum Status {
    pending,       // warning: variant `pending` should have an upper camel case name
    in_progress,   // warning
    COMPLETED,     // Not idiomatic
}

enum Color {
    RED,           // Screaming case - not Rust style
    GREEN,
    BLUE,
}
```

### Good

```rust
enum Status {
    Pending,
    InProgress,
    Completed,
    Failed,
}

enum Color {
    Red,
    Green,
    Blue,
    Custom(u8, u8, u8),
}

enum HttpMethod {
    Get,
    Post,
    Put,
    Delete,
    Patch,
}
```

### Variants with Data

```rust
enum Message {
    // Unit variant
    Quit,
    
    // Tuple variant
    Move(i32, i32),
    
    // Struct variant
    Write { text: String },
    
    // Named fields
    ChangeColor {
        red: u8,
        green: u8,
        blue: u8,
    },
}
```

### Variant Naming Tips

```rust
// Be specific
enum Error {
    NotFound,           // Good: specific
    PermissionDenied,   // Good: specific
    Error,              // Bad: vague
}

// Avoid redundant type name in variant
enum ConnectionState {
    Connected,          // Good
    Disconnected,       // Good
    ConnectionError,    // Bad: redundant "Connection"
}

// Use None/Some pattern for Option-like enums
enum MaybeValue<T> {
    Some(T),
    None,
}
```

Related: `name-types-camel`, `api-non-exhaustive`, `type-enum-states`

## name-funcs-snake

> Use `snake_case` for functions, methods, variables, and modules

### Why It Matters

Rust uses `snake_case` for "value-level" names—functions, methods, variables, modules. This convention is enforced by the compiler and distinguishes runtime entities from types. Consistent naming makes code scannable and predictable.

### Bad

```rust
// CamelCase functions - compiler warns
fn calculateTotal() -> f64 { ... }  // warning: function `calculateTotal` should have a snake case name
fn getUserName() -> String { ... }  // warning

// Inconsistent naming
fn get_user() -> User { ... }
fn fetchOrder() -> Order { ... }  // Mixed conventions
```

### Good

```rust
// snake_case for functions
fn calculate_total() -> f64 { ... }
fn get_user_name() -> String { ... }
fn fetch_order() -> Order { ... }

// snake_case for methods
impl User {
    fn full_name(&self) -> String { ... }
    fn is_active(&self) -> bool { ... }
    fn set_email(&mut self, email: &str) { ... }
}

// snake_case for variables
let user_count = 42;
let max_connections = 100;
let is_valid = true;

// snake_case for modules
mod user_service;
mod http_client;
mod json_parser;
```

### Acronyms in snake_case

```rust
// Lowercase acronyms in snake_case
fn parse_json() -> Json { ... }   // Not parse_JSON
fn connect_tcp() -> TcpStream { ... }   // Not connect_TCP
fn generate_uuid() -> Uuid { ... }      // Not generate_UUID

let http_response = fetch();
let json_data = parse();
```

### Local Variables

```rust
fn process_data(input_data: &[u8]) -> Result<Output, Error> {
    let raw_bytes = input_data;
    let decoded_string = decode(raw_bytes)?;
    let parsed_value = parse(&decoded_string)?;
    let final_result = transform(parsed_value)?;
    
    Ok(final_result)
}
```

Related: `name-types-camel`, `name-consts-screaming`, `name-lifetime-short`

## name-consts-screaming

> Use `SCREAMING_SNAKE_CASE` for constants and statics

### Why It Matters

Constants and statics are special—they're known at compile time and have program-wide lifetime. `SCREAMING_SNAKE_CASE` makes them visually distinct from runtime variables. This convention is enforced by the compiler and universally expected.

### Bad

```rust
// lowercase/camelCase constants - compiler warns
const maxConnections: u32 = 100;  // warning
const default_timeout: u64 = 30;  // warning
static globalCounter: AtomicU64 = AtomicU64::new(0);  // warning
```

### Good

```rust
// SCREAMING_SNAKE_CASE for constants
const MAX_CONNECTIONS: u32 = 100;
const DEFAULT_TIMEOUT: Duration = Duration::from_secs(30);
const BUFFER_SIZE: usize = 4096;

// SCREAMING_SNAKE_CASE for statics
static GLOBAL_COUNTER: AtomicU64 = AtomicU64::new(0);
static CONFIG: OnceLock<Config> = OnceLock::new();

// Type-level constants in impl blocks
impl Buffer {
    const INITIAL_CAPACITY: usize = 1024;
    const MAX_CAPACITY: usize = 1024 * 1024;
}
```

### Associated Constants

```rust
trait Limit {
    const MAX: usize;
    const MIN: usize;
}

impl Limit for SmallBuffer {
    const MAX: usize = 256;
    const MIN: usize = 16;
}

// Generic associated constants
struct Container<T> {
    data: Vec<T>,
}

impl<T> Container<T> {
    const EMPTY: Self = Self { data: Vec::new() };
}
```

### Environment and Config

```rust
// Environment variable names
const ENV_DATABASE_URL: &str = "DATABASE_URL";
const ENV_LOG_LEVEL: &str = "LOG_LEVEL";

// Configuration keys
const CONFIG_TIMEOUT_SECONDS: &str = "timeout_seconds";
const CONFIG_MAX_RETRIES: &str = "max_retries";
```

### Lazy Static / OnceLock

```rust
use std::sync::OnceLock;

// Global configuration
static CONFIG: OnceLock<AppConfig> = OnceLock::new();

// Compiled regex
static EMAIL_REGEX: OnceLock<Regex> = OnceLock::new();

fn get_email_regex() -> &'static Regex {
    EMAIL_REGEX.get_or_init(|| {
        Regex::new(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").unwrap()
    })
}
```

Related: `name-funcs-snake`, `name-types-camel`, `type-newtype-ids`

## name-lifetime-short

> Use short, conventional lifetime names: `'a`, `'b`, `'de`, `'src`

### Why It Matters

Lifetime parameters are ubiquitous in Rust signatures. Short names like `'a` keep signatures readable. For domain-specific lifetimes, descriptive but short names like `'src` or `'de` communicate intent without clutter. The Rust community has established conventions that aid recognition.

### Bad

```rust
// Overly verbose lifetimes
fn parse<'input_lifetime, 'output_lifetime>(
    input: &'input_lifetime str
) -> Result<&'output_lifetime str, Error> { ... }

// Meaningless long names
struct Parser<'parser_instance_lifetime> {
    source: &'parser_instance_lifetime str,
}
```

### Good

```rust
// Standard short lifetimes
fn parse<'a>(input: &'a str) -> Result<&'a str, Error> { ... }

struct Parser<'a> {
    source: &'a str,
}

// Multiple lifetimes: 'a, 'b, 'c
fn merge<'a, 'b>(first: &'a str, second: &'b str) -> String { ... }

// Descriptive when clarity helps
fn deserialize<'de>(input: &'de [u8]) -> Result<Value<'de>, Error> { ... }
```

### Common Lifetime Conventions

| Lifetime | Convention | Example |
|----------|------------|---------|
| `'a` | Generic, first lifetime | `fn foo<'a>(x: &'a str)` |
| `'b` | Generic, second lifetime | `fn bar<'a, 'b>(x: &'a T, y: &'b U)` |
| `'de` | Deserialization | serde's `Deserialize<'de>` |
| `'src` | Source code/input | `struct Lexer<'src>` |
| `'ctx` | Context | `struct Query<'ctx>` |
| `'input` | Input data | `struct Parser<'input>` |
| `'static` | Static lifetime | `&'static str` |

### Elision Preferred

```rust
// Let elision work when possible
fn first_word(s: &str) -> &str {  // Not fn first_word<'a>(s: &'a str) -> &'a str
    s.split_whitespace().next().unwrap_or("")
}

impl User {
    fn name(&self) -> &str {  // Elision handles this
        &self.name
    }
}
```

### Serde Convention

```rust
use serde::{Deserialize, Serialize};

// 'de is the standard serde lifetime for borrowed data
#[derive(Deserialize)]
struct Request<'de> {
    #[serde(borrow)]
    name: &'de str,
    #[serde(borrow)]
    tags: Vec<&'de str>,
}
```

Related: `own-lifetime-elision`, `name-type-param-single`, `own-borrow-over-clone`

## name-type-param-single

> Use single uppercase letters for type parameters: `T`, `E`, `K`, `V`

### Why It Matters

Generic type parameters conventionally use single uppercase letters. This keeps signatures concise and follows established conventions that readers instantly recognize. `T` for "type", `E` for "error", `K` for "key", `V` for "value" are universal in Rust.

### Bad

```rust
// Verbose type parameters
struct Container<ElementType> {
    items: Vec<ElementType>,
}

fn process<InputType, OutputType>(input: InputType) -> OutputType { ... }

// Lowercase - looks like lifetime
struct Wrapper<t> { ... }  // Confusing
```

### Good

```rust
// Single uppercase letters
struct Container<T> {
    items: Vec<T>,
}

fn process<I, O>(input: I) -> O { ... }

// Standard conventions
struct HashMap<K, V> { ... }     // K=Key, V=Value
enum Result<T, E> { ... }         // T=Type, E=Error
enum Option<T> { ... }            // T=Type
struct Ref<'a, T> { ... }        // Lifetime + Type
```

### Standard Type Parameter Names

| Parameter | Meaning | Example |
|-----------|---------|---------|
| `T` | Type (generic) | `Vec<T>` |
| `E` | Error | `Result<T, E>` |
| `K` | Key | `HashMap<K, V>` |
| `V` | Value | `HashMap<K, V>` |
| `I` | Input / Item | `Iterator<Item = I>` |
| `O` | Output | `Fn(I) -> O` |
| `R` | Return / Result | `fn() -> R` |
| `S` | State | `StateMachine<S>` |
| `A` | Allocator | `Vec<T, A>` |
| `F` | Function | `map<F>(f: F)` |

### Multiple Type Parameters

```rust
// Use related letters
fn transform<I, O, E>(input: I) -> Result<O, E>
where
    I: Input,
    O: Output,
    E: Error,
{ ... }

// Or sequential: T, U, V
fn combine<T, U, V>(a: T, b: U) -> V { ... }

// Descriptive only when many parameters need clarity
struct Query<Db, Row, Err> { ... }
```

### Trait Bounds

```rust
// Keep type params short, move complexity to where clause
fn process<T, E>(value: T) -> Result<T, E>
where
    T: Clone + Debug + Send + Sync,
    E: Error + From<IoError>,
{ ... }

// Not inline
fn process<T: Clone + Debug + Send + Sync, E: Error + From<IoError>>(value: T) -> Result<T, E>
// Too long!
```

Related: `name-lifetime-short`, `name-types-camel`, `type-generic-bounds`

## name-as-free

> `as_` prefix: free reference conversion

### Why It Matters

Consistent naming helps users understand API cost. `as_` prefix signals a free (O(1), no allocation) conversion that returns a reference. This convention is used throughout the standard library.

### The Convention

| Prefix | Cost | Ownership | Example |
|--------|------|-----------|---------|
| `as_` | Free | `&T -> &U` | `str::as_bytes()` |
| `to_` | Expensive | `&T -> U` | `str::to_lowercase()` |
| `into_` | Variable | `T -> U` | `String::into_bytes()` |

### Examples

```rust
impl MyString {
    // as_ - free reference conversion
    pub fn as_str(&self) -> &str {
        &self.inner
    }
    
    pub fn as_bytes(&self) -> &[u8] {
        self.inner.as_bytes()
    }
}

impl Wrapper<T> {
    // as_ - returns reference to inner
    pub fn as_inner(&self) -> &T {
        &self.inner
    }
    
    pub fn as_inner_mut(&mut self) -> &mut T {
        &mut self.inner
    }
}
```

### Standard Library Examples

```rust
// String
let s = String::from("hello");
let bytes: &[u8] = s.as_bytes();    // Free, returns &[u8]
let str_ref: &str = s.as_str();     // Free, returns &str

// Vec
let v = vec![1, 2, 3];
let slice: &[i32] = v.as_slice();   // Free, returns &[i32]

// Path
let p = PathBuf::from("/home");
let path: &Path = p.as_path();      // Free, returns &Path

// OsString
let os = OsString::from("hello");
let os_str: &OsStr = os.as_os_str(); // Free, returns &OsStr
```

### Bad

```rust
impl MyType {
    // BAD: as_ but allocates
    pub fn as_string(&self) -> String {
        format!("{}", self.value)  // Allocates! Should be to_string()
    }
    
    // BAD: as_ but expensive
    pub fn as_processed(&self) -> &ProcessedData {
        // Actually does expensive computation
    }
}
```

### Good

```rust
impl MyType {
    // GOOD: Free reference
    pub fn as_str(&self) -> &str {
        &self.inner
    }
    
    // GOOD: to_ signals allocation
    pub fn to_string(&self) -> String {
        format!("{}", self.value)
    }
    
    // GOOD: into_ signals ownership transfer
    pub fn into_inner(self) -> Inner {
        self.inner
    }
}
```

Related: `name-to-expensive`, `name-into-ownership`

## name-to-expensive

> Use `to_` prefix for expensive conversions that allocate or compute

### Why It Matters

The `to_` prefix signals "this conversion has a cost"—typically allocation, cloning, or computation. Callers know to consider caching the result or avoiding repeated calls. This contrasts with `as_` (free reference conversion) and `into_` (ownership transfer).

### Bad

```rust
impl Name {
    // Misleading: suggests expensive operation
    fn as_uppercase(&self) -> String {
        self.0.to_uppercase()  // Allocates!
    }
    
    // Misleading: suggests cheap reference
    fn get_string(&self) -> String {
        self.0.clone()  // Allocates!
    }
}
```

### Good

```rust
impl Name {
    // to_ = allocates/computes
    fn to_uppercase(&self) -> String {
        self.0.to_uppercase()
    }
    
    // to_ = creates new value
    fn to_string(&self) -> String {
        self.0.clone()
    }
    
    // as_ = free reference (cheap)
    fn as_str(&self) -> &str {
        &self.0
    }
}
```

### Standard Library Examples

```rust
// to_ methods - all allocate or compute
let s: String = slice.to_vec();           // Allocates Vec
let s: String = "hello".to_string();      // Allocates String
let s: String = "HELLO".to_lowercase();   // Allocates new String
let s: String = path.to_string_lossy().into_owned();  // May allocate

// Contrast with as_ methods - all are free
let slice: &[u8] = s.as_bytes();          // Just reinterpret
let str_ref: &str = string.as_str();      // Just reference
let path: &Path = Path::new("foo");       // Just reference
```

### Conversion Method Prefixes

| Prefix | Cost | Ownership | Example |
|--------|------|-----------|---------|
| `as_` | Free (O(1)) | Borrows `&T` | `as_str()`, `as_bytes()` |
| `to_` | Allocates/Computes | Creates new | `to_string()`, `to_vec()` |
| `into_` | Usually free | Takes ownership | `into_inner()`, `into_vec()` |

### Custom Types

```rust
struct Email(String);

impl Email {
    // Cheap: just returns reference
    fn as_str(&self) -> &str {
        &self.0
    }
    
    // Expensive: allocates
    fn to_lowercase(&self) -> Email {
        Email(self.0.to_lowercase())
    }
    
    // Expensive: allocates
    fn to_display_format(&self) -> String {
        format!("<{}>", self.0)
    }
    
    // Ownership transfer: usually cheap
    fn into_string(self) -> String {
        self.0
    }
}
```

### to_owned() Pattern

```rust
// to_owned() for getting owned version of borrowed data
let borrowed: &str = "hello";
let owned: String = borrowed.to_owned();  // Allocates

let borrowed: &[i32] = &[1, 2, 3];
let owned: Vec<i32> = borrowed.to_owned();  // Allocates

// ToOwned trait
trait ToOwned {
    type Owned;
    fn to_owned(&self) -> Self::Owned;
}
```

Related: `name-as-free`, `name-into-ownership`, `own-cow-conditional`

## name-into-ownership

> Use `into_` prefix for ownership-consuming conversions

### Why It Matters

The `into_` prefix signals "this method consumes self and returns something else." The original value is moved and no longer usable. This ownership transfer is usually cheap (no allocation), but the caller loses access to the original. Clear naming prevents "use after move" confusion.

### Bad

```rust
impl Wrapper {
    // Misleading: doesn't indicate ownership transfer
    fn get_inner(self) -> Inner {  
        self.inner
    }
    
    // Misleading: suggests borrowing
    fn as_inner(self) -> Inner {  // Takes self by value!
        self.inner
    }
}
```

### Good

```rust
impl Wrapper {
    // into_ clearly shows ownership transfer
    fn into_inner(self) -> Inner {
        self.inner
    }
}

// Usage is clear
let wrapper = Wrapper::new(inner);
let inner = wrapper.into_inner();  // wrapper is consumed
// wrapper.foo();  // Error: use of moved value
```

### Standard Library Examples

```rust
// All consume self and return owned data
let string: String = "hello".to_string();
let bytes: Vec<u8> = string.into_bytes();  // String consumed

let path = PathBuf::from("/foo");
let os_string: OsString = path.into_os_string();  // PathBuf consumed

let boxed: Box<[i32]> = vec![1, 2, 3].into_boxed_slice();  // Vec consumed

let vec: Vec<u8> = boxed.into_vec();  // Box consumed
```

### into_iter() Pattern

```rust
let vec = vec![1, 2, 3];

// into_iter consumes the collection
for item in vec.into_iter() {  // or just: for item in vec
    // item is i32, not &i32
}
// vec is consumed, can't use anymore

// Contrast with iter() which borrows
let vec = vec![1, 2, 3];
for item in vec.iter() {
    // item is &i32
}
// vec still usable
```

### IntoIterator Trait

```rust
impl IntoIterator for MyCollection {
    type Item = Element;
    type IntoIter = std::vec::IntoIter<Element>;
    
    fn into_iter(self) -> Self::IntoIter {
        self.elements.into_iter()  // Consumes self
    }
}
```

### Conversion Prefix Summary

```rust
struct Buffer {
    data: Vec<u8>,
    name: String,
}

impl Buffer {
    // as_ : free borrow, returns reference
    fn as_slice(&self) -> &[u8] {
        &self.data
    }
    
    // to_ : allocates, creates new value
    fn to_vec(&self) -> Vec<u8> {
        self.data.clone()
    }
    
    // into_ : consumes self, usually cheap
    fn into_inner(self) -> Vec<u8> {
        self.data
    }
    
    // into_ : can destructure into parts
    fn into_parts(self) -> (Vec<u8>, String) {
        (self.data, self.name)
    }
}
```

Related: `name-as-free`, `name-to-expensive`, `api-from-not-into`
