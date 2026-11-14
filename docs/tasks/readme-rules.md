---
id: readme-rules
status: done
priority: medium
kind: task
---

# readme rules

- is there a rule about readme size? or readme location, if there should be should be small readme file in different directories and root readme file references. or if no relevant directory exists, use docs-directory for documentation files.

# Implementation Plan

## What the repository says today

**Size: no rule.** The only README mention in the audit is qualitative, in
`skills/audit/SKILL.md` section 3: "Check whether README files carry excessive
technical detail". No code in `audit-rules.md` measures one. The numeric limits
(80, 100, 50, 200 lines) all apply to context files, imports and auto memory.

**Location: no rule either.** `setup` writes context files and says nothing
about where documentation lives. `templates.md` happens to point at
`docs/architecture.md` and `docs/release.md`, which is the convention you are
asking about, but only as an example line.

**Why the rule is weaker than for `CLAUDE.md`.** A README is not loaded at
startup. It costs tokens only when something pulls it in: an `@README.md`
import (already `EAGER_IMPORT`), `setup` step 1 reading it to map the repo, or
an agent opening it while exploring. So the real cost of a big README is "paid
every time an agent orients itself", not "paid every request". A size rule
should say that, or it will read as another 80-line limit and be over-applied.

## The rule to write

Two parts, both advice rather than hard limits, in the same register as the
existing codes:

1. **Size.** A README an agent is likely to read in full should stay short and
   point at detail. Over a stated line count it is a finding, with the fix
   "move the detail into `docs/<topic>.md` and leave a one-line link".
2. **Location.** The convention you described:
   * a small root `README.md`: what the project is, how to build and run it, and
     links to everything else;
   * a small `README.md` in a directory that is a real unit of the project (a
     module, a package) and has something to say that a reader of that
     directory needs, linked from the root;
   * documentation with no directory of its own goes in `docs/`, linked from the
     root README, not appended to it.

   Caveat worth stating in the rule: a per-directory README and that module's
   `CLAUDE.md` must not repeat each other (`DUPLICATE_CONTENT` already catches
   it). `CLAUDE.md` holds what the agent needs; the README holds what a human
   needs; neither copies the other.

## Steps

1. **Check the primary source first.** Read the Claude Code memory and best
   practice docs for anything on README size or placement. Every number in this
   plugin that was inherited without a source later turned out to be a house
   limit, so say which one this is. If the docs say nothing, label the threshold
   as this skill's own, as `ROOT_TOO_LONG` does.

2. **Add one finding code to `skills/audit/references/audit-rules.md`**:
   `README_TOO_LONG` (condition, then fix, in the file's existing shape), placed
   next to `EAGER_IMPORT` since both are about documentation that gets loaded.
   The location convention goes in its Fix line, so there is still one code and
   one place to look. This is a reference file, so it costs nothing until a
   condition matches.

3. **Section 3 of `skills/audit/SKILL.md`**: add the two-sentence location
   convention and name the code. Net growth about three lines on a 234-line body,
   under the plugin's own 300-line `SKILL_TOO_LONG` threshold.

4. **`skills/setup/SKILL.md`**: one line only, where it already talks about
   pointing at docs (step 7). When a context file points at documentation, point
   at `docs/` and the module README rather than copying. `setup` still writes no
   READMEs: it writes context files, and the write/measure split from the
   earlier task stays as it is.

5. **Dogfood.** This repository's own `README.md` is 113 lines and links out to
   `docs/`. Check it against the number chosen in step 1 and fix it if it fails,
   rather than shipping a rule the repo breaks.

6. **Verify.** `scripts/check.ps1` must still exit 0 with the always-loaded
   budget unchanged at 1105 bytes, because no frontmatter is touched. `Grep` for
   `README_TOO_LONG` to confirm the code appears in both `audit-rules.md` and
   `SKILL.md`, and check any place that counts codes ("eighteen" in
   `docs/prior-art.md` describes the state when it was written; leave it, but do
   not add a new count that is wrong).

No unit tests: markdown only, the same as the earlier tasks. The deterministic
check is step 6.

## Open questions for the human

1. **The threshold.** I suggest note at 150 lines and finding at 250, labelled
   as this skill's own limits. There is no sourced number, so it is a judgment
   call. Or no number at all, only the qualitative wording already in section 3
   plus the location convention. Which?
2. **Per-directory READMEs: advise, or only describe?** The plan makes the
   convention a recommendation in the fix line. A stricter version would flag a
   module that has a `CLAUDE.md` but no README, which I think is wrong: humans
   and agents need different things, and not every module needs both.
3. **Should `setup` ever write a README?** The plan says no. Say so if you want
   a `/context:setup` mode that scaffolds the root README and `docs/`.

## Result

Done on `main`, commit `3797d53` (no branch:
`create_branch` is off).

Answers from the human: no threshold, do not flag a module for lacking a README,
`setup` never writes a README.

* `skills/audit/references/audit-rules.md`: new `README_DETAIL`, qualitative, no
  line count. The fix line holds the layout convention and says not to flag a
  missing module README.
* `skills/audit/SKILL.md` section 3 names the code and states the layout in three
  sentences. 234 → 237 lines.
* `skills/setup/SKILL.md` step 7 gained one sentence: point at `docs/` or the
  module README, do not copy.

Deviation: plan step 1, reading the Claude Code docs for a README rule, was
skipped. With no number to source it had nothing to settle.

Verified: `scripts/check.ps1` exits 0, always-loaded budget unchanged at 1105
bytes. This repository's own README is 113 lines and links out to `docs/`, so it
meets the rule.

## How to review

1. Read the diff: `git diff c69eac5..HEAD -- skills`. Three files, about 20 added
   lines.
2. Check the code reads right in context: `README_DETAIL` in
   `skills/audit/references/audit-rules.md`, and section 3 of
   `skills/audit/SKILL.md`.
3. Run `scripts/check.ps1`. Expect exit 0 and `total 1105 chars`.
4. Not run: whether an audit on a real repo reports `README_DETAIL` sensibly.
   That needs a session, and trigger behaviour is untested by design.
