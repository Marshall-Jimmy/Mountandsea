# RFC 0001：DataRegistry

## 状态

草案

## 目标

DataRegistry 提供统一位置，用于加载 JSON 数据并暴露运行时查询 API。Snowhuman Framework 代码不得硬编码项目内容。内容数据来自 `game/data/`。

## 非目标

- 定义所有未来数据类型。
- 实现编辑器工具。
- 实现 UI。
- 实现背包系统。
- 实现存档或持久化系统。
- 实现交互系统。
- 实现地图系统。
- 实现战斗系统。
- 实现项目专属逻辑。

## API

```gdscript
DataRegistry.load_all() -> bool
DataRegistry.reload_all() -> bool
DataRegistry.get_item(id: String) -> Dictionary
DataRegistry.has_item(id: String) -> bool
DataRegistry.get_all_items() -> Array
DataRegistry.get_creature(id: String) -> Dictionary
DataRegistry.has_creature(id: String) -> bool
DataRegistry.get_all_creatures() -> Array
DataRegistry.clear() -> void
```

`load_all()` 从 JSON 文件加载 item 和 creature 数据。`reload_all()` 先清空当前缓存，再调用 `load_all()`。`clear()` 清空已缓存的 items 和 creatures。

查询方法返回缓存数据的 deep duplicate，避免调用方修改 registry 内部缓存。记录不存在时，`get_item()` 和 `get_creature()` 返回 `{}`。

加载成功且 `EventBus` 存在时，DataRegistry 发出 `data_loaded`。

## 数据格式

初始数据从以下路径加载：

- `game/data/items/items.json`
- `game/data/creatures/creatures.json`

每个顶层文件包含 `version` 字段，以及对应记录类型的数组。

`items.json` 必须包含 `items` 数组。每个 item 必须是 object，并包含：

- `id`
- `name`
- `type`
- `stack_size`

`creatures.json` 必须包含 `creatures` 数组。每个 creature 必须是 object，并包含：

- `id`
- `name`
- `type`

记录 `id` 必须是非空字符串，并且在同一集合内唯一。item 的 `stack_size` 必须是正整数。

## 错误处理

DataRegistry 和 `tools/validate_data.py` 会对以下情况报告清晰错误：

- 文件缺失。
- JSON 解析失败。
- 顶层字段缺失。
- 集合字段不是数组。
- 集合元素不是 object。
- 必填字段缺失。
- `id` 非法。
- `id` 重复。
- item 的 `stack_size` 非法。

运行时加载失败时返回 `false`，并通过 `push_error()` 记录错误。校验脚本失败时以非 0 状态码退出，并使用 `ERROR:` 前缀输出错误。

## 与其他模块的关系

DataRegistry 是由 Snowhuman Framework 注册的 autoload singleton。其他系统可以在运行时查询它，但内容定义仍保留在 addon 外部。

## 验收标准

- 可以加载 `test_item`。
- 可以查询 `test_item`。
- 重复 `id` 会产生错误。
- 缺失字段会被校验脚本检测到。
- Snowhuman Framework 不包含项目专属内容。

## 备注

新增数据集合应先通过后续 RFC 定义，再进入实现。
