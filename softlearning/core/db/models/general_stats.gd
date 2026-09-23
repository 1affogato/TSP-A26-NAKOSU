class_name GeneralStats
extends Resource
## General view of one department (UC-11.3, "GeneralStats").
##
## A computed snapshot: [StatisticsTracker] builds a new one on every call from
## the history, so there are no counters to keep in sync (B6).

@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var total_played: int = 0
@export var total_correct: int = 0
## True when the department meets its level-up condition (UC-11.3.a1). B6 asks
## [DepartmentManager] for it; the level change itself is UC-12.
@export var upgrade_available: bool = false


## Matches the `«create»` of the UC-11 sequence diagram.
static func create(
	new_department: Enums.Department,
	played: int,
	correct: int,
	can_upgrade: bool
) -> GeneralStats:
	var stats := GeneralStats.new()
	stats.department = new_department
	stats.total_played = played
	stats.total_correct = correct
	stats.upgrade_available = can_upgrade
	return stats


## Share of correct answers. Returns 0.0 while nothing has been played.
func get_accuracy() -> float:
	if total_played == 0:
		return 0.0
	return float(total_correct) / float(total_played)
