---
name: audit
description: Audit a codebase for unnecessary AI coding assistant token consumption. Evaluates CLAUDE.md and AGENTS.md, documentation, skills, MCP servers, build and test commands, repository exploration, subagents, and context management, then produces a prioritized improvement report without modifying project files. Use when the user asks why Claude Code is expensive, wants token usage reduced, or wants their context files and skills reviewed for bloat.
---

# Token Usage Audit

Find the changes that would cut token consumption on this project, and report
them. **This skill is an audit, not an implementation task:** do not create,
modify, move or delete project files. At the end, offer to implement the
recommendations as a separate phase.

To set context files up or restructure them, use the `setup` skill instead.

## Principles

- Evidence over assumptions. Separate **confirmed** (seen in a file) from
  **likely** (strong evidence, session behavior unknown) from **potential**.
- Inspect configuration before source. Don't scan the whole repo, don't read
  large docs in full, don't run full builds or tests, don't install anything.
- Never recommend a change that costs build correctness, test coverage or
  diagnosability. Reducing tokens is the goal; reducing quality is not.
- Don't invent percentages or monetary savings. No measurement, no number.
- Don't print secrets, credentials or sensitive log contents.

## 1. Discover the project

Cheap commands only: list the top level, glob the build files two levels deep
(`pom.xml`, `package.json`, `build.gradle*`, `Cargo.toml`, `go.mod`,
`pyproject.toml`), glob `CLAUDE.md` / `AGENTS.md` and `.claude/` directories,
excluding `target/` and `node_modules/`.

Establish: single- or multi-module, how many modules, whether modules have
distinct responsibilities, whether module-level instructions exist, and which
generated or vendored directories should be excluded from exploration.

## 2. Context files

Inventory every `CLAUDE.md` / `AGENTS.md` (root, nested, `.claude/CLAUDE.md`),
`.claude/rules/*.md` and `SKILL.md`. Line counts via `wc -l`; tokens ≈ chars ÷ 4.

Estimate **startup cost**: root files + rules without `paths:` frontmatter +
skill descriptions + everything pulled in by `@imports`. Nested `CLAUDE.md`
files and skill bodies load on demand and do not count.

Check each file against the per-file rules in the `setup` skill's
`references/audit-rules.md` — one section per check, each with its threshold and
its fix (root too long, module too long, eager `@import`, unscoped rule,
duplicate content, oversized skill body, weak skill description, generic
advice). Read only the sections whose condition you actually see.

Then, beyond those thresholds, check for:

- **Misplacement** — module-only rules in the root file; technical description
  that belongs in `docs/`; a repeatable workflow that belongs in a skill.
- **Staleness** — instructions that no longer match the code.
- **Missing scope limits** — whether the instructions say to work only in the
  requested module, avoid unrelated exploration, avoid unasked refactoring, run
  targeted tests, keep command output short, and ask before touching shared
  modules or parent build files. Absence of these is a common cause of
  whole-repository exploration.

For each finding say whether the content should be removed, shortened,
consolidated, moved to docs, moved to a skill, or made module-specific. Do not
delete useful architectural knowledge just to shorten a file.

## 3. Documentation

Check whether README files carry excessive technical detail, whether documents
repeat each other, whether build instructions are duplicated, and whether module
docs are mixed into global docs. Recommend linking to docs rather than copying
them into a context file, so they load only when needed.

## 4. Skills

Evaluate count, body size, overlap, fragmentation, reusability, and whether a
skill carries large reference material in its body instead of `references/`.
Recommend consolidation where skills overlap, and a skill for a genuinely
recurring workflow — but not one per coding convention.

## 5. MCP servers

From the accessible MCP configuration, identify configured servers and roughly
how many tools each contributes. Tool definitions are paid for on every request.

Flag servers that merely wrap shell work — builds, tests, git, file search. Local
builds and tests belong in Bash. MCP earns its tokens when it provides something
a shell cannot: structured CI results, remote build management, issue tracking,
code-quality integrations.

Distinguish *configured* servers from servers actually loaded into this session.

## 6. Build scope and module targeting

For a multi-module project this is usually the biggest win. Check whether the
instructions push whole-project builds (`mvn clean install`, `npm run build` at
the root, a full `cargo build --workspace`) for an ordinary one-module change,
and recommend targeted commands instead. Maven examples:

```bash
./mvnw -pl module-a test                      # one module
./mvnw -pl module-a -Dtest=ExampleTest test   # one test class
./mvnw -pl module-a -am test                  # with reactor dependencies
```

Check that module names and artifact IDs are documented, that per-module commands
exist, that the assistant is told to start in the target module, and that
cross-module changes need approval.

Important: Maven's `-pl` limits what Maven builds. It does **not** limit what the
assistant reads or edits. For a real boundary, recommend permission rules or
filesystem restrictions.

## 7. Repository exploration

Look for unrestricted recursive search, whole-repo analysis for small tasks,
reading every README or build file, searching generated directories, re-opening
the same files, and large file dumps. Recommend naming the module and the entry
point in the task instead:

> Investigate the issue in `module-billing`. Start with the relevant service and
> its tests. Inspect only directly related classes. Do not touch other modules.

Identify directories to exclude — typically `target/`, `build/`, `dist/`,
`node_modules/`, `generated/`, `vendor/`. Adapt to the actual project.

## 8. Build and test output

Repeated verbose output is one of the largest avoidable costs. Check whether
routine commands run quietly, whether test output is unnecessarily verbose,
whether logs get pasted in full, and whether failure summaries are available.

```bash
./mvnw -q -pl module-a test
```

Redirect, then extract — preserving the exit status:

```bash
./mvnw -q test > "$LOG" 2>&1
status=$?
grep -E "ERROR|FAILURE|Tests run:|BUILD SUCCESS|BUILD FAILURE" "$LOG" | tail -40
exit $status
```

Never recommend suppressing the diagnostics needed to investigate a failure.

For a project whose builds are genuinely noisy — plugin banners, Spring startup,
Hibernate SQL, Testcontainers — read `references/maven-output.md`: it covers
finding the actual output source, judging quiet mode, test logging levels, and
whether a wrapper script is justified.

## 9. Session-level habits

- **Model and reasoning effort** — cheaper model and lower effort for routine or
  mechanical edits, stronger for architecture and hard debugging. Session
  settings, not project configuration, and not every assistant exposes them.
- **Prompt caching** — editing context files mid-session, changing MCP
  configuration and switching models all disturb the stable prefix. Finalize
  instructions before a session; change configuration between sessions. Don't
  claim a given change always resets every cache — that depends on the provider.
- **Subagents** — flag them for trivial edits, several agents reading the same
  files, and duplicated findings. They earn their keep on independently
  investigable work; parallelism alone is not a reason, and the handoff costs
  tokens too.

## 10. Measurement

Check whether the project has any way to see usage: a cost or usage command,
context inspection, provider usage reports, historical tracking. Recommend
measuring an equivalent task before and after — input, output, cache-read and
cache-write tokens, tool calls, files inspected, build scope, and whether the
result was still correct. Token savings and time savings are different things.

## 11. Report

Write the report as `references/report-template.md` lays out: it defines the
sections, the per-finding fields, and the severity / confidence / effort scales.
Keep it short enough to act on, and omit sections the project has nothing to say
about — an empty "MCP" heading costs tokens and tells the user nothing.

Finish by asking whether the user wants the recommendations implemented as a
separate phase.
