---
name: rust-19-numeric
description: Rust rules module 19: Numeric & Arithmetic Safety. 5 rules, priority HIGH. Load on its own to review or write Rust code against this topic only. Rule prefixes: `num-`
---

# Numeric & Arithmetic Safety

Priority: HIGH. 5 rules. Part of the split rust-skills set (see `rust-00-router`).

## How to use this module

1. Read the rule list below.
2. Compare the code under review against each rule's Bad/Good examples.
3. Report only violations that actually occur, citing the rule id and the line.
4. When finished, stop and let the next module be loaded.

## Rule list

- `num-overflow-explicit` - Handle integer overflow explicitly: `checked_`/`saturating_`/`wrapping_`/`overflowing_`
- `num-cast-try-from` - Avoid `as` for narrowing casts; use `From` for widening and `TryFrom` for narrowing
- `num-float-compare` - Don't compare floats with `==`; use a tolerance, and `total_cmp` for ordering
- `num-saturating-clamp` - Bound values with `clamp` and saturating arithmetic
- `num-nonzero` - Use `NonZero*` types to forbid zero and unlock the niche optimization

---

## num-overflow-explicit

> Handle integer overflow explicitly: `checked_`/`saturating_`/`wrapping_`/`overflowing_`

### Why It Matters

Integer overflow panics in debug builds and silently wraps (two's complement) in release builds. Relying on either default behavior is a latent bug — the release build can produce wrong results without any diagnostic. Choosing an explicit variant makes intent unmistakable to both the compiler and future readers.

### Bad

```rust
fn add_score(current: u32, delta: u32) -> u32 {
    current + delta  // panics in debug, wraps silently in release
}

fn increment_counter(c: u8) -> u8 {
    c + 1  // wraps to 0 in release when c == 255
}
```

### Good

```rust
// checked_add: returns None on overflow — propagate or handle the error
fn add_score(current: u32, delta: u32) -> Option<u32> {
    current.checked_add(delta)
}

// saturating_add: clamps at the type's upper bound (u8::MAX == 255)
fn increment_saturating(c: u8) -> u8 {
    c.saturating_add(1)
}

// wrapping_add: intentional modular (two's complement) arithmetic
fn wrapping_sequence(n: u8) -> u8 {
    n.wrapping_add(1)
}

// overflowing_add: returns (result, did_overflow) — useful for carry detection
fn add_with_carry(a: u32, b: u32) -> (u32, bool) {
    a.overflowing_add(b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn checked_returns_none_on_overflow() {
        assert_eq!(add_score(u32::MAX, 1), None);
        assert_eq!(add_score(10, 5), Some(15));
    }

    #[test]
    fn saturating_clamps_at_max() {
        assert_eq!(increment_saturating(255), 255);
        assert_eq!(increment_saturating(10), 11);
    }

    #[test]
    fn wrapping_rolls_over() {
        assert_eq!(wrapping_sequence(255), 0);
    }

    #[test]
    fn overflowing_reports_carry() {
        assert_eq!(add_with_carry(u32::MAX, 1), (0, true));
        assert_eq!(add_with_carry(1, 2), (3, false));
    }
}
```

### Key Points

| Method family | Returns | Use when |
|---|---|---|
| `checked_*` | `Option<T>` | overflow is an error your caller must handle |
| `saturating_*` | `T` | clamping at the type's bounds is correct behavior |
| `wrapping_*` | `T` | modular arithmetic is intentional (e.g., checksums, ring buffers) |
| `overflowing_*` | `(T, bool)` | you need the result *and* know whether it overflowed |

These methods are available on all primitive integer types in the standard library (`u8` through `u128`, `i8` through `i128`, `usize`, `isize`). Equivalent sub/mul/div/shl/shr variants exist for every arithmetic operation.

Related: `num-saturating-clamp`, `num-cast-try-from`

## num-cast-try-from

> Avoid `as` for narrowing casts; use `From` for widening and `TryFrom` for narrowing

### Why It Matters

The `as` cast silently truncates or wraps on narrowing (`300u32 as u8 == 44`) and produces surprising results on float-to-integer conversion (values outside range saturate to the type's min/max since Rust 1.45, but `NaN` becomes `0`). These behaviors are easy to miss during code review and impossible to catch at runtime without tests. `From`/`Into` are lossless by design and will not compile for lossy conversions; `TryFrom`/`TryInto` return `Result` and make the fallibility explicit.

### Bad

```rust
fn narrow(x: u32) -> u8 {
    x as u8  // silently truncates: 300 becomes 44
}

fn to_index(f: f64) -> usize {
    f as usize  // NaN becomes 0, negatives become 0, may truncate
}

fn widen(x: u8) -> u32 {
    x as u32  // works, but hides that this is always safe
}
```

### Good

```rust
use std::convert::TryFrom;

// widening: From<u8> for u32 is always lossless — won't compile if lossy
fn widen(x: u8) -> u32 {
    u32::from(x)
    // or: x.into()
}

// narrowing: TryFrom makes the failure case explicit
fn narrow(x: u32) -> Result<u8, <u8 as TryFrom<u32>>::Error> {
    u8::try_from(x)
    // or: x.try_into()
}

// float → integer: validate the range manually before casting
fn float_to_index(f: f64, len: usize) -> Option<usize> {
    if f.is_nan() || f < 0.0 || f >= len as f64 {
        return None;
    }
    Some(f as usize)  // `as` is acceptable here: range is verified above
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::convert::TryFrom;

    #[test]
    fn widen_is_lossless() {
        assert_eq!(widen(255), 255u32);
    }

    #[test]
    fn narrow_errors_on_overflow() {
        assert!(narrow(300).is_err());
        assert_eq!(narrow(200), Ok(200u8));
    }

    #[test]
    fn float_to_index_rejects_nan_and_negative() {
        assert_eq!(float_to_index(f64::NAN, 10), None);
        assert_eq!(float_to_index(-1.0, 10), None);
        assert_eq!(float_to_index(3.9, 10), Some(3));
    }

    #[test]
    fn as_cast_truncation_footgun() {
        // demonstrating why `as` is dangerous for narrowing:
        let x: u32 = 300;
        assert_eq!(x as u8, 44);  // 300 % 256 == 44 — silently wrong
    }
}
```

### Key Points

- `From<A> for B` compiles only when the conversion is always lossless. Attempting `u8::from(300u32)` is a compile error.
- `TryFrom` returns `Result<T, TryFromIntError>` from the standard library — no external crates needed.
- Reserve `as` for:
  - Pointer casts (e.g., `*const u8 as *mut u8`) that are intentional.
  - Float-to-integer when you have verified the range and documented the intent.
  - `usize` ↔ pointer-sized integer when exact semantics are required.
- When using `.try_into()`, the turbofish or type annotation is often needed to help inference: `let n: u8 = x.try_into()?;`

Related: `conv-tryfrom-fallible`, `num-overflow-explicit`

## num-float-compare

> Don't compare floats with `==`; use a tolerance, and `total_cmp` for ordering

### Why It Matters

Floating-point arithmetic is not exact: `0.1 + 0.2 == 0.3` evaluates to `false` in Rust (and every IEEE 754 language) because neither value is representable exactly in binary. Additionally, `NaN != NaN` by the IEEE 754 standard, so equality comparisons involving `NaN` always return `false`. For sorting, `f64::partial_cmp` returns `None` on `NaN`, which makes `sort_by` panic with an inconsistent-order error. Use an epsilon tolerance for approximate equality and `f64::total_cmp` (stable since Rust 1.62) for total ordering.

### Bad

```rust
fn is_unit_length(x: f64, y: f64) -> bool {
    (x * x + y * y).sqrt() == 1.0  // almost always false due to rounding
}

fn sort_scores(scores: &mut Vec<f64>) {
    scores.sort_by(|a, b| a.partial_cmp(b).unwrap());
    // panics (unwrap on None) if any score is NaN
}
```

### Good

```rust
// approximate equality with an absolute epsilon
fn approx_eq(a: f64, b: f64, epsilon: f64) -> bool {
    (a - b).abs() < epsilon
}

fn is_unit_length(x: f64, y: f64) -> bool {
    approx_eq((x * x + y * y).sqrt(), 1.0, 1e-9)
}

// total ordering: NaN sorts after everything else (consistent, never panics)
fn sort_scores(scores: &mut Vec<f64>) {
    scores.sort_by(|a, b| a.total_cmp(b));
}

// direct NaN check when needed
fn safe_reciprocal(x: f64) -> Option<f64> {
    if x == 0.0 || x.is_nan() {
        None
    } else {
        Some(1.0 / x)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn float_addition_is_not_exact() {
        assert_ne!(0.1_f64 + 0.2, 0.3);  // IEEE 754 rounding
        assert!(approx_eq(0.1 + 0.2, 0.3, 1e-10));
    }

    #[test]
    fn nan_is_not_equal_to_itself() {
        let nan = f64::NAN;
        assert_ne!(nan, nan);  // NaN != NaN by IEEE 754
    }

    #[test]
    fn total_cmp_handles_nan() {
        let mut v = vec![3.0_f64, f64::NAN, 1.0, f64::NAN, 2.0];
        sort_scores(&mut v);
        // NaN values sort to the end; finite values are in order
        assert_eq!(&v[..3], &[1.0, 2.0, 3.0]);
        assert!(v[3].is_nan());
        assert!(v[4].is_nan());
    }

    #[test]
    fn unit_length_uses_tolerance() {
        assert!(is_unit_length(1.0, 0.0));
        assert!(is_unit_length(0.6, 0.8));  // 3-4-5 right triangle scaled
    }
}
```

### Key Points

- **Epsilon choice**: an absolute epsilon (`1e-9`) is simple but wrong for very large or very small values. For general-purpose code, a relative epsilon `(a - b).abs() / a.abs().max(b.abs()) < epsilon` is more robust — but requires handling the zero case.
- **`f64::total_cmp`** defines a strict total order: `-NaN < -∞ < … < -0.0 < +0.0 < … < +∞ < NaN`. It never panics and is available on `f32` and `f64`.
- **`is_nan` / `is_infinite` / `is_finite`**: use these predicates before arithmetic on untrusted floats.
- **Equality on `f32`/`f64` with `==`** is intentionally kept in the language for cases where you need bit-exact comparison (e.g., checking whether a value changed since last write). Document such uses explicitly.

Related: `num-overflow-explicit`

## num-saturating-clamp

> Bound values with `clamp` and saturating arithmetic

### Why It Matters

Constraining a numeric value to a range is a common operation, but hand-rolled `if`/`min`/`max` chains are verbose and easy to get wrong (especially when combining signed and unsigned types). `Ord::clamp(min, max)` expresses the intent in a single call and is available on all types that implement `Ord` (all integer primitives, and `f32`/`f64` via their own `clamp` since Rust 1.50). When you additionally want arithmetic that stops at the type's limits rather than panicking or wrapping, combine `clamp` with `saturating_*` methods.

### Bad

```rust
fn apply_damage(health: i32, damage: i32) -> i32 {
    let result = health - damage;
    if result < 0 { 0 } else { result }  // verbose, easy to mis-order
}

fn clamp_volume(vol: u8, min: u8, max: u8) -> u8 {
    if vol < min {
        min
    } else if vol > max {
        max
    } else {
        vol
    }
}
```

### Good

```rust
fn apply_damage(health: i32, damage: i32) -> i32 {
    // saturating_sub stops at i32::MIN — then clamp ensures non-negative
    health.saturating_sub(damage).clamp(0, i32::MAX)
}

fn clamp_volume(vol: u8, min: u8, max: u8) -> u8 {
    vol.clamp(min, max)
}

// integer clamp: any Ord type
fn clamp_score(score: i64) -> i64 {
    score.clamp(0, 100)
}

// float clamp: available on f32/f64 since Rust 1.50
fn normalize_alpha(a: f32) -> f32 {
    a.clamp(0.0, 1.0)  // NaN propagates: NaN.clamp(0.0, 1.0) == NaN
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn damage_does_not_go_below_zero() {
        assert_eq!(apply_damage(10, 5), 5);
        assert_eq!(apply_damage(3, 100), 0);
    }

    #[test]
    fn volume_is_bounded() {
        assert_eq!(clamp_volume(50, 10, 90), 50);
        assert_eq!(clamp_volume(5, 10, 90), 10);
        assert_eq!(clamp_volume(200, 10, 90), 90);
    }

    #[test]
    fn score_is_clamped() {
        assert_eq!(clamp_score(-10), 0);
        assert_eq!(clamp_score(150), 100);
        assert_eq!(clamp_score(75), 75);
    }

    #[test]
    fn float_nan_propagates_through_clamp() {
        assert!(f32::NAN.clamp(0.0, 1.0).is_nan());
    }
}
```

### Key Points

- **`clamp` panics if `min > max`** — this is a programming error and is caught in debug builds. If `min`/`max` come from user input, validate their order first.
- **`f32`/`f64` `clamp`** propagates `NaN`: if `self` is `NaN`, the result is `NaN`. If `min` or `max` is `NaN`, the result is unspecified. Filter `NaN` before calling `clamp` on untrusted floats.
- **Saturating vs. clamping**: `saturating_*` applies to a single arithmetic operation and stops at the type's absolute limits (`i32::MIN`/`i32::MAX`). `clamp` applies to the final value and accepts arbitrary bounds. They compose well, as shown in `apply_damage`.
- The standard library docs for `clamp` are at `std::cmp::Ord::clamp` and `f32::clamp`.

Related: `num-overflow-explicit`, `num-cast-try-from`

## num-nonzero

> Use `NonZero*` types to forbid zero and unlock the niche optimization

### Why It Matters

`NonZeroU32`, `NonZeroI64`, and their siblings (available for all integer primitives in `std::num`) make zero unrepresentable at the type level — you cannot construct one without going through `NonZeroU32::new(n)`, which returns `Option<NonZeroU32>`. This pushes the zero-check to the construction site and eliminates defensive zero-checks throughout the rest of the code. As a bonus, the compiler uses the zero bit-pattern as a *niche*, so `Option<NonZeroU32>` is exactly the same size as `u32` — no overhead for the `Option` tag.

### Bad

```rust
// caller must remember never to pass 0, but nothing enforces it
fn divide(numerator: u32, denominator: u32) -> u32 {
    assert!(denominator != 0, "denominator must not be zero");
    numerator / denominator
}

// ID of 0 is "invalid" by convention — not enforced
struct Widget {
    id: u32,  // 0 means "not yet assigned" — stringly-typed convention
}
```

### Good

```rust
use std::num::NonZeroU32;
use std::mem::size_of;

// zero is rejected at construction; division is always safe
fn divide(numerator: u32, denominator: NonZeroU32) -> u32 {
    numerator / denominator.get()
}

// ID is guaranteed non-zero; Option<WidgetId> is free
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct WidgetId(NonZeroU32);

impl WidgetId {
    /// Returns `None` if `id` is zero.
    pub fn new(id: u32) -> Option<Self> {
        NonZeroU32::new(id).map(WidgetId)
    }

    pub fn get(self) -> u32 {
        self.0.get()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::num::NonZeroU32;

    #[test]
    fn nonzero_new_returns_none_for_zero() {
        assert!(NonZeroU32::new(0).is_none());
        assert!(NonZeroU32::new(1).is_some());
    }

    #[test]
    fn option_nonzero_is_same_size_as_u32() {
        // niche optimization: no space overhead for Option
        assert_eq!(size_of::<Option<NonZeroU32>>(), size_of::<u32>());
        assert_eq!(size_of::<Option<NonZeroU32>>(), 4);
    }

    #[test]
    fn widget_id_rejects_zero() {
        assert!(WidgetId::new(0).is_none());
        let id = WidgetId::new(42).unwrap();
        assert_eq!(id.get(), 42);
    }

    #[test]
    fn divide_uses_nonzero_denominator() {
        let denom = NonZeroU32::new(3).unwrap();
        assert_eq!(divide(12, denom), 4);
    }
}
```

### Key Points

- All `NonZero*` types live in `std::num`: `NonZeroU8`, `NonZeroU16`, `NonZeroU32`, `NonZeroU64`, `NonZeroU128`, `NonZeroUsize`, and their signed counterparts.
- **Construction**: `NonZeroU32::new(n) -> Option<NonZeroU32>`. Use `NonZeroU32::new(n).expect("n must be non-zero")` only at well-verified program boundaries, not in production fallible paths.
- **Access**: `.get()` returns the inner primitive value.
- **Arithmetic**: `NonZeroU32` does not implement `Add`/`Sub` directly (the result could be zero). Extract with `.get()`, do arithmetic, and reconstruct with `NonZeroU32::new(result)?`.
- **Niche optimization** applies to `Option` and `Result`: the compiler stores the `None`/`Err` discriminant in the zero bit-pattern, so no extra word is needed. This also applies to custom newtypes that wrap `NonZero*`.

Related: `type-newtype-ids`, `mem-smaller-integers`
