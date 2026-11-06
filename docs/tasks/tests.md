---
id: tests
status: planned
priority: high
---

# tests

- plugin has no tests yet.

# Implementation Plan

## What there is to test against

Claude Code ships three mechanisms, confirmed from `claude plugin --help` on this
machine:

| Tool | What it checks | Cost | CI |
| :- | :- | :- | :- |
| `claude plugin validate <path>` | manifests, and the skills, agents and commands in a directory. `--strict` fails on warnings, `--profile directory` additionally applies the plugin-directory submission checks (missing README and so on) | free, deterministic | yes |
| `claude plugin details <name>` | component inventory and **projected token cost** | free | yes, as a budget check |
| `claude plugin eval [target]` | behavioural eval cases: `evals/**/case.yaml`, or `prompt.md` plus `graders/*.md`. Runs real `claude` children on your credential, haiku as judge | paid, non-deterministic | on demand, not every push |

The three answer different questions, and this plugin needs all three:
validation would have caught the defect the packaging task found by hand (the
audit skill's frontmatter was one unfenced line, so the skill could not load at
all); the token budget matters because this plugin's whole claim is about
always-loaded cost; and only an eval can tell whether `setup` or `audit` fires
for a given request, which is exactly what the last task changed with no evidence
either way.

## Steps

1. **Validation first — it is free and it is the regression that already bit us.**
   Confirm `claude plugin validate . --strict` passes today, and record the exact
   command in the README. Then `claude plugin validate . --profile directory
   --strict` and fix whatever the submission profile wants; it checks for a README
   among other things, which this plugin now has.

2. **A token budget check.** Run `claude plugin details context` and record the
   projected always-loaded cost in `docs/token-budget.md`: the two skill
   descriptions and nothing else, since both bodies and all five reference files
   load on demand. Note the number and the date. This is the figure a future
   change must not quietly grow — the audit description is already 616 characters
   against a planned 500.

3. **Eval suite under `evals/`.** `claude plugin eval init` runs an interview that
   designs graders; use it rather than hand-writing the first case, then trim.
   Cases to cover, in priority order:

   * **Trigger discrimination** — the highest-value cases, because the split is
     new and untested:
     - "set up CLAUDE.md for this repo" → `setup` fires, `audit` does not.
     - "my CLAUDE.md is a mess" → `audit` fires.
     - "why is Claude Code so expensive on this project?" → `audit` fires.
     - "split my CLAUDE.md into module files" → `setup` fires.

     Grade with `tool_used: Skill` naming the expected skill. Under
     `--ablation with-without` (the default when a plugin resolves) a
     `tool_used: Skill` grader counts as a plugin-fired indicator rather than
     part of the score, so each case also needs a grader on the *answer* to carry
     the score.

   * **Audit changes nothing** — the guarantee that makes `/context:audit` safe to
     run on a repo you do not own. Point a case at a scaffolded repo and grade
     that no `Write` or `Edit` call happened and that the output is a report.
     `--disallow-tools` is the wrong instrument here: the case must prove the
     skill declines on its own, not that the harness blocked it.

   * **Setup respects its own limits** — a scaffolded two-module repo; grade that
     a root file was written, that it is under 80 lines, and that a module file
     was written for each module with its own commands.

   Scaffolded repos need `scaffold_script`, which only runs under `--scaffold`
   (author-supplied bash, off by default). Keep those scripts to `mkdir` plus a
   couple of `printf`s so they are readable at a glance.

4. **Keep the eval bill bounded.** `--runs 1` while authoring, the default 3 for a
   real run; `--max-cost-usd` as a hard ceiling; `-j 2` or so, remembering every
   run is a full `claude` child on one rate limit. Results land under
   `evals/results/<timestamp>/` — add that to `.gitignore`, and `--no-publish`
   unless the HTML report is wanted on claude.ai.

5. **CI.** A GitHub Actions workflow on push and pull request that runs only the
   free checks: `claude plugin validate . --strict` and the token-budget
   comparison. The eval suite stays a local or manual job — it needs a credential
   and spends money per run, so put it behind `workflow_dispatch` rather than on
   every push, with `--trust-plugin --threshold 1.0` when it does run.

6. **README** — a short "Tests" section: the free commands anyone can run, and
   how to run the eval suite with its cost caveat.

7. **Verify.** `validate --strict` exits 0; `--profile directory --strict` exits 0;
   the eval suite runs end to end with `--runs 1` and every case scores as
   intended; the budget file matches `plugin details` output. Report the real
   numbers, including any case that does not pass — a trigger case that fails is a
   finding about the descriptions, not a reason to weaken the case.

## Open questions for the human

1. **Cost ceiling for an eval run.** Needed for `--max-cost-usd`. With 6 cases ×
   3 runs × 2 arms (with and without the plugin) that is 36 `claude` child runs
   per full pass. Name a figure, or say "author with `--runs 1` and we will decide
   later".
2. **CI on GitHub Actions?** The remote is `github.com/markoniemi/context-plugin`,
   so that is the assumption. The free checks need no secret; the eval job would
   need an API credential in repository secrets — say whether to add that job at
   all.
3. **Does a failing trigger case block the task?** If "my CLAUDE.md is a mess"
   turns out to fire `setup` rather than `audit`, the fix is a description change,
   which is the previous task's territory. I would report it and fix it here
   rather than open another task, unless you would rather keep them separate.
