# RFC 0004：BestiaryService

## 状态

草案

## 目标

定义通用图鉴 / 发现记录服务，用于记录 owner 已发现的 creature 和 item 条目。

## 非目标

- 不处理 UI。
- 不处理战斗。
- 不处理任务。
- 不处理地图交互。
- 不直接依赖 `InventoryService`。
- 不直接注册 `SaveService`。
- 不处理山海经专属逻辑。

## API

```gdscript
BestiaryService.discover_creature(owner_id: String, creature_id: String) -> bool
BestiaryService.discover_item(owner_id: String, item_id: String) -> bool
BestiaryService.has_discovered_creature(owner_id: String, creature_id: String) -> bool
BestiaryService.has_discovered_item(owner_id: String, item_id: String) -> bool
BestiaryService.get_discovered_creatures(owner_id: String) -> Array
BestiaryService.get_discovered_items(owner_id: String) -> Array
BestiaryService.get_entry_count(owner_id: String) -> int
BestiaryService.clear_owner(owner_id: String) -> void
BestiaryService.clear_all() -> void
BestiaryService.get_save_data_for_owner(owner_id: String) -> Dictionary
BestiaryService.load_save_data_for_owner(owner_id: String, data: Dictionary) -> bool
```

## 数据格式

内部按 `owner_id` 分别保存 creature 和 item 的发现记录。每个 owner 的记录用 `Dictionary` 模拟 Set：

```gdscript
{
	"owner_id": {
		"entry_id": true
	}
}
```

保存辅助接口输出排序后的数组，不直接暴露内部 `Dictionary`：

```gdscript
{
	"creatures": ["creature_id"],
	"items": ["item_id"]
}
```

## 错误处理

以下情况会返回 `false` 并通过 `push_error()` 输出原因：

- `owner_id` 为空。
- `creature_id` 或 `item_id` 为空。
- `DataRegistry` 不可用。
- `creature_id` 不存在于 `DataRegistry`。
- `item_id` 不存在于 `DataRegistry`。
- `load_save_data_for_owner()` 收到的 `creatures` 不是 `Array`。
- `load_save_data_for_owner()` 收到的 `items` 不是 `Array`。
- load 数据中包含非空字符串以外的 id。
- load 数据中包含不存在于 `DataRegistry` 的 id。

重复发现同一条目会返回 `true`，但不会重复插入。

## 与其他模块的关系

- 依赖 `DataRegistry` 校验 `creature_id` 和 `item_id`。
- 可由 `SaveService` provider / adapter 接入，但本 PR 不实现注册。
- 不依赖 UI。
- 不依赖 `InventoryService`。
- 当前 `EventBus` 没有图鉴专用信号；本服务会在信号存在时尝试发出通用发现事件，否则静默跳过。

## 验收标准

- 可以记录 owner 已发现的 creature。
- 可以记录 owner 已发现的 item。
- 重复发现同一条目不会产生重复数据。
- 查询不存在 owner 或空 id 时返回安全默认值。
- `get_discovered_creatures()` 和 `get_discovered_items()` 返回排序后的 id 数组。
- `get_entry_count()` 返回 creature 与 item 的发现总数。
- `clear_owner()` 只清理指定 owner。
- `clear_all()` 清理所有 owner。
- 保存辅助接口输出排序后的数组。
- 读取保存数据时会通过 `DataRegistry` 校验 id。

## 备注

后续 RFC 可以扩展图鉴分类、条目状态、发现时间、详细文本、UI 过滤、专用事件或更完整的 `SaveService` provider。本 RFC 不实现这些能力。
