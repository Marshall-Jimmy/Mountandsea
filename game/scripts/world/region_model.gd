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
		errors.append("region must be a Dictionary")
		return errors

	if not _is_positive_version(data.get("version")):
		errors.append("region version must be a positive integer")
	_require_non_empty_string(data, "id", "region", errors)
	_require_non_empty_string(data, "name", "region", errors)

	var mountains: Variant = data.get("mvp_mountains")
	if not (mountains is Array) or mountains.is_empty():
		errors.append("region mvp_mountains must be a non-empty Array")
		return errors

	var mountain_ids := {}
	for index in range(mountains.size()):
		var mountain_value: Variant = mountains[index]
		var location := "region mvp_mountains[%d]" % index
		if not (mountain_value is Dictionary):
			errors.append("%s must be a Dictionary" % location)
			continue

		var mountain: Dictionary = mountain_value
		_require_non_empty_string(mountain, "id", location, errors)
		_require_non_empty_string(mountain, "name", location, errors)
		_require_string_array(mountain, "biomes", location, errors)
		_require_string_array(mountain, "resources", location, errors)
		_require_string_array(mountain, "creatures", location, errors)

		var spawn_weight: Variant = mountain.get("spawn_weight")
		if not _is_number(spawn_weight) or float(spawn_weight) < 0.0:
			errors.append("%s spawn_weight must be a non-negative number" % location)

		var mountain_id: Variant = mountain.get("id")
		if mountain_id is String and not mountain_id.is_empty():
			if mountain_ids.has(mountain_id):
				errors.append("%s duplicates mountain id %s" % [location, mountain_id])
			mountain_ids[mountain_id] = true

	return errors


static func _parse_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["region file not found: %s" % path])
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray(["failed to open region file: %s" % path])
		}

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return {
			"ok": false,
			"data": {},
			"errors": PackedStringArray([
				"failed to parse region file %s at line %d: %s" % [
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


static func _require_string_array(
	data: Dictionary,
	field: String,
	location: String,
	errors: PackedStringArray
) -> void:
	var values: Variant = data.get(field)
	if not (values is Array):
		errors.append("%s %s must be an Array" % [location, field])
		return
	for index in range(values.size()):
		var value: Variant = values[index]
		if not (value is String) or value.is_empty():
			errors.append("%s %s[%d] must be a non-empty string" % [location, field, index])


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


static func _is_positive_version(value: Variant) -> bool:
	return (value is int or (value is float and floorf(value) == value)) and value > 0
