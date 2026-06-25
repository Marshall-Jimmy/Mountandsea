# RFC 0002：InventoryService

## 状态

草案

## 目标

定义通用背包接口，支持 `owner_id` 维度的 `item_id`/`count` 管理。

## 非目标

- 不处理 UI
- 不处理装备栏
- 不处理快捷栏
- 不处理采集交互
- 不处理存档持久化
- 不处理项目专属逻辑

## API

```gdscript
InventoryService.add_item(owner_id: String, item_id: String, count: int) -> bool
InventoryService.remove_item(owner_id: String, item_id: String, count: int) -> bool
InventoryService.has_item(owner_id: String, item_id: String, count: int) -> bool
InventoryService.get_item_count(owner_id: String, item_id: String) -> int
InventoryService.get_items(owner_id: String) -> Array
InventoryService.clear_inventory(owner_id: String) -> void
InventoryService.clear_all() -> void
InventoryService.is_empty(owner_id: String) -> bool
```

## 数据格式

InventoryService 按 `owner_id` 存储背包。每个 owner 的背包是 item stack 数组：

```gdscript
[
	{
		"item_id": "example_item",
		"count": 10,
	}
]
```

背包内部只保存 `item_id` 和 `count`。它不会复制 `name`、`description`、`type` 等 item 元数据。调用方需要 item 定义时，应查询 `DataRegistry`。

## 错误处理

当修改类操作遇到以下情况时，InventoryService 返回 `false` 并报告清晰错误：

- `owner_id` 为空。
- `item_id` 为空。
- `count` 小于或等于 0。
- `item_id` 不存在于 `DataRegistry`。
- item 定义中的 `stack_size` 非法。
- remove 请求的数量超过当前 owner 持有数量。

只读查询返回安全默认值：owner 不存在或 item 不存在时，根据接口语义返回 `false`、`0`、空数组，或在 `is_empty()` 中返回 `true`。

## 与其他模块的关系

- 依赖 `DataRegistry` 校验 `item_id` 并读取 `stack_size`。
- 指定 owner 的背包成功变更后发出 `EventBus.inventory_changed`。
- 不直接依赖 `SaveService`。
- 不直接依赖 UI。

## 验收标准

- 当 `owner_id` 非空且 item 存在于 `DataRegistry` 时，可以添加 item。
- 添加 item 时会按 item 的 `stack_size` 堆叠。
- 超出单 stack 容量时会创建额外 stack。
- 只有 owner 总数量足够时才能移除 item。
- 移除 item 后，数量为 0 的 stack 会被删除。
- `get_items()` 返回 deep duplicate，调用方不能修改内部状态。
- 清空单个 owner 背包会发出 inventory changed 事件。
- 清空所有背包不会逐个 owner 发事件。
- 服务内部只保存 `item_id` 和 `count`。

## 备注

后续 RFC 可以扩展装备、快捷栏、容量限制、持久化或更丰富的 stack 元数据。本 RFC 不实现这些能力。
