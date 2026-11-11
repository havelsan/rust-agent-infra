---
name: rust-21-type-safety-2of2
description: Rust rules module 21: Type Safety (part 2 of 2). 7 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `type-`
---

# Type Safety (part 2/2)

Priority: MEDIUM. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `type-never-diverge` - Use `!` (never type) for functions that never return
- `type-generic-bounds` - Add trait bounds only where needed, prefer where clauses for readability
- `type-no-stringly` - Avoid stringly-typed APIs; use enums, newtypes, or validated types
- `type-repr-transparent` - Use `#[repr(transparent)]` for newtypes in FFI contexts
- `type-deref-coercion` - Implement `Deref`/`DerefMut` only for smart-pointer and transparent wrapper types
- `type-display-vs-debug` - Use `Display` for user-facing output and `Debug` for diagnostics; never swap them
- `type-numeric-fmt` - Implement `LowerHex`, `UpperHex`, `Octal`, and `Binary` for numeric newtypes

---

## type-never-diverge

> Use `!` (never type) for functions that never return

### Why It Matters

The never type `!` indicates a function will never return normally—it either loops forever, panics, or exits the process. This helps the compiler understand control flow and enables `!` to coerce to any type, making it useful in match arms and expressions.

### Bad

```rust
// Return type doesn't indicate non-returning
fn infinite_loop() {
    loop {
        process_events();
    }
    // Implicit () return type, but never returns
}

// Using Option when it always panics
fn unreachable_code() -> Option<()> {
    panic!("This should never be called");
}
```

### Good

```rust
// ! indicates function never returns
fn infinite_loop() -> ! {
    loop {
        process_events();
    }
}

fn abort_with_error(msg: &str) -> ! {
    eprintln!("Fatal error: {}", msg);
    std::process::exit(1);
}

fn panic_handler() -> ! {
    panic!("Unexpected state");
}
```

### Coercion to Any Type

```rust
// ! coerces to any type
fn get_value(opt: Option<i32>) -> i32 {
    match opt {
        Some(v) => v,
        None => panic!("No value"),  // panic! returns !, coerces to i32
    }
}

// Useful in Result handling
fn must_get_config() -> Config {
    match load_config() {
        Ok(c) => c,
        Err(e) => {
            log_error(&e);
            std::process::exit(1)  // Returns !, coerces to Config
        }
    }
}
```

### Standard Library Examples

```rust
// std::process::exit
pub fn exit(code: i32) -> !

// panic! macro
// Expands to an expression of type !

// std::hint::unreachable_unchecked
pub unsafe fn unreachable_unchecked() -> !

// loop {} with no break
fn forever() -> ! {
    loop {}
}
```

### In Match Expressions

```rust
enum State {
    Running,
    Stopped,
    Error,
}

fn get_status(state: &State) -> &str {
    match state {
        State::Running => "running",
        State::Stopped => "stopped",
        State::Error => unreachable!(),  // ! coerces to &str
    }
}

// With Result
fn process(r: Result<Data, Error>) -> Data {
    match r {
        Ok(d) => d,
        Err(e) => panic!("Unexpected error: {}", e),  // ! coerces to Data
    }
}
```

### Diverging Closures

```rust
// Closures that never return
let handler: fn() -> ! = || {
    panic!("Handler called");
};

// In thread spawn
std::thread::spawn(|| -> ! {
    loop {
        process_work();
    }
});
```

### Stability Notes

`fn f() -> !` (never type as a return type) has been **stable since Rust 1.41** — no feature gate needed.

Using `!` as an *arbitrary type argument* (e.g. `Result<(), !>`) still requires the nightly feature gate:

```rust
// Nightly only — using ! as a type argument
#![feature(never_type)]

type NeverResult = Result<(), !>;  // Can never be Err
```

On stable Rust, use `std::convert::Infallible` as the conventional substitute:

```rust
// Stable: Infallible is the standard stand-in for !
type StableNeverResult = Result<(), std::convert::Infallible>;
```

Related: `err-result-over-panic`, `type-result-fallible`, `opt-cold-unlikely`

## type-generic-bounds

> Add trait bounds only where needed, prefer where clauses for readability

### Why It Matters

Trait bounds constrain what types can be used with generic code. Adding unnecessary bounds limits flexibility. Adding bounds in the right place (impl vs function vs where clause) affects usability and readability. Well-placed bounds keep APIs flexible while ensuring type safety.

### Bad

```rust
// Bounds on struct definition - limits all uses
struct Container<T: Clone + Debug> {  // Even storage requires Clone?
    items: Vec<T>,
}

// Inline bounds make signature hard to read
fn process<T: Clone + Debug + Send + Sync + 'static, E: Error + Send + Clone>(
    value: T
) -> Result<T, E> { ... }

// Redundant bounds
fn print_twice<T: Clone + Debug>(value: T)
where
    T: Clone,  // Already specified above
{ ... }
```

### Good

```rust
// No bounds on struct - store anything
struct Container<T> {
    items: Vec<T>,
}

// Bounds only on impls that need them
impl<T: Clone> Container<T> {
    fn duplicate(&self) -> Self {
        Container { items: self.items.clone() }
    }
}

impl<T: Debug> Container<T> {
    fn debug_print(&self) {
        println!("{:?}", self.items);
    }
}

// Where clause for readability
fn process<T, E>(value: T) -> Result<T, E>
where
    T: Clone + Debug + Send + Sync + 'static,
    E: Error + Send + Clone,
{ ... }
```

### Bound Placement

```rust
// On struct: affects all uses of the type
struct MustBeClone<T: Clone> { data: T }  // Rarely needed

// On impl: affects specific functionality
impl<T: Clone> Container<T> { ... }  // Common pattern

// On function: affects that function only
fn requires_send<T: Send>(value: T) { ... }

// Recommendation: start with no bounds, add as needed
```

### Where Clause Benefits

```rust
// Inline: hard to read
fn complex<T: Clone + Debug + Send, U: AsRef<str> + Into<String>>(t: T, u: U) { }

// Where clause: clear and scannable
fn complex<T, U>(t: T, u: U)
where
    T: Clone + Debug + Send,
    U: AsRef<str> + Into<String>,
{ }

// Essential for complex bounds
fn foo<T, U>(t: T, u: U)
where
    T: Iterator<Item = U>,
    U: Clone + Into<String>,
    Vec<U>: Debug,  // Bounds on expressions
{ }
```

### Implied Bounds

```rust
// Supertrait bounds are implied
trait Foo: Clone + Debug {}

fn process<T: Foo>(value: T) {
    // T: Clone and T: Debug are implied by T: Foo
    let cloned = value.clone();
    println!("{:?}", cloned);
}

// Associated type bounds
fn process<I>(iter: I)
where
    I: Iterator,
    I::Item: Clone,  // Bound on associated type
{ }
```

### Conditional Trait Implementation

```rust
struct Wrapper<T>(T);

// Implement Clone only when T: Clone
impl<T: Clone> Clone for Wrapper<T> {
    fn clone(&self) -> Self {
        Wrapper(self.0.clone())
    }
}

// Implement Debug only when T: Debug  
impl<T: Debug> Debug for Wrapper<T> {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        f.debug_tuple("Wrapper").field(&self.0).finish()
    }
}

// Wrapper<i32> is Clone + Debug
// Wrapper<NonCloneable> is neither
```

Related: `api-impl-into`, `api-impl-asref`, `name-type-param-single`, `trait-dyn-vs-generic`, `trait-associated-type-vs-generic`

## type-no-stringly

> Avoid stringly-typed APIs; use enums, newtypes, or validated types

### Why It Matters

Strings accept any value—typos, wrong formats, invalid data all compile fine. Enums, newtypes, and validated types catch errors at compile time or construction time, not runtime. They also provide better IDE support, documentation, and make invalid states unrepresentable.

### Bad

```rust
// Status as string - easy to get wrong
fn set_status(status: &str) {
    match status {
        "pending" => { ... }
        "active" => { ... }
        "completed" => { ... }
        _ => panic!("Unknown status"),  // Runtime error
    }
}

// Easy to misuse
set_status("pending");   // OK
set_status("Pending");   // Runtime error - wrong case
set_status("aktive");    // Runtime error - typo
set_status("done");      // Runtime error - wrong word

// Configuration as strings
fn configure(key: &str, value: &str) {
    // No type safety, no validation
}
```

### Good

```rust
// Status as enum - compile-time safety
enum Status {
    Pending,
    Active,
    Completed,
}

fn set_status(status: Status) {
    match status {
        Status::Pending => { ... }
        Status::Active => { ... }
        Status::Completed => { ... }
    }  // Exhaustive - compiler checks all cases
}

// Can only pass valid values
set_status(Status::Pending);  // OK
set_status(Status::Aktivev);  // Compile error - typo caught!

// Configuration with typed builder
struct Config {
    timeout: Duration,
    retries: u32,
    mode: Mode,
}

enum Mode { Fast, Safe, Balanced }
```

### Parsing at Boundaries

```rust
use std::str::FromStr;

#[derive(Debug, Clone, Copy)]
enum Priority {
    Low,
    Medium,
    High,
}

impl FromStr for Priority {
    type Err = ParseError;
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "low" => Ok(Priority::Low),
            "medium" | "med" => Ok(Priority::Medium),
            "high" => Ok(Priority::High),
            _ => Err(ParseError::UnknownPriority(s.to_string())),
        }
    }
}

// Parse once at boundary
fn handle_request(priority_str: &str) -> Result<(), Error> {
    let priority: Priority = priority_str.parse()?;
    // From here, priority is type-safe
    process(priority);
    Ok(())
}
```

### Validated Newtypes

```rust
// Instead of string for email
struct Email(String);

impl Email {
    fn new(s: &str) -> Result<Self, ValidationError> {
        if is_valid_email(s) {
            Ok(Email(s.to_string()))
        } else {
            Err(ValidationError::InvalidEmail)
        }
    }
}

// Instead of string for UUID
struct UserId(uuid::Uuid);

// Instead of string for paths
struct ConfigPath(PathBuf);
```

### With Serde

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum EventType {
    UserCreated,
    UserDeleted,
    UserUpdated,
}

// JSON: {"type": "user_created", ...}
// Automatically validated during deserialization
```

Related: `anti-stringly-typed`, `type-newtype-validated`, `type-enum-states`

## type-repr-transparent

> Use `#[repr(transparent)]` for newtypes in FFI contexts

### Why It Matters

`#[repr(transparent)]` guarantees a newtype has the same memory layout as its inner type. This is essential for FFI where you need type safety in Rust but must match C ABI layouts. Without it, the compiler may add padding or change layout.

### Bad

```rust
// No layout guarantee - might not match inner type in FFI
struct Handle(u64);

// Passing to C code might fail
extern "C" {
    fn process_handle(h: Handle);  // May not work correctly
}

// Wrapping C type without layout guarantee
struct SafePointer(*mut c_void);
```

### Good

```rust
// Guaranteed same layout as inner type
#[repr(transparent)]
struct Handle(u64);

// Safe for FFI
extern "C" {
    fn process_handle(h: Handle);  // Works - same layout as u64
}

// FFI pointer wrapper
#[repr(transparent)]
struct SafePointer(*mut c_void);

impl SafePointer {
    // Safe Rust API around raw pointer
    pub fn new(ptr: *mut c_void) -> Option<Self> {
        if ptr.is_null() {
            None
        } else {
            Some(SafePointer(ptr))
        }
    }
}
```

### What repr(transparent) Guarantees

```rust
use std::mem::{size_of, align_of};

#[repr(transparent)]
struct Meters(f64);

// Same size
assert_eq!(size_of::<Meters>(), size_of::<f64>());

// Same alignment
assert_eq!(align_of::<Meters>(), align_of::<f64>());

// Same ABI - can pass where f64 expected
extern "C" fn measure(distance: Meters) { ... }
```

### With PhantomData

```rust
use std::marker::PhantomData;

// PhantomData is zero-sized, doesn't affect layout
#[repr(transparent)]
struct TypedHandle<T> {
    raw: u64,
    _marker: PhantomData<T>,  // Zero-sized, ignored for layout
}

// Still same layout as u64
assert_eq!(size_of::<TypedHandle<String>>(), size_of::<u64>());
```

### NonZero Wrappers

```rust
use std::num::NonZeroU64;

#[repr(transparent)]
struct NonZeroHandle(NonZeroU64);

// Inherits null-pointer optimization
assert_eq!(size_of::<Option<NonZeroHandle>>(), size_of::<u64>());
```

### FFI Pattern

```rust
mod ffi {
    use std::os::raw::c_int;
    
    #[repr(transparent)]
    pub struct FileDescriptor(c_int);
    
    extern "C" {
        pub fn open(path: *const i8, flags: c_int) -> FileDescriptor;
        pub fn close(fd: FileDescriptor) -> c_int;
        pub fn read(fd: FileDescriptor, buf: *mut u8, len: usize) -> isize;
    }
}

// Safe wrapper
pub struct File {
    fd: ffi::FileDescriptor,
}

impl File {
    pub fn open(path: &str) -> std::io::Result<Self> {
        let c_path = std::ffi::CString::new(path)?;
        let fd = unsafe { ffi::open(c_path.as_ptr(), 0) };
        // ... error handling
        Ok(File { fd })
    }
}
```

### When to Use

| Scenario | Use `#[repr(transparent)]`? |
|----------|----------------------------|
| FFI newtype wrappers | Yes |
| Type-safe handles | Yes |
| NonZero optimization | Yes |
| Pure Rust newtypes | Optional (doesn't hurt) |
| Multi-field structs | N/A (only for single-field) |

Related: `type-newtype-ids`, `type-phantom-marker`, `api-newtype-safety`

## type-deref-coercion

> Implement `Deref`/`DerefMut` only for smart-pointer and transparent wrapper types

### Why It Matters

`Deref` coercions are what make `Box<T>`, `Arc<T>`, `String`, and `Vec<T>` ergonomic — they let the inner type's methods surface through the wrapper transparently. The Rust API Guidelines (C-DEREF) specify this usage precisely: implement `Deref<Target = T>` when your type *is* a smart pointer or a transparent container for `T`. Using it as an OOP-style inheritance mechanism pollutes method resolution, confuses readers, and makes refactoring hazardous because adding methods to `T` silently affects every wrapper that `Deref`s to it.

### Bad

```rust
struct User {
    name: String,
    email: String,
}

struct AdminUser(User);

// Anti-pattern: using Deref to "inherit" User methods on AdminUser
impl std::ops::Deref for AdminUser {
    type Target = User;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

// Now AdminUser silently exposes all User fields/methods —
// callers can't tell what AdminUser owns vs. inherits.
fn greet(admin: &AdminUser) {
    println!("hello, {}", admin.name); // surprising implicit deref
}
```

### Good

```rust
// Smart-pointer/transparent wrapper: correct use of Deref
struct MyBox<T>(T);

impl<T> std::ops::Deref for MyBox<T> {
    type Target = T;
    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl<T> std::ops::DerefMut for MyBox<T> {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

// Domain types: expose only the API you intend, explicitly
struct User {
    pub name: String,
    pub email: String,
}

struct AdminUser(User);

impl AdminUser {
    pub fn name(&self) -> &str {
        &self.0.name
    }

    pub fn email(&self) -> &str {
        &self.0.email
    }

    pub fn can_delete_users(&self) -> bool {
        true
    }
}

fn greet(admin: &AdminUser) {
    println!("hello, {}", admin.name()); // explicit, readable
}
```

### Legitimate Uses

- `Box<T>`, `Rc<T>`, `Arc<T>` — pointer indirection
- `String` → `str`, `Vec<T>` → `[T]` — owned-to-borrowed transparent containers
- `MutexGuard<T>` → `T` — RAII guards that provide temporary access
- Newtype wrappers where the entire semantic purpose is "this is a `T` with additional invariants"

Related: `api-newtype-safety`, `type-newtype-ids`, `own-borrow-over-clone`

## type-display-vs-debug

> Use `Display` for user-facing output and `Debug` for diagnostics; never swap them

### Why It Matters

`Debug` (`{:?}`) is for developers: logs, panic messages, test assertions, and `dbg!()`. It should always be derived and reflects internal structure. `Display` (`{}`) is for end users: CLI output, error messages surfaced to humans, and log fields meant to be read in production. `std::error::Error` requires `Display` so that error chains read naturally. Routing `Debug` output to users leaks implementation details; routing `Display` output to log frameworks loses structural information.

### Bad

```rust
#[derive(Debug)]
struct ParseError {
    input: String,
    line: u32,
}

// Mistake 1: using Debug output in a user-facing message
fn report_error(e: &ParseError) {
    eprintln!("failed: {:?}", e); // leaks internal field names
}

// Mistake 2: implementing Display by calling debug
use std::fmt;
impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}", self) // wrong — duplicates Debug
    }
}
```

### Good

```rust
use std::fmt;

#[derive(Debug)] // derive Debug for free diagnostic output
struct ParseError {
    input: String,
    line: u32,
}

// Hand-write Display for a clean, human-readable message
impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "parse error on line {}: {:?}", self.line, self.input)
    }
}

impl std::error::Error for ParseError {}

fn main() {
    let e = ParseError { input: "foo bar".into(), line: 42 };

    // User-facing: clean sentence
    eprintln!("error: {e}");

    // Developer/log: structured dump
    eprintln!("debug: {e:?}");
}
```

### Guidelines

| Trait | Format | Audience | How to implement |
|-------|--------|----------|-----------------|
| `Debug` | `{:?}` / `{:#?}` | Developers, logs | `#[derive(Debug)]` (almost always) |
| `Display` | `{}` | End users, error messages | Hand-write to describe the condition clearly |

- Never derive `Display` — it must be intentionally written.
- `#[derive(Debug)]` on every public type (API Guidelines C-DEBUG).
- If your error type implements `std::error::Error`, its `Display` output becomes the human-readable error message that propagates through `anyhow::Context` and similar.
- The `{:#?}` pretty-print form is still `Debug`; use it in tests for readable assertion output, not in user-facing code.

Related: `api-common-traits`, `err-thiserror-lib`, `type-numeric-fmt`

## type-numeric-fmt

> Implement `LowerHex`, `UpperHex`, `Octal`, and `Binary` for numeric newtypes

### Why It Matters

Rust's API Guidelines (C-NUM-FMT) state that numeric types should support `{:x}`, `{:X}`, `{:o}`, and `{:b}` wherever the underlying integer type does. A numeric newtype that silently drops these format specifiers is an ergonomic regression — callers who reach for `{:x}` to debug a bitmask or address will hit a compile error instead. The fix is a one-liner per trait that forwards to the inner value's formatter.

### Bad

```rust
use std::fmt;

struct Mask(u32);

impl fmt::Display for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

fn main() {
    let m = Mask(0xDEAD_BEEF);
    println!("{}", m);   // ok
    // println!("{:x}", m); // compile error: Mask doesn't implement LowerHex
}
```

### Good

```rust
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Mask(u32);

impl fmt::Display for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Display::fmt(&self.0, f)
    }
}

impl fmt::LowerHex for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::LowerHex::fmt(&self.0, f)
    }
}

impl fmt::UpperHex for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::UpperHex::fmt(&self.0, f)
    }
}

impl fmt::Octal for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Octal::fmt(&self.0, f)
    }
}

impl fmt::Binary for Mask {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Binary::fmt(&self.0, f)
    }
}

fn main() {
    let m = Mask(0xDEAD_BEEF);
    println!("{m}");          // 3735928559
    println!("{m:x}");        // deadbeef
    println!("{m:X}");        // DEADBEEF
    println!("{m:#010x}");    // 0xdeadbeef
    println!("{m:o}");        // 33653337357
    println!("{m:b}");        // 11011110101011011011111011101111
}
```

### Notes

- Forward through the inner type's trait implementation (e.g., `fmt::LowerHex::fmt(&self.0, f)`) so that format flags like `#`, `0`, and width are handled correctly by the inner type.
- Apply this to any newtype whose inner type is a primitive integer (`u8`–`u128`, `i8`–`i128`, `usize`, `isize`).
- Skip `Octal`/`Binary` if there is genuinely no domain reason to print the value in those bases (e.g., a purely decimal `Count` newtype), but always implement `LowerHex`/`UpperHex` for any mask, address, or identifier type.

Related: `type-newtype-ids`, `type-display-vs-debug`
