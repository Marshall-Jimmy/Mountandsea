extends Node

var _providers: Dictionary = {}

func register_provider(provider_id: String, provider: Object) -> bool:
	if provider_id.is_empty():
		return false
	if provider == null:
		return false
	if _providers.has(provider_id):
		return false

	_providers[provider_id] = provider
	return true


func has_provider(provider_id: String) -> bool:
	return _providers.has(provider_id)


func save_slot(slot: int) -> bool:
	if slot < 0:
		_emit_save_failed(slot, "Slot must be greater than or equal to 0.")
		return false

	_emit_save_requested(slot)
	_emit_save_completed(slot)
	return true


func load_slot(slot: int) -> bool:
	if slot < 0:
		return false

	return true


func _emit_save_requested(slot: int) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("save_requested"):
		event_bus.emit_signal("save_requested", slot)


func _emit_save_completed(slot: int) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("save_completed"):
		event_bus.emit_signal("save_completed", slot)


func _emit_save_failed(slot: int, reason: String) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("save_failed"):
		event_bus.emit_signal("save_failed", slot, reason)
