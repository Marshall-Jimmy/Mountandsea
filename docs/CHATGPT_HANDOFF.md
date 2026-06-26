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

## Current Open PRs

### PR #33: game: add collapsible optional progress journal
- **Status:** PR opened / pending review (draft)
- **Branch:** `game/collapsible-optional-progress-journal`
- **Link:** https://github.com/Marshall-Jimmy/Mountandsea/pull/33
- Adds a collapsible optional progress journal to `minimal_playable_demo`.
- Shows data-driven optional collectible and creature/interaction completion state from existing optional state.
- Adds a show/hide toggle for the existing interaction history panel while preserving history when collapsed.
- After user feedback that the log could not be collapsed, the PR now uses an explicit scene button node and the toggle hides both the right-side journal/history panel and the left-side live log while preserving their text.
- Extends the minimal demo save/load regression to cover journal state after save/load, reset, legacy optional loads, and the toggle preserving history.
- Regression coverage now emits the toggle button's `pressed` signal instead of directly calling the handler.
- GUI manual test is reserved for user.

---

## Current Demo State

- Minimal playable demo has data-driven optional content.
- There are three optional content pairs.
- Optional content supports prompt, interaction, history, completion summary, save/load, and reset.
- PR #33 adds an optional progress journal and history panel toggle, but it is not merged yet.
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

**Current active feature:** `game: add collapsible optional progress journal`

**Goal:**
- Add optional content progress journal to minimal playable demo
- Show completion state for optional collectibles and optional creature/interactions
- Add show/hide toggle for interaction log panel
- Preserve history while collapsed
- Keep GUI manual test reserved for user

**Status:** PR #33 opened / pending review (draft). This feature is not merged yet.

**Validation run for PR #33:**
- `python tools/validate_data.py` passed
- `python tools/check_framework.py` passed
- `python tools/validate_minimal_demo.py` passed
- `git diff --check` passed with exit code 0; Windows line-ending warnings only
- `git diff --stat` ran
- Explicit Snowhuman Framework keyword scan for `zhuyu`, `shensheng`, `zaoyaoshan`, `祝余`, `狌狌`, `招摇山` found no matches

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
