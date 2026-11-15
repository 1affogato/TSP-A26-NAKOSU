class_name CablePool
extends ContentPool
## Connect the Cables pool (B2) of UC-10. Difficulty choice and draw without
## repeats live in ContentPool.
##
## Unlike TrainPool and BombPool (one department each), this pool covers the four
## departments: UC-10 describes a general minigame usable everywhere, so the
## orchestrator (B4) lists it as generic.

@export var boards: Array[CableBoard]


## UC-10.1
func get_board(department: Enums.Department, elo: float) -> CableBoard:
	return _pick(boards, department, elo)
