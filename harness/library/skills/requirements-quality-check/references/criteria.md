# Quality criteria for requirements and issues

Check each requirement against all twelve. Report a finding as: `ID | criterion | severity (high/medium/low) | evidence | fix`.

| Criterion | Question | Typical finding |
| --- | --- | --- |
| Consistency | Do two statements agree in terms, units, and values? | "Timeout is 5 s" in REQ-3, "10 s" in REQ-8 |
| Ambiguity | Can the text be read in more than one way? | "fast", "as needed", "and/or" |
| Contradiction | Can both statements be true at once? | "shall store data" vs "shall not persist data" |
| Completeness | Is anything missing: inputs, outputs, errors, limits, actors, units? | No behavior defined for invalid input |
| Redundancy | Is the same thing said twice? | Same requirement in two issues |
| Validity | Does the requirement serve a stated need or stakeholder? | Requirement without a purpose |
| Relevance | Does it belong in this project and this level of detail? | Implementation detail in a business requirement |
| Accuracy | Are facts, numbers, and references right? | Wrong standard number, wrong unit |
| Clarity | Can a new reader understand it on first read? | Long sentence, unexplained abbreviation |
| Correctness | Is it technically possible and physically sensible? | Latency target below the speed of the link |
| Entailment | Does one statement follow from others (making it implied or in conflict)? | REQ-9 already follows from REQ-2 and REQ-4 |
| Satisfiability | Can all requirements be met together? | Memory limit and cache size that cannot both hold |

## Severity

- **high**: blocks design or testing, or two requirements cannot both be met. Escalate to the Coordinator.
- **medium**: causes rework if not fixed.
- **low**: wording only.

## Evidence rule

Quote the exact text (short) and the issue or wiki location. A finding without evidence cannot be fixed.
