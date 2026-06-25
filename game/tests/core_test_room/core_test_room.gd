extends Control

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const INTERACTABLE_ID := "pickup_zhuyu_leaf"
const SAVE_PROVIDER_ID := "core_test_room"
const SAVE_SLOT := 0

@onready var load_data_button: Button = %LoadDataButton
@onready var register_interactable_button: Button = %RegisterInteractableButton
@onready var pickup_item_button: Button = %PickupItemButton
@onready var discover_creature_button: Button = %DiscoverCreatureButton
@onready var save_slot_button: Button = %SaveSlotButton
@onready var clear_state_button: Button = %ClearStateButton
@onready var load_slot_button: Button = %LoadSlotButton
@onready var inventory_status_label: Label = %InventoryStatusLabel
@onready var bestiary_status_label: Label = %BestiaryStatusLabel
@onready var log_output: RichTextLabel = %LogOutput

var inventory_service: InventoryService
var bestiary_service: BestiaryService
var interaction_service: InteractionService
var save_provider: TestCoreStateProvider
var data_loaded := false
var interactable_registered := false
var save_provider_registered := false


class TestCoreStateProvider:
	var owner_id := ""
	var inventory_service: InventoryService
	var bestiary_service: BestiaryService

	func _init(new_owner_id: String, new_inventory_service: InventoryService, new_bestiary_service: BestiaryService) -> void:
		owner_id = new_owner_id
		inventory_service = new_inventory_service
		bestiary_service = new_bestiary_service

	func get_save_data() -> Dictionary:
		return {
			"inventory": inventory_service.get_items(owner_id),
			"bestiary": bestiary_service.get_save_data_for_owner(owner_id)
		}

	func load_save_data(data: Dictionary) -> bool:
		if inventory_service == null or bestiary_service == null:
			return false
		if not (data is Dictionary):
			return false

		var inventory_items: Variant = data.get("inventory", [])
		var bestiary_data: Variant = data.get("bestiary", {})
		if not (inventory_items is Array):
			return false
		if not (bestiary_data is Dictionary):
			return false

		inventory_service.clear_inventory(owner_id)
		bestiary_service.clear_owner(owner_id)

		for stack in inventory_items:
			if not (stack is Dictionary):
				return false
			var item_id: Variant = stack.get("item_id", "")
			var count: Variant = stack.get("count", 0)
			if not (item_id is String) or item_id.is_empty():
				return false

			var item_count := _to_positive_int(count)
			if item_count <= 0:
				return false
			if not inventory_service.add_item(owner_id, item_id, item_count):
				return false

		return bestiary_service.load_save_data_for_owner(owner_id, bestiary_data)

	func _to_positive_int(value: Variant) -> int:
		if value is int:
			return value
		if value is float and floor(value) == value:
			return int(value)
		return 0


func _ready() -> void:
	load_data_button.pressed.connect(_on_load_data_pressed)
	register_interactable_button.pressed.connect(_on_register_interactable_pressed)
	pickup_item_button.pressed.connect(_on_pickup_item_pressed)
	discover_creature_button.pressed.connect(_on_discover_creature_pressed)
	save_slot_button.pressed.connect(_on_save_slot_pressed)
	clear_state_button.pressed.connect(_on_clear_state_pressed)
	load_slot_button.pressed.connect(_on_load_slot_pressed)

	_refresh_status()
	_log("Core Test Room ready. 请先点击“加载数据”。")


func _on_load_data_pressed() -> void:
	var data_registry := _get_autoload("DataRegistry")
	if data_registry == null:
		_log_error("找不到 DataRegistry autoload，停止后续操作。请确认 Snowhuman Framework addon 已启用。")
		return
	if not data_registry.has_method("load_all"):
		_log_error("DataRegistry 缺少 load_all()，停止后续操作。")
		return

	var load_result: Variant = data_registry.call("load_all")
	if load_result != true:
		data_loaded = false
		_log_error("DataRegistry.load_all() 失败。")
		_refresh_status()
		return

	if not _verify_test_data(data_registry):
		data_loaded = false
		_refresh_status()
		return

	inventory_service = InventoryService.new()
	bestiary_service = BestiaryService.new()
	interaction_service = InteractionService.new()
	save_provider = TestCoreStateProvider.new(OWNER_ID, inventory_service, bestiary_service)
	data_loaded = true
	interactable_registered = false
	save_provider_registered = false
	_register_save_provider()

	_log_ok("DataRegistry.load_all() 成功，核心测试服务已实例化。")
	_refresh_status()


func _on_register_interactable_pressed() -> void:
	if not _ensure_services_ready("注册交互对象"):
		return

	var registered := interaction_service.register_interactable(INTERACTABLE_ID, {
		"type": "pickup",
		"metadata": {
			"item_id": ITEM_ID,
			"count": 1
		},
		"callback_target": self,
		"callback_method": "_on_pickup_zhuyu_leaf"
	})
	interactable_registered = registered

	if registered:
		_log_ok("InteractionService.register_interactable(%s) 成功。" % INTERACTABLE_ID)
	else:
		_log_error("InteractionService.register_interactable(%s) 失败。" % INTERACTABLE_ID)
	_refresh_status()


func _on_pickup_item_pressed() -> void:
	if not _ensure_services_ready("采集祝余叶"):
		return
	if not interactable_registered or not interaction_service.has_interactable(INTERACTABLE_ID):
		_log_error("尚未注册 %s，请先点击“注册交互对象”。" % INTERACTABLE_ID)
		return

	var interacted := interaction_service.interact(OWNER_ID, INTERACTABLE_ID)
	if interacted:
		_log_ok("InteractionService.interact(%s, %s) 成功。" % [OWNER_ID, INTERACTABLE_ID])
	else:
		_log_error("InteractionService.interact(%s, %s) 失败。" % [OWNER_ID, INTERACTABLE_ID])
	_refresh_status()


func _on_pickup_zhuyu_leaf(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	var item_id: Variant = metadata.get("item_id", "")
	var count: Variant = metadata.get("count", 0)
	if actor_id.is_empty() or interactable_id != INTERACTABLE_ID:
		_log_error("pickup callback 收到无效 actor 或 interactable。")
		return false
	if item_id != ITEM_ID:
		_log_error("pickup callback 收到非预期 item_id：%s。" % str(item_id))
		return false

	var item_count := _to_positive_int(count)
	if item_count <= 0:
		_log_error("pickup callback 收到无效 count：%s。" % str(count))
		return false

	var added := inventory_service.add_item(actor_id, item_id, item_count)
	var discovered := bestiary_service.discover_item(actor_id, item_id)
	if added and discovered:
		_log_ok("callback 已添加 %s x%d，并记录 item 图鉴发现。" % [item_id, item_count])
		return true

	_log_error("callback 处理失败：added=%s discovered=%s。" % [str(added), str(discovered)])
	return false


func _on_discover_creature_pressed() -> void:
	if not _ensure_services_ready("发现狌狌"):
		return

	var discovered := bestiary_service.discover_creature(OWNER_ID, CREATURE_ID)
	if discovered:
		_log_ok("BestiaryService.discover_creature(%s, %s) 成功。" % [OWNER_ID, CREATURE_ID])
	else:
		_log_error("BestiaryService.discover_creature(%s, %s) 失败。" % [OWNER_ID, CREATURE_ID])
	_refresh_status()


func _on_save_slot_pressed() -> void:
	if not _ensure_services_ready("保存 Slot 0"):
		return
	if not _register_save_provider():
		return

	var save_service := _get_autoload("SaveService")
	var saved: Variant = save_service.call("save_slot", SAVE_SLOT)
	if saved == true:
		_log_ok("SaveService.save_slot(%d) 成功。" % SAVE_SLOT)
	else:
		_log_error("SaveService.save_slot(%d) 失败。" % SAVE_SLOT)
	_refresh_status()


func _on_clear_state_pressed() -> void:
	if inventory_service != null:
		inventory_service.clear_inventory(OWNER_ID)
	if bestiary_service != null:
		bestiary_service.clear_owner(OWNER_ID)

	_log_ok("测试状态已清空：InventoryService 与 BestiaryService 已重置。")
	_refresh_status()


func _on_load_slot_pressed() -> void:
	if not _ensure_services_ready("读取 Slot 0"):
		return
	if not _register_save_provider():
		return

	var save_service := _get_autoload("SaveService")
	var loaded: Variant = save_service.call("load_slot", SAVE_SLOT)
	if loaded == true:
		_log_ok("SaveService.load_slot(%d) 成功。" % SAVE_SLOT)
	else:
		_log_error("SaveService.load_slot(%d) 失败。" % SAVE_SLOT)
	_refresh_status()


func _register_save_provider() -> bool:
	var save_service := _get_autoload("SaveService")
	if save_service == null:
		_log_error("找不到 SaveService autoload，无法注册测试 provider。")
		return false
	if save_provider == null:
		_log_error("测试 provider 尚未创建，请先点击“加载数据”。")
		return false

	if save_service.has_method("has_provider") and save_service.call("has_provider", SAVE_PROVIDER_ID) == true:
		if save_service.has_method("unregister_provider"):
			save_service.call("unregister_provider", SAVE_PROVIDER_ID)

	if not save_service.has_method("register_provider"):
		_log_error("SaveService 缺少 register_provider()。")
		return false

	var registered: Variant = save_service.call("register_provider", SAVE_PROVIDER_ID, save_provider)
	save_provider_registered = registered == true
	if save_provider_registered:
		_log_ok("SaveService provider 已注册：%s。" % SAVE_PROVIDER_ID)
	else:
		_log_error("SaveService provider 注册失败：%s。" % SAVE_PROVIDER_ID)
	return save_provider_registered


func _ensure_services_ready(action_name: String) -> bool:
	if not data_loaded:
		_log_error("%s 失败：请先点击“加载数据”。" % action_name)
		return false
	if inventory_service == null or bestiary_service == null or interaction_service == null:
		_log_error("%s 失败：核心服务尚未实例化。" % action_name)
		return false
	if _get_autoload("DataRegistry") == null:
		_log_error("%s 失败：DataRegistry autoload 不可用，停止后续操作。" % action_name)
		return false
	return true


func _verify_test_data(data_registry: Node) -> bool:
	var has_item: bool = data_registry.has_method("has_item") and data_registry.call("has_item", ITEM_ID) == true
	var has_creature: bool = data_registry.has_method("has_creature") and data_registry.call("has_creature", CREATURE_ID) == true
	if not has_item:
		_log_error("测试物品不存在：%s。" % ITEM_ID)
	if not has_creature:
		_log_error("测试生物不存在：%s。" % CREATURE_ID)
	return has_item and has_creature


func _get_autoload(node_name: String) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _refresh_status() -> void:
	var zhuyu_count := 0
	var discovered_items: Array = []
	var discovered_creatures: Array = []

	if inventory_service != null:
		zhuyu_count = inventory_service.get_item_count(OWNER_ID, ITEM_ID)
	if bestiary_service != null:
		discovered_items = bestiary_service.get_discovered_items(OWNER_ID)
		discovered_creatures = bestiary_service.get_discovered_creatures(OWNER_ID)

	inventory_status_label.text = "背包状态：%s x%d" % [ITEM_ID, zhuyu_count]
	bestiary_status_label.text = "图鉴状态：items=%s creatures=%s" % [
		_format_ids(discovered_items),
		_format_ids(discovered_creatures)
	]


func _format_ids(ids: Array) -> String:
	if ids.is_empty():
		return "[]"

	var formatted := ""
	for index in range(ids.size()):
		if index > 0:
			formatted += ", "
		formatted += str(ids[index])
	return "[%s]" % formatted


func _to_positive_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float and floor(value) == value:
		return int(value)
	return 0


func _log_ok(message: String) -> void:
	_log("[OK] %s" % message)


func _log_error(message: String) -> void:
	_log("[ERROR] %s" % message)


func _log(message: String) -> void:
	var line := "%s  %s" % [Time.get_time_string_from_system(), message]
	log_output.text += line + "\n"
