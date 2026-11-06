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
reaching `in_review` opens a pull request on GitHub, or a merge request on GitLab.
Each key is a ceiling: `false` takes the thing away from every task, whatever else
is written down. Edit them here and the next task follows them.

Entry format: `### <short title> [<status>, <priority>]` plus a short explanation.
Once the AI has created the task file, it adds a `plan: <link>` line under the
heading and keeps the brackets up to date as the status changes. An entry is
removed when its task is cleaned, so this file shows open work only.

Keep a heading short and plain: it becomes the task file's name, and the branch
name when the project uses branches.

Statuses:

* `draft` - written down, not planned yet.
* `planning` - a human asked the AI to plan it.
* `planned` - plan written, waiting for a human to verify it.
* `in_progress` - the AI is implementing it.
* `in_review` - the implementation is ready, waiting for review.
* `changes_requested` - review asked for changes.
* `approved` - review passed, ready to land.
* `done` - merged, or committed on `main` when the project uses no branches.

Priorities: `high` | `medium` | `low`.

---

## Backlog

### package context-plugin as plugin [done, medium]

plan: [package-context-plugin-as-plugin.md](package-context-plugin-as-plugin.md)

- add needed config files
- readme which explains what plugin does
- skills are: /context:audit /context:setup
- should plugin be named context-plugin or token-usage-plugin?

### resolve setup and audit overlap [done, medium]

plan: [resolve-setup-and-audit-overlap.md](resolve-setup-and-audit-overlap.md)

`skills/setup/SKILL.md` carries its own "Audit workflow" section, and its setup
workflow ends by telling the agent to run it. The `audit` skill now covers the
same ground in more depth, and both read `setup/references/audit-rules.md`.

Decide where the audit lives: setup keeps a short self-check and defers the real
audit to the `audit` skill, or the audit workflow moves out of setup entirely and
setup just points at `/context:audit`. Then move `audit-rules.md` to whichever
skill owns it, since a cross-skill reference is the thing to avoid.

### other related plugins [draft, low]

- are there other related plugins, maybe from some real authority?
- is there some good best practices on how to reduce token usage?

### tests [done, high]

plan: [tests.md](tests.md)

- plugin has no tests yet.

### trigger evals [draft, low]

Nothing tests which skill fires for a given request. `claude plugin validate`
reads the descriptions; it does not exercise them. So the `setup` / `audit` split
rests on reasoning alone, and a request reaching the wrong skill passes every
check the `tests` task adds.

Fixing that means a `claude plugin eval` suite, which costs money per run: around
36 `claude` child runs for a full pass. Deferred for that reason. The cases worth
writing, and the grader wrinkle around `--ablation with-without`, are recorded
under "Dropped from this plan" in [tests.md](tests.md).