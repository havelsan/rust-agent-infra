---
name: rust-ddd
description: Create, review, and verify Domain-Driven Design (DDD) architecture in Rust projects (layered / hexagonal, Cargo workspace or single crate). Use this skill whenever the user wants to scaffold a Rust project with DDD, add a bounded context, aggregate, entity, value object, repository, domain event, or use case, or asks to check, audit, or refactor Rust code for layer violations, anemic domain models, or dependency-rule breaks. Trigger even if they only say "clean architecture", "hexagonal", "ports and adapters", "domain layer", or "bounded context" in a Rust context.
---

# Rust DDD

Two jobs: **create** DDD structure in Rust, and **check** that existing code obeys it.
Rust is the fixed language; never propose another.

## Core rules (the dependency rule)

```
interface ──▶ application ──▶ domain ◀── infrastructure
                                ▲             │
                                └─ implements domain ports
```

- `domain`: pure Rust. Entities, value objects, aggregates, domain events, domain services, **repository traits (ports)**, domain errors. No I/O, no async runtime, no DB/HTTP/framework crates.
- `application`: use cases / command & query handlers orchestrating the domain. Depends on `domain` only. Defines extra ports (clock, event bus, unit of work) as traits.
- `infrastructure`: adapters implementing ports (sqlx/diesel repos, HTTP clients, message brokers). Depends on `domain` + `application`.
- `interface` (presentation): axum/actix/clap/gRPC handlers, DTOs, mapping to commands. Depends on `application` (and `domain` types only for mapping). Never calls infrastructure directly.
- `bootstrap` / `main`: the only place that wires concrete adapters into use cases (composition root).

## Workflow: CREATE

1. Ask (or infer) once: bounded context name(s), single crate vs workspace (default: **workspace**, one set of layer crates per bounded context), and sync vs async (default: async traits via `async fn` in traits, Rust 1.75+).
2. Scaffold using `references/layout.md` (layout + code templates). Create, in this order: domain → application → infrastructure → interface → bootstrap.
3. Model the domain first:
   - **Value objects**: immutable, validated in constructor (`new() -> Result<Self, DomainError>`), `#[derive(Clone, PartialEq, Eq, Debug)]`, newtype over primitives. No public fields.
   - **Entities**: identity (`Id` newtype), private fields, behavior as methods, invariants enforced in methods.
   - **Aggregates**: one root, other entities reachable only through it; one repository per aggregate root; changes collect `DomainEvent`s.
   - **Repository trait** lives in `domain`, returns domain types and `DomainError`/`RepositoryError`, never ORM types.
4. Use `thiserror` for error enums per layer; map errors at layer boundaries (`From` impls), never leak `sqlx::Error` upward.
5. Keep DTOs/serde derives in `interface` and `infrastructure`. Domain may use serde only if the user explicitly accepts it; default is no.
6. Add tests: unit tests for invariants in `domain`; use-case tests in `application` with in-memory fake repositories.
7. Run `cargo check` and `cargo clippy` after scaffolding, then run the checker (below).

## Workflow: CHECK

1. Run the checker from the repository root:
   ```bash
   python3 <skill-dir>/scripts/check_ddd.py <path-to-project> [--strict]
   ```
   It auto-detects workspace layout (crates named/located `*domain*`, `*application*`, `*infrastructure*`, `*interface*`/`*api*`/`*presentation*`) or single-crate layout (`src/domain`, `src/application`, ...). Exit code 1 means violations.
2. Report findings grouped by severity:
   - **ERROR** (dependency rule): inner layer imports outer layer; framework/DB/HTTP crate in `domain`; infrastructure referenced from `interface` outside bootstrap.
   - **WARN** (design smell): public fields on domain structs (anemic model), `unwrap()`/`expect()`/`panic!` in domain, repository *implementation* inside domain, `async`/`tokio` in domain.
3. For every ERROR, propose the concrete fix (usually: introduce a trait in the inner layer, implement it in infrastructure, inject in bootstrap). Do not just list problems.
4. Apply fixes only if the user asks; otherwise show a diff-style plan.
5. Also manually review what the script cannot see: aggregates that are too large, repositories per entity instead of per aggregate, domain logic leaking into handlers (application/interface), missing ubiquitous-language names.

## Conventions

- Names come from the business language (ubiquitous language), not technical names: `Order::confirm()`, not `OrderService::update_status()`.
- Application layer functions take a command/query struct and return a result DTO or domain type; no HTTP types.
- Prefer `Arc<dyn Trait>` or generics for ports; pick one style per project and stay consistent.
- One bounded context = its own set of layer crates; cross-context communication only via events or an explicit anti-corruption layer.
