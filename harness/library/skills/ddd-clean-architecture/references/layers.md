# Layers for Rust projects (Domain-Driven Design + Clean Architecture)

Dependencies point inward only.

```
interface  ->  infrastructure  ->  application  ->  domain
(bin, CLI,      (DB, files,         (use cases,      (entities, value
 HTTP, wiring)   network, clock)     ports)           objects, rules)
```

| Layer | Contains | May depend on | Must not contain |
| --- | --- | --- | --- |
| domain | Entities, value objects, domain services, domain errors, repository traits (ports) for aggregates | std only (plus tiny pure crates such as `thiserror`) | I/O, async runtime, serialization framework, database types |
| application | Use cases, command/query handlers, port traits for outside systems | domain | Concrete adapters, framework types |
| infrastructure | Adapters implementing ports: database, file system, network, time, logging | application, domain | Business rules |
| interface | `main`, CLI/HTTP handlers, dependency wiring (composition root) | all inner layers | Business rules |

## Rules

1. A type that carries a business rule lives in `domain`.
2. A trait that the inside needs from the outside (repository, clock, message sender) is defined inside and implemented outside.
3. Parse and validate at the border: construct value objects so that an invalid value cannot exist inside.
4. Errors: each layer has its own error enum. Convert at the boundary with `From`. No `unwrap()` in library code.
5. Aggregates are changed only through their root. Other aggregates are referenced by ID.
6. Use the ubiquitous language: names in code match names in the requirements.

## Checks

`arch_snapshot.py` (see `architecture-assessment`) reads `layers.toml` and reports any dependency from an inner layer to an outer layer.
