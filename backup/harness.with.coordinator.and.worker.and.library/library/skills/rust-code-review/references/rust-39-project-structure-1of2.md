---
name: rust-39-project-structure-1of2
description: Rust rules module 39: Project Structure (part 1 of 2). 7 rules, priority LOW. Load on its own to review or write Rust code against this topic only. Rule prefixes: `proj-`
---

# Project Structure (part 1/2)

Priority: LOW. 7 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `proj-lib-main-split` - Keep `main.rs` minimal, logic in `lib.rs`
- `proj-mod-by-feature` - Organize modules by feature, not type
- `proj-flat-small` - Keep small projects flat
- `proj-mod-rs-dir` - Use mod.rs for multi-file modules
- `proj-pub-crate-internal` - Use pub(crate) for internal APIs
- `proj-pub-super-parent` - Use pub(super) for parent-only visibility
- `proj-pub-use-reexport` - Use pub use for clean public API

---

## proj-lib-main-split

> Keep `main.rs` minimal, logic in `lib.rs`

### Why It Matters

Putting your logic in `lib.rs` makes it testable, reusable, and keeps `main.rs` as a thin entry point. Integration tests can only access your library crate, not binary code in `main.rs`.

### Bad

```rust
// src/main.rs - everything here
fn main() {
    let args = parse_args();
    let config = load_config(&args.config_path).unwrap();
    let db = connect_database(&config.db_url).unwrap();
    
    // Hundreds of lines of application logic...
    // All untestable from integration tests!
}

fn parse_args() -> Args { /* ... */ }
fn load_config(path: &str) -> Result<Config, Error> { /* ... */ }
fn connect_database(url: &str) -> Result<Db, Error> { /* ... */ }
// ... more functions that can't be tested
```

### Good

```rust
// src/main.rs - thin entry point
use my_app::{run, Config};

fn main() -> anyhow::Result<()> {
    let config = Config::from_env()?;
    run(config)
}

// src/lib.rs - all the logic
pub mod config;
pub mod database;
pub mod handlers;

pub use config::Config;

pub fn run(config: Config) -> anyhow::Result<()> {
    let db = database::connect(&config.db_url)?;
    let app = handlers::build_app(db);
    app.run()
}
```

### With CLI Arguments

```rust
// src/main.rs
use clap::Parser;
use my_app::{run, Args};

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    run(args)
}

// src/lib.rs
use clap::Parser;

#[derive(Parser, Debug)]
#[command(name = "myapp", version, about)]
pub struct Args {
    #[arg(short, long)]
    pub config: PathBuf,
    
    #[arg(short, long, default_value = "info")]
    pub log_level: String,
}

pub fn run(args: Args) -> anyhow::Result<()> {
    // All application logic here - testable!
}
```

### Project Structure

```
my_app/
├── Cargo.toml
├── src/
│   ├── main.rs       # Entry point only
│   ├── lib.rs        # Library root, re-exports
│   ├── config.rs     # Configuration
│   ├── database.rs   # Database connection
│   └── handlers/     # Request handlers
│       ├── mod.rs
│       └── users.rs
└── tests/
    └── integration.rs  # Can access lib.rs!
```

### Testing Benefits

```rust
// tests/integration.rs - can test everything!
use my_app::{Config, run, database};

#[test]
fn test_database_connection() {
    let config = Config::test_config();
    let db = database::connect(&config.db_url).unwrap();
    assert!(db.is_connected());
}

#[test]
fn test_full_workflow() {
    let config = Config::test_config();
    // Test the actual run function
    assert!(my_app::run(config).is_ok());
}
```

### Multiple Binaries

```rust
// src/lib.rs - shared code
pub mod core;
pub mod utils;

// src/bin/server.rs
use my_app::core::Server;

fn main() -> anyhow::Result<()> {
    Server::new()?.run()
}

// src/bin/cli.rs
use my_app::core::Client;

fn main() -> anyhow::Result<()> {
    let client = Client::new()?;
    client.execute_command()
}
```

Related: `proj-bin-dir`, `proj-mod-by-feature`, `test-integration-dir`

## proj-mod-by-feature

> Organize modules by feature, not type

### Why It Matters

Feature-based organization keeps related code together, making navigation intuitive and changes localized. Type-based organization (all handlers in one folder, all models in another) scatters related code across the codebase, making features harder to understand and modify.

### Bad

```
src/
├── controllers/
│   ├── user_controller.rs
│   ├── order_controller.rs
│   └── product_controller.rs
├── models/
│   ├── user.rs
│   ├── order.rs
│   └── product.rs
├── services/
│   ├── user_service.rs
│   ├── order_service.rs
│   └── product_service.rs
└── repositories/
    ├── user_repository.rs
    ├── order_repository.rs
    └── product_repository.rs
```

### Good

```
src/
├── user/
│   ├── mod.rs           # Re-exports public items
│   ├── model.rs         # User struct, types
│   ├── repository.rs    # Database operations
│   ├── service.rs       # Business logic
│   └── handler.rs       # HTTP handlers
├── order/
│   ├── mod.rs
│   ├── model.rs
│   ├── repository.rs
│   ├── service.rs
│   └── handler.rs
├── product/
│   ├── mod.rs
│   ├── model.rs
│   ├── repository.rs
│   └── handler.rs
└── lib.rs
```

### Benefits

| Aspect | Type-Based | Feature-Based |
|--------|------------|---------------|
| Finding code | Search across folders | One folder per feature |
| Adding feature | Touch 4+ folders | Create one folder |
| Understanding feature | Jump between folders | Everything in one place |
| Deleting feature | Hunt through codebase | Delete one folder |
| Code ownership | Unclear | Clear feature owners |

### Module Structure

```rust
// src/user/mod.rs
mod model;
mod repository;
mod service;
mod handler;

// Re-export public API
pub use model::{User, UserId, CreateUserRequest};
pub use handler::router;
pub(crate) use service::UserService;
```

### Shared Code

```
src/
├── user/
├── order/
├── shared/              # Cross-cutting concerns
│   ├── mod.rs
│   ├── database.rs      # Connection pool
│   ├── error.rs         # Common error types
│   └── middleware.rs    # Auth, logging
└── lib.rs
```

### When to Flatten

Small modules don't need deep nesting:

```
src/
├── user/
│   ├── mod.rs           # Contains User struct + simple functions
│   └── repository.rs    # Only if complex enough
├── config.rs            # Simple enough for single file
└── lib.rs
```

### Hybrid Approach

For larger features, nest further by concern:

```
src/
├── billing/
│   ├── mod.rs
│   ├── invoice/
│   │   ├── mod.rs
│   │   ├── model.rs
│   │   └── service.rs
│   ├── payment/
│   │   ├── mod.rs
│   │   ├── model.rs
│   │   └── processor.rs
│   └── shared.rs
```

Related: `proj-flat-small`, `proj-pub-use-reexport`, `proj-lib-main-split`

## proj-flat-small

> Keep small projects flat

### Why It Matters

Over-organizing small projects adds navigation overhead without benefit. A project with 5-10 files doesn't need nested directories. Start flat, add structure only when complexity demands it.

### Bad

```
src/
├── core/
│   └── mod.rs           # Just re-exports
├── domain/
│   ├── mod.rs
│   └── models/
│       ├── mod.rs
│       └── user.rs      # 50 lines
├── infrastructure/
│   ├── mod.rs
│   └── database/
│       ├── mod.rs
│       └── connection.rs # 30 lines
├── application/
│   ├── mod.rs
│   └── services/
│       └── mod.rs       # Empty
└── main.rs
```

### Good

```
src/
├── main.rs
├── lib.rs
├── config.rs
├── database.rs
├── user.rs
└── error.rs
```

### When to Add Structure

| File Count | Structure |
|------------|-----------|
| < 10 files | Flat in `src/` |
| 10-20 files | Group by feature |
| 20+ files | Feature folders with submodules |

### Progressive Structuring

#### Stage 1: Flat

```
src/
├── main.rs
├── config.rs
├── user.rs
└── database.rs
```

#### Stage 2: Logical Groups

```
src/
├── main.rs
├── config.rs
├── user.rs
├── order.rs        # Getting bigger
├── order_item.rs   # Related to order
└── database.rs
```

#### Stage 3: Feature Folders

```
src/
├── main.rs
├── config.rs
├── user.rs
├── order/          # Now complex enough
│   ├── mod.rs
│   ├── model.rs
│   └── item.rs
└── database.rs
```

### Signs You Need More Structure

- Files exceed 300-500 lines
- Related files are hard to identify
- You're adding `_` prefixes for grouping (`user_model.rs`, `user_service.rs`)
- New team members get lost
- Same concepts repeated in file names

### Signs of Over-Structure

- Folders with 1-2 files
- `mod.rs` files that only re-export
- Deep nesting for simple concepts
- More lines in module declarations than code

### Example: CLI Tool

```
src/
├── main.rs         # Argument parsing, entry point
├── commands.rs     # CLI subcommands
├── config.rs       # Configuration loading
└── output.rs       # Formatting, printing
```

Not:

```
src/
├── cli/
│   └── commands/
│       └── mod.rs
├── config/
│   └── mod.rs
└── presentation/
    └── output/
        └── mod.rs
```

Related: `proj-mod-by-feature`, `proj-lib-main-split`, `proj-mod-rs-dir`

## proj-mod-rs-dir

> Use mod.rs for multi-file modules

### Why It Matters

Rust offers two styles for multi-file modules. The `mod.rs` style is clearer for larger modules and aligns with how most Rust projects are structured. Choose one style consistently.

### Two Styles

#### Style 1: mod.rs (Recommended for larger modules)

```
src/
├── user/
│   ├── mod.rs          # Module root
│   ├── model.rs
│   └── repository.rs
└── lib.rs
```

```rust
// src/lib.rs
mod user;  // Looks for user/mod.rs or user.rs

// src/user/mod.rs
mod model;
mod repository;
pub use model::User;
```

#### Style 2: Adjacent file (Recommended for smaller modules)

```
src/
├── user.rs             # Module root
├── user/
│   ├── model.rs
│   └── repository.rs
└── lib.rs
```

```rust
// src/lib.rs
mod user;  // Looks for user.rs, then user/ for submodules

// src/user.rs
mod model;
mod repository;
pub use model::User;
```

### When to Use Each

| Scenario | Recommendation |
|----------|----------------|
| Simple module (1-3 submodules) | Adjacent file (`user.rs` + `user/`) |
| Complex module (4+ submodules) | `mod.rs` style (`user/mod.rs`) |
| Deep nesting | `mod.rs` at each level |
| Library with public modules | Consistent style throughout |

### mod.rs Benefits

- Clear that `user/` is a module directory
- All module code inside the folder
- Easier to move/rename entire modules
- Common in large codebases (tokio, serde)

### Adjacent File Benefits

- Module declaration outside directory
- Can see module's interface without entering folder
- Matches Rust 2018+ default lint preference
- Good for small modules with few submodules

### Example: Complex Module

```
src/
├── database/
│   ├── mod.rs          # Main module, re-exports
│   ├── connection.rs   # Connection pool
│   ├── migrations.rs   # Schema migrations
│   ├── queries/        # Sub-module for queries
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   └── order.rs
│   └── error.rs
└── lib.rs
```

```rust
// src/database/mod.rs
mod connection;
mod migrations;
mod queries;
mod error;

pub use connection::Pool;
pub use error::DatabaseError;
pub use queries::{UserQueries, OrderQueries};
```

### Consistency Rule

Pick one style for your project and stick with it:

```rust
// Cargo.toml or clippy.toml
[lints.clippy]
mod_module_files = "warn"  # Enforces mod.rs style
# OR
self_named_module_files = "warn"  # Enforces adjacent style
```

Related: `proj-flat-small`, `proj-mod-by-feature`, `proj-pub-use-reexport`

## proj-pub-crate-internal

> Use pub(crate) for internal APIs

### Why It Matters

`pub(crate)` exposes items within the crate but hides them from external users. This creates clear boundaries between public API and internal implementation, preventing accidental breakage and reducing public API surface.

### Bad

```rust
// Everything public - users depend on internals
pub mod internal {
    pub struct InternalState {
        pub buffer: Vec<u8>,    // Implementation detail exposed
        pub dirty: bool,
    }
    
    pub fn process_internal(state: &mut InternalState) {
        // Users can call this, creating coupling
    }
}

pub struct Widget {
    pub state: internal::InternalState,  // Exposed!
}
```

### Good

```rust
// Internal module with crate visibility
pub(crate) mod internal {
    pub(crate) struct InternalState {
        pub(crate) buffer: Vec<u8>,
        pub(crate) dirty: bool,
    }
    
    pub(crate) fn process_internal(state: &mut InternalState) {
        // Only callable within crate
    }
}

pub struct Widget {
    state: internal::InternalState,  // Private field
}

impl Widget {
    pub fn new() -> Self {
        Self {
            state: internal::InternalState {
                buffer: Vec::new(),
                dirty: false,
            }
        }
    }
    
    pub fn do_something(&mut self) {
        internal::process_internal(&mut self.state);
    }
}
```

### Visibility Levels

| Visibility | Accessible From |
|------------|-----------------|
| `pub` | Everywhere |
| `pub(crate)` | Current crate only |
| `pub(super)` | Parent module only |
| `pub(in path)` | Specific module path |
| (private) | Current module only |

### Pattern: Internal Module

```rust
// src/lib.rs
mod internal;  // Private module
pub mod api;   // Public API

// src/internal.rs
pub(crate) struct Helper;
pub(crate) fn helper_function() -> Helper { Helper }

// src/api.rs
use crate::internal::{Helper, helper_function};

pub struct PublicType {
    helper: Helper,  // Uses internal type, but field is private
}
```

### Pattern: Test Visibility

```rust
pub struct Parser {
    // Private implementation
    state: ParserState,
}

// Expose for testing but not public API
#[cfg(test)]
pub(crate) fn debug_state(&self) -> &ParserState {
    &self.state
}

// Or use a dedicated test helper
#[doc(hidden)]
pub mod __test_helpers {
    pub use super::ParserState;
}
```

### Pattern: Feature Module Internals

```rust
// src/user/mod.rs
mod repository;  // Private
mod service;     // Private

pub use service::UserService;  // Only export the public API

// repository and service are pub(crate) internally
// so other modules in crate can use them if needed
```

### Benefits

| Approach | API Stability | Flexibility |
|----------|---------------|-------------|
| All `pub` | Any change breaks users | None |
| `pub(crate)` internals | Only `pub` items matter | Can refactor freely |
| Private | Maximum encapsulation | Limits crate flexibility |

Related: `proj-pub-super-parent`, `proj-pub-use-reexport`, `api-non-exhaustive`

## proj-pub-super-parent

> Use pub(super) for parent-only visibility

### Why It Matters

`pub(super)` exposes items only to the immediate parent module. This is useful for helper functions and types that submodules share but shouldn't be visible to the rest of the crate.

### Bad

```rust
// src/parser/mod.rs
pub mod lexer;
pub mod ast;

// src/parser/lexer.rs
pub fn internal_helper() {  // Visible to entire crate!
    // Helper only needed by lexer and ast
}

pub(crate) struct Token {  // Visible to entire crate
    // Only parser submodules need this
}
```

### Good

```rust
// src/parser/mod.rs
pub mod lexer;
pub mod ast;

// Shared types for parser submodules only
pub(super) struct Token {
    pub(super) kind: TokenKind,
    pub(super) span: Span,
}

pub(super) fn shared_helper() -> Token {
    // Only visible in parser/*
}

// src/parser/lexer.rs
use super::{Token, shared_helper};

pub fn lex(input: &str) -> Vec<Token> {
    shared_helper();
    // ...
}

// src/parser/ast.rs
use super::Token;

pub fn parse(tokens: Vec<Token>) -> Ast {
    // ...
}
```

### Visibility Hierarchy

```
src/
├── lib.rs           # crate root
├── parser/
│   ├── mod.rs       # pub(super) items visible here
│   ├── lexer.rs     # can use pub(super) from mod.rs
│   └── ast.rs       # can use pub(super) from mod.rs
└── codegen.rs       # CANNOT see pub(super) parser items
```

### Pattern: Layered Visibility

```rust
// src/database/mod.rs
mod connection;
mod query;
mod pool;

// Only this module's children can see
pub(super) struct RawConnection { /* ... */ }

// Entire crate can see
pub(crate) struct Pool { /* ... */ }

// Everyone can see
pub struct Database { /* ... */ }
```

### Pattern: Test Helpers

```rust
// src/parser/mod.rs
mod lexer;
mod ast;

#[cfg(test)]
mod tests {
    use super::*;
    
    // Test helper visible only to parser module's tests
    pub(super) fn make_test_token() -> Token {
        Token { kind: TokenKind::Test, span: Span::dummy() }
    }
}

// src/parser/lexer.rs
#[cfg(test)]
mod tests {
    use super::super::tests::make_test_token;
    // ...
}
```

### Comparison

| Visibility | Scope | Use Case |
|------------|-------|----------|
| `pub` | Everywhere | Public API |
| `pub(crate)` | Crate-wide | Internal shared utilities |
| `pub(super)` | Parent module | Submodule helpers |
| `pub(in path)` | Specific path | Precise control |
| (private) | Current module | Implementation details |

### When to Use pub(super)

- Helper functions shared between sibling modules
- Types used by submodules but not the rest of crate
- Implementation details of a module group
- Test utilities for a module tree

Related: `proj-pub-crate-internal`, `proj-pub-use-reexport`, `proj-mod-by-feature`

## proj-pub-use-reexport

> Use pub use for clean public API

### Why It Matters

`pub use` re-exports items from submodules at the current module level. This creates a flat, ergonomic public API while keeping internal organization flexible. Users import from one place; you can reorganize internals without breaking their code.

### Bad

```rust
// lib.rs - Deep module paths exposed
pub mod error;
pub mod config;
pub mod client;
pub mod types;

// Users must write:
use my_crate::error::MyError;
use my_crate::config::Config;
use my_crate::client::http::HttpClient;
use my_crate::types::request::Request;
```

### Good

```rust
// lib.rs - Flat public API
mod error;
mod config;
mod client;
mod types;

pub use error::MyError;
pub use config::Config;
pub use client::http::HttpClient;
pub use types::request::Request;

// Users write:
use my_crate::{Config, HttpClient, MyError, Request};
```

### Pattern: Selective Re-export

```rust
// src/lib.rs
mod internal;

// Only re-export what users need
pub use internal::{
    PublicStruct,
    PublicTrait,
    public_function,
};

// Keep implementation details hidden
// internal::helper_function is NOT exported
```

### Pattern: Rename on Re-export

```rust
mod v1 {
    pub struct Client { /* old implementation */ }
}

mod v2 {
    pub struct Client { /* new implementation */ }
}

// Re-export with clear names
pub use v2::Client;
pub use v1::Client as LegacyClient;
```

### Pattern: Prelude Module

```rust
// src/lib.rs
pub mod prelude {
    pub use crate::{
        Config,
        Client,
        Error,
        Request,
        Response,
    };
}

// Users can glob import common items
use my_crate::prelude::*;
```

### Pattern: Feature-Gated Re-exports

```rust
// src/lib.rs
mod core;
mod serde_impl;
mod async_impl;

pub use core::*;

#[cfg(feature = "serde")]
pub use serde_impl::*;

#[cfg(feature = "async")]
pub use async_impl::*;
```

### Comparison: Module Structure vs Public API

```rust
// Internal structure (complex)
src/
├── transport/
│   ├── http/
│   │   └── client.rs    // HttpClient
│   └── grpc/
│       └── client.rs    // GrpcClient
├── auth/
│   └── token.rs         // Token
└── lib.rs

// Public API (flat)
pub use transport::http::client::HttpClient;
pub use transport::grpc::client::GrpcClient;
pub use auth::token::Token;

// Users see:
my_crate::HttpClient
my_crate::GrpcClient
my_crate::Token
```

### Re-export External Types

```rust
// Re-export dependencies users will need
pub use bytes::Bytes;
pub use http::{Method, StatusCode};

// Now users don't need to depend on these crates directly
```

### Glob Re-exports

Use sparingly:

```rust
// OK for internal modules
pub use internal::*;

// Careful with external crates - pollutes namespace
pub use serde::*;  // Usually too broad
```

Related: `proj-prelude-module`, `proj-pub-crate-internal`, `api-non-exhaustive`
