extends Node2D

const WorldGenerator := preload("res://scripts/world/world_generator.gd")
const WorldMapModel := preload("res://scripts/world/world_map_model.gd")
const SeededRng := preload("res://scripts/world/seeded_rng.gd")

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
const LIVE_LOG_UI_RECENT_LIMIT := 3
const OPTIONAL_PROGRESS_DETAIL_LINE_LIMIT := 10
const OPTIONAL_PROGRESS_COMPACT_LINE_LIMIT := 6
const JOURNAL_SHORTCUT_HINT_TEXT := "快捷键：J 隐藏/显示，V 简洁/详细"
const JOURNAL_SHORTCUT_HINT_FONT_SIZE := 13
const TITLE_RECT := Rect2(480, 16, 220, 24)
const INSTRUCTION_RECT := Rect2(420, 44, 520, 24)
const OBJECTIVE_RECT := Rect2(420, 76, 300, 24)
const TARGET_HINT_RECT := Rect2(720, 76, 340, 24)
const STATUS_RECT := Rect2(24, 104, 396, 68)
const SURVIVAL_HUD_RECT := Rect2(24, 16, 336, 80)
const NAVIGATION_HUD_RECT := Rect2(1080, 16, 336, 80)
const LIVE_LOG_RECT := Rect2(24, 650, 476, 136)
const PROMPT_RECT := Rect2(520, 750, 520, 36)
const DEMO_MENU_RECT := Rect2(1080, 16, 336, 208)
const JOURNAL_PANEL_RECT := Rect2(1080, 144, 336, 576)
const JOURNAL_TOGGLE_RECT := Rect2(1270, 104, 146, 32)
const COMPLETION_PANEL_RECT := Rect2(500, 140, 440, 500)
const KNOWLEDGE_CODEX_PANEL_RECT := Rect2(360, 160, 620, 460)
const KNOWLEDGE_CODEX_CONTENT_RECT := Rect2(20, 56, 580, 340)
const KNOWLEDGE_CODEX_TITLE_RECT := Rect2(20, 16, 580, 28)
const KNOWLEDGE_CODEX_HINT_RECT := Rect2(20, 410, 580, 28)
const JOURNAL_CONTENT_LEFT := 16.0
const JOURNAL_CONTENT_RIGHT := 320.0
const JOURNAL_TITLE_RIGHT := 196.0
const JOURNAL_VIEW_BUTTON_LEFT := 208.0
const JOURNAL_TITLE_TOP := 8.0
const JOURNAL_TITLE_BOTTOM := 36.0
const JOURNAL_HINT_TOP := 44.0
const JOURNAL_HINT_BOTTOM := 68.0
const JOURNAL_PROGRESS_TOP := 76.0
const JOURNAL_PROGRESS_BOTTOM := 260.0
const JOURNAL_HISTORY_TOP := 276.0
const JOURNAL_HISTORY_BOTTOM := 560.0
const DEMO_HUNGER_MAX := 100.0
const DEMO_HUNGER_DECAY_PER_SECOND := 2.0
const DEMO_HUNGER_WARNING_THRESHOLD := 70.0
const DEMO_HUNGER_CRITICAL_THRESHOLD := 35.0
const ZHUYU_SATIETY_DURATION := 15.0
const COOKED_ZHUYU_SATIETY_DURATION := 45.0
const ZHUYU_KNOWLEDGE_APPEARANCE := "appearance"
const ZHUYU_KNOWLEDGE_TYPE := "type"
const ZHUYU_KNOWLEDGE_EFFECT := "effect"
const ZHUYU_KNOWLEDGE_COOKING := "cooking"
const NAVIGATION_NEAR_ORIGIN_DISTANCE := 180.0
const NAVIGATION_LOST_PRESSURE_DISTANCE := 360.0
const MIGU_KNOWLEDGE_APPEARANCE := "appearance"
const MIGU_KNOWLEDGE_TYPE := "type"
const MIGU_KNOWLEDGE_EFFECT := "effect"
const DEFAULT_WORLD_MAP_PATH := "res://data/world/world_map.json"
const GENERATED_ZHUYU_TYPE := "zhuyu"
const GENERATED_MIGU_TYPE := "migu"
const GENERATED_SHENSHENG_TYPE := "shensheng"
const GENERATED_CONTENT_TYPES := [
	GENERATED_ZHUYU_TYPE,
	GENERATED_MIGU_TYPE,
	GENERATED_SHENSHENG_TYPE
]
const GENERATED_COLLECTIBLE_TYPES := [
	GENERATED_ZHUYU_TYPE,
	GENERATED_MIGU_TYPE
]
const DEMO_ZHUYU_PLACEMENT_SLOTS := [
	Vector2(430, 260),
	Vector2(520, 600),
	Vector2(760, 650),
	Vector2(930, 250),
	Vector2(1000, 610)
]
const DEMO_MIGU_PLACEMENT_SLOTS := [
	Vector2(720, 300),
	Vector2(1000, 360)
]
const DEMO_SHENSHENG_PLACEMENT_SLOTS := [
	Vector2(650, 260),
	Vector2(620, 620),
	Vector2(820, 160)
]
const GENERATED_PLACEMENT_SEED_SALTS := {
	GENERATED_ZHUYU_TYPE: 101,
	GENERATED_MIGU_TYPE: 211,
	GENERATED_SHENSHENG_TYPE: 307
}
const GENERATED_LABEL_OFFSETS := {
	GENERATED_ZHUYU_TYPE: Vector2(-30, 36),
	GENERATED_MIGU_TYPE: Vector2(-40, 36),
	GENERATED_SHENSHENG_TYPE: Vector2(-30, 36)
}

enum DemoStep {
	COLLECT_ZHUYU = 0,
	ACTIVATE_STONE = 1,
	OBSERVE_SHENSHENG = 2,
	COMPLETE = 3,
	EAT_ZHUYU = 4
}

@onready var world_root: Node2D = $WorldRoot
@onready var player: Polygon2D = %Player
@onready var player_sprite: AnimatedSprite2D = %PlayerSprite
@onready var player_animation_state_machine: DemoPlayerAnimationStateMachine = %PlayerAnimationStateMachine
@onready var zhuyu_pickup: Polygon2D = %ZhuyuPickup
@onready var zhuyu_label: Label = %ZhuyuLabel
@onready var campfire: Node2D = %Campfire
@onready var campfire_label: Label = %CampfireLabel
@onready var guidance_stone: Polygon2D = %GuidanceStone
@onready var guidance_stone_label: Label = $WorldRoot/GuidanceStoneLabel
@onready var shensheng_creature: Polygon2D = %ShenshengCreature
@onready var shensheng_label: Label = %ShenshengLabel
@onready var migu_branch: Node2D = %MiguBranch
@onready var migu_branch_label: Label = $WorldRoot/MiguBranchLabel
@onready var lushu_creature: Node2D = %LushuCreature
@onready var lushu_label: Label = $WorldRoot/LushuLabel
@onready var title_label: Label = %TitleLabel
@onready var instruction_label: Label = %InstructionLabel
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
var live_log_entries: Array[String] = []
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
var survival_status_label: Label
var navigation_status_label: Label
var knowledge_codex_panel: Panel
var knowledge_codex_title_label: Label
var knowledge_codex_content_label: Label
var knowledge_codex_hint_label: Label
var optional_progress_detail_view := true
var recent_optional_completion_name := ""
var interaction_history_panel_visible := true
var demo_hunger := DEMO_HUNGER_MAX
var demo_hunger_max := DEMO_HUNGER_MAX
var demo_hunger_decay_per_second := DEMO_HUNGER_DECAY_PER_SECOND
var zhuyu_satiety_remaining := 0.0
var zhuyu_consumed := false
var cooked_zhuyu_count := 0
var zhuyu_knowledge_state := {
	ZHUYU_KNOWLEDGE_APPEARANCE: false,
	ZHUYU_KNOWLEDGE_TYPE: false,
	ZHUYU_KNOWLEDGE_EFFECT: false,
	ZHUYU_KNOWLEDGE_COOKING: false
}
var hunger_warning_level := 0
var demo_origin_position := PLAYER_START_POSITION
var migu_equipped := false
var migu_knowledge_state := {
	MIGU_KNOWLEDGE_APPEARANCE: false,
	MIGU_KNOWLEDGE_TYPE: false,
	MIGU_KNOWLEDGE_EFFECT: false
}
var generation_seed := 0
var generated_content := {
	GENERATED_ZHUYU_TYPE: 0,
	GENERATED_MIGU_TYPE: 0,
	GENERATED_SHENSHENG_TYPE: 0
}
var generated_instance_nodes := {
	GENERATED_ZHUYU_TYPE: {},
	GENERATED_MIGU_TYPE: {},
	GENERATED_SHENSHENG_TYPE: {}
}
var generated_instance_labels := {
	GENERATED_ZHUYU_TYPE: {},
	GENERATED_MIGU_TYPE: {},
	GENERATED_SHENSHENG_TYPE: {}
}
var collected_instance_ids := {
	GENERATED_ZHUYU_TYPE: {},
	GENERATED_MIGU_TYPE: {}
}
var navigation_pressure_level := 0
var was_near_zhuyu := false
var was_near_stone := false
var was_near_shensheng := false
var was_interact_key_pressed := false
var was_menu_toggle_key_pressed := false
var was_journal_toggle_key_pressed := false
var was_progress_view_toggle_key_pressed := false
var was_codex_toggle_key_pressed := false


func _ready() -> void:
	if not _initialize_default_generated_world():
		_log_error("默认 world generation 加载失败，Demo 使用单实例安全回退。")
		_configure_generated_world_layout(0, {
			GENERATED_ZHUYU_TYPE: 1,
			GENERATED_MIGU_TYPE: 1,
			GENERATED_SHENSHENG_TYPE: 1
		})
	_init_optional_content_config()
	_configure_hud_layout()
	_configure_interaction_history_panel()
	_configure_survival_status_label()
	_configure_navigation_status_label()
	_configure_knowledge_codex_panel()
	_connect_button_signals()
	demo_menu_panel.visible = false
	completion_panel.visible = false
	prompt_label.visible = false
	_set_knowledge_codex_visible(false)
	_set_interaction_history_panel_visible(true)
	_apply_world_visual_state()
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
			"label_default": "陌生黑理发光之木",
			"label_done": "迷穀（已采集）",
			"history": "采集迷穀枝",
			"prompt_locked": "完成主流程后解锁迷穀枝",
			"prompt_ready": "按 E 采集迷穀",
			"prompt_done": "迷穀已采集",
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


func _initialize_default_generated_world() -> bool:
	var world_result := WorldMapModel.load_file(DEFAULT_WORLD_MAP_PATH)
	if not world_result.get("ok", false):
		_log_error("world_map.json 加载失败：%s" % str(world_result.get("errors", [])))
		return false

	var world_data: Variant = world_result.get("data", {})
	if not (world_data is Dictionary):
		return false
	var seed_value := _to_non_negative_int(world_data.get("default_seed", -1))
	if seed_value < 0:
		_log_error("world_map.json default_seed 无效。")
		return false

	var generator := WorldGenerator.new()
	var generation_result: Dictionary = generator.generate_from_files(seed_value)
	if generation_result.is_empty():
		_log_error("world generation 失败：%s" % generator.last_error)
		return false

	var content := _extract_generated_demo_content(generation_result)
	if content.is_empty():
		_log_error("world generation result 缺少 Demo 所需资源或异兽数量。")
		return false

	_clear_collected_instance_ids()
	_configure_generated_world_layout(seed_value, content)
	return true


func _extract_generated_demo_content(generation_result: Dictionary) -> Dictionary:
	var region_id: Variant = generation_result.get("starting_region_id")
	var mountain_id: Variant = generation_result.get("starting_mountain_id")
	var generated_regions: Variant = generation_result.get("generated_regions", {})
	if (
		not (region_id is String)
		or not (mountain_id is String)
		or not (generated_regions is Dictionary)
	):
		return {}

	var region_data: Variant = generated_regions.get(region_id, {})
	if not (region_data is Dictionary):
		return {}
	var mountains: Variant = region_data.get("mountains", {})
	if not (mountains is Dictionary):
		return {}
	var mountain_data: Variant = mountains.get(mountain_id, {})
	if not (mountain_data is Dictionary):
		return {}

	var resources: Variant = mountain_data.get("resources", [])
	var encounters: Variant = mountain_data.get("encounters", [])
	if not (resources is Array) or not (encounters is Array):
		return {}

	var zhuyu_count := _find_generated_entry_count(resources, GENERATED_ZHUYU_TYPE)
	var migu_count := _find_generated_entry_count(resources, GENERATED_MIGU_TYPE)
	var shensheng_count := _find_generated_entry_count(
		encounters,
		GENERATED_SHENSHENG_TYPE
	)
	if zhuyu_count < 0 or migu_count < 0 or shensheng_count < 0:
		return {}

	return {
		GENERATED_ZHUYU_TYPE: zhuyu_count,
		GENERATED_MIGU_TYPE: migu_count,
		GENERATED_SHENSHENG_TYPE: shensheng_count
	}


func _find_generated_entry_count(entries: Array, entry_id: String) -> int:
	for entry_value in entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		if entry.get("id", "") != entry_id:
			continue
		var count := _to_non_negative_int(entry.get("count", -1))
		return count
	return -1


func _configure_generated_world_layout(seed_value: int, content: Dictionary) -> void:
	generation_seed = seed_value
	var clamped_content := {}
	for content_type in GENERATED_CONTENT_TYPES:
		var requested_count := _to_non_negative_int(content.get(content_type, 0))
		if requested_count < 0:
			requested_count = 0
		var available_slots := _placement_slots_for_type(content_type).size()
		var clamped_count := mini(requested_count, available_slots)
		if requested_count > available_slots:
			var warning := (
				"minimal_playable_demo: generated %s count %d exceeds %d placement slots; clamped."
				% [content_type, requested_count, available_slots]
			)
			push_warning(warning)
			_log(warning)
		clamped_content[content_type] = clamped_count
	generated_content = clamped_content
	_rebuild_generated_instances()


func _rebuild_generated_instances() -> void:
	_clear_generated_extra_nodes()
	for content_type in GENERATED_CONTENT_TYPES:
		generated_instance_nodes[content_type] = {}
		generated_instance_labels[content_type] = {}
		_build_generated_instances_for_type(content_type)
	_apply_generated_placement_visuals()


func _clear_generated_extra_nodes() -> void:
	for content_type in GENERATED_CONTENT_TYPES:
		var primary_node := _primary_generated_node(content_type)
		var primary_label := _primary_generated_label(content_type)
		var nodes_value: Variant = generated_instance_nodes.get(content_type, {})
		if nodes_value is Dictionary:
			for node_value in nodes_value.values():
				var node := node_value as Node
				if (
					node != null
					and node != primary_node
					and is_instance_valid(node)
				):
					node.free()
		var labels_value: Variant = generated_instance_labels.get(content_type, {})
		if labels_value is Dictionary:
			for label_value in labels_value.values():
				var label := label_value as Node
				if (
					label != null
					and label != primary_label
					and is_instance_valid(label)
				):
					label.free()


func _build_generated_instances_for_type(content_type: String) -> void:
	var primary_node := _primary_generated_node(content_type)
	var primary_label := _primary_generated_label(content_type)
	if primary_node == null or primary_label == null:
		return

	primary_node.visible = false
	primary_label.visible = false
	primary_node.scale = Vector2.ONE
	primary_node.modulate = Color.WHITE

	var count := int(generated_content.get(content_type, 0))
	var ordered_slots := _ordered_placement_slots(content_type)
	var label_offset: Vector2 = GENERATED_LABEL_OFFSETS.get(content_type, Vector2.ZERO)
	for index in range(count):
		var node: Node2D
		var label: Label
		if index == 0:
			node = primary_node
			label = primary_label
		else:
			node = primary_node.duplicate() as Node2D
			label = primary_label.duplicate() as Label
			if node == null or label == null:
				continue
			node.name = "%sGenerated%d" % [_generated_node_name_prefix(content_type), index]
			label.name = "%sGenerated%d" % [_generated_label_name_prefix(content_type), index]
			node.unique_name_in_owner = false
			label.unique_name_in_owner = false
			world_root.add_child(node)
			world_root.add_child(label)

		var instance_id := _generated_instance_id(content_type, index)
		node.position = ordered_slots[index]
		node.scale = Vector2.ONE
		node.modulate = Color.WHITE
		node.visible = true
		node.set_meta("generated_instance_id", instance_id)
		label.position = ordered_slots[index] + label_offset
		label.visible = true
		label.set_meta("generated_instance_id", instance_id)
		generated_instance_nodes[content_type][instance_id] = node
		generated_instance_labels[content_type][instance_id] = label


func _ordered_placement_slots(content_type: String) -> Array:
	var slots := _placement_slots_for_type(content_type).duplicate()
	if slots.size() <= 1:
		return slots
	var salt := int(GENERATED_PLACEMENT_SEED_SALTS.get(content_type, 0))
	var rng := SeededRng.new(generation_seed + salt)
	for index in range(slots.size() - 1, 0, -1):
		var swap_index := rng.next_int(0, index)
		var slot_value: Variant = slots[index]
		slots[index] = slots[swap_index]
		slots[swap_index] = slot_value
	return slots


func _placement_slots_for_type(content_type: String) -> Array:
	match content_type:
		GENERATED_ZHUYU_TYPE:
			return DEMO_ZHUYU_PLACEMENT_SLOTS
		GENERATED_MIGU_TYPE:
			return DEMO_MIGU_PLACEMENT_SLOTS
		GENERATED_SHENSHENG_TYPE:
			return DEMO_SHENSHENG_PLACEMENT_SLOTS
	return []


func _primary_generated_node(content_type: String) -> Node2D:
	match content_type:
		GENERATED_ZHUYU_TYPE:
			return zhuyu_pickup
		GENERATED_MIGU_TYPE:
			return migu_branch
		GENERATED_SHENSHENG_TYPE:
			return shensheng_creature
	return null


func _primary_generated_label(content_type: String) -> Label:
	match content_type:
		GENERATED_ZHUYU_TYPE:
			return zhuyu_label
		GENERATED_MIGU_TYPE:
			return migu_branch_label
		GENERATED_SHENSHENG_TYPE:
			return shensheng_label
	return null


func _generated_node_name_prefix(content_type: String) -> String:
	match content_type:
		GENERATED_ZHUYU_TYPE:
			return "ZhuyuPickup"
		GENERATED_MIGU_TYPE:
			return "MiguBranch"
		GENERATED_SHENSHENG_TYPE:
			return "ShenshengCreature"
	return "GeneratedContent"


func _generated_label_name_prefix(content_type: String) -> String:
	match content_type:
		GENERATED_ZHUYU_TYPE:
			return "ZhuyuLabel"
		GENERATED_MIGU_TYPE:
			return "MiguBranchLabel"
		GENERATED_SHENSHENG_TYPE:
			return "ShenshengLabel"
	return "GeneratedContentLabel"


func _generated_instance_id(content_type: String, index: int) -> String:
	return "%s_%d" % [content_type, index]


func _generated_interactable_id(content_type: String, index: int) -> String:
	var base_id := ""
	match content_type:
		GENERATED_ZHUYU_TYPE:
			base_id = ZHUYU_INTERACTABLE_ID
		GENERATED_MIGU_TYPE:
			base_id = MIGU_BRANCH_INTERACTABLE_ID
		GENERATED_SHENSHENG_TYPE:
			base_id = SHENSHENG_INTERACTABLE_ID
	if index == 0:
		return base_id
	return "%s_%d" % [base_id, index]


func _generated_instance_id_from_interactable(
	content_type: String,
	interactable_id: String
) -> String:
	var slot_count := _placement_slots_for_type(content_type).size()
	for index in range(slot_count):
		if _generated_interactable_id(content_type, index) == interactable_id:
			return _generated_instance_id(content_type, index)
	return ""


func _clear_collected_instance_ids() -> void:
	for content_type in GENERATED_COLLECTIBLE_TYPES:
		collected_instance_ids[content_type] = {}


func _is_generated_instance_collected(content_type: String, instance_id: String) -> bool:
	var collected_value: Variant = collected_instance_ids.get(content_type, {})
	return collected_value is Dictionary and collected_value.get(instance_id, false) == true


func _set_generated_instance_collected(
	content_type: String,
	instance_id: String,
	is_collected: bool
) -> void:
	var collected_value: Variant = collected_instance_ids.get(content_type, {})
	if not (collected_value is Dictionary):
		collected_value = {}
	var collected_state: Dictionary = collected_value
	if is_collected:
		collected_state[instance_id] = true
	else:
		collected_state.erase(instance_id)
	collected_instance_ids[content_type] = collected_state


func _nearest_generated_instance_id(
	content_type: String,
	skip_collected := true
) -> String:
	var nearest_id := ""
	var nearest_distance := INF
	var count := int(generated_content.get(content_type, 0))
	for index in range(count):
		var instance_id := _generated_instance_id(content_type, index)
		if (
			skip_collected
			and content_type in GENERATED_COLLECTIBLE_TYPES
			and _is_generated_instance_collected(content_type, instance_id)
		):
			continue
		var nodes_value: Variant = generated_instance_nodes.get(content_type, {})
		if not (nodes_value is Dictionary):
			continue
		var node := nodes_value.get(instance_id, null) as Node2D
		if node == null or not node.visible:
			continue
		var distance := player.global_position.distance_to(node.global_position)
		if distance <= interaction_distance and distance < nearest_distance:
			nearest_id = instance_id
			nearest_distance = distance
	return nearest_id


func _generated_instance_node(content_type: String, instance_id: String) -> Node2D:
	var nodes_value: Variant = generated_instance_nodes.get(content_type, {})
	if not (nodes_value is Dictionary):
		return null
	return nodes_value.get(instance_id, null) as Node2D


func _generated_instance_index(instance_id: String) -> int:
	var separator_index := instance_id.rfind("_")
	if separator_index < 0:
		return -1
	var index_text := instance_id.substr(separator_index + 1)
	if not index_text.is_valid_int():
		return -1
	var index := index_text.to_int()
	return index if index >= 0 else -1


func _apply_generated_placement_visuals() -> void:
	_update_generated_zhuyu_visuals()
	_update_generated_migu_visuals()
	_update_generated_shensheng_visuals()


func _update_generated_zhuyu_visuals() -> void:
	var count := int(generated_content.get(GENERATED_ZHUYU_TYPE, 0))
	for index in range(count):
		var instance_id := _generated_instance_id(GENERATED_ZHUYU_TYPE, index)
		var node := _generated_instance_node(GENERATED_ZHUYU_TYPE, instance_id)
		var label := generated_instance_labels[GENERATED_ZHUYU_TYPE].get(
			instance_id,
			null
		) as Label
		if node == null or label == null:
			continue
		var collected := _is_generated_instance_collected(
			GENERATED_ZHUYU_TYPE,
			instance_id
		)
		node.visible = not collected
		label.visible = not collected
		node.modulate.a = 1.0
		label.text = (
			"祝余"
			if _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE)
			else "陌生青华草"
		)


func _update_generated_migu_visuals() -> void:
	var count := int(generated_content.get(GENERATED_MIGU_TYPE, 0))
	for index in range(count):
		var instance_id := _generated_instance_id(GENERATED_MIGU_TYPE, index)
		var node := _generated_instance_node(GENERATED_MIGU_TYPE, instance_id)
		var label := generated_instance_labels[GENERATED_MIGU_TYPE].get(
			instance_id,
			null
		) as Label
		if node == null or label == null:
			continue
		var collected := _is_generated_instance_collected(
			GENERATED_MIGU_TYPE,
			instance_id
		)
		node.visible = not collected
		label.visible = not collected
		if collected:
			continue
		label.text = (
			"迷穀"
			if _has_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE)
			else "陌生黑理发光之木"
		)
		node.modulate.a = 1.0 if current_step == DemoStep.COMPLETE else 0.3


func _update_generated_shensheng_visuals() -> void:
	var count := int(generated_content.get(GENERATED_SHENSHENG_TYPE, 0))
	for index in range(count):
		var instance_id := _generated_instance_id(GENERATED_SHENSHENG_TYPE, index)
		var node := _generated_instance_node(GENERATED_SHENSHENG_TYPE, instance_id)
		var label := generated_instance_labels[GENERATED_SHENSHENG_TYPE].get(
			instance_id,
			null
		) as Label
		if node == null or label == null:
			continue
		node.visible = true
		label.visible = true
		node.modulate.a = 0.45 if shensheng_discovered else 1.0
		label.text = "狌狌（已发现）" if shensheng_discovered else "狌狌"


func _set_generated_type_alpha(content_type: String, alpha: float) -> void:
	var nodes_value: Variant = generated_instance_nodes.get(content_type, {})
	if not (nodes_value is Dictionary):
		return
	for node_value in nodes_value.values():
		var node := node_value as Node2D
		if node != null and node.visible:
			node.modulate.a = alpha


func _set_generated_type_scale(content_type: String, scale_value: Vector2) -> void:
	var nodes_value: Variant = generated_instance_nodes.get(content_type, {})
	if not (nodes_value is Dictionary):
		return
	for node_value in nodes_value.values():
		var node := node_value as Node2D
		if node != null:
			node.scale = scale_value


func _process(delta: float) -> void:
	_handle_menu_toggle_input()
	_handle_codex_shortcut_input()

	if not initialized:
		_set_player_animation_movement(Vector2.ZERO)
		_sync_journal_shortcut_key_state()
		return

	if _is_ui_blocking_gameplay():
		prompt_label.visible = false
		was_interact_key_pressed = Input.is_key_pressed(KEY_E)
		_set_player_animation_movement(Vector2.ZERO)
		_sync_journal_shortcut_key_state()
		_update_objective_guidance()
		return

	_update_hunger(delta)
	_handle_journal_shortcut_input()
	_move_player(delta)
	_update_navigation_state()
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


func _configure_hud_layout() -> void:
	_apply_control_rect(title_label, TITLE_RECT)
	_apply_control_rect(instruction_label, INSTRUCTION_RECT)
	_apply_control_rect(objective_label, OBJECTIVE_RECT)
	_apply_control_rect(target_hint_label, TARGET_HINT_RECT)
	_apply_control_rect(status_label, STATUS_RECT)
	_apply_control_rect(prompt_label, PROMPT_RECT)
	_apply_control_rect(log_label, LIVE_LOG_RECT)
	_apply_control_rect(demo_menu_panel, DEMO_MENU_RECT)
	_apply_control_rect(completion_panel, COMPLETION_PANEL_RECT)

	instruction_label.text = "WASD / 方向键移动，E 交互，K 图鉴"
	status_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.clip_text = true
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.scroll_active = false
	log_label.scroll_following = false
	log_label.fit_content = false
	log_label.clip_contents = true
	_refresh_live_log_ui()


func _apply_control_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


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


func _configure_survival_status_label() -> void:
	if survival_status_label == null:
		survival_status_label = Label.new()
		survival_status_label.name = "SurvivalStatusLabel"
		survival_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$CanvasLayer.add_child(survival_status_label)
	_apply_control_rect(survival_status_label, SURVIVAL_HUD_RECT)
	_refresh_survival_status()


func _configure_navigation_status_label() -> void:
	if navigation_status_label == null:
		navigation_status_label = Label.new()
		navigation_status_label.name = "NavigationStatusLabel"
		navigation_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$CanvasLayer.add_child(navigation_status_label)
	_apply_control_rect(navigation_status_label, NAVIGATION_HUD_RECT)
	_refresh_navigation_status()


func _configure_knowledge_codex_panel() -> void:
	if knowledge_codex_panel == null:
		knowledge_codex_panel = Panel.new()
		knowledge_codex_panel.name = "KnowledgeCodexPanel"
		$CanvasLayer.add_child(knowledge_codex_panel)
	_apply_control_rect(knowledge_codex_panel, KNOWLEDGE_CODEX_PANEL_RECT)

	if knowledge_codex_title_label == null:
		knowledge_codex_title_label = Label.new()
		knowledge_codex_title_label.name = "KnowledgeCodexTitleLabel"
		knowledge_codex_panel.add_child(knowledge_codex_title_label)
	knowledge_codex_title_label.text = "图鉴 / Knowledge Codex"
	knowledge_codex_title_label.add_theme_font_size_override("font_size", 20)
	_apply_control_rect(knowledge_codex_title_label, KNOWLEDGE_CODEX_TITLE_RECT)

	if knowledge_codex_content_label == null:
		knowledge_codex_content_label = Label.new()
		knowledge_codex_content_label.name = "KnowledgeCodexContentLabel"
		knowledge_codex_panel.add_child(knowledge_codex_content_label)
	knowledge_codex_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	knowledge_codex_content_label.clip_text = true
	knowledge_codex_content_label.add_theme_font_size_override("font_size", 16)
	_apply_control_rect(knowledge_codex_content_label, KNOWLEDGE_CODEX_CONTENT_RECT)

	if knowledge_codex_hint_label == null:
		knowledge_codex_hint_label = Label.new()
		knowledge_codex_hint_label.name = "KnowledgeCodexHintLabel"
		knowledge_codex_panel.add_child(knowledge_codex_hint_label)
	knowledge_codex_hint_label.text = "K 打开/关闭图鉴"
	knowledge_codex_hint_label.add_theme_font_size_override("font_size", 13)
	knowledge_codex_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_control_rect(knowledge_codex_hint_label, KNOWLEDGE_CODEX_HINT_RECT)
	_refresh_knowledge_codex()


func _configure_interaction_history_panel_bounds() -> void:
	_apply_control_rect(interaction_history_panel, JOURNAL_PANEL_RECT)


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
		interaction_history_panel.add_child(optional_progress_shortcut_hint_label)
	optional_progress_shortcut_hint_label.text = JOURNAL_SHORTCUT_HINT_TEXT
	optional_progress_shortcut_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	optional_progress_shortcut_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	optional_progress_shortcut_hint_label.add_theme_font_size_override("font_size", JOURNAL_SHORTCUT_HINT_FONT_SIZE)
	optional_progress_shortcut_hint_label.clip_text = true
	optional_progress_shortcut_hint_label.offset_left = JOURNAL_CONTENT_LEFT
	optional_progress_shortcut_hint_label.offset_top = JOURNAL_HINT_TOP
	optional_progress_shortcut_hint_label.offset_right = JOURNAL_CONTENT_RIGHT
	optional_progress_shortcut_hint_label.offset_bottom = JOURNAL_HINT_BOTTOM
	optional_progress_shortcut_hint_label.visible = true


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
	_apply_control_rect(interaction_history_toggle_button, JOURNAL_TOGGLE_RECT)
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


func _handle_codex_shortcut_input() -> void:
	var codex_toggle_key_pressed := Input.is_key_pressed(KEY_K)
	if (
		codex_toggle_key_pressed
		and not was_codex_toggle_key_pressed
		and _can_toggle_knowledge_codex()
	):
		_on_knowledge_codex_toggle_pressed()
	was_codex_toggle_key_pressed = codex_toggle_key_pressed


func _can_toggle_knowledge_codex() -> bool:
	return (
		initialized
		and not demo_menu_panel.visible
		and not completion_panel.visible
	)


func _on_knowledge_codex_toggle_pressed() -> void:
	var should_show := knowledge_codex_panel != null and not knowledge_codex_panel.visible
	_set_knowledge_codex_visible(should_show)


func _set_knowledge_codex_visible(is_visible: bool) -> void:
	if knowledge_codex_panel == null:
		return
	knowledge_codex_panel.visible = is_visible
	if is_visible:
		_refresh_knowledge_codex()
		prompt_label.visible = false


func _refresh_knowledge_codex() -> void:
	if knowledge_codex_content_label == null:
		return
	knowledge_codex_content_label.text = (
		"祝余\n"
		+ "- 外观：%s\n" % _format_codex_slot(
			_has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE),
			"其状如韭而青华"
		)
		+ "- 类型：%s\n" % _format_codex_slot(
			_has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE),
			"草"
		)
		+ "- 效果：%s\n" % _format_codex_slot(
			_has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT),
			"食之不饥"
		)
		+ "- 烹饪：%s\n\n" % _format_codex_slot(
			_has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_COOKING),
			"熟祝余：食之不饥更久"
		)
		+ "迷穀\n"
		+ "- 外观：%s\n" % _format_codex_slot(
			_has_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE),
			"其状如榖而黑理，其华自照"
		)
		+ "- 类型：%s\n" % _format_codex_slot(
			_has_migu_knowledge(MIGU_KNOWLEDGE_TYPE),
			"木"
		)
		+ "- 效果：%s" % _format_codex_slot(
			_has_migu_knowledge(MIGU_KNOWLEDGE_EFFECT),
			"佩之不迷"
		)
	)


func _format_codex_slot(is_unlocked: bool, unlocked_text: String) -> String:
	if is_unlocked:
		return unlocked_text
	return "???"


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
	if not _register_generated_zhuyu_interactables():
		return false

	var shensheng_registered := interaction_service.register_interactable(SHENSHENG_INTERACTABLE_ID, {
		"type": "observe",
		"metadata": {
			"creature_id": CREATURE_ID,
			"instance_id": _generated_instance_id(GENERATED_SHENSHENG_TYPE, 0)
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


func _register_generated_zhuyu_interactables() -> bool:
	for index in range(DEMO_ZHUYU_PLACEMENT_SLOTS.size()):
		var interactable_id := _generated_interactable_id(
			GENERATED_ZHUYU_TYPE,
			index
		)
		var registered := interaction_service.register_interactable(interactable_id, {
			"type": "pickup",
			"metadata": {
				"item_id": ITEM_ID,
				"count": 1,
				"instance_id": _generated_instance_id(GENERATED_ZHUYU_TYPE, index)
			},
			"callback_target": self,
			"callback_method": "_on_zhuyu_interacted"
		})
		if not registered:
			_log_error("InteractionService 注册失败：%s" % interactable_id)
			return false
	return true


func _register_optional_interactables() -> bool:
	if not _register_generated_migu_interactables():
		return false

	for config in optional_collectibles:
		if str(config.get("id", "")) == MIGU_BRANCH_ITEM_ID:
			continue
		if not _register_optional_interactable(config, "_on_optional_collectible_interacted"):
			return false

	for config in optional_creatures:
		if not _register_optional_interactable(config, "_on_optional_creature_interacted"):
			return false

	return true


func _register_generated_migu_interactables() -> bool:
	for index in range(DEMO_MIGU_PLACEMENT_SLOTS.size()):
		var interactable_id := _generated_interactable_id(
			GENERATED_MIGU_TYPE,
			index
		)
		var registered := interaction_service.register_interactable(interactable_id, {
			"type": "pickup",
			"metadata": {
				"item_id": MIGU_BRANCH_ITEM_ID,
				"count": 1,
				"instance_id": _generated_instance_id(GENERATED_MIGU_TYPE, index)
			},
			"callback_target": self,
			"callback_method": "_on_optional_collectible_interacted"
		})
		if not registered:
			_log_error("InteractionService 注册失败：%s" % interactable_id)
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
	return (
		demo_menu_panel.visible
		or completion_panel.visible
		or (knowledge_codex_panel != null and knowledge_codex_panel.visible)
	)


func _open_demo_menu() -> void:
	_set_knowledge_codex_visible(false)
	demo_menu_panel.visible = true
	menu_open = true
	prompt_label.visible = false
	if survival_status_label != null:
		survival_status_label.visible = false
	if navigation_status_label != null:
		navigation_status_label.visible = false


func _close_demo_menu() -> void:
	demo_menu_panel.visible = false
	menu_open = false
	if survival_status_label != null:
		survival_status_label.visible = true
	if navigation_status_label != null:
		navigation_status_label.visible = true


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

	var movement := move_direction.normalized()
	if movement.length_squared() > 0.0:
		player.position += movement * player_speed * delta
	_set_player_animation_movement(movement)


func _set_player_animation_movement(movement: Vector2) -> void:
	if player_animation_state_machine != null:
		player_animation_state_machine.set_movement_vector(movement)


func _update_hunger(delta: float) -> void:
	if delta <= 0.0:
		return

	var decay_time := delta
	if zhuyu_satiety_remaining > 0.0:
		var protected_time := minf(delta, zhuyu_satiety_remaining)
		zhuyu_satiety_remaining = maxf(0.0, zhuyu_satiety_remaining - protected_time)
		decay_time -= protected_time
		if zhuyu_satiety_remaining <= 0.0:
			_log("祝余效力消退，饥饿会再次增长。")

	if decay_time > 0.0:
		demo_hunger = clampf(
			demo_hunger - demo_hunger_decay_per_second * decay_time,
			0.0,
			demo_hunger_max
		)
		_update_hunger_pressure_feedback()

	_refresh_survival_status()


func _update_hunger_pressure_feedback() -> void:
	var next_warning_level := _get_hunger_warning_level()

	if next_warning_level > hunger_warning_level:
		if next_warning_level >= 2:
			_log("饥饿加深，应该寻找可食之物。")
		else:
			_log("你开始感到饥饿。")
	hunger_warning_level = next_warning_level


func _get_hunger_warning_level() -> int:
	if demo_hunger <= DEMO_HUNGER_CRITICAL_THRESHOLD:
		return 2
	if demo_hunger <= DEMO_HUNGER_WARNING_THRESHOLD:
		return 1
	return 0


func _update_navigation_state() -> void:
	var next_pressure_level := _get_navigation_pressure_level()
	if not migu_equipped and next_pressure_level > navigation_pressure_level:
		if next_pressure_level >= 2:
			_log("你离起点越来越远，方向感开始模糊。")
		else:
			_log("你已远离起点，方向感开始不稳。")
	navigation_pressure_level = next_pressure_level
	_refresh_navigation_status()


func _get_navigation_pressure_level() -> int:
	var distance_to_origin := player.global_position.distance_to(demo_origin_position)
	if distance_to_origin > NAVIGATION_LOST_PRESSURE_DISTANCE:
		return 2
	if distance_to_origin > NAVIGATION_NEAR_ORIGIN_DISTANCE:
		return 1
	return 0


func _refresh_navigation_status() -> void:
	if navigation_status_label == null:
		return

	var guidance_text := "方向感：稳定"
	if migu_equipped:
		guidance_text = _format_migu_origin_guidance()
	else:
		match _get_navigation_pressure_level():
			1:
				guidance_text = "方向感：不稳"
			2:
				guidance_text = "方向感：模糊"

	var equipped_text := "未佩戴"
	if migu_equipped:
		equipped_text = "已佩戴"
	navigation_status_label.text = "%s\n迷穀：%s\n迷穀知识：%s" % [
		guidance_text,
		equipped_text,
		_format_migu_knowledge_status()
	]


func _format_migu_origin_guidance() -> String:
	var origin_vector := demo_origin_position - player.global_position
	var distance_to_origin := origin_vector.length()
	if distance_to_origin <= NAVIGATION_NEAR_ORIGIN_DISTANCE:
		return "迷穀归向：已接近起点"
	return "迷穀归向：%s · %d" % [
		_format_eight_direction(origin_vector),
		int(round(distance_to_origin))
	]


func _format_eight_direction(direction: Vector2) -> String:
	if direction.length_squared() <= 0.0001:
		return "原地"
	var directions: Array[String] = [
		"东",
		"东南",
		"南",
		"西南",
		"西",
		"西北",
		"北",
		"东北"
	]
	var angle_degrees := wrapf(rad_to_deg(direction.angle()), 0.0, 360.0)
	var direction_index := int(round(angle_degrees / 45.0)) % directions.size()
	return directions[direction_index]


func _format_migu_knowledge_status() -> String:
	var unlocked: Array[String] = []
	if _has_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE):
		unlocked.append("外观")
	if _has_migu_knowledge(MIGU_KNOWLEDGE_TYPE):
		unlocked.append("类型")
	if _has_migu_knowledge(MIGU_KNOWLEDGE_EFFECT):
		unlocked.append("佩之不迷")
	if unlocked.is_empty():
		return "未知"
	return "、".join(unlocked)


func _update_prompt() -> void:
	var near_zhuyu := _is_near_zhuyu()
	var near_campfire := _is_near_campfire()
	var near_stone := _is_near_stone()
	var near_shensheng := _is_near_shensheng()
	var nearest_optional := _nearest_optional_config()
	var near_optional := not nearest_optional.is_empty()
	if near_zhuyu:
		_discover_zhuyu_appearance_and_type()
	if (
		current_step == DemoStep.COMPLETE
		and near_optional
		and str(nearest_optional.get("id", "")) == MIGU_BRANCH_ITEM_ID
		and not _is_optional_done(nearest_optional)
	):
		_discover_migu_appearance_and_type()

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if near_zhuyu:
				_show_prompt(_format_zhuyu_collect_prompt())
			elif near_campfire:
				_show_prompt("篝火：需要祝余")
			elif near_stone:
				_show_prompt("先寻找并采集祝余")
			elif near_shensheng:
				_show_prompt("先完成前置目标")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.EAT_ZHUYU:
			if near_zhuyu:
				_show_prompt(_format_zhuyu_collect_prompt())
			elif cooked_zhuyu_count > 0:
				_show_prompt("按 E 食用熟祝余")
			elif near_campfire and _get_raw_zhuyu_count() > 0:
				_show_prompt("按 E 烹饪祝余")
			elif near_campfire:
				_show_prompt("篝火：需要祝余")
			else:
				_show_prompt("按 E 食用生祝余（靠近篝火可烹饪）")
		DemoStep.ACTIVATE_STONE:
			if near_zhuyu:
				_show_prompt(_format_zhuyu_collect_prompt())
			elif near_stone:
				_show_prompt("按 E 激活山海石碑")
			elif near_campfire:
				_show_prompt("篝火：需要祝余")
			elif near_shensheng:
				_show_prompt("先激活山海石碑")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.OBSERVE_SHENSHENG:
			if near_zhuyu:
				_show_prompt(_format_zhuyu_collect_prompt())
			elif near_shensheng:
				_show_prompt("按 E 观察狌狌")
			elif near_campfire:
				_show_prompt("篝火：需要祝余")
			elif near_stone:
				_show_prompt("山海石碑已激活")
			elif near_optional:
				_show_prompt(str(nearest_optional.get("prompt_locked", "")))
			else:
				prompt_label.visible = false
		DemoStep.COMPLETE:
			if near_zhuyu:
				_show_prompt(_format_zhuyu_collect_prompt())
			elif near_optional:
				if str(nearest_optional.get("id", "")) == MIGU_BRANCH_ITEM_ID:
					_show_prompt(_format_migu_prompt(nearest_optional))
				elif _is_optional_done(nearest_optional):
					_show_prompt(str(nearest_optional.get("prompt_done", "")))
				else:
					_show_prompt(str(nearest_optional.get("prompt_ready", "")))
			elif near_campfire:
				_show_prompt("篝火：需要祝余")
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
	var nearest_zhuyu_instance_id := _nearest_generated_instance_id(
		GENERATED_ZHUYU_TYPE
	)
	var near_campfire := _is_near_campfire()
	var near_stone := _is_near_stone()
	var near_shensheng := _is_near_shensheng()
	var nearest_optional := _nearest_optional_config()
	var near_optional := not nearest_optional.is_empty()

	if current_step == DemoStep.EAT_ZHUYU:
		if near_zhuyu:
			_interact_with_generated_instance(
				GENERATED_ZHUYU_TYPE,
				nearest_zhuyu_instance_id
			)
		elif cooked_zhuyu_count > 0:
			_eat_cooked_zhuyu()
		elif near_campfire and _get_raw_zhuyu_count() > 0:
			_cook_zhuyu()
		elif near_campfire:
			_log("篝火还缺少祝余。")
		else:
			_eat_zhuyu()
		return

	if current_step == DemoStep.COMPLETE:
		if near_zhuyu:
			_interact_with_generated_instance(
				GENERATED_ZHUYU_TYPE,
				nearest_zhuyu_instance_id
			)
			return
		if near_optional:
			var interactable_id := str(nearest_optional.get("interactable_id", ""))
			if str(nearest_optional.get("id", "")) == MIGU_BRANCH_ITEM_ID:
				var migu_instance_id := _nearest_generated_instance_id(
					GENERATED_MIGU_TYPE
				)
				var migu_index := _generated_instance_index(migu_instance_id)
				interactable_id = _generated_interactable_id(
					GENERATED_MIGU_TYPE,
					migu_index
				)
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

	if near_campfire:
		_log("篝火：需要祝余。")
		return

	if near_zhuyu and current_step != DemoStep.COLLECT_ZHUYU:
		_interact_with_generated_instance(
			GENERATED_ZHUYU_TYPE,
			nearest_zhuyu_instance_id
		)
		return

	if not near_zhuyu and not near_stone and not near_shensheng:
		_log("附近没有可交互对象。")
		return

	match current_step:
		DemoStep.COLLECT_ZHUYU:
			if near_zhuyu:
				_interact_with_generated_instance(
					GENERATED_ZHUYU_TYPE,
					nearest_zhuyu_instance_id
				)
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


func _interact_with_generated_instance(
	content_type: String,
	instance_id: String
) -> bool:
	var index := _generated_instance_index(instance_id)
	if index < 0:
		_log_error("找不到可交互的 generated %s instance。" % content_type)
		return false
	var interactable_id := _generated_interactable_id(content_type, index)
	var interacted := interaction_service.interact(OWNER_ID, interactable_id)
	if not interacted:
		_log_error("InteractionService 交互失败：%s" % interactable_id)
	return interacted


func _on_zhuyu_interacted(actor_id: String, interactable_id: String, metadata: Dictionary) -> bool:
	if actor_id.is_empty():
		_log_error("采集失败：actor_id 为空。")
		return false
	var mapped_instance_id := _generated_instance_id_from_interactable(
		GENERATED_ZHUYU_TYPE,
		interactable_id
	)
	if mapped_instance_id.is_empty():
		_log_error("采集失败：interactable_id 不匹配。")
		return false
	var instance_id := str(metadata.get("instance_id", mapped_instance_id))
	if (
		instance_id != mapped_instance_id
		or _generated_instance_node(GENERATED_ZHUYU_TYPE, instance_id) == null
	):
		_log_error("采集失败：metadata.instance_id 无效。")
		return false
	if _is_generated_instance_collected(GENERATED_ZHUYU_TYPE, instance_id):
		_log("这株祝余已经采集。")
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

	_discover_zhuyu_appearance_and_type()
	var was_initial_collection := current_step == DemoStep.COLLECT_ZHUYU
	_set_generated_instance_collected(GENERATED_ZHUYU_TYPE, instance_id, true)
	zhuyu_collected = true
	_update_generated_zhuyu_visuals()
	prompt_label.visible = false
	if was_initial_collection:
		current_step = DemoStep.EAT_ZHUYU
		_log_ok("你采集了祝余。")
		_log("祝余已采集，可食用以缓解饥饿。")
		_append_history_event("采集祝余叶")
	else:
		_log_ok("你又采集了一株祝余。")
		_append_history_event("采集祝余叶（%s）" % instance_id)
	_refresh_status()
	_refresh_survival_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _eat_zhuyu() -> bool:
	if current_step != DemoStep.EAT_ZHUYU or zhuyu_consumed:
		_log("祝余已经食用，无法重复食用。")
		return false
	if _get_raw_zhuyu_count() <= 0:
		_log_error("食用祝余失败：背包中没有祝余。")
		return false
	if not inventory_service.remove_item(OWNER_ID, ITEM_ID, 1):
		_log_error("食用祝余失败：无法移除背包物品。")
		return false

	zhuyu_consumed = true
	demo_hunger = demo_hunger_max
	zhuyu_satiety_remaining = ZHUYU_SATIETY_DURATION
	hunger_warning_level = 0
	current_step = DemoStep.ACTIVATE_STONE
	_log_ok("你食用了祝余，饥饿感暂时消退。")
	_unlock_zhuyu_knowledge(
		ZHUYU_KNOWLEDGE_EFFECT,
		"图鉴更新：祝余 · 效果：食之不饥"
	)
	_log("祝余效力发动：食之不饥")
	_append_history_event("食用祝余")
	prompt_label.visible = false
	_refresh_status()
	_refresh_survival_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _cook_zhuyu() -> bool:
	if current_step != DemoStep.EAT_ZHUYU or zhuyu_consumed:
		_log("当前没有可烹饪的祝余。")
		return false
	if not _is_near_campfire():
		_log("需要靠近篝火才能烹饪祝余。")
		return false
	if cooked_zhuyu_count > 0:
		_log("熟祝余已经备好，无需重复烹饪。")
		return false
	if _get_raw_zhuyu_count() <= 0:
		_log_error("烹饪祝余失败：背包中没有生祝余。")
		return false
	if not inventory_service.remove_item(OWNER_ID, ITEM_ID, 1):
		_log_error("烹饪祝余失败：无法移除生祝余。")
		return false

	cooked_zhuyu_count += 1
	_log_ok("你在篝火旁烹成了熟祝余。")
	_unlock_zhuyu_knowledge(
		ZHUYU_KNOWLEDGE_COOKING,
		"图鉴更新：祝余 · 烹饪"
	)
	_append_history_event("烹饪熟祝余")
	prompt_label.visible = false
	_refresh_status()
	_refresh_survival_status()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _eat_cooked_zhuyu() -> bool:
	if current_step != DemoStep.EAT_ZHUYU or zhuyu_consumed:
		_log("熟祝余已经食用，无法重复食用。")
		return false
	if cooked_zhuyu_count <= 0:
		_log_error("食用熟祝余失败：没有熟祝余。")
		return false

	cooked_zhuyu_count -= 1
	zhuyu_consumed = true
	demo_hunger = demo_hunger_max
	zhuyu_satiety_remaining = COOKED_ZHUYU_SATIETY_DURATION
	hunger_warning_level = 0
	current_step = DemoStep.ACTIVATE_STONE
	_log_ok("你食用了熟祝余，温热的饱腹感延续更久。")
	_unlock_zhuyu_knowledge(
		ZHUYU_KNOWLEDGE_EFFECT,
		"图鉴更新：祝余 · 效果：食之不饥"
	)
	_log("熟祝余效力发动：食之不饥更久。")
	_append_history_event("食用熟祝余")
	prompt_label.visible = false
	_refresh_status()
	_refresh_survival_status()
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
	_update_generated_shensheng_visuals()
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
	var migu_instance_id := _generated_instance_id_from_interactable(
		GENERATED_MIGU_TYPE,
		interactable_id
	)
	if config.is_empty() and not migu_instance_id.is_empty():
		config = _find_optional_config_by_id(MIGU_BRANCH_ITEM_ID)
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
	var is_generated_migu := (
		expected_type == "collectible"
		and str(config.get("id", "")) == MIGU_BRANCH_ITEM_ID
		and not migu_instance_id.is_empty()
	)
	if is_generated_migu:
		var saved_instance_id := str(
			metadata.get("instance_id", migu_instance_id)
		)
		if (
			saved_instance_id != migu_instance_id
			or _generated_instance_node(GENERATED_MIGU_TYPE, saved_instance_id) == null
		):
			_log_error("%s：metadata.instance_id 无效。" % error_prefix)
			return false
		migu_instance_id = saved_instance_id
		if _is_generated_instance_collected(
			GENERATED_MIGU_TYPE,
			migu_instance_id
		):
			_log(str(config.get("already_done_log", "")))
			return true
	elif _is_optional_done(config):
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
		if content_id == MIGU_BRANCH_ITEM_ID:
			_discover_migu_appearance_and_type()
	elif expected_type == "creature":
		if not bestiary_service.discover_creature(actor_id, content_id):
			_log_error("图鉴发现 %s 失败。" % content_id)
			return false
	else:
		_log_error("未知 optional content 类型：%s。" % expected_type)
		return false

	if is_generated_migu:
		_set_generated_instance_collected(
			GENERATED_MIGU_TYPE,
			migu_instance_id,
			true
		)
	_set_optional_done(config, true)
	recent_optional_completion_name = str(config.get("display_name", content_id))
	if (
		content_id == MIGU_BRANCH_ITEM_ID
		and not migu_equipped
		and not _equip_migu(true)
	):
		_log_error("迷穀自动佩戴失败。")
		return false
	_update_optional_content_visuals()
	prompt_label.visible = false
	if content_id != MIGU_BRANCH_ITEM_ID:
		_log_ok(str(config.get("success_log", "")))
	_append_history_event(str(config.get("history", "")))
	_refresh_status()
	_refresh_completion_summary()
	_update_objective_ui()
	_update_objective_guidance()
	return true


func _discover_migu_appearance_and_type() -> void:
	_unlock_migu_knowledge(
		MIGU_KNOWLEDGE_APPEARANCE,
		"图鉴更新：迷穀 · 外观"
	)
	_unlock_migu_knowledge(
		MIGU_KNOWLEDGE_TYPE,
		"图鉴更新：迷穀 · 类型"
	)


func _unlock_migu_knowledge(slot: String, feedback: String) -> bool:
	if not migu_knowledge_state.has(slot):
		return false
	if migu_knowledge_state.get(slot, false) == true:
		return false

	migu_knowledge_state[slot] = true
	if migu_branch_label != null and (
		slot == MIGU_KNOWLEDGE_APPEARANCE
		or slot == MIGU_KNOWLEDGE_TYPE
	):
		_update_generated_migu_visuals()
	_log(feedback)
	_refresh_navigation_status()
	_refresh_knowledge_codex()
	return true


func _has_migu_knowledge(slot: String) -> bool:
	return migu_knowledge_state.get(slot, false) == true


func _reset_migu_knowledge_state() -> void:
	migu_knowledge_state = {
		MIGU_KNOWLEDGE_APPEARANCE: false,
		MIGU_KNOWLEDGE_TYPE: false,
		MIGU_KNOWLEDGE_EFFECT: false
	}


func _format_migu_prompt(config: Dictionary) -> String:
	if _nearest_generated_instance_id(GENERATED_MIGU_TYPE).is_empty():
		if _is_optional_done(config):
			return "迷穀已采集并自动佩戴"
		return str(config.get("prompt_locked", ""))
	if (
		_has_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE)
		and _has_migu_knowledge(MIGU_KNOWLEDGE_TYPE)
	):
		return "按 E 采集迷穀"
	if _is_optional_done(config):
		return "迷穀已采集并自动佩戴"
	return "按 E 采集陌生黑理发光之木"


func _equip_migu(is_automatic := false) -> bool:
	if migu_equipped:
		_log("迷穀已经佩戴。")
		return false
	var migu_config := _find_optional_config_by_id(MIGU_BRANCH_ITEM_ID)
	if migu_config.is_empty() or not _is_optional_done(migu_config):
		_log_error("佩戴迷穀失败：尚未采集迷穀。")
		return false
	if (
		inventory_service == null
		or inventory_service.get_item_count(OWNER_ID, MIGU_BRANCH_ITEM_ID) <= 0
	):
		_log_error("佩戴迷穀失败：背包中没有迷穀。")
		return false

	migu_equipped = true
	_unlock_migu_knowledge(
		MIGU_KNOWLEDGE_EFFECT,
		"图鉴更新：迷穀 · 效果：佩之不迷"
	)
	if is_automatic:
		_log_ok("你采下迷穀，其华自照，已佩于身侧。")
	else:
		_log_ok("迷穀效力发动：佩之不迷")
		_append_history_event("佩戴迷穀")
	prompt_label.visible = false
	_update_optional_content_visuals()
	_refresh_navigation_status()
	_refresh_completion_summary()
	return true


func _discover_zhuyu_appearance_and_type() -> void:
	_unlock_zhuyu_knowledge(
		ZHUYU_KNOWLEDGE_APPEARANCE,
		"图鉴更新：祝余 · 外观"
	)
	_unlock_zhuyu_knowledge(
		ZHUYU_KNOWLEDGE_TYPE,
		"图鉴更新：祝余 · 类型"
	)


func _unlock_zhuyu_knowledge(slot: String, feedback: String) -> bool:
	if not zhuyu_knowledge_state.has(slot):
		return false
	if zhuyu_knowledge_state.get(slot, false) == true:
		return false

	zhuyu_knowledge_state[slot] = true
	if zhuyu_label != null and (
		slot == ZHUYU_KNOWLEDGE_APPEARANCE
		or slot == ZHUYU_KNOWLEDGE_TYPE
	):
		_update_generated_zhuyu_visuals()
	_log(feedback)
	_refresh_survival_status()
	_refresh_knowledge_codex()
	return true


func _has_zhuyu_knowledge(slot: String) -> bool:
	return zhuyu_knowledge_state.get(slot, false) == true


func _reset_zhuyu_knowledge_state() -> void:
	zhuyu_knowledge_state = {
		ZHUYU_KNOWLEDGE_APPEARANCE: false,
		ZHUYU_KNOWLEDGE_TYPE: false,
		ZHUYU_KNOWLEDGE_EFFECT: false,
		ZHUYU_KNOWLEDGE_COOKING: false
	}


func _format_zhuyu_collect_prompt() -> String:
	if (
		_has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE)
		and _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE)
	):
		return "按 E 采集祝余"
	return "按 E 采集陌生青华草"


func _get_raw_zhuyu_count() -> int:
	if inventory_service == null:
		return 0
	return inventory_service.get_item_count(OWNER_ID, ITEM_ID)


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
		"version": 5,
		"owner_id": OWNER_ID,
		"current_step": int(current_step),
		"world": {
			"generation_seed": generation_seed,
			"generated_content": generated_content.duplicate(true),
			"collected_instances": _build_collected_instance_save_state(),
			"pickup_collected": zhuyu_collected,
			"zhuyu_consumed": zhuyu_consumed,
			"cooked_zhuyu_count": cooked_zhuyu_count,
			"stone_activated": stone_activated,
			"creature_discovered": shensheng_discovered,
			"optional": _build_optional_save_state()
		},
		"survival": {
			"demo_hunger": demo_hunger,
			"zhuyu_satiety_remaining": zhuyu_satiety_remaining
		},
		"navigation": {
			"migu_equipped": migu_equipped,
			"origin_position": {
				"x": demo_origin_position.x,
				"y": demo_origin_position.y
			}
		},
		"knowledge": {
			"zhuyu": zhuyu_knowledge_state.duplicate(true),
			"migu": migu_knowledge_state.duplicate(true)
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


func _build_collected_instance_save_state() -> Dictionary:
	var state := {}
	for content_type in GENERATED_COLLECTIBLE_TYPES:
		var ids: Array = []
		var collected_value: Variant = collected_instance_ids.get(content_type, {})
		if collected_value is Dictionary:
			ids = collected_value.keys()
			ids.sort()
		state[content_type] = ids
	return state


func _build_optional_save_state() -> Dictionary:
	var state := {}
	for config in _all_optional_content():
		var content_id := str(config.get("id", ""))
		state[content_id] = _is_optional_done(config)
	return state


func _apply_generated_world_save_state(world_data: Dictionary) -> bool:
	if (
		not world_data.has("generation_seed")
		or not world_data.has("generated_content")
	):
		return _initialize_default_generated_world()

	var seed_value := _to_non_negative_int(world_data.get("generation_seed", -1))
	var content_value: Variant = world_data.get("generated_content", {})
	if seed_value < 0 or not (content_value is Dictionary):
		return false
	var content: Dictionary = content_value
	var loaded_content := {}
	for content_type in GENERATED_CONTENT_TYPES:
		var count := _to_non_negative_int(content.get(content_type, -1))
		if count < 0:
			return false
		loaded_content[content_type] = count

	_clear_collected_instance_ids()
	_configure_generated_world_layout(seed_value, loaded_content)

	var collected_value: Variant = world_data.get("collected_instances", {})
	if not (collected_value is Dictionary):
		return false
	var collected_data: Dictionary = collected_value
	for content_type in GENERATED_COLLECTIBLE_TYPES:
		var instance_ids: Variant = collected_data.get(content_type, [])
		if not (instance_ids is Array):
			return false
		for instance_id_value in instance_ids:
			if not (instance_id_value is String):
				return false
			var instance_id: String = instance_id_value
			if _generated_instance_node(content_type, instance_id) == null:
				return false
			_set_generated_instance_collected(content_type, instance_id, true)
	return true


func _migrate_legacy_generated_instance_state() -> void:
	if (
		zhuyu_collected
		and int(generated_content.get(GENERATED_ZHUYU_TYPE, 0)) > 0
	):
		_set_generated_instance_collected(
			GENERATED_ZHUYU_TYPE,
			_generated_instance_id(GENERATED_ZHUYU_TYPE, 0),
			true
		)
	var migu_config := _find_optional_config_by_id(MIGU_BRANCH_ITEM_ID)
	if (
		not migu_config.is_empty()
		and _is_optional_done(migu_config)
		and int(generated_content.get(GENERATED_MIGU_TYPE, 0)) > 0
	):
		_set_generated_instance_collected(
			GENERATED_MIGU_TYPE,
			_generated_instance_id(GENERATED_MIGU_TYPE, 0),
			true
		)


func _has_collected_generated_instance(content_type: String) -> bool:
	var collected_value: Variant = collected_instance_ids.get(content_type, {})
	return collected_value is Dictionary and not collected_value.is_empty()


func _apply_survival_save_state(state: Dictionary) -> void:
	demo_hunger_max = DEMO_HUNGER_MAX
	demo_hunger_decay_per_second = DEMO_HUNGER_DECAY_PER_SECOND
	demo_hunger = clampf(
		_to_float_or_default(state.get("demo_hunger"), demo_hunger_max),
		0.0,
		demo_hunger_max
	)
	zhuyu_satiety_remaining = clampf(
		_to_float_or_default(state.get("zhuyu_satiety_remaining"), 0.0),
		0.0,
		COOKED_ZHUYU_SATIETY_DURATION
	)
	hunger_warning_level = _get_hunger_warning_level()


func _apply_zhuyu_knowledge_save_state(state: Dictionary) -> void:
	_reset_zhuyu_knowledge_state()
	for slot in [
		ZHUYU_KNOWLEDGE_APPEARANCE,
		ZHUYU_KNOWLEDGE_TYPE,
		ZHUYU_KNOWLEDGE_EFFECT,
		ZHUYU_KNOWLEDGE_COOKING
	]:
		zhuyu_knowledge_state[slot] = state.get(slot, false) == true


func _apply_navigation_save_state(state: Dictionary) -> void:
	migu_equipped = state.get("migu_equipped", false) == true
	demo_origin_position = PLAYER_START_POSITION
	var origin_data: Variant = state.get("origin_position", {})
	if not (origin_data is Dictionary):
		return
	demo_origin_position = Vector2(
		_to_float_or_default(origin_data.get("x"), PLAYER_START_POSITION.x),
		_to_float_or_default(origin_data.get("y"), PLAYER_START_POSITION.y)
	)


func _apply_migu_knowledge_save_state(state: Dictionary) -> void:
	_reset_migu_knowledge_state()
	for slot in [
		MIGU_KNOWLEDGE_APPEARANCE,
		MIGU_KNOWLEDGE_TYPE,
		MIGU_KNOWLEDGE_EFFECT
	]:
		migu_knowledge_state[slot] = state.get(slot, false) == true


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
	if not _is_valid_demo_step(saved_step):
		return false

	var world_data: Variant = state.get("world", {})
	var inventory_data: Variant = state.get("inventory", {})
	var bestiary_data: Variant = state.get("bestiary", {})
	var survival_data: Variant = state.get("survival", {})
	var navigation_data: Variant = state.get("navigation", {})
	var knowledge_data: Variant = state.get("knowledge", {})
	if not (world_data is Dictionary):
		return false
	if not (inventory_data is Dictionary):
		return false
	if not (bestiary_data is Dictionary):
		return false
	if not (survival_data is Dictionary):
		return false
	if not (navigation_data is Dictionary):
		return false
	if not (knowledge_data is Dictionary):
		return false
	var zhuyu_knowledge_data: Variant = knowledge_data.get("zhuyu", {})
	var migu_knowledge_data: Variant = knowledge_data.get("migu", {})
	if not (zhuyu_knowledge_data is Dictionary):
		return false
	if not (migu_knowledge_data is Dictionary):
		return false

	var inventory_counts := _build_loaded_inventory_counts(inventory_data)
	if inventory_counts.is_empty():
		return false
	var loaded_cooked_zhuyu_count := _to_non_negative_int(
		world_data.get("cooked_zhuyu_count", 0)
	)
	if loaded_cooked_zhuyu_count < 0:
		return false
	if not _apply_generated_world_save_state(world_data):
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
	zhuyu_consumed = world_data.get(
		"zhuyu_consumed",
		_step_is_after_zhuyu_eaten(current_step)
	) == true
	cooked_zhuyu_count = loaded_cooked_zhuyu_count
	stone_activated = world_data.get("stone_activated", false) == true
	shensheng_discovered = world_data.get("creature_discovered", false) == true
	_apply_survival_save_state(survival_data)
	_apply_navigation_save_state(navigation_data)
	_apply_zhuyu_knowledge_save_state(zhuyu_knowledge_data)
	_apply_migu_knowledge_save_state(migu_knowledge_data)
	recent_optional_completion_name = ""
	var optional_data: Variant = world_data.get("optional", {})
	if not (optional_data is Dictionary):
		return false
	_apply_optional_save_state(optional_data)
	_apply_legacy_optional_save_state(world_data, optional_data)
	if _step_has_collected_zhuyu(current_step):
		zhuyu_collected = true
	if _step_is_after_zhuyu_eaten(current_step):
		zhuyu_consumed = true
	if current_step == DemoStep.OBSERVE_SHENSHENG or current_step == DemoStep.COMPLETE:
		stone_activated = true
	if current_step == DemoStep.COMPLETE:
		shensheng_discovered = true
	if not world_data.has("collected_instances"):
		_migrate_legacy_generated_instance_state()
	if _has_collected_generated_instance(GENERATED_ZHUYU_TYPE):
		zhuyu_collected = true
	if _has_collected_generated_instance(GENERATED_MIGU_TYPE):
		var generated_migu_config := _find_optional_config_by_id(
			MIGU_BRANCH_ITEM_ID
		)
		if not generated_migu_config.is_empty():
			_set_optional_done(generated_migu_config, true)

	var migu_config := _find_optional_config_by_id(MIGU_BRANCH_ITEM_ID)
	var has_collected_migu := (
		not migu_config.is_empty()
		and _is_optional_done(migu_config)
		and inventory_service.get_item_count(OWNER_ID, MIGU_BRANCH_ITEM_ID) > 0
	)
	if has_collected_migu:
		migu_equipped = true
		migu_knowledge_state[MIGU_KNOWLEDGE_APPEARANCE] = true
		migu_knowledge_state[MIGU_KNOWLEDGE_TYPE] = true
		migu_knowledge_state[MIGU_KNOWLEDGE_EFFECT] = true
	elif migu_equipped:
		migu_equipped = false

	_restore_saved_player_position(state)
	player_animation_state_machine.reset_to_idle()
	_restore_saved_history(state)
	_apply_world_visual_state()
	completion_panel.visible = false
	if current_step == DemoStep.COMPLETE:
		_refresh_completion_summary()
	_refresh_status()
	_refresh_survival_status()
	_update_navigation_state()
	_refresh_knowledge_codex()
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
	if not _initialize_default_generated_world():
		_clear_collected_instance_ids()
		_configure_generated_world_layout(0, {
			GENERATED_ZHUYU_TYPE: 1,
			GENERATED_MIGU_TYPE: 1,
			GENERATED_SHENSHENG_TYPE: 1
		})

	player.position = PLAYER_START_POSITION
	player_animation_state_machine.reset_to_idle()
	current_step = DemoStep.COLLECT_ZHUYU
	zhuyu_collected = false
	zhuyu_consumed = false
	cooked_zhuyu_count = 0
	stone_activated = false
	shensheng_discovered = false
	demo_hunger = demo_hunger_max
	zhuyu_satiety_remaining = 0.0
	hunger_warning_level = 0
	_reset_zhuyu_knowledge_state()
	demo_origin_position = PLAYER_START_POSITION
	migu_equipped = false
	navigation_pressure_level = 0
	_reset_migu_knowledge_state()
	_set_knowledge_codex_visible(false)
	was_codex_toggle_key_pressed = false
	recent_optional_completion_name = ""
	_reset_optional_state()
	_close_demo_menu()
	completion_panel.visible = false
	_apply_world_visual_state()
	_refresh_status()
	_refresh_survival_status()
	_refresh_navigation_status()
	_refresh_knowledge_codex()
	_update_objective_ui()
	_update_objective_guidance()
	interaction_history.clear()
	_append_history_event(history_message)
	_log_ok(history_message)


func _apply_world_visual_state() -> void:
	_update_generated_zhuyu_visuals()

	if stone_activated:
		guidance_stone.modulate.a = 0.55
		guidance_stone_label.text = "山海石碑（已激活）"
	else:
		guidance_stone.modulate.a = 1.0
		guidance_stone_label.text = "山海石碑"

	_update_generated_shensheng_visuals()

	_update_optional_content_visuals()

	prompt_label.visible = false
	was_near_zhuyu = false
	was_near_stone = false
	was_near_shensheng = false
	_reset_optional_near_state()
	was_interact_key_pressed = false


func _show_completion_panel() -> void:
	_set_knowledge_codex_visible(false)
	_refresh_completion_summary()
	completion_panel.visible = true
	prompt_label.visible = false
	_refresh_status()
	_update_objective_ui()
	_update_objective_guidance()


func _refresh_completion_summary() -> void:
	completion_summary_label.text = "已完成 Demo 流程\n\n已采集：祝余\n已食用：祝余（食之不饥）\n已激活：山海石碑\n已发现：狌狌\n%s\n\n%s\n\n验证服务：\n- DataRegistry\n- InteractionService\n- InventoryService\n- BestiaryService\n- SaveService（菜单保存 / 读取）" % [
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
	return not _nearest_generated_instance_id(
		GENERATED_ZHUYU_TYPE
	).is_empty()


func _is_near_campfire() -> bool:
	if campfire == null or not campfire.visible:
		return false
	return player.global_position.distance_to(campfire.global_position) <= interaction_distance


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
	if str(config.get("id", "")) == MIGU_BRANCH_ITEM_ID:
		return not _nearest_generated_instance_id(
			GENERATED_MIGU_TYPE
		).is_empty()
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
		var content_id := str(config.get("id", ""))
		if content_id == MIGU_BRANCH_ITEM_ID:
			continue
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
			if content_id == MIGU_BRANCH_ITEM_ID and migu_equipped:
				label.text = "迷穀（已佩戴）"
		elif current_step == DemoStep.COMPLETE:
			node.modulate.a = _to_float_or_default(config.get("ready_alpha", 1.0), 1.0)
			if (
				content_id == MIGU_BRANCH_ITEM_ID
				and _has_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE)
			):
				label.text = "迷穀"
		else:
			node.modulate.a = _to_float_or_default(config.get("locked_alpha", 0.3), 0.3)

	_update_generated_migu_visuals()
	_update_optional_progress_journal()


func _set_optional_content_alpha(alpha: float) -> void:
	for config in _all_optional_content():
		if str(config.get("id", "")) == MIGU_BRANCH_ITEM_ID:
			continue
		var node: Node2D = config.get("node", null) as Node2D
		if node != null:
			node.modulate.a = alpha
	_set_generated_type_alpha(GENERATED_MIGU_TYPE, alpha)


func _reset_optional_content_scale() -> void:
	for config in _all_optional_content():
		if str(config.get("id", "")) == MIGU_BRANCH_ITEM_ID:
			continue
		var node: Node2D = config.get("node", null) as Node2D
		if node != null:
			node.scale = Vector2.ONE
	_set_generated_type_scale(GENERATED_MIGU_TYPE, Vector2.ONE)


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


func _refresh_survival_status() -> void:
	if survival_status_label == null:
		return

	var satiety_text := "未发动"
	if zhuyu_satiety_remaining > 0.0:
		satiety_text = "%d 秒" % int(ceil(zhuyu_satiety_remaining))
	survival_status_label.text = "饥饿：%d / %d\n祝余效力：%s\n祝余知识：%s" % [
		int(round(demo_hunger)),
		int(round(demo_hunger_max)),
		satiety_text,
		_format_zhuyu_knowledge_status()
	]


func _format_zhuyu_knowledge_status() -> String:
	var unlocked: Array[String] = []
	if _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE):
		unlocked.append("外观")
	if _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE):
		unlocked.append("类型")
	if _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT):
		unlocked.append("食之不饥")
	if _has_zhuyu_knowledge(ZHUYU_KNOWLEDGE_COOKING):
		unlocked.append("烹饪")
	if unlocked.is_empty():
		return "未知"
	return "、".join(unlocked)


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
			objective_label.text = "当前目标：寻找并采集祝余"
		DemoStep.EAT_ZHUYU:
			if cooked_zhuyu_count > 0:
				objective_label.text = "当前目标：食用熟祝余"
			else:
				objective_label.text = "当前目标：食用或烹饪祝余"
		DemoStep.ACTIVATE_STONE:
			objective_label.text = "当前目标：前往山海石碑"
		DemoStep.OBSERVE_SHENSHENG:
			objective_label.text = "当前目标：观察狌狌"
		DemoStep.COMPLETE:
			if _is_optional_exploration_complete():
				objective_label.text = "当前目标：Demo 完成，可选探索完成"
			else:
				objective_label.text = "当前目标：Demo 完成，可选探索已解锁"


func _is_valid_demo_step(step: int) -> bool:
	return step in [
		DemoStep.COLLECT_ZHUYU,
		DemoStep.EAT_ZHUYU,
		DemoStep.ACTIVATE_STONE,
		DemoStep.OBSERVE_SHENSHENG,
		DemoStep.COMPLETE
	]


func _step_has_collected_zhuyu(step: int) -> bool:
	return step != DemoStep.COLLECT_ZHUYU and _is_valid_demo_step(step)


func _step_is_after_zhuyu_eaten(step: int) -> bool:
	return step in [
		DemoStep.ACTIVATE_STONE,
		DemoStep.OBSERVE_SHENSHENG,
		DemoStep.COMPLETE
	]


func _get_active_target_node() -> Node2D:
	match current_step:
		DemoStep.COLLECT_ZHUYU:
			return zhuyu_pickup
		DemoStep.EAT_ZHUYU:
			return null
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
			_set_generated_type_alpha(GENERATED_SHENSHENG_TYPE, 0.35)
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("祝余", "按 E 采集", active_target)
		DemoStep.EAT_ZHUYU:
			guidance_stone.modulate.a = 0.35
			_set_generated_type_alpha(GENERATED_SHENSHENG_TYPE, 0.35)
			_set_optional_content_alpha(0.3)
			if cooked_zhuyu_count > 0:
				target_hint_label.text = "目标提示：熟祝余已备好，按 E 食用"
			else:
				target_hint_label.text = "目标提示：直接食用，或带到篝火烹饪"
		DemoStep.ACTIVATE_STONE:
			guidance_stone.modulate.a = 1.0
			guidance_stone.scale = Vector2(1.15, 1.15)
			_set_generated_type_alpha(GENERATED_SHENSHENG_TYPE, 0.35)
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("山海石碑", "按 E 激活", active_target)
		DemoStep.OBSERVE_SHENSHENG:
			guidance_stone.modulate.a = 0.55
			_set_generated_type_alpha(GENERATED_SHENSHENG_TYPE, 1.0)
			shensheng_creature.scale = Vector2(1.15, 1.15)
			_set_optional_content_alpha(0.3)
			target_hint_label.text = _format_target_hint("狌狌", "按 E 观察", active_target)
		DemoStep.COMPLETE:
			guidance_stone.modulate.a = 0.55
			_set_generated_type_alpha(GENERATED_SHENSHENG_TYPE, 0.45)
			_update_optional_content_visuals()
			if _is_optional_exploration_complete():
				target_hint_label.text = "目标提示：所有 Demo 内容已完成"
			else:
				target_hint_label.text = "目标提示：可选探索：%s" % _format_optional_display_names(" / ")


func _reset_guidance_visuals() -> void:
	_set_generated_type_scale(GENERATED_ZHUYU_TYPE, Vector2.ONE)
	guidance_stone.scale = Vector2.ONE
	_set_generated_type_scale(GENERATED_SHENSHENG_TYPE, Vector2.ONE)
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
	live_log_entries.append(line)
	_refresh_live_log_ui()


func _refresh_live_log_ui() -> void:
	if log_label == null:
		return
	var first_visible_index: int = max(
		0,
		live_log_entries.size() - LIVE_LOG_UI_RECENT_LIMIT
	)
	var visible_lines: Array[String] = []
	for index in range(first_visible_index, live_log_entries.size()):
		visible_lines.append(live_log_entries[index])
	log_label.text = "\n".join(visible_lines)
