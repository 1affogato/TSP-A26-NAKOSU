class_name MinigameResult
extends Resource
## What one finished minigame produced: the output of the Minigame contract
## (B3), carried by its `finished` signal (UC-02.5).
##
## SessionOrchestrator (B4) hands it to DepartmentManager (B1), which adjusts
## the ELO with it, and to StatisticsTracker (B6), which turns it into the
## ResultRecord that ends up saved. The result itself is never stored.

## Key of the engine (B5) that produced it, e.g. `QuizMinigame.TYPE`.
@export var type: String = ""
@export var success: bool = false
## Difficulty of the item that was played.
@export var level: Enums.Difficulty = Enums.Difficulty.FACIL
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES


static func create(
	minigame_type: String,
	was_success: bool,
	new_level: Enums.Difficulty,
	new_department: Enums.Department
) -> MinigameResult:
	var result := MinigameResult.new()
	result.type = minigame_type
	result.success = was_success
	result.level = new_level
	result.department = new_department
	return result
