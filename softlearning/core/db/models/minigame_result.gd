class_name MinigameResult
extends Resource
## What a minigame hands over when it ends (block 3, the minigame contract).
##
## It is the pure data that travels from the engine (B5) to the session
## orchestrator (B4), and from there to [DepartmentManager] (ELO adjustment) and
## [StatisticsTracker] (record). It is never persisted: what gets stored is the
## [ResultRecord] that B6 builds out of it with the current time.
##
## Field order follows the diagram: `type`, `success`, `level`, `department`.

## Key of the minigame engine that produced the result, e.g. "quiz".
@export var type: String = ""
@export var success: bool = false
## Difficulty of the item that was played.
@export var level: Enums.Difficulty = Enums.Difficulty.FACIL
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES


## Builds the result of a game that just ended.
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
