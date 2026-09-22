class_name JsonUtil
extends RefCounted
## Coercion helpers for values coming back from `JSON.parse_string()`.
##
## JSON has no integer, enum, boolean-in-number or timestamp type: every
## number is parsed as a `float`, keys are always `String`, and a field that
## was not written simply does not exist. Models therefore never read a raw
## field directly — they go through these helpers in `from_dict()`, which cast
## the value and fall back to a sane default when the file is incomplete or
## was written by an older version of the game.


## Returns `value` as an int, or `fallback` when it cannot be converted.
static func as_int(value: Variant, fallback: int = 0) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(value)
		TYPE_BOOL:
			return 1 if value else 0
		TYPE_STRING:
			var text := value as String
			return int(text) if text.is_valid_int() else fallback
	return fallback


## Returns `value` as a float, or `fallback` when it cannot be converted.
static func as_float(value: Variant, fallback: float = 0.0) -> float:
	match typeof(value):
		TYPE_FLOAT:
			return value
		TYPE_INT:
			return float(value)
		TYPE_BOOL:
			return 1.0 if value else 0.0
		TYPE_STRING:
			var text := value as String
			return float(text) if text.is_valid_float() else fallback
	return fallback


## Returns `value` as a bool, or `fallback` when it cannot be converted.
static func as_bool(value: Variant, fallback: bool = false) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return float(value) != 0.0
		TYPE_STRING:
			match (value as String).strip_edges().to_lower():
				"true", "1", "yes", "si", "sí":
					return true
				"false", "0", "no":
					return false
	return fallback


## Returns `value` as a String, or `fallback` when it is null/empty.
static func as_string(value: Variant, fallback: String = "") -> String:
	if value == null:
		return fallback
	var text := str(value)
	return fallback if text.is_empty() else text
