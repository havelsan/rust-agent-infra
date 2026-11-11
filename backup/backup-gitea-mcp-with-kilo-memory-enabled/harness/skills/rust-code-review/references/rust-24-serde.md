---
name: rust-24-serde
description: Rust rules module 24: Serde. 8 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `serde-`
---

# Serde

Priority: MEDIUM. 8 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `serde-rename-all` - Match the external naming convention with `#[serde(rename_all = ...)]`
- `serde-default-compat` - Use `#[serde(default)]` for optional and backward-compatible fields
- `serde-skip-empty` - Omit empty fields with `skip_serializing_if`
- `serde-flatten` - Inline nested structs or capture extra keys with `#[serde(flatten)]`
- `serde-enum-representation` - Choose enum tagging deliberately: externally, internally, adjacently tagged, or untagged
- `serde-deny-unknown-fields` - Reject unexpected keys with `#[serde(deny_unknown_fields)]`
- `serde-custom-with` - Customize a field's (de)serialization with `with` / `serialize_with` / `deserialize_with`
- `serde-try-from-validate` - Validate while deserializing with `#[serde(try_from = "Raw")]`

---

## serde-rename-all

> Match the external naming convention with `#[serde(rename_all = ...)]`

### Why It Matters

Rust fields are `snake_case` by convention, but JSON APIs, GraphQL responses, and config formats often use `camelCase`, `kebab-case`, or `SCREAMING_SNAKE_CASE`. Renaming every field individually with `#[serde(rename = "...")]` is noisy and error-prone. A single `#[serde(rename_all = "camelCase")]` on the container keeps Rust idiomatic and the wire format correct in one declaration.

### Bad

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
struct UserProfile {
    #[serde(rename = "firstName")]
    first_name: String,
    #[serde(rename = "lastName")]
    last_name: String,
    #[serde(rename = "emailAddress")]
    email_address: String,
    #[serde(rename = "isActive")]
    is_active: bool,
}
```

### Good

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct UserProfile {
    first_name: String,
    last_name: String,
    email_address: String,
    is_active: bool,
    // per-field override: "type" is a keyword in Rust, so we rename it explicitly
    #[serde(rename = "type")]
    user_type: String,
}

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum Status {
    Active,
    Inactive,
    PendingVerification,
}
```

### Key Points

`rename_all` applies to both serialization and deserialization. Supported values:

| Value | Example field `foo_bar` becomes |
|---|---|
| `"camelCase"` | `fooBar` |
| `"PascalCase"` | `FooBar` |
| `"kebab-case"` | `foo-bar` |
| `"SCREAMING_SNAKE_CASE"` | `FOO_BAR` |
| `"snake_case"` | `foo_bar` (identity) |
| `"UPPERCASE"` | `FOOBAR` |
| `"lowercase"` | `foobar` |

A field-level `#[serde(rename = "...")]` always wins over the container-level `rename_all`, so use it for exceptions like reserved words or one-off mismatches. For enums, `rename_all` applies to variant names.

Related: `serde-default-compat`, `api-serde-optional`

## serde-default-compat

> Use `#[serde(default)]` for optional and backward-compatible fields

### Why It Matters

Without `#[serde(default)]`, any field missing from an incoming payload causes deserialization to fail with a "missing field" error. When you add new fields to a struct over time, older payloads that predate those fields will suddenly break. Marking fields (or the whole container) with `#[serde(default)]` fills missing keys from the type's `Default` implementation, enabling graceful forward compatibility.

### Bad

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
struct Config {
    host: String,
    port: u16,
    timeout_secs: u64,  // newly added — old configs don't have this, so they fail
    retries: u32,       // newly added — same problem
}
```

### Good

```rust
use serde::{Serialize, Deserialize};

fn default_timeout() -> u64 { 30 }
fn default_retries() -> u32 { 3 }

#[derive(Serialize, Deserialize, Debug)]
struct Config {
    host: String,
    port: u16,
    // fills from Default::default() (0u64) if missing
    #[serde(default)]
    timeout_secs: u64,
    // fills from the named function if missing
    #[serde(default = "default_retries")]
    retries: u32,
    // fills from Default (None) if missing
    #[serde(default)]
    tls_cert_path: Option<String>,
}

// Alternatively, annotate the whole container so every field uses its Default:
#[derive(Serialize, Deserialize, Debug, Default)]
#[serde(default)]
struct FeatureFlags {
    enable_caching: bool,    // false
    enable_metrics: bool,    // false
    max_connections: u32,    // 0
}
```

### Key Points

- **Field-level** `#[serde(default)]` — fills only that field; other required fields still fail if absent.
- **Field-level** `#[serde(default = "path")]` — calls a user-supplied function `fn() -> T`; use this when `Default` would produce the wrong value (e.g. `timeout = 30` rather than `0`).
- **Container-level** `#[serde(default)]` — applies to every field; the struct must implement `Default` (or `#[derive(Default)]`). Convenient for all-optional structs like feature-flag configs.
- The default function signature must be `fn() -> T` with no arguments and no generics.
- `#[serde(default)]` only affects **deserialization**. It has no effect on serialization; pair with `#[serde(skip_serializing_if = "...")]` if you also want to omit defaults on the way out.

### Caveats

Using container-level `#[serde(default)]` makes every field optional to deserializers, which can hide typos in field names. Prefer field-level annotation when only some fields are backward-compatible additions.

Related: `serde-skip-empty`, `api-default-impl`

## serde-skip-empty

> Omit empty fields with `skip_serializing_if`

### Why It Matters

Serializing `None` values as `null` and empty collections as `[]` bloats payloads, clutters logs, and can confuse clients that distinguish between a missing key and an explicit null. `#[serde(skip_serializing_if = "predicate")]` conditionally drops a field from output when the predicate returns true, keeping the wire format lean. `#[serde(skip)]` goes further and excludes a field from both serialization and deserialization entirely.

### Bad

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
struct ApiResponse {
    id: u64,
    name: String,
    description: Option<String>,  // serializes as null when None
    tags: Vec<String>,            // serializes as [] when empty
    error: Option<String>,        // serializes as null when None
}
```

Produces: `{"id":1,"name":"Alice","description":null,"tags":[],"error":null}`

### Good

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug)]
struct ApiResponse {
    id: u64,
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    tags: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
    // internal field excluded entirely from the wire format
    #[serde(skip)]
    _cache_key: Option<String>,
}

impl Default for ApiResponse {
    fn default() -> Self {
        ApiResponse {
            id: 0,
            name: String::new(),
            description: None,
            tags: Vec::new(),
            error: None,
            _cache_key: None,
        }
    }
}
```

Produces: `{"id":1,"name":"Alice"}` — absent fields are simply omitted.

### Key Points

- `skip_serializing_if` takes any path resolving to `fn(&T) -> bool`. Common choices:
  - `Option::is_none` for `Option<T>`
  - `Vec::is_empty` / `<[T]>::is_empty` for collections
  - `String::is_empty` for strings
  - A custom function for more complex conditions
- `#[serde(skip)]` removes the field from **both** directions. The type must implement `Default` so deserialization can still construct the struct (serde fills it with `Default::default()`).
- `#[serde(skip_serializing)]` skips only on the way out; `#[serde(skip_deserializing)]` skips only on the way in — useful when reading legacy fields you no longer write.
- Pair `skip_serializing_if` with `#[serde(default)]` so that a missing key on deserialization also produces the empty/`None` value rather than a hard error.

Related: `serde-default-compat`, `serde-rename-all`

## serde-flatten

> Inline nested structs or capture extra keys with `#[serde(flatten)]`

### Why It Matters

APIs frequently share a common set of fields across multiple message types (pagination metadata, audit timestamps, error envelopes). Duplicating those fields in every struct is fragile. `#[serde(flatten)]` merges a nested struct's fields directly into the parent's wire representation, so the JSON looks flat while the Rust code stays modular. The same attribute can also collect all unknown keys into a `HashMap`, giving you a "catch-all" bucket.

### Bad

```rust
use serde::{Serialize, Deserialize};

// Duplicated pagination fields in every list response
#[derive(Serialize, Deserialize, Debug)]
struct UserListResponse {
    users: Vec<String>,
    page: u32,
    per_page: u32,
    total: u64,
}

#[derive(Serialize, Deserialize, Debug)]
struct PostListResponse {
    posts: Vec<String>,
    page: u32,       // copy-paste
    per_page: u32,   // copy-paste
    total: u64,      // copy-paste
}
```

### Good

```rust
use serde::{Serialize, Deserialize};
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Debug)]
struct Pagination {
    page: u32,
    per_page: u32,
    total: u64,
}

#[derive(Serialize, Deserialize, Debug)]
struct UserListResponse {
    users: Vec<String>,
    #[serde(flatten)]
    pagination: Pagination,
}

#[derive(Serialize, Deserialize, Debug)]
struct PostListResponse {
    posts: Vec<String>,
    #[serde(flatten)]
    pagination: Pagination,
}

// Capture unknown/dynamic keys into a map
#[derive(Serialize, Deserialize, Debug)]
struct FlexibleConfig {
    name: String,
    version: u32,
    #[serde(flatten)]
    extra: HashMap<String, serde_json::Value>,
}
```

`UserListResponse` serializes to `{"users":[...],"page":1,"per_page":20,"total":100}` — the `Pagination` fields appear at the top level, not nested under a `"pagination"` key.

### Key Points

- Works with both structs and maps. The flattened type must implement `Serialize`/`Deserialize`.
- Multiple `#[serde(flatten)]` fields are allowed on the same struct, as long as the key sets don't overlap at runtime.
- `HashMap<String, serde_json::Value>` (or any map type) as a flattened field acts as a catch-all for keys not matched by other fields — useful for extensible configs and pass-through proxies.

### Caveats

- `#[serde(flatten)]` is **incompatible with `#[serde(deny_unknown_fields)]`** on the same struct. The two attributes conflict because `flatten` needs to forward unrecognized keys.
- Flattening uses a less efficient internal deserialization path (content buffering) compared to normal struct deserialization. Avoid it on extremely hot deserialization paths.
- `flatten` does not work with non-self-describing formats like `bincode` that don't support maps with arbitrary keys.

Related: `serde-deny-unknown-fields`, `serde-enum-representation`

## serde-enum-representation

> Choose enum tagging deliberately: externally, internally, adjacently tagged, or untagged

### Why It Matters

Serde's default enum representation (externally tagged) wraps every variant in an object keyed by variant name. That format can clash with external APIs, event systems, or config schemas that use a discriminator field. Picking the wrong tagging strategy produces a mismatch between your wire format and the expected schema, leading to silent parse failures or round-trip data loss.

### Bad

```rust
use serde::{Serialize, Deserialize};

// Default: externally tagged. Serializes as {"Circle":{"radius":5.0}}
// Most REST APIs expect {"type":"circle","radius":5.0} instead.
#[derive(Serialize, Deserialize, Debug)]
enum Shape {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
}
```

### Good

```rust
use serde::{Serialize, Deserialize};

// Externally tagged (default) — {"Circle":{"radius":5.0}}
// Good for: Rust-to-Rust, when the variant name IS the key
#[derive(Serialize, Deserialize, Debug)]
enum ShapeExternal {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
}

// Internally tagged — {"type":"Circle","radius":5.0}
// Good for: REST APIs with a discriminator field; all variants must be structs/maps
#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "type")]
enum ShapeInternal {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
}

// Adjacently tagged — {"t":"Circle","c":{"radius":5.0}}
// Good for: when variants may contain primitives or vecs (internally tagged can't handle those)
#[derive(Serialize, Deserialize, Debug)]
#[serde(tag = "t", content = "c")]
enum ShapeAdjacent {
    Circle { radius: f64 },
    Rectangle { width: f64, height: f64 },
    Count(u32),  // tuple variant — works here, but NOT with internally tagged
}

// Untagged — {"radius":5.0}
// Good for: wrapping a small number of clearly distinct types; avoid otherwise
#[derive(Serialize, Deserialize, Debug)]
#[serde(untagged)]
enum Value {
    Integer(i64),
    Float(f64),
    Text(String),
}
```

### Comparison Table

| Strategy | Attribute | Wire form (Circle) | Tuple variant |
|---|---|---|---|
| Externally tagged | (default) | `{"Circle":{"radius":5}}` | yes |
| Internally tagged | `#[serde(tag = "type")]` | `{"type":"Circle","radius":5}` | no |
| Adjacently tagged | `#[serde(tag="t", content="c")]` | `{"t":"Circle","c":{"radius":5}}` | yes |
| Untagged | `#[serde(untagged)]` | `{"radius":5}` | yes |

### Caveats

- **Untagged** deserializes by trying each variant in declaration order; it is slower, can silently pick the wrong variant, and produces generic error messages. Reserve it for small, structurally distinct sets (numbers vs strings).
- **Internally tagged** cannot represent tuple variants or newtype variants wrapping primitives/vecs — use adjacently tagged instead.
- All variants in an internally tagged enum must serialize as maps (structs or `HashMap`).

Related: `type-enum-states`, `api-non-exhaustive`, `serde-flatten`

## serde-deny-unknown-fields

> Reject unexpected keys with `#[serde(deny_unknown_fields)]`

### Why It Matters

By default, serde silently discards any key in the input that doesn't match a struct field. For user-facing config files and strict API contracts this is dangerous: a typo like `"timout_secs"` passes validation without error, and the intended field is simply never set. `#[serde(deny_unknown_fields)]` turns unrecognized keys into hard errors, surfacing mistakes immediately.

### Bad

```rust
use serde::{Serialize, Deserialize};
use serde_json;

#[derive(Serialize, Deserialize, Debug)]
struct ServerConfig {
    host: String,
    port: u16,
    timeout_secs: u64,
}

fn main() {
    // "timout_secs" is a typo — serde silently ignores it, timeout stays 0
    let json = r#"{"host":"localhost","port":8080,"timout_secs":30}"#;
    let cfg: ServerConfig = serde_json::from_str(json).unwrap();
    println!("{:?}", cfg); // timeout_secs is 0, not 30
}
```

### Good

```rust
use serde::{Serialize, Deserialize};
use serde_json;

#[derive(Serialize, Deserialize, Debug)]
#[serde(deny_unknown_fields)]
struct ServerConfig {
    host: String,
    port: u16,
    timeout_secs: u64,
}

fn parse_config(json: &str) -> Result<ServerConfig, serde_json::Error> {
    serde_json::from_str(json)
}

fn main() {
    // Typo is now a hard error
    let bad = r#"{"host":"localhost","port":8080,"timout_secs":30}"#;
    assert!(parse_config(bad).is_err());

    // Correct input still works
    let good = r#"{"host":"localhost","port":8080,"timeout_secs":30}"#;
    let cfg = parse_config(good).unwrap();
    println!("{:?}", cfg);
}
```

### Key Points

- Apply `deny_unknown_fields` to **config-file structs**, **request/response DTOs**, and any struct that forms a public API contract where typos must be caught.
- Skip it for **flexible or extensible** structs where callers are expected to pass extra metadata. Use `#[serde(flatten)]` with a `HashMap` catch-all instead.
- The attribute works with JSON, TOML, YAML, and most self-describing formats.
- Error messages name the unexpected field, making them actionable for end users.

### Caveats

`#[serde(deny_unknown_fields)]` is **incompatible with `#[serde(flatten)]`** on the same struct. `flatten` needs to pass unmatched keys down to the flattened field; `deny_unknown_fields` intercepts them first. If you need both behaviors, split the struct or use a two-pass approach (deserialize into a `serde_json::Value`, then convert).

Related: `serde-flatten`, `api-parse-dont-validate`

## serde-custom-with

> Customize a field's (de)serialization with `with` / `serialize_with` / `deserialize_with`

### Why It Matters

Some types have a natural Rust representation that differs from what the wire format expects: a `Duration` stored as whole seconds, raw bytes encoded as base64, a timestamp as an ISO-8601 string. Changing the field type just to satisfy serde pollutes the domain model. A `#[serde(with = "module")]` (or the one-sided `serialize_with`/`deserialize_with`) attributes point serde at custom conversion functions without touching the field type.

### Bad

```rust
use serde::{Serialize, Deserialize};

// Forces a u64 "seconds" field instead of the natural Duration type
#[derive(Serialize, Deserialize, Debug)]
struct Task {
    name: String,
    timeout_secs: u64,   // callers must manually convert to/from Duration
}
```

### Good

```rust
use serde::{Serialize, Deserialize, Serializer, Deserializer};
use std::time::Duration;

mod duration_secs {
    use super::*;

    pub fn serialize<S>(duration: &Duration, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_u64(duration.as_secs())
    }

    pub fn deserialize<'de, D>(deserializer: D) -> Result<Duration, D::Error>
    where
        D: Deserializer<'de>,
    {
        let secs = u64::deserialize(deserializer)?;
        Ok(Duration::from_secs(secs))
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Task {
    name: String,
    // wire format: {"name":"...", "timeout": 30}
    // Rust type: Duration — no manual conversion needed at call sites
    #[serde(with = "duration_secs", rename = "timeout")]
    timeout: Duration,
}

// One-sided variants when you only need to customize one direction:
#[derive(Serialize, Deserialize, Debug)]
struct Report {
    title: String,
    #[serde(serialize_with = "duration_secs::serialize")]
    elapsed: Duration,
    // deserialize_with leaves the deserialize direction at its default
}
```

### Key Points

- `#[serde(with = "module")]` requires the module to expose both `pub fn serialize<S>(&T, S) -> Result<S::Ok, S::Error>` and `pub fn deserialize<'de, D>(D) -> Result<T, D::Error>`.
- Use `serialize_with = "path"` or `deserialize_with = "path"` to customize only one direction, leaving the other at its derived default.
- The module approach (`with`) is more reusable: define it once, apply it anywhere. Some crates (e.g. `time`, `chrono`, `uuid`) ship ready-made `with` modules in their serde feature.
- For widespread custom representations, a newtype wrapper with its own `Serialize`/`Deserialize` impl is often cleaner than repeating `#[serde(with = "...")]` everywhere.

### Caveats

The `with` module functions must match the exact signatures serde expects. The `serialize` function receives `&T` (a reference), not `T`.

Related: `serde-try-from-validate`, `type-newtype-validated`

## serde-try-from-validate

> Validate while deserializing with `#[serde(try_from = "Raw")]`

### Why It Matters

Running validation after deserialization means you can construct an invalid value in memory, even briefly. Parse-don't-validate says to make invalid states unrepresentable. `#[serde(try_from = "Raw")]` wires the deserializer directly through a `TryFrom` conversion: serde reads the raw type, then your conversion either produces the validated value or returns an error — so an invalid instance is never constructed.

### Bad

```rust
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Email(String);

impl Email {
    fn new(s: String) -> Result<Self, String> {
        if s.contains('@') {
            Ok(Email(s))
        } else {
            Err(format!("invalid email: {s}"))
        }
    }
}

// Caller must validate after deserialization — easy to forget:
fn process(json: &str) -> Result<(), Box<dyn std::error::Error>> {
    let email: Email = serde_json::from_str(json)?;
    // nothing stops "notanemail" from being deserialized and used
    println!("{:?}", email);
    Ok(())
}
```

### Good

```rust
use serde::{Serialize, Deserialize};
use serde_json;

#[derive(Debug, Clone)]
struct Email(String);

impl TryFrom<String> for Email {
    type Error = String;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.contains('@') && !s.starts_with('@') && !s.ends_with('@') {
            Ok(Email(s))
        } else {
            Err(format!("invalid email address: {s}"))
        }
    }
}

// For the serialize direction: implement From<Email> for String, then add into = "String"
impl From<Email> for String {
    fn from(e: Email) -> String {
        e.0
    }
}

// Deserialize: serde reads a String, then calls Email::try_from — error if invalid.
// Serialize:   serde calls String::from(email) — converts back to the raw type.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(try_from = "String", into = "String")]
struct ValidatedEmail(String);

impl TryFrom<String> for ValidatedEmail {
    type Error = String;

    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.contains('@') && !s.starts_with('@') && !s.ends_with('@') {
            Ok(ValidatedEmail(s))
        } else {
            Err(format!("invalid email address: {s}"))
        }
    }
}

impl From<ValidatedEmail> for String {
    fn from(e: ValidatedEmail) -> String {
        e.0
    }
}

fn main() {
    // Valid email round-trips fine
    let good = serde_json::from_str::<ValidatedEmail>("\"user@example.com\"").unwrap();
    println!("{}", serde_json::to_string(&good).unwrap());

    // Invalid email is rejected at parse time — never enters the program
    let bad = serde_json::from_str::<ValidatedEmail>("\"notanemail\"");
    assert!(bad.is_err());
}
```

### Key Points

- `#[serde(try_from = "Raw")]` — serde deserializes `Raw`, then calls `T::try_from(raw)?`. Any error from `TryFrom` becomes a serde deserialization error.
- `#[serde(into = "Raw")]` — serde calls `Raw::from(value)` for serialization. The type must also implement `Clone` because serde may clone before converting.
- The `Raw` type must itself implement `Deserialize` (for `try_from`) and the target must implement `Into<Raw>` / `From<T> for Raw` (for `into`).
- This pattern is composable with other rules: define the `TryFrom` logic once and reuse it in both serde and non-serde code paths (e.g. CLI argument parsing, form validation).

### Caveats

`#[serde(try_from)]` and `#[serde(into)]` are mutually exclusive with deriving `Serialize`/`Deserialize` via field-by-field derivation on the same struct — the attribute replaces the derived impl entirely.

Related: `api-parse-dont-validate`, `type-newtype-validated`, `serde-custom-with`
