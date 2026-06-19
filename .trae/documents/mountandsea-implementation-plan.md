# 《山海经·Mountandsea》实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从纯设计文档仓库转型为可运行的 Godot 4.x 游戏项目，短期交付招摇山 30 分钟可玩 Demo，长线架构支持完整山海经开放世界。

**Architecture:** 数据驱动设计——JSON 数据表承载全部游戏内容（物品/异兽/科技树/山系/配方），游戏代码只读数据不硬编码。Chunk 系统数据层与渲染层解耦（MVP 用 TileMapLayer，长线可迁移自绘 shader）。图鉴/传承/科技树系统从第一天起定义完整接口，MVP 只启用子集。

**Tech Stack:** Godot 4.6.1 + GDScript + JSON 数据表 + TileMapLayer（MVP）/ 自绘 shader（长线）

---

## 全局架构决策

| 项目 | 决策 | 理由 |
|------|------|------|
| 引擎 | Godot 4.6.1 stable | 最新稳定版，TileMapLayer 成熟 |
| 语言 | GDScript | 引擎调研所有 Godot 仓库均用 GDScript，社区生态好 |
| 渲染（MVP） | TileMapLayer + TileSet | 快速出原型，引擎原生 autotile/碰撞 |
| 渲染（长线） | 自绘 shader（参考 Substrata） | per-tile 特效、可编辑地形、大世界性能 |
| PCG | MVP 手写噪声，后期 Gaea addon | 避免前期引入复杂依赖 |
| 数据格式 | JSON（运行时加载为自定义 Resource） | 数据驱动，策划可编辑 |
| 存档格式 | JSON 元数据 + 二进制 chunk | 人类可读 + 紧凑地形 |

---

## Godot 项目结构

```
d:\Mountandsea\game/
├── project.godot
├── data/                          # JSON 数据表
│   ├── items/items.json           # 物品总表
│   ├── creatures/creatures.json   # 异兽总表
│   ├── tech_tree/tech_nodes.json  # 科技节点
│   ├── recipes/cooking.json       # 烹饪配方
│   ├── recipes/crafting.json      # 制作配方
│   ├── bestiary/bestiary_slots.json # 图鉴槽位定义
│   ├── mountains/nanshan/*.json   # 各山配置
│   └── constants/game_balance.json # 数值常量
├── scenes/
│   ├── main/main.tscn             # 入口
│   ├── world/chunk.tscn           # Chunk 场景
│   ├── world/world_manager.tscn   # 世界管理器
│   ├── player/player.tscn         # 玩家
│   ├── player/player_ui.tscn      # HUD
│   ├── entities/creature/*.tscn   # 异兽
│   ├── entities/gatherable/*.tscn  # 采集物
│   ├── ui/bestiary_ui.tscn        # 图鉴
│   ├── ui/inventory_ui.tscn       # 背包
│   ├── ui/death_ui.tscn           # 死亡/传承
│   └── menus/title_screen.tscn    # 标题
├── scripts/
│   ├── autoload/                  # 单例
│   │   ├── data_loader.gd         # JSON 加载器
│   │   ├── signal_bus.gd          # 全局信号
│   │   ├── game_state.gd          # 运行时状态
│   │   ├── save_manager.gd        # 存档
│   │   └── constants.gd           # 枚举/常量
│   ├── resources/                 # 自定义 Resource
│   │   ├── item_resource.gd
│   │   ├── creature_resource.gd
│   │   ├── tech_node_resource.gd
│   │   └── recipe_resource.gd
│   ├── systems/
│   │   ├── chunk/                 # Chunk 系统
│   │   ├── bestiary/              # 图鉴
│   │   ├── survival/              # 生存
│   │   ├── tech_tree/             # 科技树
│   │   ├── inheritance/           # 传承
│   │   └── interaction/           # 交互
│   ├── entities/
│   │   ├── player/                # 玩家
│   │   └── creatures/             # 异兽
│   └── ui/                        # UI 控制器
├── assets/                        # 美术（占位→正式）
└── tests/                         # 测试场景
```

---

## Phase 0：基础设施

**目标：** 搭建 Godot 项目骨架 + 数据加载管线 + JSON 数据表，使项目可运行空白世界。

### Task 0.1: Godot 项目初始化

**Files:**
- Create: `d:\Mountandsea\game\project.godot`
- Create: `d:\Mountandsea\game\.gitignore`

- [ ] **Step 1: 创建 Godot 4.6.1 项目**

```ini
# project.godot 核心配置
[application]
config/name="山海经·Mountandsea"
run/main_scene="res://scenes/main/main.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"

[physics]
2d/run_on_separate_thread=true
```

- [ ] **Step 2: 创建 .gitignore**

```
# Godot
.godot/
*.import
export_presets.cfg

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
```

- [ ] **Step 3: 创建 main.tscn 入口场景（空白 Node2D）**

- [ ] **Step 4: 验证项目可在 Godot 编辑器中打开无报错**

- [ ] **Step 5: Commit**

```
git add game/
git commit -m "init: 创建 Godot 4.6.1 项目骨架"
```

### Task 0.2: 数据加载管线

**Files:**
- Create: `d:\Mountandsea\game\scripts\autoload\data_loader.gd`
- Create: `d:\Mountandsea\game\scripts\autoload\signal_bus.gd`
- Create: `d:\Mountandsea\game\scripts\autoload\constants.gd`
- Create: `d:\Mountandsea\game\scripts\autoload\game_state.gd`
- Create: `d:\Mountandsea\game\scripts\autoload\save_manager.gd`
- Modify: `d:\Mountandsea\game\project.godot` (注册 autoload)

- [ ] **Step 1: 创建 constants.gd（枚举与常量）**

```gdscript
# constants.gd
class_name Constants

enum ItemType { HERB, TREE, CREATURE_PRODUCT, MINERAL, FOOD, EQUIPMENT, MATERIAL }
enum Rarity { COMMON, UNCOMMON, RARE, PRECIOUS, LEGENDARY }
enum EffectType { SATIATE, BUFF_SPEED, EQUIP_PASSIVE, CURE, POISON }
enum KnowledgeState { UNKNOWN, GUESSED, KNOWN, MASTERED }
enum TechBranch { SURVIVAL, MEDICINE, CULTIVATION, SACRIFICE, CRAFTING, FARMING }
```

- [ ] **Step 2: 创建 signal_bus.gd（全局信号）**

```gdscript
# signal_bus.gd
extends Node

signal player_died(character_data: Dictionary)
signal inheritance_started(new_character: Dictionary)
signal bestiary_slot_unlocked(entity_id: String, slot_id: String)
signal tech_unlocked(tech_id: String)
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)
signal hunger_changed(value: float)
signal stamina_changed(value: float)
signal hp_changed(value: float)
signal item_gathered(item_id: String, amount: int)
signal item_consumed(item_id: String)
```

- [ ] **Step 3: 创建 data_loader.gd（JSON 加载器）**

```gdscript
# data_loader.gd
extends Node

var _items: Dictionary = {}
var _creatures: Dictionary = {}
var _tech_nodes: Dictionary = {}
var _recipes: Dictionary = {}
var _balance: Dictionary = {}

func _ready() -> void:
    _load_all_data()

func _load_all_data() -> void:
    _load_json("res://data/items/items.json", _items, "id")
    _load_json("res://data/creatures/creatures.json", _creatures, "id")
    _load_json("res://data/tech_tree/tech_nodes.json", _tech_nodes, "id")
    _load_json("res://data/recipes/cooking.json", _recipes, "id")
    var balance_file = FileAccess.open("res://data/constants/game_balance.json", FileAccess.READ)
    if balance_file:
        _balance = JSON.parse_string(balance_file.get_as_text())

func _load_json(path: String, dict: Dictionary, key_field: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_error("DataLoader: 无法加载 %s" % path)
        return
    var data = JSON.parse_string(file.get_as_text())
    if data and data.has("items"):
        for item in data["items"]:
            dict[item[key_field]] = item
    elif data and data.has("creatures"):
        for item in data["creatures"]:
            dict[item[key_field]] = item

func get_item(id: String) -> Dictionary:
    return _items.get(id, {})

func get_creature(id: String) -> Dictionary:
    return _creatures.get(id, {})

func get_tech_node(id: String) -> Dictionary:
    return _tech_nodes.get(id, {})
```

- [ ] **Step 4: 创建 game_state.gd 和 save_manager.gd（骨架，Phase 1 填充）**

- [ ] **Step 5: 在 project.godot 中注册 autoload**

```ini
[autoload]
DataLoader="*res://scripts/autoload/data_loader.gd"
SignalBus="*res://scripts/autoload/signal_bus.gd"
Constants="*res://scripts/autoload/constants.gd"
GameState="*res://scripts/autoload/game_state.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
```

- [ ] **Step 6: Commit**

```
git commit -m "feat: 数据加载管线（DataLoader/SignalBus/Constants）"
```

### Task 0.3: JSON 数据表（招摇山 MVP 子集）

**Files:**
- Create: `d:\Mountandsea\game\data\items\items.json`
- Create: `d:\Mountandsea\game\data\creatures\creatures.json`
- Create: `d:\Mountandsea\game\data\tech_tree\tech_nodes.json`
- Create: `d:\Mountandsea\game\data\recipes\cooking.json`
- Create: `d:\Mountandsea\game\data\bestiary\bestiary_slots.json`
- Create: `d:\Mountandsea\game\data\constants\game_balance.json`

- [ ] **Step 1: 创建 items.json（招摇山 6 项物品）**

从附录1提取：祝余、迷榖、狌狌生肉排、熟狌狌肉、育沛、蝮虫毒牙。每项含 id/name/type/rarity/effects/bestiary_slots/source_text。Schema 设计要能承载全部 18 卷。

- [ ] **Step 2: 创建 creatures.json（2 种异兽）**

狌狌（wander_then_flee，掉落生肉排）+ 蝮虫（ambush_aggressive，带毒，掉落毒牙）。

- [ ] **Step 3: 创建 tech_nodes.json（3 个 MVP 节点 + 完整分支定义）**

采集（起始）、狩猎（前置：采集）、生火（前置：采集）。标记 `mvp: true`。同时定义全部 6 个分支和完整节点列表（标记 `mvp: false`），数据表从第一天起完整。

- [ ] **Step 4: 创建 cooking.json（2 个配方）**

熟祝余（祝余→篝火→熟祝余，饱食×4）、熟狌狌肉（生肉排→篝火→熟肉，速度×4）。

- [ ] **Step 5: 创建 bestiary_slots.json（7 槽位完整定义）**

appearance/type/effect/cooking/location/rarity/note。MVP 只启用前 3 个。

- [ ] **Step 6: 创建 game_balance.json（MVP 数值）**

生存数值（hp/hunger/stamina 衰减率）、chunk 参数（size=32, render_distance=1）、天赋范围、传承变异概率。

- [ ] **Step 7: Commit**

```
git commit -m "data: 招摇山 MVP 数据表（物品/异兽/科技树/配方/图鉴/数值）"
```

### Task 0.4: 文档更新（C++ → Godot）

**Files:**
- Modify: `d:\Mountandsea\docs\山海经游戏设定集.md` 第 16 行
- Modify: `d:\Mountandsea\README.md` 技术选型章节

- [ ] **Step 1: 设定集「开发语言：C++」→「开发语言：GDScript（Godot 4.6.1）」**

- [ ] **Step 2: README 技术选型章节补充 Godot 4.6.1 确认和 game/ 目录说明**

- [ ] **Step 3: Commit**

```
git commit -m "docs: 统一技术栈为 Godot 4.6.1 + GDScript"
```

### Phase 0 验收标准

- [ ] Godot 项目可打开，显示空白场景无报错
- [ ] DataLoader 加载所有 JSON，`get_item("zhuyu")` 返回正确数据
- [ ] SignalBus 所有信号可连接/发射
- [ ] 设定集 C++ 引用已更新
- [ ] JSON schema 可承载附录1 全部物品（结构验证）

---

## Phase 1：MVP Demo（招摇山 30 分钟可玩）

**目标：** 实现核心循环：随机出生 → 探索招摇山 → 采集/狩猎 → 生火烹饪 → 解锁图鉴 → 遭遇危险 → 死亡/传承。

### Task 1.1: Chunk 系统（3×3 地图）

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\chunk\chunk_manager.gd`
- Create: `d:\Mountandsea\game\scripts\systems\chunk\chunk_generator.gd`
- Create: `d:\Mountandsea\game\scripts\systems\chunk\chunk_data.gd`
- Create: `d:\Mountandsea\game\scripts\systems\chunk\chunk_spawner.gd`
- Create: `d:\Mountandsea\game\scenes\world\chunk.tscn`
- Create: `d:\Mountandsea\game\scenes\world\world_manager.tscn`
- Create: `d:\Mountandsea\game\assets\tilesets\overworld_tileset.tres`

- [ ] **Step 1: 创建 overworld_tileset.tres（占位瓦片集）**

用彩色方块创建 grass/water/stone/sand/forest 5 种地形瓦片。

- [ ] **Step 2: 创建 chunk.tscn（TileMapLayer + Node2D 容器）**

- [ ] **Step 3: 实现 chunk_generator.gd**

用 FastNoiseLite 生成招摇山地形：
- 西侧海洋（height < 0.3 → water）
- 中央山地/森林（0.3-0.7 → grass/forest）
- 高处石头（> 0.7 → stone）
- 固定 seed 保证可复现

- [ ] **Step 4: 实现 chunk_manager.gd**

MVP 简化：启动时一次性生成 3×3=9 个 chunk，全部常驻，无加载/卸载。

- [ ] **Step 5: 实现 chunk_spawner.gd**

在 chunk 内按 biome 规则放置采集物（祝余/迷榖/育沛）和异兽（狌狌/蝮虫）。

- [ ] **Step 6: Commit**

```
git commit -m "feat: Chunk 系统（3×3 招摇山地形生成）"
```

### Task 1.2: 玩家系统

**Files:**
- Create: `d:\Mountandsea\game\scenes\player\player.tscn`
- Create: `d:\Mountandsea\game\scripts\entities\player\player_controller.gd`
- Create: `d:\Mountandsea\game\scripts\entities\player\player_stats.gd`
- Create: `d:\Mountandsea\game\scripts\entities\player\player_inventory.gd`
- Create: `d:\Mountandsea\game\scenes\player\player_ui.tscn`

- [ ] **Step 1: 创建 player.tscn（CharacterBody2D + CollisionShape2D + Sprite2D）**

- [ ] **Step 2: 实现 player_controller.gd（8 方向移动 + 交互键 E）**

- [ ] **Step 3: 实现 player_stats.gd（hp/hunger/stamina，连接 SignalBus）**

- [ ] **Step 4: 实现 player_inventory.gd（10 格背包）**

- [ ] **Step 5: 创建 player_ui.tscn（HUD：生命条/饥饿条/体力条）**

- [ ] **Step 6: Commit**

```
git commit -m "feat: 玩家系统（移动/属性/背包/HUD）"
```

### Task 1.3: 交互与采集系统

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\interaction\interaction_manager.gd`
- Create: `d:\Mountandsea\game\scripts\systems\interaction\gatherable_component.gd`
- Create: `d:\Mountandsea\game\scenes\entities\gatherable\base_gatherable.tscn`
- Create: `d:\Mountandsea\game\scenes\entities\gatherable\zhuyu.tscn`
- Create: `d:\Mountandsea\game\scenes\entities\gatherable\migu.tscn`
- Create: `d:\Mountandsea\game\scenes\entities\interactive\campfire.tscn`

- [ ] **Step 1: 实现 interaction_manager.gd（Area2D 检测 + 交互提示）**

- [ ] **Step 2: 实现 gatherable_component.gd（采集逻辑 + 掉落物品）**

- [ ] **Step 3: 创建采集物场景（祝余/迷榖）**

- [ ] **Step 4: 创建篝火场景（烹饪交互）**

- [ ] **Step 5: Commit**

```
git commit -m "feat: 交互与采集系统（祝余/迷榖/篝火）"
```

### Task 1.4: 异兽 AI

**Files:**
- Create: `d:\Mountandsea\game\scripts\entities\creatures\base_creature.gd`
- Create: `d:\Mountandsea\game\scripts\entities\creatures\creature_ai.gd`
- Create: `d:\Mountandsea\game\scripts\entities\creatures\creature_loot.gd`
- Create: `d:\Mountandsea\game\scenes\entities\creature\base_creature.tscn`
- Create: `d:\Mountandsea\game\scenes\entities\creature\xingxing.tscn`
- Create: `d:\Mountandsea\game\scenes\entities\creature\fuchong.tscn`

- [ ] **Step 1: 实现 base_creature.gd（CharacterBody2D + 属性 + 状态机）**

- [ ] **Step 2: 实现 creature_ai.gd（idle/wander/chase/flee/attack 状态）**

- [ ] **Step 3: 实现狌狌（wander_then_flee）和蝮虫（ambush_aggressive + 毒）**

- [ ] **Step 4: Commit**

```
git commit -m "feat: 异兽 AI（狌狌/蝮虫）"
```

### Task 1.5: 图鉴系统（3 槽位）

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\bestiary\bestiary_manager.gd`
- Create: `d:\Mountandsea\game\scenes\ui\bestiary_ui.tscn`
- Create: `d:\Mountandsea\game\scripts\ui\bestiary_ui_controller.gd`

- [ ] **Step 1: 实现 bestiary_manager.gd**

维护 `Dictionary<String, Dictionary<String, bool>>`，记录每个实体每个槽位是否解锁。采集时解锁 appearance+type，使用时解锁 effect。

- [ ] **Step 2: 创建 bestiary_ui.tscn（显示已解锁槽位，锁定槽位显示???）**

- [ ] **Step 3: 连接 SignalBus.bestiary_slot_unlocked**

- [ ] **Step 4: Commit**

```
git commit -m "feat: 图鉴系统（3 槽位 MVP）"
```

### Task 1.6: 生存系统

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\survival\hunger_system.gd`
- Create: `d:\Mountandsea\game\scripts\systems\survival\stamina_system.gd`
- Create: `d:\Mountandsea\game\scripts\systems\survival\health_system.gd`

- [ ] **Step 1: 实现 hunger_system.gd（每分钟 -2，0 时扣血）**

- [ ] **Step 2: 实现 stamina_system.gd（移动/采集消耗，休息恢复）**

- [ ] **Step 3: 实现 health_system.gd（0 时触发死亡）**

- [ ] **Step 4: Commit**

```
git commit -m "feat: 生存系统（饥饿/体力/生命）"
```

### Task 1.7: 死亡与传承（简化版）

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\inheritance\inheritance_manager.gd`
- Create: `d:\Mountandsea\game\scenes\ui\death_ui.tscn`
- Create: `d:\Mountandsea\game\scripts\ui\death_ui_controller.gd`

- [ ] **Step 1: 实现 inheritance_manager.gd**

死亡 → 显示传承预览（后代继承图鉴）→ 后代在招摇山随机重生 → 图鉴保留，物品/熟练度丢失。

- [ ] **Step 2: 创建 death_ui.tscn（传承预览 + 确认按钮）**

- [ ] **Step 3: 实现 save_manager.gd 存档/读档**

存档格式：JSON，包含 permanent_knowledge（图鉴/科技）+ current_character（属性/背包/位置）。

- [ ] **Step 4: Commit**

```
git commit -m "feat: 死亡与传承系统（简化版）"
```

### Task 1.8: 昼夜循环 + 标题画面

**Files:**
- Create: `d:\Mountandsea\game\scripts\systems\time\day_night_cycle.gd`
- Create: `d:\Mountandsea\game\scenes\menus\title_screen.tscn`

- [ ] **Step 1: 实现简易昼夜循环（2 分钟一轮，CanvasModulate 调亮度）**

- [ ] **Step 2: 创建标题画面（游戏名 + 开始按钮 + 设置）**

- [ ] **Step 3: Commit**

```
git commit -m "feat: 昼夜循环 + 标题画面"
```

### Phase 1 验收标准

- [ ] 玩家可在 3×3 chunk 招摇山地图自由移动
- [ ] 可采集祝余（恢复饱食度）、迷榖（获得物品）
- [ ] 可狩猎狌狌（获得生肉排）、遭遇蝮虫（中毒）
- [ ] 可在篝火烹饪熟祝余/熟狌狌肉
- [ ] 图鉴记录 3 种物品的外观/类型/效果
- [ ] 饥饿/体力/生命正常运作
- [ ] 死亡后可传承，图鉴知识保留
- [ ] 存档/读档正常
- [ ] 30 分钟可完成完整核心循环

---

## Phase 2：扩展内容

**目标：** 扩展到南山经多山系，chunk 流式加载，完整图鉴 7 槽位，生态反馈雏形。

### Task 2.1: Chunk 流式加载升级

- [ ] 升级 chunk_manager.gd：render_distance 从 1 扩展到 3-5
- [ ] 引入 chunk 加载/卸载队列
- [ ] 超出视距的 chunk 卸载并保存到存档
- [ ] 引入 biome 系统（按山系定义不同地形参数）

### Task 2.2: 扩展数据表

- [ ] items.json 扩展到南山经全部物品（鹿蜀/旋龟/九尾狐/灌灌等）
- [ ] creatures.json 扩展到南山经全部异兽
- [ ] 新增 crafting.json（石器/木工/制皮配方）
- [ ] 新增 mountains/nanshan/*.json（招摇山/堂庭山/猨翼山/杻阳山配置）

### Task 2.3: 完整图鉴 7 槽位

- [ ] 启用 cooking/location/rarity/note 槽位
- [ ] 实现 cooking 槽位（第一次烹饪解锁）
- [ ] 实现 location 槽位（第一次在该地点采集）
- [ ] 实现 rarity 槽位（累计 10 次）
- [ ] 实现 note 槽位（特殊事件触发）

### Task 2.4: 扩展科技树

- [ ] 新增节点：渔猎/建造/制皮/草药学/烹药/解毒术/石器/木工
- [ ] 创建 tech_tree_ui.tscn（科技树可视化界面）
- [ ] 实现跨分支组合解锁

### Task 2.5: 昼夜影响 + 生态反馈雏形

- [ ] 夜间异兽行为变化
- [ ] 迷榖夜间发光
- [ ] ecology_tracker.gd：过度采集导致资源再生速度下降

### Phase 2 验收标准

- [ ] 地图扩展到南山经 5+ 座山，chunk 流式加载正常
- [ ] 物品/异兽覆盖南山经全部
- [ ] 科技树 10+ 节点，跨分支组合可工作
- [ ] 图鉴 7 槽位全部启用
- [ ] 昼夜影响玩法
- [ ] 生态反馈可感知

---

## Phase 3：完整系统

**目标：** 祭祀、修仙、灾变、远征、完整传承，50+ 小时内容。

### Task 3.1: 祭祀系统

- [ ] sacrifice_manager.gd + altar.tscn
- [ ] data/sacrifice/sacrifice_rules.json（各山系祭品规则，严格遵循原文）
- [ ] 正确祭祀→山神庇佑，错误祭祀→触怒降灾

### Task 3.2: 修仙系统

- [ ] cultivation_manager.gd + lingqi_system.gd
- [ ] 引气→筑基→御物→御兽→飞升
- [ ] 灵气地绑定机制

### Task 3.3: 灾变系统

- [ ] disaster_manager.gd + omen_system.gd
- [ ] 预兆异兽（长右→洪水，顒→干旱，毕方→野火）
- [ ] 灾变强度 = 基础 × (1 + 科技系数) × (1 + 村落系数)

### Task 3.4: 远征系统

- [ ] expedition_manager.gd + event_table.gd
- [ ] 物资准备→行进→随机事件→目的地→返回
- [ ] 地理独占资源（玉膏/不死树/夔牛等）

### Task 3.5: 完整传承

- [ ] 天赋遗传变异公式
- [ ] 鹿蜀角赌注机制
- [ ] 尸体肥料→土地肥力
- [ ] 血脉断绝判定

### Task 3.6: 渲染管线升级（可选）

- [ ] terrain.gdshader（参考 Substrata）
- [ ] PackedByteArray → Image → shader → Texture2DArray
- [ ] 数据层不变，只替换渲染层

### Phase 3 验收标准

- [ ] 祭祀系统按原文规则运行
- [ ] 修仙可引气/筑基
- [ ] 灾变有预兆/爆发/恢复循环
- [ ] 远征可规划/执行/返回
- [ ] 传承有完整天赋/鹿蜀角/肥料
- [ ] 50+ 小时可玩内容

---

## 依赖关系

```
Phase 0.1 → 0.2 → 0.3 → 0.4（串行）
Phase 1.1 → 1.2 → 1.3 → 1.4（串行核心）
         1.5 ← 1.3（图鉴依赖交互）
         1.6 ← 1.2（生存依赖玩家）
         1.7 ← 1.5 + 1.6（传承依赖图鉴+生存）
         1.8（可并行）
Phase 2.x ← Phase 1 全部完成
Phase 3.x ← Phase 2 全部完成
```

---

## 风险与应对

| 风险 | 应对 |
|------|------|
| TileMapLayer 性能不足 | 数据层与渲染层解耦，可迁移自绘 shader |
| JSON 编辑困难 | 编写验证脚本，提供编辑器工具 |
| GDScript 性能瓶颈 | 关键路径多线程，后期 C++ 扩展 |
| 美术资源缺失 | Phase 1 占位资源，同步制作像素素材 |
| 存档格式变更 | version 字段 + 迁移器 |
