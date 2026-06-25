extends Node

const ITEMS_PATH := "res://data/items/items.json"
const CREATURES_PATH := "res://data/creatures/creatures.json"

var _items_by_id: Dictionary = {}
var _creatures_by_id: Dictionary = {}

func load_all() -> bool:
	var items_result := _load_collection(ITEMS_PATH, "items", ["id", "name", "type", "stack_size"])
	if not items_result["ok"]:
		return false

	var creatures_result := _load_collection(CREATURES_PATH, "creatures", ["id", "name", "type"])
	if not creatures_result["ok"]:
		return false

	_items_by_id = items_result["entries"]
	_creatures_by_id = creatures_result["entries"]
	_emit_data_loaded()
	return true


func reload_all() -> bool:
	clear()
	return load_all()


func get_item(id: String) -> Dictionary:
	if not has_item(id):
		return {}
	return _items_by_id[id].duplicate(true)


func has_item(id: String) -> bool:
	return _items_by_id.has(id)


func get_all_items() -> Array:
	var items := []
	for item in _items_by_id.values():
		items.append(item.duplicate(true))
	return items


func get_creature(id: String) -> Dictionary:
	if not has_creature(id):
		return {}
	return _creatures_by_id[id].duplicate(true)


func has_creature(id: String) -> bool:
	return _creatures_by_id.has(id)


func get_all_creatures() -> Array:
	var creatures := []
	for creature in _creatures_by_id.values():
		creatures.append(creature.duplicate(true))
	return creatures


func clear() -> void:
	_items_by_id.clear()
	_creatures_by_id.clear()


func _load_collection(path: String, root_key: String, required_fields: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("%s: file does not exist." % path)
		return {"ok": false, "entries": {}}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("%s: failed to open file. Error code: %s" % [path, FileAccess.get_open_error()])
		return {"ok": false, "entries": {}}

	var parsed := JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("%s: failed to parse JSON." % path)
		return {"ok": false, "entries": {}}

	if not (parsed is Dictionary):
		push_error("%s: expected top-level JSON object." % path)
		return {"ok": false, "entries": {}}

	if not parsed.has(root_key):
		push_error("%s: missing top-level field '%s'." % [path, root_key])
		return {"ok": false, "entries": {}}

	var records = parsed[root_key]
	if not (records is Array):
		push_error("%s: field '%s' must be an array." % [path, root_key])
		return {"ok": false, "entries": {}}

	var entries := {}
	for index in range(records.size()):
		var record = records[index]
		if not (record is Dictionary):
			push_error("%s: %s[%d] must be an object." % [path, root_key, index])
			return {"ok": false, "entries": {}}

		for field_name in required_fields:
			if not record.has(field_name):
				var record_id = record.get("id", "<missing>")
				push_error("%s: %s[%d] id=%s is missing required field '%s'." % [path, root_key, index, record_id, field_name])
				return {"ok": false, "entries": {}}

		var record_id = record["id"]
		if not (record_id is String):
			push_error("%s: %s[%d] field 'id' must be a string." % [path, root_key, index])
			return {"ok": false, "entries": {}}
		if record_id.is_empty():
			push_error("%s: %s[%d] field 'id' must not be empty." % [path, root_key, index])
			return {"ok": false, "entries": {}}
		if entries.has(record_id):
			push_error("%s: duplicate id '%s' in '%s'." % [path, record_id, root_key])
			return {"ok": false, "entries": {}}
		if root_key == "items" and not _is_positive_integer(record["stack_size"]):
			push_error("%s: %s[%d] field 'stack_size' must be a positive integer." % [path, root_key, index])
			return {"ok": false, "entries": {}}

		entries[record_id] = record.duplicate(true)

	return {"ok": true, "entries": entries}


func _is_positive_integer(value: Variant) -> bool:
	if value is int:
		return value > 0
	if value is float:
		return value > 0.0 and floor(value) == value
	return false


func _emit_data_loaded() -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("data_loaded"):
		event_bus.data_loaded.emit()
