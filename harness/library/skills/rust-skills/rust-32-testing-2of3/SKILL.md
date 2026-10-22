---
name: rust-32-testing-2of3
description: Rust rules module 32: Testing (part 2 of 3). 4 rules, priority MEDIUM. Load on its own to review or write Rust code against this topic only. Rule prefixes: `test-`
---

# Testing (part 2/3)

Priority: MEDIUM. 4 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `test-mockall-mocking` - Use mockall for trait mocking
- `test-mock-traits` - Use traits for dependencies to enable mocking in tests
- `test-fixture-raii` - Use RAII pattern (Drop trait) for automatic test cleanup
- `test-tokio-async` - Use `#[tokio::test]` for async tests

---

## test-mockall-mocking

> Use mockall for trait mocking

### Why It Matters

Unit tests should isolate the code under test from external dependencies (databases, APIs, file systems). Mockall generates mock implementations of traits, allowing you to control and verify behavior without real dependencies.

### Setup

```toml
# Cargo.toml
[dev-dependencies]
mockall = "0.12"
```

### Basic Usage

```rust
use mockall::automock;

#[automock]
trait Database {
    fn get_user(&self, id: u64) -> Option<User>;
    fn save_user(&self, user: &User) -> Result<(), Error>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    
    #[test]
    fn test_get_user() {
        let mut mock = MockDatabase::new();
        
        mock.expect_get_user()
            .with(eq(42))
            .returning(|_| Some(User { id: 42, name: "Alice".into() }));
        
        let service = UserService::new(mock);
        let user = service.find_user(42);
        
        assert_eq!(user.unwrap().name, "Alice");
    }
}
```

### Expectations

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_save_calls() {
        let mut mock = MockDatabase::new();
        
        // Expect exactly one call
        mock.expect_save_user()
            .times(1)
            .returning(|_| Ok(()));
        
        // Expect call with specific argument
        mock.expect_get_user()
            .with(eq(42))
            .returning(|_| Some(User::default()));
        
        // Expect multiple calls
        mock.expect_get_user()
            .times(3..)  // At least 3 times
            .returning(|_| None);
        
        // Expectations are verified on drop
    }
}
```

### Predicates

```rust
use mockall::predicate::*;

mock.expect_process()
    .with(eq(42))                    // Exact match
    .returning(|_| Ok(()));

mock.expect_validate()
    .with(function(|s: &str| s.len() > 5))  // Custom predicate
    .returning(|_| true);

mock.expect_search()
    .withf(|query, limit| {           // Multiple args
        query.len() < 100 && *limit <= 1000
    })
    .returning(|_, _| vec![]);
```

### Sequences

```rust
use mockall::Sequence;

#[test]
fn test_ordered_calls() {
    let mut seq = Sequence::new();
    let mut mock = MockDatabase::new();
    
    mock.expect_connect()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|| Ok(()));
    
    mock.expect_query()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|_| Ok(vec![]));
    
    mock.expect_disconnect()
        .times(1)
        .in_sequence(&mut seq)
        .returning(|| Ok(()));
}
```

### Return Values

```rust
// Fixed value
mock.expect_count().returning(|| 42);

// Based on input
mock.expect_double().returning(|x| x * 2);

// Different values per call
mock.expect_next()
    .times(3)
    .returning(|| 1)
    .returning(|| 2)
    .returning(|| 3);

// Return owned values
mock.expect_get_name()
    .returning(|| "Alice".to_string());
```

### Mocking External Traits

```rust
// For traits you don't own
#[cfg_attr(test, mockall::automock)]
trait HttpClient {
    fn get(&self, url: &str) -> Result<Response, Error>;
}

// In production
struct RealHttpClient;
impl HttpClient for RealHttpClient {
    fn get(&self, url: &str) -> Result<Response, Error> { /* ... */ }
}

// In tests
#[cfg(test)]
fn mock_client() -> MockHttpClient {
    let mut mock = MockHttpClient::new();
    mock.expect_get()
        .returning(|_| Ok(Response::new(200, "OK")));
    mock
}
```

### Async Mocking

```rust
#[automock]
#[async_trait]
trait AsyncDatabase {
    async fn fetch(&self, id: u64) -> Option<Data>;
}

#[tokio::test]
async fn test_async() {
    let mut mock = MockAsyncDatabase::new();
    
    mock.expect_fetch()
        .returning(|_| Some(Data::default()));
    
    let result = mock.fetch(1).await;
    assert!(result.is_some());
}
```

### Design for Testability

```rust
// Accept trait, not concrete type
struct Service<D: Database> {
    db: D,
}

impl<D: Database> Service<D> {
    fn new(db: D) -> Self {
        Self { db }
    }
}

// Tests use mock
#[test]
fn test_service() {
    let mock = MockDatabase::new();
    let service = Service::new(mock);
}

// Production uses real implementation
fn main() {
    let db = PostgresDatabase::connect();
    let service = Service::new(db);
}
```

Related: `test-mock-traits`, `test-proptest-properties`, `test-arrange-act-assert`

## test-mock-traits

> Use traits for dependencies to enable mocking in tests

### Why It Matters

Concrete dependencies make testing hard—you can't easily test error paths, timeouts, or edge cases without real external systems. Extracting dependencies behind traits lets you inject test doubles (mocks, fakes, stubs), enabling isolated unit tests that run fast and cover edge cases.

### Bad

```rust
struct UserService {
    db: PostgresConnection,  // Concrete type - hard to test
}

impl UserService {
    async fn get_user(&self, id: u64) -> Result<User, Error> {
        // Directly calls Postgres - needs real database to test
        self.db.query("SELECT * FROM users WHERE id = $1", &[&id]).await
    }
}

// Test requires real Postgres instance
#[tokio::test]
async fn test_get_user() {
    let db = PostgresConnection::connect("postgres://...").await?;
    let service = UserService { db };
    // Slow, flaky, can't test error paths
}
```

### Good

```rust
// Define trait for dependency
#[async_trait]
trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError>;
    async fn save(&self, user: &User) -> Result<(), DbError>;
}

// Production implementation
struct PostgresUserRepo {
    pool: PgPool,
}

#[async_trait]
impl UserRepository for PostgresUserRepo {
    async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError> {
        sqlx::query_as("SELECT * FROM users WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
    }
    // ...
}

// Service depends on trait, not concrete type
struct UserService<R: UserRepository> {
    repo: R,
}

impl<R: UserRepository> UserService<R> {
    async fn get_user(&self, id: u64) -> Result<User, Error> {
        self.repo.find_by_id(id).await?
            .ok_or(Error::NotFound)
    }
}

// Test with mock
#[cfg(test)]
mod tests {
    struct MockUserRepo {
        users: HashMap<u64, User>,
    }
    
    #[async_trait]
    impl UserRepository for MockUserRepo {
        async fn find_by_id(&self, id: u64) -> Result<Option<User>, DbError> {
            Ok(self.users.get(&id).cloned())
        }
        // ...
    }
    
    #[tokio::test]
    async fn test_get_user_found() {
        let mut mock = MockUserRepo { users: HashMap::new() };
        mock.users.insert(1, User { id: 1, name: "Alice".into() });
        
        let service = UserService { repo: mock };
        let user = service.get_user(1).await.unwrap();
        
        assert_eq!(user.name, "Alice");
    }
    
    #[tokio::test]
    async fn test_get_user_not_found() {
        let mock = MockUserRepo { users: HashMap::new() };
        let service = UserService { repo: mock };
        
        let result = service.get_user(999).await;
        assert!(matches!(result, Err(Error::NotFound)));
    }
}
```

### mockall Crate

```rust
use mockall::*;
use mockall::predicate::*;

#[automock]
#[async_trait]
trait Database: Send + Sync {
    async fn query(&self, sql: &str) -> Result<Vec<Row>, Error>;
}

#[tokio::test]
async fn test_with_mockall() {
    let mut mock = MockDatabase::new();
    
    mock.expect_query()
        .with(eq("SELECT 1"))
        .times(1)
        .returning(|_| Ok(vec![Row::new()]));
    
    let result = mock.query("SELECT 1").await;
    assert!(result.is_ok());
}
```

### Testing Error Paths

```rust
#[async_trait]
trait HttpClient: Send + Sync {
    async fn get(&self, url: &str) -> Result<Response, HttpError>;
}

struct FailingClient;

#[async_trait]
impl HttpClient for FailingClient {
    async fn get(&self, _url: &str) -> Result<Response, HttpError> {
        Err(HttpError::Timeout)  // Always fails
    }
}

#[tokio::test]
async fn test_handles_timeout() {
    let client = FailingClient;
    let service = ApiService { client };
    
    let result = service.fetch_data().await;
    assert!(matches!(result, Err(Error::NetworkError(_))));
}
```

### Dynamic Dispatch Alternative

```rust
// When you don't want generics everywhere
struct UserService {
    repo: Box<dyn UserRepository>,
}

impl UserService {
    fn new(repo: impl UserRepository + 'static) -> Self {
        Self { repo: Box::new(repo) }
    }
}

// Slight runtime cost but cleaner API
```

### Cargo.toml

```toml
[dev-dependencies]
mockall = "0.11"
async-trait = "0.1"  # For async trait mocking
```

Related: `api-sealed-trait`, `test-proptest-properties`, `proj-lib-main-split`

## test-fixture-raii

> Use RAII pattern (Drop trait) for automatic test cleanup

### Why It Matters

Tests often need setup and teardown—creating temp files, starting servers, setting environment variables. Using RAII (Resource Acquisition Is Initialization) with Drop ensures cleanup happens automatically, even if the test panics. This prevents test pollution and resource leaks.

### Bad

```rust
#[test]
fn test_with_temp_file() {
    let path = "/tmp/test_file.txt";
    std::fs::write(path, "test data").unwrap();
    
    let result = process_file(path);
    
    std::fs::remove_file(path).unwrap();  // Might not run if test panics!
    assert!(result.is_ok());
}

#[test]
fn test_with_env_var() {
    std::env::set_var("MY_VAR", "test_value");
    
    let result = read_config();
    
    std::env::remove_var("MY_VAR");  // Might not run if test panics!
    assert!(result.is_ok());
}
```

### Good

```rust
use tempfile::NamedTempFile;

#[test]
fn test_with_temp_file() {
    // Arrange - file deleted automatically when `file` drops
    let file = NamedTempFile::new().unwrap();
    std::fs::write(file.path(), "test data").unwrap();
    
    // Act
    let result = process_file(file.path());
    
    // Assert - file cleaned up even if assertion panics
    assert!(result.is_ok());
}

// Custom RAII guard for environment variables
struct EnvGuard {
    key: String,
    original: Option<String>,
}

impl EnvGuard {
    fn set(key: &str, value: &str) -> Self {
        let original = std::env::var(key).ok();
        // SAFETY: env::set_var is unsafe since the 2024 edition (env writes are
        // not thread-safe); env-touching tests should run single-threaded.
        unsafe { std::env::set_var(key, value) };
        EnvGuard {
            key: key.to_string(),
            original,
        }
    }
}

impl Drop for EnvGuard {
    fn drop(&mut self) {
        // SAFETY: see EnvGuard::set — restored on the same single-threaded test
        match &self.original {
            Some(v) => unsafe { std::env::set_var(&self.key, v) },
            None => unsafe { std::env::remove_var(&self.key) },
        }
    }
}

#[test]
fn test_with_env_var() {
    let _guard = EnvGuard::set("MY_VAR", "test_value");
    
    let result = read_config();
    
    assert!(result.is_ok());
}  // MY_VAR automatically restored
```

### Common RAII Patterns

```rust
// Temporary directory
use tempfile::TempDir;

#[test]
fn test_with_temp_dir() {
    let dir = TempDir::new().unwrap();
    let file_path = dir.path().join("test.txt");
    std::fs::write(&file_path, "data").unwrap();
    
    // dir and all contents deleted on drop
}

// Server guard
struct TestServer {
    handle: std::thread::JoinHandle<()>,
    shutdown: std::sync::mpsc::Sender<()>,
}

impl Drop for TestServer {
    fn drop(&mut self) {
        let _ = self.shutdown.send(());
        // Wait for server to stop
    }
}

// Database transaction rollback
struct TestTransaction<'a> {
    conn: &'a mut Connection,
}

impl Drop for TestTransaction<'_> {
    fn drop(&mut self) {
        self.conn.execute("ROLLBACK").unwrap();
    }
}
```

### scopeguard Crate

```rust
use scopeguard::defer;

#[test]
fn test_with_defer() {
    let path = "/tmp/test_file.txt";
    std::fs::write(path, "data").unwrap();
    
    defer! {
        std::fs::remove_file(path).ok();
    }
    
    // Test logic here
    // File removed when scope exits
}
```

Related: `test-arrange-act-assert`, `test-tokio-async`, `test-mock-traits`

## test-tokio-async

> Use `#[tokio::test]` for async tests

### Why It Matters

Async functions can't be called directly—they need a runtime to drive them. `#[tokio::test]` provides a Tokio runtime for your test, handling setup automatically. This is simpler than manually creating a runtime and essential for testing async code.

### Bad

```rust
// Won't compile - async fn can't be called without runtime
#[test]
async fn test_async_function() {  // Error!
    let result = fetch_data().await;
    assert!(result.is_ok());
}

// Manual runtime - verbose and error-prone
#[test]
fn test_async_function() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let result = fetch_data().await;
        assert!(result.is_ok());
    });
}
```

### Good

```rust
#[tokio::test]
async fn test_async_function() {
    let result = fetch_data().await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_concurrent_operations() {
    let (a, b) = tokio::join!(
        fetch_user(1),
        fetch_user(2),
    );
    assert!(a.is_ok());
    assert!(b.is_ok());
}
```

### Runtime Configuration

```rust
// Multi-threaded runtime (default)
#[tokio::test]
async fn test_default_runtime() {
    // Uses multi-thread runtime
}

// Single-threaded (current_thread)
#[tokio::test(flavor = "current_thread")]
async fn test_single_threaded() {
    // Simpler, deterministic
}

// With specific thread count
#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_with_workers() {
    // Exactly 2 worker threads
}

// With time control
#[tokio::test(start_paused = true)]
async fn test_with_time_control() {
    // Time starts paused for deterministic testing
    tokio::time::advance(Duration::from_secs(60)).await;
}
```

### Testing Timeouts

```rust
use tokio::time::{timeout, Duration};

#[tokio::test]
async fn test_operation_completes_in_time() {
    let result = timeout(
        Duration::from_secs(5),
        slow_operation()
    ).await;
    
    assert!(result.is_ok(), "Operation timed out");
}

#[tokio::test]
async fn test_timeout_triggers() {
    let result = timeout(
        Duration::from_millis(100),
        never_completes()
    ).await;
    
    assert!(result.is_err(), "Expected timeout");
}
```

### Testing Channels

```rust
use tokio::sync::mpsc;

#[tokio::test]
async fn test_channel_communication() {
    let (tx, mut rx) = mpsc::channel(10);
    
    tokio::spawn(async move {
        tx.send("hello").await.unwrap();
        tx.send("world").await.unwrap();
    });
    
    assert_eq!(rx.recv().await, Some("hello"));
    assert_eq!(rx.recv().await, Some("world"));
    assert_eq!(rx.recv().await, None);
}
```

### Testing with Mocks

```rust
use mockall::*;

#[automock]
#[async_trait::async_trait]
trait Database {
    async fn get_user(&self, id: u64) -> Option<User>;
}

#[tokio::test]
async fn test_with_mock_database() {
    let mut mock = MockDatabase::new();
    mock.expect_get_user()
        .with(eq(42))
        .returning(|_| Some(User { id: 42, name: "Alice".into() }));
    
    let service = UserService::new(mock);
    let user = service.find_user(42).await;
    
    assert_eq!(user.unwrap().name, "Alice");
}
```

Related: `async-tokio-runtime`, `test-mock-traits`, `test-fixture-raii`
