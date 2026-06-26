# ChatGPT 交接文档

## 如何使用本文件

本文件是用于继续 web ChatGPT 对话的仓库内交接文档。

- 在新的 ChatGPT 对话中，先粘贴本文件。
- 要求 assistant 将本文件作为当前项目上下文。
- AI agents 在项目有实质进展后应更新本文件。

---

## 稳定项目事实

- **仓库：** Marshall-Jimmy/Mountandsea
- **引擎：** Godot 4.7
- **语言：** GDScript
- **主分支：** master
- **不使用 C# / .NET / NuGet / MSBuild**
- **Godot GUI 手动测试由用户完成，不由自动化执行。**
- **协作文档、交接文档和规则文档默认使用中文；技术实体保持原文。**

---

## 当前已完成里程碑

### PR #30: game: make demo optional content data-driven
- **状态：** 已合并
- 将 `minimal_playable_demo` 的可选内容改为 data-driven。
- 保持 optional save/load 兼容性。
- 修改了 `minimal_playable_demo.gd` 和 `minimal_playable_demo_save_load_regression.gd`。

### PR #31: game: add third data-driven demo optional pair
- **状态：** 已合并
- **Merge commit：** b1241183cfe469d909d579f7c12061e6cabf6e61
- 新增第三组 data-driven optional content pair。
- 扩展了回归覆盖。
- 用户已完成 Godot GUI 手测。

### PR #33: game: add collapsible optional progress journal
- **状态：** 已合并
- **Branch：** `game/collapsible-optional-progress-journal`
- **Head SHA：** 24a3201bf674508577ad15ee9b32591ddd9ada2b
- **Merge commit：** 86de81a24c3a18a7dd22e5773c3f2754b881ce9c
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/33
- 为 `minimal_playable_demo` 新增可折叠 optional progress journal。
- 基于现有 data-driven optional state 显示 optional collectible 和 optional creature / interaction 完成状态。
- 新增显式 `InteractionHistoryToggleButton` scene node。
- toggle 会折叠右侧 journal/history panel 和左侧 live log，同时保留 text/history。
- 扩展 `minimal_playable_demo_save_load_regression.gd`，覆盖 journal state 的 save/load、reset、legacy optional load，以及 toggle 保留 history。
- 回归测试通过触发 toggle button 的 `pressed` signal 覆盖真实按钮路径。
- 验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、`git diff --check`、`git diff --stat`，以及显式 Snowhuman Framework keyword scan。
- 用户已完成 Godot GUI 手测，并确认折叠 / 展开 UI 可用。

### PR #35: docs: localize agent docs to Chinese
- **状态：** 已合并
- **Branch：** `docs/localize-agent-docs-zh`
- **Merge commit：** c968fbeb9f6c2b62c78bf43c155cf043aab8c269
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/35
- 将 agent 协作文档和交接文档本地化为中文。
- 新增自动合并规则和自动合并后的本地同步规则。
- 继续要求协作文档、交接文档和规则文档默认使用中文，技术实体保持原文。

---

## 当前开放 PR

### PR #36: game: improve optional journal usability
- **状态：** Draft PR opened / 已根据用户 GUI 手测反馈追加 layout 修复，待用户复测
- **Branch：** `game/optional-journal-usability-bundle`
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/36
- 增强 `minimal_playable_demo` 的 optional progress journal usability。
- 新增总体 progress counters 和 section progress counters。
- 新增运行时 `简洁视图` / `详细视图` 切换，不写入 save data。
- 新增运行时 `最近完成` 提示；reset 或 save/load 后无可靠来源时显示 `无`。
- 改善 journal 与历史记录文本层次和 readability。
- 保持 `隐藏日志` / `显示日志` 折叠右侧 panel 和左侧 live log 的行为不变。
- 扩展 `minimal_playable_demo_save_load_regression.gd`，覆盖 progress counters、compact/detail toggle、recent completion、history preservation、reset、legacy optional load 和不新增 save fields。
- 用户 GUI 手测发现右侧 journal UI 文本重叠：optional progress、recent completion、section title / item list 和 history records 挤在一起。
- 本次追加修复将 optional progress label 和 history label 固定在分离区域，启用 text clipping，并将右侧 history UI 限制为最近 5 条；内部 `interaction_history` 数据仍保留。
- 验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、`git diff --check`、`git diff --stat`，以及显式 Snowhuman Framework keyword scan。
- `git diff --check` 和 `git diff --stat` 仅提示 Windows line-ending warning。
- Godot GUI manual test reserved for user；本 PR 不允许自动合并，仍需用户复测 layout。

---

## 当前 Demo 状态

- Minimal playable demo 已使用 data-driven optional content。
- 当前有三组 optional content pair。
- Optional content 支持 prompt、interaction、history、completion summary、save/load 和 reset。
- PR #33 的可折叠 optional progress journal 已合并并可用。
- Journal 会显示 optional collectible 和 optional creature / interaction 完成状态。
- 显式 `InteractionHistoryToggleButton` 可折叠 / 展开右侧 journal/history panel 和左侧 live log，并保留 text/history。
- PR #36 正在增强 journal usability：progress counters、compact/detail view toggle、recent completion hint，以及 readability / layout polish。
- PR #36 已根据用户 GUI 手测反馈追加修复 journal layout overlap：progress 与 history 分区显示，history UI 只显示最近 5 条但不截断内部 history 数据。
- PR #36 不改变 optional state 核心结构、不新增 save fields、不改变 data-driven optional content 设计。
- Snowhuman Framework 保持通用；addon 内没有项目专用内容。

---

## 用户未来任务偏好

- 对真实实现或文档任务，提示词通常会要求 agent 完成实现、验证、提交、推送和创建 PR。
- 不要为用户可手动完成的简单 GitHub 操作提供 standalone automation prompt。
- 不要单独为 tooling 或 validation 改进创建 PR，除非它们支持 feature PR。
- 不要运行 Godot GUI 手动测试；该步骤由用户完成。
- 保持 PR 范围小而聚焦。
- 不要修改无关文件。
- 不要编造验证结果。
- 如果上下文变长，应将状态总结进本文件。

---

## 标准验证命令

```
python tools/validate_data.py
python tools/check_framework.py
python tools/validate_minimal_demo.py
git diff --check
git diff --stat
```

另需确认 Snowhuman Framework addon 不含项目专用关键词；通常由 `tools/check_framework.py` 覆盖。

---

## 当前建议的下一项功能

**Current active PR：** `game: improve optional journal usability`（PR #36）

**目标：**
- 为 optional progress journal 增加总体与 section progress counters。
- 增加 `简洁视图` / `详细视图` 运行时切换。
- 增加 `最近完成` 运行时提示。
- 改善 journal 文本层次、section labels 和 readability。
- 不改变 optional state、save fields 或 data-driven content。
- 不移动 demo-specific 内容到 Snowhuman Framework。

**状态：** Draft PR 已打开；用户 GUI 手测发现 journal UI 重叠，本次已追加 layout 修复，等待用户复测；不要自动合并。

**验证：**
- `python tools/validate_data.py` passed
- `python tools/check_framework.py` passed
- `python tools/validate_minimal_demo.py` passed
- `git diff --check` passed；仅有 Windows line-ending warning
- `git diff --stat` ran
- 显式 Snowhuman Framework keyword scan for `zhuyu|shensheng|zaoyaoshan|祝余|狌狌|招摇山`：no matches

**下一步：**
- 用户重新进行 Godot GUI manual test，重点检查右侧 optional journal / history panel 是否仍有重叠。
- GUI 手测通过后，由用户决定是否将 draft 标为 ready、merge 或继续反馈修改。

---

## 常用相关文件

- `game/scenes/demo/minimal_playable_demo.gd`
- `game/scenes/demo/minimal_playable_demo.tscn`
- `game/tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd`
- `tools/validate_minimal_demo.py`
- `AGENTS.md`
- `docs/CHATGPT_HANDOFF.md`

---

## 更新本文件的规则

- 每次合并 PR 后更新。
- 更改推荐下一项任务后更新。
- 用户偏好有重要变化后更新。
- 保持本文件事实准确。
- 工作未实际合并或用户未明确报告完成前，不要标记为 completed / merged。
- 已知时记录 PR number、branch name 和 commit SHA。
