---
id: resolve-setup-and-audit-overlap
status: planned
priority: medium
---

# resolve setup and audit overlap

`skills/setup/SKILL.md` carries its own "Audit workflow" section, and its setup
workflow ends by telling the agent to run it. The `audit` skill now covers the
same ground in more depth, and both read `setup/references/audit-rules.md`.

Decide where the audit lives: setup keeps a short self-check and defers the real
audit to the `audit` skill, or the audit workflow moves out of setup entirely and
setup just points at `/context:audit`. Then move `audit-rules.md` to whichever
skill owns it, since a cross-skill reference is the thing to avoid.

# Implementation Plan

## The decision

**`audit` owns the audit. `setup` keeps a short inline self-check and nothing
else.**

Why not "setup defers entirely": a setup run that writes eight files and then
says "now run `/context:audit`" leaves the user holding a second step for
problems setup itself just created. A handful of checks against what it wrote is
part of writing it.

Why not "setup keeps its five-step audit workflow": that is the duplication.

So the split is by depth, and it decides the file move:

| | `setup` | `audit` |
| :- | :- | :- |
| Scope | the files it just wrote | the whole repo, plus docs, MCP, build scope, output, caching |
| Depth | 4 inline checks, no file read | the full rule set and a report |
| Owns `audit-rules.md` | no | yes |

`audit-rules.md` moves to `skills/audit/references/`. Setup's self-check is
inline and short enough to need no reference file, so **no cross-skill reference
remains in either direction** — which is the point.

## Steps

1. **Move the rules file.**
   `git mv skills/setup/references/audit-rules.md skills/audit/references/audit-rules.md`

2. **`skills/audit/SKILL.md` section 2** — the pointer currently reads "the
   `setup` skill's `references/audit-rules.md`". Change it to the local
   `references/audit-rules.md`.

3. **`skills/audit/references/audit-rules.md`** — two references point back out
   of the file and must be repointed now that it has moved:
   * `LARGE_DIR_NOT_DENIED` cites "Excluding paths" in `templates.md`, which
     stays in `skills/setup/references/`. Inline the deny-rule snippet here
     instead of citing a file in the other skill.
   * `NO_ROOT_FILE` says "switch to the Setup workflow" — make it name
     `/context:setup`.

4. **`skills/setup/SKILL.md`** — replace the whole `## Audit workflow` section
   (its five numbered steps) with a `## Self-check` section of four checks
   against the files just written:
   * root file ≤ 80 lines,
   * no `@import` of a file over ~50 lines, and no `@import` of a missing path,
   * every `.claude/rules/*.md` either has `paths:` frontmatter or is short,
   * no line that was copied verbatim into two files.

   Then one sentence: for anything deeper — docs, skills, MCP, build scope,
   command output, caching, subagents — run `/context:audit`.

   Setup workflow step 8 currently reads "Run the audit (below)"; point it at the
   self-check. Target: setup stays under 60 lines.

5. **`skills/setup/SKILL.md` frontmatter description.** It currently claims the
   audit as well ("Sets up **and audits**", "check whether existing context files
   have grown too large"). Both descriptions are always loaded and currently
   compete for the same request. Narrow setup's to creating and restructuring
   context files, and let `audit`'s description own "reduce token usage", "why is
   Claude Code expensive", "files have grown too large". Keep both under ~500
   characters.

   Also drop setup's "Pick the mode from the user's request / Setup vs Audit"
   paragraph near the top, which only exists because the skill had two modes.

6. **`README.md`** — the command table says setup "Sets up or restructures the
   context files". Add that it self-checks what it wrote, and that the deep audit
   is `/context:audit`. Update the layout tree: `audit-rules.md` moves under
   `skills/audit/references/`.

7. **Verify.**
   * `Grep` for `audit-rules`, `audit workflow`, `templates.md` and `Audit` across
     `skills/` and `README.md` — no reference may point into the other skill's
     directory, and no path may point at the old location.
   * Line counts: `setup/SKILL.md` ≤ 60, `audit/SKILL.md` unchanged at ~183.
   * Both descriptions still parse as frontmatter.

## Open questions for the human

1. **Is four self-checks the right size for setup?** The alternative is zero —
   setup writes files and says nothing about them. Say which you prefer.
2. **No tests**, as with the previous task: markdown and JSON, no harness. The
   real check is installing the plugin and seeing which skill fires for "my
   CLAUDE.md is a mess" (should be `setup`) versus "why is Claude Code so
   expensive" (should be `audit`). That is yours to run.
