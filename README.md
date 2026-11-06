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
      maven-output.md     diagnosing noisy Maven builds
      report-template.md  the audit report's shape
docs/tasks/            this repository's own backlog
```

The plugin follows its own advice: each `SKILL.md` holds the workflow, and the
long material sits in `references/`, which loads only when a skill reads it.

## License

MIT. See [LICENSE](LICENSE).
