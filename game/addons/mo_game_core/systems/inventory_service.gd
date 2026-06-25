extends RefCounted
class_name InventoryService

var _inventories_by_owner: Dictionary = {}


func add_item(owner_id: String, item_id: String, count: int) -> bool:
	if not _is_valid_owner_id(owner_id):
		push_error("InventoryService.add_item: owner_id must not be empty.")
		return false
	if not _is_valid_item_id(item_id):
		return false
	if count <= 0:
		push_error("InventoryService.add_item: count must be greater than 0.")
		return false

	var stack_size := _get_stack_size(item_id)
	if stack_size <= 0:
		return false

	var inventory := _get_or_create_inventory(owner_id)
	var remaining := count

	for stack in inventory:
		if stack.get("item_id", "") != item_id:
			continue

		var current_count: int = stack.get("count", 0)
		if current_count >= stack_size:
			continue

		var space := stack_size - current_count
		var added_count: int = min(space, remaining)
		stack["count"] = current_count + added_count
		remaining -= added_count

		if remaining <= 0:
			_emit_inventory_changed(owner_id)
			return true

	while remaining > 0:
		var stack_count: int = min(stack_size, remaining)
		inventory.append({
			"item_id": item_id,
			"count": stack_count
		})
		remaining -= stack_count

	_emit_inventory_changed(owner_id)
	return true


func remove_item(owner_id: String, item_id: String, count: int) -> bool:
	if not _is_valid_owner_id(owner_id):
		push_error("InventoryService.remove_item: owner_id must not be empty.")
		return false
	if not _is_valid_item_id(item_id):
		return false
	if count <= 0:
		push_error("InventoryService.remove_item: count must be greater than 0.")
		return false
	if get_item_count(owner_id, item_id) < count:
		push_error("InventoryService.remove_item: not enough items to remove.")
		return false

	var inventory: Array = _inventories_by_owner[owner_id]
	var remaining := count
	var index := 0

	while index < inventory.size() and remaining > 0:
		var stack: Dictionary = inventory[index]
		if stack.get("item_id", "") != item_id:
			index += 1
			continue

		var current_count: int = stack.get("count", 0)
		var removed_count: int = min(current_count, remaining)
		current_count -= removed_count
		remaining -= removed_count

		if current_count <= 0:
			inventory.remove_at(index)
		else:
			stack["count"] = current_count
			index += 1

	if inventory.is_empty():
		_inventories_by_owner.erase(owner_id)

	_emit_inventory_changed(owner_id)
	return true


func has_item(owner_id: String, item_id: String, count: int) -> bool:
	if count <= 0:
		return false
	if owner_id.is_empty() or item_id.is_empty():
		return false
	if not _item_exists(item_id):
		return false
	if not _inventories_by_owner.has(owner_id):
		return false

	return get_item_count(owner_id, item_id) >= count


func get_item_count(owner_id: String, item_id: String) -> int:
	if owner_id.is_empty() or item_id.is_empty():
		return 0
	if not _item_exists(item_id):
		return 0
	if not _inventories_by_owner.has(owner_id):
		return 0

	var total := 0
	for stack in _inventories_by_owner[owner_id]:
		if stack.get("item_id", "") == item_id:
			total += stack.get("count", 0)

	return total


func get_items(owner_id: String) -> Array:
	if not _inventories_by_owner.has(owner_id):
		return []

	var inventory: Array = _inventories_by_owner[owner_id]
	return inventory.duplicate(true)


func clear_inventory(owner_id: String) -> void:
	if not _inventories_by_owner.has(owner_id):
		return

	_inventories_by_owner.erase(owner_id)
	_emit_inventory_changed(owner_id)


func clear_all() -> void:
	_inventories_by_owner.clear()


func is_empty(owner_id: String) -> bool:
	if not _inventories_by_owner.has(owner_id):
		return true

	var inventory: Array = _inventories_by_owner[owner_id]
	return inventory.is_empty()


func _is_valid_owner_id(owner_id: String) -> bool:
	return not owner_id.is_empty()


func _is_valid_item_id(item_id: String) -> bool:
	if item_id.is_empty():
		push_error("InventoryService: item_id must not be empty.")
		return false
	if not _item_exists(item_id):
		push_error("InventoryService: item_id does not exist in DataRegistry: %s" % item_id)
		return false

	return true


func _item_exists(item_id: String) -> bool:
	return DataRegistry.has_item(item_id)


func _get_stack_size(item_id: String) -> int:
	var item := DataRegistry.get_item(item_id)
	var stack_size: Variant = item.get("stack_size", 0)

	if stack_size is int and stack_size > 0:
		return stack_size
	if stack_size is float and stack_size > 0.0 and floor(stack_size) == stack_size:
		return int(stack_size)

	push_error("InventoryService: item stack_size must be a positive integer: %s" % item_id)
	return 0


func _get_or_create_inventory(owner_id: String) -> Array:
	if not _inventories_by_owner.has(owner_id):
		_inventories_by_owner[owner_id] = []

	return _inventories_by_owner[owner_id]


func _emit_inventory_changed(owner_id: String) -> void:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return

	var event_bus := (main_loop as SceneTree).root.get_node_or_null("EventBus")
	if event_bus != null and event_bus.has_signal("inventory_changed"):
		event_bus.emit_signal("inventory_changed", owner_id)
