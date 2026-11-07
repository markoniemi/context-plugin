---
id: port-the-audit-script
status: done
priority: medium
---

# port the audit script

The `context-setup` skill this plugin started from measures context files with
`scripts/audit_context.py` — stdlib only, `--json` output, and the source of the
twelve finding codes this plugin inherited. This plugin dropped the script and
asks the model to check the same thresholds by reading instead.

Port it to `skills/audit/scripts/`, or record why prose-only is right.

# Decision

**Not porting it. Closed 2026-11-07 without writing code.** This file is the
decision record; the durable version lives in [../prior-art.md](../prior-art.md),
which outlives this directory.

## What the script actually does

245 lines, standard library only. It walks the repository past a skip-list and
classifies four kinds of file — root (`CLAUDE.md`, `AGENTS.md`,
`CLAUDE.local.md` at the root or in `.claude/`), module (the same names nested),
rule (`.claude/rules/*.md`) and skill (`SKILL.md`) — then counts lines, estimates
tokens at characters ÷ 4, and emits all twelve of the original finding codes.

Mechanically: line-count thresholds, frontmatter parsing for `paths:` and
`description`, an import regex that correctly skips fenced blocks and code spans,
seven regexes for generic advice, cross-file duplicate detection on normalised
lines of 30 characters or more, and a substring check of `permissions.deny`
against the large directories it found. Output is a markdown file table plus
sorted findings, or `--json`.

## Why not

1. **It covers twelve of this plugin's eighteen codes** — sections 1 and 2 of
   eleven. It never reads MCP configuration, build files, command output,
   exploration habits or auto memory. Every code added on 2026-11-07
   (`OUTDATED_EMPHASIS`, `RULE_NEEDS_ENFORCEMENT`, `AUTO_MEMORY_LARGE`,
   `DEAD_INSTRUCTION`, `SKILL_BODY_ORDER`, `MCP_INSTRUCTIONS_LARGE`) needs
   judgment a regex cannot apply.
2. **Two sources of truth for every threshold.** Upstream's own copy has already
   drifted: `MODULE_WARN = 100`, but the message it prints reads
   `target ≤ 60`. A port would drift from `audit-rules.md` the same way.
3. **Porting the code reopens the licensing question** that rewriting
   `audit-rules.md` just closed. The rewrite existed to stop depending on an
   answer nobody has; copying 245 lines of the same skill's Python would undo
   that for a larger file.
4. **The product now does this better.** `/context` reports real per-category
   token numbers where the script estimates characters ÷ 4, and
   `/doctor prompt-audit` audits instruction files for stale references and
   contradictions, which the script never attempted. Porting it now means
   shipping a worse `/context`. The script predates both.

## The Python question, answered concretely

There is no Python on the development machine, and in the worst available form.
Both `python` and `python3` resolve to the Microsoft Store stub at
`%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe`, so `Get-Command` and
`command -v python3` both report success; running it prints a Store install
prompt and exits 49. A ported script could not reliably detect its own
unavailability here, which makes "guard it behind a Python check" unsound as a
mitigation.

## What was kept from the idea

The want behind this entry was determinism. The cheaper form of it already
exists: the always-loaded budget check in `scripts/check.ps1` and
`scripts/check.sh`, which applies this plugin's own thresholds to this plugin's
own files with no interpreter and no second source of truth. Extending that is
the route to more determinism — not a general-purpose auditor.

One genuine loss, recorded so it is not rediscovered as a surprise: on a large
monorepo, an agent counting dozens of files by hand is slower and more prone to
slips than a script. `/context` gives the authoritative startup figure there for
free, so the loss is narrower than it appears.
