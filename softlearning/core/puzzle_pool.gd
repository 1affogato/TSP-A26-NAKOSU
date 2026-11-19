class_name PuzzlePool
extends ContentPool
## Concept Puzzle pool (B2) of UC-05. Difficulty choice and draw without
## repeats live in ContentPool. Only Coding Paradigms (CODING) has puzzles:
## the minigame is specific to that department.

@export var puzzles: Array[ConceptPuzzle]


## UC-05.1
func get_puzzle(department: Enums.Department, elo: float) -> ConceptPuzzle:
	return _pick(puzzles, department, elo)
