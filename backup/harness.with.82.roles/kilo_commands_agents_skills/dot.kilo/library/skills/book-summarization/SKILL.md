---
name: book-summarization
description: "Summarize a long PDF part by part into a markdown file with a quick reference on top; interrupted runs resume where they stopped."
---
Script: `bash .kilo/skills/scripts/summarize_book.sh` (run with --dry-run first). summarize_book.sh extracts the PDF text page by page, splits it into parts that fit the context, has the Team Leader summarize each part in a fresh session, then writes the combined summary file
Do: read the issue and the hand-off, apply this skill, save results in the repo, report in the hand-off.
Large PDFs are split into parts that fit the context; each part is summarized in a fresh session and kept on disk, so an interrupted run resumes. Output: quick reference first, then one section per part.
