---
id: package-context-plugin-as-plugin
status: in_progress
priority: medium
branch: task/package-context-plugin-as-plugin
---

# package context-plugin as plugin

- add needed config files
- readme which explains what plugin does
- skills are: /context:audit /context:setup
- should plugin be named context-plugin or token-usage-plugin?

# Implementation Plan

## Naming decision

The slash commands a plugin's skills get are `/<plugin-name>:<skill-name>`. The
entry asks for `/context:audit` and `/context:setup`, so the **plugin** name must
be `context` and the skill directories must be named `audit` and `setup`.
`context-plugin` is then the repository and the marketplace name — which is what
the origin remote already says (`github.com/markoniemi/context-plugin`), and it
matches the `task-plugin` marketplace / `task` plugin split already in use.

`token-usage-plugin` is rejected: the plugin does setup as well as auditing, and
token usage is the motivation, not the scope.

## Steps

1. **Rename the skill directories** to match the wanted commands:
   * `skills/context-setup/` → `skills/setup/` (with its `references/`)
   * `skills/token-usage-audit/` → `skills/audit/`

   Use `git mv` so the history follows. The skills are staged but not committed,
   so this lands as one add.

2. **Fix `skills/audit/SKILL.md`.** Its frontmatter is broken: line 1 is
   `name: ... description: ...` on a single line with no `---` delimiters, and the
   body has lost its markdown (headings, lists and fenced code blocks are plain
   text, e.g. a bare `bash` line before commands). Without valid frontmatter the
   skill will not load at all. Restore:
   * a real frontmatter block with `name: audit` and the description,
   * `##` headings for the numbered sections,
   * bullet lists and ```` ```bash ```` fences.

3. **Shrink `skills/audit/SKILL.md`.** It is ~770 lines. A plugin whose own
   subject is token efficiency should not ship a 770-line skill body. Move the
   rarely needed detail into `skills/audit/references/`:
   * `references/maven-output.md` — section 9A (Maven output volume, steps 1-9)
   * `references/report-template.md` — section 15 (the required report shape)
   * keep the SKILL.md body as the workflow plus pointers, target ≤ 150 lines.

   It is also Maven-specific throughout; make the Maven parts clearly conditional
   so the skill is usable on non-Maven projects.

4. **Set `name:` in `skills/setup/SKILL.md`** to `setup` (currently
   `context-setup`), keeping the description as it stands — the description is what
   triggers the skill and it is already good.

5. **Add `.claude-plugin/plugin.json`**, modelled on the `task` plugin's:

   ```json
   {
     "name": "context",
     "displayName": "context",
     "version": "0.1.0",
     "description": "...",
     "author": { "name": "Marko Niemi", "url": "https://github.com/markoniemi" },
     "homepage": "https://github.com/markoniemi/context-plugin",
     "repository": "https://github.com/markoniemi/context-plugin",
     "license": "MIT",
     "keywords": ["context", "tokens", "claude-md", "audit"]
   }
   ```

   No `userConfig`: neither skill has a project-level switch to expose.

6. **Add `.claude-plugin/marketplace.json`** with marketplace name
   `context-plugin`, the same owner block, and one plugin entry
   (`name: context`, `source: "./"`, `category: "workflow"`).

7. **Add `LICENSE`** (MIT, Marko Niemi) since `plugin.json` claims MIT.

8. **Write the root `README.md`**: what the plugin does (keep agent context small
   so every request costs less), the two commands and when to use each, install
   instructions (`/plugin marketplace add markoniemi/context-plugin` then
   `/plugin install context@context-plugin`), and the repository layout. Keep it
   short.

9. **Extend `.gitignore`** — currently just `.idea`. Nothing else is generated
   here, so leave it unless something turns up.

10. **Verify** before claiming done:
    * `Get-Content .claude-plugin/plugin.json | ConvertFrom-Json` and the same for
      `marketplace.json`, to prove both parse.
    * install the local checkout as a marketplace
      (`/plugin marketplace add C:\Users\marko\Documents\Git\context-plugin`,
      then `/plugin install context@context-plugin`) and confirm `/context:audit`
      and `/context:setup` appear and load. This step is the human's to run, since
      it is a slash command in their session.

## Open questions for the human

1. **Version.** Plan says `0.1.0`. Change it if you want to start elsewhere.
2. **Rewriting the audit skill (steps 2-3).** Answered 2026-11-06: do it in this
   task.
3. **No `commands/`, `agents/` or `hooks/`** are planned: two skills only. Say so
   if you want a `/context:help` style command as well.
