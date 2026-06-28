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

### PR #36: game: improve optional journal usability
- **状态：** 已合并
- **Branch：** `game/optional-journal-usability-bundle`
- **Merge commit：** 644be3d89e7eb81ce04cbecfcac86412dceac78d
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/36
- 增强 `minimal_playable_demo` 的 optional progress journal usability。
- 新增总体 progress counters 和 section progress counters。
- 新增运行时 `简洁视图` / `详细视图` 切换，不写入 save data。
- 新增运行时 `最近完成` 提示；reset 或 save/load 后无可靠来源时显示 `无`。
- 修复右侧 journal layout overlap：progress 与 history 分区显示，history UI 只显示最近 5 条但不截断内部 `interaction_history` 数据。
- 扩展 `minimal_playable_demo_save_load_regression.gd`，覆盖 progress counters、compact/detail toggle、recent completion、history preservation、reset、legacy optional load、不新增 save fields，以及 layout overlap regression。
- 用户已完成 Godot GUI 复测，并确认 optional journal layout overlap 修复通过。

### PR #37: game: polish optional journal controls
- **状态：** 已合并
- **Branch：** `game/optional-journal-controls-polish`
- **Merge commit：** 571b2f5fa076c115a774d46c22e9136abb0f9d27
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/37
- 为 `minimal_playable_demo` 的 optional journal 增加 keyboard shortcuts：`J` 切换隐藏 / 显示，`V` 切换简洁 / 详细视图。
- 用户 GUI 手测发现 journal panel 内未显示快捷键提示。
- 本次追加修复将提示设为固定单行小字号、增加可用高度并显式设为可见，文案为：`快捷键：J 隐藏/显示，V 简洁/详细`。
- Godot headless 回归发现提示与 `简洁视图` / `详细视图` 按钮的实际 Control rect 仍有重叠；已下移提示并顺延 progress label 起点，保留明确间距。
- 回归测试补充 shortcut hint label 的存在、可见、非空、包含 `J` / `V`，以及不与 journal buttons、progress label、history label 重叠的断言。
- 将 optional journal layout offsets 提取为局部常量，并拆分 panel title、progress label、history label、buttons 和 shortcut hint 的配置 helper。
- 保持 PR #36 的 overlap 修复：progress 与 history 分区显示，history UI 只显示最近 5 条，内部 `interaction_history` 不截断。
- 不改变 optional state、不新增 save fields、不改变 data-driven optional content 设计。
- 未修改 Snowhuman Framework addon。
- 追加修复验证：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、`git diff --check`、`git diff --stat` passed / ran；显式 Snowhuman Framework keyword scan 无匹配。
- 用户已完成 PR #37 Godot GUI 手动测试。

---

## 当前已完成里程碑（续）

### PR #39: game: add art-guided demo animation state machine
- **状态：** 已合并
- **Branch：** `game/demo-animation-state-machine`
- **Merge commit：** eec4d830eb40d3e159e43f847c028f5cdf0c62ab
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/39
- **合并前的用户 GUI 手测反馈：**
  - 走路动作还是不连贯。
  - 上半身都不动。
  - 腿的动作很别扭。
- **最终追加修复目标：**
  - replace awkward leg-driven walk with stylized robe walk
  - add subtle upper-body motion
  - make robe / sleeve / talisman / shadow motion continuous
  - preserve clean cutout, stable idle, and facing direction
- **美术依据：**
  - `docs/art-direction-materials.md`
  - `docs/山海经附录5-工程路线图.md`
  - `docs/山海经游戏设定集.md`
  - `docs/third-party.md`
- **美术约束摘要：**
  - 画风为半写实东方手绘、青绿山水、动漫感、荒野生存、古朴神秘，优先俯视角表达。
  - 色彩以墨青 `#193d3f`、深绿 `#327345`、雾蓝 `#4f6781` 为主，浅赭/陶土辅助，朱砂与青光作为强调。
  - 角色使用 512×512 单帧画布，实际轮廓约占 300×450；强调清晰剪影和可读表情。文档未规定更具体的身体比例。
  - 明确不采用像素风；使用自由缩放和平滑插值。
  - 文档未规定 idle/walk 精确帧数、FPS 或最终 4/8 方向方案；本 demo 当前使用 idle 2 帧、walk 8 帧，idle 2 FPS、walk 8 FPS。
  - 禁止现代科幻 UI、纯欧美卡通、克苏鲁/现代怪兽、照片级写实和直接照搬《饥荒》焦黑哥特风格。
  - 不引入外部版权素材；本次按用户要求使用内置图像生成工具制作 demo-local 原创 placeholder，再在本地完成 chroma-key 去背和 atlas 整理。
- 使用透明 `1536×1024` 的 `3×2` source sheet，并由 Python 标准库脚本确定性清理、对齐和重排为横向 `5120×512` player sprite sheet：frame `0-1` 为 idle，frame `2-9` 为 8 帧 walk cycle，每帧 `512×512`。
- 生成脚本显式记录各帧 source layout、source feet anchor 和统一 `TARGET_FEET_ANCHOR = (256, 488)`；所有输出帧使用相同 canvas，脚底 baseline 均为 y=488。
- 抠图清理会去除 alpha 低于 32 的 matte residue、微小孤立色点，并从邻近实色像素修复半透明边缘颜色；本次追加修复未调用外部 AI，不引入网络素材或外部版权素材。
- walk 生成管线不再拼接四个不同腿部 pose，而是复用同一个 canonical silhouette，通过 8 帧参数表确定性控制 `torso_x/y`、轻微 tilt、robe / sleeve sway、talisman offset、foot-tip hint 和 shadow offset / scale。
- walk 改为 stylized robe walk：程序化长袍纹理覆盖夸张腿部，只保留靠近 feet anchor 的轻微暗色足尖；脚步感主要由上半身 bob、袍摆、袖口、青光符牌和阴影的周期变化表达。
- 新增 `demo_player_walk_metadata.json`，记录 `stylized_robe_walk` design、robe-dominant / leg-style 声明、8 FPS、统一 feet anchor 和逐帧运动参数。
- 生成脚本会验证逐帧参数连续性、feet baseline、body center spread、bounding box height spread，以及包含首尾闭环在内的相邻帧 normalized alpha delta，拒绝明显跳变。
- 新图继续使用成年山行者轮廓、分层衣袍、披风、发髻、木杖、朱砂腰带和青光符牌；idle 保持原有稳定呼吸 / 青光变化，walk 改为 8 帧 robe-dominant 连续循环。
- `PlayerSprite` 放大到 `0.2`，提高到 `z_index = 10`；旧 Polygon2D 保持透明，仅作为 fallback，不再主导画面。
- demo-local `DemoPlayerAnimationStateMachine` 继续集中管理 `IDLE` / `WALK` 与 `idle` / `walk` 映射；重复状态不会重启动画。
- 状态机新增运行时 `last_facing_direction`：素材原始朝左，左移保持 `flip_h = false`，右移使用 `flip_h = true`，停止及纯上下移动保留最近水平朝向，reset/load 恢复默认朝右。
- `minimal_playable_demo` 使用 `AnimatedSprite2D` 显示 player；移动代码只传入 movement vector，reset/load 回到 idle，动画状态不进入存档。
- 回归测试覆盖资源路径、8 帧 walk count / loop / 8 FPS、stylized robe metadata、上半身非零小幅运动、robe / sleeve / talisman / shadow 参数连续性、固定 frame canvas / feet baseline / centered anchor、body center 与 bounding box spread、首尾及相邻帧 alpha continuity、低 alpha 残留、sprite scale / filtering / z-index、透明 Polygon2D fallback、左右转身、停止及上下移动保留朝向、状态切换不重复 restart、reset/load、journal/optional/save-load 回归和不新增 save fields。
- 将 player 的 clean cutout、stable idle、stylized robe walk 和 facing direction 修复合入 `master`。

---

## 当前开放 PR

### PR #41: game: add shensheng idle animation
- **状态：** Draft PR；Godot GUI manual test 保留给用户。
- **Branch：** `game/shensheng-idle-animation`
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/41
- **基线：** 最新 `origin/master`，包含 PR #39 merge commit `eec4d830eb40d3e159e43f847c028f5cdf0c62ab`。
- 为 `ShenshengCreature` 新增 demo-local `AnimatedSprite2D`，仅包含 6 帧、4 FPS 的循环 `idle`，不新增 creature state machine。
- 视觉设计使用白耳、人面兽吻、猿身、半蹲前倾肩、落地长臂、墨青灰毛发、朱砂纹样和青色眼睛 / 胸纹微光。
- Python 标准库生成器确定性输出横向 `3072×512` RGBA8 atlas 和运动元数据；未调用外部 AI / 网络服务，未引入外部版权素材。
- 所有帧使用 `512×512` canvas、feet-center anchor `(256, 470)`；呼吸、肩部、耳朵、手臂、青光与阴影以小幅参数闭环变化。
- 原 `ShenshengCreature` Polygon2D 保持原位置与交互身份，仅改为透明回退；interaction、save/load、reset、journal、optional state 与 player `IDLE/WALK` 状态机保持不变。
- 自动验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、`git diff --check`、`git diff --stat`。
- atlas reproducibility SHA-256：`C0D4A4A372CCFD1DB82D54CB0B8EF1D093F5C04AB5ECF272320BE10146CA2B13`；metadata reproducibility SHA-256：`3C1C5ECC2EB3AE609FF88BEC895D7019914EE4B18774BBA9D6E7CA2C31F44972`。
- 显式范围检查确认 `AGENTS.md`、`game/project.godot`、Snowhuman Framework、schemas、CI、`minimal_playable_demo.gd` 均未修改；framework 项目专用关键词扫描无匹配。
- Draft PR 已创建；不要自动合并。

---

## 过期 / 关闭 PR

### PR #38: game: add journal keyboard shortcuts and hints
- **状态：** 已关闭、未合并
- **Branch：** `game/journal-keyboard-shortcuts`
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/38
- PR #38 是 PR #37 的过期重复 PR，不应继续开发或合并。

---

## 当前 Demo 状态

- Minimal playable demo 已使用 data-driven optional content。
- 当前有三组 optional content pair。
- Optional content 支持 prompt、interaction、history、completion summary、save/load 和 reset。
- PR #33 的可折叠 optional progress journal 已合并并可用。
- Journal 会显示 optional collectible 和 optional creature / interaction 完成状态。
- 显式 `InteractionHistoryToggleButton` 可折叠 / 展开右侧 journal/history panel 和左侧 live log，并保留 text/history。
- PR #36 已合并：journal 支持 progress counters、compact/detail view toggle、recent completion hint，以及 readability / layout polish。
- PR #36 已根据用户 GUI 手测反馈修复 journal layout overlap：progress 与 history 分区显示，history UI 只显示最近 5 条但不截断内部 history 数据。
- PR #37 已合并：journal 支持 `J` / `V` keyboard shortcuts、可见 shortcut hint 和防 overlap layout，并已完成用户 Godot GUI 手测。
- PR #39 已合并：player 使用同一 silhouette 驱动的 stylized robe walk，并保留 clean cutout、stable idle、`IDLE/WALK` state machine 和 facing direction。
- 当前 `game/shensheng-idle-animation` 分支只为狌狌增加 art-guided idle：6 帧、4 FPS、统一 feet-center anchor，不增加 walk / attack / creature state machine。
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

**Current active PR：** `game: add shensheng idle animation`（PR #41）

**目标：**
- 为 `ShenshengCreature` 增加可见的 demo-local `AnimatedSprite2D` 和单一循环 `idle` 动画。
- 使用确定性 Python 标准库脚本生成 6 帧、4 FPS、`512×512` 单帧 canvas 的透明 atlas。
- 以白耳、人面兽吻、猿身、半蹲前倾肩、长臂、墨青灰毛、朱砂纹与青光建立狌狌的山海异兽辨识度。
- 保持 `(256, 470)` feet-center anchor，使用呼吸、肩部、耳动、臂摆、青光脉冲与阴影收放形成安静闭环。
- 保留原 Polygon2D 的位置与 interaction identity，只将其视觉设为透明 fallback。
- 不增加 walk / attack / creature state machine，不改变 player `IDLE/WALK` 状态机。
- 不改变 interaction、optional state、save fields、save/load、reset、journal 或 data-driven content。
- 不移动 demo-specific 内容到 Snowhuman Framework。

**状态：** Draft PR #41 已创建；本地实现、复现性检查、完整 headless 验证与范围审计已通过。Godot GUI manual test 仍由用户完成；不要自动合并。

**验证：**
- `python tools/validate_data.py` passed
- `python tools/check_framework.py` passed
- `python tools/validate_minimal_demo.py` passed，包含 Godot 4.7 headless import、script check-only 和 save/load regression
- generator 内建检查 passed：6 帧唯一、3–5 FPS、feet baseline、canvas containment、逐参数闭环连续性和相邻帧 normalized alpha delta。
- atlas reproducibility SHA-256：`C0D4A4A372CCFD1DB82D54CB0B8EF1D093F5C04AB5ECF272320BE10146CA2B13`
- metadata reproducibility SHA-256：`3C1C5ECC2EB3AE609FF88BEC895D7019914EE4B18774BBA9D6E7CA2C31F44972`
- `git diff --check` passed；`git diff --stat` ran。
- 显式 Snowhuman Framework keyword scan for `zhuyu|shensheng|zaoyaoshan|祝余|狌狌|招摇山`：no matches。
- `AGENTS.md`、`game/project.godot`、Snowhuman Framework、schemas、CI 和 `minimal_playable_demo.gd` 均未修改。

**下一步：**
- 创建 Draft PR 后，由用户在 Godot GUI 检查狌狌的白耳、人面兽吻、半蹲长臂剪影、透明边缘、idle 闭环与稳定锚点，并复核 interaction、save/load、reset、journal 和 player movement 未回归。

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
