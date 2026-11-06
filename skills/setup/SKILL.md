---
name: setup
description: Writes token-efficient agent context for a repository — a small root CLAUDE.md or AGENTS.md, per-module memory files, and path-scoped .claude/rules. Use this when the user wants to create, initialize or restructure CLAUDE.md or AGENTS.md, organize instructions for a monorepo or multi-module project, or split an overgrown memory file into module files. To diagnose what existing context costs rather than write it, use the audit skill instead.
---

# Context Setup

Every line in an always-loaded file is paid for on every request. The goal is a small root file with pointers, module details that load only when Claude works in that module, and skills that load only when relevant.

## How Claude Code loads context (the rules everything below follows)

- Root `CLAUDE.md` and every `CLAUDE.md` in parent directories of the cwd load at startup.
- `CLAUDE.md` files in subdirectories load **only when Claude reads files in that subtree**. This is the main lever for multi-module projects.
- `@path/to/file` imports are expanded when the importing file loads, so `@README.md` in the root file puts the whole README in every session. Use a plain-text pointer ("See docs/architecture.md for …") when the file is only sometimes needed.
- `.claude/rules/*.md` load at startup unless they have `paths:` frontmatter, which limits them to matching files.
- Skills: only `name` + `description` are always loaded; the SKILL.md body loads when the skill triggers; files in `references/` load only when read.

## Workflow

1. **Map the repo.** List top-level directories and build files (package.json, pom.xml, build.gradle, Cargo.toml, go.mod, pyproject.toml, *.sln, etc.) to identify modules. Read the README and any existing docs briefly — skim, don't load everything.
2. **Collect the essentials** per module: build/test/lint commands, entry points, conventions that differ from the rest of the repo, and known pitfalls. Ask the user for pitfalls you can't infer; these are the most valuable lines.
3. **Write the root file** using the root template in `references/templates.md`. Target ≤ 50 lines, hard ceiling 80.
4. **Write one CLAUDE.md per module** that has its own commands or conventions, using the module template. Target ≤ 60 lines. Skip modules with nothing specific to say.
5. **Move topic rules** (testing, security, style) that apply to only part of the repo into `.claude/rules/<topic>.md` with `paths:` frontmatter.
6. **Handle AGENTS.md** if the team uses other agents: keep the shared content in `AGENTS.md` and make `CLAUDE.md` a one-line `@AGENTS.md` import plus any Claude-only notes, so there is a single source of truth.
7. **Import only what every session needs.** An `@import` loads the whole target file whenever the importing file loads, so use it for small always-relevant files (`@AGENTS.md`) and a plain-text pointer for everything else. Check that every path you write actually exists — a broken `@import` fails silently.
8. **Suggest exclusions** for large generated or vendored directories (see "Excluding paths" in `references/templates.md`).

Show the user the planned file list before writing files if the repo has more than ~5 modules or already has context files you'd change.

The line targets are heuristics. Use judgment: an 85-line root file in a huge monorepo can be fine; a 40-line one full of generic advice is not.

## What to cut

Delete lines that Claude follows without being told: "write clean code", "handle errors properly", "use meaningful names", restated language conventions, and long explanations of well-known frameworks. Keep lines that change behavior: exact commands, non-obvious conventions, "never do X here because Y", and directory maps. Prefer one short example over a paragraph of description.

## Reporting

End with a short summary: files created or changed, startup token estimate before and after (root files + unscoped rules + skill descriptions + whatever the `@imports` pull in, characters ÷ 4), and anything left for the user to decide.

For anything beyond the files just written — documentation structure, skill sizes, MCP overhead, build scope, command output, prompt caching, subagents — run `/context:audit`.
