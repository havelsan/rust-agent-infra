#!/usr/bin/env python3
"""Generate a domain module: ID value object, error enum, entity, repository port, and tests.

Usage: scaffold_aggregate.py <domain-crate-dir> <Name>
Example: scaffold_aggregate.py crates/domain Order  -> crates/domain/src/order.rs (+ 'pub mod order;' in lib.rs)
"""
import os
import re
import sys

if len(sys.argv) != 3:
    sys.exit(__doc__)
crate, raw = sys.argv[1], sys.argv[2]
words = re.findall(r"[A-Z]?[a-z0-9]+|[A-Z]+(?![a-z])", raw)
if not words:
    sys.exit("error: invalid name")
pascal = "".join(w.capitalize() for w in words)
snake = "_".join(w.lower() for w in words)
path = os.path.join(crate, "src", f"{snake}.rs")
if os.path.exists(path):
    sys.exit(f"error: {path} exists")

TEMPLATE = '''//! __N__ aggregate: value objects, entity, errors, and the repository port.

use std::fmt;

/// Identity of a `__N__`. The value zero is not allowed.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct __N__Id(u64);

impl __N__Id {
    /// Create an ID. Returns an error for zero.
    pub fn new(value: u64) -> Result<Self, __N__Error> {
        if value == 0 {
            return Err(__N__Error::InvalidId);
        }
        Ok(Self(value))
    }

    pub fn value(self) -> u64 {
        self.0
    }
}

/// Errors of the `__N__` domain.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum __N__Error {
    InvalidId,
    NotFound,
    Storage(String),
}

impl fmt::Display for __N__Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidId => write!(f, "invalid __S__ id"),
            Self::NotFound => write!(f, "__S__ not found"),
            Self::Storage(msg) => write!(f, "storage error: {msg}"),
        }
    }
}

impl std::error::Error for __N__Error {}

/// Entity and aggregate root. Change it only through its methods.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct __N__ {
    id: __N__Id,
}

impl __N__ {
    pub fn new(id: __N__Id) -> Self {
        Self { id }
    }

    pub fn id(&self) -> __N__Id {
        self.id
    }
}

/// Port. The infrastructure layer implements it.
pub trait __N__Repository {
    fn find(&self, id: __N__Id) -> Result<Option<__N__>, __N__Error>;
    fn save(&mut self, item: &__N__) -> Result<(), __N__Error>;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn zero_id_is_rejected() {
        assert_eq!(__N__Id::new(0), Err(__N__Error::InvalidId));
    }

    #[test]
    fn valid_id_is_kept() -> Result<(), __N__Error> {
        let id = __N__Id::new(7)?;
        assert_eq!(id.value(), 7);
        assert_eq!(__N__::new(id).id(), id);
        Ok(())
    }
}
'''
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, "w", encoding="utf-8").write(TEMPLATE.replace("__N__", pascal).replace("__S__", " ".join(w.lower() for w in words)))
lib = os.path.join(crate, "src", "lib.rs")
line = f"pub mod {snake};\n"
existing = open(lib, encoding="utf-8").read() if os.path.exists(lib) else ""
if line not in existing:
    open(lib, "a", encoding="utf-8").write(("" if existing.endswith("\n") or not existing else "\n") + line)
print(f"created {path}")
