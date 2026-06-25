extends Node2D

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const INTERACTABLE_ID := "pickup_zhuyu_leaf"
const CREATURE_ID := "shensheng"
const CREATURE_INTERACTABLE_ID := "observe_shensheng"
const SAVE_PROVIDER_ID := "player_interaction_room"
const TEST_SAVE_SLOT := 0

@onready var player: Polygon2D = %Player
@onready var pickup: Polygon2D = %Pickup
@onready var pickup_label: Label = $PickupLabel
@onready var creature: Polygon2D = %Creature
@onready var creature_label: Label = $CreatureLabel
@onready var prompt_label: Label = %PromptLabel
@onready var status_label: Label = %StatusLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var save_button: Button = %SaveButton
@onready var clear_button: Button = %ClearButton
@onready var load_button: Button = %LoadButton

var player_speed := 220.0
var interaction_distance := 80.0

var inventory_service: InventoryService
var bestiary_service: BestiaryService
var interaction_service: InteractionService
var save_service: Node

var initialized := false
var pickup_collected := false
var creature_discovered := false
var save_provider_registered := false
var was_near_pickup := false
var was_near_creature := false
var was_interact_key_pressed := false


func _ready() -> void:
	_connect_button_signals()

	prompt_label.visible = false
	_refresh_ui()
	_log("场景启动成功")
	_initialize_core_services()


func _connect_button_signals() -> void:
	var save_callable := Callable(self, "_on_save_button_pressed")
	var clear_callable := Callable(self, "_on_clear_button_pressed")
	var load_callable := Callable(self, "_on_load_button_pressed")

	if not save_button.pressed.is_connected(save_callable):
		save_button.pressed.connect(save_callable)
	if not clear_button.pressed.is_connected(clear_callable):
		clear_button.pressed.connect(clear_callable)
	if not load_button.pressed.is_connected(load_callable):
		load_button.pressed.connect(load_callable)


func _process(delta: float) -> void:
	if not initialized:
		return

	_move_player(delta)
	_update_interaction_prompt()
	_handle_interaction_input()


func _initialize_core_services() -> void:
	var data_registry: Variant = _get_autoload("DataRegistry")
	if data_registry == null:
		_log_error("找不到 DataRegistry autoload，停止后续逻辑。请确认 Snowhuman Framework addon 已启用。")
		return
	if not data_registry.has_method("load_all"):
		_log_error("DataRegistry 缺少 load_all()，停止后续逻辑。")
		return

	var load_result: Variant = data_registry.call("load_all")
	if load_result != true:
		_log_error("DataRegistry 加载失败，停止后续逻辑。")
		return
	_log_ok("DataRegistry 加载成功")

	if not _verify_test_item(data_registry):
		return
	if not _verify_test_creature(data_registry):
		return

	inventory_service = InventoryService.new()
	bestiary_service = BestiaryService.new()
	interaction_service = InteractionService.new()
	save_service = _get_autoload("SaveService")
	if save_service == null:
		_log_error("找不到 SaveService autoload，停止后续逻辑。")
		return

	if not _register_interactables():
		return
	if not _register_save_provider():
		return

	initialized = true
	_log_ok("核心服务初始化成功")
	_refresh_ui()


func _register_interactables() -> bool:
	var pickup_registered := interaction_service.register_interactable(INTERACTABLE_ID, {
		"type": "pickup",
		"metadata": {
			"item_id": ITEM_ID,
			"count": 1
		},
		"callback_target": self,
		"callback_method": "_on_pickup_interacted"
	})
	if not pickup_registered:
		_log_error("InteractionService 注册失败：%s" % INTERACTABLE_ID)
		return false

	var creature_registered := interaction_service.register_interactable(CREATURE_INTERACTABLE_ID, {
		"type": "observe",
		"metadata": {
			"creature_id": CREATURE_ID
		},
		"callback_target": self,
		"callback_method": "_on_creature_interacted"
	})
	if not creature_registered:
		_log_error("InteractionService 注册失败：%s" % CREATURE_INTERACTABLE_ID)
		return false

	_log_ok("InteractionService 注册成功：%s" % INTERACTABLE_ID)
	_log_ok("InteractionService 注册成功：%s" % CREATURE_INTERACTABLE_ID)
	return true


func _move_player(delta: float) -> void:
	var move_direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_direction.x += 1.0

	if move_direction.length_squared() > 0.0:
		player.position += move_direction.normalized() * player_speed * delta


func _update_interaction_prompt() -> void:
	var near_pickup := _is_near_pickup()
	var near_creature := _is_near_creature()

	if near_pickup:
		prompt_label.text = "按 E 采集祝余叶"
		prompt_label.visible = true
	elif near_creature:
		prompt_label.text = "按 E 观察狌狌"
		prompt_label.visible = true
	else:
		prompt_label.visible = false

	if near_pickup and not was_near_pickup:
		_log("玩家靠近采集物")
	if near_creature and not was_near_creature:
		_log("玩家靠近狌狌")
	was_near_pickup = near_pickup
	was_near_creature = near_creature


func _handle_interaction_input() -> void:
	var interact_key_pressed := Input.is_key_pressed(KEY_E)
	var interact_just_pressed := (interact_key_pressed and not was_interact_key_pressed) or Input.is_action_just_pressed("ui_accept")

	if interact_just_pressed:
		_try_interact()

	was_interact_key_pressed = interact_key_pressed


func _try_interact() -> void:
	if _is_near_pickup():
		var pickup_interacted := interaction_service.interact(OWNER_ID, INTERACTABLE_ID)
		if not pickup_interacted:
			_log_error("InteractionService 交互失败：%s" % INTERACTABLE_ID)
		_refresh_ui()
		return

	if _is_near_creature():
		var creature_interacted := interaction_service.interact(OWNER_ID, CREATURE_INTERACTABLE_ID)
		if not creature_interacted:
			_log_error("InteractionService 交互失败：%s" % CREATURE_INTERACTABLE_ID)
		_refresh_ui()
		return

	_log("附近没有可交互对象。")


func _on_pickup_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("采集失败：actor_id 为空。")
		return false
	if interactable_id != INTERACTABLE_ID:
		_log_error("采集失败：interactable_id 不匹配：%s。" % interactable_id)
		return false

	var item_id_value: Variant = metadata.get("item_id", "")
	if not (item_id_value is String) or item_id_value.is_empty():
		_log_error("采集失败：metadata.item_id 无效。")
		return false
	var item_id: String = item_id_value

	var count := _to_positive_int(metadata.get("count", 0))
	if count <= 0:
		_log_error("采集失败：metadata.count 无效。")
		return false

	var added := inventory_service.add_item(actor_id, item_id, count)
	if not added:
		_log_error("背包增加 %s 失败。" % item_id)
		return false
	_log_ok("背包增加 %s x%d" % [item_id, count])

	var discovered := bestiary_service.discover_item(actor_id, item_id)
	if not discovered:
		_log_error("图鉴发现 %s 失败。" % item_id)
		return false
	_log_ok("图鉴发现 %s" % item_id)

	pickup_collected = true
	pickup.visible = false
	pickup_label.visible = false
	prompt_label.visible = false
	_log_ok("采集成功")
	_refresh_ui()
	return true


func _on_creature_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("观察失败：actor_id 为空。")
		return false
	if interactable_id != CREATURE_INTERACTABLE_ID:
		_log_error("观察失败：interactable_id 不匹配：%s。" % interactable_id)
		return false
	if creature_discovered:
		_log("狌狌已经被发现。")
		return true

	var creature_id_value: Variant = metadata.get("creature_id", "")
	if not (creature_id_value is String) or creature_id_value.is_empty():
		_log_error("观察失败：metadata.creature_id 无效。")
		return false
	var creature_id: String = creature_id_value

	var discovered := bestiary_service.discover_creature(actor_id, creature_id)
	if not discovered:
		_log_error("图鉴发现 %s 失败。" % creature_id)
		return false

	creature_discovered = true
	creature.modulate.a = 0.45
	creature_label.text = "狌狌（已发现）"
	prompt_label.visible = false
	_log_ok("图鉴发现 %s" % creature_id)
	_log_ok("观察狌狌成功")
	_refresh_ui()
	return true


func get_save_data() -> Dictionary:
	return _build_save_state()


func load_save_data(data: Dictionary) -> bool:
	return _restore_save_state(data)


func _on_save_button_pressed() -> void:
	if not _ensure_services_ready("保存 Slot 0"):
		return
	if not _register_save_provider():
		_log_error("保存 Slot 0 失败")
		return

	var save_state := _build_save_state()
	if save_state.is_empty():
		_log_error("保存 Slot 0 失败")
		return

	var saved: Variant = save_service.call("save_slot", TEST_SAVE_SLOT)
	if saved == true:
		_log_ok("保存 Slot 0 成功")
	else:
		_log_error("保存 Slot 0 失败")


func _on_clear_button_pressed() -> void:
	if inventory_service != null:
		inventory_service.clear_inventory(OWNER_ID)
	if bestiary_service != null:
		bestiary_service.clear_owner(OWNER_ID)

	pickup_collected = false
	creature_discovered = false
	_apply_world_state()
	_refresh_ui()
	_log_ok("已清空当前测试状态")


func _on_load_button_pressed() -> void:
	if not _ensure_services_ready("读取 Slot 0"):
		return
	if not _register_save_provider():
		_log_error("读取 Slot 0 失败或存档不存在")
		return

	var loaded: Variant = save_service.call("load_slot", TEST_SAVE_SLOT)
	if loaded == true:
		_log_ok("读取 Slot 0 成功")
	else:
		_log_error("读取 Slot 0 失败或存档不存在")
	_refresh_ui()


func _build_save_state() -> Dictionary:
	if inventory_service == null or bestiary_service == null:
		return {}

	return {
		"owner_id": OWNER_ID,
		"inventory": {
			ITEM_ID: inventory_service.get_item_count(OWNER_ID, ITEM_ID)
		},
		"bestiary": {
			"items": bestiary_service.get_discovered_items(OWNER_ID),
			"creatures": bestiary_service.get_discovered_creatures(OWNER_ID)
		},
		"test_room": {
			"pickup_collected": pickup_collected,
			"creature_discovered": creature_discovered
		}
	}


func _restore_save_state(data: Dictionary) -> bool:
	if inventory_service == null or bestiary_service == null:
		return false
	if not (data is Dictionary):
		return false

	var saved_owner_id: Variant = data.get("owner_id", OWNER_ID)
	if saved_owner_id != OWNER_ID:
		return false

	var inventory_data: Variant = data.get("inventory", {})
	var bestiary_data: Variant = data.get("bestiary", {})
	var test_room_data: Variant = data.get("test_room", {})
	if not (inventory_data is Dictionary):
		return false
	if not (bestiary_data is Dictionary):
		return false
	if not (test_room_data is Dictionary):
		return false

	var item_count := _to_non_negative_int(inventory_data.get(ITEM_ID, 0))
	if item_count < 0:
		return false

	inventory_service.clear_inventory(OWNER_ID)
	bestiary_service.clear_owner(OWNER_ID)
	if item_count > 0 and not inventory_service.add_item(OWNER_ID, ITEM_ID, item_count):
		return false
	if not bestiary_service.load_save_data_for_owner(OWNER_ID, bestiary_data):
		return false

	pickup_collected = test_room_data.get("pickup_collected", false) == true
	creature_discovered = test_room_data.get("creature_discovered", false) == true
	_apply_world_state()
	_refresh_ui()
	return true


func _register_save_provider() -> bool:
	if save_service == null:
		save_service = _get_autoload("SaveService")
	if save_service == null:
		_log_error("找不到 SaveService autoload，无法注册测试 provider。")
		return false

	if save_service.has_method("has_provider") and save_service.call("has_provider", SAVE_PROVIDER_ID) == true:
		if save_service.has_method("unregister_provider"):
			save_service.call("unregister_provider", SAVE_PROVIDER_ID)

	if not save_service.has_method("register_provider"):
		_log_error("SaveService 缺少 register_provider()。")
		return false

	var registered: Variant = save_service.call("register_provider", SAVE_PROVIDER_ID, self)
	save_provider_registered = registered == true
	if save_provider_registered:
		_log_ok("SaveService provider 已注册：%s。" % SAVE_PROVIDER_ID)
	else:
		_log_error("SaveService provider 注册失败：%s。" % SAVE_PROVIDER_ID)
	return save_provider_registered


func _ensure_services_ready(action_name: String) -> bool:
	if not initialized:
		_log_error("%s 失败：核心服务尚未初始化。" % action_name)
		return false
	if inventory_service == null or bestiary_service == null or interaction_service == null or save_service == null:
		_log_error("%s 失败：核心服务不可用。" % action_name)
		return false
	return true


func _apply_world_state() -> void:
	pickup.visible = not pickup_collected
	pickup_label.visible = not pickup_collected
	pickup_label.text = "祝余叶"

	if creature_discovered:
		creature.modulate.a = 0.45
		creature_label.text = "狌狌（已发现）"
	else:
		creature.modulate.a = 1.0
		creature_label.text = "狌狌"

	prompt_label.visible = false
	was_near_pickup = false
	was_near_creature = false


func _verify_test_item(data_registry: Variant) -> bool:
	if not data_registry.has_method("has_item"):
		_log_error("DataRegistry 缺少 has_item()，无法验证测试物品。")
		return false
	if data_registry.call("has_item", ITEM_ID) != true:
		_log_error("测试物品不存在：%s。" % ITEM_ID)
		return false
	return true


func _verify_test_creature(data_registry: Variant) -> bool:
	if not data_registry.has_method("has_creature"):
		_log_error("DataRegistry 缺少 has_creature()，无法验证测试生物。")
		return false
	if data_registry.call("has_creature", CREATURE_ID) != true:
		_log_error("测试生物不存在：%s。" % CREATURE_ID)
		return false
	return true


func _is_near_pickup() -> bool:
	if pickup_collected or pickup == null or not pickup.visible:
		return false
	return player.global_position.distance_to(pickup.global_position) <= interaction_distance


func _is_near_creature() -> bool:
	if creature == null or not creature.visible:
		return false
	return player.global_position.distance_to(creature.global_position) <= interaction_distance


func _get_autoload(node_name: String) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _refresh_ui() -> void:
	var item_count := 0
	var discovered_items: Array = []
	var discovered_creatures: Array = []

	if inventory_service != null:
		item_count = inventory_service.get_item_count(OWNER_ID, ITEM_ID)
	if bestiary_service != null:
		discovered_items = bestiary_service.get_discovered_items(OWNER_ID)
		discovered_creatures = bestiary_service.get_discovered_creatures(OWNER_ID)

	status_label.text = "背包：%s x%d\n图鉴 items=%s\n图鉴 creatures=%s" % [
		ITEM_ID,
		item_count,
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


func _to_non_negative_int(value: Variant) -> int:
	if value is int:
		return value
	if value is float and floor(value) == value:
		return int(value)
	return -1


func _log_ok(message: String) -> void:
	_log("[OK] %s" % message)


func _log_error(message: String) -> void:
	_log("[ERROR] %s" % message)


func _log(message: String) -> void:
	var line := "%s  %s" % [Time.get_time_string_from_system(), message]
	log_label.text += line + "\n"
