# 2D 开放世界游戏引擎架构选型调研报告

> 调查日期：2026-06-19
> 调查方法：通过 `gh api` 拉取仓库元数据、文件树与关键源码，进行代码级审计式阅读（非复述 README）
> 调查范围：6 个 Godot 仓库 + 2 个 Unity 仓库，共 8 个开源项目
> 行为约束：无法从代码确认的信息标注「⚠️ 未能从代码确认」

---

## 1. Executive Summary

如果要从零做「2D 大世界」（俯视角 or 类 Terraria），推荐如下起点路线：

**Godot 路线（首选）**：

- **类 Terraria 侧视沙盒（挖掘 + 物理 + 可编辑地形）**：以 `BerkZerker/Substrata-Game` 为架构蓝本。它是 8 个仓库中大世界工程实践最扎实的一个——WorkerThreadPool 多线程生成 + 队列背压 + chunk pooling + 自绘 shader 渲染（绕过 TileMap 性能瓶颈）+ 自定义 swept AABB 物理 + 运行时 dig/place + 脏 chunk 自动存盘。每一项都是经过深思的架构决策，其 `CLAUDE.md` 本身就是一份优秀的大世界架构文档。
- **俯视角程序化生成（PCG 框架）**：以 `BenjaTK/Gaea` 为生成层插件。它是抽象层次最高的项目——可视化节点图 + 多线程任务池 + 优先级队列 + 去重 + TileMapLayer/GridMap 双渲染路径，活跃维护（115 stars，2026-05 仍有更新），MIT 协议。但它不提供运行时编辑/物理/网络，需自行补齐。
- **多人网络可见性同步**：若需要 chunk 级多人同步，参考 `DigitallyTailored/Godot-Open-World-Database`（OWDB）的 HOST/PEER 可见性同步系统——这是 8 个仓库中唯一有完整网络层的项目。

**Unity 路线（对照）**：

- 两个 Unity 仓库均**不建议作为生产起点**。`Pandawan/Islands`（2018）有引用计数式 chunk 流式加载框架但 GC 压力严重、BinaryFormatter 有安全漏洞、Perlin 噪声有负坐标镜像 bug；`0PaiPai0/AdvancedTilemap` 有出色的自绘 Mesh + bitmask autotile + 液体模拟，但**缺失 chunk 流式加载**（致命短板），大世界场景下内存会爆炸。若必须用 Unity，可借鉴 Islands 的流式加载架构 + AdvancedTilemap 的渲染层，但需自行重写。

---

## 2. 对比矩阵

| Repo | 引擎/版本 | 世界类型 | Chunk 策略 | 线程模型 | 编辑地形 | 多人 | License | 成熟度风险 |
|------|----------|---------|-----------|---------|---------|------|---------|-----------|
| OWDB | Godot 4.5 / GDScript | 3D 节点流式（非地形） | 多尺寸 [8/16/64] + 引用计数 | Timer 时间片（单线程） | save/load 节点库 | ✅ HOST/PEER | MIT | 生产级插件，362 star |
| cosei-indie | Godot 4.4 / GDScript | 离散瓦片（俯视） | 16 cell + 距离 LRU (cap=15) | 同步 _physics_process | ❌ | ❌ | ⚠️ 无 License | 教学原型，1 star |
| overmapchunkdemo | Godot 4.4 / GDScript | 离散瓦片（战略地图） | 180 tile + 边界邻近触发 | 同步 _process | ❌ | ❌ | MIT | 研究原型，**无卸载（内存泄漏）** |
| Substrata-Game | Godot 4.6 / GDScript | 离散方块（侧视 voxel） | 32 tile + Region 环形 + pooling | WorkerThreadPool + 背压 | ✅ dig/place + 自动存盘 | ❌ | ⚠️ 无 License | 架构最完整，0 star |
| Godot-2DMap | Godot 3.x / C# | 离散瓦片（球形行星） | 40 tile + 相机视口 | C# async/await + Task.Run | ✅ 基础 set tile | ❌ | ⚠️ 无 License | 2022 demo，**已废弃** |
| Gaea | Godot 4.6 / GDScript | 节点图（2D/3D 通用） | 16 tile + 可配环形卸载 | WorkerThreadPool + 优先级 + 去重 | ❌ | ❌ | MIT | 活跃插件，115 star |
| Islands | Unity 2018.3 / C# | 离散瓦片（string ID） | 可配 + 引用计数 | async/await + Task.Run | ✅ + dirty 自动保存 | ❌ | ⚠️ 无 License | 2019 原型，GC 严重 |
| AdvancedTilemap | Unity 2023.2 / C# | 离散瓦片（自绘 Mesh） | 16 tile + **无流式加载** | System.Threading.Thread | ✅ + undo/redo | ❌ | MIT | **无 chunk 流式（致命）** |

---

## 3. 逐项目 Deep-Dive

### 3.1 DigitallyTailored/Godot-Open-World-Database（OWDB）

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2025-11-26 |
| 主要语言 | GDScript |
| License | MIT |
| Star | 362 |
| Godot 版本 | **4.5**（`config/features=PackedStringArray("4.5", "Forward Plus")`） |
| 定位 | Godot 插件（addon），3D 场景节点流式加载系统，附带多人网络支持 |

#### 世界模型

**混合模型——核心是「离散场景节点流式加载」，不是地形系统。** OWDB 管理任意 Godot Node3D 场景实例（岩石、树、敌人、建筑等），按节点 AABB 尺寸分类到不同粒度的 chunk 中。demo 中附带的 `terrain.gd` 用 `SurfaceTool` 生成连续高度图 mesh，但只是展示用例。

#### 大世界策略

**多尺寸 chunk 系统（核心创新点）**：

```gd
# open_world_database.gd
enum Size { SMALL, MEDIUM, LARGE, ALWAYS_LOADED }
var _chunk_sizes: Array[float] = [8.0, 16.0, 64.0]
var _threshold_ratio: float = 0.25
var _chunk_load_range: int = 3
```

节点根据 AABB 尺寸分入 4 类：SMALL（8.0）、MEDIUM（16.0）、LARGE（64.0）、ALWAYS_LOADED（不参与 chunk）。大物体用大 chunk 减少加载频率，小物体用小 chunk 保持精度。

**加载触发**：`OWDBPosition` 节点（Node3D 标记），可绑定玩家/相机/编辑器相机。Position 的 `global_position` 变化时调用 `update_position_chunks()`。

**加载方式**：Timer 时间片批处理（非多线程），每批最多 10ms，批次间隔 50ms：

```gd
# batch_processor.gd
var batch_time_limit_ms: float = 10.0
func _process_batch():
    var start_time = Time.get_ticks_msec()
    while not operation_order.is_empty():
        # ... 处理操作 ...
        if Time.get_ticks_msec() - start_time >= batch_time_limit_ms:
            break  # 超时，剩余留到下一批
```

**卸载策略**：精确引用计数。`chunk_requirements[chunk_key]` 记录所有需要该 chunk 的 position_id，当且仅当所有 Position 都不再需要时才卸载——多人安全。

```gd
# chunk_manager.gd
func _remove_chunk_requirement(size, chunk_pos, position_id):
    chunk_requirements[chunk_key].erase(position_id)
    if chunk_requirements[chunk_key].is_empty():
        chunk_requirements.erase(chunk_key)
        _queue_chunk_operation(size, chunk_pos, "unload")
```

**数据存储**：自定义 `.owdb` 文本格式，每行 `uid|"scene"|x,y,z|rx,ry,rz|sx,sy,sz|size|{properties_json}`，Tab 缩进表示父子层级。属性差分存储（只保存与基线不同的属性）。

**渲染路径**：OWDB 不负责渲染——加载/卸载 Godot 节点（PackedScene 实例），节点自带渲染组件。demo terrain.gd 用 `SurfaceTool` 生成 `ArrayMesh` + trimesh 碰撞。

#### 程序化生成

demo 的 `terrain.gd`：FastNoiseLite (Simplex + FBM)，seed=12345 可复现。基于高度阈值的顶点颜色（water < 0.2 < sand < 0.3 < grass < 0.6 < rock < 0.8 < snow）。无 biome 噪声混合。

#### 多人/网络

**有完整的 chunk 可见性同步系统**（核心卖点）。`Syncer.gd`（25KB）管理每个 peer 的实体可见性，HOST 决定每个 peer 能看到哪些实体：

```gd
# Syncer.gd
func _update_entity_visibility_from_owdb():
    if not multiplayer.is_server() or not owdb: return
    for peer_id in _peer_positions:
        for entity_name in all_entities_to_check:
            var should_see = _should_peer_see_entity_via_chunks(peer_id, entity_node)
            if should_see and not currently_visible:
                entity_peer_visible(peer_id, entity_name, true)
```

#### 坑点与风险

- **浮点精度**：使用绝对世界坐标 `Vector3`，`chunk_pos = int(position.x / chunk_size)` 在远离原点时精度下降。⚠️ 未见 origin rebasing 机制。
- **线程安全**：完全不使用 WorkerThreadPool，所有操作在主线程通过 Timer 执行——安全但吞吐量受限。
- **O(n²) 保存复杂度**：`database.gd` 的 `_get_child_uids` 遍历所有 `stored_nodes` 查找子节点，大世界保存时性能堪忧。
- **chunk_load_range 固定方形**：角落 chunk 被加载但实际视距外，浪费加载预算。

#### 定位

**适合**：3D 开放世界场景节点流式加载 + 多人网络可见性同步。
**不适合**：2D TileMap 世界、连续高度图地形流式加载、超高吞吐量超大规模世界。

---

### 3.2 cosei-indie/topdown-open-world-2d-procedural-gen

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2025-04-25 |
| 主要语言 | GDScript |
| License | ⚠️ **无 License**（不可自由使用） |
| Star | 1 |
| Godot 版本 | **4.4** |
| 定位 | 俯视角 2D 程序化生成开放世界 demo，教学/原型性质 |

#### 世界模型

**离散瓦片模型**。使用 Godot 4 原生 `TileMapLayer`，每个 cell 16×16 像素。5 个 TileMapLayer 叠加（Water / Grass / Mush / Hills / MushHills），通过噪声高度值决定每层是否填充。

#### 大世界策略

**分区单位**：chunk=16 cell（256px），render_distance=1 → 3×3=9 个 chunk，可见范围仅 768px（非常局促）。

**加载触发**：`_physics_process` 中每帧检查玩家所在 chunk，变化时触发加载。**完全同步**，无 async/协程/多线程。

**卸载策略**：距离 LRU，固定容量 `max_chunk_memory = 15`，满时移除距离当前 chunk 最远的：

```gd
# world.gd
func load_chunk(chunk_pos):
    if loaded_chunk.size() == max_chunk_memory:
        pop_furthest_point(chunk_pos)
    loaded_chunk.append(chunk_pos)
    generate_chunk(chunk_pos)

func pop_furthest_point(new_chunk):
    var furthest = loaded_chunk[0]
    for c in loaded_chunk:
        if c.distance_to(new_chunk) > furthest.distance_to(new_chunk):
            furthest = c
    unload_chunk(furthest)
```

**数据存储**：无持久化。噪声源 `NoiseTexture2D` + `FastNoiseLite`（默认参数，⚠️ 未设 seed → 不可复现）。

**渲染路径**：内置 TileMapLayer + `set_cells_terrain_connect()` 自动连接。

#### 程序化生成

```gd
# world.gd
var noise_value = noise.get_noise_2d(world_x, world_y)
water_cells.append(Vector2i(x, y))
if noise_value > 0.2: grass_cells.append(Vector2i(x, y))
if noise_value > 0.4: hills_cells.append(Vector2i(x, y))
```

纯高度阈值，无温度/湿度二维生物群落。⚠️ 代码中未设置 `noise.seed`，每次运行世界不同。⚠️ `Mush` 和 `MushHills` 两个 TileMapLayer 存在但代码中**完全未使用**（死层）。

#### 坑点与风险

- **chunk 加载卡顿**：`load_chunk` 在 `_physics_process` 中同步处理 256 个 cell 的噪声采样 + `set_cells_terrain_connect`，每次 chunk 切换造成一帧卡顿。
- **render_distance=1 太小**：玩家移动稍快就会看到边缘加载。
- **无 seed**：世界不可复现。
- **无 License**：不可自由使用。

#### 定位

**适合**：Godot 4 初学者学习 TileMapLayer + 噪声程序化生成 + chunk 基本概念的最小原型。
**不适合**：任何生产级项目。

---

### 3.3 AliveGh0st/overmapchunkdemo

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2025-05-23 |
| 主要语言 | GDScript |
| License | MIT |
| Star | 6 |
| Godot 版本 | **4.4** |
| 定位 | Cataclysm DDA 风格 overmap 程序化生成 demo |

#### 世界模型

**离散瓦片模型——但粒度极粗（战略地图级）**。每个 tile 代表一个「地区」（如一片森林、一栋建筑、一段道路）。使用 Godot 4 `TileMapLayer` 渲染，地形数据存储在 `terrain_data: Dictionary[Vector2i] → TerrainType` 中。

#### 大世界策略

**分区单位**：`CHUNK_SIZE = 180`（180 tile = 2880px），极大——一个 chunk 就是一个「区域块」。

**加载触发**：**边界邻近触发**（非固定环形）。只有当玩家走到 chunk 边缘 11 tile 以内时才生成相邻 chunk：

```gd
# coordinate_utils.gd
static func get_adjacent_chunks_to_generate(player_grid, current_chunk, threshold=11):
    var local_pos = world_to_local(player_grid, current_chunk)
    var chunks = []
    if local_pos.x < threshold:
        chunks.append(current_chunk + Vector2i(-1, 0))
    if local_pos.x >= CHUNK_SIZE - threshold:
        chunks.append(current_chunk + Vector2i(1, 0))
    # ... 同理南北 ...
    return chunks
```

**加载方式**：完全同步，在 `_process` 中执行。有 `chunk_creation_cooldown` 节流。

**卸载策略**：⚠️ **无卸载机制**。`terrain_data`、`generated_chunks`、`city_tiles`、`city_buildings` 全部只增不减——长时间游玩后内存持续增长，最终 OOM。

**数据存储**：`ConfigFile` 存到 `user://runtime_config.cfg`，但仅保存**配置参数**，生成的地形数据不可持久化。

#### 程序化生成（核心价值）

生成管线复杂且忠实移植自 Cataclysm DDA：

```gd
# overmap_renderer.gd
func generate_chunk(chunk_coord):
    var forestosity = calculate_forestosity(world_pos)
    var urbanity = calculate_urbanity(world_pos)
    place_rivers(chunk_coord)      # 跨 chunk 河流连接
    place_lakes(chunk_coord)
    place_forests(chunk_coord, forestosity)  # 双噪声：base + density
    place_swamps(chunk_coord)
    place_cities(chunk_coord, urbanity)      # 递归街道 + 建筑放置
```

4 种独立 FastNoiseLite 噪声（LAKE / FOREST_BASE / FOREST_DENSITY / FLOODPLAIN），每种有独立 seed_offset。城市街道递归生成（有方向变化和分叉概率），全局唯一建筑追踪。⚠️ `world_seed = randi()` 每次运行不同，但 seed 基础设施完备，改为固定值即可复现。

#### 坑点与风险

- **无卸载机制（最大风险）**：内存泄漏，demo 性质的明确体现。
- **chunk 生成卡顿**：180×180=32400 tile 的多噪声采样 + 河流/城市递归在单帧内完成。
- **河流跨 chunk 一致性**：邻居 chunk 未生成时河流可能断裂。
- **城市生成递归深度**：街道递归无明确深度限制，极端参数下可能栈溢出。

#### 定位

**适合**：学习 Cataclysm DDA 风格战略地图程序化生成——多噪声生物群落、跨 chunk 河流连接、城市街道递归生成的参考实现。
**不适合**：生产级无限世界——无卸载、无持久化、单帧卡顿。

---

### 3.4 BerkZerker/Substrata-Game

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2026-03-27 |
| 主要语言 | GDScript |
| License | ⚠️ 未能从代码确认（`license: null`） |
| Star | 0 |
| Godot 版本 | **Godot 4.6** |
| 定位 | 2D Voxel Based Game，大世界架构最完整 |

#### 世界模型

**离散方块（voxel tile）模型**，2D 侧视。每 tile 占 **2 字节**：`[tile_id, damage_stage]`，存储在 `PackedByteArray` 中。

```gd
# src/world/chunks/chunk.gd
var _terrain_data: PackedByteArray = PackedByteArray()
var index = (tile_y * GlobalSettings.CHUNK_SIZE + tile_x) * 2
_terrain_data[index]     # tile_id
_terrain_data[index + 1] # damage_stage
```

#### 大世界策略

**「Region → Chunk → Tile」三级分区**，大世界架构最完整。

- **Chunk**：`CHUNK_SIZE = 32`（32×32 tiles）
- **Region**：`REGION_SIZE = 4`（4×4 chunks = 128×128 tiles）
- **加载触发**：Player chunk position 驱动，通过 `SignalBus.player_chunk_changed` 信号通知

**加载方式**：**WorkerThreadPool 多线程**，生产者-消费者模型 + 背压：

```gd
# src/world/chunks/chunk_loader.gd
func _generate_chunk_task(chunk_pos: Vector2i) -> void:
    var terrain_data = _terrain_generator.generate_chunk(chunk_pos)  # 纯计算，线程安全
    var visual_image = _generate_visual_image(terrain_data)
    _mutex.lock()
    if not _shutdown_requested:
        _build_queue.append({"pos": chunk_pos, "terrain_data": terrain_data, "visual_image": visual_image})
        if _build_queue.size() >= GlobalSettings.MAX_BUILD_QUEUE_SIZE:
            _generation_paused = true   # 背压
    _mutex.unlock()
```

- `MAX_CONCURRENT_GENERATION_TASKS = 8`（最多 8 个并行任务）
- 主线程每帧从 `_build_queue` 取出已生成的 chunk 实例化

**卸载策略**：固定视距环形 + 队列。卸载半径 = `LOD_RADIUS + REMOVAL_BUFFER = 6` regions。脏 chunk 在卸载前自动存盘。每帧最多移除 `MAX_CHUNK_REMOVALS_PER_FRAME = 32` 个。

**渲染路径**：**完全自绘，不使用 TileMap/TileMapLayer**（最关键架构决策）：

```
PackedByteArray → Image(RGBA8, R=tile_id, G=damage_stage) → ImageTexture → fragment shader → Texture2DArray
```

```glsl
// src/world/chunks/terrain.gdshader
void fragment() {
    vec4 data = texture(chunk_data_texture, UV);
    float tile_id = data.r * 255.0;
    if (tile_id < 0.5) { discard; }            // air 透明
    COLOR = texture(tile_textures, vec3(tile_uv, tile_id));  // Texture2DArray 采样
}
```

**内存上限手段**：
- Chunk pooling：`MAX_CHUNK_POOL_SIZE = (2*4+1)² * 4² = 1296`，回收的 chunk 进入 `_chunk_pool` 复用
- Per-frame build limit：`MAX_CHUNK_BUILDS_PER_FRAME = 16`
- 背压：`MAX_BUILD_QUEUE_SIZE = 128`，满时暂停生成，降到 64 以下恢复

#### 程序化生成

3 个独立 `FastNoiseLite`（Simplex）：heightmap（frequency=0.002, amplitude=96）、detail（0.008, 20）、layer（0.006, 12）。Seed 可复现（seed, seed+1, seed+2）。基于 depth 和 slope 分配 grass/dirt/stone，陡坡不生草。⚠️ 无 biome 系统。

#### 可编辑地形

✅ dig/place 支持。`TerrainEditor` 捕获鼠标输入，按笔刷形状/尺寸批量提交。`ChunkManager.set_tiles_at_world_positions()` 按 chunk 分组，每 chunk 仅 2 次 mutex 获取。✅ Save/Load：仅持久化脏 chunk，卸载时自动存盘。

```gd
# chunk.gd 的就地更新（避免每帧分配新纹理）
func _update_visuals() -> void:
    if _terrain_image and _data_texture:
        _data_texture.update(_terrain_image)  # GPU 纹理原地更新
```

#### 物理/碰撞

**完全自定义 swept AABB**，不使用 Godot 内置物理引擎。`CollisionDetector` 执行轴分离扫描（先 X 后 Y）。`project.godot` 中 `physics/2d/run_on_separate_thread=true`。

#### 坑点与风险

- **TileMap → TileMapLayer 迁移**：不涉及——完全绕过 TileMap，使用自绘 shader 管线。反而是优势。
- **浮点精度**：⚠️ 存在风险。chunk 的 `position` 直接设为 `Vector2(chunk_pos.x * 32, chunk_pos.y * 32)`，无 floating origin。远离原点时 float32 精度下降。
- **线程安全**：处理得当——生成器在 worker 线程只做纯计算，不碰 SceneTree/RID；`_init()` 中预先缓存 autoload 值；所有 chunk 数据访问通过 `_mutex` 保护；`ImageTexture.create_from_image()` 在主线程调用。
- **Y-inversion 复杂度**：`_generate_visual_image` 和 `edit_tiles` 都做了 Y 反转，极易在修改时引入渲染错位 bug。

#### 定位

**适合**：2D 侧视方块沙盒游戏（Terraria-like），需要大世界 + 可编辑地形 + 自定义物理。其 shader 渲染管线 + WorkerThreadPool 背压模型是可直接复用的工程范本。
**不适合**：需要复杂 biome / 3D 地形 / 多人同步的场景。

---

### 3.5 VincentSinel/Godot-2DMap

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2022-08-18 |
| 主要语言 | C# |
| License | ⚠️ 未能从代码确认 |
| Star | 0 |
| Godot 版本 | **Godot 3.x**（`config_version=4`，已停止维护近 4 年） |

#### 世界模型

**离散瓦片 + 球形行星**模型。世界是一个「行星」，X 轴环绕（circular wrap），Y 轴有限（从太空到地核）。每 tile 存 `ushort[] tiles_Front` + `ushort[] tiles_Back` + `byte[] tiles_Color`。行星按 Y 轴分层：Space → Atmosphere → Surface → Subsurface → ShallowUnderground → MidUnderground → DeepUnderground → Core。

#### 大世界策略

**分区单位**：`ChunkSize = 40`（40×40 tiles）。Large 行星 = 150×75 chunks。

**加载触发**：相机视口位置驱动，每帧 `_Process()` 计算视口覆盖的 chunk 范围。

**加载方式**：C# `async/await + Task.Run`。生成（`G_Tiles`）跑在线程池，绘制（`D_Tiles`）在 await 之后主线程执行。

```csharp
// ChunkData.cs
private async Task<bool> Draw()
{
    D_Tiles(await Task.Run(() => CD_Tiles()));  // 后台算碰撞，前台画 TileMap
}
```

**卸载策略**：视口外清除绘制，但**保留数据**。`generatedChunks` 字典只增不减——内存随探索单调增长。

**渲染路径**：Godot 3.x TileMap（3 层）。`TileMapLimiter` 继承 `TileMap`，重写 `SetCell()` 实现行星 X 轴环绕——每次 SetCell 在 `±IntTileW` 偏移处复制 tile：

```csharp
// Script/PlanetGen/TileMapLimiter.cs
public new void SetCell(int x, int y, int tile, ...)
{
    base.SetCell(x, y, tile, ...);
    int ux = x - Info.IntTileW;
    while (ux >= -ViewportSize.x) {
        base.SetCell(ux, y, tile, ...);   // 向左复制
        ux -= Info.IntTileW;
    }
    // ... 向右同理 ...
}
```

**数据存储**：`Planet_Binary` 二进制文件，DeflateStream 压缩，每 tile 5 字节。

#### 程序化生成

`OpenSimplexNoise`（Godot 3.x）：地表形状（Octaves=8, Period=300）、地表细节（2, 50）、洞穴（8, 20）。Seed 可复现（由行星坐标派生）。行星表面用极坐标 `GetCPosition(x)` 将 X 映射到圆周，实现「球形行星」效果。有 biome 枚举体系但未实际使用。

#### 物理/碰撞

Marching squares 碰撞，通过 `TileMap_Collision` 实现。`CD_Tiles()` 将前景 tile 转换为 marching squares 编码（0-15），由 Godot 3.x TileMap 内置碰撞体生成物理形状。

#### 坑点与风险

- **TileMap → TileMapLayer 迁移成本（3.x→4.x）：极高**。深度依赖 Godot 3.x API（`TileMap.SetCell` 签名、`WorldToMap`、`KinematicBody2D`、`OpenSimplexNoise`），迁移到 4.x 基本等于重写。
- **线程安全**：⚠️ `async void` + `await Task.Run(...)` 后的续体**不保证在主线程执行**，Godot 3.x C# 的 `SynchronizationContext` 行为不确定，可能引发崩溃。
- **内存泄漏**：`generatedChunks` 字典无限增长，探索整个行星约 90MB。
- **byte 坐标类型**限制行星在 255 chunks 宽。

#### 定位

**适合**：作为 Godot 3.x 时代「球形行星 + 分层地下世界 + 极坐标 noise」概念的参考实现。
**不适合**：直接用于生产——2022 demo，依赖已废弃 API，无内存管理，线程安全存疑。

---

### 3.6 BenjaTK/Gaea

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2026-05-30 |
| 主要语言 | GDScript |
| License | MIT |
| Star | 115 |
| Godot 版本 | **Godot 4.6** |
| 定位 | Procedural generation add-on for Godot 4，活跃维护 |

#### 世界模型

**节点图驱动的混合模型**。Gaea 通过可视化节点图生成 `GaeaGrid`（`Dictionary[int layer, GaeaValue.Map]`）。数据类型支持 SAMPLE（浮点网格）、MAP（material 网格）、SCALAR、VECTOR、RANGE。支持 2D（TileMapLayer）和 3D（GridMap）。

#### 大世界策略

**两种模式**：一次性全量生成（`generate()`）和 chunk 流式加载（`GaeaChunkLoader`）。

**分区单位**：`chunk_size: Vector3i`，默认 `Vector3i(16, 16, 1)`（可配置）。3D 整数网格。

**加载触发**：Actor chunk position 驱动，timer 轮询（默认 0.1s）。

**加载方式**：**WorkerThreadPool + 优先级队列 + 去重**，通过 `GaeaTaskPool`：

```gd
# addons/gaea/runtime/scene_nodes/threading/task_pool.gd
func _wait_on_task(task: GaeaTask) -> void:
    _mutex_tasks.lock()
    _tasks[task.task_id] = task
    _mutex_tasks.unlock()
    while not WorkerThreadPool.is_task_completed(task.task_id):
        await _main_loop.process_frame   # 协程等待，不阻塞主线程
    WorkerThreadPool.wait_for_task_completion(task.task_id)
```

- `DeDuplicationStrategy`：NONE / DROP_NEW / DROP_EXISTING
- 优先级排序：按 actor chunk 距离排序

**卸载策略**：可配置环形卸载。超出 `loading_radius` 的 chunk 调用 `generator.request_area_erasure(area)`。

**渲染路径**：内置 TileMapLayer（Godot 4.x）或 GridMap，通过 `GaeaRenderer` 抽象基类。`TileMapGaeaRenderer` 支持 SINGLE_CELL / TERRAIN（`set_cells_terrain_connect`）/ PATTERN，含 hexagon/isometric 坐标转换。

#### 程序化生成（核心价值）

**节点图执行引擎**。`GaeaNodeResource` 是所有节点基类，通过 `traverse(output_port, pouch)` 递归遍历图获取数据。

节点类型：Sampling（Noise2D/3D、FloorWalker、SnakePath2D、FalloffMap）、Filters（Threshold/Distance/Random/Flags）、Mappers（Basic/Threshold/Value/Flags）、Operations、Placing（RandomScatter/RulesPlacer）。

```gd
# addons/gaea/runtime/graph_nodes/root/sampling/noise/noise.gd
func _get_data(_output_port, pouch: GaeaGenerationPouch) -> GaeaValue.Sample:
    var noise: FastNoiseLite = FastNoiseLite.new()
    noise.seed = pouch.settings.seed + salt   # 全局 seed + 节点 salt
    noise.frequency = _get_arg(&"frequency", pouch)
    # ... 遍历 area 采样 ...
```

Seed 可复现（`settings.seed + salt`）。FloorWalker 实现 Nuclear Throne 风格 walker 地牢生成。⚠️ 不提供内置 biome 系统——需用户通过节点图组合自行实现。

#### 可编辑地形

⚠️ **不支持**。Gaea 是程序化**生成器**，不是运行时编辑器。生成后编辑需直接操作 `TileMapLayer`/`GridMap`（脱离 Gaea 管线）。无 dig/place、无 undo、无运行时 save/load。

#### 坑点与风险

- **TileMap → TileMapLayer 迁移**：已处于 4.x 正确路径，使用 `TileMapLayer`，无迁移负担。
- **线程安全**：生成在 worker 线程只操作纯数据，结果用 `call_deferred` 回传主线程。⚠️ 潜在风险：`_define_rng(pouch)` 调用全局 `seed()` 函数，在 worker 线程会影响主线程 RNG 状态（全局状态竞争）。
- **@tool 注解**：几乎所有 runtime 类标 `@tool`，编辑器预览时 WorkerThreadPool 任务可能与编辑器操作竞争。
- **图遍历取消**：`cancelled` 标志仅在入口检查，长循环节点（FloorWalker 10000 次迭代）无法中途响应取消。

#### 定位

**适合**：作为 Godot 4.x 程序化生成的**通用框架/插件**——可视化节点图 + 多线程 + chunk 流式 + 双渲染路径。适合做 2D/3D 地牢、洞穴、地形生成器。
**不适合**：需要开箱即用 biome、运行时地形编辑、物理碰撞、多人同步的项目。

---

### 3.7 Pandawan/Islands

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2019-03-19 |
| 主要语言 | C# |
| License | ⚠️ 未能从代码确认 |
| Star | 4 |
| Unity 版本 | **2018.3.8f1** |

#### 世界模型

**离散瓦片模型**，基于 Unity 内置 Tilemap。每 chunk 内部用 `string[] tiles` 一维数组存储 tile 的**字符串 ID**（不是整数 ID）。额外有 `ChunkData` 存储 per-tile 动态属性。

#### 大世界策略

**加载触发**：`ChunkLoader` 组件跟随 Transform，每帧 `Update()` 计算当前 chunk 边界（`BoundsInt`），与上一帧做差集。

**加载方式**：`async/await + Task`，所有操作封装为 `IChunkOperation`，入队 `Queue<IChunkOperation>`，严格串行执行：

```csharp
// World.cs
private async Task ProcessOperations()
{
    isProcessingOperations = true;
    while (chunkOperations.Any())
    {
        IChunkOperation operation = chunkOperations.Dequeue();
        await operation.Execute(this);
        chunksUsed = chunksUsed.Union(operation.ChunkPositions).ToList();
    }
    if (chunksUsed.Count > 0)
        await UnloadChunks(GetChunksToUnloadFromPositions(chunksUsed), worldInfo);
    isProcessingOperations = false;
}
```

**卸载策略**：引用计数。`Dictionary<Vector3Int, List<ChunkLoader>> chunkLoadingRequests` 记录每个 chunk 被哪些 ChunkLoader 请求。requester 列表归零且无排队操作需要时才卸载。卸载前 dirty chunk 异步保存。

**数据存储**：`BinaryFormatter` 二进制序列化，每 chunk 存为独立文件。tile 字符串 ID 通过 `TileDB` 静态字典映射回 `BasicTile`。

**渲染路径**：完全依赖 Unity 内置 Tilemap。`Tilemap.SetTiles()` 批量写入。

#### 程序化生成

5 种模式：None / Square / SquareNoBorders / Circle / Perlin。`Mathf.PerlinNoise(x * 0.125f, y * 0.125f)`，height > 0.35 → "grass"，否则 → "water"。⚠️ 无 seed 系统，`Mathf.PerlinNoise` 不接受 seed。⚠️ 负坐标区域 Perlin 值是正坐标的镜像（已知 bug）。

#### 坑点与风险

- **GC 压力（严重）**：大量 LINQ（`.Where().ToList()`、`.Union().ToList()`），每帧产生大量临时 List 和 lambda 闭包。`LoadTilesToTilemap()` 每次 new `Dictionary` + `Keys.ToArray()` + `Values.ToArray()`。
- **async void Update()**：危险模式——异常不会被捕获，无法保证退出前完成。
- **BinaryFormatter 安全性**：反序列化外部文件存在漏洞风险（Unity 官方已不推荐）。
- **单例耦合**：`World.instance` 全局单例，难以多世界并存或单元测试。
- **操作队列串行化**：高负载时操作积压，无法并行处理多个独立 chunk。

#### 定位

**适合**：学习 Unity 内置 Tilemap 之上搭建 async chunk 流式加载框架；理解引用计数式卸载和操作队列串行化。
**不适合**：高性能大世界（Tilemap 渲染瓶颈 + LINQ GC）；需要 seed 可复现；多人游戏；移动端。

---

### 3.8 0PaiPai0/AdvancedTilemap

#### 仓库状态

| 项目 | 内容 |
|------|------|
| 最后 push | 2024-02-17 |
| 主要语言 | C# |
| License | MIT |
| Star | 0 |
| Unity 版本 | **2023.2.10f1** |

#### 世界模型

**离散瓦片模型**，完全自绘 Mesh，不使用 Unity Tilemap。chunk 内部用 `AChunkData` 存储 6 个并行数组：

```csharp
public class AChunkData
{
    public ushort[] data;          // tile ID
    public byte[] bitmaskData;     // 8 位 autotile bitmask
    public Color32[] colors;       // per-tile 颜色
    public bool[] collision;       // 碰撞标记
    public byte[] variations;      // 纹理变体
    public UVTransform[] transforms; // UV 变换
}
```

支持多层（`List<ALayer>`）和液体（`ALiquidChunk`，独立 `float[]` 数据）。

#### 大世界策略

**分区单位**：固定 16×16（`AChunk.CHUNK_SIZE = 16`，硬编码）。chunk 坐标编码为 `uint key = (chunkY << 16) | (chunkX & 0xFFFF)`。

**加载触发**：⚠️ **没有基于相机/玩家位置的自动 chunk 流式加载**。chunk 在 `SetTile()` 时按需创建，创建后常驻内存。这是「无限画布」模型——chunk 随绘制产生，不随距离卸载。

**加载方式**：同步创建（主线程 `new GameObject()`）。Mesh 生成支持 `DummyMeshJob`（同步）或 `ThreadMeshJob`（裸 `System.Threading.Thread` + `while(thread.IsAlive){}` 自旋等待）。**不是 Job System，不是 Burst**。

**卸载策略**：**没有自动卸载**。只有手动 `Trim()`：删除 `IsEmpty()` 的 chunk（全 0）。这不是 LRU、不是引用计数——纯粹是「空 chunk 回收」。

**渲染路径**：完全自绘 Mesh。`MeshData` 维护 `List<Vector3> vertices`、`List<int> triangles`、`List<Vector2> uv`、`List<Color32> colors`。`DefaultTileDriver` 画 quad，`StarboundTileDriver` 根据 bitmask 画多个 sub-quad 实现平滑过渡。UV 边缘有 `GAP_FIX = 0.00625f` 偏移防止纹理渗漏。

#### 程序化生成

⚠️ **无程序化生成代码**。纯 tilemap 引擎/编辑器，世界内容通过编辑器笔刷工具手动绘制。

#### 可编辑地形

✅ dig/place 完整实现。✅ undo/redo（命令模式，`ATilemapCommand` 记录 `List<TileData>` 变更，两个 Stack）。⚠️ 未能从代码确认有运行时存档。

#### 物理/碰撞

**自定义碰撞网格生成**，使用 `PolygonCollider2D`。遍历 chunk 的 `bool[] collision` 数组，对每个有碰撞的 tile 检查 4 个邻居生成暴露边线段，`FindPath()` 把线段首尾相连组装成闭合路径。比 Unity Tilemap 的 per-tile collider 更高效。

#### 液体模拟

Starbound 风格元胞自动机，`SimulateLiquid()` 在主线程 `Update()` 中按 10fps 步进。向下流动（重力）+ 水平扩散 + `MAX_FLOW` 限制。

#### 坑点与风险

- **没有 chunk 流式加载——大世界内存爆炸（最严重缺陷）**。10000×10000 的世界只要画过就会留下 chunk GameObject。`Trim()` 只删全空 chunk。若要做真正的大世界，必须自行实现 chunk 流式加载层。
- **裸 Thread 而非 Job System**：`while(thread.IsAlive){}` 自旋等待是忙等，浪费 CPU。无 Burst SIMD 优化。
- **GC 压力**：`List<T>.ToArray()` 每次产生数组分配。`FindPath()` 中大量 `List<List<Vector2>>` 和 `segments.Remove()`（O(n)）。
- **坐标编码限制**：16 位 per axis，范围 -32768~32767，超出溢出冲突。

#### 定位

**适合**：Starbound/Terraria 风格 2D 沙盒原型；需要自定义 autotile、液体物理、多层 tilemap 的项目；编辑器内 tilemap 设计工具。
**不适合**：超大世界（无 chunk 流式加载）；移动端（裸 Thread + GC）；需要程序化生成；需要运行时存档。

---

## 4. 架构模式提炼

从这批方案中抽象出 3 种主流做法：

### Pattern A：TileMapLayer + 视距 chunk 实例场景（Godot 最常见）

**代表项目**：cosei-indie、overmapchunkdemo、Gaea

**核心思路**：使用引擎内置 TileMap/TileMapLayer 作为渲染层，chunk 作为逻辑分区单位，按玩家视距加载/卸载 chunk 范围内的 tile cells。

**数据流**：
```
Noise 采样 → 高度/阈值判定 → TileMapLayer.set_cell() / set_cells_terrain_connect()
```

**优点**：
- 开发速度快，引擎原生 API 即可完成
- `set_cells_terrain_connect` 自动处理瓦片过渡
- 碰撞由 TileSet physics layer 自动生成

**缺点**：
- `set_cell` 逐个调用在大 chunk 时性能不佳
- TileMap 内部维护 cell 字典，大世界下内存开销大于原始数组
- 渲染受限于 TileMapLayer 的 batching 策略，无法做 per-tile shader 特效
- Godot 3.x→4.x TileMap→TileMapLayer 迁移成本（API 完全变更）

**适用场景**：俯视角 2D 游戏、快速原型、不需要 per-tile 精细渲染特效的项目。

### Pattern B：自定义 tile buffer（PackedByteArray/Image）+ GPU 上传（高性能可编辑）

**代表项目**：Substrata-Game、AdvancedTilemap（Unity 对照）

**核心思路**：tile 数据存储在紧凑的自定义数组（`PackedByteArray` / `ushort[]`）中，不经过 TileMap，直接生成 Image/Mesh 上传 GPU 渲染。

**数据流（Substrata-Game）**：
```
PackedByteArray → Image(RGBA8) → ImageTexture → fragment shader 解码 tile_id → Texture2DArray 采样
```

**数据流（AdvancedTilemap）**：
```
ushort[] data → bitmask 计算 → MeshData(List<Vector3/int/Vector2>) → MeshFilter/MeshRenderer
```

**优点**：
- 内存极紧凑（Substrata 每 tile 仅 2 字节 vs TileMap cell 字典开销）
- 渲染完全可控——可做 per-tile shader 特效、Texture2DArray 批量采样
- 绕过 TileMap 性能瓶颈，不受 3.x→4.x API 迁移影响
- 编辑地形时只需更新 ImageTexture（`_data_texture.update(_terrain_image)`），无需逐 cell 调用 API

**缺点**：
- 开发复杂度高——需自写 shader、自管理 UV、自处理 autotile bitmask
- 碰撞需自建（Substrata 用 swept AABB，AdvancedTilemap 用 PolygonCollider2D 路径合并）
- 无引擎编辑器集成（无法在 Godot 编辑器中用 TileSet 编辑器绘制）
- Y 轴坐标系对齐容易出错（PackedByteArray 行优先 vs Image 坐标系）

**适用场景**：Terraria 式可编辑沙盒、需要 per-tile 渲染特效、超高吞吐量大世界、长期可维护项目。

### Pattern C：Unity Tilemap + ChunkOperation 队列 + coroutine（Unity 路线）

**代表项目**：Islands

**核心思路**：在 Unity 内置 Tilemap 之上搭建异步 chunk 流式加载框架，所有 chunk 操作封装为 `IChunkOperation` 入队串行执行，用 `async/await + Task.Run` 做后台 I/O。

**数据流**：
```
IChunkOperation 入队 → ProcessOperations() 串行 await Execute() → Task.Run 文件 I/O → Tilemap.SetTiles()
```

**优点**：
- 操作队列串行化避免并发冲突
- 引用计数式卸载支持多 ChunkLoader 共享 chunk
- dirty chunk 自动保存

**缺点**：
- Unity Tilemap 渲染瓶颈（`SetTiles` 触发 redraw + collider 重建）
- GC 压力严重（LINQ + string ID + Dictionary 分配）
- `async void Update()` 异常不安全
- `BinaryFormatter` 安全漏洞
- 操作串行化导致高负载积压

**适用场景**：Unity 项目中中小规模 2D tile 世界（几百个 chunk），作为流式加载设计模式参考。

---

## 5. 选型建议

### 需求卡 1：俯视角连续地形 + 车辆/寻路

**倾向：Gaea（生成层）+ 自建 chunk 流式层**

理由：Gaea 提供最成熟的程序化生成框架（节点图 + 多线程 + seed 可复现 + TileMapLayer 渲染），但其 chunk 流式加载较基础。对于俯视角连续地形，不需要 per-tile 挖掘，TileMapLayer 的 `set_cells_terrain_connect` 足以处理瓦片过渡。寻路可使用 Godot 4 的 `NavigationServer2D` + TileMapLayer 的 navigation layer。

若需更精细的视距管理，可参考 OWDB 的多尺寸 chunk + 引用计数模型，但 OWDB 是 3D 节点系统，需适配为 2D tile 场景。

### 需求卡 2：Terraria 式挖掘编辑 + 液体 + 物理

**倾向：Substrata-Game（架构蓝本）+ AdvancedTilemap（autotile/液体参考）**

理由：Substrata-Game 是 8 个仓库中唯一同时具备「可编辑地形 + 自定义物理 + 多线程生成 + chunk pooling + 背压 + 自动存盘」的项目。其 `PackedByteArray → Image → shader → Texture2DArray` 渲染管线可直接复用。

液体模拟参考 AdvancedTilemap 的 Starbound 风格元胞自动机（向下流动 + 水平扩散 + MAX_FLOW 限制）。autotile 参考 AdvancedTilemap 的 8 位 bitmask + StarboundTileDriver sub-quad 拆分。

需自行补齐：biome 系统（Substrata 无 biome）、floating origin（远离原点精度问题）、undo 栈（Substrata 有 `old_tile_id` 信号但无 undo 栈，可参考 AdvancedTilemap 的命令模式）。

### 需求卡 3：最快出原型

**倾向：Gaea（Godot 4.x 插件）**

理由：Gaea 是唯一一个「安装即用」的成熟插件——MIT 协议、115 stars、活跃维护、可视化节点图编辑器、内置 chunk 流式加载。安装 addon 后在编辑器中拖节点连线即可生成世界，无需写底层架构代码。其 `GaeaChunkLoader` + `TileMapGaeaRenderer` 开箱即用，`FloorWalker` 节点可快速生成地牢。

代价：无运行时编辑、无物理、无网络——但原型阶段不需要这些。

### 需求卡 4：长期可维护 / 可扩展

**倾向：Substrata-Game（架构骨架）+ Gaea（生成层插件）**

理由：Substrata-Game 的架构设计最适合长期维护：
- 自绘 shader 渲染绕过 TileMap API 变更风险（3.x→4.x 迁移对它无影响）
- `PackedByteArray` 数据存储极紧凑且格式自控
- WorkerThreadPool + 背压 + pooling 的内存管理模型可扩展
- `CLAUDE.md` 架构文档使代码可读性高
- Region→Chunk→Tile 三级分区支持超大规模世界

Gaea 作为生成层插件可独立升级（addon 形式），其节点图系统允许非程序员调整生成逻辑，降低长期维护成本。

**需规避**：cosei-indie（无 License）、Godot-2DMap（Godot 3.x 已废弃）、overmapchunkdemo（无卸载机制）、Islands（2018 + BinaryFormatter 安全漏洞）。

---

## 附录：调查方法说明

本报告通过以下方法获取代码级证据：

1. `gh api repos/{owner}/{repo}` 获取仓库元数据（star、push 时间、license、大小）
2. `gh api repos/{owner}/{repo}/git/trees/{branch}?recursive=1` 获取完整文件树
3. `gh api repos/{owner}/{repo}/contents/{path}` 逐文件下载关键源码
4. 逐行精读 `project.godot`（确认引擎版本）、核心架构脚本（确认 chunk/线程/渲染策略）、shader 文件（确认渲染管线）

所有代码片段均引自实际源码，非复述 README。无法从代码确认的信息已标注「⚠️ 未能从代码确认」。

---

*报告完*
