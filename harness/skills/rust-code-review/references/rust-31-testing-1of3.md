---
name: rust-31-testing-1of3
description: Rust rules module 31: Testing (part 1 of 3). 6 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `test-`
---

# Testing (part 1/3)

Priority: MEDIUM. 6 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `test-cfg-test-module` - Put unit tests in `#[cfg(test)] mod tests { }` within each module
- `test-use-super` - Use `use super::*;` in test modules to access parent module items
- `test-integration-dir` - Put integration tests in the `tests/` directory
- `test-descriptive-names` - Use descriptive test names that explain what is being tested
- `test-arrange-act-assert` - Structure tests with clear Arrange, Act, Assert sections
- `test-proptest-properties` - Use proptest for property-based testing

---

## test-cfg-test-module

> Put unit tests in `#[cfg(test)] mod tests { }` within each module

### Why It Matters

The `#[cfg(test)]` attribute ensures test code is only compiled during `cargo test`, not in release builds. Placing tests in a `tests` submodule within the same file keeps tests close to the code they test while maintaining separation. This is Rust's idiomatic unit test pattern.

### Bad

```rust
// Tests without cfg(test) - compiled into release binary
mod tests {
    #[test]
    fn test_something() { ... }  // Included in release build!
}

// Tests in separate file without access to private items
// src/my_module.rs
fn private_helper() { ... }

// tests/my_module_test.rs
// Can't access private_helper!
```

### Good

```rust
// src/my_module.rs

fn public_api() -> i32 {
    private_helper() * 2
}

fn private_helper() -> i32 {
    21
}

#[cfg(test)]
mod tests {
    use super::*;  // Access to private items
    
    #[test]
    fn test_public_api() {
        assert_eq!(public_api(), 42);
    }
    
    #[test]
    fn test_private_helper() {
        assert_eq!(private_helper(), 21);  // Can test private!
    }
}
```

### Module Structure

```rust
// src/lib.rs
mod parser;
mod lexer;
mod ast;

// src/parser.rs
pub fn parse(input: &str) -> Result<Ast, Error> {
    let tokens = tokenize(input)?;
    build_ast(tokens)
}

fn tokenize(input: &str) -> Result<Vec<Token>, Error> { ... }
fn build_ast(tokens: Vec<Token>) -> Result<Ast, Error> { ... }

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_parse_simple() {
        let ast = parse("1 + 2").unwrap();
        assert_eq!(ast.evaluate(), 3);
    }
    
    #[test]
    fn test_tokenize() {
        let tokens = tokenize("1 + 2").unwrap();
        assert_eq!(tokens.len(), 3);
    }
}
```

### Test Helpers

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Test-only helpers
    fn create_test_data() -> Data {
        Data {
            id: 1,
            name: "test".into(),
            values: vec![1, 2, 3],
        }
    }
    
    fn assert_valid(data: &Data) {
        assert!(data.id > 0);
        assert!(!data.name.is_empty());
    }
    
    #[test]
    fn test_processing() {
        let data = create_test_data();
        let result = process(&data);
        assert_valid(&result);
    }
}
```

### Multiple Test Modules

```rust
// For larger test suites, use submodules
#[cfg(test)]
mod tests {
    use super::*;
    
    mod parsing {
        use super::*;
        
        #[test]
        fn test_parse_number() { ... }
        
        #[test]
        fn test_parse_string() { ... }
    }
    
    mod validation {
        use super::*;
        
        #[test]
        fn test_validate_range() { ... }
    }
}
```

Related: `test-use-super`, `test-integration-dir`, `test-descriptive-names`

## test-use-super

> Use `use super::*;` in test modules to access parent module items

### Why It Matters

The test module is a child of the module being tested. `use super::*` imports all items from the parent module, including private ones. This gives tests access to both public API and internal implementation details for thorough testing.

### Bad

```rust
// Verbose imports
#[cfg(test)]
mod tests {
    use crate::my_module::public_function;
    use crate::my_module::MyStruct;
    // Can't access private items this way!
    
    #[test]
    fn test_function() {
        let result = public_function();
        // ...
    }
}
```

### Good

```rust
// src/my_module.rs
pub struct PublicStruct { ... }
struct PrivateStruct { ... }  // Private

pub fn public_function() -> i32 { ... }
fn private_helper() -> i32 { ... }  // Private

#[cfg(test)]
mod tests {
    use super::*;  // Imports everything from parent
    
    #[test]
    fn test_public_struct() {
        let s = PublicStruct::new();
        // ...
    }
    
    #[test]
    fn test_private_struct() {
        let s = PrivateStruct::new();  // Can access private!
        // ...
    }
    
    #[test]
    fn test_private_helper() {
        assert_eq!(private_helper(), 42);  // Can test private!
    }
}
```

### Selective Imports

```rust
#[cfg(test)]
mod tests {
    // When you want to be explicit
    use super::{parse, ParseError, Token};
    
    // Or import all plus test utilities
    use super::*;
    use std::fs;
    use tempfile::TempDir;
    
    #[test]
    fn test_parse() { ... }
}
```

### Nested Modules

```rust
mod outer {
    pub fn outer_fn() -> i32 { 1 }
    
    mod inner {
        pub fn inner_fn() -> i32 { 2 }
        
        #[cfg(test)]
        mod tests {
            use super::*;           // Gets inner's items
            use super::super::*;    // Gets outer's items
            
            #[test]
            fn test_inner() {
                assert_eq!(inner_fn(), 2);
                assert_eq!(outer_fn(), 1);
            }
        }
    }
}
```

### With External Dependencies

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Test-only dependencies
    use proptest::prelude::*;
    use mockall::predicate::*;
    
    proptest! {
        #[test]
        fn test_property(s: String) {
            let result = process(&s);
            prop_assert!(result.is_ok());
        }
    }
}
```

Related: `test-cfg-test-module`, `test-integration-dir`, `proj-pub-crate-internal`

## test-integration-dir

> Put integration tests in the `tests/` directory

### Why It Matters

Integration tests live in `tests/` at the crate root, separate from `src/`. Each file in `tests/` is compiled as a separate crate, testing your library's public API as external users would. This separation ensures you're testing the real public interface, not implementation details.

### Structure

```
my_project/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   └── internal.rs
└── tests/
    ├── integration_test.rs    # Each file is a separate test binary
    ├── api_tests.rs
    └── common/                 # Shared test utilities
        └── mod.rs
```

### Bad

```rust
// src/lib.rs
// Mixing integration test logic in library code
#[test]
fn integration_test_full_workflow() {
    // This is a unit test location, not integration
}
```

### Good

```rust
// tests/integration_test.rs
use my_crate::{Client, Config};  // Uses public API only

#[test]
fn test_full_workflow() {
    let config = Config::default();
    let client = Client::new(config);
    
    let result = client.process("input");
    assert!(result.is_ok());
}

#[test]
fn test_error_handling() {
    let client = Client::new(Config::strict());
    
    let result = client.process("invalid");
    assert!(matches!(result, Err(Error::InvalidInput { .. })));
}
```

### Shared Test Utilities

```rust
// tests/common/mod.rs
use my_crate::Config;

pub fn test_config() -> Config {
    Config {
        timeout: Duration::from_secs(5),
        retries: 3,
        debug: true,
    }
}

pub fn setup_test_environment() {
    // Set up test fixtures
}

// tests/api_tests.rs
mod common;

use my_crate::Client;

#[test]
fn test_with_shared_config() {
    common::setup_test_environment();
    let client = Client::new(common::test_config());
    // ...
}
```

### Organizing Many Tests

```rust
// tests/api/mod.rs
mod auth;
mod users;
mod orders;

// tests/api/auth.rs
use my_crate::auth::{login, logout};

#[test]
fn test_login_success() { ... }

#[test]
fn test_login_invalid_credentials() { ... }

// tests/api/users.rs
use my_crate::users::{create_user, get_user};

#[test]
fn test_create_user() { ... }
```

### Integration vs Unit Tests

| Unit Tests | Integration Tests |
|------------|-------------------|
| In `src/` with `#[cfg(test)]` | In `tests/` directory |
| Access private items | Public API only |
| Test individual functions | Test module interactions |
| Fast, isolated | May be slower |
| `cargo test --lib` | `cargo test --test '*'` |

### Running Specific Tests

```bash
# Run all tests
cargo test

# Run only integration tests
cargo test --test '*'

# Run specific integration test file
cargo test --test integration_test

# Run tests matching pattern
cargo test --test api_tests test_login
```

Related: `test-cfg-test-module`, `test-descriptive-names`, `test-tokio-async`

## test-descriptive-names

> Use descriptive test names that explain what is being tested

### Why It Matters

Test names appear in test output and serve as documentation. A good test name tells you what behavior is being verified without reading the test body. When a test fails, a descriptive name immediately tells you what broke.

### Bad

```rust
#[test]
fn test1() { ... }

#[test]
fn test_parse() { ... }  // Parse what? What behavior?

#[test]
fn it_works() { ... }

#[test]
fn test_function() { ... }

// Failure output: "test test_parse ... FAILED"
// What failed? No idea.
```

### Good

```rust
#[test]
fn parse_returns_error_for_empty_input() { ... }

#[test]
fn parse_handles_unicode_characters() { ... }

#[test]
fn user_creation_requires_valid_email() { ... }

#[test]
fn expired_token_is_rejected() { ... }

// Failure output: "test parse_returns_error_for_empty_input ... FAILED"
// Immediately know what broke!
```

### Naming Patterns

```rust
// Pattern: function_condition_expected_result
#[test]
fn parse_valid_json_returns_document() { ... }

#[test]
fn parse_invalid_json_returns_syntax_error() { ... }

// Pattern: scenario_expectation
#[test]
fn empty_cart_has_zero_total() { ... }

#[test]
fn adding_item_increases_cart_total() { ... }

// Pattern: when_given_then (BDD-style)
#[test]
fn when_user_not_found_then_returns_404() { ... }
```

### Edge Cases

```rust
#[test]
fn handles_empty_string() { ... }

#[test]
fn handles_max_length_input() { ... }

#[test]
fn handles_unicode_emoji() { ... }

#[test]
fn handles_null_bytes() { ... }

#[test]
fn handles_concurrent_access() { ... }
```

### Error Cases

```rust
#[test]
fn rejects_negative_quantity() { ... }

#[test]
fn returns_error_for_invalid_email_format() { ... }

#[test]
fn panics_on_double_initialization() { ... }

#[test]
fn timeout_returns_timeout_error() { ... }
```

### Module Organization

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    mod parsing {
        use super::*;
        
        #[test]
        fn accepts_valid_json() { ... }
        
        #[test]
        fn rejects_trailing_comma() { ... }
    }
    
    mod validation {
        use super::*;
        
        #[test]
        fn requires_name_field() { ... }
        
        #[test]
        fn email_must_contain_at_symbol() { ... }
    }
}

// Test output:
// tests::parsing::accepts_valid_json
// tests::parsing::rejects_trailing_comma
// tests::validation::requires_name_field
```

Related: `test-arrange-act-assert`, `test-cfg-test-module`, `doc-examples-section`

## test-arrange-act-assert

> Structure tests with clear Arrange, Act, Assert sections

### Why It Matters

The AAA pattern makes tests readable and maintainable. Each section has a clear purpose: set up test data, execute the code under test, verify the results. This structure helps identify what's being tested and makes tests easier to debug when they fail.

### Bad

```rust
#[test]
fn test_user() {
    assert_eq!(User::new("alice", "alice@example.com").unwrap().name(), "alice");
    assert!(User::new("", "email@example.com").is_err());
    let u = User::new("bob", "bob@example.com").unwrap();
    assert!(u.validate());
    assert_eq!(u.email(), "bob@example.com");
}
// Multiple concerns, hard to understand, hard to debug
```

### Good

```rust
#[test]
fn new_user_has_correct_name() {
    // Arrange
    let name = "alice";
    let email = "alice@example.com";
    
    // Act
    let user = User::new(name, email).unwrap();
    
    // Assert
    assert_eq!(user.name(), "alice");
}

#[test]
fn user_creation_fails_with_empty_name() {
    // Arrange
    let name = "";
    let email = "email@example.com";
    
    // Act
    let result = User::new(name, email);
    
    // Assert
    assert!(result.is_err());
    assert!(matches!(result, Err(UserError::EmptyName)));
}
```

### With Comments

```rust
#[test]
fn order_total_includes_tax() {
    // Arrange
    let mut order = Order::new();
    order.add_item(Item::new("Widget", 100.00));
    order.add_item(Item::new("Gadget", 50.00));
    let tax_rate = 0.10;
    
    // Act
    let total = order.calculate_total(tax_rate);
    
    // Assert
    let expected = (100.00 + 50.00) * 1.10;
    assert_eq!(total, expected);
}
```

### Complex Arrange

```rust
#[test]
fn search_returns_matching_documents() {
    // Arrange
    let mut index = SearchIndex::new();
    index.add_document(Document::new(1, "rust programming"));
    index.add_document(Document::new(2, "python programming"));
    index.add_document(Document::new(3, "rust web development"));
    
    let query = Query::new("rust");
    
    // Act
    let results = index.search(&query);
    
    // Assert
    assert_eq!(results.len(), 2);
    assert!(results.iter().any(|d| d.id == 1));
    assert!(results.iter().any(|d| d.id == 3));
}
```

### Async Tests

```rust
#[tokio::test]
async fn fetch_user_returns_user_data() {
    // Arrange
    let client = TestClient::new();
    let user_id = 42;
    
    // Act
    let result = client.fetch_user(user_id).await;
    
    // Assert
    assert!(result.is_ok());
    let user = result.unwrap();
    assert_eq!(user.id, user_id);
}
```

### Helper Functions

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    // Arrange helpers
    fn create_test_user() -> User {
        User::new("test", "test@example.com").unwrap()
    }
    
    fn create_order_with_items(items: &[(&str, f64)]) -> Order {
        let mut order = Order::new();
        for (name, price) in items {
            order.add_item(Item::new(name, *price));
        }
        order
    }
    
    // Assert helpers
    fn assert_order_total(order: &Order, expected: f64) {
        let total = order.calculate_total(0.0);
        assert!((total - expected).abs() < 0.01);
    }
    
    #[test]
    fn order_total_sums_items() {
        // Arrange
        let order = create_order_with_items(&[
            ("A", 10.0),
            ("B", 20.0),
        ]);
        
        // Act & Assert
        assert_order_total(&order, 30.0);
    }
}
```

Related: `test-descriptive-names`, `test-fixture-raii`, `test-mock-traits`

## test-proptest-properties

> Use proptest for property-based testing

### Why It Matters

Property-based testing generates random inputs to verify that properties hold across all possible values, not just hand-picked examples. Proptest finds edge cases you wouldn't think to test manually—empty strings, integer overflows, unicode edge cases.

### Setup

```toml
# Cargo.toml
[dev-dependencies]
proptest = "1.0"
```

### Basic Usage

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_reverse_reverse_is_identity(s in ".*") {
        let reversed: String = s.chars().rev().collect();
        let double_reversed: String = reversed.chars().rev().collect();
        assert_eq!(s, double_reversed);
    }
    
    #[test]
    fn test_sort_is_idempotent(mut v in prop::collection::vec(any::<i32>(), 0..100)) {
        v.sort();
        let sorted = v.clone();
        v.sort();
        assert_eq!(v, sorted);
    }
}
```

### Common Strategies

```rust
use proptest::prelude::*;

proptest! {
    // Any type implementing Arbitrary
    #[test]
    fn test_i32(x in any::<i32>()) { }
    
    // Regex-based string generation
    #[test]
    fn test_email(email in "[a-z]+@[a-z]+\\.[a-z]{2,3}") { }
    
    // Ranges
    #[test]
    fn test_range(x in 0..100i32) { }
    
    // Collections
    #[test]
    fn test_vec(v in prop::collection::vec(any::<i32>(), 0..10)) { }
    
    // Optionals
    #[test]
    fn test_option(opt in prop::option::of(any::<i32>())) { }
}
```

### Custom Strategies

```rust
use proptest::prelude::*;

#[derive(Debug, Clone)]
struct User {
    name: String,
    age: u8,
}

fn user_strategy() -> impl Strategy<Value = User> {
    ("[a-zA-Z]{1,20}", 0..120u8)
        .prop_map(|(name, age)| User { name, age })
}

proptest! {
    #[test]
    fn test_user(user in user_strategy()) {
        assert!(user.age < 150);
        assert!(!user.name.is_empty());
    }
}

// Or derive Arbitrary
use proptest_derive::Arbitrary;

#[derive(Debug, Arbitrary)]
struct Point {
    x: i32,
    y: i32,
}
```

### Properties to Test

| Property | Example |
|----------|---------|
| Roundtrip | `decode(encode(x)) == x` |
| Idempotence | `f(f(x)) == f(x)` |
| Commutativity | `f(a, b) == f(b, a)` |
| Associativity | `f(f(a, b), c) == f(a, f(b, c))` |
| Identity | `f(x, identity) == x` |
| Invariants | `len(push(v, x)) == len(v) + 1` |

### Example: Parser Roundtrip

```rust
proptest! {
    #[test]
    fn parse_roundtrip(config in valid_config_strategy()) {
        let serialized = config.to_string();
        let parsed = Config::parse(&serialized).unwrap();
        assert_eq!(config, parsed);
    }
}
```

### Shrinking

Proptest automatically shrinks failing inputs to minimal cases:

```rust
// If this fails with vec![100, 50, 75, 25, 0]
// Proptest will shrink to vec![1, 0] (minimal failing case)
proptest! {
    #[test]
    fn test_sorted(v in prop::collection::vec(0..1000i32, 1..100)) {
        let sorted = is_sorted(&v);
        // This will fail and shrink
    }
}
```

### Configuration

```rust
proptest! {
    #![proptest_config(ProptestConfig {
        cases: 1000,  // More test cases
        max_shrink_iters: 10000,  // More shrinking
        ..ProptestConfig::default()
    })]
    
    #[test]
    fn extensive_test(x in any::<i32>()) { }
}
```

Related: `test-criterion-bench`, `test-mockall-mocking`, `test-arrange-act-assert`
