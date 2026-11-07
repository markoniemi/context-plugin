# Audit rules

One entry per thing that can be wrong with a project's context. Each gives the
condition to look for and what to do about it.

**Read selectively.** Find the entry for a condition you have actually observed;
do not read the file through. Report the code so the user can look the reasoning
up themselves.

Thresholds here are this skill's, not the runtime's, and are deliberately tighter
in places than the documented guidance — say which number you applied and why.
`loading-model.md` has the mechanics they rest on: what loads when, what survives
compaction, and the numbers the runtime itself enforces.

## NO_ROOT_FILE

No `CLAUDE.md` and no `AGENTS.md` at the repository root.

Stop. An audit measures what exists, and nothing does. Hand over to
`/context:setup`, which writes the files from scratch, and audit the result
afterwards.

## ROOT_TOO_LONG

A root `CLAUDE.md` or `AGENTS.md` longer than 80 lines (note it above 50).

The root file is the single most expensive file in the project: it is sent with
every request of every session, whatever the task. The documented target is 200
lines per file; 80 is the limit this skill argues for, on the grounds that a file
nobody has to pay for twice is worth more than a complete one.

Shrink it by relocation rather than deletion. Module-specific lines belong in
that module's own `CLAUDE.md`, which loads only when Claude works there. Topic
rules belong in `.claude/rules/` with `paths:` frontmatter. Long explanations
become a sentence naming the document that holds them. Generic advice goes.

Claude Code already warns about this at startup and in `/status`, including when
several individually-acceptable files add up past a combined limit. Read its
warnings before computing your own.

## MODULE_TOO_LONG

A `CLAUDE.md` in a subdirectory longer than 100 lines.

Cheaper than the root file, because it loads only when Claude touches that
subtree — so judge a genuinely large module against the documented 200 instead.

Keep what is specific to the module: its commands, its layout, its pitfalls. Move
anything reference-shaped — endpoint lists, schemas, step-by-step procedures —
into a document in the module and point at it in one line.

## UNSCOPED_RULE

A file in `.claude/rules/` with no `paths:` frontmatter, so it loads in every
session like the root file.

Add `paths:` globs when the rule only ever applies to part of the repository. A
short rule that genuinely applies everywhere can stay as it is; this is worth
noting, not fixing.

**State the trade-off rather than skipping it.** A path-scoped rule enters the
conversation when Claude touches a matching file, which means compaction
summarizes it away; an unscoped rule is re-injected from disk every time. So a
rule that must still hold after six hours of work is one you leave unscoped, or
move into the root file. Never recommend `paths:` for a rule that must not be
forgotten.

## AUTO_MEMORY_LARGE

`~/.claude/projects/<project>/memory/MEMORY.md` is long, stale, or wrong.

This is the always-loaded cost people miss, because it sits outside the
repository and Claude wrote it, so no reviewer has necessarily seen it. The first
200 lines or 25KB load at the start of every conversation and are re-injected
after compaction; the topic files beside it load only when read.

Anything past that threshold never loads at all and is dead weight — it belongs
in a topic file. Content that contradicts the current code is worse than content
that is merely long, because it is an instruction.

Report what you find; do not edit another project's memory during an audit.
`/memory` browses and edits it, and turns it off, as do `autoMemoryEnabled` and
`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.

## EAGER_IMPORT

An `@path` import whose target runs past ~50 lines.

An import is not a reference; the target is spliced into the importing file every
time that file loads. `@README.md` in a root file means the whole README is
charged to every session.

Reserve imports for small files every session needs — `@AGENTS.md` is the usual
one. For everything else write a sentence a human would write: name the file and
the situation that calls for it. Splitting one long file into several imports
tidies it without making it cheaper.

## IMPORT_MISSING

An `@path` whose target does not exist.

It fails quietly: no error, no content, and a line of instruction that reads as
though it worked. Correct the path or delete the line.

## DEAD_INSTRUCTION

A line that cannot have an effect, so whatever it costs is wasted. Five kinds:

- **A pointer dressed as an instruction** — "see `AGENTS.md` for our
  conventions". Claude reads that file only if it independently decides to.
  Make it an import if every session needs it; otherwise accept that it is a
  note to humans.
- **An external import that was declined.** An `@path` resolving outside the
  working directory needs one-time approval. Decline it and the import stays
  disabled permanently, without asking again.
- **An import inside backticks or a fenced block.** Import parsing skips both,
  so the line is literal text.
- **An import with unescaped spaces.** The path stops at the first space. Quoting
  it does not help — a quoted path is not imported at all.
- **An import more than four hops deep.** Four is the limit.

## DUPLICATE_CONTENT

The same line present in two or more context files that can load together, so it
is charged twice.

Keep it in the most specific file that needs it and delete the rest: the root
file if it is genuinely repository-wide, the module file otherwise. A deliberate
`AGENTS.md` / `CLAUDE.md` pair is the exception — see below.

## AGENTS_CLAUDE_DUPLICATE

An `AGENTS.md` and a `CLAUDE.md` side by side with overlapping content.

Pick one home for the shared text. Recent Claude Code reads `AGENTS.md`
directly, so often no `CLAUDE.md` is needed at all; where one is, reduce it to
`@AGENTS.md` plus whatever is Claude-specific. Copying between them guarantees
they drift.

## GENERIC_ADVICE

Instructions Claude would follow without being told: write clean code, handle
errors properly, use meaningful names, restatements of a language's own
conventions, explanations of well-known frameworks.

Delete, or replace with the specific non-obvious rule the author actually had in
mind. A line earns its place by changing behaviour — an exact command, a
convention that differs from the default, a "never do X here, because Y", a map
of where things live.

## OUTDATED_EMPHASIS

Advice shaped for older models, which now works against the project rather than
merely costing tokens. Three forms:

- **Emphasis stacking** — `IMPORTANT`, `CRITICAL`, capitals, piled-on bold on a
  line Claude keeps missing. A plainly worded line is followed; the emphasis
  mostly causes the rule to be applied where it does not belong.
- **"The context window is the main constraint."** Windows are large and
  compaction is automatic. Keeping context small is about cost and focus now, not
  about running out of room.
- **"Keep going", "loop until done", "don't be lazy".** These produce over-work
  more often than they rescue a stalled task.

Strip the emphasis and keep the sentence. If the line is one that can never bend,
it is `RULE_NEEDS_ENFORCEMENT` instead. If it keeps being missed, suspect the
length of the file it lives in.

## RULE_NEEDS_ENFORCEMENT

A context file states something absolute — never commit to `main`, never touch
`migrations/`, never read `.env`, always run the typecheck — and trusts Claude to
comply.

A context file is guidance, and Claude is permitted to judge that a guideline
does not apply here. Anything that must hold regardless belongs where the harness
enforces it: a `PreToolUse` hook to block the action, a `permissions.deny` rule
for a path (deny holds in every permission mode), a `Stop` hook for a check that
must pass before a turn can end.

Leave genuine preferences in the context file, and keep the enforced set small —
every hook and deny rule eventually fires when it should not, and each one needs
maintaining. A project with dozens of them has mostly encoded preferences.

## SKILL_TOO_LONG

A `SKILL.md` body past 500 lines (note it past 300).

The whole body enters context when the skill fires. There is a harder limit than
taste, though: after compaction an invoked body comes back capped at 5,000 tokens
for that skill and 25,000 across all of them, oldest dropped first.

Move detail into `references/` and leave one line in the body saying when each
file is worth reading. Deterministic procedures are better as a script than as
prose.

## SKILL_BODY_ORDER

A `SKILL.md` that leaves its most important instructions — refusals, safety
limits, the things it must not do — until late in the body.

Truncation keeps the beginning of the file, so the end is the first thing to
disappear in any session that compacts. Put what must survive at the top.

## SKILL_DESCRIPTION

A skill description that is missing, under ~50 characters, or over 1024.

The description is always loaded and is the only thing deciding whether the skill
fires. Too short and it never triggers; too long and every session pays for it.
Write what the skill does, then the situations that should reach it, in the words
a user would actually type.

## MCP_INSTRUCTIONS_LARGE

A configured MCP server declaring more than ~1,000 characters of instructions.

Server count is the wrong thing to count. Tool definitions are deferred until
Claude needs one, but every server's instructions and tool names load at session
start, with instructions cut at 4,096 characters. One verbose server therefore
costs more than several terse ones.

Measure in this order, and do not skip to the last:

1. **Ask the user for `/context` and `/usage`.** That covers every server,
   including the stdio and authenticated ones nothing here can inspect, with
   real numbers from a real session.
2. **Read the repository's `.mcp.json`.** This is what the repository imposes on
   everyone who clones it, and the only part that is a finding about the
   repository at all — a developer's own global servers are their configuration,
   not this project's problem.
3. **Optionally, with the user's agreement, probe an HTTP server** as
   `loading-model.md` describes. Never start a stdio server to measure it, and
   never send credentials.

To fix: ask the server's author for shorter instructions, or drop the server. A
CLI like `gh`, `aws` or `gcloud` adds no per-tool listing at all and is the better
choice for anything a shell can do. `/mcp` turns off servers that are configured
but unused.

## LARGE_DIR_NOT_DENIED

A generated or vendored directory — `node_modules`, `build`, `dist`, `target`,
`.venv`, `generated`, `vendor` — that no `Read` deny rule covers.

Worth noting rather than insisting on: check first that Claude has no reason to
read those files. A generated API client it has to call correctly is a legitimate
read, and denying it costs correctness to save tokens.

Deny rules go in `.claude/settings.json` to apply to everyone, or
`.claude/settings.local.json` to apply to one developer:

```json
{
  "permissions": {
    "deny": ["Read(./build/**)", "Read(./dist/**)", "Read(./node_modules/**)", "Read(./**/generated/**)"]
  }
}
```
