# AGENTS.md

## Purpose

This file is the mandatory ruleset that all AI coding agents (Codex, Claude, GLM, ChatGPT, and similar) must read and follow when working in this repository.

It exists to prevent hallucinations, unauthorized tech-stack changes, framework contamination, scope creep, and fabricated project status.

---

## Project Facts

| Key | Value |
|-----|-------|
| Repository | Marshall-Jimmy/Mountandsea |
| Engine | Godot 4.7 |
| Language | GDScript |
| Main branch | master |
| C# | Not used |
| .NET | Not used |
| NuGet | Not used |
| MSBuild | Not used |

---

## Architecture Boundaries

1. **Snowhuman Framework addon must remain generic.** The addon at `game/addons/snowhuman_framework/` is a reusable game framework. It must not contain any project-specific content.

2. **山海经 / Mountandsea project-specific content must not enter Snowhuman Framework.** Keywords like `zhuyu`, `shensheng`, `zaoyaoshan`, `祝余`, `狌狌`, `招摇山` must not appear inside `game/addons/snowhuman_framework/`.

3. **Demo-specific content should stay in `minimal_playable_demo` or demo-local tests.** Do not promote demo optional content into global systems.

4. **Do not modify `game/project.godot`** unless the task explicitly requires it and there is a sufficient reason.

---

## AI Grounding Rules

1. **Inspect the repository before making claims.** Read the actual files, branches, PRs, and issues before stating facts.

2. **Do not invent files, issues, PRs, systems, roadmap items, or validation results.** If something does not exist in the repository, do not claim it does.

3. **If uncertain, inspect first or state uncertainty.** Do not guess.

4. **Do not claim GUI manual testing was run** unless the user explicitly reports it. GUI manual testing is reserved for the user.

5. **Do not fabricate successful validation results.** If a validation command did not run, say so. If it failed, report the failure.

---

## Scope Control

1. **Do not perform unrelated refactors.** Only modify files relevant to the current task.

2. **Do not opportunistically fix unrelated issues.** If you spot a bug outside scope, note it but do not fix it in the same PR.

3. **Do not expand a small task into a framework rewrite.** Keep changes minimal.

4. **Do not add new dependencies** unless explicitly requested by the user.

5. **Keep PRs small and scoped.** One PR should address one logical change.

---

## User Workflow Preferences

1. **For real code/documentation tasks**, the AI should complete implementation, validation, commit, push, and PR creation automatically. Do not stop after local edits.

2. **Simple GitHub operations are handled manually by the user** and do not need standalone automation prompts, including:
   - updating PR descriptions
   - marking draft PRs ready
   - merging PRs
   - deleting branches
   - checking checkboxes
   - simple local pull/cleanup

3. **Godot GUI manual testing is reserved for the user.** Do not attempt to run Godot GUI tests automatically.

4. **Tooling / validation improvements should not usually be standalone PRs.** Include them only when they support a feature PR.

---

## Required Validation

Default validation commands that should run before every PR:

```
python tools/validate_data.py
python tools/check_framework.py
python tools/validate_minimal_demo.py
git diff --check
git diff --stat
```

Additional check:
- Confirm `game/addons/snowhuman_framework/` contains no project-specific content keywords.

Rules:
- **GUI manual test is reserved for user manual verification.** List it as "reserved for user" in the PR.
- **If a non-GUI validation step cannot run, the PR must clearly say why.**
- **Never mark a validation item as passed unless it actually ran or the user explicitly confirmed it.**

---

## Pull Request Requirements

PR body should include these sections:

- **Summary** — what the PR does
- **Changes** — files modified and what changed
- **Validation** — each validation command and its result
- **Scope** — what was intentionally not changed

Final response after an automated task should include:
- branch name
- commit SHA
- PR link
- modified files
- validation results
- unrun items (if any)
- whether GUI manual test was reserved for user

---

## Conversation Handoff

`docs/CHATGPT_HANDOFF.md` is the source of truth for switching web ChatGPT conversations.

- At the end of meaningful work, update `docs/CHATGPT_HANDOFF.md` with current project state, latest PR, next recommended task, and constraints.
- Do not rely on memory alone when the handoff file exists; read it first.
- The handoff file should be updated after every merged PR or significant progress change.
