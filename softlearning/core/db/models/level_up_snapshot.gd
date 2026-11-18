class_name LevelUpSnapshot
extends RefCounted
## UC-12.9.e1: what a level-up changed, kept so it can be undone when the new
## state cannot be saved. `DepartmentManager.snapshot()` creates it right before
## the scripted session starts and `rollback()` puts it back.
##
## It is plain in-memory data, never persisted: it only has to outlive one
## level-up session.

var department: Enums.Department = Enums.Department.DATA_STRUCTURES
var level: int = DepartmentState.STARTING_LEVEL
var elo: float = DepartmentState.STARTING_ELO
## `PlayerProgress.last_level_up_date` as it was before the session.
var last_level_up_date: String = ""


static func create(
	new_department: Enums.Department,
	new_level: int,
	new_elo: float,
	new_last_level_up_date: String
) -> LevelUpSnapshot:
	var snapshot := LevelUpSnapshot.new()
	snapshot.department = new_department
	snapshot.level = new_level
	snapshot.elo = new_elo
	snapshot.last_level_up_date = new_last_level_up_date
	return snapshot
