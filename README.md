# context

A Claude Code plugin for keeping an agent's context small.

Every line in an always-loaded file is paid for on every single request. A root
`CLAUDE.md` that has grown into a manual, a skill body carrying its own reference
manual, an MCP server whose tool definitions nobody uses, instructions that
invite a whole-repository build for a one-file change — all of it is billed
again and again. This plugin organizes the context so that detail loads only
when it is needed, and reports what is costing tokens when it already has not.

## Commands

| Command | What it does |
| :- | :- |
| `/context:setup` | Sets up or restructures the context files: a small root `CLAUDE.md`, one memory file per module that needs it, `.claude/rules` with `paths:` frontmatter, and skills that load on demand. Writes files. |
| `/context:audit` | Audits the repository for avoidable token consumption — context files, docs, skills, MCP servers, build scope, exploration habits, build output, caching, subagents — and reports a prioritized plan. Writes nothing. |

`/context:setup` is the one to reach for when the structure is wrong or missing.
`/context:audit` is the one to reach for when the question is "why is this so
expensive?" — it ends by asking whether you want its recommendations applied.

Both skills also trigger on their own, without the slash command, when a request
matches their description: "my CLAUDE.md is a mess", "reduce token usage",
"Claude Code is burning tokens".

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
      templates.md     root and module memory file templates
      audit-rules.md   per-file thresholds and their fixes
  audit/
    SKILL.md
    references/
      maven-output.md     diagnosing noisy Maven builds
      report-template.md  the audit report's shape
docs/tasks/            this repository's own backlog
```

The plugin follows its own advice: each `SKILL.md` holds the workflow, and the
long material sits in `references/`, which loads only when a skill reads it.

## License

MIT. See [LICENSE](LICENSE).
