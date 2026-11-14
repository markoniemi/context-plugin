---
create_branch: false
create_pull_request: false
---

# Task Backlog

Inbox for new tasks. A human adds an entry; the AI turns it into a task file. See
`README.md` for how. The rules come from the `task` plugin, not from this
directory.

The frontmatter above is this project's configuration. `create_branch` decides
whether a task may have its own branch; `create_pull_request` decides whether
reaching `in_review` opens a pull request on GitHub, or a merge request on GitLab;
`squash_on_merge` decides whether merging a task branch squashes it into one
commit. The first two are ceilings: `false` takes the thing away from every task,
whatever else is written down. Edit them here and the next task follows them.

Entry format: `### [<kind>: ]<short title> [<status>, <priority>]` plus a short
explanation. Once the AI has created the task file, it adds a `file: <link>` line
under the heading and keeps the brackets up to date as the status changes. An entry
is removed when its task is cleaned, so this file shows open work only.

Keep a heading short and plain: it becomes the task file's name, and the branch
name when the project uses branches.

Kinds, written before a colon, decide what the branch is called and nothing else:

* `feature: add a login page` - branch `feature/add-a-login-page`.
* `bug: duplicate invoice rows` - branch `bug/duplicate-invoice-rows`.
* `task: bump the version` - branch `task/bump-the-version`.

**No prefix means `task`.** The prefix is dropped from the file and branch name, so
`feature: add a login page` gives `add-a-login-page.md`. A word before a colon that
is not one of the three is simply part of the title.

Statuses:

* `draft` - written down, not planned yet.
* `planning` - a human asked the AI to plan it.
* `planned` - cleared to implement. Either a plan is written and waiting for a
  human to verify it, or you set `planned` yourself **with no plan** in the task
  file, which waives the plan and tells the AI to go straight to the code.
* `in_progress` - the AI is implementing it.
* `in_review` - the implementation is ready, waiting for review.
* `changes_requested` - review asked for changes.
* `approved` - review passed, ready to land.
* `done` - merged, or committed on `main` when the project uses no branches.
* `cancelled` - it will not happen, or it happened and was reverted. Yours to set,
  from any status but `done`, and nothing comes back out of it. The AI deletes the
  task's unmerged branch and leaves anything already on `main` alone.

Priorities: `high` | `medium` | `low`.

---

## Backlog

### trigger evals [draft, low]

Nothing tests which skill fires for a given request. `claude plugin validate`
reads the descriptions; it does not exercise them. So the `setup` / `audit` split
rests on reasoning alone, and a request reaching the wrong skill passes every
check the `tests` task adds.

Fixing that means a `claude plugin eval` suite, which costs money per run: around
36 `claude` child runs for a full pass (6 cases × 3 runs × 2 ablation arms),
bounded with `--max-cost-usd` and `--runs`. Deferred for that reason.

Cases worth writing:

* **Trigger discrimination**, the highest value. "set up CLAUDE.md for this repo"
  and "split my CLAUDE.md into module files" should fire `setup`; "my CLAUDE.md is
  a mess" and "why is Claude Code so expensive on this project?" should fire
  `audit`. Grade with `tool_used: Skill` naming the expected skill, plus a grader
  on the answer: under the default `--ablation with-without`, a `tool_used: Skill`
  grader is a plugin-fired indicator, not part of the score.
* **Audit changes nothing**, the guarantee that makes `/context:audit` safe on a
  repo you do not own: no `Write` or `Edit` call, and a report as output. Do not
  use `--disallow-tools`; the case must prove the skill declines on its own, not
  that the harness blocked it.
* **Setup respects its own limits**: a scaffolded two-module repo gets a root file
  under 80 lines and a module file per module with its own commands.

### readme rules [done, medium]

file: [readme-rules.md](readme-rules.md)

- is there a rule about readme size? or readme location, if there should be should be small readme file in different directories and root readme file references. or if no relevant directory exists, use docs-directory for documentation files.
