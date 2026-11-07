# Audit rules

One entry per thing that can be wrong: the condition, then the fix. Find the
entries for conditions you have actually observed; don't read the file through.
Report the code so the user can look it up.

Thresholds are this skill's, and tighter than the documented guidance in places —
say which number you applied. `loading-model.md` has the mechanics behind them.

## NO_ROOT_FILE
No `CLAUDE.md` and no `AGENTS.md` at the repository root.
Fix: nothing to audit. Run `/context:setup`, then audit the result.

## ROOT_TOO_LONG
Root `CLAUDE.md`/`AGENTS.md` over 80 lines (note it above 50). Sent with every
request of every session. Documented target is 200 per file; 80 is this skill's
tighter limit.
Fix: move module-specific lines into that module's `CLAUDE.md`, topic rules into
`.claude/rules/` with `paths:`, long explanations into a doc named in one line.
Delete generic advice. Claude Code already warns at startup and in `/status`,
including when several acceptable files exceed a combined limit — read those
first.

## MODULE_TOO_LONG
A subdirectory `CLAUDE.md` over 100 lines. Loads only for its own subtree, so
judge a genuinely large module against 200.
Fix: keep commands, layout and pitfalls. Move endpoint lists, schemas and
step-by-step procedures into a doc in the module and point at it.

## UNSCOPED_RULE
A `.claude/rules/*.md` with no `paths:` frontmatter, so it loads every session.
Fix: add `paths:` globs if it applies to only part of the repo; a short repo-wide
rule can stay.
Trade-off to state, not skip: path-scoped rules are summarized away by
compaction, unscoped ones are re-injected from disk. A rule that must still hold
late in a long session stays unscoped, or moves into the root file.

## AUTO_MEMORY_LARGE
`~/.claude/projects/<project>/memory/MEMORY.md` long, stale or wrong. Its first
200 lines or 25KB load every conversation; topic files beside it load on demand.
Easy to miss — outside the repo, and written by Claude rather than reviewed.
Fix: content past the threshold never loads, so move it to topic files. Stale
entries are worse than long ones, because they are instructions. Report only —
do not edit it during an audit. `/memory` edits and disables it, as do
`autoMemoryEnabled` and `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

## EAGER_IMPORT
An `@path` whose target runs past ~50 lines. The target is spliced in whenever
the importing file loads.
Fix: reserve imports for small files every session needs (`@AGENTS.md`).
Otherwise name the file and the situation in a sentence. Splitting one long file
into several imports does not reduce its cost.

## IMPORT_MISSING
An `@path` whose target does not exist. No error, no content.
Fix: correct the path or delete the line.

## DEAD_INSTRUCTION
A line that cannot take effect:
- A pointer written as an instruction ("see `AGENTS.md` for conventions") —
  Claude reads that file only if it decides to.
- An external import (resolving outside the working directory) that was declined
  at the approval prompt. It stays disabled and never asks again.
- An import inside backticks or a fenced block. Parsing skips both.
- An import with unescaped spaces — the path stops at the first space. Quoting it
  prevents the import entirely.
- An import more than four hops deep.
Fix: make it a real import, correct it, or delete it.

## DUPLICATE_CONTENT
The same line in two context files that can load together.
Fix: keep it in the most specific file that needs it — root if repo-wide, module
otherwise — and delete the rest. A deliberate `AGENTS.md`/`CLAUDE.md` pair is the
exception; see below.

## AGENTS_CLAUDE_DUPLICATE
`AGENTS.md` and `CLAUDE.md` side by side with overlapping content.
Fix: one home for the shared text. Recent Claude Code reads `AGENTS.md`
directly, so often no `CLAUDE.md` is needed; where one is, reduce it to
`@AGENTS.md` plus what is Claude-specific.

## GENERIC_ADVICE
Instructions Claude follows without being told: write clean code, handle errors
properly, use meaningful names, restated language conventions, explanations of
well-known frameworks.
Fix: delete, or replace with the specific non-obvious rule the author meant. A
line earns its place by changing behaviour — an exact command, a convention that
differs from the default, a "never do X here, because Y", a map of where things
live.

## OUTDATED_EMPHASIS
Advice shaped for older models, now counterproductive rather than merely costly:
- `IMPORTANT`, `CRITICAL`, capitals, piled-on bold. A plain line is followed;
  emphasis mostly causes the rule to be over-applied.
- "The context window is the main constraint." Windows are large and compaction
  is automatic; small context is about cost and focus.
- "Keep going", "loop until done", "don't be lazy". Produces over-work more often
  than it rescues a stall.
Fix: strip the emphasis, keep the sentence. A rule that can never bend is
`RULE_NEEDS_ENFORCEMENT` instead. One that keeps being missed suggests the file
is too long.

## RULE_NEEDS_ENFORCEMENT
A context file states something absolute — never commit to `main`, never touch
`migrations/`, never read `.env`, always typecheck — and relies on compliance. A
context file is guidance; Claude may judge that a guideline does not apply.
Fix: move it where the harness enforces it — a `PreToolUse` hook to block the
action, a `permissions.deny` rule for a path (deny holds in every permission
mode), a `Stop` hook for a check that must pass. Leave preferences in the context
file, and keep the enforced set small.

## SKILL_TOO_LONG
A `SKILL.md` body past 500 lines (note it past 300). After compaction an invoked
body returns capped at 5,000 tokens for that skill and 25,000 across all of them,
oldest dropped first.
Fix: move detail into `references/`, leaving one line saying when each is worth
reading. Deterministic procedures belong in a script, not in prose.

## SKILL_BODY_ORDER
A `SKILL.md` leaving refusals, safety limits and must-nots late in the body.
Truncation keeps the beginning of the file.
Fix: move what must survive to the top.

## SKILL_DESCRIPTION
A description missing, under ~50 characters, or over 1024. Always loaded, and the
only thing deciding whether the skill fires.
Fix: what the skill does, then the situations that should reach it, in the words
a user would type.

## MCP_INSTRUCTIONS_LARGE
A server declaring more than ~1,000 characters of instructions. Count is the
wrong metric: tool definitions are deferred, but every server's instructions and
tool names load at session start, instructions cut at 4,096 characters.
Measure in this order, and do not skip to the last:
1. Ask the user for `/context` and `/usage` — covers every server, including the
   stdio and authenticated ones nothing here can inspect, with real numbers.
2. Read the repo's `.mcp.json` — what the repo imposes on everyone who clones it,
   and the only part that is a finding about the repo.
3. Optionally, with the user's agreement, probe an HTTP server as
   `loading-model.md` describes. Never start a stdio server to measure it, and
   never send credentials.
Fix: shorter instructions from the server's author, or drop the server. A CLI
(`gh`, `aws`, `gcloud`) adds no per-tool listing at all. `/mcp` disables servers
that are configured but unused.

## LARGE_DIR_NOT_DENIED
A generated or vendored directory (`node_modules`, `build`, `dist`, `target`,
`.venv`, `generated`, `vendor`) that no `Read` deny rule covers.
Fix: check first that Claude has no reason to read it — a generated client it
must call correctly is a legitimate read. Deny rules go in
`.claude/settings.json` for everyone, `.claude/settings.local.json` for one
developer:

```json
{
  "permissions": {
    "deny": ["Read(./build/**)", "Read(./dist/**)", "Read(./node_modules/**)", "Read(./**/generated/**)"]
  }
}
```
