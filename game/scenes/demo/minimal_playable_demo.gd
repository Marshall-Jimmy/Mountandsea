extends Node2D

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const ZHUYU_INTERACTABLE_ID := "pickup_zhuyu_leaf"
const SHENSHENG_INTERACTABLE_ID := "observe_shensheng"
const STONE_INTERACTABLE_ID := "activate_guidance_stone"
const SAVE_PROVIDER_ID := "minimal_playable_demo"
const DEMO_SAVE_SLOT := 0
const PLAYER_START_POSITION := Vector2(220, 260)

enum DemoStep {
	COLLECT_ZHUYU,
	ACTIVATE_STONE,
	OBSERVE_SHENSHENG,
	COMPLETE
}

@onready var player: Polygon2D = %Player
@onready var zhuyu_pickup: Polygon2D = %ZhuyuPickup
@onready var zhuyu_label: Label = %ZhuyuLabel
@onready var guidance_stone: Polygon2D = %GuidanceStone
@onready var guidance_stone_label: Label = $WorldRoot/GuidanceStoneLabel
@onready var shensheng_creature: Polygon2D = %ShenshengCreature
@onready var shensheng_label: Label = %ShenshengLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var target_hint_label: Label = %TargetHintLabel
@onready var prompt_label: Label = %PromptLabel
@onready var status_label: Label = %StatusLabel
@onready var log_label: RichTextLabel = %LogLabel
@onready var demo_menu_panel: Control = %DemoMenuPanel
@onready var save_demo_button: Button = %SaveDemoButton
@onready var load_demo_button: Button = %LoadDemoButton
@onready var reset_demo_button: Button = %ResetDemoButton
@onready var close_menu_button: Button = %CloseMenuButton
@onready var completion_panel: Control = %CompletionPanel
@onready var completion_summary_label: Label = %CompletionSummaryLabel
@onready var restart_demo_button: Button = %RestartDemoButton
@onready var close_completion_button: Button = %CloseCompletionButton

var player_speed := 220.0
var interaction_distance := 80.0

var inventory_service: InventoryService
var bestiary_service: BestiaryService
var interaction_service: InteractionService
var save_service: Node

var current_step := DemoStep.COLLECT_ZHUYU
var initialized := false
var save_provider_registered := false
var menu_open := false
var zhuyu_collected := false
var stone_activated := false
var shensheng_discovered := false
var was_near_zhuyu := false
var was_near_stone := false
var was_near_shensheng := false
var was_interact_key_pressed := false
var was_menu_toggle_key_pressed := false


func _ready() -> void:
	_connect_button_signals()
	demo_menu_panel.visible = false
	completion_panel.visible = false
	prompt_label.visible = false
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	_log("山海经 Demo 场景启动")
	_initialize_services()


func _process(delta: float) -> void:
	_handle_menu_toggle_input()

	if not initialized:
		return

	if _is_ui_blocking_gameplay():
		prompt_label.visible = false
		was_interact_key_pressed = Input.is_key_pressed(KEY_E)
		_update_objective_guidance()
		return

	_move_player(delta)
	_update_prompt()
	_handle_interaction_input()
	_update_objective_guidance()


func _connect_button_signals() -> void:
	var save_callable := Callable(self, "_on_save_demo_pressed")
	var load_callable := Callable(self, "_on_load_demo_pressed")
	var reset_callable := Callable(self, "_on_reset_demo_pressed")
	var close_menu_callable := Callable(self, "_on_close_menu_pressed")
	var restart_callable := Callable(self, "_on_restart_demo_pressed")
	var close_completion_callable := Callable(self, "_on_close_completion_pressed")

	if not save_demo_button.pressed.is_connected(save_callable):
		save_demo_button.pressed.connect(save_callable)
	if not load_demo_button.pressed.is_connected(load_callable):
		load_demo_button.pressed.connect(load_callable)
	if not reset_demo_button.pressed.is_connected(reset_callable):
		reset_demo_button.pressed.connect(reset_callable)
	if not close_menu_button.pressed.is_connected(close_menu_callable):
		close_menu_button.pressed.connect(close_menu_callable)
	if not restart_demo_button.pressed.is_connected(restart_callable):
		restart_demo_button.pressed.connect(restart_callable)
	if not close_completion_button.pressed.is_connected(close_completion_callable):
		close_completion_button.pressed.connect(close_completion_callable)


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
	save_service = _get_autoload("SaveService")
	if save_service == null:
		_log_error("找不到 SaveService autoload，Demo 菜单保存读取不可用。")
		return

	if not _register_interactables():
		return
	if not _register_save_provider():
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

	var stone_registered := interaction_service.register_interactable(STONE_INTERACTABLE_ID, {
		"type": "activate",
		"metadata": {
			"target": "guidance_stone"
		},
		"callback_target": self,
		"callback_method": "_on_guidance_stone_interacted"
	})
	if not stone_registered:
		_log_error("InteractionService 注册失败：%s" % STONE_INTERACTABLE_ID)
		return false

	_log_ok("InteractionService 注册成功")
	return true


func _register_save_provider() -> bool:
	if save_service == null:
		save_service = _get_autoload("SaveService")
	if save_service == null:
		_log_error("找不到 SaveService autoload，无法注册 Demo provider。")
		return false

	if save_provider_registered and save_service.has_method("has_provider") and save_service.call("has_provider", SAVE_PROVIDER_ID) == true:
		return true

	if save_service.has_method("has_provider") and save_service.call("has_provider", SAVE_PROVIDER_ID) == true:
		if save_service.has_method("unregister_provider"):
			save_service.call("unregister_provider", SAVE_PROVIDER_ID)

	if not save_service.has_method("register_provider"):
		_log_error("SaveService 缺少 register_provider()。")
		return false

	var registered: Variant = save_service.call("register_provider", SAVE_PROVIDER_ID, self)
	save_provider_registered = registered == true
	if not save_provider_registered:
		_log_error("SaveService provider 注册失败：%s。" % SAVE_PROVIDER_ID)
		return false

	_log_ok("SaveService provider 已注册：%s。" % SAVE_PROVIDER_ID)
	return true


func _handle_menu_toggle_input() -> void:
	var menu_toggle_key_pressed := Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_M)
	if menu_toggle_key_pressed and not was_menu_toggle_key_pressed:
		if demo_menu_panel.visible:
			_close_demo_menu()
		else:
			_open_demo_menu()

	was_menu_toggle_key_pressed = menu_toggle_key_pressed


func _is_ui_blocking_gameplay() -> bool:
	return demo_menu_panel.visible or completion_panel.visible


func _open_demo_menu() -> void:
	demo_menu_panel.visible = true
	menu_open = true
	prompt_label.visible = false


func _close_demo_menu() -> void:
	demo_menu_panel.visible = false
	menu_open = false


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
	var near_stone := _is_near_stone()
	var near_shensheng := _is_near_shensheng()

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if near_zhuyu:
				_show_prompt("按 E 采集祝余叶")
			elif near_stone:
				_show_prompt("先采集祝余叶")
			elif near_shensheng:
				_show_prompt("先完成前置目标")
			else:
				prompt_label.visible = false
		DemoStep.ACTIVATE_STONE:
			if near_stone:
				_show_prompt("按 E 激活山海石碑")
			elif near_shensheng:
				_show_prompt("先激活山海石碑")
			else:
				prompt_label.visible = false
		DemoStep.OBSERVE_SHENSHENG:
			if near_shensheng:
				_show_prompt("按 E 观察狌狌")
			elif near_stone:
				_show_prompt("山海石碑已激活")
			else:
				prompt_label.visible = false
		DemoStep.COMPLETE:
			if near_zhuyu or near_stone or near_shensheng:
				_show_prompt("Demo 已完成")
			else:
				prompt_label.visible = false

	if near_zhuyu and not was_near_zhuyu:
		_log("靠近祝余叶")
	if near_stone and not was_near_stone:
		_log("靠近山海石碑")
	if near_shensheng and not was_near_shensheng:
		_log("靠近狌狌")

	was_near_zhuyu = near_zhuyu
	was_near_stone = near_stone
	was_near_shensheng = near_shensheng


func _handle_interaction_input() -> void:
	var interact_key_pressed := Input.is_key_pressed(KEY_E)
	var interact_just_pressed := (interact_key_pressed and not was_interact_key_pressed) or Input.is_action_just_pressed("ui_accept")

	if interact_just_pressed:
		_try_interact()

	was_interact_key_pressed = interact_key_pressed


func _try_interact() -> void:
	if current_step == DemoStep.COMPLETE:
		_log("Demo 已完成。")
		return

	if not _is_near_zhuyu() and not _is_near_stone() and not _is_near_shensheng():
		_log("附近没有可交互对象。")
		return

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if _is_near_zhuyu():
				var zhuyu_interacted := interaction_service.interact(OWNER_ID, ZHUYU_INTERACTABLE_ID)
				if not zhuyu_interacted:
					_log_error("InteractionService 交互失败：%s" % ZHUYU_INTERACTABLE_ID)
				return
			_log("请先前往当前目标。")
		DemoStep.ACTIVATE_STONE:
			if _is_near_stone():
				var stone_interacted := interaction_service.interact(OWNER_ID, STONE_INTERACTABLE_ID)
				if not stone_interacted:
					_log_error("InteractionService 交互失败：%s" % STONE_INTERACTABLE_ID)
				return
			_log("请先前往当前目标。")
		DemoStep.OBSERVE_SHENSHENG:
			if _is_near_shensheng():
				var shensheng_interacted := interaction_service.interact(OWNER_ID, SHENSHENG_INTERACTABLE_ID)
				if not shensheng_interacted:
					_log_error("InteractionService 交互失败：%s" % SHENSHENG_INTERACTABLE_ID)
				return
			_log("请先前往当前目标。")


func _on_zhuyu_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("采集失败：actor_id 为空。")
		return false
	if interactable_id != ZHUYU_INTERACTABLE_ID:
		_log_error("采集失败：interactable_id 不匹配。")
		return false
	if current_step != DemoStep.COLLECT_ZHUYU:
		_log("祝余叶不是当前目标。")
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
	current_step = DemoStep.ACTIVATE_STONE
	_log_ok("采集祝余叶成功")
	_log("当前目标：前往山海石碑")
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _on_guidance_stone_interacted(actor_id: String, interactable_id: String, _metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("激活失败：actor_id 为空。")
		return false
	if interactable_id != STONE_INTERACTABLE_ID:
		_log_error("激活失败：interactable_id 不匹配。")
		return false
	if current_step != DemoStep.ACTIVATE_STONE:
		_log_error("山海石碑还不是当前目标。")
		return false

	stone_activated = true
	current_step = DemoStep.OBSERVE_SHENSHENG
	guidance_stone.modulate.a = 0.55
	guidance_stone_label.text = "山海石碑（已激活）"
	prompt_label.visible = false
	_log_ok("山海石碑已激活")
	_log("当前目标：观察狌狌")
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _on_shensheng_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("观察失败：actor_id 为空。")
		return false
	if interactable_id != SHENSHENG_INTERACTABLE_ID:
		_log_error("观察失败：interactable_id 不匹配。")
		return false
	if current_step != DemoStep.OBSERVE_SHENSHENG:
		if not stone_activated:
			_log("需要先激活山海石碑。")
		else:
			_log("狌狌不是当前目标。")
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
	current_step = DemoStep.COMPLETE
	shensheng_creature.modulate.a = 0.45
	shensheng_label.text = "狌狌（已发现）"
	prompt_label.visible = false
	_log_ok("观察狌狌成功")
	_log("Demo 完成")
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	_show_completion_panel()
	return true


func get_save_data() -> Dictionary:
	return _build_demo_save_state()


func load_save_data(data: Dictionary) -> bool:
	return _apply_demo_save_state(data)


func _on_save_demo_pressed() -> void:
	if not _ensure_services_ready("保存 Demo"):
		return
	if not _register_save_provider():
		_log_error("Demo 保存失败")
		return
	if _build_demo_save_state().is_empty():
		_log_error("Demo 保存失败")
		return

	var saved: Variant = save_service.call("save_slot", DEMO_SAVE_SLOT)
	if saved == true:
		_log_ok("Demo 已保存到 Slot %d" % DEMO_SAVE_SLOT)
	else:
		_log_error("Demo 保存失败")


func _on_load_demo_pressed() -> void:
	if not _ensure_services_ready("读取 Demo"):
		return
	if not _register_save_provider():
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)
		return
	if not _has_demo_save_in_slot(DEMO_SAVE_SLOT):
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)
		return

	var loaded: Variant = save_service.call("load_slot", DEMO_SAVE_SLOT)
	if loaded == true:
		_log_ok("Demo 已从 Slot %d 读取" % DEMO_SAVE_SLOT)
		_close_demo_menu()
		if current_step == DemoStep.COMPLETE:
			_show_completion_panel()
		else:
			completion_panel.visible = false
	else:
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)


func _on_reset_demo_pressed() -> void:
	_reset_demo_state()


func _on_close_menu_pressed() -> void:
	_close_demo_menu()


func _on_restart_demo_pressed() -> void:
	_reset_demo_state()


func _on_close_completion_pressed() -> void:
	completion_panel.visible = false


func _build_demo_save_state() -> Dictionary:
	if inventory_service == null or bestiary_service == null:
		return {}

	return {
		"version": 1,
		"owner_id": OWNER_ID,
		"current_step": int(current_step),
		"world": {
			"pickup_collected": zhuyu_collected,
			"stone_activated": stone_activated,
			"creature_discovered": shensheng_discovered
		},
		"inventory": {
			ITEM_ID: inventory_service.get_item_count(OWNER_ID, ITEM_ID)
		},
		"bestiary": bestiary_service.get_save_data_for_owner(OWNER_ID)
	}


func _apply_demo_save_state(state: Dictionary) -> bool:
	if inventory_service == null or bestiary_service == null:
		return false
	if not (state is Dictionary):
		return false

	var saved_owner_id: Variant = state.get("owner_id", OWNER_ID)
	if saved_owner_id != OWNER_ID:
		return false

	var saved_step := _to_non_negative_int(state.get("current_step", -1))
	if saved_step < DemoStep.COLLECT_ZHUYU or saved_step > DemoStep.COMPLETE:
		return false

	var world_data: Variant = state.get("world", {})
	var inventory_data: Variant = state.get("inventory", {})
	var bestiary_data: Variant = state.get("bestiary", {})
	if not (world_data is Dictionary):
		return false
	if not (inventory_data is Dictionary):
		return false
	if not (bestiary_data is Dictionary):
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

	current_step = saved_step
	zhuyu_collected = world_data.get("pickup_collected", false) == true
	stone_activated = world_data.get("stone_activated", false) == true
	shensheng_discovered = world_data.get("creature_discovered", false) == true
	if current_step >= DemoStep.ACTIVATE_STONE:
		zhuyu_collected = true
	if current_step >= DemoStep.OBSERVE_SHENSHENG:
		stone_activated = true
	if current_step == DemoStep.COMPLETE:
		shensheng_discovered = true

	_apply_world_visual_state()
	completion_panel.visible = false
	if current_step == DemoStep.COMPLETE:
		_refresh_completion_summary()
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _has_demo_save_in_slot(slot: int) -> bool:
	if save_service == null or not save_service.has_method("get_slot_path"):
		return false

	var path_value: Variant = save_service.call("get_slot_path", slot)
	if not (path_value is String) or path_value.is_empty():
		return false
	var path: String = path_value
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false

	var save_data: Variant = json.data
	if not (save_data is Dictionary):
		return false

	var providers: Variant = save_data.get("providers", {})
	if not (providers is Dictionary):
		return false

	return providers.has(SAVE_PROVIDER_ID)


func _reset_demo_state() -> void:
	if inventory_service != null:
		inventory_service.clear_inventory(OWNER_ID)
	if bestiary_service != null:
		bestiary_service.clear_owner(OWNER_ID)

	player.position = PLAYER_START_POSITION
	current_step = DemoStep.COLLECT_ZHUYU
	zhuyu_collected = false
	stone_activated = false
	shensheng_discovered = false
	_close_demo_menu()
	completion_panel.visible = false
	_apply_world_visual_state()
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	_log_ok("Demo 已重置")


func _apply_world_visual_state() -> void:
	zhuyu_pickup.visible = not zhuyu_collected
	zhuyu_label.visible = not zhuyu_collected
	zhuyu_label.text = "祝余叶"

	if stone_activated:
		guidance_stone.modulate.a = 0.55
		guidance_stone_label.text = "山海石碑（已激活）"
	else:
		guidance_stone.modulate.a = 1.0
		guidance_stone_label.text = "山海石碑"

	if shensheng_discovered:
		shensheng_creature.modulate.a = 0.45
		shensheng_label.text = "狌狌（已发现）"
	else:
		shensheng_creature.modulate.a = 1.0
		shensheng_label.text = "狌狌"

	prompt_label.visible = false
	was_near_zhuyu = false
	was_near_stone = false
	was_near_shensheng = false
	was_interact_key_pressed = false


func _show_completion_panel() -> void:
	_refresh_completion_summary()
	completion_panel.visible = true
	prompt_label.visible = false
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()


func _refresh_completion_summary() -> void:
	completion_summary_label.text = "已完成 Demo 流程\n\n已采集：祝余叶\n已激活：山海石碑\n已发现：狌狌\n\n验证服务：\n- DataRegistry\n- InteractionService\n- InventoryService\n- BestiaryService\n- SaveService（菜单保存 / 读取）"


func _ensure_services_ready(action_name: String) -> bool:
	if not initialized:
		_log_error("%s 失败：Demo 尚未初始化。" % action_name)
		return false
	if inventory_service == null or bestiary_service == null or interaction_service == null or save_service == null:
		_log_error("%s 失败：Demo 服务不可用。" % action_name)
		return false
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


func _is_near_stone() -> bool:
	if guidance_stone == null or not guidance_stone.visible:
		return false
	return player.global_position.distance_to(guidance_stone.global_position) <= interaction_distance


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


func _update_objective_ui() -> void:
	match current_step:
		DemoStep.COLLECT_ZHUYU:
			objective_label.text = "当前目标：采集祝余叶"
		DemoStep.ACTIVATE_STONE:
			objective_label.text = "当前目标：前往山海石碑"
		DemoStep.OBSERVE_SHENSHENG:
			objective_label.text = "当前目标：观察狌狌"
		DemoStep.COMPLETE:
			objective_label.text = "当前目标：Demo 完成"


func _get_active_target_node() -> Node2D:
	match current_step:
		DemoStep.COLLECT_ZHUYU:
			return zhuyu_pickup
		DemoStep.ACTIVATE_STONE:
			return guidance_stone
		DemoStep.OBSERVE_SHENSHENG:
			return shensheng_creature
		DemoStep.COMPLETE:
			return null
	return null


func _update_objective_guidance() -> void:
	_reset_guidance_visuals()
	var active_target := _get_active_target_node()

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if zhuyu_pickup.visible:
				zhuyu_pickup.modulate.a = 1.0
				zhuyu_pickup.scale = Vector2(1.15, 1.15)
			guidance_stone.modulate.a = 0.35
			shensheng_creature.modulate.a = 0.35
			target_hint_label.text = _format_target_hint("祝余叶", "按 E 采集", active_target)
		DemoStep.ACTIVATE_STONE:
			guidance_stone.modulate.a = 1.0
			guidance_stone.scale = Vector2(1.15, 1.15)
			shensheng_creature.modulate.a = 0.35
			target_hint_label.text = _format_target_hint("山海石碑", "按 E 激活", active_target)
		DemoStep.OBSERVE_SHENSHENG:
			guidance_stone.modulate.a = 0.55
			shensheng_creature.modulate.a = 1.0
			shensheng_creature.scale = Vector2(1.15, 1.15)
			target_hint_label.text = _format_target_hint("狌狌", "按 E 观察", active_target)
		DemoStep.COMPLETE:
			guidance_stone.modulate.a = 0.55
			shensheng_creature.modulate.a = 0.45
			target_hint_label.text = "目标提示：Demo 已完成"


func _reset_guidance_visuals() -> void:
	zhuyu_pickup.scale = Vector2.ONE
	guidance_stone.scale = Vector2.ONE
	shensheng_creature.scale = Vector2.ONE


func _format_target_hint(target_name: String, action_text: String, active_target: Node2D) -> String:
	if active_target != null:
		var distance := int(player.global_position.distance_to(active_target.global_position))
		return "目标提示：%s距离 %d，%s" % [target_name, distance, action_text]
	return "目标提示：靠近%s，%s" % [target_name, action_text]


func _show_prompt(message: String) -> void:
	prompt_label.text = message
	prompt_label.visible = true


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
