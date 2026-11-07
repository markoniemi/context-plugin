---
id: other-related-plugins
status: done
priority: low
---

# other related plugins

- are there other related plugins, maybe from some real authority?
- is there some good best practices on how to reduce token usage?

# Implementation Plan

## What planning already found, because it changes the task

The authority plugin exists, it is Anthropic's, it is **already installed on this
machine**, and this plugin looks like a derivative of it.

`anthropic-skills:context-setup` ships in the synced Anthropic skill set beside
`docx`, `pdf`, `pptx`, `xlsx` and `skill-creator`:

```
~/.claude/skills/synced/9d41ad2a-.../context-setup/
  SKILL.md                    4936 bytes
  references/audit-rules.md   2988 bytes
  references/templates.md     3232 bytes
  scripts/audit_context.py   10385 bytes
```

Compare it with this repository:

| | upstream `context-setup` | this plugin |
| :- | :- | :- |
| shape | one skill, two modes picked from the request (`Setup` / `Audit`) | two skills, `/context:setup` and `/context:audit` |
| `references/audit-rules.md` | yes | yes — same filename |
| `references/templates.md` | yes | yes — same filename |
| measurement | `scripts/audit_context.py`, stdlib only, `--json` | none; the rules are prose in `audit/references/audit-rules.md` |
| loading rules | the same five bullets (startup files, subtree files, `@import` expansion, `paths:` frontmatter, name+description always loaded) | the same five |
| description | "…even if they just say \"my CLAUDE.md is a mess\" or \"Claude Code is burning tokens\"" | audit's description ends with the same two phrases |

Those last two rows are not convergence. The same two example phrases, the same
two reference filenames and the same opening line about every line being paid for
on every request mean this repository started from that skill.

Three consequences, and they are the task:

1. **Attribution.** If this is a derivative, the README and LICENSE say nothing
   about it. That is the kind of thing to fix before a first push, not after.
2. **A trigger collision that already exists.** In this environment three
   descriptions now compete for "my CLAUDE.md is a mess": `context-setup`,
   `/context:setup` and `/context:audit`. The `tests` task established that
   nothing in the repository can detect this — only `claude plugin eval` can, and
   that is the deferred `trigger evals` entry.
3. **A dropped capability.** Upstream measures with a Python script; this plugin
   asks the model to measure by reading rules. The script is deterministic, free
   and reusable. Dropping it is defensible — Python need not be on `PATH`, and
   `audit` covers far more ground than the script does — but it was never a
   decision, it was an omission.

## Steps

1. **Pin the provenance.** Diff this plugin's `audit/references/audit-rules.md`
   and `setup/references/templates.md` against upstream's, file by file, and
   record how much is shared text versus rewritten. Also read
   `scripts/audit_context.py` to see what it actually checks, since the finding
   codes in our `audit-rules.md` (`NO_ROOT_FILE`, `LARGE_DIR_NOT_DENIED`,
   `SKILL_DESCRIPTION`, …) are probably its codes.

2. **Answer the attribution question**, whichever way the human answers the first
   open question below. Derivative → a credit line in the README and whatever the
   upstream license requires. Independent → say so in the record, because the
   resemblance will be noticed by anyone who has both installed.

3. **Decide on the script.** Either port `audit_context.py` into
   `skills/audit/scripts/`, which would give the audit a deterministic,
   free, testable core and would let `scripts/check.sh` run it on this very
   repository as a real test; or record why prose-only is the right call. Not
   both, and not silence.

4. **Survey the rest, breadth-first, and keep it short.** Already on disk:
   `~/.claude/plugins/cache/claude-plugins-official/` holds `context7`,
   `playwright` and `superpowers` — none of them about context size, which is
   itself an answer. Then the published guidance: Anthropic's context-engineering
   and Claude Code best-practice material, plus whatever `claude plugin` surfaces
   from the official marketplace. Needs network.

5. **Answer question two against our own rules.** Take the published token-saving
   advice and mark each item: already covered by `audit`, missing, or
   contradicted. The missing ones become backlog entries; a contradiction is a
   bug in `audit-rules.md`.

6. **Write `docs/prior-art.md`** — the upstream, the diff summary, what this
   plugin keeps, drops and adds, and the collision from consequence 2. One page.
   This task's deliverable is that page plus whatever backlog entries step 5
   produces; it writes no skill code unless step 3 goes the porting way.

## Result

Done on `main`, no branch (`create_branch` is off). Research in
[../prior-art.md](../prior-art.md) — commits `d13478c`, `88ecc7d`, `0f0eec3` —
then the rule changes it called for.

**Answers to the open questions, from the human on 2026-11-07:** question 1, yes
— this plugin started from the `context-setup` skill, and the README's "Origin
and credit" section now says so plainly; question 2, it does more than that
skill, and the README says what; question 3, the script port is its own backlog
entry.

One thing the confirmation did **not** settle: who holds the copyright on the
upstream skill. It is served as `anthropic-skills:context-setup`, but its
manifest entry reads `source: plugin` where the first-party siblings read
`source: anthropic`, it is the only one of the ten with no `LICENSE.txt` beside
it, and it is not findable in a public Anthropic repository. So the credit names
the skill without asserting its author, and no licence is known to permit the
near-verbatim `audit-rules.md`. Recorded under "Unresolved: who holds the
copyright" in [../prior-art.md](../prior-art.md); it needs an answer before a
public push.

Three rules were wrong and are fixed:

* `audit/SKILL.md` §5 claimed "tool definitions are paid for on every request".
  Tool search defers them by default. The section is rewritten around what is
  actually paid — server instructions and tool names — and no longer treats
  server count as a finding.
* `UNSCOPED_RULE` recommended `paths:` unconditionally. A path-scoped rule is
  summarized away by compaction, so the trade-off is now stated.
* `ROOT_TOO_LONG` and `MODULE_TOO_LONG` presented 80 and 100 lines as though
  authoritative. The documented target is 200; ours are now labelled as a
  deliberately stricter house limit, with Claude Code's own startup and `/status`
  warnings named as the thing to read first.

Five finding codes added, all in `references/` where they cost nothing until a
condition matches: `SKILL_BODY_ORDER`, `OUTDATED_EMPHASIS`,
`RULE_NEEDS_ENFORCEMENT`, `AUTO_MEMORY_LARGE`, `DEAD_INSTRUCTION`,
`MCP_INSTRUCTIONS_LARGE`.

New `skills/audit/references/loading-model.md` — the startup set including auto
memory, what survives compaction and the 5,000/25,000-token skill body caps, MCP
cost after tool search with the conditions under which deferral is off, the
`initialize` probe for measuring a server's instructions, the built-in commands,
and guidance-versus-enforcement.

Both skills now defer to `/context`, `/usage` and `/doctor prompt-audit` instead
of estimating what those measure. §10 names them; §2 asks for `/context` output
before computing a startup figure.

`skills/setup/SKILL.md` gained the authoring side: imports don't reduce cost,
path-scoped rules don't survive compaction, auto memory counts in the startup
total, a context file is guidance not configuration, `AGENTS.md` is read directly
now (and never point at it in words), and three kinds of advice written for older
models not to write at all.

Verified: `scripts/check.ps1` exits 0 and the always-loaded budget is unchanged at
**1105 bytes**, because no description was touched. `audit/SKILL.md` grew from 184
to 234 lines, 12233 bytes ≈ 3058 tokens — under the 5,000-token per-skill
compaction cap it now documents, and under its own `SKILL_TOO_LONG` info
threshold of 300 lines.

Not done, by decision: porting `audit_context.py`, now the `port the audit script`
backlog entry.

## Open questions

1. **Did this repository start from Anthropic's `context-setup` skill?** You would
   know; the file evidence says yes but cannot say whether it was deliberate. The
   answer decides step 2 entirely, and it is the one question I cannot resolve by
   reading anything.

2. **Given that the official skill ships with Claude Code, what is this plugin
   for?** It needs one sentence, and it should go in the README. The honest
   candidates: two skills that cannot be confused with each other instead of one
   skill guessing a mode; an audit covering nine areas rather than context files
   alone; a packaged plugin installable in one line. That is a real answer — but
   if the answer is "nothing the official skill does not do", the finding belongs
   in the record rather than being worked around.

3. **Scope** — is step 3 (the script) in this task, or a backlog entry of its own?
   It is the only step that would write code, and it is the largest.

4. ~~**Network**~~ — **answered 2026-11-07: web access is already available.**
   `WebSearch` and `WebFetch` are session tools; nothing had to be configured. A
   live search confirmed it. Two findings from that one search, folded into the
   steps above:

   * A generic query returns twenty third-party SEO posts and no Anthropic page,
     several repeating secondhand numbers ("80% less system prompt", "84% from
     context editing" — the second is about API context editing, not Claude Code).
     Step 4 must filter to `anthropic.com` / `docs.claude.com` for the primary
     guidance and treat blog surveying as a separate, labelled pass.
   * Two candidate gaps for step 5, to check rather than assume: whether section
     10 "Measurement" names `/context` and `/usage`, and whether
     `ROOT_TOO_LONG`'s 80-line warning squares with the widely repeated claim that
     Anthropic recommends keeping CLAUDE.md under 200 lines. Our threshold was
     inherited from the upstream skill, so a primary source has to settle it.
