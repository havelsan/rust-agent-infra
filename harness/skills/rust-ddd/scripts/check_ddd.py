#!/usr/bin/env python3
"""Check DDD layer rules in a Rust project (Cargo workspace or single crate).

Usage: check_ddd.py <project-root> [--strict]
Exit code 1 if any ERROR (or any WARN with --strict).
"""
import re, sys, pathlib
try:
    import tomllib
except ImportError:  # Python < 3.11
    tomllib = None

ALLOWED = {  # layer -> layers it may depend on
    "domain": set(),
    "application": {"domain"},
    "infrastructure": {"domain", "application"},
    "interface": {"domain", "application"},
    "bootstrap": {"domain", "application", "infrastructure", "interface"},
}
KEYS = [  # (layer, name tokens)
    ("bootstrap", ("bootstrap", "server", "composition")),
    ("domain", ("domain",)),
    ("application", ("application", "usecases", "app")),
    ("infrastructure", ("infrastructure", "infra", "adapters", "persistence")),
    ("interface", ("interface", "presentation", "api", "web", "http", "cli", "grpc")),
]
BAD_DOMAIN_CRATES = {
    "sqlx", "diesel", "sea_orm", "rusqlite", "tokio", "async_std", "axum", "actix_web",
    "rocket", "warp", "hyper", "reqwest", "tonic", "redis", "mongodb", "lapin", "rdkafka",
    "clap", "anyhow",
}
issues = []


def add(sev, where, msg):
    issues.append((sev, str(where), msg))


def layer_of(name):
    toks = re.split(r"[-_./]", name.lower())
    for layer, keys in KEYS:
        if any(t in keys for t in toks):
            return layer
    return None


def strip_comments(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)


def scan_domain_source(path, root):
    src = strip_comments(path.read_text(errors="ignore"))
    rel = path.relative_to(root)
    for m in re.finditer(r"\b(?:use|extern\s+crate)\s+([A-Za-z_][A-Za-z0-9_]*)", src):
        if m.group(1) in BAD_DOMAIN_CRATES:
            add("ERROR", rel, f"domain uses framework/IO crate `{m.group(1)}`")
    if re.search(r"\bunsafe\b", src):
        add("WARN", rel, "`unsafe` in domain")
    if re.search(r"\.unwrap\(\)|\.expect\(|\bpanic!\(", src):
        add("WARN", rel, "unwrap/expect/panic in domain: return DomainError instead")
    if re.search(r"\basync\s+fn\b", src) and "trait" not in src:
        add("WARN", rel, "async fn in domain logic (async belongs in ports/application)")
    if re.search(r"\bimpl(?:<[^>]*>)?\s+\w*Repository\w*\s+for\b", src):
        add("ERROR", rel, "repository implementation inside domain: move to infrastructure")
    for m in re.finditer(r"pub struct (\w+)\s*\{([^}]*)\}", src):
        pub_fields = re.findall(r"^\s*pub\s+\w+\s*:", m.group(2), flags=re.M)
        if pub_fields:
            add("WARN", rel, f"struct `{m.group(1)}` has public fields (anemic model / broken invariants)")


def check_workspace(root):
    crates = {}
    for toml in root.glob("**/Cargo.toml"):
        if "target" in toml.parts or toml.parent == root and "[workspace]" in toml.read_text() and "[package]" not in toml.read_text():
            continue
        if tomllib is None:
            continue
        data = tomllib.loads(toml.read_text())
        pkg = data.get("package", {}).get("name")
        if not pkg:
            continue
        crates[pkg] = (toml.parent, data)
    layered = {n: layer_of(n) or layer_of(p.name) for n, (p, _) in crates.items()}
    if sum(1 for v in layered.values() if v) < 2:
        return False
    for name, (path, data) in crates.items():
        layer = layered[name]
        if not layer:
            continue
        deps = set()
        for sec in ("dependencies", "build-dependencies"):
            deps |= set(data.get(sec, {}))
        for d in deps:
            dl = layered.get(d)
            if dl and dl != layer and dl not in ALLOWED[layer]:
                add("ERROR", path.relative_to(root) / "Cargo.toml", f"{layer} crate `{name}` depends on {dl} crate `{d}`")
            if layer == "domain" and d.replace("-", "_") in BAD_DOMAIN_CRATES:
                add("ERROR", path.relative_to(root) / "Cargo.toml", f"domain crate depends on `{d}`")
        for f in path.glob("src/**/*.rs"):
            if layer == "domain":
                scan_domain_source(f, root)
            src = strip_comments(f.read_text(errors="ignore"))
            for m in re.finditer(r"\b(?:use\s+)?([a-z][a-z0-9_]*)::", src):
                dn = m.group(1).replace("_", "-")
                for other, ol in layered.items():
                    if other.replace("-", "_") == m.group(1) and ol and ol != layer and ol not in ALLOWED[layer]:
                        add("ERROR", f.relative_to(root), f"{layer} code references {ol} crate `{other}`")
                        break
    return True


def check_modules(root):
    src = root / "src"
    dirs = {d.name: layer_of(d.name) for d in src.iterdir() if d.is_dir()} if src.exists() else {}
    dirs = {k: v for k, v in dirs.items() if v}
    if len(dirs) < 2:
        return False
    for mod, layer in dirs.items():
        for f in (src / mod).glob("**/*.rs"):
            if layer == "domain":
                scan_domain_source(f, root)
            text = strip_comments(f.read_text(errors="ignore"))
            for m in re.finditer(r"\bcrate::(\w+)", text):
                ol = dirs.get(m.group(1))
                if ol and ol != layer and ol not in ALLOWED[layer]:
                    add("ERROR", f.relative_to(root), f"{layer} imports {ol} (`crate::{m.group(1)}`)")
    return True


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    strict = "--strict" in sys.argv
    root = pathlib.Path(args[0] if args else ".").resolve()
    if not (check_workspace(root) or check_modules(root)):
        print("No DDD layers detected (need >=2 of: domain, application, infrastructure, interface).")
        sys.exit(2)
    for sev, where, msg in sorted(set(issues)):
        print(f"{sev:5} {where}: {msg}")
    errors = sum(1 for i in issues if i[0] == "ERROR")
    warns = len(set(issues)) - errors
    print(f"\n{errors} error(s), {warns} warning(s)")
    sys.exit(1 if errors or (strict and warns) else 0)


if __name__ == "__main__":
    main()
