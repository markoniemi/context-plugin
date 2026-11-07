# Prior art and gaps

What else covers this ground, and what this plugin gets wrong or misses against
it. Researched 2026-11-07.

Two sources matter. Everything else is noise.

1. **Anthropic's `context-setup` skill** — this plugin's ancestor.
2. **The Claude Code documentation** — the authority on how context actually
   loads, and it has moved since these rules were written.

Third-party blog posts were surveyed and added nothing: their themes were a
strict subset of the documentation, plus two secondhand figures ("80% less system
prompt", "84% from context editing" — the second is about API context editing,
not Claude Code) that no primary source backs. They are not cited below.

## 1. The upstream skill

**Confirmed by the author 2026-11-07: this plugin started from this skill**, and
the direction of copying is measurable rather than inferred.

This repository's first `skills/setup/SKILL.md` (commit `08907be`) is upstream's
`context-setup/SKILL.md` with **8 insertions and 14 deletions**, and every one of
those changes removes the Python script:

| upstream | this repo's first version |
| :- | :- |
| `name: "context-setup"` | `name: setup` |
| "run the audit script first" | "inventory the context files first" |
| three steps invoking `python3 <skill-dir>/scripts/audit_context.py` | three steps doing the same counting by hand |
| "rerun the script to confirm" | "recount to confirm" |
| "The script's thresholds are heuristics" | "The thresholds are heuristics" |

Everything else is byte-identical. That asymmetry fixes the direction:
de-scripting a scripted skill takes those five edits, while the reverse would
mean writing a working 10KB script and rewriting the prose to call it.

Two further checks rule out the alternative that the synced skill is simply an
earlier release of this plugin: no commit on any branch ever added
`audit_context.py` or anything named `context-setup`, and the plugin cache holds
exactly one version, `0.1.0` from 2026-11-06. The upstream files are stamped
2026-11-01; this repository's first commit is 2026-11-06.

`anthropic-skills:context-setup` ships in the synced skill set beside `docx`,
`pdf`, `pptx`, `xlsx` and `skill-creator`:

```
~/.claude/skills/synced/<id>/context-setup/
  SKILL.md                    4936 bytes
  references/audit-rules.md   2988 bytes
  references/templates.md     3232 bytes
  scripts/audit_context.py   10385 bytes
```

It is a skill, not a plugin: no `.claude-plugin/`, no marketplace entry, no
per-mode command. One name, and the mode is picked from the request.

| | upstream | this plugin |
| :- | :- | :- |
| shape | one skill, `Setup` / `Audit` modes | two skills, `/context:setup` and `/context:audit` |
| `references/audit-rules.md` | yes | yes — same filename |
| `references/templates.md` | yes | yes — same filename |
| measurement | `scripts/audit_context.py`, stdlib only, `--json` | none; the rules are prose |
| audit scope | context files | context files plus eight more areas |

**`skills/audit/references/audit-rules.md` is upstream's file, near-verbatim** —
the same twelve finding codes in the same order with the same thresholds, and the
same Fix wording in most sections. Four deltas, all ours: the header sentence,
`SKILL_TOO_LONG` dropping the "move deterministic procedures into `scripts/`"
clause, `LARGE_DIR_NOT_DENIED` inlining the deny JSON, and `NO_ROOT_FILE`
pointing at `/context:setup`.

The twelve codes:

`NO_ROOT_FILE` · `ROOT_TOO_LONG` · `MODULE_TOO_LONG` · `UNSCOPED_RULE` ·
`EAGER_IMPORT` · `IMPORT_MISSING` · `DUPLICATE_CONTENT` ·
`AGENTS_CLAUDE_DUPLICATE` · `SKILL_TOO_LONG` · `SKILL_DESCRIPTION` ·
`GENERIC_ADVICE` · `LARGE_DIR_NOT_DENIED`

**Where this plugin is genuinely wider.** Upstream's audit stops at context
files. Sections 3 and 5–9 of `skills/audit/SKILL.md` have no upstream
counterpart: documentation structure, MCP overhead, build scope and module
targeting, repository exploration, build and test output (including
`references/maven-output.md`), and session habits. None of that is in
`context-setup`.

Net: upstream's context-file audit with the script removed and six areas added.

### Unresolved: who holds the copyright

Derivation is settled; **the licence is not**, and this matters before a public
push because `audit-rules.md` is close to verbatim.

What the evidence on this machine says:

* The skill is surfaced as `anthropic-skills:context-setup`, in the synced skill
  set, which is why it reads as first-party.
* But its entry in that set's `manifest.json` records `source: plugin`, where
  `pdf`, `docx`, `pptx` and `xlsx` record `source: anthropic` and `docs`,
  `morning`, `skill-creator`, `google-workspace` and `import-memory` record
  `source: anthropic-example`. `context-setup` is the only one of the ten with
  `source: plugin`.
* Those `source: anthropic` siblings each carry an Apache 2.0 `LICENSE.txt`.
  **`context-setup` carries no licence file at all.**
* A web search for a `context-setup` skill or an `audit_context.py` in
  `anthropics/skills` found neither.
* No `anthropic-skills` plugin appears in `claude plugin list`, so the namespace
  is the synced set rather than an installed plugin whose source could be read.

So "Anthropic's skill" is a reasonable reading of where it is served from, but it
is not established from anything checkable here, and no licence grants
redistribution of its text. The README therefore credits the skill by the name it
is distributed under and does not assert who wrote it.

Two conclusions that do **not** follow, and should not be drawn from the above:

* **That the skill does not exist or is not first-party.** It is on disk, dated
  2026-11-01, served in the same namespace as `pdf`, `docx` and `skill-creator`.
  One web search failing to find it in `anthropics/skills` is weak evidence; that
  may not be where it is published.
* **That `source: plugin` identifies an author.** It most plausibly records how
  the skill entered the account — through some plugin rather than the curated
  first-party set — which says nothing about who wrote it. Unconfirmed either
  way from this machine.

#### What has been done about it

`skills/audit/references/audit-rules.md` was **rewritten from scratch in original
wording on 2026-11-07**, from the documented mechanics rather than from
upstream's text. Measured afterwards: of 26 substantive lines upstream and 150
in the rewrite, exactly one is identical — the heading `## AGENTS_CLAUDE_DUPLICATE`.

The finding-code identifiers were deliberately kept. They are short functional
labels, they have to keep matching `loading-model.md`, `audit/SKILL.md` and this
document, and they are what upstream's script emits, so keeping them is what
makes the `port the audit script` entry possible at all.

**Still outstanding: `skills/setup/references/templates.md` is a complete copy** —
all 39 of its substantive lines are identical to upstream's file of the same
name. It is the larger exposure of the two and has not been touched.

Beyond that, in increasing order of effort: check the skill's entry in `/plugin`
or the claude.ai skills UI for an author and licence; look for the
`context-setup` skill in a public Anthropic repository; or rewrite
`templates.md` too, which is the only route that does not depend on an answer
from anyone.

## 2. Against the Claude Code documentation

This is where the real findings are. Three of our rules are wrong, not merely
incomplete.

### Wrong

| Where | Our claim | What the docs say |
| :- | :- | :- |
| `SKILL.md` §5 | "Tool definitions are paid for on every request." | MCP tool definitions are **deferred by default**; only tool names and server instructions enter context until Claude uses a specific tool. Our case for dropping MCP servers rests on a cost that no longer applies at full size. See "What MCP still costs" below. |
| `audit-rules.md` `UNSCOPED_RULE` | unscoped rule → add `paths:` | Path-scoped rules are summarized away by compaction: "If a rule must persist across compaction, drop the `paths:` frontmatter or move it to the project-root CLAUDE.md." Blanket `paths:` advice can silently lose a rule in a long session. |
| `audit-rules.md` thresholds | root warn > 80, info > 50; module > 100 | "**Size**: target under 200 lines per CLAUDE.md file." Claude Code already warns at startup and in `/status` when a file exceeds the recommended length, and again when files individually within it exceed a combined limit. Ours are stricter than the vendor's and presented as though authoritative. |

### What MCP still costs

The §5 correction is not "MCP is free". The docs are explicit that **"adding more
MCP servers has minimal impact on your context window"** and that "Claude Code
doesn't impose a fixed per-server tool cap; the practical limit is your context
window budget." Server *count* is therefore the wrong metric. Four things are the
right ones, and an audit should check these instead:

1. **Server instructions load at session start**, per server, cut at **4,096
   characters**. A tool description that loads upfront has the same limit; one
   loaded through tool search gets 16,384. So a handful of chatty servers is a
   real always-loaded cost even with deferral on, while a dozen terse ones are
   not. Measure the instructions, not the servers.
2. **Tool names load at session start** — all of them. Cheap per tool, not free
   in bulk.
3. **Deferral is not always active.** Claude Code loads every MCP tool upfront
   when: the model is earlier than Opus 4 / Sonnet 4; the session runs on an
   earlier Agent Platform model on Google Cloud; the deployment is Microsoft
   Foundry hosted on Azure, which rejects tool search server-side and cannot be
   overridden; `ENABLE_TOOL_SEARCH=false`; or a tool or server is exempted with
   `anthropic/alwaysLoad` in `_meta` or `alwaysLoad` in the configuration. On any
   of those, the old full-schema cost is back in force. An audit has to establish
   the model and provider before judging MCP cost at all.
4. **Tool output is where MCP actually spends now.** Claude Code warns above
   **10,000 tokens** of output from one MCP tool, caps it at **25,000** by default
   (`MAX_MCP_OUTPUT_TOKENS`), and writes a text result over **50,000 characters**
   to a file instead of the conversation.

#### Can an audit detect a chatty server?

Yes, and exactly rather than by estimate — within limits. A server's `instructions`
come back from an unauthenticated JSON-RPC `initialize` call. Measured against the
`context7` server configured on this machine, 2026-11-07:

```
server      : Context7 4.5.0
instructions: 707 chars, 713 UTF-8 bytes, ~178 tokens
```

The text matched the session's system prompt verbatim, which confirms the
mechanism. For scale: this whole plugin costs 1105 bytes always-loaded, so one
server's instructions rivals it.

`claude mcp get <name>` does **not** help — it reports scope, transport and
connection status only, with no tool count and no instructions.

Three limits make probing partial, and they decide the design:

1. **stdio servers cannot be probed without running them.** A server configured
   as `npx @playwright/mcp@latest` would have to be spawned, which the audit's
   own rules forbid ("don't install anything", "changes nothing").
2. **Authenticated HTTP servers return 401** without credentials, which an audit
   must not use.
3. A probe is an outward network call to a third party, so it needs consent.

So the measuring order is cheapest and broadest first:

| Tier | How | Covers | Cost |
| :- | :- | :- | :- |
| 1 | have the user run `/context` and read the MCP line; `/usage` for per-server attribution | everything, including stdio and authenticated servers, with real session numbers | free, no risk |
| 2 | read the repo's `.mcp.json` | what the repo imposes on everyone who clones it | free, in scope |
| 3 | `initialize` probe of HTTP servers | exact `instructions` size | network call, consent, partial |

Tier 1 is better than anything this plugin could build, and §5 currently does not
mention it. Tier 2 is the part that belongs in a *repository* audit at all: a
user's own global servers are personal configuration, not a finding about the
repo. Tier 3 belongs in a reference file as an option, not in the default
workflow.

Proposed finding code `MCP_INSTRUCTIONS_LARGE`: warn above 1,000 characters of
server instructions, noting the 4,096-character cut beyond which Claude sees
nothing.

Two of our existing instincts survive, with corrected reasons. "Prefer a CLI over
a server that wraps shell work" is still the documented advice — "Tools like
`gh`, `aws`, `gcloud`, and `sentry-cli` are still more context-efficient than MCP
servers because they don't add any per-tool listing" — and "disable unused
servers" is still there too, via `/mcp`. What dies is counting servers and
treating the number as the finding.

### Missing, high value

1. **Auto memory is absent entirely.** It is a second always-loaded mechanism:
   the first 200 lines or 25KB of `~/.claude/projects/<project>/memory/MEMORY.md`
   load at the start of every conversation, re-injected from disk after
   compaction; topic files load on demand. Our §2 startup-cost formula is wrong
   without it. Controls: the `/memory` toggle, `autoMemoryEnabled`,
   `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

2. **The product measures what we estimate.** §10 "Measurement" names no command.
   It should name four:

   * `/context` — live breakdown by category with optimization suggestions,
     including which CLAUDE.md and auto memory files loaded.
   * `/usage` — attributes recent usage to **skills, subagents, plugins and
     individual MCP servers**, flags long context and cache misses once either
     passes 10% of usage, and offers a `f` key that applies the fixes it can.
   * `/doctor prompt-audit` — audits CLAUDE.md, AGENTS.md and everything under
     `.claude/` for instructions written for older models, references to files
     that no longer exist, and files that contradict each other, proposing edits
     without applying them.
   * `/insights` — HTML report on working patterns and friction.

   An audit that does not start with `/context` and `/usage` is guessing where it
   could be reading measured attribution.

3. **CLAUDE.md is not enforcement.** "Claude treats them as context, not enforced
   configuration. To block an action regardless of what Claude decides, use a
   PreToolUse hook instead." Also: stacking emphasis on a line Claude keeps
   missing "is a sign the line belongs in a hook", and deny rules hold in every
   permission mode including auto and `bypassPermissions`. We say nothing about
   any of this, and "NEVER commit to main" in a CLAUDE.md is a top-frequency
   real-world pitfall.

4. **Advice written for older models.** The docs keep an explicit outdated-advice
   table. Three entries are things that appear in real context files:
   * `IMPORTANT` / ALL CAPS emphasis — "Current ones follow a plainly worded
     line, and piling on emphasis mostly makes Claude over-apply the rule."
   * "the context window is your main constraint, manage it aggressively" — most
     current models have a 1M window and compaction is automatic; the reason to
     `/clear` is focus and cost, not capacity.
   * "keep going, loop until done, don't be lazy" — "more likely to cause
     over-work than fix a stall."

5. **Compaction economics.** `/compact` reads the whole conversation to summarize
   it, so it is itself a large request; `/clear` costs nothing. A focus can be
   passed (`/compact keep the API changes`) or set permanently as a
   `# Compact instructions` section in CLAUDE.md. `/autocompact 500k` moves the
   automatic threshold. None of this is in §9.

6. **Skill bodies are truncated after compaction** — 5,000 tokens per skill,
   25,000 total, oldest dropped first, and truncation keeps the **start** of the
   file. So: put the most important instructions at the top of a `SKILL.md`.
   That is a concrete authoring rule, and it gives `SKILL_TOO_LONG` a real number
   instead of a line count.

7. **Hooks as a context tool.** A `PreToolUse` hook can filter output before
   Claude ever sees it — the docs' example turns a 10,000-line log into hundreds
   of tokens. Our §8 recommends redirect-then-grep written into each command by
   hand; a hook does it for every Bash call, automatically. Strictly better, and
   unmentioned.

8. **Subagents also *save* context.** Verbose work delegated to a subagent keeps
   the output in its window, returning only a summary. Our §9 treats subagents
   mainly as a cost risk. Both are true; we state one.

9. **Thinking is billed as output**, with a default budget that "can be tens of
   thousands of tokens per request". Levers: `/effort`, `/config`,
   `MAX_THINKING_TOKENS`. §9 mentions "reasoning effort" without the billing
   fact that makes it matter.

### Missing, worth a line at most

* Code intelligence plugins for typed languages — symbol navigation instead of
  grep-then-read-candidates.
* Agent teams use roughly 7× the tokens of a standard session in plan mode.
* Idle costs that are invisible by construction: session recap, idle compaction,
  prompt suggestions, session-scoped scheduled tasks, cross-session messages and
  goal check-ins all send the full context while nobody is typing.
* `claude -p --bare` skips hooks, skills, plugins, MCP servers and every
  CLAUDE.md — the right default for CI.
* Import mechanics we never mention: max four hops; a path with spaces needs
  backslashes; a quoted path is not imported at all; backticks prevent an import;
  an import resolving outside the working directory needs one-time approval and
  stays **silently disabled** if declined.
* `AGENTS.md` is read directly since v2.1.277, so the `@AGENTS.md` import is now
  often unnecessary — but a `CLAUDE.md` that tells Claude *in words* to read
  `AGENTS.md` is a dead instruction, and on Windows the symlink alternative
  checks out as a plain text file without `core.symlinks`.

## 3. What this means for the plugin's reason to exist

Harder to answer than it was. `/doctor prompt-audit` plus `/usage` attribution
plus `f to fix` is a built-in instruction-file audit with **measured** per-skill,
per-MCP-server attribution, where ours reads files and estimates.

What is still ours after that: build scope and module targeting, build and test
output, exploration discipline, and documentation structure. None of those are
touched by the built-in commands or by the upstream skill. That is a narrower
claim than the README currently makes, and an honest one.

## 4. Keeping it short while fixing this

The always-loaded budget is unaffected by almost all of the above, because only
`name` and `description` load on every request:

* `references/*.md` — free until read. **Put new rules here.**
* `SKILL.md` body — paid when the skill fires, and now subject to the 5,000-token
  truncation cap. Spend sparingly; one-line pointers to references.
* `description` — always loaded, against the 1200-byte ceiling in
  `scripts/check.sh`. Do not grow it.

The three wrong items are edits, not additions, so they cost nothing. Four new
finding codes (`OUTDATED_EMPHASIS`, `RULE_NEEDS_ENFORCEMENT`, `AUTO_MEMORY`,
`DEAD_INSTRUCTION`) belong in `audit-rules.md` at roughly four lines each, where
they are free until a condition matches. The loading and compaction facts belong
in one new reference file rather than in the body.
