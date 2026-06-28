extends RefCounted

var initial_seed: int
var last_error := ""

var _rng := RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	initial_seed = seed_value
	_rng.seed = seed_value


func next_int(min_value: int, max_value: int) -> int:
	last_error = ""
	if min_value > max_value:
		last_error = "next_int requires min_value <= max_value"
		return min_value
	return _rng.randi_range(min_value, max_value)


func next_float() -> float:
	last_error = ""
	return _rng.randf()


func choose(values: Array) -> Variant:
	last_error = ""
	if values.is_empty():
		last_error = "choose requires a non-empty array"
		return null
	return values[next_int(0, values.size() - 1)]
