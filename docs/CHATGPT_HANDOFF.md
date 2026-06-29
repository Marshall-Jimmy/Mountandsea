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

### PR #45: game: add campfire cooking loop and Migu auto-equip
- **状态：** 已合并
- **Branch：** `game/campfire-cooking-migu-auto-equip`
- **Merge commit：** 301f31d3f77f0f11d2ed4b547c285ba40a739d34
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/45
- **目标：** 在同一个小范围 gameplay / UX PR 中完成 Migu auto-equip 与 campfire cooking preparation loop。
- 迷穀采集后自动设置 `navigation.migu_equipped = true`，立即解锁 `knowledge.migu.effect` 并启用归向 HUD；原迷穀位置不再提供二次佩戴交互。
- 新增 demo-local primitive 篝火，不使用新美术；祝余可直接食用获得 15 秒短效“不饥”，也可烹饪成熟祝余。
- 熟祝余食用后恢复 hunger，并提供 45 秒长效“不饥”；效力结束后 hunger 继续正常下降。
- 祝余图鉴新增 `cooking` 槽位；首次成功烹饪后解锁“熟祝余：食之不饥更久”。
- save version 更新为 `4`；raw 祝余继续复用 `inventory.zhuyu_leaf`，新增 `world.cooked_zhuyu_count` 与 `knowledge.zhuyu.cooking`，并保持 legacy save 缺失字段时安全默认。
- 不新增完整背包、装备、烹饪 UI、燃料、火候或多个配方；不修改美术、`game/project.godot` 或 Snowhuman Framework。
- 合并前自动验证已通过；Godot GUI manual test 未在本文件中记录为已通过。

### PR #46: game: add data-driven world map foundation
- **状态：** 已合并
- **Branch：** `game/world-map-foundation`
- **Merge commit：** 33c84c83a2111eee19d5ad96e34ad82ec264daff
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/46
- **目标：** 在 Mountandsea 游戏层建立 data-driven world map foundation，为后续随机出生、区域资源、异兽刷新、远征和地图生成提供可测试基础。
- 新增 `world_map.json`、`south_mountain` region、spawn rules、resource rules 与 encounter rules；当前 MVP 覆盖 `south_mountain / zhaoyao`、祝余、迷穀、狌狌和 `zhaoyao_village` 出生候选点。
- 新增游戏层 deterministic seeded RNG、weighted table、world map / region 轻量模型与 world generator。
- generator 同时支持从 `res://` 文件加载和从已解析 Dictionary 生成；结果包含 seed、starting region/mountain、player spawn 和各 mountain 的 resources / encounters，可 JSON 序列化且同 seed 同输入完全一致。
- 新增独立 headless world generation regression，并扩展 `tools/validate_data.py` 的 world 字段和跨文件引用校验。
- 未修改 Snowhuman Framework；未实现正式地图渲染或完整出生系统；未修改 demo gameplay loop、scene 或 save fields。
- 自动验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、world generator check-only、world generation regression、`git diff --check` 和范围审计。
- 本 PR 不接入正式场景，Godot GUI manual test 不是核心验证；仍保留给用户，且未标记为已通过。本 PR 不允许自动合并。

---

## 当前已完成里程碑（world generation）

### PR #47: game: add world generation debug view
- **状态：** 已合并
- **Branch：** `game/world-generation-debug-view`
- **Merge commit：** 98241ee4d02dd26b9236b4ab83e5da8135404b1d
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/47
- **目标：** 新增独立的 demo-local / game-layer world generation debug scene，用于查看 PR #46 world generator 的结构化输出。
- debug view 显示 seed、starting region、starting mountain、player spawn、resources、encounters 与紧凑的 generation result summary。
- 默认 seed 从 `world_map.json` 的 `default_seed` 读取；按钮可切换 default、`42`、`20260629`，并可重复生成当前 seed。
- generation 或 world data 加载失败时，主 `RichTextLabel` 显示明确的 `World generation failed` 错误摘要，不静默失败。
- 扩展独立 headless world generation regression，覆盖摘要字段、三个 seed、同 seed 稳定性、数据文件不变、scene 实例化、按钮节点和错误显示。
- 未修改 Snowhuman Framework、`game/project.godot`、美术素材、`minimal_playable_demo` gameplay 或 save fields。
- 未接入正式地图渲染、随机出生系统、资源实体落地或异兽实体刷新。
- 自动验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、debug script check-only、world generation regression、`git diff --check` 和范围审计。
- Godot GUI manual test reserved for user，未标记为已通过。本 PR 不允许自动合并。

---

## 当前开放 PR

### PR #48: game: connect world generation to demo content placement
- **状态：** Draft / pending Godot GUI manual test。
- **Branch：** `game/world-generated-demo-placement`
- **链接：** https://github.com/Marshall-Jimmy/Mountandsea/pull/48
- **目标：** 将 PR #46 / #47 的 deterministic world generation result 小范围接入 `minimal_playable_demo`，由 seed 驱动祝余、迷穀、狌狌的数量与固定 placement slot 选择。
- 默认从 `world_map.json` 读取 seed `20260628`；当前结果为 `zhuyu: 3`、`migu: 2`、`shensheng: 3`。
- 每类内容使用 demo-local 固定 slots，并用 seed 对 slot 顺序做确定性选择；同 seed 的布局稳定，不同 seed 可以选择不同 slots。
- generated count 超过可用 slots 时会安全 clamp 并输出 warning；count 为 `0` 时不创建对应实例。
- 祝余和迷穀使用稳定 instance id（如 `zhuyu_0`、`migu_0`）记录逐实例采集状态；多个祝余分别增加 `inventory.zhuyu_leaf`，多个迷穀分别记录采集，首次迷穀采集继续自动佩戴并解锁 `knowledge.migu.effect`。
- 狌狌复用 PR #41 的 idle sprite setup；所有 generated instances 都有稳定 interactable id，主流程可通过任意一只完成物种发现，完成后仍可重复观察，但不会重复写入图鉴或完成记录。
- demo save version 更新为 `5`；新增 `world.generation_seed`、`world.generated_content` 和 `world.collected_instances`，保留 `world.pickup_collected`、`world.zhuyu_consumed`、`inventory.zhuyu_leaf`、`world.cooked_zhuyu_count`、optional journal 与 knowledge 字段。
- legacy save 缺少 generation 字段时使用 default seed 重新生成布局，并把旧 `pickup_collected` / `migu_collected` 状态迁移到 `zhuyu_0` / `migu_0`。
- 回归覆盖 default / different seed、count → instance 映射、zero count、slot clamp、stable ids、reset、祝余 / 迷穀多实例、狌狌 idle 与多实例互动、save/load、legacy migration，以及 hunger、cooking、navigation、K / J / V、optional journal 和 player animation。
- 用户首次 Godot GUI 手测发现实际按 `E` 时持续显示 `找不到可交互的 generated zhuyu instance`；根因是 `_generated_instance_index()` 把 instance id 后缀截成字符串后传给只接受数值 Variant 的 helper，导致真实 `_try_interact()` 路由恒定得到 `-1`，而原回归直接调用 callback 未覆盖该路径。
- 修复改为严格校验并解析 instance id 的数字字符串后缀；新增从玩家真实位置调用 `_update_prompt()` / `_try_interact()` 的祝余与迷穀回归，确认采集、库存、逐实例状态和迷穀 auto-equip 均能通过实际路由。
- 用户后续 GUI 反馈指出只有一只狌狌可互动，且主流程推进后采集的祝余无法烹饪；已将所有生成狌狌注册为独立 interactable，同时保持物种级图鉴状态；篝火交互改为按当前库存烹饪生祝余或食用熟祝余，不再受首次 `EAT_ZHUYU` 步骤和 `zhuyu_consumed` 锁死。
- 新增 `shensheng_1` 完成主流程、`shensheng_2` 完成后重复观察，以及 Demo 完成后采集 `zhuyu_1`、烹饪、save/load、食用熟祝余且不重播主流程的回归覆盖。
- 自动验证已通过：`python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py`、`godot --headless --path game --script res://tests/world/world_generation_regression.gd`、`git diff --check` 和范围审计；clamp regression 会按设计输出三条 warning。
- 不做完整地图渲染、随机出生系统、chunk、minimap、大地图 UI、正式资源刷新或完整 creature system；不修改 Snowhuman Framework、`game/project.godot`、world data、美术素材、schemas、CI 或 tooling。
- 修复后的 Godot GUI manual re-test reserved for user，未标记为已通过。本 PR 不允许自动合并。

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
- PR #45 已合并：迷穀采集后自动佩戴并立即启用归向 HUD；已采集迷穀不再是原地佩戴交互点。
- PR #45 已合并：demo-local primitive 篝火提供“生祝余 → 熟祝余 → 45 秒长效不饥”准备循环；祝余图鉴新增 `cooking` 槽位。
- 当前开放 PR 将 demo save version 更新为 `5`；raw 祝余沿用 `inventory.zhuyu_leaf`，熟祝余使用 `world.cooked_zhuyu_count`，新增 `world.generation_seed`、`world.generated_content`、`world.collected_instances`，并兼容缺少 generation 字段的 legacy save。
- PR #46 的 world map foundation 与 PR #47 的 debug view 已合并；当前开放 PR 仅把生成 count 和 seed-driven 固定 slot 选择接入 `minimal_playable_demo`，不替换地图或实现正式出生系统。
- 所有狌狌 generated instances 均保持 PR #41 idle animation 并可互动；图鉴发现与主流程完成仍是物种级状态，不重复累计。
- 后续采集的祝余仍可在篝火逐个烹饪；熟祝余可继续食用并刷新长效 satiety，不会回退或重播已经完成的主流程。
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

**Current active PR：** `game: connect world generation to demo content placement`（PR #48）

**目标：**
- 使用 `world_map.json` default seed 调用现有 generator，把祝余、迷穀、狌狌 count 映射到 demo-local 固定 placement slots。
- 支持祝余 / 迷穀逐实例采集与 save/load；首次迷穀采集继续 auto-equip。
- 生成多个狌狌时，每个实例都可观察；首次有效观察完成物种发现，其余实例提供可重复反馈。
- 不修改 Snowhuman Framework，不接入完整地图渲染、随机出生或完整 creature system。

**状态：** Draft PR #48 已创建且 GitHub 显示可合并；本地实现、扩展后的 minimal demo regression、标准验证和范围审计已通过。Godot GUI manual test 仍由用户完成；不要自动合并。

**验证：**
- `godot --headless --path game --check-only --script res://scenes/demo/minimal_playable_demo.gd` passed。
- `godot --headless --path game --check-only --script res://tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd` passed。
- `godot --headless --path game --script res://tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd` passed。
- `python tools/validate_data.py`、`python tools/check_framework.py`、`python tools/validate_minimal_demo.py` passed。
- `godot --headless --path game --script res://tests/world/world_generation_regression.gd` passed。
- `git diff --check` passed；`git diff --stat` 已运行。
- 显式 Snowhuman Framework keyword scan 无匹配；未修改 `AGENTS.md`、`game/project.godot`、Snowhuman Framework、schemas、CI、tooling、world data 或美术素材。

**下一步：**
- 用户在 Godot GUI 中检查默认 seed 的多实例位置、逐实例采集、篝火 / navigation / journal 回归；GUI 手测不得在用户确认前标记为通过。
- 后续 PR 再考虑正式地图渲染或出生系统；不要在当前 placement PR 中扩展。

---

## 常用相关文件

- `game/scenes/demo/minimal_playable_demo.gd`
- `game/scenes/demo/minimal_playable_demo.tscn`
- `game/tests/minimal_playable_demo/minimal_playable_demo_save_load_regression.gd`
- `game/scenes/debug/world_generation_debug.gd`
- `game/scenes/debug/world_generation_debug.tscn`
- `game/data/world/world_map.json`
- `game/data/world/regions/south_mountain.json`
- `game/scripts/world/world_generator.gd`
- `game/tests/world/world_generation_regression.gd`
- `tools/validate_minimal_demo.py`
- `tools/validate_data.py`
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
