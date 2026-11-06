---
id: resolve-setup-and-audit-overlap
status: in_review
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

Decided 2026-11-06, after asking whether `setup` is needed at all: **two skills,
re-split as write versus measure.** `setup` authors context files and does no
auditing whatsoever; `audit` diagnoses, plans and — when asked — applies.

The question was fair, because `audit` already plans the fix: report section D is
a prioritized table, F is the per-file retain / shorten / move / remove list, K is
the implementation order, and the skill ends by offering to implement. For a repo
that *has* context files, `audit` covers the whole arc, and setup's "Audit
workflow" section is dead weight.

What survives is the one thing `audit` structurally cannot do: author from
nothing. Map the repo, find the per-module build and test commands, **ask the
human for the pitfalls** — the highest-value lines and the only ones not
inferable — and write the files from templates. With no root file there is
nothing to audit; `audit-rules.md` says as much in `NO_ROOT_FILE`.

| | `setup` | `audit` |
| :- | :- | :- |
| Precondition | no usable context files | context files exist |
| Input | repo structure plus the human's knowledge | the files themselves |
| Output | files on disk | a report, then files only if asked |
| Owns `audit-rules.md` | no | yes |

The rejected alternative was one merged `context` skill, which would halve the
always-loaded description cost — around 100-200 tokens on every request, which is
this plugin's own thesis turned on itself. Rejected because a single skill that
sometimes writes files and sometimes refuses to is harder to predict, and
`audit`'s "writes nothing unless you say so" guarantee is what makes it safe to
run on a repo you do not own. The command would also come out as
`/context:context` or need `commands/` wrappers. Worth revisiting if the
descriptions grow.

`audit-rules.md` moves to `skills/audit/references/`, and **no cross-skill
reference remains in either direction** — which is the point.

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

4. **`skills/setup/SKILL.md`** — delete the whole `## Audit workflow` section,
   all five steps. No self-check section replaces it: under B the skill does no
   auditing, and a four-item checklist would be the duplication in miniature.

   Instead, the limits live where the writing happens, as a spec for the output
   rather than a review of it — the write steps already say "target ≤ 50 lines,
   hard ceiling 80" and "target ≤ 60 lines", so keep those and add the same kind
   of inline constraint for imports (point to a doc rather than `@import` it
   unless the file is small and needed every session).

   Setup workflow step 8 currently reads "Run the audit (below)". Replace it with
   one sentence: for anything deeper than the files just written — docs, skills,
   MCP, build scope, command output, caching, subagents — run `/context:audit`.

   Target: setup drops from 54 to roughly 40 lines.

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
   * Line counts: `setup/SKILL.md` ≈ 40, `audit/SKILL.md` unchanged at ~183.
   * Both descriptions still parse as frontmatter.
   * No occurrence of "audit" left in `setup/SKILL.md` except the one sentence
     pointing at `/context:audit`.

## Result

Done on `main`, commit `6ce1acd` (no branch: `create_branch` is off).

* `audit-rules.md` moved to `skills/audit/references/`. Its two outward
  references repointed: the deny-rule snippet is now inline in
  `LARGE_DIR_NOT_DENIED`, and `NO_ROOT_FILE` names `/context:setup`.
* `skills/audit/SKILL.md` section 2 points at the local `references/audit-rules.md`;
  the "use the setup skill instead" line became the `NO_ROOT_FILE` case.
* `skills/setup/SKILL.md`: `## Audit workflow` deleted, the two-mode paragraph
  deleted, the import constraint added as write step 7, the threshold caveat kept
  next to the write steps, and a closing pointer to `/context:audit`. 54 → 41
  lines. "audit" now appears twice in the file: the description's deferral
  sentence and that pointer.
* Descriptions re-split: setup owns creating and restructuring, audit owns "why is
  this expensive", "my CLAUDE.md is a mess", "burning tokens".
* `README.md`: the command table now says write versus measure, and the layout
  tree shows `audit-rules.md` under the audit skill.

Verified: `Grep` for `audit-rules`, `templates.md` and `audit workflow` across
`skills/` and `README.md` shows no reference crossing between the two skills and
no path at the old location; both frontmatter blocks parse; setup is 41 lines,
audit 184.

Deviation: the audit description is 616 characters, not the planned ≤ 500. Left as
is — the plugin's own `SKILL_DESCRIPTION` rule warns above 1024, and the extra
phrasing is what makes audit win the "my CLAUDE.md is a mess" request instead of
setup.

No unit tests: markdown and JSON with no harness, same as the previous task. The
`tests` backlog entry covers it.

## Open questions for the human

1. **No tests**, as with the previous task: markdown and JSON, no harness. The
   real check is installing the plugin and seeing which skill fires for "my
   CLAUDE.md is a mess" (should be `audit` — the files exist) versus "set up
   CLAUDE.md for this repo" (should be `setup`). That is yours to run, and the
   `tests` backlog entry now covers the general problem.
