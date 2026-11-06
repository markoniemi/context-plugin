# Token budget

What this plugin costs a session that never uses it. Measured 2026-11-06.

Only each skill's `name` and `description` are loaded on every request. The two
`SKILL.md` bodies and all five files under `references/` load on demand, so they
cost nothing until a skill fires or reads one.

| | bytes | ~tokens |
| :- | --: | --: |
| `skills/audit/SKILL.md` frontmatter | 633 | 158 |
| `skills/setup/SKILL.md` frontmatter | 472 | 118 |
| **always loaded** | **1105** | **~276** |

Tokens are estimated as bytes ÷ 4, the same heuristic the skills themselves use.
Both check scripts count UTF-8 bytes with the CR stripped and the newline
counted, so they agree to the byte; counting UTF-16 characters instead would
undercount every em dash by two.

The ceiling enforced by `scripts/check.sh` is **1200 bytes**. It is a
regression guard, not a limit from the runtime: raise it deliberately in the
script and here together, rather than letting it drift.

For comparison, the plugin's own `SKILL_DESCRIPTION` rule warns above 1024
characters for a *single* description. The audit description is well under that,
and long on purpose — the extra phrasing is what makes "my CLAUDE.md is a mess"
reach `audit` rather than `setup`.

## What is not measured here

`claude plugin details context` reports a projected token cost from the installed
plugin, and that is the authoritative figure. It needs the plugin installed — it
takes no `--plugin-dir` — so it cannot run against a bare checkout or in CI:

```
claude plugin marketplace add .
claude plugin install context@context-plugin
claude plugin details context
```

The numbers above are measured from the files instead, which is why they count
only frontmatter and ignore whatever per-plugin overhead the runtime adds.

## Known validation warning

`claude plugin validate . --profile directory --strict` exits 1 on
`ICON_MISSING`. It is left unresolved on purpose: the fix is a square PNG of 512
to 2048 px, and the file becomes the listing icon **only once**, at the first save
or submission in the developer portal — so a placeholder would permanently take
the real icon's place. `scripts/check.sh` therefore runs that profile without
`--strict`, prints the warning, and does not fail on it.
