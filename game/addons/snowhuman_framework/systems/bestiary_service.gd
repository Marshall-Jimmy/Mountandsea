extends RefCounted
class_name BestiaryService

var _creatures_by_owner: Dictionary = {}
var _items_by_owner: Dictionary = {}


func discover_creature(owner_id: String, creature_id: String) -> bool:
	if not _is_valid_owner_id(owner_id, "discover_creature"):
		return false
	if creature_id.is_empty():
		push_error("BestiaryService.discover_creature: creature_id 不能为空。")
		return false

	var data_registry := _get_data_registry()
	if data_registry == null:
		return false
	if not data_registry.has_creature(creature_id):
		push_error("BestiaryService.discover_creature: creature_id 不存在于 DataRegistry：%s" % creature_id)
		return false

	var owner_entries := _get_or_create_owner_entries(_creatures_by_owner, owner_id)
	var is_first_discovery := not owner_entries.has(creature_id)
	owner_entries[creature_id] = true

	if is_first_discovery:
		_emit_entry_discovered(owner_id, "creature", creature_id)

	return true


func discover_item(owner_id: String, item_id: String) -> bool:
	if not _is_valid_owner_id(owner_id, "discover_item"):
		return false
	if item_id.is_empty():
		push_error("BestiaryService.discover_item: item_id 不能为空。")
		return false

	var data_registry := _get_data_registry()
	if data_registry == null:
		return false
	if not data_registry.has_item(item_id):
		push_error("BestiaryService.discover_item: item_id 不存在于 DataRegistry：%s" % item_id)
		return false

	var owner_entries := _get_or_create_owner_entries(_items_by_owner, owner_id)
	var is_first_discovery := not owner_entries.has(item_id)
	owner_entries[item_id] = true

	if is_first_discovery:
		_emit_entry_discovered(owner_id, "item", item_id)

	return true


func has_discovered_creature(owner_id: String, creature_id: String) -> bool:
	if owner_id.is_empty() or creature_id.is_empty():
		return false
	if not _creatures_by_owner.has(owner_id):
		return false

	return _creatures_by_owner[owner_id].has(creature_id)


func has_discovered_item(owner_id: String, item_id: String) -> bool:
	if owner_id.is_empty() or item_id.is_empty():
		return false
	if not _items_by_owner.has(owner_id):
		return false

	return _items_by_owner[owner_id].has(item_id)


func get_discovered_creatures(owner_id: String) -> Array:
	return _get_sorted_owner_entry_ids(_creatures_by_owner, owner_id)


func get_discovered_items(owner_id: String) -> Array:
	return _get_sorted_owner_entry_ids(_items_by_owner, owner_id)


func get_entry_count(owner_id: String) -> int:
	if owner_id.is_empty():
		return 0

	return get_discovered_creatures(owner_id).size() + get_discovered_items(owner_id).size()


func clear_owner(owner_id: String) -> void:
	if owner_id.is_empty():
		return

	_creatures_by_owner.erase(owner_id)
	_items_by_owner.erase(owner_id)


func clear_all() -> void:
	_creatures_by_owner.clear()
	_items_by_owner.clear()


func get_save_data_for_owner(owner_id: String) -> Dictionary:
	return {
		"creatures": get_discovered_creatures(owner_id),
		"items": get_discovered_items(owner_id)
	}


func load_save_data_for_owner(owner_id: String, data: Dictionary) -> bool:
	if not _is_valid_owner_id(owner_id, "load_save_data_for_owner"):
		return false
	if not (data is Dictionary):
		push_error("BestiaryService.load_save_data_for_owner: data 必须是 Dictionary。")
		return false

	var data_registry := _get_data_registry()
	if data_registry == null:
		return false

	var creature_ids: Variant = data.get("creatures", [])
	var item_ids: Variant = data.get("items", [])
	if not (creature_ids is Array):
		push_error("BestiaryService.load_save_data_for_owner: creatures 必须是 Array。")
		return false
	if not (item_ids is Array):
		push_error("BestiaryService.load_save_data_for_owner: items 必须是 Array。")
		return false

	var loaded_creatures := {}
	for creature_id in creature_ids:
		if not (creature_id is String) or creature_id.is_empty():
			push_error("BestiaryService.load_save_data_for_owner: creature id 必须是非空 String。")
			return false
		if not data_registry.has_creature(creature_id):
			push_error("BestiaryService.load_save_data_for_owner: creature_id 不存在于 DataRegistry：%s" % creature_id)
			return false
		loaded_creatures[creature_id] = true

	var loaded_items := {}
	for item_id in item_ids:
		if not (item_id is String) or item_id.is_empty():
			push_error("BestiaryService.load_save_data_for_owner: item id 必须是非空 String。")
			return false
		if not data_registry.has_item(item_id):
			push_error("BestiaryService.load_save_data_for_owner: item_id 不存在于 DataRegistry：%s" % item_id)
			return false
		loaded_items[item_id] = true

	if loaded_creatures.is_empty():
		_creatures_by_owner.erase(owner_id)
	else:
		_creatures_by_owner[owner_id] = loaded_creatures

	if loaded_items.is_empty():
		_items_by_owner.erase(owner_id)
	else:
		_items_by_owner[owner_id] = loaded_items

	return true


func _is_valid_owner_id(owner_id: String, method_name: String) -> bool:
	if owner_id.is_empty():
		push_error("BestiaryService.%s: owner_id 不能为空。" % method_name)
		return false

	return true


func _get_or_create_owner_entries(collection: Dictionary, owner_id: String) -> Dictionary:
	if not collection.has(owner_id):
		collection[owner_id] = {}

	return collection[owner_id]


func _get_sorted_owner_entry_ids(collection: Dictionary, owner_id: String) -> Array:
	if owner_id.is_empty() or not collection.has(owner_id):
		return []

	var entry_ids: Array = collection[owner_id].keys()
	entry_ids.sort()
	return entry_ids


func _get_data_registry() -> Variant:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		push_error("BestiaryService: SceneTree 不可用，无法查找 DataRegistry。")
		return null

	var data_registry := (main_loop as SceneTree).root.get_node_or_null("DataRegistry")
	if data_registry == null:
		push_error("BestiaryService: DataRegistry 不可用。")

	return data_registry


func _get_event_bus() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null

	return (main_loop as SceneTree).root.get_node_or_null("EventBus")


func _emit_entry_discovered(owner_id: String, entry_type: String, entry_id: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus == null:
		return

	if event_bus.has_signal("bestiary_entry_discovered"):
		event_bus.emit_signal("bestiary_entry_discovered", owner_id, entry_type, entry_id)
	elif event_bus.has_signal("bestiary_changed"):
		event_bus.emit_signal("bestiary_changed", owner_id)
