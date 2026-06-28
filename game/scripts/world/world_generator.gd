extends RefCounted

const SeededRng := preload("res://scripts/world/seeded_rng.gd")
const WeightedTable := preload("res://scripts/world/weighted_table.gd")
const WorldMapModel := preload("res://scripts/world/world_map_model.gd")
const RegionModel := preload("res://scripts/world/region_model.gd")

const DEFAULT_WORLD_MAP_PATH := "res://data/world/world_map.json"
const DEFAULT_SPAWN_RULES_PATH := "res://data/world/spawn_rules.json"
const DEFAULT_RESOURCE_RULES_PATH := "res://data/world/resource_rules.json"
const DEFAULT_ENCOUNTER_RULES_PATH := "res://data/world/encounter_rules.json"

var last_error := ""


func generate_from_files(
	seed_value: int,
	world_map_path := DEFAULT_WORLD_MAP_PATH,
	spawn_rules_path := DEFAULT_SPAWN_RULES_PATH,
	resource_rules_path := DEFAULT_RESOURCE_RULES_PATH,
	encounter_rules_path := DEFAULT_ENCOUNTER_RULES_PATH
) -> Dictionary:
	last_error = ""
	var world_result := WorldMapModel.load_file(world_map_path)
	if not world_result["ok"]:
		return _fail("world map load failed: %s" % _join_errors(world_result["errors"]))

	var world_map: Dictionary = world_result["data"]
	var regions_by_id := {}
	for region_reference in world_map["regions"]:
		var region_path: String = region_reference["region_file"]
		var region_result := RegionModel.load_file(region_path)
		if not region_result["ok"]:
			return _fail("region load failed: %s" % _join_errors(region_result["errors"]))

		var region_data: Dictionary = region_result["data"]
		var expected_id: String = region_reference["id"]
		if region_data["id"] != expected_id:
			return _fail(
				"region file %s has id %s, expected %s" % [
					region_path,
					region_data["id"],
					expected_id
				]
			)
		regions_by_id[expected_id] = region_data

	var spawn_result := _load_json_file(spawn_rules_path, "spawn rules")
	if not spawn_result["ok"]:
		return _fail(_join_errors(spawn_result["errors"]))
	var resource_result := _load_json_file(resource_rules_path, "resource rules")
	if not resource_result["ok"]:
		return _fail(_join_errors(resource_result["errors"]))
	var encounter_result := _load_json_file(encounter_rules_path, "encounter rules")
	if not encounter_result["ok"]:
		return _fail(_join_errors(encounter_result["errors"]))

	return generate(
		seed_value,
		world_map,
		regions_by_id,
		spawn_result["data"],
		resource_result["data"],
		encounter_result["data"]
	)


func generate(
	seed_value: int,
	world_map: Dictionary,
	regions_by_id: Dictionary,
	spawn_rules: Dictionary,
	resource_rules: Dictionary,
	encounter_rules: Dictionary
) -> Dictionary:
	last_error = ""

	var world_errors := WorldMapModel.validate_data(world_map)
	if not world_errors.is_empty():
		return _fail("invalid world map: %s" % _join_errors(world_errors))

	var region_error := _validate_regions(world_map, regions_by_id)
	if not region_error.is_empty():
		return _fail(region_error)

	var spawn_errors := _validate_rule_set(spawn_rules, "spawn", "spawn_id", false)
	if not spawn_errors.is_empty():
		return _fail("invalid spawn rules: %s" % _join_errors(spawn_errors))
	var resource_errors := _validate_rule_set(resource_rules, "resource", "resource_id", true)
	if not resource_errors.is_empty():
		return _fail("invalid resource rules: %s" % _join_errors(resource_errors))
	var encounter_errors := _validate_rule_set(encounter_rules, "encounter", "creature_id", true)
	if not encounter_errors.is_empty():
		return _fail("invalid encounter rules: %s" % _join_errors(encounter_errors))

	var reference_error := _validate_rule_references(
		regions_by_id,
		[
			{
				"label": "spawn",
				"data": spawn_rules,
				"id_field": "spawn_id",
				"declaration_field": ""
			},
			{
				"label": "resource",
				"data": resource_rules,
				"id_field": "resource_id",
				"declaration_field": "resources"
			},
			{
				"label": "encounter",
				"data": encounter_rules,
				"id_field": "creature_id",
				"declaration_field": "creatures"
			}
		]
	)
	if not reference_error.is_empty():
		return _fail(reference_error)

	var rng := SeededRng.new(seed_value)
	var starting_region_id: Variant = rng.choose(world_map["starting_regions"])
	if starting_region_id == null:
		return _fail("world map has no valid starting region")

	var starting_region: Dictionary = regions_by_id[starting_region_id]
	var mountain_table := WeightedTable.new()
	for mountain in starting_region["mvp_mountains"]:
		mountain_table.add(mountain["id"], mountain["spawn_weight"])
	var starting_mountain_id: Variant = mountain_table.pick(rng)
	if starting_mountain_id == null:
		return _fail("starting region mountain selection failed: %s" % mountain_table.last_error)

	var spawn_table := WeightedTable.new()
	for spawn_rule in spawn_rules["rules"]:
		if (
			spawn_rule["region_id"] == starting_region_id
			and spawn_rule["mountain_id"] == starting_mountain_id
		):
			spawn_table.add(spawn_rule["spawn_id"], spawn_rule["spawn_weight"])
	var player_spawn_id: Variant = spawn_table.pick(rng)
	if player_spawn_id == null:
		return _fail("player spawn selection failed: %s" % spawn_table.last_error)

	var generated_regions := {}
	for region_reference in world_map["regions"]:
		var region_id: String = region_reference["id"]
		var region_data: Dictionary = regions_by_id[region_id]
		var generated_mountains := {}
		for mountain in region_data["mvp_mountains"]:
			var mountain_id: String = mountain["id"]
			generated_mountains[mountain_id] = {
				"resources": _generate_rule_entries(
					resource_rules["rules"],
					"resource_id",
					region_id,
					mountain_id,
					rng
				),
				"encounters": _generate_rule_entries(
					encounter_rules["rules"],
					"creature_id",
					region_id,
					mountain_id,
					rng
				)
			}
		generated_regions[region_id] = {
			"mountains": generated_mountains
		}

	return {
		"version": 1,
		"seed": seed_value,
		"starting_region_id": starting_region_id,
		"starting_mountain_id": starting_mountain_id,
		"player_spawn_id": player_spawn_id,
		"generated_regions": generated_regions
	}


func _validate_regions(world_map: Dictionary, regions_by_id: Dictionary) -> String:
	for region_reference in world_map["regions"]:
		var region_id: String = region_reference["id"]
		if not regions_by_id.has(region_id):
			return "missing region data for %s" % region_id

		var region_data: Variant = regions_by_id[region_id]
		var region_errors := RegionModel.validate_data(region_data)
		if not region_errors.is_empty():
			return "invalid region %s: %s" % [region_id, _join_errors(region_errors)]
		if region_data["id"] != region_id:
			return "region data id %s does not match world map id %s" % [region_data["id"], region_id]
	return ""


func _validate_rule_set(
	data: Variant,
	label: String,
	id_field: String,
	requires_count_range: bool
) -> PackedStringArray:
	var errors := PackedStringArray()
	if not (data is Dictionary):
		errors.append("%s rules must be a Dictionary" % label)
		return errors
	if not _is_positive_int(data.get("version")):
		errors.append("%s rules version must be a positive integer" % label)

	var rules: Variant = data.get("rules")
	if not (rules is Array):
		errors.append("%s rules field must be an Array" % label)
		return errors
	if rules.is_empty():
		errors.append("%s rules field must not be empty" % label)
		return errors

	var seen_keys := {}
	for index in range(rules.size()):
		var rule_value: Variant = rules[index]
		var location := "%s rules[%d]" % [label, index]
		if not (rule_value is Dictionary):
			errors.append("%s must be a Dictionary" % location)
			continue

		var rule: Dictionary = rule_value
		for field in [id_field, "region_id", "mountain_id"]:
			var field_value: Variant = rule.get(field)
			if not (field_value is String) or field_value.is_empty():
				errors.append("%s %s must be a non-empty string" % [location, field])

		var spawn_weight: Variant = rule.get("spawn_weight")
		if not _is_number(spawn_weight) or float(spawn_weight) < 0.0:
			errors.append("%s spawn_weight must be a non-negative number" % location)

		if requires_count_range:
			var min_count: Variant = rule.get("min_count")
			var max_count: Variant = rule.get("max_count")
			if not _is_positive_int(min_count):
				errors.append("%s min_count must be a positive integer" % location)
			if not _is_positive_int(max_count):
				errors.append("%s max_count must be a positive integer" % location)
			if _is_positive_int(min_count) and _is_positive_int(max_count) and min_count > max_count:
				errors.append("%s min_count must be <= max_count" % location)

		if label == "spawn":
			var tags: Variant = rule.get("tags")
			if not _is_non_empty_string_array(tags):
				errors.append("%s tags must be a non-empty string Array" % location)
		if label == "encounter":
			var behavior_hint: Variant = rule.get("behavior_hint")
			if not (behavior_hint is String) or behavior_hint.is_empty():
				errors.append("%s behavior_hint must be a non-empty string" % location)

		if (
			rule.get(id_field) is String
			and rule.get("region_id") is String
			and rule.get("mountain_id") is String
		):
			var unique_key := "%s/%s/%s" % [
				rule.get("region_id"),
				rule.get("mountain_id"),
				rule.get(id_field)
			]
			if seen_keys.has(unique_key):
				errors.append("%s duplicates %s" % [location, unique_key])
			seen_keys[unique_key] = true

	return errors


func _validate_rule_references(regions_by_id: Dictionary, rule_sets: Array) -> String:
	var mountain_ids_by_region := {}
	for region_id in regions_by_id:
		var region_data: Variant = regions_by_id[region_id]
		if not (region_data is Dictionary):
			continue
		var mountains: Variant = region_data.get("mvp_mountains")
		if not (mountains is Array):
			continue

		var mountain_ids := {}
		for mountain in mountains:
			if mountain is Dictionary and mountain.get("id") is String:
				mountain_ids[mountain["id"]] = mountain
		mountain_ids_by_region[region_id] = mountain_ids

	for rule_set in rule_sets:
		for rule in rule_set["data"]["rules"]:
			var region_id: String = rule["region_id"]
			var mountain_id: String = rule["mountain_id"]
			if not mountain_ids_by_region.has(region_id):
				return "%s rule references unknown region %s" % [rule_set["label"], region_id]
			if not mountain_ids_by_region[region_id].has(mountain_id):
				return "%s rule references unknown mountain %s/%s" % [
					rule_set["label"],
					region_id,
					mountain_id
				]
			var declaration_field: String = rule_set["declaration_field"]
			if not declaration_field.is_empty():
				var mountain: Dictionary = mountain_ids_by_region[region_id][mountain_id]
				if not mountain[declaration_field].has(rule[rule_set["id_field"]]):
					return "%s rule id %s is not declared by %s/%s" % [
						rule_set["label"],
						rule[rule_set["id_field"]],
						region_id,
						mountain_id
					]
	return ""


func _generate_rule_entries(
	rules: Array,
	id_field: String,
	region_id: String,
	mountain_id: String,
	rng: Variant
) -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	for rule in rules:
		if rule["region_id"] != region_id or rule["mountain_id"] != mountain_id:
			continue
		if float(rule["spawn_weight"]) <= 0.0:
			continue
		generated.append({
			"id": rule[id_field],
			"count": rng.next_int(int(rule["min_count"]), int(rule["max_count"]))
		})
	return generated


func _load_json_file(path: String, label: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["%s file not found: %s" % [label, path]])
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["failed to open %s file: %s" % [label, path]])
		}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray([
				"failed to parse %s file %s at line %d: %s" % [
					label,
					path,
					json.get_error_line(),
					json.get_error_message()
				]
			])
		}

	if not (json.data is Dictionary):
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["%s file must contain a Dictionary" % label])
		}

	return {
		"ok": true,
		"data": json.data,
		"errors": PackedStringArray()
	}


func _fail(message: String) -> Dictionary:
	last_error = message
	return {}


func _join_errors(errors: Variant) -> String:
	var messages := PackedStringArray()
	for error in errors:
		messages.append(str(error))
	return "; ".join(messages)


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _is_positive_int(value: Variant) -> bool:
	return (value is int or (value is float and floorf(value) == value)) and value > 0


func _is_non_empty_string_array(value: Variant) -> bool:
	if not (value is Array) or value.is_empty():
		return false
	for entry in value:
		if not (entry is String) or entry.is_empty():
			return false
	return true
