---
name: memory-compression
description: "Shrink memory and doc files in caveman style (drop filler and articles, keep facts, code, paths and numbers exact) to cut the input tokens they cost when recalled."
---
Script: `bash .kilo/skills/scripts/compress_memory.sh` (run with --dry-run first). compress_memory.sh backs up each markdown file as .orig, rewrites its prose tersely through kctx compress, and reports tokens before and after
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Modes lite, full, ultra. Never touches code fences, inline code, paths, URLs, numbers, headings, tables or front matter. Keeps an .orig backup. Do not invent abbreviations. The LLM-based /caveman-compress skill is a higher-quality alternative if installed.
