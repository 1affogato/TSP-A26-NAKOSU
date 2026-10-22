class_name TrainPool
extends ContentPool
## Train Sorting pool (B2) of UC-03. Difficulty choice and draw without repeats
## live in ContentPool.

@export var sequences: Array[TrainSequence]


## UC-03.1
func get_sequence(department: Enums.Department, elo: float) -> TrainSequence:
	return _pick(sequences, department, elo)
