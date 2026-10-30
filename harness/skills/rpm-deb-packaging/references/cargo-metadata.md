# Cargo metadata for packages

Add to the `Cargo.toml` of the binary crate. Replace `myapp`.

```toml
[package]
name = "myapp"
version = "1.2.0"
license = "MIT"
description = "One-line description"

[package.metadata.deb]
maintainer = "Team Name <team@example.org>"
copyright = "2026, Team Name"
license-file = ["LICENSE", "0"]
extended-description = "Longer description for the package manager."
depends = "$auto"
section = "utils"
priority = "optional"
assets = [
    ["target/release/myapp", "usr/bin/", "755"],
    ["README.md", "usr/share/doc/myapp/README", "644"],
]

[package.metadata.generate-rpm]
assets = [
    { source = "target/release/myapp", dest = "/usr/bin/myapp", mode = "0755" },
    { source = "README.md", dest = "/usr/share/doc/myapp/README", mode = "0644", doc = true },
]
```

## Tools

```
cargo install cargo-deb
cargo install cargo-generate-rpm
```

## Checks after the build

- `dpkg-deb --info dist/*.deb` and `dpkg-deb --contents dist/*.deb`
- `rpm -qpi dist/*.rpm` and `rpm -qpl dist/*.rpm`
- Install and remove on a clean container for each format.
