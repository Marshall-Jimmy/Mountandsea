extends RefCounted


static func load_file(path: String) -> Dictionary:
	var parsed := _parse_json_file(path)
	if not parsed["ok"]:
		return parsed

	var errors := validate_data(parsed["data"])
	return {
		"ok": errors.is_empty(),
		"data": parsed["data"],
		"errors": errors
	}


static func validate_data(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not (data is Dictionary):
		errors.append("world map must be a Dictionary")
		return errors

	if not _is_positive_version(data.get("version")):
		errors.append("world map version must be a positive integer")
	if not _is_integer_value(data.get("default_seed")):
		errors.append("world map default_seed must be an integer")

	var regions: Variant = data.get("regions")
	if not (regions is Array) or regions.is_empty():
		errors.append("world map regions must be a non-empty Array")
		return errors

	var region_ids := {}
	for index in range(regions.size()):
		var region_value: Variant = regions[index]
		var location := "world map regions[%d]" % index
		if not (region_value is Dictionary):
			errors.append("%s must be a Dictionary" % location)
			continue

		var region: Dictionary = region_value
		_require_non_empty_string(region, "id", location, errors)
		_require_non_empty_string(region, "name", location, errors)
		_require_non_empty_string(region, "display_name", location, errors)
		_require_non_empty_string(region, "region_file", location, errors)
		if not (region.get("mvp") is bool):
			errors.append("%s mvp must be a bool" % location)

		var region_id: Variant = region.get("id")
		if region_id is String and not region_id.is_empty():
			if region_ids.has(region_id):
				errors.append("%s duplicates region id %s" % [location, region_id])
			region_ids[region_id] = true

		var region_file: Variant = region.get("region_file")
		if region_file is String and not region_file.begins_with("res://"):
			errors.append("%s region_file must use a res:// path" % location)

	var starting_regions: Variant = data.get("starting_regions")
	if not (starting_regions is Array) or starting_regions.is_empty():
		errors.append("world map starting_regions must be a non-empty Array")
	else:
		for index in range(starting_regions.size()):
			var region_id: Variant = starting_regions[index]
			if not (region_id is String) or region_id.is_empty():
				errors.append("world map starting_regions[%d] must be a non-empty string" % index)
			elif not region_ids.has(region_id):
				errors.append("world map starting region does not exist: %s" % region_id)

	return errors


static func _parse_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["world map file not found: %s" % path])
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["failed to open world map file: %s" % path])
		}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray([
				"failed to parse world map file %s at line %d: %s" % [
					path,
					json.get_error_line(),
					json.get_error_message()
				]
			])
		}

	return {
		"ok": true,
		"data": json.data,
		"errors": PackedStringArray()
	}


static func _require_non_empty_string(
	data: Dictionary,
	field: String,
	location: String,
	errors: PackedStringArray
) -> void:
	var value: Variant = data.get(field)
	if not (value is String) or value.is_empty():
		errors.append("%s %s must be a non-empty string" % [location, field])


static func _is_positive_version(value: Variant) -> bool:
	return _is_integer_value(value) and value > 0


static func _is_integer_value(value: Variant) -> bool:
	return value is int or (value is float and floorf(value) == value)
