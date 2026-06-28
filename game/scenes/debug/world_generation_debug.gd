extends Control

const WorldGenerator := preload("res://scripts/world/world_generator.gd")
const WorldMapModel := preload("res://scripts/world/world_map_model.gd")
const RegionModel := preload("res://scripts/world/region_model.gd")

const WORLD_MAP_PATH := "res://data/world/world_map.json"
const TEST_SEED_42 := 42
const TEST_SEED_20260629 := 20260629

@onready var default_seed_button: Button = %DefaultSeedButton
@onready var seed_42_button: Button = %Seed42Button
@onready var seed_20260629_button: Button = %Seed20260629Button
@onready var regenerate_button: Button = %RegenerateButton
@onready var summary_label: RichTextLabel = %SummaryLabel

var default_seed := 0
var current_seed := 0
var last_generation_result := {}
var last_summary := ""

var _world_map_data := {}
var _regions_by_id := {}


func _ready() -> void:
	default_seed_button.pressed.connect(_on_default_seed_pressed)
	seed_42_button.pressed.connect(_on_seed_42_pressed)
	seed_20260629_button.pressed.connect(_on_seed_20260629_pressed)
	regenerate_button.pressed.connect(_on_regenerate_pressed)

	if not _load_world_context():
		return

	default_seed = int(_world_map_data.get("default_seed", 0))
	if default_seed == 0:
		show_failure("world map default_seed must be a non-zero integer")
		return

	default_seed_button.text = "Seed: default (%d)" % default_seed
	generate_for_seed(default_seed)


func generate_for_seed(seed_value: int) -> bool:
	current_seed = seed_value
	var generator := WorldGenerator.new()
	var generated := generator.generate_from_files(seed_value)
	if generated.is_empty():
		var message: String = generator.last_error
		if message.is_empty():
			message = "generator returned an empty result"
		show_failure(message)
		return false

	last_generation_result = generated.duplicate(true)
	last_summary = build_debug_summary(
		last_generation_result,
		_world_map_data,
		_regions_by_id
	)
	summary_label.text = last_summary
	return true


func regenerate_current_seed() -> bool:
	return generate_for_seed(current_seed)


func show_failure(message: String) -> String:
	var detail := message.strip_edges()
	if detail.is_empty():
		detail = "unknown generation error"
	detail = detail.replace("; ", "\n- ")
	last_generation_result = {}
	last_summary = "World generation failed:\n- %s" % detail
	summary_label.text = last_summary
	return last_summary


static func build_debug_summary(
	result: Dictionary,
	world_map_data: Dictionary,
	regions_by_id: Dictionary
) -> String:
	if result.is_empty():
		return ""

	var starting_region_id := str(result.get("starting_region_id", "unknown"))
	var starting_mountain_id := str(result.get("starting_mountain_id", "unknown"))
	var resources := _collect_generated_entries(result, "resources")
	var encounters := _collect_generated_entries(result, "encounters")
	var result_counts := _count_generated_result(result)
	var lines := PackedStringArray([
		"World Generation Debug",
		"",
		"Seed: %s" % str(result.get("seed", "unknown")),
		"Starting Region: %s" % _format_named_id(
			starting_region_id,
			_find_region_name(starting_region_id, world_map_data, regions_by_id)
		),
		"Starting Mountain: %s" % _format_named_id(
			starting_mountain_id,
			_find_mountain_name(starting_region_id, starting_mountain_id, regions_by_id)
		),
		"Player Spawn: %s" % str(result.get("player_spawn_id", "unknown")),
		"",
		"Resources:"
	])
	_append_generated_entry_lines(lines, resources)
	lines.append("")
	lines.append("Encounters:")
	_append_generated_entry_lines(lines, encounters)
	lines.append("")
	lines.append("Generation Result Summary:")
	lines.append("- Regions: %d" % result_counts["regions"])
	lines.append("- Mountains: %d" % result_counts["mountains"])
	lines.append("- Resource Types: %d" % resources["order"].size())
	lines.append("- Resource Instances: %d" % resources["total"])
	lines.append("- Encounter Types: %d" % encounters["order"].size())
	lines.append("- Encounter Instances: %d" % encounters["total"])
	return "\n".join(lines)


func _load_world_context() -> bool:
	var world_result := WorldMapModel.load_file(WORLD_MAP_PATH)
	if not world_result["ok"]:
		show_failure("world map load failed: %s" % _join_errors(world_result["errors"]))
		return false

	_world_map_data = world_result["data"]
	_regions_by_id = {}
	for region_reference in _world_map_data["regions"]:
		var region_path: String = region_reference["region_file"]
		var region_result := RegionModel.load_file(region_path)
		if not region_result["ok"]:
			show_failure(
				"region load failed for %s: %s" % [
					region_path,
					_join_errors(region_result["errors"])
				]
			)
			return false
		_regions_by_id[region_reference["id"]] = region_result["data"]
	return true


func _on_default_seed_pressed() -> void:
	generate_for_seed(default_seed)


func _on_seed_42_pressed() -> void:
	generate_for_seed(TEST_SEED_42)


func _on_seed_20260629_pressed() -> void:
	generate_for_seed(TEST_SEED_20260629)


func _on_regenerate_pressed() -> void:
	regenerate_current_seed()


static func _collect_generated_entries(result: Dictionary, entry_field: String) -> Dictionary:
	var order := PackedStringArray()
	var counts := {}
	var total := 0
	var generated_regions: Variant = result.get("generated_regions", {})
	if not (generated_regions is Dictionary):
		return {"order": order, "counts": counts, "total": total}

	for region_id in generated_regions:
		var region_result: Variant = generated_regions[region_id]
		if not (region_result is Dictionary):
			continue
		var mountains: Variant = region_result.get("mountains", {})
		if not (mountains is Dictionary):
			continue
		for mountain_id in mountains:
			var mountain_result: Variant = mountains[mountain_id]
			if not (mountain_result is Dictionary):
				continue
			var entries: Variant = mountain_result.get(entry_field, [])
			if not (entries is Array):
				continue
			for entry in entries:
				if not (entry is Dictionary):
					continue
				var entry_id := str(entry.get("id", "unknown"))
				var count := int(entry.get("count", 0))
				if not counts.has(entry_id):
					order.append(entry_id)
					counts[entry_id] = 0
				counts[entry_id] += count
				total += count

	return {"order": order, "counts": counts, "total": total}


static func _count_generated_result(result: Dictionary) -> Dictionary:
	var region_count := 0
	var mountain_count := 0
	var generated_regions: Variant = result.get("generated_regions", {})
	if generated_regions is Dictionary:
		region_count = generated_regions.size()
		for region_id in generated_regions:
			var region_result: Variant = generated_regions[region_id]
			if region_result is Dictionary and region_result.get("mountains") is Dictionary:
				mountain_count += region_result["mountains"].size()
	return {"regions": region_count, "mountains": mountain_count}


static func _append_generated_entry_lines(lines: PackedStringArray, entries: Dictionary) -> void:
	var order: PackedStringArray = entries["order"]
	if order.is_empty():
		lines.append("- none")
		return
	for entry_id in order:
		lines.append("- %s: %d" % [entry_id, entries["counts"][entry_id]])


static func _find_region_name(
	region_id: String,
	world_map_data: Dictionary,
	regions_by_id: Dictionary
) -> String:
	var region_references: Variant = world_map_data.get("regions", [])
	if region_references is Array:
		for region_reference in region_references:
			if region_reference is Dictionary and region_reference.get("id") == region_id:
				var display_name := str(
					region_reference.get("display_name", region_reference.get("name", ""))
				)
				if not display_name.is_empty():
					return display_name
	var region_data: Variant = regions_by_id.get(region_id, {})
	if region_data is Dictionary:
		return str(region_data.get("name", ""))
	return ""


static func _find_mountain_name(
	region_id: String,
	mountain_id: String,
	regions_by_id: Dictionary
) -> String:
	var region_data: Variant = regions_by_id.get(region_id, {})
	if not (region_data is Dictionary):
		return ""
	var mountains: Variant = region_data.get("mvp_mountains", [])
	if not (mountains is Array):
		return ""
	for mountain in mountains:
		if mountain is Dictionary and mountain.get("id") == mountain_id:
			return str(mountain.get("name", ""))
	return ""


static func _format_named_id(identifier: String, display_name: String) -> String:
	if display_name.is_empty() or display_name == identifier:
		return identifier
	return "%s / %s" % [identifier, display_name]


static func _join_errors(errors: Variant) -> String:
	var messages := PackedStringArray()
	for error in errors:
		messages.append(str(error))
	return "; ".join(messages)
