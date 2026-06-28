extends RefCounted

var last_error := ""

var _entries: Array[Dictionary] = []


func _init(source: Variant = null) -> void:
	if source != null:
		load_entries(source)


func add(entry_or_id: Variant, weight: Variant = null) -> bool:
	last_error = ""
	var entry_id: Variant = entry_or_id
	var entry_weight: Variant = weight

	if entry_or_id is Dictionary:
		entry_id = entry_or_id.get("id", "")
		entry_weight = entry_or_id.get("weight", null)

	if not (entry_id is String) or entry_id.is_empty():
		last_error = "weighted entry id must be a non-empty string"
		return false
	if not _is_number(entry_weight):
		last_error = "weighted entry %s requires a numeric weight" % entry_id
		return false

	_entries.append({
		"id": entry_id,
		"weight": maxf(float(entry_weight), 0.0)
	})
	return true


func load_entries(source: Variant) -> bool:
	last_error = ""
	_entries.clear()

	if source is Array:
		for entry in source:
			if not add(entry):
				_entries.clear()
				return false
		return true

	if source is Dictionary:
		if source.has("id") or source.has("weight"):
			return add(source)

		var ids: Array = source.keys()
		ids.sort()
		for entry_id in ids:
			if not add(entry_id, source[entry_id]):
				_entries.clear()
				return false
		return true

	last_error = "weighted table source must be an Array or Dictionary"
	return false


func pick(rng: Variant) -> Variant:
	last_error = ""
	if rng == null or not rng.has_method("next_float"):
		last_error = "weighted table requires a seeded rng"
		return null
	if _entries.is_empty():
		last_error = "weighted table is empty"
		return null

	var total := total_weight()
	if total <= 0.0:
		last_error = "weighted table total weight must be greater than zero"
		return null

	var roll := float(rng.call("next_float")) * total
	var running_total := 0.0
	var last_positive_id: Variant = null
	for entry in _entries:
		var entry_weight := float(entry["weight"])
		if entry_weight <= 0.0:
			continue
		last_positive_id = entry["id"]
		running_total += entry_weight
		if roll < running_total:
			return entry["id"]

	return last_positive_id


func total_weight() -> float:
	var total := 0.0
	for entry in _entries:
		total += float(entry["weight"])
	return total


func entries() -> Array[Dictionary]:
	return _entries.duplicate(true)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
