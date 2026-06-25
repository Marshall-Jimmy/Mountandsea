extends Node2D

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const ZHUYU_INTERACTABLE_ID := "pickup_zhuyu_leaf"
const SHENSHENG_INTERACTABLE_ID := "observe_shensheng"

@onready var player: Polygon2D = %Player
@onready var zhuyu_pickup: Polygon2D = %ZhuyuPickup
@onready var zhuyu_label: Label = %ZhuyuLabel
@onready var shensheng_creature: Polygon2D = %ShenshengCreature
@onready var shensheng_label: Label = %ShenshengLabel
@onready var prompt_label: Label = %PromptLabel
@onready var status_label: Label = %StatusLabel
@onready var log_label: RichTextLabel = %LogLabel

var player_speed := 220.0
var interaction_distance := 80.0

var inventory_service: InventoryService
var bestiary_service: BestiaryService
var interaction_service: InteractionService

var initialized := false
var zhuyu_collected := false
var shensheng_discovered := false
var was_near_zhuyu := false
var was_near_shensheng := false
var was_interact_key_pressed := false


func _ready() -> void:
	prompt_label.visible = false
	_refresh_status()
	_log("山海经 Demo 场景启动")
	_initialize_services()


func _process(delta: float) -> void:
	if not initialized:
		return

	_move_player(delta)
	_update_prompt()
	_handle_interaction_input()


func _initialize_services() -> void:
	var data_registry := _get_autoload("DataRegistry")
	if data_registry == null:
		_log_error("找不到 DataRegistry autoload，Demo 停止初始化。")
		return
	if not data_registry.has_method("load_all"):
		_log_error("DataRegistry 缺少 load_all()，Demo 停止初始化。")
		return

	var load_result: Variant = data_registry.call("load_all")
	if load_result != true:
		_log_error("DataRegistry 加载失败，Demo 停止初始化。")
		return
	_log_ok("DataRegistry 加载成功")

	if not _verify_demo_data(data_registry):
		return

	inventory_service = InventoryService.new()
	bestiary_service = BestiaryService.new()
	interaction_service = InteractionService.new()

	if not _register_interactables():
		return

	initialized = true
	_log_ok("Demo 初始化完成")
	_refresh_status()


func _register_interactables() -> bool:
	var zhuyu_registered := interaction_service.register_interactable(ZHUYU_INTERACTABLE_ID, {
		"type": "pickup",
		"metadata": {
			"item_id": ITEM_ID,
			"count": 1
		},
		"callback_target": self,
		"callback_method": "_on_zhuyu_interacted"
	})
	if not zhuyu_registered:
		_log_error("InteractionService 注册失败：%s" % ZHUYU_INTERACTABLE_ID)
		return false

	var shensheng_registered := interaction_service.register_interactable(SHENSHENG_INTERACTABLE_ID, {
		"type": "observe",
		"metadata": {
			"creature_id": CREATURE_ID
		},
		"callback_target": self,
		"callback_method": "_on_shensheng_interacted"
	})
	if not shensheng_registered:
		_log_error("InteractionService 注册失败：%s" % SHENSHENG_INTERACTABLE_ID)
		return false

	_log_ok("InteractionService 注册成功")
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


func _update_prompt() -> void:
	var near_zhuyu := _is_near_zhuyu()
	var near_shensheng := _is_near_shensheng()

	if near_zhuyu:
		prompt_label.text = "按 E 采集祝余叶"
		prompt_label.visible = true
	elif near_shensheng:
		prompt_label.text = "按 E 观察狌狌"
		prompt_label.visible = true
	else:
		prompt_label.visible = false

	if near_zhuyu and not was_near_zhuyu:
		_log("靠近祝余叶")
	if near_shensheng and not was_near_shensheng:
		_log("靠近狌狌")

	was_near_zhuyu = near_zhuyu
	was_near_shensheng = near_shensheng


func _handle_interaction_input() -> void:
	var interact_key_pressed := Input.is_key_pressed(KEY_E)
	var interact_just_pressed := (interact_key_pressed and not was_interact_key_pressed) or Input.is_action_just_pressed("ui_accept")

	if interact_just_pressed:
		_try_interact()

	was_interact_key_pressed = interact_key_pressed


func _try_interact() -> void:
	if _is_near_zhuyu():
		var zhuyu_interacted := interaction_service.interact(OWNER_ID, ZHUYU_INTERACTABLE_ID)
		if not zhuyu_interacted:
			_log_error("InteractionService 交互失败：%s" % ZHUYU_INTERACTABLE_ID)
		return

	if _is_near_shensheng():
		var shensheng_interacted := interaction_service.interact(OWNER_ID, SHENSHENG_INTERACTABLE_ID)
		if not shensheng_interacted:
			_log_error("InteractionService 交互失败：%s" % SHENSHENG_INTERACTABLE_ID)
		return

	_log("附近没有可交互对象。")


func _on_zhuyu_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("采集失败：actor_id 为空。")
		return false
	if interactable_id != ZHUYU_INTERACTABLE_ID:
		_log_error("采集失败：interactable_id 不匹配。")
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

	if not inventory_service.add_item(actor_id, item_id, count):
		_log_error("背包增加 %s 失败。" % item_id)
		return false
	if not bestiary_service.discover_item(actor_id, item_id):
		_log_error("图鉴发现 %s 失败。" % item_id)
		return false

	zhuyu_collected = true
	zhuyu_pickup.visible = false
	zhuyu_label.visible = false
	prompt_label.visible = false
	_log_ok("采集祝余叶成功")
	_refresh_status()
	return true


func _on_shensheng_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("观察失败：actor_id 为空。")
		return false
	if interactable_id != SHENSHENG_INTERACTABLE_ID:
		_log_error("观察失败：interactable_id 不匹配。")
		return false
	if shensheng_discovered:
		_log("狌狌已经被发现。")
		return true

	var creature_id_value: Variant = metadata.get("creature_id", "")
	if not (creature_id_value is String) or creature_id_value.is_empty():
		_log_error("观察失败：metadata.creature_id 无效。")
		return false
	var creature_id: String = creature_id_value

	if not bestiary_service.discover_creature(actor_id, creature_id):
		_log_error("图鉴发现 %s 失败。" % creature_id)
		return false

	shensheng_discovered = true
	shensheng_creature.modulate.a = 0.45
	shensheng_label.text = "狌狌（已发现）"
	prompt_label.visible = false
	_log_ok("观察狌狌成功")
	_refresh_status()
	return true


func _verify_demo_data(data_registry: Variant) -> bool:
	if not data_registry.has_method("has_item"):
		_log_error("DataRegistry 缺少 has_item()，无法验证 Demo 物品。")
		return false
	if data_registry.call("has_item", ITEM_ID) != true:
		_log_error("Demo 物品不存在：%s。" % ITEM_ID)
		return false

	if not data_registry.has_method("has_creature"):
		_log_error("DataRegistry 缺少 has_creature()，无法验证 Demo 生物。")
		return false
	if data_registry.call("has_creature", CREATURE_ID) != true:
		_log_error("Demo 生物不存在：%s。" % CREATURE_ID)
		return false

	return true


func _is_near_zhuyu() -> bool:
	if zhuyu_collected or zhuyu_pickup == null or not zhuyu_pickup.visible:
		return false
	return player.global_position.distance_to(zhuyu_pickup.global_position) <= interaction_distance


func _is_near_shensheng() -> bool:
	if shensheng_creature == null or not shensheng_creature.visible:
		return false
	return player.global_position.distance_to(shensheng_creature.global_position) <= interaction_distance


func _get_autoload(node_name: String) -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.root.get_node_or_null(node_name)


func _refresh_status() -> void:
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


func _log_ok(message: String) -> void:
	_log("[OK] %s" % message)


func _log_error(message: String) -> void:
	_log("[ERROR] %s" % message)


func _log(message: String) -> void:
	var line := "%s  %s" % [Time.get_time_string_from_system(), message]
	log_label.text += line + "\n"
