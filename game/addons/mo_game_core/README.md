# Mo Game Core

Mo Game Core is a reusable Godot game-core addon.

Current status: early skeleton.

It currently includes:

- `GameCore`
- `DataRegistry`
- `EventBus`
- `SaveService`
- `InventoryService`
- service skeletons for interaction and bestiary-style catalogs

## InventoryService

`InventoryService` provides basic owner-scoped `item_id`/`count` inventory management. It is not an autoload; project code should instantiate it directly or route it through a future core manager.

The service validates item ids through `DataRegistry`, reads stack sizes from item data, and emits `EventBus.inventory_changed` after successful owner inventory changes.

The addon does not include project-specific content. Content data should live in `game/data/` or project scripts outside this addon.
