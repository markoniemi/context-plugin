# Audit report shape

The structure of the report the `audit` skill produces. Skip any section the
project has nothing to say about; an empty heading costs tokens and informs
nobody.

## A. Project overview

Project type and build tool. Number of modules. Instruction files found, with
line counts. Skills found. MCP configuration found. The main build and test
approach. Estimated startup context cost in tokens.

## B. Executive summary

The handful of findings that matter, in a few sentences. If one change accounts
for most of the waste, say which.

## C. Findings by category

Only the categories that apply: context files, documentation, skills, MCP,
modules and build scope, repository exploration, build and test output, model
and reasoning, prompt caching, subagents, measurement.

Per finding:

- **Finding** — what is wrong.
- **Evidence** — file and line, or the command whose output shows it.
- **Why it costs tokens** — the mechanism, not a guess at a number.
- **Proposed change** — concrete; show the replacement text or command.
- **Expected benefit** — qualitative unless measured.
- **Severity / confidence / effort** — on the scales below.
- **Risks** — what gets harder if this is done.
- **Verification** — how to tell afterwards that it worked.

Scales:

- **Severity** — critical (large unnecessary context, or repeated whole-project
  work) / high (big exploration, build or tool-overhead wins) / medium
  (documentation, skill or instruction inefficiency) / low (optional polish).
- **Confidence** — confirmed (seen in a file) / likely (strong evidence, session
  behavior unknown) / potential (worth investigating).
- **Effort** — small (one instruction or config change) / medium (restructuring)
  / large (workflow or tooling change).

## D. Prioritized improvement plan

| Priority | Finding | Proposed change | Effort | Confidence |
| :- | :- | :- | :- | :- |

## E. Recommended target structure

A directory tree for instructions, skills and documentation, fitted to this
project. Not every project needs the same one.

## F. Recommended context file changes

For each `CLAUDE.md` / `AGENTS.md`: content to retain, to shorten, to move (and
where), to remove, and instructions that are missing. Do not rewrite the files
during the audit.

## G. Build scope plan

Exact module-scoped commands for this project's real module names, and the cases
where dependencies force a wider build.

## H. Quick wins

What can be done in minutes.

## I. Longer-term improvements

What needs restructuring or tooling work.

## J. Measurement plan

How to compare an equivalent task before and after: which metrics, which task,
where the numbers come from.

## K. Conclusion

The recommended implementation order, then the question of whether the user
wants it implemented.
