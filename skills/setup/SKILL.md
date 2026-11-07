---
name: setup
description: Writes token-efficient agent context for a repository — a small root CLAUDE.md or AGENTS.md, per-module memory files, and path-scoped .claude/rules. Use this when the user wants to create, initialize or restructure CLAUDE.md or AGENTS.md, organize instructions for a monorepo or multi-module project, or split an overgrown memory file into module files. To diagnose what existing context costs rather than write it, use the audit skill instead.
---

# Context Setup

Every line in an always-loaded file is paid for on every request. The goal is a small root file with pointers, module details that load only when Claude works in that module, and skills that load only when relevant.

## How Claude Code loads context (the rules everything below follows)

- Root `CLAUDE.md` and every `CLAUDE.md` in parent directories of the cwd load at startup.
- `CLAUDE.md` files in subdirectories load **only when Claude reads files in that subtree**. This is the main lever for multi-module projects.
- `@path/to/file` imports are expanded when the importing file loads, so `@README.md` in the root file puts the whole README in every session. Splitting a long file into imports organizes it but does **not** reduce its cost. Use a plain-text pointer ("See docs/architecture.md for …") when the file is only sometimes needed.
- `.claude/rules/*.md` load at startup unless they have `paths:` frontmatter, which limits them to matching files. A path-scoped rule is summarized away by compaction, so a rule that must survive a long session belongs unscoped or in the root file.
- Skills: only `name` + `description` are always loaded; the SKILL.md body loads when the skill triggers; files in `references/` load only when read.
- Auto memory also loads every session — the first 200 lines or 25KB of `~/.claude/projects/<project>/memory/MEMORY.md` — and Claude writes it, so it is not under the team's review. It is not part of the repo and not written by this skill, but it counts in the startup total.
- A context file is **guidance**, not configuration: Claude may decide a guideline doesn't apply. A rule that can never bend belongs in a `PreToolUse` hook, a `permissions.deny` rule, or a `Stop` hook.

## Workflow

1. **Map the repo.** List top-level directories and build files (package.json, pom.xml, build.gradle, Cargo.toml, go.mod, pyproject.toml, *.sln, etc.) to identify modules. Read the README and any existing docs briefly — skim, don't load everything.
2. **Collect the essentials** per module: build/test/lint commands, entry points, conventions that differ from the rest of the repo, and known pitfalls. Ask the user for pitfalls you can't infer; these are the most valuable lines.
3. **Write the root file** using the root template in `references/templates.md`. Target ≤ 50 lines, hard ceiling 80.
4. **Write one CLAUDE.md per module** that has its own commands or conventions, using the module template. Target ≤ 60 lines. Skip modules with nothing specific to say.
5. **Move topic rules** (testing, security, style) that apply to only part of the repo into `.claude/rules/<topic>.md` with `paths:` frontmatter.
6. **Handle AGENTS.md** if the team uses other agents: keep the shared content in `AGENTS.md`. Recent Claude Code reads `AGENTS.md` directly, so a `CLAUDE.md` is not required; add one holding `@AGENTS.md` plus any Claude-only notes when the project also needs Claude-specific instructions or when sessions can't load `AGENTS.md` directly. Never write a `CLAUDE.md` that tells Claude *in words* to read `AGENTS.md` — Claude sees that file only if it decides to open it. On Windows, use the import rather than a symlink: git checks a committed symlink out as plain text without `core.symlinks`.
7. **Import only what every session needs.** An `@import` loads the whole target file whenever the importing file loads, so use it for small always-relevant files (`@AGENTS.md`) and a plain-text pointer for everything else. Check that every path you write actually exists — a broken `@import` fails silently.
8. **Suggest exclusions** for large generated or vendored directories (see "Excluding paths" in `references/templates.md`).

Show the user the planned file list before writing files if the repo has more than ~5 modules or already has context files you'd change.

The line targets are heuristics, and deliberately stricter than the documented target of under 200 lines per file: a root file is paid for on every request of every session, so 50 is a budget worth defending. Use judgment — an 85-line root file in a huge monorepo can be fine; a 40-line one full of generic advice is not. Claude Code warns at startup and in `/status` when a file passes the recommended length.

## What to cut

Delete lines that Claude follows without being told: "write clean code", "handle errors properly", "use meaningful names", restated language conventions, and long explanations of well-known frameworks. Keep lines that change behavior: exact commands, non-obvious conventions, "never do X here because Y", and directory maps. Prefer one short example over a paragraph of description.

Don't write these at all — they were useful for older models and now backfire:

- `IMPORTANT`, `CRITICAL` or ALL CAPS emphasis. A plainly worded line is followed; stacked emphasis makes the rule get over-applied.
- "Keep going", "loop until done", "don't be lazy". More likely to cause over-work than to fix a stall.
- Advice to treat the context window as the main constraint. Windows are large and compaction is automatic; the reason to stay small is cost and focus.

## Reporting

End with a short summary: files created or changed, startup token estimate before and after (root files + unscoped rules + skill descriptions + whatever the `@imports` pull in + auto memory, characters ÷ 4), and anything left for the user to decide. `/context` reports the real figure — suggest it rather than defending an estimate.

For anything beyond the files just written — documentation structure, skill sizes, MCP overhead, build scope, command output, prompt caching, subagents — run `/context:audit`.
