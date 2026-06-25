# Snowhuman Framework

Snowhuman Framework 是一个可复用的 Godot 游戏框架 addon。

当前状态：早期框架骨架。

当前包含：

- `GameCore`
- `DataRegistry`
- `EventBus`
- `SaveService`
- `InventoryService`
- `InteractionService` 和 `BestiaryService` 的服务骨架

## 启用方式

将 addon 保持在 `game/addons/snowhuman_framework/`，并在 Godot 项目中启用 `Snowhuman Framework`。

启用后，addon 会注册当前框架需要的 autoload。`InventoryService` 不是 autoload，需要由项目代码实例化，或后续由核心管理器统一管理。

## InventoryService

`InventoryService` 提供基础的、按 `owner_id` 区分的 `item_id`/`count` 管理能力。

它通过 `DataRegistry` 校验 `item_id`，从 item 数据读取 `stack_size`，并在指定 owner 的背包发生成功变更后发出 `EventBus.inventory_changed`。

## 重要限制

Snowhuman Framework 不包含项目专属内容。内容数据应放在 `game/data/`，或放在 addon 外部的项目脚本中。
