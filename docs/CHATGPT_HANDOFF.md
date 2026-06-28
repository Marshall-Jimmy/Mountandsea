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

### PR #41: game: add shensheng idle animation
- **状态：** 已合并
- **Branch：** `game/shensheng-idle-animation`
- **Merge commit：** a2b1a165dcd36637e4e5e851bb2f18bc6bb057a8
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/41
- 为 `ShenshengCreature` 新增 demo-local `AnimatedSprite2D`，使用 6 帧、4 FPS 的循环 `idle`。
- 视觉设计使用白耳、人面兽吻、猿身、半蹲长臂、墨青灰毛发、朱砂纹样和青色眼睛 / 胸纹微光。
- 保留原 `ShenshengCreature` 的位置与 interaction identity；未新增 walk、attack 或 creature state machine。
- 完整 headless 验证、生成器复现性检查和范围审计通过；合并前的 Godot GUI manual test 未在本文件中记录为已通过。

### PR #42: game: add Zhuyu hunger and knowledge loop
- **状态：** 已合并
- **Branch：** `game/zhuyu-hunger-knowledge-loop`
- **Merge commit：** f071d30894123df3409722b8b612a078af704e0a
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/42
- 增加“饥饿压力 → 发现祝余 → 采集 / 食用祝余 → 图鉴知识解锁 → 饥饿压力缓解”的第一个知识驱动 gameplay loop。
- 饥饿从 `100` 开始，以每秒 `2` 点下降；食用祝余恢复满值，并提供 15 秒“食之不饥”效力。
- 靠近祝余解锁 `appearance` / `type`，食用后解锁 `effect`。
- save version 更新为 `2`，保存 `world.zhuyu_consumed`、`survival.*` 和 `knowledge.zhuyu`，并兼容 legacy save。
- 完整 headless regression 和范围审计通过；Godot GUI manual test 未在本文件中记录为已通过。

### PR #43: game: add Migu navigation knowledge loop
- **状态：** 已合并
- **Branch：** `game/migu-navigation-knowledge-loop`
- **Merge commit：** 2933b80760961875e1269ecf71ee83bca5e7311b
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/43
- **目标：** 增加“远离 origin → 迷失压力 → 发现 / 采集 / 佩戴迷穀 → 解锁佩之不迷 → 获得归向指引”的第二个知识驱动 gameplay loop。
- 复用现有 data-driven optional `migu_branch`，不创建第二个迷穀对象，也不改变 optional state 核心结构。
- 出生点作为 demo-local origin；距离超过 `180 px` 显示方向感不稳，超过 `360 px` 显示方向感模糊。
- 未佩戴迷穀时不显示精确方向；佩戴后实时显示 8 方向和距起点距离，接近 origin 时显示“已接近起点”。
- 靠近迷穀解锁 `appearance` / `type`，佩戴后解锁 `effect`，反馈为“佩之不迷”。
- save version 更新为 `3`，新增 `navigation.migu_equipped`、`navigation.origin_position` 和 `knowledge.migu`；保留 PR #42 的 `survival.*`、`knowledge.zhuyu` 与 `world.zhuyu_consumed`。
- 右侧脚本 HUD 位于 hunger HUD 与 journal toggle 之间；打开 Demo 菜单时隐藏，不遮挡 optional journal。
- 回归测试覆盖 origin、两级迷失压力、发现 / 采集 / 防重复 / 佩戴、8 方向、距离更新、原点零向量、save/load、legacy 默认值，以及 hunger、祝余、journal、J / V 和动画回归。
- 不新增美术，不修改 `.tscn`，不做完整背包、装备、地图、minimap、寻路或图鉴 UI。
- 合并前自动验证已通过：`python tools/validate_minimal_demo.py`（包含 data、framework、Godot import、script check-only、save/load regression 和 framework keyword scan）。

---

## 当前已完成里程碑（再续）

### PR #44: game: add demo knowledge codex and HUD layout polish
- **状态：** 已合并
- **Branch：** `game/demo-knowledge-codex-hud-polish`
- **Merge commit：** ab4d429adc689bf1ea52cc413d033e438855ac90
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/44
- **目标：** 增加 demo-local Knowledge Codex，并整理 HUD / live log 布局以减少画面遮挡。
- 图鉴仅显示祝余与迷穀，每项包含 `appearance`、`type`、`effect` 三个槽位；未解锁槽位显示 `???`。
- 使用 `K` 打开 / 关闭图鉴；不新增 Input Map action，不改变 `J` / `V` journal 状态，也不写入 save data。
- 图鉴只读取现有 `knowledge.zhuyu` 和 `knowledge.migu`，save/load 后同步显示；legacy save 缺少 knowledge 时保持 unknown。
- HUD 调整为左上生存状态、右上 navigation、右侧 optional journal、左下最近 3 条 live log、底部中间 prompt；live log 保留内部历史并启用固定尺寸、换行和 clipping。
- `game/project.godot` 原先未显式配置 window / viewport 尺寸；本 PR 仅增加 `viewport_width`、`viewport_height`、`window_width_override`、`window_height_override` 四项，统一设为 `1440 × 810`（16:9）。
- 不新增美术，不修改 `.tscn`，不实现完整全局图鉴或新 gameplay loop。
- 完整自动验证和范围审计已通过；合并前的 Godot GUI manual test 未在本文件中记录为已通过。

---

## 当前开放 PR

### PR #45: game: add campfire cooking loop and Migu auto-equip
- **状态：** Draft PR；pending GUI manual test。
- **Branch：** `game/campfire-cooking-migu-auto-equip`
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/45
- **目标：** 在同一个小范围 gameplay / UX PR 中完成 Migu auto-equip 与 campfire cooking preparation loop。
- 迷穀采集后自动设置 `navigation.migu_equipped = true`，立即解锁 `knowledge.migu.effect` 并启用归向 HUD；原迷穀位置不再提供二次佩戴交互。
- 新增 demo-local primitive 篝火，不使用新美术；祝余可直接食用获得 15 秒短效“不饥”，也可烹饪成熟祝余。
- 熟祝余食用后恢复 hunger，并提供 45 秒长效“不饥”；效力结束后 hunger 继续正常下降。
- 祝余图鉴新增 `cooking` 槽位；首次成功烹饪后解锁“熟祝余：食之不饥更久”。
- save version 更新为 `4`；raw 祝余继续复用 `inventory.zhuyu_leaf`，新增 `world.cooked_zhuyu_count` 与 `knowledge.zhuyu.cooking`，并保持 legacy save 缺失字段时安全默认。
- 不新增完整背包、装备、烹饪 UI、燃料、火候或多个配方；不修改美术、`game/project.godot` 或 Snowhuman Framework。
- 自动验证已通过：`python tools/validate_minimal_demo.py`（包含 data、framework、Godot import、script check-only、save/load regression 与 framework keyword scan）。
- Godot GUI manual test 保留给用户；本 PR 不允许自动合并。

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
- PR #41 已合并：狌狌使用 6 帧、4 FPS、统一 feet-center anchor 的 art-guided idle；未增加 walk / attack / creature state machine。
- PR #42 已合并：demo 包含饥饿、祝余采集 / 食用、`appearance` / `type` / `effect` 知识解锁和右上角生存 HUD。
- 祝余食用后恢复满饥饿并提供 15 秒“食之不饥”效力；状态支持 reset、save/load 与 legacy save 默认值。
- PR #43 已合并：demo 复用现有迷穀 optional collectible，增加迷失压力、采集后佩戴、`佩之不迷` 知识和实时 origin 归向 HUD。
- 迷穀未佩戴时只显示方向感压力；佩戴后显示 8 方向、距离或“已接近起点”。
- PR #44 已合并：demo-local 图鉴使用 `K` 查看祝余 / 迷穀 knowledge，live log、prompt、生存、navigation 与 optional journal 已分区；window / viewport 显式配置为 `1440 × 810`。
- 当前 `game/campfire-cooking-migu-auto-equip` 分支让迷穀采集后自动佩戴并立即启用归向 HUD；已采集迷穀不再是原地佩戴交互点。
- 当前分支新增 demo-local primitive 篝火与“生祝余 → 熟祝余 → 45 秒长效不饥”准备循环；祝余图鉴新增 `cooking` 槽位。
- 当前分支 save version 为 `4`，raw 祝余沿用 `inventory.zhuyu_leaf`，熟祝余使用 `world.cooked_zhuyu_count`，并兼容缺少新字段的 legacy save。
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

**Current active PR：** `game: add campfire cooking loop and Migu auto-equip`（PR #45）

**目标：**
- 迷穀采集后自动佩戴，立即解锁“佩之不迷”并显示归向 HUD。
- 在 `minimal_playable_demo` 内增加 primitive 篝火，让生祝余可烹饪成熟祝余。
- 生祝余保持 15 秒短效“不饥”；熟祝余提供 45 秒长效“不饥”。
- 祝余图鉴新增 `knowledge.zhuyu.cooking` 槽位，并保存 cooked count、satiety 与 cooking knowledge。
- 不新增完整背包 / 装备 / 烹饪系统，不新增美术。
- 不移动 demo-specific 内容到 Snowhuman Framework。

**状态：** Draft PR #45 已创建；本地实现和 headless regression 已通过。Godot GUI manual test 仍由用户完成；不要自动合并。

**验证：**
- `python tools/validate_data.py` passed
- `python tools/check_framework.py` passed
- `python tools/validate_minimal_demo.py` passed，包含 Godot 4.7 headless import、script check-only 和 save/load regression
- `git diff --check` passed；最终 `git diff --stat` 将在发布前复核。
- 显式 Snowhuman Framework keyword scan for `zhuyu|shensheng|zaoyaoshan|migu|祝余|狌狌|招摇山|迷穀|迷榖`：no matches。
- 未修改 `AGENTS.md`、`game/project.godot`、Snowhuman Framework、schemas、CI、tooling 或美术资产；`.tscn` 只新增 demo-local primitive 篝火。

**下一步：**
- 创建 Draft PR 后，由用户在 Godot GUI 检查迷穀采集后自动佩戴、归向 HUD 即时出现、篝火位置与 prompt、生 / 熟祝余选择、45 秒熟祝余效力、K 图鉴 cooking 槽位，并复核 J / V / K、player animation 和 shensheng idle 未回归。

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
