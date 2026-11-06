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

**Scope, decided 2026-11-06: the free checks only. No eval suite and no eval CI
job.** So this task delivers rows one and two; `claude plugin eval` stays
unused.

Validation would have caught the defect the packaging task found by hand — the
audit skill's frontmatter was one unfenced line, so the skill could not load at
all — and the token budget matters because this plugin's whole claim is about
always-loaded cost. Both are cheap and deterministic.

What the scope leaves untested, stated plainly rather than buried: **nothing here
checks which skill fires for a given request.** `validate` reads the
descriptions, it does not exercise them. The `setup` / `audit` split from the
previous task rests on reasoning alone, and a request like "my CLAUDE.md is a
mess" firing the wrong skill would pass every check in this task. Only an eval
case can catch that. See the open question below.

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

3. **A check script**, so the two commands are one thing to run and one thing for
   CI to call. `scripts/check.ps1` plus `scripts/check.sh`, each running
   `validate . --strict`, then `validate . --profile directory --strict`, then
   `plugin details context`, failing on the first non-zero exit. A dozen lines
   each; this is a wrapper, not a test framework.

4. **CI.** A GitHub Actions workflow on push and pull request that installs the
   CLI and runs `scripts/check.sh`. Free checks only, so no secret and no
   credential. One job, `ubuntu-latest`.

5. **README** — a short "Tests" section: the commands, what each catches, and one
   honest sentence saying triggering behaviour is not covered.

6. **Verify.** Run all three commands and report their real exit codes and output:
   `validate . --strict` exits 0, `validate . --profile directory --strict` exits
   0, and `plugin details context` prints a cost matching what step 2 recorded. If
   `--profile directory` objects to something, fix it or report it — do not drop
   the flag to make the check pass.

## Dropped from this plan

The eval suite, decided 2026-11-06. Kept here so the thinking is not lost if the
budget question is ever worth answering.

Cases that would have been worth writing:

* **Trigger discrimination** — the highest-value cases, because the split is new
  and rests on reasoning alone. "set up CLAUDE.md for this repo" and "split my
  CLAUDE.md into module files" should fire `setup`; "my CLAUDE.md is a mess" and
  "why is Claude Code so expensive on this project?" should fire `audit`.
  Graded with `tool_used: Skill` naming the expected skill — plus a grader on the
  answer, because under the default `--ablation with-without` a `tool_used: Skill`
  grader is a plugin-fired indicator rather than part of the score.
* **Audit changes nothing** — the guarantee that makes `/context:audit` safe to
  run on a repo you do not own: no `Write` or `Edit` call, and a report as output.
  `--disallow-tools` would be the wrong instrument, since the case must prove the
  skill declines on its own rather than that the harness blocked it.
* **Setup respects its own limits** — a scaffolded two-module repo: a root file
  under 80 lines, and a module file per module with its own commands.

Cost, for whenever this is reconsidered: 6 cases × 3 runs × 2 ablation arms is 36
`claude` child runs per pass, bounded with `--max-cost-usd` and `--runs`.

## Answered

Both answered 2026-11-06:

1. **Trigger discrimination has no coverage under this scope** — a request firing
   the wrong skill passes every check this task adds. Tracked separately: the
   `trigger evals` backlog entry, `draft` at low priority.
2. **Two check scripts**, `check.ps1` and `check.sh`, as step 3 describes: Windows
   for development, shell for CI.
