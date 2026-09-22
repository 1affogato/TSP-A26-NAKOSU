class_name ResultRecord
extends RefCounted
## One finished minigame, as stored in `user://save/result_history.json`.
##
## This is the flat, persistable twin of `MinigameResult` (UC-02 / UC-07).
## The extra fields (`score`, `duration_seconds`, `minigame_name`) are what
## [MinigameStats] needs to update itself, and `timestamp_unix` replaces the
## "now" that `StatisticsTracker.register_result()` uses while the game runs.
##
## This file is an append-only log: it is the only place where every single
## game is still visible, so every aggregate in the save file could be
## recomputed from it if the rules ever change.

var department: Enums.Department = Enums.Department.DATA_STRUCTURES
## Key of the concrete minigame engine (B5) that produced this result.
var minigame_type: String = ""
var minigame_name: String = ""
## Difficulty played (UC-02 / UC-07, "level").
var level: Enums.Difficulty = Enums.Difficulty.FACIL
var success: bool = false
var score: int = 0
var duration_seconds: int = 0
var timestamp_unix: int = 0


## Builds a record for a game that just ended. `now_unix` exists so tests can
## inject a fixed timestamp.
static func create(
	minigame_type: String,
	department: Enums.Department,
	level: Enums.Difficulty,
	success: bool,
	score: int = 0,
	duration_seconds: int = 0,
	now_unix: int = -1
) -> ResultRecord:
	var record := ResultRecord.new()
	record.minigame_type = minigame_type
	record.minigame_name = minigame_type
	record.department = department
	record.level = level
	record.success = success
	record.score = score
	record.duration_seconds = duration_seconds
	record.timestamp_unix = now_unix if now_unix > 0 else int(Time.get_unix_time_from_system())
	return record


## Rebuilds a record from parsed JSON.
static func from_dict(data: Dictionary) -> ResultRecord:
	var record := ResultRecord.new()
	record.department = Enums.department_from_key(JsonUtil.as_string(data.get("department")))
	record.minigame_type = JsonUtil.as_string(data.get("minigame_type"))
	record.minigame_name = JsonUtil.as_string(data.get("minigame_name"), record.minigame_type)
	record.level = Enums.difficulty_from_key(JsonUtil.as_string(data.get("level")))
	record.success = JsonUtil.as_bool(data.get("success"))
	record.score = maxi(0, JsonUtil.as_int(data.get("score")))
	record.duration_seconds = maxi(0, JsonUtil.as_int(data.get("duration_seconds")))
	record.timestamp_unix = maxi(0, JsonUtil.as_int(data.get("timestamp_unix")))
	return record


## Plain data for `JSON.stringify()`. The keys are the JSON field names.
func to_dict() -> Dictionary:
	return {
		"department": Enums.department_to_key(department),
		"minigame_type": minigame_type,
		"minigame_name": minigame_name,
		"level": Enums.difficulty_to_key(level),
		"success": success,
		"score": score,
		"duration_seconds": duration_seconds,
		"timestamp_unix": timestamp_unix,
	}


## `timestamp_unix` as a readable UTC date ("" when unknown).
func timestamp_iso() -> String:
	if timestamp_unix <= 0:
		return ""
	return Time.get_datetime_string_from_unix_time(timestamp_unix, true)
