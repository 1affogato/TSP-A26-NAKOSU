class_name ResultRecord
extends Resource
## One finished minigame (UC-02, "ResultRecord").
##
## `StatisticsTracker` (B6) creates one per game with `create()`, and `DbService`
## stores it as a single line of `user://save/result_history.jsonl`. The file is
## an append-only log — one JSON object per line — so the history grows forever
## without ever rewriting what is already saved.
##
## `type` is the key of the concrete minigame engine (B5) that produced the
## result, `level` is the difficulty that was played, and `timestamp` is unix
## seconds (UTC) of the moment the game ended.

@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var type: String = ""
@export var level: Enums.Difficulty = Enums.Difficulty.FACIL
@export var success: bool = false
@export var timestamp: int = 0


## Builds the record of a game that just ended. `now_unix` exists so tests can
## inject a fixed time instead of reading the clock.
static func create(
	minigame_type: String,
	new_department: Enums.Department,
	new_level: Enums.Difficulty,
	was_success: bool,
	now_unix: int = -1
) -> ResultRecord:
	var record := ResultRecord.new()
	record.type = minigame_type
	record.department = new_department
	record.level = new_level
	record.success = was_success
	record.timestamp = now_unix if now_unix > 0 else int(Time.get_unix_time_from_system())
	return record


## One line of the log, without the trailing newline (the caller adds it).
func to_json_line() -> String:
	return JSON.stringify(to_dict())


## Plain data for `JSON.stringify()`. Enums are written as their name, not as
## their index, so the log stays readable and survives a reordering of the
## enum values.
func to_dict() -> Dictionary:
	return {
		"department": Enums.department_to_key(department),
		"type": type,
		"level": Enums.difficulty_to_key(level),
		"success": success,
		"timestamp": timestamp,
	}


## Rebuilds a record from an already parsed JSON object.
static func from_dict(data: Dictionary) -> ResultRecord:
	var record := ResultRecord.new()
	record.department = Enums.department_from_key(JsonUtil.as_string(data.get("department")))
	record.type = JsonUtil.as_string(data.get("type"))
	record.level = Enums.difficulty_from_key(JsonUtil.as_string(data.get("level")))
	record.success = JsonUtil.as_bool(data.get("success"))
	record.timestamp = maxi(0, JsonUtil.as_int(data.get("timestamp")))
	return record


## Reads one line of the log. Returns null for a blank or broken line, so a
## truncated last line (a crash while appending) cannot break the whole history.
static func from_json_line(line: String) -> ResultRecord:
	var trimmed := line.strip_edges()
	if trimmed.is_empty():
		return null
	var parsed: Variant = JSON.parse_string(trimmed)
	if parsed is Dictionary:
		return from_dict(parsed as Dictionary)
	push_warning("ResultRecord: línea del historial ilegible, se ignora: %s" % trimmed)
	return null


## `timestamp` as a readable UTC date ("" when it was never set).
func timestamp_iso() -> String:
	if timestamp <= 0:
		return ""
	return Time.get_datetime_string_from_unix_time(timestamp, true)
