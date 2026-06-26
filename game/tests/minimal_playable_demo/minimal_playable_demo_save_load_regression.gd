extends SceneTree

const DEMO_SCENE := preload("res://scenes/demo/minimal_playable_demo.tscn")

const OWNER_ID := "player"
const ITEM_ID := "zhuyu_leaf"
const CREATURE_ID := "shensheng"
const MIGU_BRANCH_ITEM_ID := "migu_branch"
const LUSHU_CREATURE_ID := "lushu"
const ZHUYU_INTERACTABLE_ID := "pickup_zhuyu_leaf"
const STONE_INTERACTABLE_ID := "activate_guidance_stone"
const SHENSHENG_INTERACTABLE_ID := "observe_shensheng"
const MIGU_BRANCH_INTERACTABLE_ID := "collect_migu_branch"
const LUSHU_INTERACTABLE_ID := "observe_lushu"
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
	_force_optional_complete()
	_assert_optional_state_complete()
	_assert_history_contains("采集迷穀枝")
	_assert_history_contains("发现鹿蜀")

	demo.call("_on_save_demo_pressed")
	_assert_history_contains("保存 Demo")

	player.position = initial_position + Vector2(520.0, 300.0)
	demo.call("_reset_demo_state")
	_assert_vec2_near(player.position, initial_position, "reset before optional-state load should return player to initial position")
	_assert_optional_state_pending()
	_assert_history_contains("Demo 已重置")
	_assert_history_not_contains("采集迷穀枝")
	_assert_history_not_contains("发现鹿蜀")

	demo.call("_on_load_demo_pressed")
	_assert_vec2_near(player.position, optional_position, "load should restore saved optional-state player position")
	_assert_state_complete()
	_assert_optional_state_complete()
	_assert_history_contains("采集迷穀枝")
	_assert_history_contains("发现鹿蜀")
	_assert_history_contains("读取 Demo")

	player.position = initial_position + Vector2(500.0, 260.0)
	demo.call("_on_restart_demo_pressed")
	_assert_vec2_near(player.position, initial_position, "restart should return player to initial position")
	_assert_true(demo.get("current_step") == STEP_COLLECT_ZHUYU, "restart should restore initial step")
	_assert_optional_state_pending()
	_assert_history_contains("重新开始 Demo")
	_assert_history_not_contains("发现狌狌")
	_assert_history_not_contains("采集迷穀枝")
	_assert_history_not_contains("发现鹿蜀")

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

	var migu_result: Variant = demo.call("_on_migu_branch_interacted", OWNER_ID, MIGU_BRANCH_INTERACTABLE_ID, {
		"item_id": MIGU_BRANCH_ITEM_ID,
		"count": 1
	})
	_assert_true(migu_result == true, "migu branch interaction should succeed")

	var lushu_result: Variant = demo.call("_on_lushu_interacted", OWNER_ID, LUSHU_INTERACTABLE_ID, {
		"creature_id": LUSHU_CREATURE_ID
	})
	_assert_true(lushu_result == true, "lushu interaction should succeed")


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
	_assert_true(demo.get("migu_collected") == false, "migu branch should not be collected")
	_assert_true(demo.get("lushu_discovered") == false, "lushu should not be discovered")

	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel")
	var lushu_label := demo.get_node_or_null("WorldRoot/LushuLabel")

	_assert_true(migu_label != null and migu_label.text == "迷穀枝", "MiguBranchLabel should show initial state")
	_assert_true(lushu_label != null and lushu_label.text == "鹿蜀", "LushuLabel should show initial state")

	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 0)
	_assert_bestiary_has_item_id(MIGU_BRANCH_ITEM_ID, false)
	_assert_bestiary_has_creature_id(LUSHU_CREATURE_ID, false)


func _assert_optional_state_complete() -> void:
	_assert_true(demo.get("migu_collected") == true, "migu branch should be collected")
	_assert_true(demo.get("lushu_discovered") == true, "lushu should be discovered")

	var migu_label := demo.get_node_or_null("WorldRoot/MiguBranchLabel")
	var lushu_label := demo.get_node_or_null("WorldRoot/LushuLabel")
	var status_label := demo.get_node_or_null("CanvasLayer/StatusLabel")
	var target_hint_label := demo.get_node_or_null("CanvasLayer/TargetHintLabel")
	var completion_summary_label := demo.get_node_or_null("CanvasLayer/CompletionPanel/CompletionSummaryLabel")

	_assert_true(migu_label != null and migu_label.text.contains("已采集"), "MiguBranchLabel should show collected state")
	_assert_true(lushu_label != null and lushu_label.text.contains("已发现"), "LushuLabel should show discovered state")
	_assert_true(status_label != null and status_label.text.contains(MIGU_BRANCH_ITEM_ID), "StatusLabel should include migu item")
	_assert_true(status_label != null and status_label.text.contains(LUSHU_CREATURE_ID), "StatusLabel should include lushu creature")
	_assert_true(target_hint_label != null and target_hint_label.text.contains("所有 Demo 内容已完成"), "TargetHintLabel should show optional completion")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已采集：迷穀枝"), "Completion summary should include migu")
	_assert_true(completion_summary_label != null and completion_summary_label.text.contains("已发现：鹿蜀"), "Completion summary should include lushu")

	_assert_inventory_item_count(MIGU_BRANCH_ITEM_ID, 1)
	_assert_bestiary_has_item_id(MIGU_BRANCH_ITEM_ID, true)
	_assert_bestiary_has_creature_id(LUSHU_CREATURE_ID, true)


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
