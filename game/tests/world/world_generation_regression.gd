extends SceneTree

const SeededRng := preload("res://scripts/world/seeded_rng.gd")
const WeightedTable := preload("res://scripts/world/weighted_table.gd")
const WorldMapModel := preload("res://scripts/world/world_map_model.gd")
const RegionModel := preload("res://scripts/world/region_model.gd")
const WorldGenerator := preload("res://scripts/world/world_generator.gd")

const WORLD_MAP_PATH := "res://data/world/world_map.json"
const REGION_PATH := "res://data/world/regions/south_mountain.json"
const SPAWN_RULES_PATH := "res://data/world/spawn_rules.json"
const RESOURCE_RULES_PATH := "res://data/world/resource_rules.json"
const ENCOUNTER_RULES_PATH := "res://data/world/encounter_rules.json"
const DEFAULT_SEED := 20260628

var world_map: Dictionary
var region: Dictionary
var spawn_rules: Dictionary
var resource_rules: Dictionary
var encounter_rules: Dictionary
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert_world_data()
	if failed:
		quit(1)
		return
	_assert_seeded_rng()
	if failed:
		quit(1)
		return
	_assert_weighted_table()
	if failed:
		quit(1)
		return
	_assert_world_generation()
	if failed:
		quit(1)
		return
	print("world generation regression passed")
	quit(0)


func _assert_world_data() -> void:
	var world_result := WorldMapModel.load_file(WORLD_MAP_PATH)
	_assert_true(world_result["ok"], "world_map.json must load: %s" % world_result["errors"])
	if failed:
		return
	world_map = world_result["data"]

	var region_result := RegionModel.load_file(REGION_PATH)
	_assert_true(region_result["ok"], "south_mountain.json must load: %s" % region_result["errors"])
	if failed:
		return
	region = region_result["data"]

	spawn_rules = _load_json(SPAWN_RULES_PATH)
	resource_rules = _load_json(RESOURCE_RULES_PATH)
	encounter_rules = _load_json(ENCOUNTER_RULES_PATH)

	_assert_true(world_map["regions"][0]["id"] == "south_mountain", "world map region id must exist")
	_assert_true(region["mvp_mountains"][0]["id"] == "zhaoyao", "region mountain id must exist")
	_assert_true(
		FileAccess.file_exists(world_map["regions"][0]["region_file"]),
		"world map region_file must exist"
	)

	var mountains := _mountain_ids_by_region()
	_assert_rules_reference_mountains(spawn_rules, "spawn_id", mountains)
	_assert_rules_reference_mountains(resource_rules, "resource_id", mountains)
	_assert_rules_reference_mountains(encounter_rules, "creature_id", mountains)

	var zhaoyao: Dictionary = region["mvp_mountains"][0]
	for rule in resource_rules["rules"]:
		_assert_true(
			zhaoyao["resources"].has(rule["resource_id"]),
			"resource rule id must exist in mountain resources: %s" % rule["resource_id"]
		)
	for rule in encounter_rules["rules"]:
		_assert_true(
			zhaoyao["creatures"].has(rule["creature_id"]),
			"encounter rule id must exist in mountain creatures: %s" % rule["creature_id"]
		)

	_assert_true(
		not WorldMapModel.validate_data({"version": 1}).is_empty(),
		"world map model must reject missing required fields"
	)
	_assert_true(
		not RegionModel.validate_data({"version": 1}).is_empty(),
		"region model must reject missing required fields"
	)


func _assert_seeded_rng() -> void:
	var first := SeededRng.new(DEFAULT_SEED)
	var second := SeededRng.new(DEFAULT_SEED)
	var first_sequence := []
	var second_sequence := []
	for index in range(12):
		first_sequence.append(first.next_int(-20, 20))
		second_sequence.append(second.next_int(-20, 20))
	_assert_true(first_sequence == second_sequence, "same seed must produce the same integer sequence")

	var different := SeededRng.new(DEFAULT_SEED + 1)
	var different_sequence := []
	for index in range(12):
		different_sequence.append(different.next_int(-20, 20))
	_assert_true(first_sequence != different_sequence, "different seeds should produce different integer sequences")

	var float_first := SeededRng.new(18)
	var float_second := SeededRng.new(18)
	for index in range(12):
		var first_float := float_first.next_float()
		var second_float := float_second.next_float()
		_assert_true(first_float == second_float, "next_float must be stable for the same seed")
		_assert_true(first_float >= 0.0 and first_float < 1.0, "next_float must remain inside 0.0..1.0")

	var ranged := SeededRng.new(41)
	for index in range(100):
		var value := ranged.next_int(3, 7)
		_assert_true(value >= 3 and value <= 7, "next_int result must remain inside inclusive range")

	var choices := ["south_mountain", "west_mountain", "north_mountain"]
	var choose_first := SeededRng.new(77)
	var choose_second := SeededRng.new(77)
	for index in range(10):
		_assert_true(
			choose_first.choose(choices) == choose_second.choose(choices),
			"choose must be stable for the same seed"
		)

	var empty_choice := SeededRng.new(1)
	_assert_true(empty_choice.choose([]) == null, "choose must safely fail for an empty array")
	_assert_true(not empty_choice.last_error.is_empty(), "empty choose must expose a clear error")


func _assert_weighted_table() -> void:
	var entries := [
		{"id": "never", "weight": 0},
		{"id": "common", "weight": 80},
		{"id": "rare", "weight": 20}
	]
	var first_table := WeightedTable.new(entries)
	var second_table := WeightedTable.new(entries)
	var first_rng := SeededRng.new(300)
	var second_rng := SeededRng.new(300)
	var first_sequence := []
	var second_sequence := []
	for index in range(100):
		var first_pick: Variant = first_table.pick(first_rng)
		var second_pick: Variant = second_table.pick(second_rng)
		_assert_true(first_pick != "never", "zero weight entry must never be selected")
		first_sequence.append(first_pick)
		second_sequence.append(second_pick)
	_assert_true(first_sequence == second_sequence, "weighted picks must be stable for the same seed")

	var dictionary_table := WeightedTable.new({"north": 1, "south": 2})
	_assert_true(dictionary_table.entries().size() == 2, "weighted table must load Dictionary entries")
	_assert_true(dictionary_table.add({"id": "east", "weight": -4}), "negative weights must be handled safely")
	_assert_true(
		dictionary_table.entries()[2]["weight"] == 0.0,
		"negative weights must be clamped to zero"
	)

	var zero_table := WeightedTable.new([
		{"id": "zero", "weight": 0},
		{"id": "negative", "weight": -10}
	])
	_assert_true(zero_table.pick(SeededRng.new(1)) == null, "zero total weight must safely fail")
	_assert_true(
		zero_table.last_error.contains("greater than zero"),
		"zero total weight must expose a clear error"
	)

	var empty_table := WeightedTable.new()
	_assert_true(empty_table.pick(SeededRng.new(1)) == null, "empty weighted table must safely fail")
	_assert_true(empty_table.last_error.contains("empty"), "empty weighted table must expose a clear error")


func _assert_world_generation() -> void:
	var generator := WorldGenerator.new()
	var first := generator.generate_from_files(DEFAULT_SEED)
	_assert_true(not first.is_empty(), "world generation must succeed: %s" % generator.last_error)
	if failed:
		return

	var repeated := WorldGenerator.new().generate_from_files(DEFAULT_SEED)
	_assert_true(first == repeated, "same seed and inputs must generate identical results")

	var count_signature := _generation_count_signature(first)
	var found_different_counts := false
	for seed_offset in range(1, 33):
		var candidate_generator := WorldGenerator.new()
		var candidate := candidate_generator.generate_from_files(DEFAULT_SEED + seed_offset)
		_assert_true(
			not candidate.is_empty(),
			"different-seed generation must succeed: %s" % candidate_generator.last_error
		)
		if failed:
			return
		if _generation_count_signature(candidate) != count_signature:
			found_different_counts = true
			break
	_assert_true(found_different_counts, "different seeds must be able to change generated counts")

	_assert_true(first["version"] == 1, "generation result version must be stable")
	_assert_true(first["seed"] == DEFAULT_SEED, "generation result must record the input seed")
	_assert_true(
		first["starting_region_id"] == "south_mountain",
		"generation result must include the starting region"
	)
	_assert_true(first["starting_mountain_id"] == "zhaoyao", "generation result must include zhaoyao")
	_assert_true(first["player_spawn_id"] == "zhaoyao_village", "generation result must include player spawn")

	var zhaoyao: Dictionary = first["generated_regions"]["south_mountain"]["mountains"]["zhaoyao"]
	var zhuyu := _find_generated_entry(zhaoyao["resources"], "zhuyu")
	var migu := _find_generated_entry(zhaoyao["resources"], "migu")
	var shensheng := _find_generated_entry(zhaoyao["encounters"], "shensheng")
	_assert_true(not zhuyu.is_empty(), "generation result must include zhuyu")
	_assert_true(not migu.is_empty(), "generation result must include migu")
	_assert_true(not shensheng.is_empty(), "generation result must include shensheng encounter")
	_assert_count_matches_rule(zhuyu, _find_rule(resource_rules, "resource_id", "zhuyu"))
	_assert_count_matches_rule(migu, _find_rule(resource_rules, "resource_id", "migu"))
	_assert_count_matches_rule(shensheng, _find_rule(encounter_rules, "creature_id", "shensheng"))

	var serialized := JSON.stringify(first)
	var parsed: Variant = JSON.parse_string(serialized)
	_assert_true(not serialized.is_empty(), "generation result must serialize to JSON")
	_assert_true(parsed is Dictionary, "serialized generation result must parse as a Dictionary")
	_assert_true(parsed["starting_region_id"] == "south_mountain", "JSON result must preserve world ids")

	for demo_save_field in [
		"current_step",
		"inventory",
		"survival",
		"knowledge",
		"navigation",
		"interaction_history",
		"optional"
	]:
		_assert_true(
			not first.has(demo_save_field),
			"generation result must not add demo save field %s" % demo_save_field
		)

	var regions_by_id := {
		"south_mountain": region
	}
	var in_memory := WorldGenerator.new().generate(
		DEFAULT_SEED,
		world_map,
		regions_by_id,
		spawn_rules,
		resource_rules,
		encounter_rules
	)
	_assert_true(in_memory == first, "file and in-memory generation inputs must produce the same result")

	var missing_region_generator := WorldGenerator.new()
	var missing_region_result := missing_region_generator.generate(
		DEFAULT_SEED,
		world_map,
		{},
		spawn_rules,
		resource_rules,
		encounter_rules
	)
	_assert_true(missing_region_result.is_empty(), "missing region data must safely fail")
	_assert_true(
		missing_region_generator.last_error.contains("missing region data"),
		"missing region data must expose a clear error"
	)


func _load_json(path: String) -> Dictionary:
	_assert_true(FileAccess.file_exists(path), "JSON file must exist: %s" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	_assert_true(file != null, "JSON file must open: %s" % path)
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	_assert_true(parse_error == OK, "JSON file must parse: %s" % path)
	_assert_true(json.data is Dictionary, "JSON top-level value must be a Dictionary: %s" % path)
	return json.data


func _mountain_ids_by_region() -> Dictionary:
	var result := {}
	result[region["id"]] = {}
	for mountain in region["mvp_mountains"]:
		result[region["id"]][mountain["id"]] = true
	return result


func _assert_rules_reference_mountains(
	data: Dictionary,
	id_field: String,
	mountains: Dictionary
) -> void:
	for index in range(data["rules"].size()):
		var rule: Dictionary = data["rules"][index]
		for field in [id_field, "region_id", "mountain_id", "spawn_weight"]:
			_assert_true(rule.has(field), "%s rule must include %s" % [id_field, field])
		_assert_true(
			mountains.has(rule["region_id"]),
			"%s rule must reference an existing region" % id_field
		)
		_assert_true(
			mountains[rule["region_id"]].has(rule["mountain_id"]),
			"%s rule must reference an existing mountain" % id_field
		)


func _find_rule(rules_data: Dictionary, id_field: String, expected_id: String) -> Dictionary:
	for rule in rules_data["rules"]:
		if rule[id_field] == expected_id:
			return rule
	return {}


func _find_generated_entry(entries: Array, expected_id: String) -> Dictionary:
	for entry in entries:
		if entry["id"] == expected_id:
			return entry
	return {}


func _assert_count_matches_rule(entry: Dictionary, rule: Dictionary) -> void:
	_assert_true(not rule.is_empty(), "count range rule must exist for %s" % entry["id"])
	_assert_true(
		entry["count"] >= rule["min_count"] and entry["count"] <= rule["max_count"],
		"generated count for %s must be inside %d..%d" % [
			entry["id"],
			rule["min_count"],
			rule["max_count"]
		]
	)


func _generation_count_signature(result: Dictionary) -> String:
	if result.is_empty():
		return ""
	var zhaoyao: Dictionary = result["generated_regions"]["south_mountain"]["mountains"]["zhaoyao"]
	return JSON.stringify({
		"resources": zhaoyao["resources"],
		"encounters": zhaoyao["encounters"]
	})


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	if failed:
		return
	failed = true
	push_error(message)
