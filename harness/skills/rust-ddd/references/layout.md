# Layout and templates

## Workspace (default)

```
Cargo.toml                      # [workspace] members = ["crates/*"]
crates/
  <ctx>-domain/                 # no external deps except thiserror (+ uuid, chrono if needed)
    src/{lib.rs, error.rs, <aggregate>/{mod.rs, entity.rs, value_objects.rs, events.rs, repository.rs}}
  <ctx>-application/            # depends on <ctx>-domain
    src/{lib.rs, commands/, queries/, ports.rs, error.rs}
  <ctx>-infrastructure/         # depends on domain + application; sqlx, reqwest, ...
    src/{lib.rs, persistence/, messaging/}
  <ctx>-interface/              # depends on application; axum / clap
    src/{lib.rs, http/, dto.rs}
  <ctx>-bootstrap/              # binary; wires everything
    src/main.rs
```

## Single crate variant

```
src/{domain,application,infrastructure,interface}/mod.rs + main.rs (composition root)
```
Enforce the same rules with `crate::` paths; the checker covers this layout.

## Domain templates

```rust
// value_objects.rs
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn new(raw: impl Into<String>) -> Result<Self, DomainError> {
        let raw = raw.into();
        if !raw.contains('@') {
            return Err(DomainError::InvalidEmail(raw));
        }
        Ok(Self(raw))
    }
    pub fn as_str(&self) -> &str { &self.0 }
}

// entity.rs  (aggregate root)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct OrderId(pub uuid::Uuid);

pub struct Order {
    id: OrderId,
    status: OrderStatus,
    lines: Vec<OrderLine>,
    events: Vec<DomainEvent>,
}

impl Order {
    pub fn place(id: OrderId, lines: Vec<OrderLine>) -> Result<Self, DomainError> {
        if lines.is_empty() { return Err(DomainError::EmptyOrder); }
        let mut o = Self { id, status: OrderStatus::Placed, lines, events: vec![] };
        o.events.push(DomainEvent::OrderPlaced(id));
        Ok(o)
    }
    pub fn confirm(&mut self) -> Result<(), DomainError> {
        if self.status != OrderStatus::Placed { return Err(DomainError::InvalidTransition); }
        self.status = OrderStatus::Confirmed;
        self.events.push(DomainEvent::OrderConfirmed(self.id));
        Ok(())
    }
    pub fn id(&self) -> OrderId { self.id }
    pub fn take_events(&mut self) -> Vec<DomainEvent> { std::mem::take(&mut self.events) }
}

// repository.rs  (port, in the domain crate)
pub trait OrderRepository: Send + Sync {
    async fn find(&self, id: OrderId) -> Result<Option<Order>, RepositoryError>;
    async fn save(&self, order: &mut Order) -> Result<(), RepositoryError>;
}
```

## Application template

```rust
pub struct ConfirmOrder { pub order_id: OrderId }

pub struct ConfirmOrderHandler<R: OrderRepository> { repo: R }

impl<R: OrderRepository> ConfirmOrderHandler<R> {
    pub fn new(repo: R) -> Self { Self { repo } }
    pub async fn handle(&self, cmd: ConfirmOrder) -> Result<(), ApplicationError> {
        let mut order = self.repo.find(cmd.order_id).await?.ok_or(ApplicationError::NotFound)?;
        order.confirm()?;
        self.repo.save(&mut order).await?;
        Ok(())
    }
}
```

## Infrastructure template

```rust
pub struct PgOrderRepository { pool: sqlx::PgPool }

impl OrderRepository for PgOrderRepository {
    async fn find(&self, id: OrderId) -> Result<Option<Order>, RepositoryError> {
        // query row -> map to domain via a private OrderRow -> Order conversion
        todo!()
    }
    async fn save(&self, order: &mut Order) -> Result<(), RepositoryError> { todo!() }
}
```
Keep `OrderRow` (DB model) private to infrastructure; never reuse it as the domain entity.

## Composition root

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let pool = sqlx::PgPool::connect(&std::env::var("DATABASE_URL")?).await?;
    let handler = ConfirmOrderHandler::new(PgOrderRepository::new(pool));
    // build axum router with `handler`, serve
    Ok(())
}
```
