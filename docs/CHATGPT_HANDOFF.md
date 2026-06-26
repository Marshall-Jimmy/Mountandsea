# ChatGPT Handoff

## How to Use This File

This file is the repository-local handoff for continuing web ChatGPT conversations.

- In a new ChatGPT conversation, paste this file first.
- Ask the assistant to use this as the current project context.
- AI agents should update this file after meaningful project progress.

---

## Stable Project Facts

- **Repository:** Marshall-Jimmy/Mountandsea
- **Engine:** Godot 4.7
- **Language:** GDScript
- **Main branch:** master
- **No C# / .NET / NuGet / MSBuild**
- **Godot GUI manual testing is done by the user, not by automation.**

---

## Current Completed Milestones

### PR #30: game: make demo optional content data-driven
- **Status:** merged
- Made `minimal_playable_demo` optional content data-driven
- Kept optional save/load compatibility
- Touched `minimal_playable_demo.gd` and `minimal_playable_demo_save_load_regression.gd`

### PR #31: game: add third data-driven demo optional pair
- **Status:** merged
- **Merge commit:** b1241183cfe469d909d579f7c12061e6cabf6e61
- Added third data-driven optional content pair
- Extended regression coverage
- GUI manual test passed by user

---

## Current Demo State

- Minimal playable demo has data-driven optional content.
- There are three optional content pairs.
- Optional content supports prompt, interaction, history, completion summary, save/load, and reset.
- Snowhuman Framework remains generic (no project-specific content inside the addon).

---

## User Preferences for Future Tasks

- For real implementation tasks, provide prompts that instruct the agent to implement, validate, commit, push, and create PR.
- Do not provide standalone automation prompts for simple GitHub operations the user can do manually.
- Do not make standalone PRs only for tooling or validation improvements.
- Do not run GUI manual tests; the user handles them.
- Keep PR scope tight.
- Do not modify unrelated files.
- Do not fabricate validation results.
- If context is getting long, summarize into this file.

---

## Standard Validation Commands

```
python tools/validate_data.py
python tools/check_framework.py
python tools/validate_minimal_demo.py
git diff --check
git diff --stat
```

Plus: framework addon keyword scan for project-specific content (handled by `tools/check_framework.py`).

---

## Current Suggested Next Feature

**Candidate next feature:** `game: add collapsible optional progress journal`

**Goal:**
- Add optional content progress journal to minimal playable demo
- Show completion state for optional collectibles and optional creature/interactions
- Add show/hide toggle for interaction log panel
- Preserve history while collapsed
- Keep GUI manual test reserved for user

**Status:** This feature is not yet confirmed as implemented unless a later update says so.

---

## Files That Often Matter

- `game/scenes/demo/minimal_playable_demo.gd`
- `game/scenes/demo/minimal_playable_demo.tscn`
- `game/tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd`
- `tools/validate_minimal_demo.py`
- `AGENTS.md`
- `docs/CHATGPT_HANDOFF.md`

---

## Rules for Updating This File

- Update after any merged PR.
- Update after changing the recommended next task.
- Update after major user preference changes.
- Keep this file factual.
- Do not mark work as completed until it is actually merged or explicitly reported as done.
- Include PR numbers, branch names, and commit SHAs when known.
