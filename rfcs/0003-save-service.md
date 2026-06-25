# RFC 0003：SaveService

## 状态

草案

## 目标

定义通用保存服务，通过 provider 机制收集和恢复模块状态。

## 非目标

- 不绑定具体 gameplay 系统。
- 不直接依赖 `InventoryService`。
- 不处理云存档。
- 不处理多用户账号。
- 不处理加密。
- 不处理压缩。
- 不处理山海经专属内容。

## API

```gdscript
SaveService.register_provider(provider_id: String, provider: Object) -> bool
SaveService.unregister_provider(provider_id: String) -> void
SaveService.has_provider(provider_id: String) -> bool
SaveService.get_registered_provider_ids() -> Array
SaveService.clear_providers() -> void
SaveService.save_slot(slot: int) -> bool
SaveService.load_slot(slot: int) -> bool
SaveService.get_slot_path(slot: int) -> String
```

## Provider 接口

provider 是外部对象，必须实现：

```gdscript
get_save_data() -> Dictionary
load_save_data(data: Dictionary) -> bool
```

`SaveService` 只负责调用 provider 接口，不保存具体玩法系统的内部结构，也不直接依赖 `InventoryService`。

## 数据格式

保存文件写入 `user://saves/slot_<slot>.json`，顶层结构如下：

```json
{
	"version": "0.1.0",
	"slot": 0,
	"saved_at_unix": 1234567890,
	"providers": {
		"provider_id": {}
	}
}
```

`providers` 下的 key 是 `provider_id`，value 是对应 provider 返回的 `Dictionary`。

保存文件中存在、但当前未注册的 `provider_id` 会被忽略，便于模块拆分或版本迭代。

## 错误处理

以下情况会导致操作失败，并通过 `push_error()` 输出原因；保存或读取 slot 时会尝试发出 `EventBus.save_failed`：

- `slot` 小于 0。
- `provider_id` 为空。
- `provider` 为 `null`。
- provider 缺少 `get_save_data()`。
- provider 缺少 `load_save_data(data)`。
- 保存目录创建失败。
- 文件打开失败。
- JSON 解析失败。
- 保存文件顶层结构错误。
- `providers` 字段缺失或不是 `Dictionary`。
- provider 的 `get_save_data()` 返回值不是 `Dictionary`。
- provider 的 `load_save_data(data)` 返回 `false`。

## 与其他模块的关系

- 通过 provider 机制接入其他模块。
- 可由 `InventoryService` 的适配器接入，但本 PR 不实现该适配器。
- 通过 `EventBus.save_requested`、`EventBus.save_completed` 和 `EventBus.save_failed` 发出保存相关信号。
- 当前版本没有新增 `load_completed` 信号；`load_slot()` 成功后暂复用 `EventBus.save_completed` 表示 slot 操作完成。
- 不直接依赖 UI。

## 验收标准

- 可以注册、注销、查询和清理 provider。
- 注册 provider 时会校验 `provider_id`、对象存在性和必需方法。
- `save_slot()` 会创建 `user://saves` 并写入 `slot_<slot>.json`。
- `save_slot()` 会把所有 provider 的 `Dictionary` 数据写入统一 JSON。
- `load_slot()` 会读取 JSON，并把当前已注册 provider 的数据交回对应 provider。
- 保存文件中未注册的 provider 数据会被忽略。
- 失败时返回 `false`，并给出清晰错误。
- `SaveService` 不绑定具体 gameplay 系统。

## 备注

后续 RFC 可以扩展多存档元数据、压缩、加密、版本迁移或独立的 load 事件。本 RFC 不实现这些能力。
