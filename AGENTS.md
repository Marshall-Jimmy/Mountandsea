# AGENTS.md

## 用途

本文件是所有 AI coding agents（Codex、Claude、GLM、ChatGPT 及类似工具）在本仓库工作时必须读取并遵守的强制规则集。

它用于防止幻觉、未经授权的技术栈变更、框架污染、范围蔓延，以及虚假的项目状态描述。

---

## 项目事实

| 项目 | 值 |
|-----|----|
| 仓库 | Marshall-Jimmy/Mountandsea |
| 引擎 | Godot 4.7 |
| 语言 | GDScript |
| 主分支 | master |
| C# | 不使用 |
| .NET | 不使用 |
| NuGet | 不使用 |
| MSBuild | 不使用 |

---

## 架构边界

1. **Snowhuman Framework addon 必须保持通用。** `game/addons/snowhuman_framework/` 下的 addon 是可复用游戏框架，不得包含项目专用内容。

2. **山海经 / Mountandsea 项目专用内容不得进入 Snowhuman Framework。** `zhuyu`、`shensheng`、`zaoyaoshan`、`祝余`、`狌狌`、`招摇山` 等关键词不得出现在 `game/addons/snowhuman_framework/` 中。

3. **Demo 专用内容应留在 `minimal_playable_demo` 或 demo-local tests 中。** 不要把 demo 的可选内容提升到全局系统。

4. **不要修改 `game/project.godot`**，除非当前任务明确要求，并且有充分理由。

---

## AI 事实依据规则

1. **作出结论前必须检查仓库。** 在陈述事实前，读取实际文件、分支、PR 和 issue。

2. **不要编造文件、issue、PR、系统、路线图条目或验证结果。** 仓库中不存在的内容，不得声称其存在。

3. **不确定时先检查，或明确说明不确定。** 不要猜测。

4. **不要声称已运行 Godot GUI 手动测试**，除非用户明确报告。Godot GUI 手动测试由用户完成。

5. **不要伪造成功的验证结果。** 如果验证命令没有运行，要如实说明；如果失败，要报告失败。

---

## 范围控制

1. **不要做无关重构。** 只修改与当前任务相关的文件。

2. **不要顺手修复范围外问题。** 如果发现范围外 bug，可以记录，但不要在同一个 PR 中修复。

3. **不要把小任务扩展成框架重写。** 保持改动最小。

4. **不要新增依赖**，除非用户明确要求。

5. **保持 PR 小而聚焦。** 一个 PR 应只处理一个逻辑变更。

---

## 用户工作流偏好

1. **真实代码或文档任务**中，AI 应自动完成实现、验证、提交、推送和 PR 创建，不要停在本地编辑阶段。

2. **简单 GitHub 操作由用户手动处理**，不需要单独自动化提示，包括：
   - 更新 PR 描述
   - 将 draft PR 标记为 ready
   - 合并 PR
   - 删除分支
   - 勾选 checkbox
   - 简单本地 pull / cleanup

3. **Godot GUI 手动测试由用户完成。** 不要尝试自动运行 Godot GUI 手测。

4. **tooling / validation 改进通常不应单独成 PR。** 只有在支持 feature PR 时才一并包含。

---

## 文档语言规则

本仓库中由 agent 新增或维护的协作文档、交接文档和规则文档，默认使用中文。

适用范围包括但不限于：

- `AGENTS.md`
- `docs/CHATGPT_HANDOFF.md`
- 面向后续 ChatGPT / Codex / Claude / GLM 的项目交接说明
- agent 协作规则
- PR handoff / progress handoff 说明

代码标识符、文件路径、命令、分支名、commit SHA、PR 标题、测试命令、错误信息、API 名称、Godot 节点名等技术实体应保持原文，不要强行翻译。必要时可以保留英文术语，并在旁边用中文解释。

已有英文协作文档在后续维护时应优先改写为中文，但不要为了翻译而扩大当前任务范围。PR 标题和 commit message 可以继续使用英文 conventional commit 风格。

---

## 任务开始前本地同步规则

agent 开始任何新任务前，必须先确认当前操作的本地 checkout / worktree 状态。

推荐流程：

1. 运行 `git status --short` 检查是否存在未提交改动。
2. 若存在未提交改动，不得擅自 `reset --hard`、`clean -fd`、`stash drop` 或覆盖用户改动；必须停止并报告用户处理。
3. 若工作区干净，切回 `master`。
4. 运行 `git fetch origin`。
5. 运行 `git pull --ff-only origin master`，确保本地 `master` 与远端同步。
6. 再从最新 `master` 创建任务分支或任务 worktree。
7. 如果任务需要在已有 PR 分支上继续，应先 `git fetch origin`，再确认当前分支与远端 PR head 的关系，避免基于过期提交继续开发。

agent 不得在过期的本地 `master` 或来源不明的旧 worktree 上开始新任务。

---

## 任务结束后的 worktree / 临时目录清理规则

agent 使用临时 worktree 或 sibling checkout 完成任务后，必须在最终汇报中说明该目录是否仍需保留。

- 如果 PR 仍是 draft、仍需用户 GUI 手测、或后续可能继续追加 commit，则保留对应 worktree，并明确告诉用户目录路径。
- 如果 PR 已合并且本地没有未提交改动，应清理本次任务创建的 worktree / 临时目录。
- 清理前必须运行 `git status --short`。
- 若存在未提交改动，不得擅自删除、`reset --hard`、`clean -fd` 或覆盖用户改动；必须停止并报告。
- 对 Git worktree，优先使用 `git worktree remove <path>`，必要时在用户明确同意后才使用 `--force`。
- 清理后运行 `git worktree prune`。
- agent 不得删除用户其他仓库目录或无法确认来源的文件夹。
- agent 不得假定所有名似 `Mountandsea-*` 的文件夹都可以删除；只能处理本次任务明确创建或用户明确指定的目录。

---

## 自动合并规则

agent 只有在同时满足以下条件时，才可以自动合并 PR：

- 当前任务明确属于低风险文档维护。
- 任务提示词明确允许 auto-merge。
- diff 只修改任务明确允许的文档文件。
- PR 没有修改游戏代码、测试、Godot 场景文件、schemas、CI、tooling、项目设置或 Snowhuman Framework addon。
- 必要验证命令全部通过。
- `git diff --check` 通过。
- `git diff --stat` 确认文件范围符合预期。
- PR 无冲突，并且 GitHub 显示可合并。

agent 不得自动合并 feature PR、gameplay PR、save/load PR、test PR、Godot scene PR、framework PR、schema PR、CI PR、tooling PR 或 project settings PR。这些 PR 必须经过用户 review；Godot GUI 手动测试仍然由用户完成。

### 自动合并后的本地同步规则

当 agent 被明确允许自动合并 PR，并且 PR 已成功合并后，agent 必须同步其当前操作的本地 checkout / worktree：

1. 切回 `master`。
2. 拉取最新 `origin/master`。
3. 确认本地 `master` 已包含刚刚合并的 commit。
4. 删除本次任务使用的本地功能分支。
5. 删除本次任务使用的远程功能分支，如果远程分支仍然存在。
6. 运行 `git status --short`，确认工作区干净。
7. 在最终汇报中说明：
   - PR 编号
   - merge commit SHA
   - 本地 `master` 当前 HEAD
   - 本地同步是否完成
   - 本地和远程功能分支是否已清理
   - 工作区是否干净

同步前必须先确认当前本地 checkout / worktree 没有未提交改动。若存在未提交改动，agent 不得擅自 `reset --hard`、`clean -fd`、`stash drop` 或覆盖用户改动；应停止同步并报告需要用户处理。

agent 只能同步自己当前操作的本地 checkout / worktree。不要假定用户电脑上的其他仓库目录也已同步，除非任务提示明确给出了对应路径并要求处理。

允许自动合并时，默认使用 squash merge，除非用户明确要求其他合并方式。合并成功后，必须按照“自动合并后的本地同步规则”同步当前本地 checkout / worktree，并确认工作区干净。

---

## 必需验证

每个 PR 前默认应运行以下验证命令：

```
python tools/validate_data.py
python tools/check_framework.py
python tools/validate_minimal_demo.py
git diff --check
git diff --stat
```

额外检查：
- 确认 `game/addons/snowhuman_framework/` 中没有项目专用内容关键词。

规则：
- **Godot GUI 手动测试保留给用户手动验证。** 在 PR 中列为 "reserved for user"。
- **如果某个非 GUI 验证步骤无法运行，PR 必须明确说明原因。**
- **除非验证实际运行过或用户明确确认，否则不得标记为通过。**

---

## Pull Request 要求

PR body 应包含以下部分：

- **Summary** — 说明 PR 做了什么
- **Changes** — 修改了哪些文件以及具体变化
- **Validation** — 每个验证命令及其结果
- **Scope** — 有意不修改的范围

自动任务完成后的最终回复应包含：
- 分支名
- commit SHA
- PR 链接
- 修改文件
- 验证结果
- 未运行项目（如有）
- Godot GUI 手动测试是否保留给用户

---

## 对话交接

`docs/CHATGPT_HANDOFF.md` 是切换 web ChatGPT 对话时的仓库内事实来源。

- 有新的 ChatGPT 对话时，先粘贴该文件。
- 当该文件存在时，不要只依赖记忆；必须先读取它。
- 每次合并 PR 或项目状态有显著进展后，都应更新该文件。
