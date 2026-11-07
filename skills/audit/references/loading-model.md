# How context loads, and what it costs

The mechanics behind the thresholds in `audit-rules.md`. Read it when a finding
turns on *when* something loads, or when you need to defend a number. Verified
against the Claude Code documentation 2026-11-07; versions move, so prefer what
`/context` reports in the session over what this file says.

## What is loaded before the user types

* Root `CLAUDE.md`, and every `CLAUDE.md` in parent directories of the cwd.
  `AGENTS.md` can load in place of `CLAUDE.md`.
* `.claude/rules/*.md` **without** `paths:` frontmatter.
* Everything `@path` imports pull in, expanded into the importing file.
* **Auto memory** — the first 200 lines or 25KB of
  `~/.claude/projects/<project>/memory/MEMORY.md`. Easy to miss: it is outside
  the repo and written by Claude, not by the team.
* Skill `name` + `description` for every available skill. Bodies load on trigger;
  `references/` load only when read.
* **MCP tool names and server instructions** for every connected server.
* An output style, and anything passed with `--append-system-prompt`.

Loaded on demand, so not startup cost: `CLAUDE.md` in subdirectories (when Claude
reads files in that subtree), rules with `paths:`, skill bodies, reference files.

Startup estimate = the first group. Characters ÷ 4 for tokens. Do not quote a
number you did not measure.

## What survives compaction

| Mechanism | After compaction |
| :- | :- |
| Root `CLAUDE.md`, unscoped rules, auto memory | re-injected from disk |
| Skill descriptions | rebuilt and re-injected |
| Rules with `paths:`, nested `CLAUDE.md` | reloaded on demand only |
| Invoked skill bodies | re-injected, **capped at 5,000 tokens per skill and 25,000 total**, oldest dropped first, truncation keeping the start of the file |
| Files Claude read or edited | up to five re-read, most recently modified first; one over 5,000 tokens returns as a path reference without content |

Two consequences worth reporting. A path-scoped rule is summarized away, so
scoping a rule that must never be forgotten is the wrong fix. And a long
`SKILL.md` loses its tail, so the instructions that matter most belong at the
top.

Compaction economics: `/compact` reads the whole conversation in order to
summarize it, so on a large context it is itself a large request. `/clear` costs
nothing. A focus can be passed once (`/compact keep the API changes`) or set
permanently as a `# Compact instructions` section in `CLAUDE.md`.
`/autocompact 500k` moves the automatic threshold.

## MCP cost after tool search

Tool search is on by default and defers tool definitions, so **adding more
servers has little effect on the context window**. Server count is the wrong
metric. These are the right ones:

1. **Server instructions**, per server, at session start, cut at 4,096
   characters. The always-loaded MCP cost.
2. **Tool names**, all of them, at session start.
3. **Whether deferral is active at all.** Everything loads upfront when the model
   is earlier than Opus 4 / Sonnet 4, on earlier Agent Platform models on Google
   Cloud, on Microsoft Foundry deployments hosted on Azure (rejected server-side,
   not overridable), with `ENABLE_TOOL_SEARCH=false`, or for a tool or server
   exempted via `anthropic/alwaysLoad`. Establish the model and provider before
   judging MCP cost.
4. **Tool output.** Claude Code warns above 10,000 tokens from one call, caps at
   25,000 by default (`MAX_MCP_OUTPUT_TOKENS`), and writes a text result over
   50,000 characters to a file instead of the conversation.

### Measuring a server's instructions

`claude mcp get <name>` does not help — scope, transport and status only. The
value comes from the server's own `initialize` response, so for an HTTP server,
with the user's agreement:

```bash
curl -s https://example.com/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"audit","version":"1"}}}'
```

`result.instructions` is the text that lands in context. Measure its length.

Limits that make this partial, and are reasons to prefer `/context`: a stdio
server would have to be spawned to answer, which an audit must not do; an
authenticated server returns 401 without credentials, which an audit must not
use; and the probe is an outward network call, so ask first.

## What the product already measures

Start here. These report measured numbers where this skill would estimate.

| Command | What it gives |
| :- | :- |
| `/context` | live breakdown by category with optimization suggestions, including which `CLAUDE.md` and auto memory files loaded |
| `/usage` | usage attributed to individual skills, subagents, plugins and MCP servers; flags long context and cache misses once either passes 10%; `f` applies the fixes it can |
| `/doctor prompt-audit` | audits instruction files for advice written for older models, references to files that no longer exist, and files that contradict each other, proposing edits without applying them |
| `/memory` | lists and opens memory files; toggles auto memory |
| `/insights` | HTML report on working patterns and friction |
| `/mcp` | configured servers; disables unused ones |

An audit that has not looked at `/context` and `/usage` is estimating something
the user could have measured. Ask for their output rather than guessing, and say
which findings came from them.

## Guidance versus enforcement

A context file is guidance. Claude may decide a guideline does not apply. Rules
that must hold regardless belong elsewhere:

* `PreToolUse` hook — blocks an action before it runs.
* `permissions.deny` — holds in every permission mode, including auto and
  `bypassPermissions`.
* `Stop` hook — a check that must pass before a turn can end.

A hook that asks a model to decide (`prompt`, `agent`) is not deterministic
either; use `command` or `http` for real enforcement. Keep the enforced set
small: every hook and deny rule eventually fires when it should not, and someone
maintains each one.

## Other costs worth naming

* **Thinking is billed as output**, and the default budget can be tens of
  thousands of tokens per request. Levers: `/effort`, `/config`,
  `MAX_THINKING_TOKENS` on models with a fixed budget.
* **Subagents cut context as well as spending it.** Verbose work delegated to a
  subagent keeps the output in its window and returns a summary. That is the main
  legitimate reason to use one; parallelism alone is not.
* **Hooks can shrink output before Claude sees it.** A `PreToolUse` hook that
  rewrites a test command to filter failures turns a 10,000-line log into
  hundreds of tokens, for every call, without relying on anyone remembering.
* **Idle costs.** Session recap, idle compaction, prompt suggestions,
  session-scoped scheduled tasks, cross-session messages and goal check-ins each
  send the full context while nobody is typing.
* **Agent teams** use roughly 7× the tokens of a standard session in plan mode.
* **`claude -p --bare`** skips hooks, skills, plugins, MCP servers and every
  `CLAUDE.md` — usually the right default in CI.
* **Code intelligence plugins** for typed languages replace grep-then-read-
  candidates with symbol navigation.
