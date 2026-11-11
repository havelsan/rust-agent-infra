# Data-driven tests in Rust

A data-driven test keeps the cases in a table and runs one check over all rows. New cases cost one line, and the table reads like the requirement.

## Standard library only

```rust
#[test]
fn parse_speed_cases() {
    // (input, expected)
    let cases: &[(&str, Result<u32, ParseError>)] = &[
        ("0",      Ok(0)),
        ("120",    Ok(120)),
        ("",       Err(ParseError::Empty)),
        ("-1",     Err(ParseError::Negative)),
        ("12x",    Err(ParseError::NotANumber)),
    ];
    for (input, expected) in cases {
        assert_eq!(parse_speed(input), *expected, "input: {input:?}");
    }
}
```

The message names the failing row. Without it, a failure only shows the last assertion.

## Rules

- One table per behavior. Do not mix error cases and success cases if the checks differ.
- Include the boundaries: zero, one, maximum, maximum plus one, empty.
- Keep a requirement ID in a comment above the table: `// REQ-012`.
- Load larger tables from a file in `tests/data/` and keep the file under version control.

## With a helper crate

`rstest` offers `#[case]` attributes. Check any helper crate with `crate-download-filter` before use, and record the choice in the issue.
