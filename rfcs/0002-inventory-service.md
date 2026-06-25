# RFC 0002: InventoryService

## Status

Draft

## Goal

定义通用背包接口，支持 owner 维度的 item_id/count 管理。

## Non-goals

- 不处理 UI
- 不处理装备栏
- 不处理快捷栏
- 不处理采集交互
- 不处理存档持久化
- 不处理山海经专属逻辑

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

## Data Format

InventoryService stores inventories by owner id. Each owner inventory is an array of item stacks:

```gdscript
[
	{
		"item_id": "example_item",
		"count": 10,
	}
]
```

The inventory only stores `item_id` and `count`. It does not duplicate item metadata such as `name`, `description`, or `type`. Callers should query `DataRegistry` when they need item definitions.

## Error Handling

InventoryService returns `false` and reports a clear error when a mutating operation receives:

- an empty `owner_id`
- an empty `item_id`
- a `count` less than or equal to 0
- an `item_id` that does not exist in `DataRegistry`
- an item definition with an invalid `stack_size`
- a remove request where the owner does not have enough items

Read-only queries return safe defaults: missing owners and missing items return `false`, `0`, empty arrays, or `true` for `is_empty()` as appropriate.

## Relationship With Other Modules

- Depends on `DataRegistry` to validate `item_id` and read `stack_size`
- Emits `EventBus.inventory_changed` after successful owner inventory changes
- Does not directly depend on `SaveService`
- Does not directly depend on UI

## Validation Criteria

- Items can be added for a non-empty owner id when the item exists in `DataRegistry`
- Added items stack up to the item `stack_size`
- Overflow creates additional stacks
- Items can be removed only when the owner has enough total count
- Removing items deletes empty stacks
- `get_items()` returns a deep duplicate so callers cannot mutate internal state
- Clearing one inventory emits an inventory changed event
- Clearing all inventories does not emit per-owner events
- The service stores only `item_id` and `count`

## Notes

Future RFCs may extend inventory behavior with equipment, hotbar support, capacity limits, persistence, or richer stack metadata. Those features are not part of this RFC.
