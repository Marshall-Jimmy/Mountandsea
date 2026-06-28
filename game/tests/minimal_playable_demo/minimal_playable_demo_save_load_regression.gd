extends SceneTree

const DEMO_SCENE := preload("res://scenes/demo/minimal_playable_demo.tscn")

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const MIGU_BRANCH_ITEM_ID := "migu_branch"
const BASIC_ORE_ITEM_ID := "basic_ore"
const LUSHU_CREATURE_ID := "lushu"
const GENERIC_BEAST_CREATURE_ID := "generic_beast"
const ZHUYU_INTERACTABLE_ID := "pickup_zhuyu_leaf"
const STONE_INTERACTABLE_ID := "activate_guidance_stone"
const SHENSHENG_INTERACTABLE_ID := "observe_shensheng"
const MIGU_BRANCH_INTERACTABLE_ID := "collect_migu_branch"
const BASIC_ORE_INTERACTABLE_ID := "collect_basic_ore"
const LUSHU_INTERACTABLE_ID := "observe_lushu"
const GENERIC_BEAST_INTERACTABLE_ID := "observe_generic_beast"
const PLAYER_SPRITE_SHEET_PATH := "res://assets/demo/placeholder_sprites/demo_player_idle_walk.png"
const PLAYER_WALK_METADATA_PATH := "res://assets/demo/placeholder_sprites/demo_player_walk_metadata.json"
const PLAYER_ANIMATION_STATE_IDLE := 0
const PLAYER_ANIMATION_STATE_WALK := 1
const PLAYER_FACING_LEFT := -1
const PLAYER_FACING_RIGHT := 1
const PLAYER_FRAME_SIZE := Vector2i(512, 512)
const PLAYER_IDLE_FRAME_COUNT := 2
const PLAYER_WALK_FRAME_COUNT := 8
const PLAYER_TOTAL_FRAME_COUNT := PLAYER_IDLE_FRAME_COUNT + PLAYER_WALK_FRAME_COUNT
const PLAYER_FEET_BASELINE_Y := 488
const PLAYER_EDGE_ALPHA_CUTOFF := 32
const PLAYER_WALK_FPS_MIN := 7.0
const PLAYER_WALK_FPS_MAX := 8.0
const PLAYER_BODY_CENTER_REGION := Rect2i(180, 80, 160, 250)
const PLAYER_BODY_CENTER_MAX_SPREAD := Vector2(8.0, 8.0)
const PLAYER_WALK_BOUNDS_MAX_SPREAD := Vector2i(16, 16)
const PLAYER_WALK_MAX_NORMALIZED_ALPHA_DELTA := 0.08
const SHENSHENG_SPRITE_SHEET_PATH := "res://assets/demo/placeholder_sprites/demo_shensheng_idle.png"
const SHENSHENG_IDLE_METADATA_PATH := "res://assets/demo/placeholder_sprites/demo_shensheng_idle_metadata.json"
const SHENSHENG_FRAME_SIZE := Vector2i(512, 512)
const SHENSHENG_IDLE_FRAME_COUNT := 6
const SHENSHENG_IDLE_FPS_MIN := 3.0
const SHENSHENG_IDLE_FPS_MAX := 5.0
const SHENSHENG_FEET_BASELINE_Y := 470
const SHENSHENG_EDGE_ALPHA_CUTOFF := 32
const SHENSHENG_MAX_NORMALIZED_ALPHA_DELTA := 0.055
const SHENSHENG_EXPECTED_POSITION := Vector2(650.0, 260.0)
const STEP_COLLECT_ZHUYU := 0
const STEP_OBSERVE_SHENSHENG := 2
const STEP_COMPLETE := 3
const STEP_EAT_ZHUYU := 4
const DEMO_HUNGER_MAX := 100.0
const ZHUYU_SATIETY_DURATION := 15.0
const ZHUYU_KNOWLEDGE_APPEARANCE := "appearance"
const ZHUYU_KNOWLEDGE_TYPE := "type"
const ZHUYU_KNOWLEDGE_EFFECT := "effect"
const NAVIGATION_NEAR_ORIGIN_DISTANCE := 180.0
const NAVIGATION_LOST_PRESSURE_DISTANCE := 360.0
const MIGU_KNOWLEDGE_APPEARANCE := "appearance"
const MIGU_KNOWLEDGE_TYPE := "type"
const MIGU_KNOWLEDGE_EFFECT := "effect"

var demo: Node
var player: Node2D
var initial_position := Vector2.ZERO
var failed := false


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	await process_frame

	demo = DEMO_SCENE.instantiate()
	root.add_child(demo)

	await process_frame
	await process_frame

	_run_test()


func _run_test() -> void:
	player = demo.get_node_or_null("WorldRoot/Player")
	_assert_true(player != null, "Player node must exist")
	_assert_true(demo.get("initialized") == true, "Demo must initialize services")
	if player != null:
		initial_position = player.position
	_assert_player_animation_pipeline()
	_assert_shensheng_idle_pipeline()
	_assert_history_panel_visible(true)
	_assert_initial_journal_state()
	_assert_progress_view_toggle_preserves_history("Demo 开始")
	_assert_journal_shortcut_handlers_preserve_text("Demo 开始")
	_assert_reset_preserves_compact_journal_view()
	_assert_zhuyu_hunger_knowledge_loop()
	_assert_migu_navigation_knowledge_loop()
	if failed:
		return

	var saved_position := initial_position + Vector2(120.0, 80.0)
	_force_state_after_stone_activation()
	_assert_state_after_stone_activation()
	_assert_history_contains("采集祝余叶")
	_assert_history_contains("食用祝余")
	_assert_history_contains("激活山海石碑")
	player.position = saved_position

	demo.call("_on_save_demo_pressed")
	_assert_history_contains("保存 Demo")

	player.position = initial_position + Vector2(300.0, 200.0)
	demo.call("_reset_demo_state")
	_assert_vec2_near(player.position, initial_position, "reset should return player to initial position")
	_assert_true(demo.get("current_step") == STEP_COLLECT_ZHUYU, "reset should restore initial step")
	_assert_history_contains("Demo 已重置")
	_assert_history_not_contains("采集祝余叶")

	var animation_state_machine := _get_player_animation_state_machine()
	if animation_state_machine != null:
		animation_state_machine.call("set_movement_vector", Vector2.LEFT)
	_assert_player_facing(PLAYER_FACING_LEFT, false, "left movement before load")
	demo.call("_on_load_demo_pressed")
	_assert_vec2_near(player.position, saved_position, "load should restore saved player position")
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_IDLE, &"idle")
	_assert_player_facing(PLAYER_FACING_RIGHT, true, "load should restore runtime default facing")
	_assert_state_after_stone_activation()
	_assert_history_contains("采集祝余叶")
	_assert_history_contains("食用祝余")
	_assert_history_contains("激活山海石碑")
	_assert_history_contains("保存 Demo")
	_assert_history_contains("读取 Demo")

	_force_state_complete()
	_assert_state_complete()
	_assert_history_contains("发现狌狌")
	_assert_history_contains("Demo 完成")

	var complete_position := initial_position + Vector2(220.0, 160.0)
	player.position = complete_position
	demo.call("_on_save_demo_pressed")
	_assert_history_contains("保存 Demo")

	player.position = initial_position + Vector2(400.0, 240.0)
	demo.call("_reset_demo_state")
	_assert_vec2_near(player.position, initial_position, "reset before complete-state load should return player to initial position")
	_assert_history_contains("Demo 已重置")
	_assert_history_not_contains("发现狌狌")

	demo.call("_on_load_demo_pressed")
	_assert_vec2_near(player.position, complete_position, "load should restore saved complete-state player position")
	_assert_state_complete()
	_assert_optional_state_pending()
	_assert_history_contains("发现狌狌")
	_assert_history_contains("Demo 完成")
	_assert_history_contains("读取 Demo")

	var optional_position := initial_position + Vector2(320.0, 220.0)
	player.position = optional_position
	_force_one_optional_collectible_complete()
	_assert_journal_progress(1, _optional_total_count())
	_assert_journal_section_progress("可选采集物", 1, _optional_collectible_count())
	_assert_journal_section_progress("可选生物 / 互动", 0, _optional_creature_count())
	_assert_journal_recent("迷穀枝")
	_assert_journal_status("迷穀枝", "已完成")
	_assert_journal_status("粗矿石", "未完成")
	_assert_repeated_optional_completion_preserves_history_and_recent()
	_force_optional_complete()
	_assert_optional_state_complete()
	_assert_journal_recent("普通野兽")
	_assert_journal_save_fields_absent()
	_assert_history_ui_recent_limit_preserves_internal_history()
	_assert_history_contains("采集迷穀枝")
	_assert_history_contains("采集粗矿石")
	_assert_history_contains("发现鹿蜀")
	_assert_history_contains("发现普通野兽")
	_assert_history_panel_toggle_preserves_history("发现普通野兽")

	demo.call("_on_save_demo_pressed")
	_assert_history_contains("保存 Demo")

	player.position = initial_position + Vector2(520.0, 300.0)
	demo.call("_reset_demo_state")
	_assert_vec2_near(player.position, initial_position, "reset before optional-state load should return player to initial position")
	_assert_optional_state_pending()
	_assert_history_contains("Demo 已重置")
	_assert_history_not_contains("采集迷穀枝")
	_assert_history_not_contains("采集粗矿石")
	_assert_history_not_contains("发现鹿蜀")
	_assert_history_not_contains("发现普通野兽")

	demo.call("_on_load_demo_pressed")
	_assert_vec2_near(player.position, optional_position, "load should restore saved optional-state player position")
	_assert_state_complete()
	_assert_optional_state_complete()
	_assert_journal_recent("无")
	_assert_history_contains("采集迷穀枝")
	_assert_history_contains("采集粗矿石")
	_assert_history_contains("发现鹿蜀")
	_assert_history_contains("发现普通野兽")
	_assert_history_contains("读取 Demo")

	_assert_legacy_optional_save_compatibility()

	player.position = initial_position + Vector2(500.0, 260.0)
	demo.call("_on_restart_demo_pressed")
	_assert_vec2_near(player.position, initial_position, "restart should return player to initial position")
	_assert_true(demo.get("current_step") == STEP_COLLECT_ZHUYU, "restart should restore initial step")
	_assert_optional_state_pending()
	_assert_history_contains("重新开始 Demo")
	_assert_history_not_contains("发现狌狌")
	_assert_history_not_contains("采集迷穀枝")
	_assert_history_not_contains("采集粗矿石")
	_assert_history_not_contains("发现鹿蜀")
	_assert_history_not_contains("发现普通野兽")

	if failed:
		return

	print("minimal_playable_demo save/load regression passed")
	quit(0)


func _assert_zhuyu_hunger_knowledge_loop() -> void:
	demo.call("_reset_demo_state")
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"reset should start hunger at maximum"
	)
	_assert_float_near(
		float(demo.get("zhuyu_satiety_remaining")),
		0.0,
		"reset should clear zhuyu satiety"
	)
	_assert_true(demo.get("zhuyu_collected") == false, "zhuyu should start uncollected")
	_assert_true(demo.get("zhuyu_consumed") == false, "zhuyu should start uneaten")
	_assert_inventory_count(0)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, false)
	_assert_survival_status("饥饿")
	_assert_survival_status("祝余效力")

	var hunger_before_tick := float(demo.get("demo_hunger"))
	demo.call("_update_hunger", 2.0)
	_assert_true(
		float(demo.get("demo_hunger")) < hunger_before_tick,
		"hunger should decay during a normal tick"
	)
	demo.set("demo_hunger", 1.0)
	demo.call("_update_hunger", 1000.0)
	_assert_float_near(
		float(demo.get("demo_hunger")),
		0.0,
		"hunger should never fall below zero"
	)

	demo.call("_reset_demo_state")
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"reset should restore hunger after decay"
	)

	var zhuyu_pickup := demo.get_node_or_null("WorldRoot/ZhuyuPickup") as Node2D
	var zhuyu_label := demo.get_node_or_null("WorldRoot/ZhuyuLabel") as Label
	_assert_true(zhuyu_pickup != null, "ZhuyuPickup should exist")
	_assert_true(
		zhuyu_label != null and zhuyu_label.text == "陌生青华草",
		"unknown zhuyu should not reveal its name before discovery"
	)
	if zhuyu_pickup == null:
		return
	player.position = zhuyu_pickup.global_position
	var unknown_prompt: Variant = demo.call("_format_zhuyu_collect_prompt")
	_assert_true(
		unknown_prompt is String and unknown_prompt.contains("陌生青华草"),
		"unknown zhuyu prompt should describe an unfamiliar plant"
	)
	demo.call("_update_prompt")
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE, true)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE, true)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, false)
	_assert_prompt_contains("采集祝余")
	_assert_log_contains("图鉴更新：祝余 · 外观")
	_assert_log_contains("图鉴更新：祝余 · 类型")

	var zhuyu_result: Variant = demo.call("_on_zhuyu_interacted", OWNER_ID, ZHUYU_INTERACTABLE_ID, {
		"item_id": ITEM_ID,
		"count": 1
	})
	_assert_true(zhuyu_result == true, "zhuyu collection should succeed")
	_assert_true(demo.get("current_step") == STEP_EAT_ZHUYU, "collection should advance to EAT_ZHUYU")
	_assert_true(demo.get("zhuyu_collected") == true, "zhuyu should be marked collected")
	_assert_true(zhuyu_pickup.visible == false, "collected zhuyu should be hidden")
	_assert_inventory_count(1)
	demo.call("_update_prompt")
	_assert_prompt_contains("食用祝余")
	var repeated_collect_result: Variant = demo.call(
		"_on_zhuyu_interacted",
		OWNER_ID,
		ZHUYU_INTERACTABLE_ID,
		{"item_id": ITEM_ID, "count": 1}
	)
	_assert_true(repeated_collect_result == false, "zhuyu should not be collected twice")
	_assert_inventory_count(1)

	var collected_state: Variant = demo.call("_build_demo_save_state")
	_assert_true(collected_state is Dictionary, "collected zhuyu state should be serializable")
	demo.call("_reset_demo_state")
	var collected_load_result: Variant = demo.call("_apply_demo_save_state", collected_state)
	_assert_true(collected_load_result == true, "collected zhuyu state should load")
	_assert_true(demo.get("current_step") == STEP_EAT_ZHUYU, "load should restore EAT_ZHUYU")
	_assert_true(demo.get("zhuyu_collected") == true, "load should restore collected zhuyu")
	_assert_true(demo.get("zhuyu_consumed") == false, "collected save should remain uneaten")
	_assert_inventory_count(1)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE, true)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE, true)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, false)

	demo.set("demo_hunger", 20.0)
	var eat_result: Variant = demo.call("_eat_zhuyu")
	_assert_true(eat_result == true, "eating collected zhuyu should succeed")
	_assert_true(demo.get("zhuyu_consumed") == true, "zhuyu should be marked consumed")
	_assert_inventory_count(0)
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"eating zhuyu should restore hunger"
	)
	_assert_true(
		float(demo.get("zhuyu_satiety_remaining")) > 0.0,
		"eating zhuyu should start satiety"
	)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_log_contains("食之不饥")
	var repeated_eat_result: Variant = demo.call("_eat_zhuyu")
	_assert_true(repeated_eat_result == false, "zhuyu should not be eaten twice")
	_assert_inventory_count(0)

	var eaten_state: Variant = demo.call("_build_demo_save_state")
	_assert_true(eaten_state is Dictionary, "eaten zhuyu state should be serializable")
	if eaten_state is Dictionary:
		_assert_true(eaten_state.has("survival"), "save should include survival state")
		_assert_true(eaten_state.has("knowledge"), "save should include knowledge state")
		var eaten_world: Variant = eaten_state.get("world", {})
		_assert_true(
			eaten_world is Dictionary and eaten_world.get("zhuyu_consumed", false) == true,
			"save should include zhuyu consumed state"
		)

	demo.call("_reset_demo_state")
	var eaten_load_result: Variant = demo.call("_apply_demo_save_state", eaten_state)
	_assert_true(eaten_load_result == true, "eaten zhuyu state should load")
	_assert_true(demo.get("zhuyu_consumed") == true, "load should restore consumed zhuyu")
	_assert_inventory_count(0)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"load should restore saved hunger"
	)
	var restored_satiety := float(demo.get("zhuyu_satiety_remaining"))
	_assert_true(restored_satiety > 0.0, "load should restore finite zhuyu satiety")
	demo.call("_update_prompt")
	_assert_prompt_not_contains("食用祝余")

	var hunger_during_satiety := float(demo.get("demo_hunger"))
	var protected_tick := minf(5.0, restored_satiety)
	demo.call("_update_hunger", protected_tick)
	_assert_float_near(
		float(demo.get("demo_hunger")),
		hunger_during_satiety,
		"satiety should pause hunger decay"
	)
	var remaining_satiety := float(demo.get("zhuyu_satiety_remaining"))
	demo.call("_update_hunger", remaining_satiety + 1.0)
	_assert_float_near(
		float(demo.get("zhuyu_satiety_remaining")),
		0.0,
		"satiety should expire"
	)
	_assert_true(
		float(demo.get("demo_hunger")) < hunger_during_satiety,
		"hunger should resume after satiety expires"
	)

	demo.set("zhuyu_satiety_remaining", 0.0)
	demo.set("demo_hunger", 71.0)
	demo.set("hunger_warning_level", 0)
	demo.call("_update_hunger", 1.0)
	_assert_log_contains("你开始感到饥饿。")
	demo.set("demo_hunger", 36.0)
	demo.set("hunger_warning_level", 1)
	demo.call("_update_hunger", 1.0)
	_assert_log_contains("饥饿加深，应该寻找可食之物。")

	var legacy_state := {
		"version": 1,
		"owner_id": OWNER_ID,
		"current_step": STEP_COLLECT_ZHUYU,
		"world": {
			"pickup_collected": false,
			"stone_activated": false,
			"creature_discovered": false
		},
		"player": {
			"position": {
				"x": initial_position.x,
				"y": initial_position.y
			}
		},
		"inventory": {
			ITEM_ID: 0
		},
		"bestiary": {
			"items": [],
			"creatures": []
		},
		"history": []
	}
	var legacy_result: Variant = demo.call("_apply_demo_save_state", legacy_state)
	_assert_true(legacy_result == true, "legacy save without hunger or knowledge should load")
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"legacy save should default hunger to maximum"
	)
	_assert_float_near(
		float(demo.get("zhuyu_satiety_remaining")),
		0.0,
		"legacy save should default satiety to zero"
	)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, false)
	_assert_true(demo.get("zhuyu_consumed") == false, "legacy initial save should remain uneaten")

	demo.call("_reset_demo_state")


func _assert_migu_navigation_knowledge_loop() -> void:
	demo.call("_reset_demo_state")
	var origin: Vector2 = demo.get("demo_origin_position")
	_assert_vec2_near(origin, initial_position, "navigation origin should start at player spawn")
	_assert_true(demo.get("migu_equipped") == false, "migu should start unequipped")
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)

	player.position = origin + Vector2(NAVIGATION_NEAR_ORIGIN_DISTANCE - 10.0, 0.0)
	demo.call("_update_navigation_state")
	_assert_navigation_status_contains("方向感：稳定")
	_assert_navigation_status_not_contains("迷穀归向：")

	player.position = origin + Vector2(NAVIGATION_NEAR_ORIGIN_DISTANCE + 20.0, 0.0)
	demo.call("_update_navigation_state")
	_assert_navigation_status_contains("方向感：不稳")
	_assert_navigation_status_not_contains("迷穀归向：")

	player.position = origin + Vector2(NAVIGATION_LOST_PRESSURE_DISTANCE + 20.0, 0.0)
	demo.call("_update_navigation_state")
	_assert_navigation_status_contains("方向感：模糊")
	_assert_navigation_status_not_contains("迷穀归向：")
	_assert_log_contains("你离起点越来越远，方向感开始模糊。")

	demo.call("_reset_demo_state")
	_assert_vec2_near(
		demo.get("demo_origin_position"),
		initial_position,
		"reset should restore navigation origin"
	)
	_assert_true(demo.get("migu_equipped") == false, "reset should clear migu equipped state")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, false)
	_assert_navigation_status_not_contains("迷穀归向：")

	_force_state_complete()
	demo.call("_on_close_completion_pressed")
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"migu loop setup should preserve zhuyu hunger recovery"
	)
	_assert_true(
		float(demo.get("zhuyu_satiety_remaining")) > 0.0,
		"migu loop setup should preserve zhuyu satiety"
	)

	var migu_node := demo.get_node_or_null("WorldRoot/MiguBranch") as Node2D
	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel") as Label
	_assert_true(migu_node != null, "MiguBranch should exist")
	_assert_true(
		migu_label != null and migu_label.text == "陌生黑理发光之木",
		"migu should remain unknown before discovery"
	)
	if migu_node == null:
		return

	player.position = migu_node.global_position
	demo.call("_update_prompt")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)
	_assert_prompt_contains("采集迷穀")
	_assert_log_contains("图鉴更新：迷穀 · 外观")
	_assert_log_contains("图鉴更新：迷穀 · 类型")

	var collect_result: Variant = demo.call(
		"_on_optional_collectible_interacted",
		OWNER_ID,
		MIGU_BRANCH_INTERACTABLE_ID,
		{"item_id": MIGU_BRANCH_ITEM_ID, "count": 1}
	)
	_assert_true(collect_result == true, "migu collection should succeed")
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, true)
	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	_assert_true(
		migu_label != null and migu_label.text.contains("已采集"),
		"collected migu should show collected state"
	)
	_assert_log_contains("你采集了迷穀。")
	_assert_log_contains("迷穀之华自照，似可佩戴以辨方向。")

	var repeated_collect_result: Variant = demo.call(
		"_on_optional_collectible_interacted",
		OWNER_ID,
		MIGU_BRANCH_INTERACTABLE_ID,
		{"item_id": MIGU_BRANCH_ITEM_ID, "count": 1}
	)
	_assert_true(repeated_collect_result == true, "repeated migu collection should be harmless")
	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	demo.call("_update_prompt")
	_assert_prompt_contains("佩戴迷穀")

	demo.call("_try_interact")
	_assert_true(demo.get("migu_equipped") == true, "migu should equip through interaction")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, true)
	_assert_log_contains("佩之不迷")
	_assert_history_contains("佩戴迷穀")
	_assert_true(
		migu_label != null and migu_label.text.contains("已佩戴"),
		"equipped migu should show equipped state"
	)
	demo.call("_update_prompt")
	_assert_prompt_not_contains("按 E 佩戴迷穀")

	demo.call("_update_navigation_state")
	_assert_navigation_status_contains("迷穀归向：")
	_assert_navigation_status_has_direction()
	var first_guidance := _navigation_status_text()
	player.position = origin + Vector2(420.0, 120.0)
	demo.call("_update_navigation_state")
	var moved_guidance := _navigation_status_text()
	_assert_true(
		first_guidance != moved_guidance,
		"migu direction guidance should update after player movement"
	)
	_assert_navigation_status_has_direction()

	player.position = origin
	demo.call("_update_navigation_state")
	_assert_navigation_status_contains("已接近起点")
	_assert_true(
		demo.call("_format_eight_direction", Vector2.ZERO) == "原地",
		"zero-length direction should be handled safely"
	)
	_assert_true(demo.call("_format_eight_direction", Vector2.RIGHT) == "东", "right should map east")
	_assert_true(demo.call("_format_eight_direction", Vector2.UP) == "北", "up should map north")
	_assert_true(demo.call("_format_eight_direction", Vector2.LEFT) == "西", "left should map west")
	_assert_true(demo.call("_format_eight_direction", Vector2.DOWN) == "南", "down should map south")
	_assert_true(
		demo.call("_format_eight_direction", Vector2(-1.0, -1.0)) == "西北",
		"up-left should map northwest"
	)

	player.position = origin + Vector2(420.0, 120.0)
	demo.call("_update_navigation_state")
	var equipped_state_value: Variant = demo.call("_build_demo_save_state")
	_assert_true(equipped_state_value is Dictionary, "equipped migu state should be serializable")
	if not (equipped_state_value is Dictionary):
		return
	var equipped_state: Dictionary = equipped_state_value
	var navigation_data: Variant = equipped_state.get("navigation", {})
	var knowledge_data: Variant = equipped_state.get("knowledge", {})
	_assert_true(navigation_data is Dictionary, "save should include navigation state")
	_assert_true(knowledge_data is Dictionary, "save should include knowledge state")
	if navigation_data is Dictionary:
		_assert_true(
			navigation_data.get("migu_equipped", false) == true,
			"save should persist migu equipped state"
		)
		_assert_true(
			navigation_data.get("origin_position", {}) is Dictionary,
			"save should persist navigation origin"
		)
	if knowledge_data is Dictionary:
		_assert_true(knowledge_data.get("migu", {}) is Dictionary, "save should include knowledge.migu")
		_assert_true(knowledge_data.get("zhuyu", {}) is Dictionary, "save should preserve knowledge.zhuyu")

	demo.call("_reset_demo_state")
	var equipped_load_result: Variant = demo.call("_apply_demo_save_state", equipped_state)
	_assert_true(equipped_load_result == true, "equipped migu state should load")
	_assert_vec2_near(
		demo.get("demo_origin_position"),
		origin,
		"load should restore navigation origin"
	)
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, true)
	_assert_true(demo.get("migu_equipped") == true, "load should restore equipped migu")
	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, true)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_navigation_status_contains("迷穀归向：")

	var legacy_state: Dictionary = equipped_state.duplicate(true)
	legacy_state["version"] = 2
	legacy_state.erase("navigation")
	var legacy_knowledge_value: Variant = legacy_state.get("knowledge", {})
	if legacy_knowledge_value is Dictionary:
		var legacy_knowledge: Dictionary = legacy_knowledge_value
		legacy_knowledge.erase("migu")
		legacy_state["knowledge"] = legacy_knowledge
	demo.call("_reset_demo_state")
	var legacy_result: Variant = demo.call("_apply_demo_save_state", legacy_state)
	_assert_true(legacy_result == true, "legacy save without migu navigation fields should load")
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, true)
	_assert_true(demo.get("migu_equipped") == false, "legacy save should default migu to unequipped")
	_assert_vec2_near(
		demo.get("demo_origin_position"),
		initial_position,
		"legacy save should default origin to player spawn"
	)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_navigation_status_not_contains("迷穀归向：")

	demo.call("_reset_demo_state")


func _force_state_after_stone_activation() -> void:
	demo.call("_reset_demo_state")

	var zhuyu_result: Variant = demo.call("_on_zhuyu_interacted", OWNER_ID, ZHUYU_INTERACTABLE_ID, {
		"item_id": ITEM_ID,
		"count": 1
	})
	_assert_true(zhuyu_result == true, "zhuyu interaction should succeed")

	var eat_result: Variant = demo.call("_eat_zhuyu")
	_assert_true(eat_result == true, "zhuyu eating should succeed")

	var stone_result: Variant = demo.call("_on_guidance_stone_interacted", OWNER_ID, STONE_INTERACTABLE_ID, {
		"target": "guidance_stone"
	})
	_assert_true(stone_result == true, "guidance stone interaction should succeed")


func _force_state_complete() -> void:
	if demo.get("current_step") != STEP_OBSERVE_SHENSHENG:
		_force_state_after_stone_activation()

	var shensheng_result: Variant = demo.call("_on_shensheng_interacted", OWNER_ID, SHENSHENG_INTERACTABLE_ID, {
		"creature_id": CREATURE_ID
	})
	_assert_true(shensheng_result == true, "shensheng interaction should succeed")


func _force_optional_complete() -> void:
	if demo.get("current_step") != STEP_COMPLETE:
		_force_state_complete()

	var migu_result: Variant = demo.call("_on_optional_collectible_interacted", OWNER_ID, MIGU_BRANCH_INTERACTABLE_ID, {
		"item_id": MIGU_BRANCH_ITEM_ID,
		"count": 1
	})
	_assert_true(migu_result == true, "migu branch interaction should succeed")

	var basic_ore_result: Variant = demo.call("_on_optional_collectible_interacted", OWNER_ID, BASIC_ORE_INTERACTABLE_ID, {
		"item_id": BASIC_ORE_ITEM_ID,
		"count": 1
	})
	_assert_true(basic_ore_result == true, "basic ore interaction should succeed")

	var lushu_result: Variant = demo.call("_on_optional_creature_interacted", OWNER_ID, LUSHU_INTERACTABLE_ID, {
		"creature_id": LUSHU_CREATURE_ID
	})
	_assert_true(lushu_result == true, "lushu interaction should succeed")

	var generic_beast_result: Variant = demo.call("_on_optional_creature_interacted", OWNER_ID, GENERIC_BEAST_INTERACTABLE_ID, {
		"creature_id": GENERIC_BEAST_CREATURE_ID
	})
	_assert_true(generic_beast_result == true, "generic beast interaction should succeed")


func _force_one_optional_collectible_complete() -> void:
	if demo.get("current_step") != STEP_COMPLETE:
		_force_state_complete()

	var migu_result: Variant = demo.call("_on_optional_collectible_interacted", OWNER_ID, MIGU_BRANCH_INTERACTABLE_ID, {
		"item_id": MIGU_BRANCH_ITEM_ID,
		"count": 1
	})
	_assert_true(migu_result == true, "migu branch interaction should succeed")


func _assert_state_after_stone_activation() -> void:
	_assert_true(demo.get("current_step") == STEP_OBSERVE_SHENSHENG, "current_step should restore OBSERVE_SHENSHENG")
	_assert_true(demo.get("zhuyu_collected") == true, "zhuyu should be collected")
	_assert_true(demo.get("zhuyu_consumed") == true, "zhuyu should be consumed")
	_assert_true(demo.get("stone_activated") == true, "guidance stone should be activated")
	_assert_true(demo.get("shensheng_discovered") == false, "shensheng should not be discovered before completion")
	_assert_optional_state_pending()

	var zhuyu_pickup := demo.get_node_or_null("WorldRoot/ZhuyuPickup")
	var guidance_stone_label := demo.get_node_or_null("WorldRoot/GuidanceStoneLabel")
	var shensheng_label := demo.get_node_or_null("WorldRoot/ShenshengLabel")
	var status_label := demo.get_node_or_null("CanvasLayer/StatusLabel")

	_assert_true(zhuyu_pickup != null and zhuyu_pickup.visible == false, "ZhuyuPickup should stay hidden after load")
	_assert_true(guidance_stone_label != null and guidance_stone_label.text.contains("已激活"), "GuidanceStoneLabel should show activated state")
	_assert_true(shensheng_label != null and shensheng_label.text == "狌狌", "ShenshengLabel should stay undiscovered before completion")
	_assert_true(status_label != null and status_label.text.contains(ITEM_ID), "StatusLabel should include zhuyu item")

	_assert_inventory_count(0)
	_assert_bestiary_has_item(true)
	_assert_bestiary_has_creature(false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, true)
	_assert_survival_status("食之不饥")


func _assert_state_complete() -> void:
	_assert_true(demo.get("current_step") == STEP_COMPLETE, "current_step should restore COMPLETE")
	_assert_true(demo.get("zhuyu_collected") == true, "zhuyu should remain collected in complete state")
	_assert_true(demo.get("stone_activated") == true, "guidance stone should remain activated in complete state")
	_assert_true(demo.get("shensheng_discovered") == true, "shensheng should be discovered in complete state")

	var shensheng_label := demo.get_node_or_null("WorldRoot/ShenshengLabel")
	var status_label := demo.get_node_or_null("CanvasLayer/StatusLabel")
	var target_hint_label := demo.get_node_or_null("CanvasLayer/TargetHintLabel")
	var completion_summary_label := demo.get_node_or_null("CanvasLayer/CompletionPanel/CompletionSummaryLabel")

	_assert_true(shensheng_label != null and shensheng_label.text.contains("已发现"), "ShenshengLabel should show discovered state")
	_assert_true(status_label != null and status_label.text.contains(CREATURE_ID), "StatusLabel should include shensheng creature")
	var target_hint_text := ""
	if target_hint_label != null:
		target_hint_text = target_hint_label.text
	_assert_true(target_hint_label != null and (target_hint_text.contains("可选探索") or target_hint_text.contains("所有 Demo 内容已完成")), "TargetHintLabel should show completion")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("历史记录"), "Completion summary should include history")

	_assert_inventory_count(0)
	_assert_bestiary_has_item(true)
	_assert_bestiary_has_creature(true)


func _assert_optional_state_pending() -> void:
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, false)
	_assert_optional_done(BASIC_ORE_ITEM_ID, false)
	_assert_optional_done(LUSHU_CREATURE_ID, false)
	_assert_optional_done(GENERIC_BEAST_CREATURE_ID, false)
	_assert_journal_recent("无")
	_assert_journal_optional_state_pending()
	_assert_true(demo.get("migu_equipped") == false, "pending optional state should not equip migu")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)

	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel")
	var basic_ore_label := demo.get_node_or_null("WorldRoot/BasicOreLabel")
	var lushu_label := demo.get_node_or_null("WorldRoot/LushuLabel")
	var generic_beast_label := demo.get_node_or_null("WorldRoot/GenericBeastLabel")

	_assert_true(
		migu_label != null and migu_label.text == "陌生黑理发光之木",
		"MiguBranchLabel should show unknown initial state"
	)
	_assert_true(basic_ore_label != null and basic_ore_label.text == "粗矿石", "BasicOreLabel should show initial state")
	_assert_true(lushu_label != null and lushu_label.text == "鹿蜀", "LushuLabel should show initial state")
	_assert_true(generic_beast_label != null and generic_beast_label.text == "普通野兽", "GenericBeastLabel should show initial state")

	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 0)
	_assert_inventory_item_count(BASIC_ORE_ITEM_ID, 0)
	_assert_bestiary_has_item_id(MIGU_BRANCH_ITEM_ID, false)
	_assert_bestiary_has_item_id(BASIC_ORE_ITEM_ID, false)
	_assert_bestiary_has_creature_id(LUSHU_CREATURE_ID, false)
	_assert_bestiary_has_creature_id(GENERIC_BEAST_CREATURE_ID, false)


func _assert_optional_state_complete() -> void:
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, true)
	_assert_optional_done(BASIC_ORE_ITEM_ID, true)
	_assert_optional_done(LUSHU_CREATURE_ID, true)
	_assert_optional_done(GENERIC_BEAST_CREATURE_ID, true)
	_assert_journal_optional_state_complete()
	_assert_true(demo.get("migu_equipped") == false, "optional collection alone should not equip migu")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, true)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)

	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel")
	var basic_ore_label := demo.get_node_or_null("WorldRoot/BasicOreLabel")
	var lushu_label := demo.get_node_or_null("WorldRoot/LushuLabel")
	var generic_beast_label := demo.get_node_or_null("WorldRoot/GenericBeastLabel")
	var status_label := demo.get_node_or_null("CanvasLayer/StatusLabel")
	var target_hint_label := demo.get_node_or_null("CanvasLayer/TargetHintLabel")
	var completion_summary_label := demo.get_node_or_null("CanvasLayer/CompletionPanel/CompletionSummaryLabel")

	_assert_true(migu_label != null and migu_label.text.contains("已采集"), "MiguBranchLabel should show collected state")
	_assert_true(basic_ore_label != null and basic_ore_label.text.contains("已采集"), "BasicOreLabel should show collected state")
	_assert_true(lushu_label != null and lushu_label.text.contains("已发现"), "LushuLabel should show discovered state")
	_assert_true(generic_beast_label != null and generic_beast_label.text.contains("已发现"), "GenericBeastLabel should show discovered state")
	_assert_true(status_label != null and status_label.text.contains(MIGU_BRANCH_ITEM_ID), "StatusLabel should include migu item")
	_assert_true(status_label != null and status_label.text.contains(BASIC_ORE_ITEM_ID), "StatusLabel should include basic ore item")
	_assert_true(status_label != null and status_label.text.contains(LUSHU_CREATURE_ID), "StatusLabel should include lushu creature")
	_assert_true(status_label != null and status_label.text.contains(GENERIC_BEAST_CREATURE_ID), "StatusLabel should include generic beast creature")
	_assert_true(target_hint_label != null and target_hint_label.text.contains("所有 Demo 内容已完成"), "TargetHintLabel should show optional completion")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已采集：迷穀枝"), "Completion summary should include migu")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已采集：粗矿石"), "Completion summary should include basic ore")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已发现：鹿蜀"), "Completion summary should include lushu")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已发现：普通野兽"), "Completion summary should include generic beast")

	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	_assert_inventory_item_count(BASIC_ORE_ITEM_ID, 1)
	_assert_bestiary_has_item_id(MIGU_BRANCH_ITEM_ID, true)
	_assert_bestiary_has_item_id(BASIC_ORE_ITEM_ID, true)
	_assert_bestiary_has_creature_id(LUSHU_CREATURE_ID, true)
	_assert_bestiary_has_creature_id(GENERIC_BEAST_CREATURE_ID, true)


func _assert_legacy_optional_save_compatibility() -> void:
	demo.call("_reset_demo_state")

	var legacy_position := initial_position + Vector2(180.0, 140.0)
	var legacy_state := {
		"version": 1,
		"owner_id": OWNER_ID,
		"current_step": STEP_COMPLETE,
		"world": {
			"pickup_collected": true,
			"stone_activated": true,
			"creature_discovered": true,
			"migu_collected": true,
			"lushu_discovered": true
		},
		"player": {
			"position": {
				"x": legacy_position.x,
				"y": legacy_position.y
			}
		},
		"inventory": {
			ITEM_ID: 1,
			MIGU_BRANCH_ITEM_ID: 1
		},
		"bestiary": {
			"items": [
				ITEM_ID,
				MIGU_BRANCH_ITEM_ID
			],
			"creatures": [
				CREATURE_ID,
				LUSHU_CREATURE_ID
			]
		},
		"history": [
			"legacy optional save"
		]
	}

	var legacy_result: Variant = demo.call("_apply_demo_save_state", legacy_state)
	_assert_true(legacy_result == true, "legacy optional save state should load")
	_assert_vec2_near(player.position, legacy_position, "legacy optional save should restore player position")
	_assert_true(demo.get("zhuyu_consumed") == true, "legacy complete save should infer consumed zhuyu")
	_assert_float_near(
		float(demo.get("demo_hunger")),
		DEMO_HUNGER_MAX,
		"legacy optional save should default hunger to maximum"
	)
	_assert_float_near(
		float(demo.get("zhuyu_satiety_remaining")),
		0.0,
		"legacy optional save should default satiety to zero"
	)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_APPEARANCE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_TYPE, false)
	_assert_zhuyu_knowledge(ZHUYU_KNOWLEDGE_EFFECT, false)
	_assert_true(demo.get("migu_equipped") == false, "legacy optional save should default migu to unequipped")
	_assert_migu_knowledge(MIGU_KNOWLEDGE_APPEARANCE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_TYPE, false)
	_assert_migu_knowledge(MIGU_KNOWLEDGE_EFFECT, false)
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, true)
	_assert_optional_done(LUSHU_CREATURE_ID, true)
	_assert_optional_done(BASIC_ORE_ITEM_ID, false)
	_assert_optional_done(GENERIC_BEAST_CREATURE_ID, false)
	_assert_journal_status("迷穀枝", "已完成")
	_assert_journal_status("粗矿石", "未完成")
	_assert_journal_status("鹿蜀", "已完成")
	_assert_journal_status("普通野兽", "未完成")
	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	_assert_inventory_item_count(BASIC_ORE_ITEM_ID, 0)
	_assert_bestiary_has_item_id(MIGU_BRANCH_ITEM_ID, true)
	_assert_bestiary_has_item_id(BASIC_ORE_ITEM_ID, false)
	_assert_bestiary_has_creature_id(LUSHU_CREATURE_ID, true)
	_assert_bestiary_has_creature_id(GENERIC_BEAST_CREATURE_ID, false)


func _assert_journal_optional_state_pending() -> void:
	_ensure_detail_journal_view()
	_assert_journal_status("迷穀枝", "未完成")
	_assert_journal_status("粗矿石", "未完成")
	_assert_journal_status("鹿蜀", "未完成")
	_assert_journal_status("普通野兽", "未完成")
	_assert_journal_progress(0, _optional_total_count())
	_assert_journal_section_progress("可选采集物", 0, _optional_collectible_count())
	_assert_journal_section_progress("可选生物 / 互动", 0, _optional_creature_count())


func _assert_journal_optional_state_complete() -> void:
	_ensure_detail_journal_view()
	_assert_journal_status("迷穀枝", "已完成")
	_assert_journal_status("粗矿石", "已完成")
	_assert_journal_status("鹿蜀", "已完成")
	_assert_journal_status("普通野兽", "已完成")
	_assert_journal_progress(_optional_total_count(), _optional_total_count())
	_assert_journal_section_progress("可选采集物", _optional_collectible_count(), _optional_collectible_count())
	_assert_journal_section_progress("可选生物 / 互动", _optional_creature_count(), _optional_creature_count())


func _assert_journal_status(display_name: String, expected_status: String) -> void:
	var journal_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressJournalLabel")
	_assert_true(journal_label != null, "optional progress journal label must exist")
	if journal_label == null:
		return

	var expected_text := "%s：%s" % [display_name, expected_status]
	_assert_true(journal_label.text.contains(expected_text), "journal should contain %s, actual=%s" % [expected_text, journal_label.text])


func _assert_shensheng_idle_pipeline() -> void:
	var shensheng := demo.get_node_or_null("WorldRoot/ShenshengCreature") as Polygon2D
	var shensheng_sprite := demo.get_node_or_null(
		"WorldRoot/ShenshengCreature/ShenshengSprite"
	) as AnimatedSprite2D
	_assert_true(shensheng != null, "Shensheng interaction Polygon2D must exist")
	_assert_true(shensheng_sprite != null, "Shensheng AnimatedSprite2D must exist")
	_assert_true(
		ResourceLoader.exists(SHENSHENG_SPRITE_SHEET_PATH),
		"Shensheng idle sprite sheet resource path must exist"
	)
	if shensheng == null or shensheng_sprite == null:
		return

	_assert_true(
		shensheng.position == SHENSHENG_EXPECTED_POSITION,
		"Shensheng interaction position must remain unchanged"
	)
	_assert_true(
		shensheng.color.a <= 0.05,
		"Shensheng Polygon2D fallback must remain visually hidden"
	)
	_assert_true(shensheng_sprite.visible, "Shensheng AnimatedSprite2D must be visible")
	_assert_true(
		shensheng_sprite.is_visible_in_tree(),
		"Shensheng AnimatedSprite2D must be visible in the scene tree"
	)
	_assert_true(
		shensheng_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"Shensheng sprite must use linear filtering for non-pixel art"
	)
	_assert_true(
		shensheng_sprite.centered,
		"Shensheng sprite must use a stable centered canvas anchor"
	)
	_assert_true(
		shensheng_sprite.offset == Vector2.ZERO,
		"Shensheng sprite offset must remain constant"
	)
	_assert_true(
		shensheng_sprite.scale == Vector2(0.24, 0.24),
		"Shensheng sprite must remain readable without dominating the demo"
	)
	_assert_true(
		shensheng_sprite.z_index > shensheng.z_index,
		"Shensheng sprite must render above its Polygon2D fallback"
	)
	var rendered_feet_y := (
		shensheng_sprite.position.y
		+ float(SHENSHENG_FEET_BASELINE_Y - SHENSHENG_FRAME_SIZE.y / 2)
		* shensheng_sprite.scale.y
	)
	_assert_true(
		is_equal_approx(rendered_feet_y, 30.0),
		"Shensheng frame anchor must preserve the original interaction footprint"
	)

	var sprite_frames := shensheng_sprite.sprite_frames
	_assert_true(sprite_frames != null, "Shensheng sprite frames must exist")
	if sprite_frames == null:
		return
	_assert_true(
		sprite_frames.get_animation_names().size() == 1,
		"Shensheng SpriteFrames must remain idle-only"
	)
	_assert_true(sprite_frames.has_animation(&"idle"), "Shensheng sprite frames must include idle")
	_assert_true(
		sprite_frames.get_frame_count(&"idle") == SHENSHENG_IDLE_FRAME_COUNT,
		"Shensheng idle must contain exactly %d frames" % SHENSHENG_IDLE_FRAME_COUNT
	)
	var idle_fps := sprite_frames.get_animation_speed(&"idle")
	_assert_true(
		idle_fps >= SHENSHENG_IDLE_FPS_MIN and idle_fps <= SHENSHENG_IDLE_FPS_MAX,
		"Shensheng idle FPS must stay between %.1f and %.1f" % [
			SHENSHENG_IDLE_FPS_MIN,
			SHENSHENG_IDLE_FPS_MAX
		]
	)
	_assert_true(sprite_frames.get_animation_loop(&"idle"), "Shensheng idle animation must loop")
	_assert_true(shensheng_sprite.animation == &"idle", "Shensheng must select the idle animation")
	_assert_true(shensheng_sprite.is_playing(), "Shensheng idle animation must autoplay")

	for frame_index in SHENSHENG_IDLE_FRAME_COUNT:
		var frame_texture := sprite_frames.get_frame_texture(&"idle", frame_index) as AtlasTexture
		_assert_true(
			frame_texture != null,
			"Shensheng idle frame %d must use an AtlasTexture" % frame_index
		)
		if frame_texture == null:
			continue
		_assert_true(
			frame_texture.atlas != null
			and frame_texture.atlas.resource_path == SHENSHENG_SPRITE_SHEET_PATH,
			"Shensheng idle frame %d must use the generated sprite sheet" % frame_index
		)
		_assert_true(
			frame_texture.region
			== Rect2(
				frame_index * SHENSHENG_FRAME_SIZE.x,
				0,
				SHENSHENG_FRAME_SIZE.x,
				SHENSHENG_FRAME_SIZE.y
			),
			"Shensheng idle frame %d must use the expected 512x512 atlas region" % frame_index
		)

	_assert_shensheng_idle_metadata(sprite_frames)
	_assert_shensheng_sprite_sheet_readability()


func _assert_shensheng_idle_metadata(sprite_frames: SpriteFrames) -> void:
	var metadata_path := ProjectSettings.globalize_path(SHENSHENG_IDLE_METADATA_PATH)
	_assert_true(FileAccess.file_exists(metadata_path), "Shensheng idle metadata must exist")
	if not FileAccess.file_exists(metadata_path):
		return

	var parsed_metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	_assert_true(parsed_metadata is Dictionary, "Shensheng idle metadata must be a Dictionary")
	if not (parsed_metadata is Dictionary):
		return
	var metadata: Dictionary = parsed_metadata
	_assert_true(
		metadata.get("design") == "art_guided_shensheng_idle",
		"Shensheng metadata must declare the art-guided idle design"
	)
	_assert_true(
		metadata.get("art_source") == "deterministic_programmatic_demo_local",
		"Shensheng art must remain deterministic and demo-local"
	)
	_assert_true(
		int(metadata.get("frame_width", 0)) == SHENSHENG_FRAME_SIZE.x
		and int(metadata.get("frame_height", 0)) == SHENSHENG_FRAME_SIZE.y,
		"Shensheng metadata canvas must remain 512x512"
	)
	_assert_true(
		int(metadata.get("idle_frame_count", 0)) == SHENSHENG_IDLE_FRAME_COUNT,
		"Shensheng metadata frame count must match SpriteFrames"
	)
	_assert_true(
		is_equal_approx(
			float(metadata.get("idle_fps", 0.0)),
			sprite_frames.get_animation_speed(&"idle")
		),
		"Shensheng metadata FPS must match SpriteFrames"
	)
	var anchor: Variant = metadata.get("anchor", [])
	_assert_true(
		anchor is Array
		and anchor.size() == 2
		and int(anchor[0]) == SHENSHENG_FRAME_SIZE.x / 2
		and int(anchor[1]) == SHENSHENG_FEET_BASELINE_Y,
		"Shensheng metadata must declare the shared feet-center anchor"
	)

	var visual_traits: Variant = metadata.get("visual_traits", [])
	_assert_true(visual_traits is Array, "Shensheng visual traits must be an Array")
	if visual_traits is Array:
		for expected_trait in [
			"white_ears",
			"humanlike_face",
			"beast_muzzle",
			"ape_body",
			"semi_crouched_posture",
			"forward_shoulders",
			"long_arms",
			"dark_teal_grey_fur",
			"cinnabar_markings",
			"cyan_eye_and_mark_glow"
		]:
			_assert_true(
				visual_traits.has(expected_trait),
				"Shensheng metadata must include %s" % expected_trait
			)

	var moving_elements: Variant = metadata.get("moving_elements", [])
	_assert_true(moving_elements is Array, "Shensheng moving elements must be an Array")
	if moving_elements is Array:
		for expected_element in [
			"breathing",
			"shoulders",
			"ears",
			"arms",
			"cyan_glow",
			"shadow"
		]:
			_assert_true(
				moving_elements.has(expected_element),
				"Shensheng metadata must include %s motion" % expected_element
			)

	var frames: Variant = metadata.get("frames", [])
	_assert_true(frames is Array, "Shensheng metadata frames must be an Array")
	if not (frames is Array) or frames.size() != SHENSHENG_IDLE_FRAME_COUNT:
		_assert_true(false, "Shensheng metadata must contain six idle frames")
		return

	var has_breathing := false
	var has_ear_motion := false
	var has_arm_follow_through := false
	var minimum_glow := INF
	var maximum_glow := -INF
	for frame_index in SHENSHENG_IDLE_FRAME_COUNT:
		var frame: Variant = frames[frame_index]
		_assert_true(
			frame is Dictionary,
			"Shensheng metadata frame %d must be a Dictionary" % frame_index
		)
		if not (frame is Dictionary):
			continue
		var frame_anchor: Variant = frame.get("anchor", [])
		_assert_true(
			frame_anchor is Array
			and frame_anchor.size() == 2
			and int(frame_anchor[0]) == SHENSHENG_FRAME_SIZE.x / 2
			and int(frame_anchor[1]) == SHENSHENG_FEET_BASELINE_Y,
			"Shensheng metadata frame %d must keep the shared anchor" % frame_index
		)
		has_breathing = has_breathing or int(frame.get("body_y", 0)) != 0
		has_ear_motion = (
			has_ear_motion
			or int(frame.get("left_ear_offset", 0)) != 0
			or int(frame.get("right_ear_offset", 0)) != 0
		)
		has_arm_follow_through = (
			has_arm_follow_through or int(frame.get("arm_sway", 0)) != 0
		)
		var glow_alpha := float(frame.get("glow_alpha", 0.0))
		minimum_glow = min(minimum_glow, glow_alpha)
		maximum_glow = max(maximum_glow, glow_alpha)

		var next_frame: Dictionary = frames[
			(frame_index + 1) % SHENSHENG_IDLE_FRAME_COUNT
		]
		for parameter_name in [
			"body_y",
			"shoulder_y",
			"left_ear_offset",
			"right_ear_offset",
			"arm_sway"
		]:
			_assert_true(
				abs(
					float(frame.get(parameter_name, 0.0))
					- float(next_frame.get(parameter_name, 0.0))
				) <= 1.0,
				"Shensheng %s must remain continuous after frame %d" % [
					parameter_name,
					frame_index
				]
			)
		_assert_true(
			abs(glow_alpha - float(next_frame.get("glow_alpha", 0.0))) <= 50.0,
			"Shensheng glow pulse must remain continuous after frame %d" % frame_index
		)
		_assert_true(
			abs(
				float(frame.get("shadow_scale", 1.0))
				- float(next_frame.get("shadow_scale", 1.0))
			) <= 0.03,
			"Shensheng shadow must remain continuous after frame %d" % frame_index
		)

	_assert_true(has_breathing, "Shensheng idle must include breathing motion")
	_assert_true(has_ear_motion, "Shensheng idle must include ear motion")
	_assert_true(has_arm_follow_through, "Shensheng idle must include arm follow-through")
	_assert_true(maximum_glow > minimum_glow, "Shensheng idle must include a cyan glow pulse")


func _assert_shensheng_sprite_sheet_readability() -> void:
	var sprite_sheet := Image.load_from_file(
		ProjectSettings.globalize_path(SHENSHENG_SPRITE_SHEET_PATH)
	)
	_assert_true(sprite_sheet != null, "Shensheng sprite sheet image must load")
	if sprite_sheet == null:
		return
	_assert_true(
		sprite_sheet.get_width() == SHENSHENG_FRAME_SIZE.x * SHENSHENG_IDLE_FRAME_COUNT,
		"Shensheng sprite sheet must contain six horizontal frames"
	)
	_assert_true(
		sprite_sheet.get_height() == SHENSHENG_FRAME_SIZE.y,
		"Shensheng sprite sheet frames must be 512 pixels tall"
	)
	_assert_true(
		sprite_sheet.get_format() == Image.FORMAT_RGBA8,
		"Shensheng sprite sheet must use RGBA8 transparency"
	)

	var frame_images: Array[Image] = []
	var frame_data: Array[PackedByteArray] = []
	var minimum_bounds_size := Vector2i(SHENSHENG_FRAME_SIZE.x, SHENSHENG_FRAME_SIZE.y)
	var maximum_bounds_size := Vector2i.ZERO
	for frame_index in SHENSHENG_IDLE_FRAME_COUNT:
		var frame_image := sprite_sheet.get_region(
			Rect2i(
				frame_index * SHENSHENG_FRAME_SIZE.x,
				0,
				SHENSHENG_FRAME_SIZE.x,
				SHENSHENG_FRAME_SIZE.y
			)
		)
		var used_rect := frame_image.get_used_rect()
		_assert_true(
			used_rect.size.x >= 300 and used_rect.size.y >= 330,
			"Shensheng frame %d must remain readable in the demo" % frame_index
		)
		_assert_true(
			used_rect.end.y == SHENSHENG_FEET_BASELINE_Y + 1,
			"Shensheng frame %d must share the configured feet baseline" % frame_index
		)
		_assert_true(
			used_rect.position.x > 0
			and used_rect.position.y > 0
			and used_rect.end.x < SHENSHENG_FRAME_SIZE.x
			and used_rect.end.y < SHENSHENG_FRAME_SIZE.y,
			"Shensheng frame %d must stay inside its transparent canvas" % frame_index
		)
		minimum_bounds_size.x = min(minimum_bounds_size.x, used_rect.size.x)
		minimum_bounds_size.y = min(minimum_bounds_size.y, used_rect.size.y)
		maximum_bounds_size.x = max(maximum_bounds_size.x, used_rect.size.x)
		maximum_bounds_size.y = max(maximum_bounds_size.y, used_rect.size.y)
		frame_images.append(frame_image)
		frame_data.append(frame_image.get_data())

	var bounds_spread := maximum_bounds_size - minimum_bounds_size
	_assert_true(
		bounds_spread.x <= 8 and bounds_spread.y <= 2,
		"Shensheng idle frame bounds must keep a stable canvas anchor"
	)
	var sprite_sheet_data := sprite_sheet.get_data()
	for alpha_index in range(3, sprite_sheet_data.size(), 4):
		var alpha := sprite_sheet_data[alpha_index]
		if alpha > 0 and alpha < SHENSHENG_EDGE_ALPHA_CUTOFF:
			_assert_true(false, "Shensheng cutout must not contain low-alpha matte residue")
			break

	for frame_index in SHENSHENG_IDLE_FRAME_COUNT:
		var next_frame_index := (frame_index + 1) % SHENSHENG_IDLE_FRAME_COUNT
		_assert_true(
			frame_data[frame_index] != frame_data[next_frame_index],
			"Shensheng idle frame %d must contain distinct motion" % frame_index
		)
		var alpha_delta := _normalized_alpha_difference(
			frame_images[frame_index],
			frame_images[next_frame_index]
		)
		_assert_true(
			alpha_delta <= SHENSHENG_MAX_NORMALIZED_ALPHA_DELTA,
			"Shensheng idle transition %d must remain continuous, actual alpha delta=%.4f" % [
				frame_index,
				alpha_delta
			]
		)


func _assert_player_animation_pipeline() -> void:
	var player_sprite := demo.get_node_or_null("WorldRoot/Player/PlayerSprite") as AnimatedSprite2D
	var animation_state_machine := _get_player_animation_state_machine()
	_assert_true(player_sprite != null, "player AnimatedSprite2D must exist")
	_assert_true(animation_state_machine != null, "player animation state machine must exist")
	_assert_true(ResourceLoader.exists(PLAYER_SPRITE_SHEET_PATH), "player sprite sheet resource path must exist")
	if player_sprite == null or animation_state_machine == null:
		return
	_assert_true(player_sprite.visible, "player AnimatedSprite2D must be visible")
	_assert_true(player_sprite.is_visible_in_tree(), "player AnimatedSprite2D must be visible in the scene tree")
	_assert_true(
		player_sprite.scale.x >= 0.18 and player_sprite.scale.y >= 0.18,
		"player sprite must be large enough to remain readable in the demo"
	)
	_assert_true(
		player_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"player sprite must use linear filtering for non-pixel art"
	)
	_assert_true(player_sprite.centered, "player sprite must use a stable centered canvas anchor")
	_assert_true(player_sprite.offset == Vector2.ZERO, "player sprite offset must remain constant across animations")
	var polygon_fallback := player as Polygon2D
	_assert_true(polygon_fallback != null, "player Polygon2D fallback must exist")
	if polygon_fallback != null:
		_assert_true(
			polygon_fallback.color.a <= 0.05,
			"player Polygon2D fallback must remain visually hidden"
		)
		_assert_true(
			player_sprite.z_index > polygon_fallback.z_index,
			"player sprite must render above the Polygon2D fallback"
		)

	var sprite_frames := player_sprite.sprite_frames
	_assert_true(sprite_frames != null, "player sprite frames must exist")
	if sprite_frames == null:
		return

	_assert_true(sprite_frames.has_animation(&"idle"), "player sprite frames must include idle")
	_assert_true(sprite_frames.has_animation(&"walk"), "player sprite frames must include walk")
	_assert_true(
		sprite_frames.get_frame_count(&"idle") == PLAYER_IDLE_FRAME_COUNT,
		"idle animation must include exactly %d frames" % PLAYER_IDLE_FRAME_COUNT
	)
	_assert_true(
		sprite_frames.get_frame_count(&"walk") == PLAYER_WALK_FRAME_COUNT,
		"walk animation must include exactly %d frames" % PLAYER_WALK_FRAME_COUNT
	)
	var walk_fps := sprite_frames.get_animation_speed(&"walk")
	_assert_true(
		walk_fps >= PLAYER_WALK_FPS_MIN and walk_fps <= PLAYER_WALK_FPS_MAX,
		"walk animation FPS must stay between %.1f and %.1f" % [PLAYER_WALK_FPS_MIN, PLAYER_WALK_FPS_MAX]
	)
	_assert_true(sprite_frames.get_animation_loop(&"walk"), "walk animation must loop")
	_assert_stylized_robe_walk_metadata(sprite_frames)
	_assert_animation_frame_sources(sprite_frames, &"idle")
	_assert_animation_frame_sources(sprite_frames, &"walk")
	_assert_player_sprite_sheet_readability()

	_assert_player_animation_state(PLAYER_ANIMATION_STATE_IDLE, &"idle")
	_assert_player_facing(PLAYER_FACING_RIGHT, true, "initial facing")
	_assert_true(player_sprite.is_playing(), "player idle animation should be playing initially")

	animation_state_machine.call("set_movement_vector", Vector2.RIGHT)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_WALK, &"walk")
	_assert_player_facing(PLAYER_FACING_RIGHT, true, "right movement")
	var walk_play_count := int(animation_state_machine.get("animation_play_count"))
	animation_state_machine.call("set_movement_vector", Vector2.RIGHT)
	_assert_true(
		int(animation_state_machine.get("animation_play_count")) == walk_play_count,
		"setting the same movement state should not restart the walk animation"
	)

	animation_state_machine.call("set_movement_vector", Vector2.LEFT)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_WALK, &"walk")
	_assert_player_facing(PLAYER_FACING_LEFT, false, "left movement")
	_assert_true(
		int(animation_state_machine.get("animation_play_count")) == walk_play_count,
		"changing facing direction should not restart the walk animation"
	)

	animation_state_machine.call("set_movement_vector", Vector2.ZERO)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_IDLE, &"idle")
	_assert_player_facing(PLAYER_FACING_LEFT, false, "stopping should preserve left facing")

	animation_state_machine.call("set_movement_vector", Vector2.UP)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_WALK, &"walk")
	_assert_player_facing(PLAYER_FACING_LEFT, false, "up movement should preserve horizontal facing")
	walk_play_count = int(animation_state_machine.get("animation_play_count"))
	animation_state_machine.call("set_movement_vector", Vector2.DOWN)
	_assert_player_facing(PLAYER_FACING_LEFT, false, "down movement should preserve horizontal facing")
	_assert_true(
		int(animation_state_machine.get("animation_play_count")) == walk_play_count,
		"vertical movement should not restart the current walk animation"
	)

	animation_state_machine.call("set_movement_vector", Vector2.ZERO)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_IDLE, &"idle")
	_assert_player_facing(PLAYER_FACING_LEFT, false, "vertical stop should preserve horizontal facing")
	animation_state_machine.call("reset_to_idle")
	_assert_player_facing(PLAYER_FACING_RIGHT, true, "animation reset should restore default facing")
	_assert_player_animation_save_fields_absent()


func _assert_stylized_robe_walk_metadata(sprite_frames: SpriteFrames) -> void:
	var metadata_path := ProjectSettings.globalize_path(PLAYER_WALK_METADATA_PATH)
	_assert_true(FileAccess.file_exists(metadata_path), "stylized robe walk metadata must exist")
	if not FileAccess.file_exists(metadata_path):
		return

	var parsed_metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	_assert_true(parsed_metadata is Dictionary, "stylized robe walk metadata must be a Dictionary")
	if not (parsed_metadata is Dictionary):
		return
	var metadata: Dictionary = parsed_metadata
	_assert_true(metadata.get("design") == "stylized_robe_walk", "walk metadata must declare stylized robe design")
	_assert_true(metadata.get("robe_dominant") == true, "walk metadata must declare robe-dominant motion")
	_assert_true(
		metadata.get("leg_style") == "robe_hidden_with_subtle_foot_tips",
		"walk metadata must hide awkward leg poses behind the robe"
	)
	_assert_true(
		int(metadata.get("frame_width", 0)) == PLAYER_FRAME_SIZE.x
		and int(metadata.get("frame_height", 0)) == PLAYER_FRAME_SIZE.y,
		"walk metadata canvas must remain 512x512"
	)
	_assert_true(
		int(metadata.get("walk_frame_count", 0)) == PLAYER_WALK_FRAME_COUNT,
		"walk metadata frame count must match SpriteFrames"
	)
	_assert_true(
		is_equal_approx(
			float(metadata.get("walk_fps", 0.0)),
			sprite_frames.get_animation_speed(&"walk")
		),
		"walk metadata FPS must match SpriteFrames"
	)

	var moving_elements: Variant = metadata.get("moving_elements", [])
	_assert_true(moving_elements is Array, "walk metadata moving_elements must be an Array")
	if moving_elements is Array:
		for expected_element in ["torso", "robe", "sleeve", "talisman", "shadow"]:
			_assert_true(
				moving_elements.has(expected_element),
				"walk metadata must include %s motion" % expected_element
			)

	var frames: Variant = metadata.get("frames", [])
	_assert_true(frames is Array, "walk metadata frames must be an Array")
	if not (frames is Array):
		return
	_assert_true(frames.size() == PLAYER_WALK_FRAME_COUNT, "walk metadata must contain eight frames")
	if frames.size() != PLAYER_WALK_FRAME_COUNT:
		return

	var has_torso_motion := false
	var has_robe_motion := false
	var has_follow_through := false
	for frame_index in PLAYER_WALK_FRAME_COUNT:
		var frame: Variant = frames[frame_index]
		_assert_true(frame is Dictionary, "walk metadata frame %d must be a Dictionary" % frame_index)
		if not (frame is Dictionary):
			continue
		var feet_anchor: Variant = frame.get("feet_anchor", [])
		_assert_true(
			feet_anchor is Array
			and feet_anchor.size() == 2
			and int(feet_anchor[0]) == 256
			and int(feet_anchor[1]) == PLAYER_FEET_BASELINE_Y,
			"walk metadata frame %d must keep the shared feet anchor" % frame_index
		)
		_assert_true(abs(float(frame.get("torso_x", 99))) <= 2.0, "walk torso_x must stay subtle")
		_assert_true(abs(float(frame.get("torso_y", 99))) <= 5.0, "walk torso_y must stay subtle")
		_assert_true(abs(float(frame.get("foot_tip_shift", 99))) <= 2.0, "walk foot tips must stay subtle")
		has_torso_motion = has_torso_motion or float(frame.get("torso_y", 0.0)) != 0.0
		has_robe_motion = has_robe_motion or float(frame.get("robe_sway", 0.0)) != 0.0
		has_follow_through = (
			has_follow_through
			or float(frame.get("sleeve_sway", 0.0)) != 0.0
			or float(frame.get("talisman_x", 0.0)) != 0.0
			or float(frame.get("talisman_y", 0.0)) != 0.0
		)

		var next_frame: Dictionary = frames[(frame_index + 1) % PLAYER_WALK_FRAME_COUNT]
		_assert_true(
			abs(float(frame.get("torso_y", 0.0)) - float(next_frame.get("torso_y", 0.0))) <= 1.0,
			"walk torso bob must remain continuous after frame %d" % frame_index
		)
		_assert_true(
			abs(float(frame.get("robe_sway", 0.0)) - float(next_frame.get("robe_sway", 0.0))) <= 3.0,
			"walk robe sway must remain continuous after frame %d" % frame_index
		)
		_assert_true(
			abs(float(frame.get("shadow_offset", 0.0)) - float(next_frame.get("shadow_offset", 0.0))) <= 1.0,
			"walk shadow offset must remain continuous after frame %d" % frame_index
		)
		_assert_true(
			abs(float(frame.get("shadow_scale", 1.0)) - float(next_frame.get("shadow_scale", 1.0))) <= 0.05,
			"walk shadow scale must remain continuous after frame %d" % frame_index
		)

	_assert_true(has_torso_motion, "stylized robe walk must include non-zero upper-body motion")
	_assert_true(has_robe_motion, "stylized robe walk must include cyclic robe sway")
	_assert_true(has_follow_through, "stylized robe walk must include sleeve or talisman follow-through")


func _assert_animation_frame_sources(sprite_frames: SpriteFrames, animation_name: StringName) -> void:
	for frame_index in sprite_frames.get_frame_count(animation_name):
		var frame_texture := sprite_frames.get_frame_texture(animation_name, frame_index) as AtlasTexture
		_assert_true(frame_texture != null, "%s frame %d must use an AtlasTexture" % [animation_name, frame_index])
		if frame_texture == null:
			continue
		_assert_true(frame_texture.atlas != null, "%s frame %d must reference the sprite sheet" % [animation_name, frame_index])
		if frame_texture.atlas != null:
			_assert_true(
				frame_texture.atlas.resource_path == PLAYER_SPRITE_SHEET_PATH,
				"%s frame %d should use %s" % [animation_name, frame_index, PLAYER_SPRITE_SHEET_PATH]
			)
		_assert_true(
			frame_texture.region.size == Vector2(PLAYER_FRAME_SIZE.x, PLAYER_FRAME_SIZE.y),
			"%s frame %d must be 512x512" % [animation_name, frame_index]
		)


func _assert_player_sprite_sheet_readability() -> void:
	var sprite_sheet := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_SPRITE_SHEET_PATH))
	_assert_true(sprite_sheet != null, "player sprite sheet image must load")
	if sprite_sheet == null:
		return
	_assert_true(
		sprite_sheet.get_width() == PLAYER_FRAME_SIZE.x * PLAYER_TOTAL_FRAME_COUNT,
		"player sprite sheet must contain %d horizontal frames" % PLAYER_TOTAL_FRAME_COUNT
	)
	_assert_true(
		sprite_sheet.get_height() == PLAYER_FRAME_SIZE.y,
		"player sprite sheet frames must be 512 pixels tall"
	)
	_assert_true(sprite_sheet.get_format() == Image.FORMAT_RGBA8, "player sprite sheet must use RGBA8 transparency")

	var frame_data: Array[PackedByteArray] = []
	var frame_images: Array[Image] = []
	var used_rects: Array[Rect2i] = []
	for frame_index in PLAYER_TOTAL_FRAME_COUNT:
		var frame_image := sprite_sheet.get_region(
			Rect2i(frame_index * PLAYER_FRAME_SIZE.x, 0, PLAYER_FRAME_SIZE.x, PLAYER_FRAME_SIZE.y)
		)
		var used_rect := frame_image.get_used_rect()
		_assert_true(
			used_rect.size.x >= 240 and used_rect.size.y >= 400,
			"player frame %d must use enough canvas area to remain readable" % frame_index
		)
		_assert_true(
			used_rect.end.y == PLAYER_FEET_BASELINE_Y + 1,
			"player frame %d feet must share the configured baseline" % frame_index
		)
		_assert_true(
			used_rect.position.x > 0
			and used_rect.position.y > 0
			and used_rect.end.x < PLAYER_FRAME_SIZE.x
			and used_rect.end.y < PLAYER_FRAME_SIZE.y,
			"player frame %d cutout must stay inside its transparent canvas" % frame_index
		)
		frame_images.append(frame_image)
		used_rects.append(used_rect)
		frame_data.append(frame_image.get_data())

	_assert_true(
		abs(used_rects[0].position.x - used_rects[1].position.x) <= 1
		and used_rects[0].position.y == used_rects[1].position.y
		and used_rects[0].end == used_rects[1].end,
		"idle frame cutouts must share the same visual anchor"
	)

	var sprite_sheet_data := sprite_sheet.get_data()
	for alpha_index in range(3, sprite_sheet_data.size(), 4):
		var alpha := sprite_sheet_data[alpha_index]
		if alpha > 0 and alpha < PLAYER_EDGE_ALPHA_CUTOFF:
			_assert_true(false, "player sprite cutout must not contain low-alpha matte residue")
			break

	_assert_walk_frame_continuity(frame_images, used_rects)
	_assert_true(frame_data[0] != frame_data[1], "idle frames must contain visible motion or glow changes")
	for walk_frame_index in range(PLAYER_IDLE_FRAME_COUNT, PLAYER_TOTAL_FRAME_COUNT):
		_assert_true(
			frame_data[walk_frame_index] != frame_data[0] and frame_data[walk_frame_index] != frame_data[1],
			"walk frame %d must differ from idle frames" % (walk_frame_index - PLAYER_IDLE_FRAME_COUNT)
		)
		for previous_walk_frame_index in range(PLAYER_IDLE_FRAME_COUNT, walk_frame_index):
			_assert_true(
				frame_data[walk_frame_index] != frame_data[previous_walk_frame_index],
				"walk frame %d must differ from earlier walk frames" % (
					walk_frame_index - PLAYER_IDLE_FRAME_COUNT
				)
			)


func _assert_walk_frame_continuity(frame_images: Array[Image], used_rects: Array[Rect2i]) -> void:
	var min_body_center := Vector2(INF, INF)
	var max_body_center := Vector2(-INF, -INF)
	var min_bounds_size := Vector2i(PLAYER_FRAME_SIZE.x, PLAYER_FRAME_SIZE.y)
	var max_bounds_size := Vector2i.ZERO
	var walk_frames: Array[Image] = []

	for walk_index in PLAYER_WALK_FRAME_COUNT:
		var atlas_index := PLAYER_IDLE_FRAME_COUNT + walk_index
		var frame_image := frame_images[atlas_index]
		var body_center := _calculate_alpha_weighted_center(frame_image, PLAYER_BODY_CENTER_REGION)
		var bounds_size := used_rects[atlas_index].size
		min_body_center.x = min(min_body_center.x, body_center.x)
		min_body_center.y = min(min_body_center.y, body_center.y)
		max_body_center.x = max(max_body_center.x, body_center.x)
		max_body_center.y = max(max_body_center.y, body_center.y)
		min_bounds_size.x = min(min_bounds_size.x, bounds_size.x)
		min_bounds_size.y = min(min_bounds_size.y, bounds_size.y)
		max_bounds_size.x = max(max_bounds_size.x, bounds_size.x)
		max_bounds_size.y = max(max_bounds_size.y, bounds_size.y)
		walk_frames.append(frame_image)

	var body_center_spread := max_body_center - min_body_center
	_assert_true(
		body_center_spread.x <= PLAYER_BODY_CENTER_MAX_SPREAD.x
		and body_center_spread.y <= PLAYER_BODY_CENTER_MAX_SPREAD.y,
		"walk frame body centers must stay within the configured stability range"
	)
	var bounds_spread := max_bounds_size - min_bounds_size
	_assert_true(
		bounds_spread.x <= PLAYER_WALK_BOUNDS_MAX_SPREAD.x
		and bounds_spread.y <= PLAYER_WALK_BOUNDS_MAX_SPREAD.y,
		"walk frame bounding boxes must remain visually consistent"
	)

	for walk_index in PLAYER_WALK_FRAME_COUNT:
		var next_walk_index := (walk_index + 1) % PLAYER_WALK_FRAME_COUNT
		var alpha_delta := _normalized_alpha_difference(
			walk_frames[walk_index],
			walk_frames[next_walk_index]
		)
		_assert_true(
			alpha_delta <= PLAYER_WALK_MAX_NORMALIZED_ALPHA_DELTA,
			"walk frame %d transition must remain continuous, actual alpha delta=%.4f" % [
				walk_index,
				alpha_delta
			]
		)


func _calculate_alpha_weighted_center(frame_image: Image, region: Rect2i) -> Vector2:
	var weighted_position := Vector2.ZERO
	var total_alpha := 0.0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var alpha := frame_image.get_pixel(x, y).a
			weighted_position += Vector2(x, y) * alpha
			total_alpha += alpha
	_assert_true(total_alpha > 0.0, "walk frame body center region must contain visible pixels")
	if total_alpha <= 0.0:
		return Vector2.ZERO
	return weighted_position / total_alpha


func _normalized_alpha_difference(first_frame: Image, second_frame: Image) -> float:
	var first_data := first_frame.get_data()
	var second_data := second_frame.get_data()
	var alpha_difference := 0
	for alpha_index in range(3, first_data.size(), 4):
		alpha_difference += abs(int(first_data[alpha_index]) - int(second_data[alpha_index]))
	return float(alpha_difference) / float(PLAYER_FRAME_SIZE.x * PLAYER_FRAME_SIZE.y * 255)


func _assert_player_animation_state(expected_state: int, expected_animation: StringName) -> void:
	var player_sprite := demo.get_node_or_null("WorldRoot/Player/PlayerSprite") as AnimatedSprite2D
	var animation_state_machine := _get_player_animation_state_machine()
	if player_sprite == null or animation_state_machine == null:
		return

	_assert_true(
		int(animation_state_machine.get("current_state")) == expected_state,
		"player animation state should be %d" % expected_state
	)
	_assert_true(
		animation_state_machine.get("current_animation_name") == expected_animation,
		"player animation name should be %s" % expected_animation
	)
	_assert_true(
		player_sprite.animation == expected_animation,
		"AnimatedSprite2D should play %s" % expected_animation
	)


func _assert_player_facing(expected_direction: int, expected_flip_h: bool, context: String) -> void:
	var player_sprite := demo.get_node_or_null("WorldRoot/Player/PlayerSprite") as AnimatedSprite2D
	var animation_state_machine := _get_player_animation_state_machine()
	if player_sprite == null or animation_state_machine == null:
		return

	_assert_true(
		int(animation_state_machine.get("last_facing_direction")) == expected_direction,
		"%s should keep facing direction %d" % [context, expected_direction]
	)
	_assert_true(
		player_sprite.flip_h == expected_flip_h,
		"%s should set player flip_h to %s" % [context, expected_flip_h]
	)


func _assert_player_animation_save_fields_absent() -> void:
	var save_data: Variant = demo.call("get_save_data")
	_assert_true(save_data is Dictionary, "save data should be a Dictionary")
	if not (save_data is Dictionary):
		return

	_assert_true(not save_data.has("player_animation_state"), "save data should not persist player animation state")
	_assert_true(not save_data.has("current_animation_name"), "save data should not persist player animation name")
	_assert_true(not save_data.has("player_facing_direction"), "save data should not persist player facing direction")
	_assert_true(not save_data.has("last_facing_direction"), "save data should not persist last facing direction")
	var player_data: Variant = save_data.get("player", {})
	_assert_true(player_data is Dictionary, "player save data should be a Dictionary")
	if player_data is Dictionary:
		_assert_true(not player_data.has("animation_state"), "player save data should not persist animation state")
		_assert_true(not player_data.has("animation"), "player save data should not persist animation name")
		_assert_true(not player_data.has("facing_direction"), "player save data should not persist facing direction")


func _get_player_animation_state_machine() -> Node:
	var animation_state_machine := demo.get_node_or_null("WorldRoot/Player/PlayerAnimationStateMachine")
	_assert_true(animation_state_machine != null, "player animation state machine must exist")
	return animation_state_machine


func _assert_initial_journal_state() -> void:
	_ensure_detail_journal_view()
	_assert_shortcut_hint_label()
	_assert_journal_labels_separated()
	_assert_journal_progress(0, _optional_total_count())
	_assert_journal_section_progress("可选采集物", 0, _optional_collectible_count())
	_assert_journal_section_progress("可选生物 / 互动", 0, _optional_creature_count())
	_assert_journal_recent("无")
	_assert_journal_status("迷穀枝", "未完成")
	_assert_journal_status("粗矿石", "未完成")
	_assert_journal_status("鹿蜀", "未完成")
	_assert_journal_status("普通野兽", "未完成")
	_assert_compact_progress_view_hides_detail_items()
	_ensure_detail_journal_view()
	_assert_journal_save_fields_absent()


func _assert_journal_progress(completed_count: int, total_count: int) -> void:
	var journal_label := _get_journal_label()
	if journal_label == null:
		return

	var expected_text := "可选进度：%d / %d" % [completed_count, total_count]
	_assert_true(journal_label.text.contains(expected_text), "journal should contain %s, actual=%s" % [expected_text, journal_label.text])


func _assert_journal_section_progress(section_title: String, completed_count: int, total_count: int) -> void:
	var journal_label := _get_journal_label()
	if journal_label == null:
		return

	var expected_text := "%s：%d / %d" % [section_title, completed_count, total_count]
	_assert_true(journal_label.text.contains(expected_text), "journal should contain %s, actual=%s" % [expected_text, journal_label.text])


func _assert_journal_recent(expected_name: String) -> void:
	var journal_label := _get_journal_label()
	if journal_label == null:
		return

	var expected_text := "最近完成：%s" % expected_name
	_assert_true(journal_label.text.contains(expected_text), "journal should contain %s, actual=%s" % [expected_text, journal_label.text])


func _assert_compact_progress_view_hides_detail_items() -> void:
	_ensure_detail_journal_view()
	var toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressViewToggleButton")
	_assert_true(toggle_button != null, "optional progress view toggle button must exist")
	if toggle_button == null:
		return

	toggle_button.emit_signal("pressed")
	_assert_true(demo.get("optional_progress_detail_view") == false, "journal should switch to compact view")
	_assert_true(toggle_button.text == "详细视图", "compact journal toggle should offer detail view")
	_assert_journal_labels_separated()
	_assert_journal_progress(0, _optional_total_count())
	_assert_journal_section_progress("可选采集物", 0, _optional_collectible_count())
	_assert_journal_section_progress("可选生物 / 互动", 0, _optional_creature_count())

	var journal_label := _get_journal_label()
	if journal_label == null:
		return
	_assert_true(not journal_label.text.contains("- 迷穀枝："), "compact journal should not list migu item details")
	_assert_true(not journal_label.text.contains("- 粗矿石："), "compact journal should not list basic ore item details")
	_assert_true(not journal_label.text.contains("- 鹿蜀："), "compact journal should not list lushu details")
	_assert_true(not journal_label.text.contains("- 普通野兽："), "compact journal should not list generic beast details")


func _assert_progress_view_toggle_preserves_history(expected_entry: String) -> void:
	_ensure_detail_journal_view()
	var history_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/InteractionHistoryLabel")
	var toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressViewToggleButton")
	_assert_true(history_label != null, "interaction history label must exist")
	_assert_true(toggle_button != null, "optional progress view toggle button must exist")
	if history_label == null or toggle_button == null:
		return

	_assert_true(history_label.text.contains(expected_entry), "history label should contain %s before view toggle" % expected_entry)
	var history_text_before_toggle: String = history_label.text

	toggle_button.emit_signal("pressed")
	_assert_true(history_label.text == history_text_before_toggle, "history label text should not change in compact journal view")
	_assert_true(history_label.text.contains(expected_entry), "history label should preserve %s in compact journal view" % expected_entry)

	toggle_button.emit_signal("pressed")
	_assert_true(history_label.text == history_text_before_toggle, "history label text should not change after returning to detail journal view")
	_assert_true(history_label.text.contains(expected_entry), "history label should preserve %s after detail journal view returns" % expected_entry)


func _assert_journal_shortcut_handlers_preserve_text(expected_entry: String) -> void:
	_ensure_detail_journal_view()
	var history_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/InteractionHistoryLabel")
	var journal_label := _get_journal_label()
	var log_label := demo.get_node_or_null("CanvasLayer/LogLabel")
	_assert_true(history_label != null, "interaction history label must exist")
	_assert_true(log_label != null, "log label must exist")
	if history_label == null or journal_label == null or log_label == null:
		return

	var history_text_before_toggle: String = history_label.text
	var journal_text_before_toggle: String = journal_label.text
	var log_text_before_toggle: String = log_label.text

	demo.call("_on_interaction_history_toggle_pressed")
	_assert_history_panel_visible(false)
	_assert_true(history_label.text == history_text_before_toggle, "J shortcut handler should preserve history text while hidden")
	_assert_true(journal_label.text == journal_text_before_toggle, "J shortcut handler should preserve journal text while hidden")
	_assert_true(log_label.text == log_text_before_toggle, "J shortcut handler should preserve live log text while hidden")

	demo.call("_on_interaction_history_toggle_pressed")
	_assert_history_panel_visible(true)
	_assert_true(history_label.text.contains(expected_entry), "J shortcut handler should preserve %s after showing journal" % expected_entry)
	_assert_true(log_label.text == log_text_before_toggle, "J shortcut handler should preserve live log text after showing journal")

	demo.call("_on_optional_progress_view_toggle_pressed")
	_assert_true(demo.get("optional_progress_detail_view") == false, "V shortcut handler should switch to compact view")
	_assert_true(history_label.text == history_text_before_toggle, "V shortcut handler should not clear history")
	_assert_true(history_label.text.contains(expected_entry), "V shortcut handler should preserve %s in compact view" % expected_entry)

	demo.call("_on_optional_progress_view_toggle_pressed")
	_assert_true(demo.get("optional_progress_detail_view") == true, "V shortcut handler should switch back to detail view")
	_assert_true(history_label.text == history_text_before_toggle, "V shortcut handler should preserve history after returning to detail view")


func _assert_reset_preserves_compact_journal_view() -> void:
	_ensure_detail_journal_view()
	demo.call("_on_optional_progress_view_toggle_pressed")
	_assert_true(demo.get("optional_progress_detail_view") == false, "journal should be compact before reset")
	var animation_state_machine := _get_player_animation_state_machine()
	if animation_state_machine != null:
		animation_state_machine.call("set_movement_vector", Vector2.LEFT)
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_WALK, &"walk")
	_assert_player_facing(PLAYER_FACING_LEFT, false, "left movement before reset")

	demo.call("_reset_demo_state")
	_assert_player_animation_state(PLAYER_ANIMATION_STATE_IDLE, &"idle")
	_assert_player_facing(PLAYER_FACING_RIGHT, true, "reset should restore runtime default facing")
	_assert_true(demo.get("optional_progress_detail_view") == false, "reset should preserve runtime journal view mode")
	_assert_journal_progress(0, _optional_total_count())
	_assert_journal_recent("无")
	_assert_history_contains("Demo 已重置")
	_assert_journal_save_fields_absent()
	_ensure_detail_journal_view()


func _assert_repeated_optional_completion_preserves_history_and_recent() -> void:
	var history: Variant = demo.get("interaction_history")
	_assert_true(history is Array, "interaction_history should be an Array")
	if not (history is Array):
		return

	var history_size_before: int = history.size()
	var repeated_result: Variant = demo.call("_on_optional_collectible_interacted", OWNER_ID, MIGU_BRANCH_INTERACTABLE_ID, {
		"item_id": MIGU_BRANCH_ITEM_ID,
		"count": 1
	})
	_assert_true(repeated_result == true, "repeated migu branch interaction should return true")

	var history_after: Variant = demo.get("interaction_history")
	_assert_true(history_after is Array and history_after.size() == history_size_before, "repeated optional completion should not append history")
	_assert_journal_recent("迷穀枝")


func _assert_history_ui_recent_limit_preserves_internal_history() -> void:
	var history: Variant = demo.get("interaction_history")
	_assert_true(history is Array, "interaction_history should be an Array")
	if not (history is Array):
		return
	_assert_true(history.size() > 5, "internal history should keep more entries than the UI recent limit")

	var history_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/InteractionHistoryLabel") as Label
	_assert_true(history_label != null, "interaction history label must exist")
	if history_label == null:
		return

	_assert_true(history_label.text.contains("历史记录（最近 5 条）"), "history UI should disclose the recent-entry limit")
	_assert_true(_count_visible_history_entries(history_label.text) == 5, "history UI should show only the latest 5 entries")
	_assert_true(history_label.max_lines_visible == 6, "history label should reserve one header line plus 5 entries")
	for index in range(history.size() - 5, history.size()):
		_assert_true(history_label.text.contains(str(history[index])), "history UI should show recent entry %s" % str(history[index]))


func _count_visible_history_entries(history_text: String) -> int:
	var entry_count := 0
	for line in history_text.split("\n"):
		if line.begins_with("- "):
			entry_count += 1
	return entry_count


func _assert_journal_labels_separated() -> void:
	var journal_label := _get_journal_label()
	var history_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/InteractionHistoryLabel") as Label
	var hint_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressShortcutHintLabel") as Label
	var view_toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressViewToggleButton") as Button
	var history_toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryToggleButton") as Button
	var survival_label := demo.get_node_or_null("CanvasLayer/SurvivalStatusLabel") as Label
	var navigation_label := demo.get_node_or_null("CanvasLayer/NavigationStatusLabel") as Label
	var journal_panel := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel") as Control
	_assert_true(history_label != null, "interaction history label must exist")
	_assert_true(hint_label != null, "optional progress shortcut hint label must exist")
	_assert_true(view_toggle_button != null, "optional progress view toggle button must exist")
	_assert_true(history_toggle_button != null, "interaction history toggle button must exist")
	_assert_true(survival_label != null, "survival status label must exist")
	_assert_true(navigation_label != null, "navigation status label must exist")
	_assert_true(journal_panel != null, "interaction history panel must exist")
	if (
		journal_label == null
		or history_label == null
		or hint_label == null
		or view_toggle_button == null
		or history_toggle_button == null
		or survival_label == null
		or navigation_label == null
		or journal_panel == null
	):
		return

	_assert_true(hint_label.offset_bottom <= journal_label.offset_top, "shortcut hint should end before journal label starts")
	_assert_true(journal_label.offset_bottom <= history_label.offset_top, "journal label should end before history label starts")
	var hint_rect := hint_label.get_global_rect()
	_assert_true(not hint_rect.intersects(view_toggle_button.get_global_rect()), "shortcut hint should not overlap compact/detail view button")
	_assert_true(not hint_rect.intersects(history_toggle_button.get_global_rect()), "shortcut hint should not overlap hide/show journal button")
	_assert_true(not hint_rect.intersects(journal_label.get_global_rect()), "shortcut hint should not overlap optional progress label")
	_assert_true(not hint_rect.intersects(history_label.get_global_rect()), "shortcut hint should not overlap interaction history label")
	_assert_true(hint_label.clip_text == true, "shortcut hint label should clip text inside its fixed area")
	_assert_true(journal_label.clip_text == true, "journal label should clip text inside its fixed area")
	_assert_true(history_label.clip_text == true, "history label should clip text inside its fixed area")
	_assert_true(
		survival_label.get_global_rect().end.y <= navigation_label.get_global_rect().position.y,
		"survival HUD should end before navigation HUD starts"
	)
	_assert_true(
		navigation_label.get_global_rect().end.y <= history_toggle_button.get_global_rect().position.y,
		"navigation HUD should end before journal toggle starts"
	)
	_assert_true(
		not navigation_label.get_global_rect().intersects(journal_panel.get_global_rect()),
		"navigation HUD should not overlap optional journal"
	)


func _assert_shortcut_hint_label() -> void:
	var hint_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressShortcutHintLabel") as Label
	_assert_true(hint_label != null, "optional progress shortcut hint label must exist")
	if hint_label == null:
		return

	_assert_true(hint_label.visible, "shortcut hint should be visible")
	_assert_true(hint_label.is_visible_in_tree(), "shortcut hint should be visible while journal panel is shown")
	_assert_true(not hint_label.text.strip_edges().is_empty(), "shortcut hint should not be empty")
	_assert_true(hint_label.text.contains("快捷键"), "shortcut hint should explain keyboard controls")
	_assert_true(hint_label.text.contains("J"), "shortcut hint should mention J")
	_assert_true(hint_label.text.contains("V"), "shortcut hint should mention V")
	_assert_true(hint_label.autowrap_mode == TextServer.AUTOWRAP_OFF, "shortcut hint should remain on one line")
	_assert_true(hint_label.size.y >= hint_label.get_minimum_size().y, "shortcut hint should have enough height to render")


func _assert_journal_save_fields_absent() -> void:
	var save_data: Variant = demo.call("get_save_data")
	_assert_true(save_data is Dictionary, "save data should be a Dictionary")
	if not (save_data is Dictionary):
		return

	_assert_true(not save_data.has("recent_optional_completion_name"), "save data should not persist recent optional completion")
	_assert_true(not save_data.has("optional_progress_detail_view"), "save data should not persist optional progress view mode")

	var world_data: Variant = save_data.get("world", {})
	_assert_true(world_data is Dictionary, "save world data should be a Dictionary")
	if not (world_data is Dictionary):
		return
	_assert_true(not world_data.has("recent_optional_completion_name"), "world save data should not persist recent optional completion")
	_assert_true(not world_data.has("optional_progress_detail_view"), "world save data should not persist optional progress view mode")

	var optional_data: Variant = world_data.get("optional", {})
	_assert_true(optional_data is Dictionary, "optional save data should be a Dictionary")
	if not (optional_data is Dictionary):
		return
	_assert_true(optional_data.size() == _optional_total_count(), "optional save data should only contain configured optional content states")


func _ensure_detail_journal_view() -> void:
	var toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressViewToggleButton")
	_assert_true(toggle_button != null, "optional progress view toggle button must exist")
	if toggle_button == null:
		return

	if demo.get("optional_progress_detail_view") == false:
		toggle_button.emit_signal("pressed")
	_assert_true(demo.get("optional_progress_detail_view") == true, "journal should be in detail view")
	_assert_true(toggle_button.text == "简洁视图", "detail journal toggle should offer compact view")


func _get_journal_label() -> Label:
	var journal_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressJournalLabel") as Label
	_assert_true(journal_label != null, "optional progress journal label must exist")
	return journal_label


func _optional_total_count() -> int:
	return _optional_collectible_count() + _optional_creature_count()


func _optional_collectible_count() -> int:
	var configs: Variant = demo.get("optional_collectibles")
	if configs is Array:
		return configs.size()
	return 0


func _optional_creature_count() -> int:
	var configs: Variant = demo.get("optional_creatures")
	if configs is Array:
		return configs.size()
	return 0


func _assert_history_panel_toggle_preserves_history(expected_entry: String) -> void:
	var history_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/InteractionHistoryLabel")
	var journal_label := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel/OptionalProgressJournalLabel")
	var log_label := demo.get_node_or_null("CanvasLayer/LogLabel")
	var toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryToggleButton")
	_assert_true(history_label != null, "interaction history label must exist")
	_assert_true(journal_label != null, "optional progress journal label must exist")
	_assert_true(log_label != null, "log label must exist")
	_assert_true(toggle_button != null, "interaction history toggle button must exist")
	if history_label == null or journal_label == null or log_label == null or toggle_button == null:
		return

	_assert_history_panel_visible(true)
	_assert_true(history_label.text.contains(expected_entry), "history label should contain %s before collapse" % expected_entry)
	_assert_true(not log_label.text.is_empty(), "log label should contain entries before collapse")
	var history_text_before_collapse: String = history_label.text
	var journal_text_before_collapse: String = journal_label.text
	var log_text_before_collapse: String = log_label.text

	toggle_button.emit_signal("pressed")
	_assert_history_panel_visible(false)
	_assert_true(history_label.text.contains(expected_entry), "history label should preserve %s while collapsed" % expected_entry)
	_assert_true(history_label.text == history_text_before_collapse, "history label text should not change when collapsed")
	_assert_true(journal_label.text == journal_text_before_collapse, "journal text should not change when collapsed")
	_assert_true(log_label.text == log_text_before_collapse, "log label text should not change when collapsed")

	toggle_button.emit_signal("pressed")
	_assert_history_panel_visible(true)
	_assert_true(history_label.text.contains(expected_entry), "history label should still contain %s after expand" % expected_entry)
	_assert_true(journal_label.text == journal_text_before_collapse, "journal text should still be preserved after expand")
	_assert_true(log_label.text == log_text_before_collapse, "log label text should still be preserved after expand")


func _assert_history_panel_visible(expected: bool) -> void:
	var history_panel := demo.get_node_or_null("CanvasLayer/InteractionHistoryPanel")
	var log_label := demo.get_node_or_null("CanvasLayer/LogLabel")
	var toggle_button := demo.get_node_or_null("CanvasLayer/InteractionHistoryToggleButton")
	_assert_true(history_panel != null, "interaction history panel must exist")
	_assert_true(log_label != null, "log label must exist")
	_assert_true(toggle_button != null, "interaction history toggle button must exist")
	if history_panel == null or log_label == null or toggle_button == null:
		return

	_assert_true(history_panel.visible == expected, "interaction history panel visibility mismatch")
	_assert_true(log_label.visible == expected, "log label visibility mismatch")
	_assert_true(toggle_button.visible == true, "interaction history toggle button should remain visible")
	var expected_button_text := "隐藏日志"
	if not expected:
		expected_button_text = "显示日志"
	_assert_true(toggle_button.text == expected_button_text, "interaction history toggle text mismatch")


func _assert_optional_done(content_id: String, expected: bool) -> void:
	var optional_state: Variant = demo.get("optional_state")
	_assert_true(optional_state is Dictionary, "optional_state should be a Dictionary")
	if not (optional_state is Dictionary):
		return

	_assert_true(optional_state.get(content_id, false) == expected, "optional state mismatch for %s" % content_id)


func _assert_inventory_count(expected_count: int) -> void:
	_assert_inventory_item_count(ITEM_ID, expected_count)


func _assert_inventory_item_count(item_id: String, expected_count: int) -> void:
	var inventory_service: Variant = demo.get("inventory_service")
	_assert_true(inventory_service != null, "inventory_service must exist")

	var item_count: Variant = inventory_service.call("get_item_count", OWNER_ID, item_id)
	_assert_true(item_count == expected_count, "inventory should contain %s x%d, actual=%s" % [item_id, expected_count, str(item_count)])


func _assert_bestiary_has_item(expected: bool) -> void:
	_assert_bestiary_has_item_id(ITEM_ID, expected)


func _assert_bestiary_has_item_id(item_id: String, expected: bool) -> void:
	var bestiary_service: Variant = demo.get("bestiary_service")
	_assert_true(bestiary_service != null, "bestiary_service must exist")

	var discovered_items: Variant = bestiary_service.call("get_discovered_items", OWNER_ID)
	_assert_true(discovered_items is Array, "discovered items should be an Array")
	_assert_true(discovered_items.has(item_id) == expected, "bestiary item state mismatch for %s" % item_id)


func _assert_bestiary_has_creature(expected: bool) -> void:
	_assert_bestiary_has_creature_id(CREATURE_ID, expected)


func _assert_bestiary_has_creature_id(creature_id: String, expected: bool) -> void:
	var bestiary_service: Variant = demo.get("bestiary_service")
	_assert_true(bestiary_service != null, "bestiary_service must exist")

	var discovered_creatures: Variant = bestiary_service.call("get_discovered_creatures", OWNER_ID)
	_assert_true(discovered_creatures is Array, "discovered creatures should be an Array")
	_assert_true(discovered_creatures.has(creature_id) == expected, "bestiary creature state mismatch for %s" % creature_id)


func _assert_zhuyu_knowledge(slot: String, expected: bool) -> void:
	var knowledge_state: Variant = demo.get("zhuyu_knowledge_state")
	_assert_true(knowledge_state is Dictionary, "zhuyu_knowledge_state should be a Dictionary")
	if not (knowledge_state is Dictionary):
		return
	_assert_true(
		knowledge_state.get(slot, false) == expected,
		"zhuyu knowledge mismatch for %s" % slot
	)


func _assert_migu_knowledge(slot: String, expected: bool) -> void:
	var knowledge_state: Variant = demo.get("migu_knowledge_state")
	_assert_true(knowledge_state is Dictionary, "migu_knowledge_state should be a Dictionary")
	if not (knowledge_state is Dictionary):
		return
	_assert_true(
		knowledge_state.get(slot, false) == expected,
		"migu knowledge mismatch for %s" % slot
	)


func _navigation_status_text() -> String:
	var navigation_label := demo.get_node_or_null("CanvasLayer/NavigationStatusLabel") as Label
	_assert_true(navigation_label != null, "NavigationStatusLabel should exist")
	if navigation_label == null:
		return ""
	return navigation_label.text


func _assert_navigation_status_contains(expected: String) -> void:
	var navigation_text := _navigation_status_text()
	_assert_true(
		navigation_text.contains(expected),
		"navigation status should contain %s, actual=%s" % [expected, navigation_text]
	)


func _assert_navigation_status_not_contains(unexpected: String) -> void:
	var navigation_text := _navigation_status_text()
	_assert_true(
		not navigation_text.contains(unexpected),
		"navigation status should not contain %s, actual=%s" % [unexpected, navigation_text]
	)


func _assert_navigation_status_has_direction() -> void:
	var navigation_text := _navigation_status_text()
	var first_line := navigation_text.get_slice("\n", 0)
	var has_direction := false
	for direction in ["东北", "西北", "东南", "西南", "东", "北", "西", "南"]:
		if first_line.contains(direction):
			has_direction = true
			break
	_assert_true(
		has_direction,
		"navigation guidance should contain an eight-way direction, actual=%s" % first_line
	)


func _assert_survival_status(expected: String) -> void:
	var survival_label := demo.get_node_or_null("CanvasLayer/SurvivalStatusLabel") as Label
	_assert_true(survival_label != null, "SurvivalStatusLabel should exist")
	if survival_label != null:
		_assert_true(
			survival_label.text.contains(expected),
			"survival status should contain %s, actual=%s" % [expected, survival_label.text]
		)


func _assert_prompt_contains(expected: String) -> void:
	var prompt_label := demo.get_node_or_null("CanvasLayer/PromptLabel") as Label
	_assert_true(prompt_label != null, "PromptLabel should exist")
	if prompt_label != null:
		_assert_true(prompt_label.visible, "PromptLabel should be visible")
		_assert_true(
			prompt_label.text.contains(expected),
			"prompt should contain %s, actual=%s" % [expected, prompt_label.text]
		)


func _assert_prompt_not_contains(unexpected: String) -> void:
	var prompt_label := demo.get_node_or_null("CanvasLayer/PromptLabel") as Label
	_assert_true(prompt_label != null, "PromptLabel should exist")
	if prompt_label != null and prompt_label.visible:
		_assert_true(
			not prompt_label.text.contains(unexpected),
			"prompt should not contain %s, actual=%s" % [unexpected, prompt_label.text]
		)


func _assert_log_contains(expected: String) -> void:
	var log_label := demo.get_node_or_null("CanvasLayer/LogLabel") as RichTextLabel
	_assert_true(log_label != null, "LogLabel should exist")
	if log_label != null:
		_assert_true(
			log_label.text.contains(expected),
			"log should contain %s" % expected
		)


func _assert_history_contains(expected: String) -> void:
	_assert_true(_history_contains(expected), "history should contain %s, actual=%s" % [expected, str(demo.get("interaction_history"))])


func _assert_history_not_contains(unexpected: String) -> void:
	_assert_true(not _history_contains(unexpected), "history should not contain %s, actual=%s" % [unexpected, str(demo.get("interaction_history"))])


func _history_contains(expected: String) -> bool:
	var history: Variant = demo.get("interaction_history")
	if not (history is Array):
		return false

	for entry in history:
		if entry is String and entry.contains(expected):
			return true
	return false


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _assert_vec2_near(actual: Vector2, expected: Vector2, message: String) -> void:
	if actual.distance_to(expected) > 0.01:
		_fail("%s actual=%s expected=%s" % [message, actual, expected])


func _assert_float_near(actual: float, expected: float, message: String) -> void:
	if absf(actual - expected) > 0.01:
		_fail("%s actual=%s expected=%s" % [message, actual, expected])


func _fail(message: String) -> void:
	if failed:
		return

	failed = true
	push_error(message)
	quit(1)
