# Snowhuman Framework

Snowhuman Framework 是一个可复用的 Godot 游戏框架 addon。

当前状态：早期框架骨架。

当前包含：

- `GameCore`
- `DataRegistry`
- `EventBus`
- `SaveService`：支持 provider 保存 / 读取。
- `InventoryService`
- `BestiaryService`：支持 creature / item 发现记录。
- `InteractionService` 的服务骨架

## 启用方式

将 addon 保持在 `game/addons/snowhuman_framework/`，并在 Godot 项目中启用 `Snowhuman Framework`。

启用后，addon 会注册当前框架需要的 autoload。`InventoryService` 不是 autoload，需要由项目代码实例化，或后续由核心管理器统一管理。

## InventoryService

`InventoryService` 提供基础的、按 `owner_id` 区分的 `item_id`/`count` 管理能力。

它通过 `DataRegistry` 校验 `item_id`，从 item 数据读取 `stack_size`，并在指定 owner 的背包发生成功变更后发出 `EventBus.inventory_changed`。

## SaveService

`SaveService` 提供通用 provider 持久化能力。provider 必须提供：

```gdscript
get_save_data() -> Dictionary
load_save_data(data: Dictionary) -> bool
```

详细设计见 `rfcs/0003-save-service.md`。

## BestiaryService

`BestiaryService` 提供通用发现记录能力，可按 `owner_id` 记录已发现的 creature 和 item。

它依赖 `DataRegistry` 校验 `creature_id` 和 `item_id`，并提供 `SaveService` 适配辅助接口，但不会直接注册到 `SaveService`。

详细设计见 `rfcs/0004-bestiary-service.md`。

## 重要限制

Snowhuman Framework 不包含项目专属内容。内容数据应放在 `game/data/`，或放在 addon 外部的项目脚本中。
