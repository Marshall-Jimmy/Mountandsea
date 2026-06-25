# RFC 0005：InteractionService

## 状态

草案

## 目标

定义通用交互服务，用于注册可交互对象，并由 actor 执行通用交互。

## 非目标

- 不处理 UI。
- 不处理地图系统。
- 不处理任务系统。
- 不处理战斗系统。
- 不直接依赖 `InventoryService`。
- 不直接依赖 `BestiaryService`。
- 不处理山海经专属逻辑。

## API

```gdscript
InteractionService.register_interactable(interactable_id: String, data: Dictionary) -> bool
InteractionService.unregister_interactable(interactable_id: String) -> void
InteractionService.has_interactable(interactable_id: String) -> bool
InteractionService.get_interactable(interactable_id: String) -> Dictionary
InteractionService.get_all_interactables() -> Array
InteractionService.clear() -> void
InteractionService.can_interact(actor_id: String, interactable_id: String) -> bool
InteractionService.interact(actor_id: String, interactable_id: String) -> bool
```

## Interactable 数据格式

`register_interactable()` 接收 `Dictionary`，支持以下字段：

```gdscript
{
	"type": "generic",
	"enabled": true,
	"callback_target": Object,
	"callback_method": "method_name",
	"metadata": {}
}
```

- `type` 是可选 `String`，默认值为 `"generic"`。
- `enabled` 是可选 `bool`，默认值为 `true`。
- `callback_target` 是可选 `Object`。
- `callback_method` 是可选 `String`。
- `metadata` 是可选 `Dictionary`，默认值为 `{}`。

注册成功时，服务会复制输入数据，不直接保存外部 `Dictionary` 引用。

## 交互流程

`can_interact(actor_id, interactable_id)` 只做静态判断：

- `actor_id` 必须非空。
- `interactable_id` 必须已注册。
- interactable 的 `enabled` 必须为 `true`。
- 不调用 callback。

`interact(actor_id, interactable_id)` 先调用 `can_interact()`。如果不能交互，返回 `false`。

如果 interactable 没有 callback，则交互直接成功。若存在 callback，则调用：

```gdscript
callback_target.call(callback_method, actor_id, interactable_id, metadata)
```

callback 返回 `bool` 时使用该值作为交互结果。callback 返回其他类型或没有返回值时，视为交互成功。

## 错误处理

以下情况会返回 `false` 并通过 `push_error()` 输出原因：

- `interactable_id` 为空。
- `actor_id` 为空。
- `data` 不是 `Dictionary`。
- `type` 不是非空 `String`。
- `enabled` 不是 `bool`。
- `metadata` 不是 `Dictionary`。
- 提供了 `callback_target` 但缺少非空 `callback_method`。
- 提供了 `callback_method` 但缺少 `callback_target`。
- `callback_target` 上不存在 `callback_method`。
- callback 返回 `false`。

## 与其他模块的关系

- 可由项目层 callback 调用 `InventoryService` 或 `BestiaryService`。
- `InteractionService` 本身不直接依赖这些模块。
- `EventBus` 只作为可选通知机制；当前版本不新增交互专用信号。
- 不依赖 UI 和场景。

## 验收标准

- 可以注册和覆盖 interactable。
- 可以注销 interactable。
- 可以查询单个 interactable。
- 可以获取按 id 排序的全部 interactable。
- `get_interactable()` 和 `get_all_interactables()` 返回复制数据，避免外部修改内部状态。
- `can_interact()` 不调用 callback。
- 无 callback 的 `interact()` 可以成功。
- 有 callback 的 `interact()` 会调用目标方法。
- callback 返回 `false` 时，`interact()` 返回 `false`。
- `clear()` 会清空所有 interactable。

## 备注

后续 RFC 可以扩展距离检测、交互优先级、交互提示文本、冷却时间、权限条件或专用事件。本 RFC 不实现这些能力。
