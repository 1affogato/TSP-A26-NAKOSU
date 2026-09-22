class_name MinigameStats
extends RefCounted
## Statistics of one minigame inside one department (UC-11, "MinigameStats").
##
## Maps to one entry of `user://save/minigame_stats.json`.
##
## UC-11 nests this class inside [DepartmentStats], but the file is a flat
## list, so each entry also carries the `department` it belongs to. That keeps
## the JSON readable and lets `DbService` regroup entries per department.
##
## `id` is derived from "department + minigame" instead of being random: it
## makes the file self-explanatory and makes it impossible to end up with two
## entries for the same minigame.

var id: String = ""
var department: Enums.Department = Enums.Department.DATA_STRUCTURES
## Key the minigame engine (B5) identifies itself with, e.g. "quiz".
var minigame_id: String = ""
## Name shown on the stats screen.
var minigame_name: String = ""
var games_played: int = 0
var games_won: int = 0
var games_lost: int = 0
var highest_score: int = 0
var current_elo: float = DbDefaults.STARTING_ELO
var total_time_played_seconds: int = 0


## Builds an empty record for one minigame.
static func create(
	department: Enums.Department,
	minigame_id: String,
	minigame_name: String = "",
	elo: float = 0.0
) -> MinigameStats:
	var stats := MinigameStats.new()
	stats.department = department
	stats.minigame_id = minigame_id
	stats.minigame_name = minigame_name if not minigame_name.is_empty() else minigame_id
	stats.current_elo = elo if elo > 0.0 else DbDefaults.STARTING_ELO
	stats.id = make_id(department, minigame_id)
	return stats


## Rebuilds stats from parsed JSON. The counters are stored instead of being
## recomputed from the history so the file stays usable on its own.
static func from_dict(data: Dictionary) -> MinigameStats:
	var stats := MinigameStats.new()
	stats.department = Enums.department_from_key(JsonUtil.as_string(data.get("department")))
	stats.minigame_id = JsonUtil.as_string(data.get("minigame_id"))
	stats.minigame_name = JsonUtil.as_string(data.get("minigame_name"), stats.minigame_id)
	stats.id = JsonUtil.as_string(data.get("id"), make_id(stats.department, stats.minigame_id))
	stats.games_played = maxi(0, JsonUtil.as_int(data.get("games_played")))
	stats.games_won = clampi(JsonUtil.as_int(data.get("games_won")), 0, stats.games_played)
	stats.games_lost = clampi(
		JsonUtil.as_int(data.get("games_lost")),
		0,
		stats.games_played - stats.games_won
	)
	stats.highest_score = maxi(0, JsonUtil.as_int(data.get("highest_score")))
	stats.current_elo = maxf(0.0, JsonUtil.as_float(data.get("current_elo"), DbDefaults.STARTING_ELO))
	stats.total_time_played_seconds = maxi(0, JsonUtil.as_int(data.get("total_time_played_seconds")))
	return stats


## Plain data for `JSON.stringify()`. The keys are the JSON field names.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"department": Enums.department_to_key(department),
		"minigame_id": minigame_id,
		"minigame_name": minigame_name,
		"games_played": games_played,
		"games_won": games_won,
		"games_lost": games_lost,
		"highest_score": highest_score,
		"current_elo": current_elo,
		"total_time_played_seconds": total_time_played_seconds,
	}


## Stable id of the entry, e.g. "SOFTWARE_DEV__quiz".
static func make_id(department: Enums.Department, minigame_id: String) -> String:
	return "%s__%s" % [Enums.department_to_key(department), minigame_id]


## UC-11 `calculateWinRate()`. Returns 0.0 while no game has been played.
func calculate_win_rate() -> float:
	if games_played == 0:
		return 0.0
	return float(games_won) / float(games_played)


## UC-11 `recordGameResult()`. `won` decides which counter grows, `score` only
## replaces `highest_score` when it is better.
func record_game_result(won: bool, score: int = 0, duration_seconds: int = 0) -> void:
	games_played += 1
	if won:
		games_won += 1
	else:
		games_lost += 1
	highest_score = maxi(highest_score, score)
	total_time_played_seconds = maxi(0, total_time_played_seconds + duration_seconds)
