extends Node2D

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const MIGU_BRANCH_ITEM_ID := "migu_branch"
const BASIC_ORE_ITEM_ID := "basic_ore"
const LUSHU_CREATURE_ID := "lushu"
const GENERIC_BEAST_CREATURE_ID := "generic_beast"
const ZHUYU_INTERACTABLE_ID := "pickup_zhuyu_leaf"
const SHENSHENG_INTERACTABLE_ID := "observe_shensheng"
const MIGU_BRANCH_INTERACTABLE_ID := "collect_migu_branch"
const BASIC_ORE_INTERACTABLE_ID := "collect_basic_ore"
const LUSHU_INTERACTABLE_ID := "observe_lushu"
const GENERIC_BEAST_INTERACTABLE_ID := "observe_generic_beast"
const STONE_INTERACTABLE_ID := "activate_guidance_stone"
const SAVE_PROVIDER_ID := "minimal_playable_demo"
const DEMO_SAVE_SLOT := 0
const PLAYER_START_POSITION := Vector2(220, 260)
const MAX_HISTORY_EVENTS := 8
const HISTORY_UI_RECENT_LIMIT := 5
const OPTIONAL_PROGRESS_DETAIL_LINE_LIMIT := 10
const OPTIONAL_PROGRESS_COMPACT_LINE_LIMIT := 6
const JOURNAL_SHORTCUT_HINT_TEXT := "快捷键：J 隐藏/显示，V 简洁/详细"
const JOURNAL_PANEL_TOP := 248.0
const JOURNAL_PANEL_BOTTOM := 600.0
const JOURNAL_CONTENT_LEFT := 16.0
const JOURNAL_CONTENT_RIGHT := 250.0
const JOURNAL_TITLE_RIGHT := 148.0
const JOURNAL_VIEW_BUTTON_LEFT := 154.0
const JOURNAL_TITLE_TOP := 8.0
const JOURNAL_TITLE_BOTTOM := 36.0
const JOURNAL_HINT_TOP := 38.0
const JOURNAL_HINT_BOTTOM := 58.0
const JOURNAL_PROGRESS_TOP := 66.0
const JOURNAL_PROGRESS_BOTTOM := 224.0
const JOURNAL_HISTORY_TOP := 238.0
const JOURNAL_HISTORY_BOTTOM := 340.0
const JOURNAL_TOGGLE_BUTTON_LEFT := 884.0
const JOURNAL_TOGGLE_BUTTON_TOP := 208.0
const JOURNAL_TOGGLE_BUTTON_RIGHT := 1010.0
const JOURNAL_TOGGLE_BUTTON_BOTTOM := 240.0

enum DemoStep {
	COLLECT_ZHUYU,
	ACTIVATE_STONE,
	OBSERVE_SHENSHENG,
	COMPLETE
}

@onready var world_root: Node2D = $WorldRoot
@onready var player: Polygon2D = %Player
@onready var zhuyu_pickup: Polygon2D = %ZhuyuPickup
@onready var zhuyu_label: Label = %ZhuyuLabel
@onready var guidance_stone: Polygon2D = %GuidanceStone
@onready var guidance_stone_label: Label = $WorldRoot/GuidanceStoneLabel
@onready var shensheng_creature: Polygon2D = %ShenshengCreature
@onready var shensheng_label: Label = %ShenshengLabel
@onready var migu_branch: Node2D = %MiguBranch
@onready var migu_branch_label: Label = $WorldRoot/MiguBranchLabel
@onready var lushu_creature: Node2D = %LushuCreature
@onready var lushu_label: Label = $WorldRoot/LushuLabel
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
@onready var interaction_history_panel: Control = %InteractionHistoryPanel
@onready var interaction_history_toggle_button: Button = %InteractionHistoryToggleButton
@onready var interaction_history_label: Label = %InteractionHistoryLabel
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
var interaction_history: Array[String] = []
var zhuyu_collected := false
var stone_activated := false
var shensheng_discovered := false
var optional_collectibles: Array = []
var optional_creatures: Array = []
var optional_state := {}
var optional_near_state := {}
var optional_progress_journal_label: Label
var optional_progress_view_toggle_button: Button
var optional_progress_shortcut_hint_label: Label
var optional_progress_detail_view := true
var recent_optional_completion_name := ""
var interaction_history_panel_visible := true
var was_near_zhuyu := false
var was_near_stone := false
var was_near_shensheng := false
var was_interact_key_pressed := false
var was_menu_toggle_key_pressed := false
var was_journal_toggle_key_pressed := false
var was_progress_view_toggle_key_pressed := false


func _ready() -> void:
	_init_optional_content_config()
	_configure_interaction_history_panel()
	_connect_button_signals()
	demo_menu_panel.visible = false
	completion_panel.visible = false
	prompt_label.visible = false
	_set_interaction_history_panel_visible(true)
	_update_history_ui()
	_update_optional_progress_journal()
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	_log("山海经 Demo 场景启动")
	_initialize_services()


func _init_optional_content_config() -> void:
	optional_collectibles = [
		{
			"id": MIGU_BRANCH_ITEM_ID,
			"interactable_id": MIGU_BRANCH_INTERACTABLE_ID,
			"display_name": "迷穀枝",
			"content_type": "collectible",
			"interaction_type": "pickup",
			"node": migu_branch,
			"label": migu_branch_label,
			"label_default": "迷穀枝",
			"label_done": "迷穀枝（已采集）",
			"history": "采集迷穀枝",
			"prompt_locked": "完成主流程后解锁迷穀枝",
			"prompt_ready": "按 E 采集迷穀枝",
			"prompt_done": "迷穀枝已采集",
			"locked_log": "完成主流程后解锁迷穀枝。",
			"already_done_log": "迷穀枝已经采集。",
			"success_log": "采集迷穀枝成功",
			"error_prefix": "采集失败",
			"completion_done_prefix": "已采集",
			"metadata_key": "item_id",
			"count": 1,
			"locked_alpha": 0.3,
			"ready_alpha": 1.0,
			"done_alpha": 0.35
		},
		{
			"id": BASIC_ORE_ITEM_ID,
			"interactable_id": BASIC_ORE_INTERACTABLE_ID,
			"display_name": "粗矿石",
			"content_type": "collectible",
			"interaction_type": "pickup",
			"node": _create_optional_polygon(
				"BasicOrePickup",
				Vector2(840, 360),
				Color(0.5, 0.54, 0.58, 1),
				PackedVector2Array([
					Vector2(-26, -14),
					Vector2(-6, -28),
					Vector2(18, -22),
					Vector2(30, 2),
					Vector2(16, 24),
					Vector2(-18, 20),
					Vector2(-32, 0)
				])
			),
			"label": _create_optional_label("BasicOreLabel", Vector2(800, 396), "粗矿石"),
			"label_default": "粗矿石",
			"label_done": "粗矿石（已采集）",
			"history": "采集粗矿石",
			"prompt_locked": "完成主流程后解锁粗矿石",
			"prompt_ready": "按 E 采集粗矿石",
			"prompt_done": "粗矿石已采集",
			"locked_log": "完成主流程后解锁粗矿石。",
			"already_done_log": "粗矿石已经采集。",
			"success_log": "采集粗矿石成功",
			"error_prefix": "采集失败",
			"completion_done_prefix": "已采集",
			"metadata_key": "item_id",
			"count": 1,
			"locked_alpha": 0.3,
			"ready_alpha": 1.0,
			"done_alpha": 0.35
		}
	]

	optional_creatures = [
		{
			"id": LUSHU_CREATURE_ID,
			"interactable_id": LUSHU_INTERACTABLE_ID,
			"display_name": "鹿蜀",
			"content_type": "creature",
			"interaction_type": "observe",
			"node": lushu_creature,
			"label": lushu_label,
			"label_default": "鹿蜀",
			"label_done": "鹿蜀（已发现）",
			"history": "发现鹿蜀",
			"prompt_locked": "完成主流程后解锁鹿蜀",
			"prompt_ready": "按 E 观察鹿蜀",
			"prompt_done": "鹿蜀已发现",
			"locked_log": "完成主流程后解锁鹿蜀。",
			"already_done_log": "鹿蜀已经被发现。",
			"success_log": "观察鹿蜀成功",
			"error_prefix": "观察失败",
			"completion_done_prefix": "已发现",
			"metadata_key": "creature_id",
			"locked_alpha": 0.3,
			"ready_alpha": 1.0,
			"done_alpha": 0.45
		},
		{
			"id": GENERIC_BEAST_CREATURE_ID,
			"interactable_id": GENERIC_BEAST_INTERACTABLE_ID,
			"display_name": "普通野兽",
			"content_type": "creature",
			"interaction_type": "observe",
			"node": _create_optional_polygon(
				"GenericBeastCreature",
				Vector2(900, 500),
				Color(0.66, 0.48, 0.34, 1),
				PackedVector2Array([
					Vector2(-34, -8),
					Vector2(-14, -26),
					Vector2(14, -24),
					Vector2(36, -6),
					Vector2(28, 18),
					Vector2(-8, 28),
					Vector2(-32, 12)
				])
			),
			"label": _create_optional_label("GenericBeastLabel", Vector2(856, 540), "普通野兽"),
			"label_default": "普通野兽",
			"label_done": "普通野兽（已发现）",
			"history": "发现普通野兽",
			"prompt_locked": "完成主流程后解锁普通野兽",
			"prompt_ready": "按 E 观察普通野兽",
			"prompt_done": "普通野兽已发现",
			"locked_log": "完成主流程后解锁普通野兽。",
			"already_done_log": "普通野兽已经被发现。",
			"success_log": "观察普通野兽成功",
			"error_prefix": "观察失败",
			"completion_done_prefix": "已发现",
			"metadata_key": "creature_id",
			"locked_alpha": 0.3,
			"ready_alpha": 1.0,
			"done_alpha": 0.45
		}
	]

	optional_state.clear()
	optional_near_state.clear()
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		optional_state[content_id] = false
		optional_near_state[content_id] = false


func _create_optional_polygon(node_name: String, position: Vector2, color: Color, polygon: PackedVector2Array) -> Polygon2D:
	var node := Polygon2D.new()
	node.name = node_name
	node.position = position
	node.color = color
	node.polygon = polygon
	world_root.add_child(node)
	return node


func _create_optional_label(label_name: String, label_position: Vector2, text: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = label_position
	label.text = text
	world_root.add_child(label)
	return label


func _process(delta: float) -> void:
	_handle_menu_toggle_input()

	if not initialized:
		_sync_journal_shortcut_key_state()
		return

	if _is_ui_blocking_gameplay():
		prompt_label.visible = false
		was_interact_key_pressed = Input.is_key_pressed(KEY_E)
		_sync_journal_shortcut_key_state()
		_update_objective_guidance()
		return

	_handle_journal_shortcut_input()
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
	var history_toggle_callable := Callable(self, "_on_interaction_history_toggle_pressed")
	var progress_view_toggle_callable := Callable(self, "_on_optional_progress_view_toggle_pressed")

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
	if interaction_history_toggle_button != null and not interaction_history_toggle_button.pressed.is_connected(history_toggle_callable):
		interaction_history_toggle_button.pressed.connect(history_toggle_callable)
	if optional_progress_view_toggle_button != null and not optional_progress_view_toggle_button.pressed.is_connected(progress_view_toggle_callable):
		optional_progress_view_toggle_button.pressed.connect(progress_view_toggle_callable)


func _configure_interaction_history_panel() -> void:
	if interaction_history_panel == null:
		return

	_configure_interaction_history_panel_bounds()
	_configure_interaction_history_title()
	_configure_optional_progress_view_toggle_button()
	_configure_optional_progress_shortcut_hint_label()
	_configure_optional_progress_label()
	_configure_interaction_history_label()
	_configure_interaction_history_toggle_button()


func _configure_interaction_history_panel_bounds() -> void:
	interaction_history_panel.offset_top = JOURNAL_PANEL_TOP
	interaction_history_panel.offset_bottom = JOURNAL_PANEL_BOTTOM


func _configure_interaction_history_title() -> void:
	var title_label := interaction_history_panel.get_node_or_null("InteractionHistoryTitleLabel") as Label
	if title_label != null:
		title_label.text = "可选进度"
		title_label.offset_top = JOURNAL_TITLE_TOP
		title_label.offset_right = JOURNAL_TITLE_RIGHT
		title_label.offset_bottom = JOURNAL_TITLE_BOTTOM


func _configure_optional_progress_label() -> void:
	if optional_progress_journal_label == null:
		optional_progress_journal_label = Label.new()
		optional_progress_journal_label.name = "OptionalProgressJournalLabel"
		optional_progress_journal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		interaction_history_panel.add_child(optional_progress_journal_label)
	optional_progress_journal_label.clip_text = true
	optional_progress_journal_label.offset_left = JOURNAL_CONTENT_LEFT
	optional_progress_journal_label.offset_top = JOURNAL_PROGRESS_TOP
	optional_progress_journal_label.offset_right = JOURNAL_CONTENT_RIGHT
	optional_progress_journal_label.offset_bottom = JOURNAL_PROGRESS_BOTTOM


func _configure_optional_progress_view_toggle_button() -> void:
	if optional_progress_view_toggle_button == null:
		optional_progress_view_toggle_button = Button.new()
		optional_progress_view_toggle_button.name = "OptionalProgressViewToggleButton"
		interaction_history_panel.add_child(optional_progress_view_toggle_button)
		var progress_view_toggle_callable := Callable(self, "_on_optional_progress_view_toggle_pressed")
		optional_progress_view_toggle_button.pressed.connect(progress_view_toggle_callable)
	optional_progress_view_toggle_button.offset_left = JOURNAL_VIEW_BUTTON_LEFT
	optional_progress_view_toggle_button.offset_top = JOURNAL_TITLE_TOP
	optional_progress_view_toggle_button.offset_right = JOURNAL_CONTENT_RIGHT
	optional_progress_view_toggle_button.offset_bottom = JOURNAL_TITLE_BOTTOM
	optional_progress_view_toggle_button.visible = true
	_update_optional_progress_view_toggle_text()


func _configure_optional_progress_shortcut_hint_label() -> void:
	if optional_progress_shortcut_hint_label == null:
		optional_progress_shortcut_hint_label = Label.new()
		optional_progress_shortcut_hint_label.name = "OptionalProgressShortcutHintLabel"
		optional_progress_shortcut_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		interaction_history_panel.add_child(optional_progress_shortcut_hint_label)
	optional_progress_shortcut_hint_label.text = JOURNAL_SHORTCUT_HINT_TEXT
	optional_progress_shortcut_hint_label.clip_text = true
	optional_progress_shortcut_hint_label.offset_left = JOURNAL_CONTENT_LEFT
	optional_progress_shortcut_hint_label.offset_top = JOURNAL_HINT_TOP
	optional_progress_shortcut_hint_label.offset_right = JOURNAL_CONTENT_RIGHT
	optional_progress_shortcut_hint_label.offset_bottom = JOURNAL_HINT_BOTTOM


func _configure_interaction_history_label() -> void:
	if interaction_history_label != null:
		interaction_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		interaction_history_label.clip_text = true
		interaction_history_label.max_lines_visible = HISTORY_UI_RECENT_LIMIT + 1
		interaction_history_label.offset_left = JOURNAL_CONTENT_LEFT
		interaction_history_label.offset_top = JOURNAL_HISTORY_TOP
		interaction_history_label.offset_right = JOURNAL_CONTENT_RIGHT
		interaction_history_label.offset_bottom = JOURNAL_HISTORY_BOTTOM


func _configure_interaction_history_toggle_button() -> void:
	if interaction_history_toggle_button == null:
		return
	interaction_history_toggle_button.offset_left = JOURNAL_TOGGLE_BUTTON_LEFT
	interaction_history_toggle_button.offset_top = JOURNAL_TOGGLE_BUTTON_TOP
	interaction_history_toggle_button.offset_right = JOURNAL_TOGGLE_BUTTON_RIGHT
	interaction_history_toggle_button.offset_bottom = JOURNAL_TOGGLE_BUTTON_BOTTOM
	interaction_history_toggle_button.visible = true
	_update_interaction_history_toggle_text()


func _on_optional_progress_view_toggle_pressed() -> void:
	optional_progress_detail_view = not optional_progress_detail_view
	_update_optional_progress_view_toggle_text()
	_update_optional_progress_journal()


func _update_optional_progress_view_toggle_text() -> void:
	if optional_progress_view_toggle_button == null:
		return
	if optional_progress_detail_view:
		optional_progress_view_toggle_button.text = "简洁视图"
	else:
		optional_progress_view_toggle_button.text = "详细视图"


func _on_interaction_history_toggle_pressed() -> void:
	_set_interaction_history_panel_visible(not interaction_history_panel_visible)


func _handle_journal_shortcut_input() -> void:
	var journal_toggle_key_pressed := Input.is_key_pressed(KEY_J)
	var progress_view_toggle_key_pressed := Input.is_key_pressed(KEY_V)

	if journal_toggle_key_pressed and not was_journal_toggle_key_pressed:
		_on_interaction_history_toggle_pressed()
	if progress_view_toggle_key_pressed and not was_progress_view_toggle_key_pressed:
		_on_optional_progress_view_toggle_pressed()

	was_journal_toggle_key_pressed = journal_toggle_key_pressed
	was_progress_view_toggle_key_pressed = progress_view_toggle_key_pressed


func _sync_journal_shortcut_key_state() -> void:
	was_journal_toggle_key_pressed = Input.is_key_pressed(KEY_J)
	was_progress_view_toggle_key_pressed = Input.is_key_pressed(KEY_V)


func _set_interaction_history_panel_visible(is_visible: bool) -> void:
	interaction_history_panel_visible = is_visible
	if log_label != null:
		log_label.visible = interaction_history_panel_visible
	if interaction_history_panel != null:
		interaction_history_panel.visible = interaction_history_panel_visible
	_update_interaction_history_toggle_text()


func _update_interaction_history_toggle_text() -> void:
	if interaction_history_toggle_button == null:
		return
	if interaction_history_panel_visible:
		interaction_history_toggle_button.text = "隐藏日志"
	else:
		interaction_history_toggle_button.text = "显示日志"


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
	_append_history_event("Demo 开始：采集祝余叶")
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

	if not _register_optional_interactables():
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


func _register_optional_interactables() -> bool:
	for config in optional_collectibles:
		if not _register_optional_interactable(config, "_on_optional_collectible_interacted"):
			return false

	for config in optional_creatures:
		if not _register_optional_interactable(config, "_on_optional_creature_interacted"):
			return false

	return true


func _register_optional_interactable(config: Dictionary, callback_method: String) -> bool:
	var interactable_id := str(config.get("interactable_id", ""))
	if interactable_id.is_empty():
		_log_error("InteractionService 注册失败：optional interactable_id 为空")
		return false

	var metadata_key := str(config.get("metadata_key", ""))
	if metadata_key.is_empty():
		_log_error("InteractionService 注册失败：%s metadata_key 为空" % interactable_id)
		return false

	var metadata := {}
	metadata[metadata_key] = str(config.get("id", ""))
	if config.has("count"):
		metadata["count"] = _to_positive_int(config.get("count", 1))

	var registered := interaction_service.register_interactable(interactable_id, {
		"type": str(config.get("interaction_type", "")),
		"metadata": metadata,
		"callback_target": self,
		"callback_method": callback_method
	})
	if not registered:
		_log_error("InteractionService 注册失败：%s" % interactable_id)
		return false

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
	var nearest_optional := _nearest_optional_config()
	var near_optional := not nearest_optional.is_empty()

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if near_zhuyu:
				_show_prompt("按 E 采集祝余叶")
			elif near_stone:
				_show_prompt("先采集祝余叶")
			elif near_shensheng:
				_show_prompt("先完成前置目标")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.ACTIVATE_STONE:
			if near_stone:
				_show_prompt("按 E 激活山海石碑")
			elif near_shensheng:
				_show_prompt("先激活山海石碑")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.OBSERVE_SHENSHENG:
			if near_shensheng:
				_show_prompt("按 E 观察狌狌")
			elif near_stone:
				_show_prompt("山海石碑已激活")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.COMPLETE:
			if near_optional:
				if _is_optional_done(nearest_optional):
					_show_prompt(str(nearest_optional.get("prompt_done", "")))
				else:
					_show_prompt(str(nearest_optional.get("prompt_ready", "")))
			elif near_zhuyu or near_stone or near_shensheng:
				_show_prompt("Demo 已完成")
			else:
				prompt_label.visible = false

	if near_zhuyu and not was_near_zhuyu:
		_log("靠近祝余叶")
	if near_stone and not was_near_stone:
		_log("靠近山海石碑")
	if near_shensheng and not was_near_shensheng:
		_log("靠近狌狌")
	_update_optional_near_state_logs()

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
	var near_zhuyu := _is_near_zhuyu()
	var near_stone := _is_near_stone()
	var near_shensheng := _is_near_shensheng()
	var nearest_optional := _nearest_optional_config()
	var near_optional := not nearest_optional.is_empty()

	if current_step == DemoStep.COMPLETE:
		if near_optional:
			var interactable_id := str(nearest_optional.get("interactable_id", ""))
			var optional_interacted := interaction_service.interact(OWNER_ID, interactable_id)
			if not optional_interacted:
				_log_error("InteractionService 交互失败：%s" % interactable_id)
			return
		if near_zhuyu or near_stone or near_shensheng:
			_log("Demo 已完成。")
		else:
			_log("附近没有可交互对象。")
		return

	if near_optional:
		_log(str(nearest_optional.get("locked_log", "")))
		return

	if not near_zhuyu and not near_stone and not near_shensheng:
		_log("附近没有可交互对象。")
		return

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if near_zhuyu:
				var zhuyu_interacted := interaction_service.interact(OWNER_ID, ZHUYU_INTERACTABLE_ID)
				if not zhuyu_interacted:
					_log_error("InteractionService 交互失败：%s" % ZHUYU_INTERACTABLE_ID)
				return
			_log("请先前往当前目标。")
		DemoStep.ACTIVATE_STONE:
			if near_stone:
				var stone_interacted := interaction_service.interact(OWNER_ID, STONE_INTERACTABLE_ID)
				if not stone_interacted:
					_log_error("InteractionService 交互失败：%s" % STONE_INTERACTABLE_ID)
				return
			_log("请先前往当前目标。")
		DemoStep.OBSERVE_SHENSHENG:
			if near_shensheng:
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
	_append_history_event("采集祝余叶")
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
	_append_history_event("激活山海石碑")
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
	_append_history_event("发现狌狌")
	_append_history_event("Demo 完成")
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	_show_completion_panel()
	return true


func _on_optional_collectible_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	return _on_optional_content_interacted(actor_id, interactable_id, metadata, "collectible")


func _on_optional_creature_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	return _on_optional_content_interacted(actor_id, interactable_id, metadata, "creature")


func _on_optional_content_interacted(actor_id: String, interactable_id: String, metadata: Dictionary, expected_type: String) -> bool:
	var config := _find_optional_config_by_interactable_id(interactable_id)
	var error_prefix := str(config.get("error_prefix", "交互失败"))
	if actor_id.is_empty():
		_log_error("%s：actor_id 为空。" % error_prefix)
		return false
	if config.is_empty() or config.get("content_type", "") != expected_type:
		_log_error("%s：interactable_id 不匹配。" % error_prefix)
		return false
	if current_step != DemoStep.COMPLETE:
		_log(str(config.get("locked_log", "")))
		return false
	if _is_optional_done(config):
		_log(str(config.get("already_done_log", "")))
		return true

	var metadata_key := str(config.get("metadata_key", ""))
	var content_id_value: Variant = metadata.get(metadata_key, "")
	if not (content_id_value is String) or content_id_value.is_empty():
		_log_error("%s：metadata.%s 无效。" % [error_prefix, metadata_key])
		return false
	var content_id: String = content_id_value

	if expected_type == "collectible":
		var count := _to_positive_int(metadata.get("count", 0))
		if count <= 0:
			_log_error("%s：metadata.count 无效。" % error_prefix)
			return false
		if not inventory_service.add_item(actor_id, content_id, count):
			_log_error("背包增加 %s 失败。" % content_id)
			return false
		if not bestiary_service.discover_item(actor_id, content_id):
			_log_error("图鉴发现 %s 失败。" % content_id)
			return false
	elif expected_type == "creature":
		if not bestiary_service.discover_creature(actor_id, content_id):
			_log_error("图鉴发现 %s 失败。" % content_id)
			return false
	else:
		_log_error("未知 optional content 类型：%s。" % expected_type)
		return false

	_set_optional_done(config, true)
	recent_optional_completion_name = str(config.get("display_name", content_id))
	_update_optional_content_visuals()
	prompt_label.visible = false
	_log_ok(str(config.get("success_log", "")))
	_append_history_event(str(config.get("history", "")))
	_refresh_status()
	_refresh_completion_summary()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func get_save_data() -> Dictionary:
	return _build_demo_save_state()


func load_save_data(data: Dictionary) -> bool:
	return _apply_demo_save_state(data)


func _on_save_demo_pressed() -> void:
	if not _ensure_services_ready("保存 Demo"):
		_append_history_event("保存 Demo 失败")
		return
	if not _register_save_provider():
		_log_error("Demo 保存失败")
		_append_history_event("保存 Demo 失败")
		return
	if _build_demo_save_state().is_empty():
		_log_error("Demo 保存失败")
		_append_history_event("保存 Demo 失败")
		return

	_append_history_event("保存 Demo")
	var saved: Variant = save_service.call("save_slot", DEMO_SAVE_SLOT)
	if saved == true:
		_log_ok("Demo 已保存到 Slot %d" % DEMO_SAVE_SLOT)
	else:
		_remove_latest_history_event("保存 Demo")
		_log_error("Demo 保存失败")
		_append_history_event("保存 Demo 失败")


func _on_load_demo_pressed() -> void:
	if not _ensure_services_ready("读取 Demo"):
		_append_history_event("读取 Demo 失败")
		return
	if not _register_save_provider():
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)
		_append_history_event("读取 Demo 失败")
		return
	if not _has_demo_save_in_slot(DEMO_SAVE_SLOT):
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)
		_append_history_event("读取 Demo 失败")
		return

	var loaded: Variant = save_service.call("load_slot", DEMO_SAVE_SLOT)
	if loaded == true:
		_log_ok("Demo 已从 Slot %d 读取" % DEMO_SAVE_SLOT)
		_close_demo_menu()
		_append_history_event("读取 Demo")
		if current_step == DemoStep.COMPLETE:
			_show_completion_panel()
		else:
			completion_panel.visible = false
	else:
		_log_error("Slot %d 没有可读取的 Demo 存档" % DEMO_SAVE_SLOT)
		_append_history_event("读取 Demo 失败")


func _on_reset_demo_pressed() -> void:
	_reset_demo_state()


func _on_close_menu_pressed() -> void:
	_close_demo_menu()


func _on_restart_demo_pressed() -> void:
	_reset_demo_state("重新开始 Demo")


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
			"creature_discovered": shensheng_discovered,
			"optional": _build_optional_save_state()
		},
		"player": {
			"position": {
				"x": player.position.x,
				"y": player.position.y
			}
		},
		"inventory": _build_inventory_save_state(),
		"bestiary": bestiary_service.get_save_data_for_owner(OWNER_ID),
		"history": interaction_history.duplicate()
	}


func _build_optional_save_state() -> Dictionary:
	var state := {}
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		state[content_id] = _is_optional_done(config)
	return state


func _apply_optional_save_state(state: Dictionary) -> void:
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		optional_state[content_id] = state.get(content_id, false) == true

	_update_optional_content_visuals()


func _apply_legacy_optional_save_state(world_data: Dictionary, optional_data: Dictionary) -> void:
	if not optional_data.has(MIGU_BRANCH_ITEM_ID) and world_data.has("migu_collected"):
		optional_state[MIGU_BRANCH_ITEM_ID] = world_data.get("migu_collected", false) == true
	if not optional_data.has(LUSHU_CREATURE_ID) and world_data.has("lushu_discovered"):
		optional_state[LUSHU_CREATURE_ID] = world_data.get("lushu_discovered", false) == true

	_update_optional_content_visuals()


func _build_inventory_save_state() -> Dictionary:
	var state := {
		ITEM_ID: inventory_service.get_item_count(OWNER_ID, ITEM_ID)
	}

	for config in optional_collectibles:
		var content_id := str(config.get("id", ""))
		state[content_id] = inventory_service.get_item_count(OWNER_ID, content_id)

	return state


func _build_loaded_inventory_counts(inventory_data: Dictionary) -> Dictionary:
	var counts := {}
	var item_count := _to_non_negative_int(inventory_data.get(ITEM_ID, 0))
	if item_count < 0:
		return {}
	counts[ITEM_ID] = item_count

	for config in optional_collectibles:
		var content_id := str(config.get("id", ""))
		var optional_item_count := _to_non_negative_int(inventory_data.get(content_id, 0))
		if optional_item_count < 0:
			return {}
		counts[content_id] = optional_item_count

	return counts


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

	var inventory_counts := _build_loaded_inventory_counts(inventory_data)
	if inventory_counts.is_empty():
		return false

	inventory_service.clear_inventory(OWNER_ID)
	bestiary_service.clear_owner(OWNER_ID)
	for item_id in inventory_counts:
		var item_id_string := str(item_id)
		var item_count: int = inventory_counts[item_id]
		if item_count > 0 and not inventory_service.add_item(OWNER_ID, item_id_string, item_count):
			return false
	if not bestiary_service.load_save_data_for_owner(OWNER_ID, bestiary_data):
		return false

	current_step = saved_step
	zhuyu_collected = world_data.get("pickup_collected", false) == true
	stone_activated = world_data.get("stone_activated", false) == true
	shensheng_discovered = world_data.get("creature_discovered", false) == true
	recent_optional_completion_name = ""
	var optional_data: Variant = world_data.get("optional", {})
	if not (optional_data is Dictionary):
		return false
	_apply_optional_save_state(optional_data)
	_apply_legacy_optional_save_state(world_data, optional_data)
	if current_step >= DemoStep.ACTIVATE_STONE:
		zhuyu_collected = true
	if current_step >= DemoStep.OBSERVE_SHENSHENG:
		stone_activated = true
	if current_step == DemoStep.COMPLETE:
		shensheng_discovered = true

	_restore_saved_player_position(state)
	_restore_saved_history(state)
	_apply_world_visual_state()
	completion_panel.visible = false
	if current_step == DemoStep.COMPLETE:
		_refresh_completion_summary()
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _restore_saved_player_position(state: Dictionary) -> void:
	var player_data: Variant = state.get("player", {})
	if not (player_data is Dictionary):
		return

	var position_data: Variant = player_data.get("position", {})
	if not (position_data is Dictionary):
		return
	if not position_data.has("x") or not position_data.has("y"):
		return

	player.position = Vector2(
		_to_float_or_default(position_data.get("x"), player.position.x),
		_to_float_or_default(position_data.get("y"), player.position.y)
	)


func _restore_saved_history(state: Dictionary) -> void:
	interaction_history.clear()

	var loaded_history: Variant = state.get("history", [])
	if loaded_history is Array:
		for entry in loaded_history:
			if entry is String and not entry.strip_edges().is_empty():
				interaction_history.append(entry)

	while interaction_history.size() > MAX_HISTORY_EVENTS:
		interaction_history.pop_front()

	_update_history_ui()


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


func _reset_demo_state(history_message := "Demo 已重置") -> void:
	if inventory_service != null:
		inventory_service.clear_inventory(OWNER_ID)
	if bestiary_service != null:
		bestiary_service.clear_owner(OWNER_ID)

	player.position = PLAYER_START_POSITION
	current_step = DemoStep.COLLECT_ZHUYU
	zhuyu_collected = false
	stone_activated = false
	shensheng_discovered = false
	recent_optional_completion_name = ""
	_reset_optional_state()
	_close_demo_menu()
	completion_panel.visible = false
	_apply_world_visual_state()
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()
	interaction_history.clear()
	_append_history_event(history_message)
	_log_ok(history_message)


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

	_update_optional_content_visuals()

	prompt_label.visible = false
	was_near_zhuyu = false
	was_near_stone = false
	was_near_shensheng = false
	_reset_optional_near_state()
	was_interact_key_pressed = false


func _show_completion_panel() -> void:
	_refresh_completion_summary()
	completion_panel.visible = true
	prompt_label.visible = false
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()


func _refresh_completion_summary() -> void:
	completion_summary_label.text = "已完成 Demo 流程\n\n已采集：祝余叶\n已激活：山海石碑\n已发现：狌狌\n%s\n\n%s\n\n验证服务：\n- DataRegistry\n- InteractionService\n- InventoryService\n- BestiaryService\n- SaveService（菜单保存 / 读取）" % [
		_format_optional_completion_summary(),
		_format_completion_history()
	]


func _format_optional_completion_summary() -> String:
	if _has_completed_all_optional_content():
		var completed_summary := "\n可选探索："
		for config in _all_optional_content():
			completed_summary += "\n- %s：%s" % [
				str(config.get("completion_done_prefix", "已完成")),
				str(config.get("display_name", config.get("id", "")))
			]
		return completed_summary
	return "\n可选探索已解锁：%s" % _format_optional_display_names("、")


func _update_optional_progress_journal() -> void:
	if optional_progress_journal_label == null:
		return
	if optional_progress_detail_view:
		optional_progress_journal_label.max_lines_visible = OPTIONAL_PROGRESS_DETAIL_LINE_LIMIT
	else:
		optional_progress_journal_label.max_lines_visible = OPTIONAL_PROGRESS_COMPACT_LINE_LIMIT
	optional_progress_journal_label.text = _format_optional_progress_journal()


func _format_optional_progress_journal() -> String:
	var optional_content := _all_optional_content()
	return "可选进度：%d / %d\n最近完成：%s\n\n%s\n\n%s" % [
		_count_completed_optional_content(optional_content),
		optional_content.size(),
		_format_recent_optional_completion(),
		_format_optional_progress_section("可选采集物", optional_collectibles),
		_format_optional_progress_section("可选生物 / 互动", optional_creatures)
	]


func _format_optional_progress_section(title: String, configs: Array) -> String:
	var formatted := "%s：%d / %d" % [
		title,
		_count_completed_optional_content(configs),
		configs.size()
	]
	if configs.is_empty():
		return "%s\n无内容" % formatted
	if not optional_progress_detail_view:
		return formatted

	for config in configs:
		formatted += "\n- %s：%s" % [
			str(config.get("display_name", config.get("id", ""))),
			_format_optional_progress_status(config)
		]
	return formatted


func _count_completed_optional_content(configs: Array) -> int:
	var completed_count := 0
	for config in configs:
		if _is_optional_done(config):
			completed_count += 1
	return completed_count


func _format_recent_optional_completion() -> String:
	if recent_optional_completion_name.is_empty():
		return "无"
	return recent_optional_completion_name


func _format_optional_progress_status(config: Dictionary) -> String:
	if _is_optional_done(config):
		return "已完成"
	return "未完成"


func _is_optional_exploration_complete() -> bool:
	return _has_completed_all_optional_content()


func _append_history_event(message: String) -> void:
	var trimmed_message := message.strip_edges()
	if trimmed_message.is_empty():
		return

	interaction_history.append(trimmed_message)
	while interaction_history.size() > MAX_HISTORY_EVENTS:
		interaction_history.pop_front()

	_update_history_ui()


func _remove_latest_history_event(message: String) -> void:
	if interaction_history.is_empty():
		return
	if interaction_history[interaction_history.size() - 1] == message:
		interaction_history.pop_back()
		_update_history_ui()


func _update_history_ui() -> void:
	if interaction_history_label == null:
		return
	if interaction_history.is_empty():
		interaction_history_label.text = "历史记录（最近 %d 条）\n尚无记录" % HISTORY_UI_RECENT_LIMIT
		return

	var formatted := "历史记录（最近 %d 条）" % HISTORY_UI_RECENT_LIMIT
	var first_visible_index: int = max(0, interaction_history.size() - HISTORY_UI_RECENT_LIMIT)
	for index in range(first_visible_index, interaction_history.size()):
		formatted += "\n- %s" % interaction_history[index]
	interaction_history_label.text = formatted


func _format_completion_history() -> String:
	if interaction_history.is_empty():
		return "历史记录：无"

	var formatted := "历史记录："
	for entry in interaction_history:
		formatted += "\n- %s" % entry
	return formatted


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
	for config in optional_collectibles:
		var item_id := str(config.get("id", ""))
		if data_registry.call("has_item", item_id) != true:
			_log_error("Demo 物品不存在：%s。" % item_id)
			return false

	if not data_registry.has_method("has_creature"):
		_log_error("DataRegistry 缺少 has_creature()，无法验证 Demo 生物。")
		return false
	if data_registry.call("has_creature", CREATURE_ID) != true:
		_log_error("Demo 生物不存在：%s。" % CREATURE_ID)
		return false
	for config in optional_creatures:
		var creature_id := str(config.get("id", ""))
		if data_registry.call("has_creature", creature_id) != true:
			_log_error("Demo 生物不存在：%s。" % creature_id)
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


func _all_optional_content() -> Array:
	return optional_collectibles + optional_creatures


func _find_optional_config_by_id(content_id: String) -> Dictionary:
	for config in _all_optional_content():
		if str(config.get("id", "")) == content_id:
			return config
	return {}


func _find_optional_config_by_interactable_id(interactable_id: String) -> Dictionary:
	for config in _all_optional_content():
		if str(config.get("interactable_id", "")) == interactable_id:
			return config
	return {}


func _is_optional_done(config: Dictionary) -> bool:
	var content_id := str(config.get("id", ""))
	return optional_state.get(content_id, false) == true


func _set_optional_done(config: Dictionary, done: bool) -> void:
	var content_id := str(config.get("id", ""))
	optional_state[content_id] = done


func _is_near_optional(config: Dictionary) -> bool:
	var node: Node2D = config.get("node", null) as Node2D
	if node == null or not node.visible:
		return false
	return player.global_position.distance_to(node.global_position) <= interaction_distance


func _nearest_optional_config() -> Dictionary:
	for config in _all_optional_content():
		if _is_near_optional(config):
			return config
	return {}


func _has_completed_all_optional_content() -> bool:
	var optional_content := _all_optional_content()
	if optional_content.is_empty():
		return false

	for config in optional_content:
		if not _is_optional_done(config):
			return false
	return true


func _reset_optional_state() -> void:
	for config in _all_optional_content():
		_set_optional_done(config, false)
		var content_id := str(config.get("id", ""))
		optional_near_state[content_id] = false


func _reset_optional_near_state() -> void:
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		optional_near_state[content_id] = false


func _update_optional_near_state_logs() -> void:
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		var near := _is_near_optional(config)
		if near and not optional_near_state.get(content_id, false):
			_log("靠近%s" % str(config.get("display_name", content_id)))
		optional_near_state[content_id] = near


func _update_optional_content_visuals() -> void:
	for config in _all_optional_content():
		var node: Node2D = config.get("node", null) as Node2D
		var label: Label = config.get("label", null) as Label
		if node == null or label == null:
			continue

		node.visible = true
		label.visible = true
		label.text = str(config.get("label_default", ""))
		if _is_optional_done(config):
			node.modulate.a = _to_float_or_default(config.get("done_alpha", 1.0), 1.0)
			label.text = str(config.get("label_done", ""))
		elif current_step == DemoStep.COMPLETE:
			node.modulate.a = _to_float_or_default(config.get("ready_alpha", 1.0), 1.0)
		else:
			node.modulate.a = _to_float_or_default(config.get("locked_alpha", 0.3), 0.3)

	_update_optional_progress_journal()


func _set_optional_content_alpha(alpha: float) -> void:
	for config in _all_optional_content():
		var node: Node2D = config.get("node", null) as Node2D
		if node != null:
			node.modulate.a = alpha


func _reset_optional_content_scale() -> void:
	for config in _all_optional_content():
		var node: Node2D = config.get("node", null) as Node2D
		if node != null:
			node.scale = Vector2.ONE


func _format_optional_display_names(separator: String) -> String:
	var formatted := ""
	var optional_content := _all_optional_content()
	for index in range(optional_content.size()):
		if index > 0:
			formatted += separator
		formatted += str(optional_content[index].get("display_name", optional_content[index].get("id", "")))
	return formatted


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

	status_label.text = "背包：%s\n图鉴 items=%s\n图鉴 creatures=%s" % [
		_format_inventory_status(item_count),
		_format_ids(discovered_items),
		_format_ids(discovered_creatures)
	]


func _format_inventory_status(main_item_count: int) -> String:
	var formatted := "%s x%d" % [ITEM_ID, main_item_count]
	for config in optional_collectibles:
		var content_id := str(config.get("id", ""))
		var item_count := 0
		if inventory_service != null:
			item_count = inventory_service.get_item_count(OWNER_ID, content_id)
		formatted += ", %s x%d" % [content_id, item_count]
	return formatted


func _update_objective_ui() -> void:
	match current_step:
		DemoStep.COLLECT_ZHUYU:
			objective_label.text = "当前目标：采集祝余叶"
		DemoStep.ACTIVATE_STONE:
			objective_label.text = "当前目标：前往山海石碑"
		DemoStep.OBSERVE_SHENSHENG:
			objective_label.text = "当前目标：观察狌狌"
		DemoStep.COMPLETE:
			if _is_optional_exploration_complete():
				objective_label.text = "当前目标：Demo 完成，可选探索完成"
			else:
				objective_label.text = "当前目标：Demo 完成，可选探索已解锁"


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
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("祝余叶", "按 E 采集", active_target)
		DemoStep.ACTIVATE_STONE:
			guidance_stone.modulate.a = 1.0
			guidance_stone.scale = Vector2(1.15, 1.15)
			shensheng_creature.modulate.a = 0.35
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("山海石碑", "按 E 激活", active_target)
		DemoStep.OBSERVE_SHENSHENG:
			guidance_stone.modulate.a = 0.55
			shensheng_creature.modulate.a = 1.0
			shensheng_creature.scale = Vector2(1.15, 1.15)
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("狌狌", "按 E 观察", active_target)
		DemoStep.COMPLETE:
			guidance_stone.modulate.a = 0.55
			shensheng_creature.modulate.a = 0.45
			_update_optional_content_visuals()
			if _is_optional_exploration_complete():
				target_hint_label.text = "目标提示：所有 Demo 内容已完成"
			else:
				target_hint_label.text = "目标提示：可选探索：%s" % _format_optional_display_names(" / ")


func _reset_guidance_visuals() -> void:
	zhuyu_pickup.scale = Vector2.ONE
	guidance_stone.scale = Vector2.ONE
	shensheng_creature.scale = Vector2.ONE
	_reset_optional_content_scale()


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


func _to_float_or_default(value: Variant, default_value: float) -> float:
	if value is int or value is float:
		return float(value)
	return default_value


func _log_ok(message: String) -> void:
	_log("[OK] %s" % message)


func _log_error(message: String) -> void:
	_log("[ERROR] %s" % message)


func _log(message: String) -> void:
	var line := "%s  %s" % [Time.get_time_string_from_system(), message]
	log_label.text += line + "\n"
