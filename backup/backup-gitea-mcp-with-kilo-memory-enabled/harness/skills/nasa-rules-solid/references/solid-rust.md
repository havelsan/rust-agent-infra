# SOLID in Rust

| Principle | Meaning | In Rust |
| --- | --- | --- |
| Single responsibility | One reason to change | One type or module per concept. If the description needs "and", split it |
| Open/closed | Extend without editing | Add a new implementation of a trait instead of adding a branch to a `match` in old code |
| Liskov substitution | Implementations are interchangeable | An implementation of a trait must keep the trait's documented behavior, errors, and limits |
| Interface segregation | Small interfaces | Several small traits instead of one large one. Callers depend only on what they use |
| Dependency inversion | Depend on abstractions | Use cases take `&dyn Port` or a generic `P: Port`. Adapters implement the port. The inner layer owns the trait |

## Signs of a violation

- A `match` on a type tag that grows with every feature (open/closed).
- A trait with methods that some implementations answer with `unimplemented!()` (Liskov, interface segregation).
- A use case that imports a database type (dependency inversion).
- A struct with fields used by only some of its methods (single responsibility).
