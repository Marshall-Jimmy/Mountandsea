extends Node

const SAVE_DIR := "user://saves"
const SAVE_VERSION := "0.1.0"

var _providers: Dictionary = {}


func register_provider(provider_id: String, provider: Object) -> bool:
	if provider_id.is_empty():
		push_error("SaveService.register_provider: provider_id 不能为空。")
		return false
	if provider == null:
		push_error("SaveService.register_provider: provider 不能为 null。")
		return false
	if not provider.has_method("get_save_data"):
		push_error("SaveService.register_provider: provider 必须实现 get_save_data()。")
		return false
	if not provider.has_method("load_save_data"):
		push_error("SaveService.register_provider: provider 必须实现 load_save_data(data)。")
		return false
	if _providers.has(provider_id):
		push_error("SaveService.register_provider: provider_id 已注册：%s" % provider_id)
		return false

	_providers[provider_id] = provider
	return true


func unregister_provider(provider_id: String) -> void:
	_providers.erase(provider_id)


func has_provider(provider_id: String) -> bool:
	return _providers.has(provider_id)


func get_registered_provider_ids() -> Array:
	var provider_ids := _providers.keys()
	provider_ids.sort()
	return provider_ids


func clear_providers() -> void:
	_providers.clear()


func save_slot(slot: int) -> bool:
	if slot < 0:
		return _fail_slot(slot, "slot 必须大于等于 0。")

	_emit_save_requested(slot)

	if not _ensure_save_dir(slot):
		return false

	var providers_data := {}
	for provider_id in get_registered_provider_ids():
		var provider: Object = _providers[provider_id]
		var provider_data: Variant = provider.call("get_save_data")
		if not (provider_data is Dictionary):
			return _fail_slot(slot, "provider 必须从 get_save_data() 返回 Dictionary：%s" % provider_id)

		providers_data[provider_id] = provider_data

	var save_data := {
		"version": SAVE_VERSION,
		"slot": slot,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"providers": providers_data
	}

	var path := get_slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail_slot(slot, "无法打开保存文件：%s，错误码：%s" % [path, FileAccess.get_open_error()])

	file.store_string(JSON.stringify(save_data, "\t"))
	var write_error := file.get_error()
	if write_error != OK:
		return _fail_slot(slot, "写入保存文件失败：%s，错误码：%s" % [path, write_error])

	_emit_save_completed(slot)
	return true


func load_slot(slot: int) -> bool:
	if slot < 0:
		return _fail_slot(slot, "slot 必须大于等于 0。")

	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return _fail_slot(slot, "保存文件不存在：%s" % path)

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail_slot(slot, "无法打开保存文件：%s，错误码：%s" % [path, FileAccess.get_open_error()])

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return _fail_slot(slot, "JSON 解析失败：%s，第 %d 行。" % [json.get_error_message(), json.get_error_line()])

	var loaded_data: Variant = json.data
	if not (loaded_data is Dictionary):
		return _fail_slot(slot, "保存文件顶层必须是 Dictionary：%s" % path)
	if not loaded_data.has("providers"):
		return _fail_slot(slot, "保存文件缺少 providers 字段：%s" % path)
	if not (loaded_data["providers"] is Dictionary):
		return _fail_slot(slot, "保存文件 providers 字段必须是 Dictionary：%s" % path)

	var providers_data: Dictionary = loaded_data["providers"]
	for provider_id in get_registered_provider_ids():
		if not providers_data.has(provider_id):
			continue

		var provider_saved_data: Variant = providers_data[provider_id]
		if not (provider_saved_data is Dictionary):
			return _fail_slot(slot, "provider 保存数据必须是 Dictionary：%s" % provider_id)

		var provider: Object = _providers[provider_id]
		var load_result: Variant = provider.call("load_save_data", provider_saved_data)
		if load_result != true:
			return _fail_slot(slot, "provider 读取失败：%s" % provider_id)

	_emit_save_completed(slot)
	return true


func get_slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func _ensure_save_dir(slot: int) -> bool:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return true

	var error := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if error != OK:
		return _fail_slot(slot, "创建保存目录失败：%s，错误码：%s" % [SAVE_DIR, error])

	return true


func _fail_slot(slot: int, reason: String) -> bool:
	push_error("SaveService: %s" % reason)
	_emit_save_failed(slot, reason)
	return false


func _get_event_bus() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null

	return (main_loop as SceneTree).root.get_node_or_null("EventBus")


func _emit_save_requested(slot: int) -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("save_requested"):
		event_bus.emit_signal("save_requested", slot)


func _emit_save_completed(slot: int) -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("save_completed"):
		event_bus.emit_signal("save_completed", slot)


func _emit_save_failed(slot: int, reason: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus != null and event_bus.has_signal("save_failed"):
		event_bus.emit_signal("save_failed", slot, reason)
