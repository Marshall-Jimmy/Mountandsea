extends RefCounted
class_name InteractionService

var _interactables: Dictionary = {}


func register_interactable(interactable_id: String, data: Dictionary) -> bool:
	if interactable_id.is_empty():
		push_error("InteractionService.register_interactable: interactable_id 不能为空。")
		return false
	if not (data is Dictionary):
		push_error("InteractionService.register_interactable: data 必须是 Dictionary。")
		return false

	var normalized_data := _normalize_interactable_data(interactable_id, data)
	if normalized_data.is_empty():
		return false

	_interactables[interactable_id] = normalized_data
	_emit_interactables_changed(interactable_id)
	return true


func unregister_interactable(interactable_id: String) -> void:
	if not _interactables.has(interactable_id):
		return

	_interactables.erase(interactable_id)
	_emit_interactables_changed(interactable_id)


func has_interactable(interactable_id: String) -> bool:
	return _interactables.has(interactable_id)


func get_interactable(interactable_id: String) -> Dictionary:
	if not _interactables.has(interactable_id):
		return {}

	return _interactables[interactable_id].duplicate(true)


func get_all_interactables() -> Array:
	var interactable_ids := _interactables.keys()
	interactable_ids.sort()

	var result := []
	for interactable_id in interactable_ids:
		var interactable_data: Dictionary = _interactables[interactable_id].duplicate(true)
		interactable_data["id"] = interactable_id
		result.append(interactable_data)

	return result


func clear() -> void:
	_interactables.clear()


func can_interact(actor_id: String, interactable_id: String) -> bool:
	if actor_id.is_empty():
		return false
	if not _interactables.has(interactable_id):
		return false

	var interactable_data: Dictionary = _interactables[interactable_id]
	return interactable_data.get("enabled", true) == true


func interact(actor_id: String, interactable_id: String) -> bool:
	if not can_interact(actor_id, interactable_id):
		push_error("InteractionService.interact: actor_id 为空、interactable 不存在或 interactable 未启用。")
		return false

	var interactable_data: Dictionary = _interactables[interactable_id]
	var callback_target: Object = interactable_data.get("callback_target", null)
	var callback_method: String = interactable_data.get("callback_method", "")
	if callback_target == null or callback_method.is_empty():
		_emit_interaction_completed(actor_id, interactable_id)
		return true

	if not callback_target.has_method(callback_method):
		push_error("InteractionService.interact: callback_method 不存在：%s" % callback_method)
		return false

	var metadata: Dictionary = interactable_data.get("metadata", {})
	var callback_result: Variant = callback_target.call(callback_method, actor_id, interactable_id, metadata.duplicate(true))
	var interaction_succeeded := true
	if callback_result is bool:
		interaction_succeeded = callback_result

	if not interaction_succeeded:
		push_error("InteractionService.interact: callback 返回 false：%s" % interactable_id)
		return false

	_emit_interaction_completed(actor_id, interactable_id)
	return true


func _normalize_interactable_data(interactable_id: String, data: Dictionary) -> Dictionary:
	var interactable_type := "generic"
	if data.has("type"):
		if not (data["type"] is String) or data["type"].is_empty():
			push_error("InteractionService.register_interactable: type 必须是非空 String：%s" % interactable_id)
			return {}
		interactable_type = data["type"]

	var enabled := true
	if data.has("enabled"):
		if not (data["enabled"] is bool):
			push_error("InteractionService.register_interactable: enabled 必须是 bool：%s" % interactable_id)
			return {}
		enabled = data["enabled"]

	var metadata := {}
	if data.has("metadata"):
		if not (data["metadata"] is Dictionary):
			push_error("InteractionService.register_interactable: metadata 必须是 Dictionary：%s" % interactable_id)
			return {}
		metadata = data["metadata"].duplicate(true)

	var callback_target: Object = null
	if data.has("callback_target"):
		if data["callback_target"] != null and not (data["callback_target"] is Object):
			push_error("InteractionService.register_interactable: callback_target 必须是 Object：%s" % interactable_id)
			return {}
		callback_target = data["callback_target"]

	var callback_method := ""
	if data.has("callback_method"):
		if not (data["callback_method"] is String):
			push_error("InteractionService.register_interactable: callback_method 必须是 String：%s" % interactable_id)
			return {}
		callback_method = data["callback_method"]

	if callback_target != null:
		if callback_method.is_empty():
			push_error("InteractionService.register_interactable: 提供 callback_target 时必须提供非空 callback_method：%s" % interactable_id)
			return {}
		if not callback_target.has_method(callback_method):
			push_error("InteractionService.register_interactable: callback_target 不存在 callback_method：%s" % callback_method)
			return {}
	elif not callback_method.is_empty():
		push_error("InteractionService.register_interactable: 提供 callback_method 时必须提供 callback_target：%s" % interactable_id)
		return {}

	return {
		"type": interactable_type,
		"enabled": enabled,
		"callback_target": callback_target,
		"callback_method": callback_method,
		"metadata": metadata
	}


func _get_event_bus() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null

	return (main_loop as SceneTree).root.get_node_or_null("EventBus")


func _emit_interactables_changed(interactable_id: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus == null:
		return

	if event_bus.has_signal("interactables_changed"):
		event_bus.emit_signal("interactables_changed", interactable_id)


func _emit_interaction_completed(actor_id: String, interactable_id: String) -> void:
	var event_bus := _get_event_bus()
	if event_bus == null:
		return

	if event_bus.has_signal("interaction_completed"):
		event_bus.emit_signal("interaction_completed", actor_id, interactable_id)
