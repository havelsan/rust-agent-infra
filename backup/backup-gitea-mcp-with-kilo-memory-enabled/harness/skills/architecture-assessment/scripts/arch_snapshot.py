#!/usr/bin/env python3
"""Snapshot of a Cargo workspace architecture: crates, dependencies, layer violations, cycles.

Usage: arch_snapshot.py [ROOT] [--layers layers.toml]
layers.toml:
    order = ["domain", "application", "infrastructure", "interface"]   # inner -> outer
    [crates]
    shop_domain = "domain"
A crate may depend only on its own layer or an inner layer. Without layers.toml the layer is
guessed from the crate name (contains 'domain', 'application', 'infrastructure', 'interface').
Needs Python 3.11+ (tomllib).
"""
import argparse
import os
import sys
import tomllib

p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
p.add_argument("root", nargs="?", default=".")
p.add_argument("--layers")
a = p.parse_args()

order = ["domain", "application", "infrastructure", "interface"]
assign = {}
cfg_path = a.layers or os.path.join(a.root, "layers.toml")
if os.path.exists(cfg_path):
    cfg = tomllib.load(open(cfg_path, "rb"))
    order = cfg.get("order", order)
    assign = cfg.get("crates", {})

manifests = []
for r, dirs, files in os.walk(a.root):
    dirs[:] = [d for d in dirs if d not in ("target", ".git")]
    if "Cargo.toml" in files:
        manifests.append(os.path.join(r, "Cargo.toml"))

ws_deps = {}
pkgs = {}
for m in manifests:
    t = tomllib.load(open(m, "rb"))
    for n, spec in t.get("workspace", {}).get("dependencies", {}).items():
        if isinstance(spec, dict) and "path" in spec:
            ws_deps[n] = True
    if "package" in t:
        pkgs[t["package"]["name"]] = (m, t)

def local_deps(name):
    m, t = pkgs[name]
    found = set()
    for sect in ("dependencies", "build-dependencies"):
        for dep, spec in t.get(sect, {}).items():
            real = spec.get("package", dep) if isinstance(spec, dict) else dep
            if real in pkgs and (isinstance(spec, dict) and ("path" in spec or spec.get("workspace"))):
                found.add(real)
            elif real in pkgs and real in ws_deps:
                found.add(real)
    return found

def ext_count(name):
    t = pkgs[name][1]
    return sum(1 for d, s in t.get("dependencies", {}).items()
               if d not in pkgs and not (isinstance(s, dict) and "path" in s))

def loc(name):
    d = os.path.dirname(pkgs[name][0])
    files = n = 0
    for r, dirs, fs in os.walk(os.path.join(d, "src")):
        for f in fs:
            if f.endswith(".rs"):
                files += 1
                n += sum(1 for _ in open(os.path.join(r, f), encoding="utf-8", errors="replace"))
    return files, n

def layer(name):
    if name in assign:
        return assign[name]
    for l in order:
        if l in name.lower():
            return l
    return None

graph = {n: local_deps(n) for n in pkgs}
print("# Architecture snapshot\n")
print("| Crate | Layer | Local deps | External deps | Files | Lines |")
print("| --- | --- | --- | ---: | ---: | ---: |")
for n in sorted(pkgs):
    f, l = loc(n)
    print(f"| {n} | {layer(n) or '?'} | {', '.join(sorted(graph[n])) or '-'} | {ext_count(n)} | {f} | {l} |")

violations = []
for n, deps in graph.items():
    ln = layer(n)
    for d in deps:
        ld = layer(d)
        if ln in order and ld in order and order.index(ld) > order.index(ln):
            violations.append(f"{n} ({ln}) depends on {d} ({ld}): inner layer must not depend on outer layer")
unknown = [n for n in pkgs if layer(n) is None]

def cycles():
    seen, stack, out = set(), [], []
    def dfs(n):
        if n in stack:
            out.append(stack[stack.index(n):] + [n]); return
        if n in seen:
            return
        seen.add(n); stack.append(n)
        for d in graph.get(n, ()):
            dfs(d)
        stack.pop()
    for n in graph:
        dfs(n)
    return out

print("\n## Findings")
cyc = cycles()
for v in violations:
    print(f"- [high] layer violation: {v}")
for c in cyc:
    print(f"- [high] dependency cycle: {' -> '.join(c)}")
for n in unknown:
    print(f"- [low] crate {n} has no layer; add it to layers.toml")
if not (violations or cyc or unknown):
    print("- none")
sys.exit(1 if (violations or cyc) else 0)
