# Audit rules

Each section is a check to run by hand during an audit. Read only the sections whose condition you actually see.

For how context actually loads, what survives compaction, and the numbers behind these thresholds, see `loading-model.md`.

## ROOT_TOO_LONG
Root CLAUDE.md/AGENTS.md is over the line limit (warn > 80, info > 50). It loads in every session.
Fix: move module-specific content into that module's CLAUDE.md; move topic rules into path-scoped `.claude/rules/`; replace long explanations with a pointer to a doc; delete generic advice.
Note the documented target is **under 200 lines per file**; 80 is this skill's stricter house limit, on the grounds that a root file is paid for on every request of every session. Say which number you are applying. Claude Code already warns at startup and in `/status` when a file passes the recommended length, and again when files individually under it exceed a combined limit — read those warnings instead of recomputing them.

## MODULE_TOO_LONG
A nested CLAUDE.md is over 100 lines. It loads whenever Claude touches that module.
Fix: keep commands, layout and pitfalls; move reference material (API lists, schemas, long how-tos) into a doc in the module and point to it.
A module file is cheaper than the root file because it loads only for its subtree, so judge it against the documented 200 rather than the root's 80 when the module is genuinely large.

## EAGER_IMPORT
An `@path` import pulls a large file (> 50 lines) into context whenever the importing file loads.
Fix: replace `@docs/x.md` with a plain sentence: "See docs/x.md when <situation>." Keep `@imports` only for small files that are needed in every session (e.g. `@AGENTS.md`).

## IMPORT_MISSING
An `@path` import points to a file that doesn't exist. It is silently useless.
Fix: correct the path or remove the line.

## UNSCOPED_RULE
A `.claude/rules/*.md` file has no `paths:` frontmatter, so it loads in every session.
Fix: if it applies only to part of the repo, add `paths:` globs. If it truly applies everywhere and is short, leave it — this is info only.
**Trade-off, state it rather than skipping it:** a path-scoped rule loads into message history when Claude touches a matching file, so compaction summarizes it away; an unscoped rule is re-injected from disk after every compaction. A rule that must survive a long session therefore belongs unscoped, or in the root file. Do not recommend `paths:` for a rule that must never be forgotten.

## DUPLICATE_CONTENT
The same line appears in more than one context file, so it is paid for twice when both load.
Fix: keep it in the most specific file that needs it (root if repo-wide, module file otherwise) and delete the others. Exception: a deliberate `AGENTS.md`/`CLAUDE.md` pair — use an import instead of copying.

## AGENTS_CLAUDE_DUPLICATE
Both AGENTS.md and CLAUDE.md exist at the same level with overlapping content.
Fix: make CLAUDE.md `@AGENTS.md` plus Claude-only notes.

## SKILL_TOO_LONG
A SKILL.md body is over 500 lines (warn) or 300 (info). The whole body loads when the skill triggers.
Fix: move detail into `references/` files and add a line in SKILL.md saying when to read each one.
There is a harder reason than size: after compaction an invoked skill body is re-injected **capped at 5,000 tokens per skill and 25,000 tokens in total**, oldest dropped first, and truncation keeps the *start* of the file. So a long body silently loses its tail in any session that compacts.

## SKILL_BODY_ORDER
A SKILL.md puts its most important instructions — the refusals, the safety limits, the "do not" rules — late in the body.
Fix: move them to the top. Truncation after compaction keeps the start of the file, so anything near the end is the first thing Claude stops seeing.

## SKILL_DESCRIPTION
A skill's description is missing, very short (< 50 chars, will undertrigger), or long (> 1024 chars, always-loaded cost).
Fix: one or two sentences on what it does plus concrete trigger situations.

## GENERIC_ADVICE
Lines that look like advice Claude follows anyway ("write clean code", "follow best practices", "handle errors appropriately").
Fix: delete them, or replace with the specific, non-obvious rule the author actually meant.

## LARGE_DIR_NOT_DENIED
A large generated/vendored directory (node_modules, build, dist, target, .venv, generated, vendor) exists and is not in a `permissions.deny` Read rule.
Fix: suggest deny rules in `.claude/settings.json` (shared) or `.claude/settings.local.json` (personal), after checking Claude doesn't need to read those files — a generated API client it must call correctly is a legitimate read. Info only.

```json
{
  "permissions": {
    "deny": ["Read(./build/**)", "Read(./dist/**)", "Read(./node_modules/**)", "Read(./**/generated/**)"]
  }
}
```

## NO_ROOT_FILE
No CLAUDE.md or AGENTS.md at the repo root.
Fix: there is nothing to audit. Run `/context:setup` to write one, then audit the result.

## OUTDATED_EMPHASIS
Instructions written for older models. Three forms, all of them now counterproductive rather than merely wasteful:
- `IMPORTANT`, `CRITICAL`, `ALL CAPS`, bold stacking on a line Claude keeps missing. Current models follow a plainly worded line, and piling on emphasis makes Claude *over*-apply the rule.
- Advice to treat the context window as the main constraint. Most current models have a 1M-token window and compaction is automatic; the reason to keep context small is cost and focus, not capacity.
- "Keep going", "loop until done", "don't be lazy", "don't stop". More likely to cause over-work than to fix a stall.
Fix: delete the emphasis and keep the plain sentence. If the line is one that can never bend, it is a `RULE_NEEDS_ENFORCEMENT` finding instead. If it keeps getting missed, the file is probably too long.

## RULE_NEEDS_ENFORCEMENT
A context file states a rule that must never bend — never commit to `main`, never touch `migrations/`, never read `.env`, always run the typecheck — and relies on Claude choosing to obey it.
Fix: a context file is guidance, not configuration; Claude is allowed to decide a guideline doesn't apply. Move the absolute rules out: a `PreToolUse` hook to block an action, a `permissions.deny` rule for a path (deny holds in every permission mode), a `Stop` hook for a check that must pass. Keep preferences in the context file. Keep the enforced set small — a project with dozens of hooks has mostly encoded preferences.

## AUTO_MEMORY_LARGE
Auto memory is a second always-loaded mechanism, easy to miss because it lives outside the repo: the first 200 lines or 25KB of `~/.claude/projects/<project>/memory/MEMORY.md`, whichever comes first, loads at the start of every conversation and is re-injected from disk after compaction. Topic files beside it load on demand.
Check: does `MEMORY.md` exist, how long is it, and does it still describe the project accurately? It is written by Claude, so nobody has necessarily reviewed it.
Fix: content past the threshold is never loaded and is dead weight on disk — move it into topic files. Stale or wrong entries are worse than long ones, because they are instructions. Report it; do not edit another project's memory during an audit. `/memory` browses and edits it; the toggle there, `autoMemoryEnabled`, or `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` turns it off.

## DEAD_INSTRUCTION
An instruction that cannot do anything, so its cost buys nothing:
- A sentence telling Claude in words to read another file ("see `AGENTS.md` for conventions"). Claude sees that file only if it decides to open it. Use an `@import` for something every session needs, or accept that it is a pointer, not an instruction.
- An `@path` whose target is outside the working directory. These need a one-time approval; if it was declined, the import stays **silently** disabled and never prompts again.
- An `@path` in backticks or a code fence — import parsing skips both, so it is literal text.
- An `@path` with unescaped spaces. The path ends at the first space; a quoted path is not imported at all.
- Imports nested more than four hops deep.
Fix: convert to a real import, fix the path, or delete the line.

## MCP_INSTRUCTIONS_LARGE
A configured MCP server declares long `instructions`. With tool search on, tool *definitions* are deferred, but **tool names and server instructions still load at session start**, cut at 4,096 characters, so instructions are the always-loaded MCP cost — not the number of servers. Warn above 1,000 characters for one server.
Measure in this order; do not skip to the last one:
1. Have the user run `/context` and read the MCP line, and `/usage` for the share attributed to each server. This covers every server, including stdio and authenticated ones, with real numbers from a real session. Nothing this skill can compute beats it.
2. Read the repo's `.mcp.json`. That is what the repo imposes on everyone who clones it, and the only part that is a finding *about the repo*; a user's own global servers are personal configuration.
3. Optionally, with the user's agreement, probe an HTTP server as `loading-model.md` describes. Never spawn a stdio server to measure it, and never send credentials.
Fix: ask the server's author to shorten its instructions, or drop the server. Prefer a CLI (`gh`, `aws`, `gcloud`, `sentry-cli`) over a server that wraps shell work, because a CLI adds no per-tool listing at all. `/mcp` disables servers that are configured but unused.
