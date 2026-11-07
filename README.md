# context

A Claude Code plugin for keeping an agent's context small.

Every line in an always-loaded file is paid for on every single request. A root
`CLAUDE.md` that has grown into a manual, a skill body carrying its own reference
manual, an MCP server whose tool definitions nobody uses, instructions that
invite a whole-repository build for a one-file change — all of it is billed
again and again. This plugin organizes the context so that detail loads only
when it is needed, and reports what is costing tokens when it already has not.

## Commands

The two skills split by what they do, not by what they look at: one **writes**,
the other **measures**.

| Command | What it does |
| :- | :- |
| `/context:setup` | Writes the context files: a small root `CLAUDE.md`, one memory file per module that needs it, and `.claude/rules` with `paths:` frontmatter. Maps the repo, collects the per-module commands, and asks you for the pitfalls it cannot infer. |
| `/context:audit` | Measures what the existing context costs — context files, docs, skills, MCP servers, build scope, exploration habits, build output, caching, subagents — and reports a prioritized fix plan. Changes nothing until you say so. |

Reach for `/context:setup` when the files do not exist yet or need rewriting, and
`/context:audit` when the question is "why is this so expensive?". The audit ends
by offering to apply its own recommendations, so it covers diagnosis through to
the fix; setup does no auditing at all.

Both skills also trigger without the slash command when a request matches their
description — "set up CLAUDE.md for this repo" reaches setup, "my CLAUDE.md is a
mess" or "Claude Code is burning tokens" reaches audit.

## Relation to Anthropic's own tooling

Anthropic ships a `context-setup` skill covering the same ground as one skill
with a setup mode and an audit mode, and this plugin's per-file audit rules
closely match its `references/audit-rules.md`. Claude Code also has built-in
commands that measure what an audit would otherwise estimate: `/context`,
`/usage` and `/doctor prompt-audit`. Both skills here now defer to those rather
than guessing.

What this plugin adds over them: build scope and module targeting, build and test
output, repository exploration discipline, documentation structure, and two
skills that cannot be confused with each other instead of one guessing a mode
from the request. [docs/prior-art.md](docs/prior-art.md) has the file-by-file
comparison and the full list of what the official docs changed about these rules.

## Install

```
/plugin marketplace add markoniemi/context-plugin
/plugin install context@context-plugin
```

## Layout

```
.claude-plugin/
  plugin.json          the plugin manifest
  marketplace.json     the single-plugin marketplace
skills/
  setup/
    SKILL.md
    references/
      templates.md        root and module memory file templates
  audit/
    SKILL.md
    references/
      audit-rules.md      per-file thresholds and their fixes
      loading-model.md    what loads when, and what it costs
      maven-output.md     diagnosing noisy Maven builds
      report-template.md  the audit report's shape
scripts/check.sh       the free checks; check.ps1 is the same for Windows
docs/token-budget.md   what the plugin costs a session that never uses it
docs/prior-art.md      Anthropic's own tooling, and the gaps against its docs
docs/tasks/            this repository's own backlog
```

The plugin follows its own advice: each `SKILL.md` holds the workflow, and the
long material sits in `references/`, which loads only when a skill reads it.

## Tests

```
scripts/check.sh          # or .\scripts\check.ps1 on Windows
```

Three checks, all free — no credential, no model calls, no cost:

| Check | What it catches |
| :- | :- |
| `claude plugin validate . --strict` | a manifest or skill that will not load. This is not hypothetical: one of these skills once shipped with its frontmatter on a single unfenced line, which made it invisible to Claude Code. Blocking. |
| `claude plugin validate . --profile directory` | what the plugin directory would refuse on submission. Informational — the one open warning is `ICON_MISSING`, explained in [docs/token-budget.md](docs/token-budget.md). |
| always-loaded budget | a skill description growing silently. Blocking above 1200 bytes; currently 1105. |

The same script runs in CI on every push and pull request.

**What is not tested:** which skill fires for a given request. `validate` reads
the descriptions; it does not exercise them. Checking that "my CLAUDE.md is a
mess" reaches `audit` rather than `setup` needs `claude plugin eval`, which spends
real money per run — tracked as the `trigger evals` entry in the backlog.

## License

MIT. See [LICENSE](LICENSE).
