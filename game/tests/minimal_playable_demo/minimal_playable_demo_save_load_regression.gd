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
const STEP_COLLECT_ZHUYU := 0
const STEP_OBSERVE_SHENSHENG := 2
const STEP_COMPLETE := 3

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
	_assert_history_panel_visible(true)
	_assert_initial_journal_state()
	_assert_progress_view_toggle_preserves_history("Demo 开始")
	_assert_journal_shortcut_handlers_preserve_text("Demo 开始")
	_assert_reset_preserves_compact_journal_view()
	if failed:
		return

	initial_position = player.position

	var saved_position := initial_position + Vector2(120.0, 80.0)
	_force_state_after_stone_activation()
	_assert_state_after_stone_activation()
	_assert_history_contains("采集祝余叶")
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

	demo.call("_on_load_demo_pressed")
	_assert_vec2_near(player.position, saved_position, "load should restore saved player position")
	_assert_state_after_stone_activation()
	_assert_history_contains("采集祝余叶")
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


func _force_state_after_stone_activation() -> void:
	demo.call("_reset_demo_state")

	var zhuyu_result: Variant = demo.call("_on_zhuyu_interacted", OWNER_ID, ZHUYU_INTERACTABLE_ID, {
		"item_id": ITEM_ID,
		"count": 1
	})
	_assert_true(zhuyu_result == true, "zhuyu interaction should succeed")

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

	_assert_inventory_count(1)
	_assert_bestiary_has_item(true)
	_assert_bestiary_has_creature(false)


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

	_assert_inventory_count(1)
	_assert_bestiary_has_item(true)
	_assert_bestiary_has_creature(true)


func _assert_optional_state_pending() -> void:
	_assert_optional_done(MIGU_BRANCH_ITEM_ID, false)
	_assert_optional_done(BASIC_ORE_ITEM_ID, false)
	_assert_optional_done(LUSHU_CREATURE_ID, false)
	_assert_optional_done(GENERIC_BEAST_CREATURE_ID, false)
	_assert_journal_recent("无")
	_assert_journal_optional_state_pending()

	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel")
	var basic_ore_label := demo.get_node_or_null("WorldRoot/BasicOreLabel")
	var lushu_label := demo.get_node_or_null("WorldRoot/LushuLabel")
	var generic_beast_label := demo.get_node_or_null("WorldRoot/GenericBeastLabel")

	_assert_true(migu_label != null and migu_label.text == "迷穀枝", "MiguBranchLabel should show initial state")
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

	demo.call("_reset_demo_state")
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
	_assert_true(history_label != null, "interaction history label must exist")
	_assert_true(hint_label != null, "optional progress shortcut hint label must exist")
	_assert_true(view_toggle_button != null, "optional progress view toggle button must exist")
	_assert_true(history_toggle_button != null, "interaction history toggle button must exist")
	if journal_label == null or history_label == null or hint_label == null or view_toggle_button == null or history_toggle_button == null:
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


func _fail(message: String) -> void:
	if failed:
		return

	failed = true
	push_error(message)
	quit(1)
