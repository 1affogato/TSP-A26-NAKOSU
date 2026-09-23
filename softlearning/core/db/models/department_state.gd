class_name DepartmentState
extends Resource
## Progress of the player inside one department (UC-02, "DepartmentState").
##
## This is a real resource: `DbService` writes one `.tres` per department under
## `user://save/`, so the file can be inspected (or fixed by hand) from the
## Godot editor between runs.
##
## `elo` and `level` live here and nowhere else. The rules that change them
## (`compute_elo_delta()`, `can_level_up()`) belong to `DepartmentManager`
## (B1), which owns the states while the game is running and hands them over
## through `SaveData` when a session ends.

const STARTING_LEVEL := 1
const STARTING_ELO := 1000.0

## Department this state belongs to. It is also what names the `.tres` file.
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var level: int = STARTING_LEVEL
@export var elo: float = STARTING_ELO


## A fresh state for one department.
static func create(new_department: Enums.Department) -> DepartmentState:
	var state := DepartmentState.new()
	state.department = new_department
	return state


## Keeps a hand-edited `.tres` inside the ranges the game expects.
func sanitize() -> void:
	level = maxi(STARTING_LEVEL, level)
	elo = maxf(0.0, elo)
