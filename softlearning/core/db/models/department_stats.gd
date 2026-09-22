class_name DepartmentStats
extends RefCounted
## Aggregated numbers for one department (UC-11, "DepartmentStats").
##
## Maps to one entry of `user://save/department_stats.json`.
##
## Two deliberate differences from the diagrams, to avoid duplicated state:
## - `elo` is kept here even though UC-11 does not list it, because UC-02
##   stores the rank per department (`DepartmentState.elo`) and the
##   `SessionOrchestrator` hands `department + elo` to every minigame.
## - `id` is the department name, which makes the file readable and enforces
##   the 1:1 relationship with `department`.
##
## `getMinigameStats()` (UC-11) lives on `DbService`, which owns the minigame
## list; see `DbService.get_minigame_stats_for()`.

var id: String = ""
var department: Enums.Department = Enums.Department.DATA_STRUCTURES
var current_level: int = DbDefaults.STARTING_LEVEL
var elo: float = DbDefaults.STARTING_ELO
var experience_points: int = 0
var total_games_played: int = 0
var total_games_won: int = 0


## Builds empty stats for one department.
static func create(department: Enums.Department) -> DepartmentStats:
	var stats := DepartmentStats.new()
	stats.department = department
	stats.id = Enums.department_to_key(department)
	return stats


## Rebuilds stats from parsed JSON, clamping every value to a sane range so a
## hand-edited file cannot produce impossible numbers (e.g. more wins than
## games played).
static func from_dict(data: Dictionary) -> DepartmentStats:
	var stats := DepartmentStats.new()
	stats.department = Enums.department_from_key(JsonUtil.as_string(data.get("department")))
	stats.id = Enums.department_to_key(stats.department)
	stats.current_level = maxi(
		DbDefaults.STARTING_LEVEL,
		JsonUtil.as_int(data.get("current_level"), DbDefaults.STARTING_LEVEL)
	)
	stats.elo = maxf(0.0, JsonUtil.as_float(data.get("elo"), DbDefaults.STARTING_ELO))
	stats.experience_points = maxi(0, JsonUtil.as_int(data.get("experience_points")))
	stats.total_games_played = maxi(0, JsonUtil.as_int(data.get("total_games_played")))
	stats.total_games_won = clampi(
		JsonUtil.as_int(data.get("total_games_won")),
		0,
		stats.total_games_played
	)
	return stats


## Plain data for `JSON.stringify()`. The keys are the JSON field names.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"department": Enums.department_to_key(department),
		"current_level": current_level,
		"elo": elo,
		"experience_points": experience_points,
		"total_games_played": total_games_played,
		"total_games_won": total_games_won,
	}


## UC-11 `getWinRate()`. Returns 0.0 while no game has been played, so callers
## never have to guard against a division by zero.
func get_win_rate() -> float:
	if total_games_played == 0:
		return 0.0
	return float(total_games_won) / float(total_games_played)


func get_losses() -> int:
	return total_games_played - total_games_won


## Applies one finished game to the aggregate numbers.
##
## `elo_delta` is computed by the caller: `DepartmentManager` (B1) owns the
## rules (`compute_elo_delta()`), this model only applies the result. The same
## goes for `current_level`, which B1 changes once the level-up thresholds are
## met (UC-02 / UC-11.3.a1).
func register_result(success: bool, score: int = 0, elo_delta: float = 0.0) -> void:
	total_games_played += 1
	if success:
		total_games_won += 1
	experience_points = maxi(0, experience_points + score)
	elo = maxf(0.0, elo + elo_delta)
