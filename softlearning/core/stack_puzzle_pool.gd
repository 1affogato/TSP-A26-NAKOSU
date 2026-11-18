class_name StackPuzzlePool
extends ContentPool
## Stack Puzzle pool (B2) of UC-06. Only Data Structures and Algorithms has
## puzzles: the minigame is specific to that department.
##
## Difficulty choice and draw without repeats live in ContentPool.

@export var puzzles: Array[StackPuzzle]


## UC-06.1
func get_puzzle(department: Enums.Department, elo: float) -> StackPuzzle:
	return _pick(puzzles, department, elo)


## Authoring check used by the test: every puzzle is structurally valid AND its
## reference solution simulates to a valid run that produces target_output.
## Returns one line per problem (empty when everything is authored right).
func validate() -> Array[String]:
	var problems: Array[String] = []
	for puzzle in puzzles:
		if puzzle == null:
			problems.append("A puzzle is null.")
			continue
		if not puzzle.is_valid():
			problems.append("Puzzle %d is not structurally valid." % puzzle.id)
			continue
		var run := StackPuzzleSimulator.simulate(puzzle, puzzle.get_valid_sequence())
		if not run.valid:
			var step := run.get_step(run.invalid_index)
			problems.append(
				"Puzzle %d reference solution is invalid at step %d: %s."
				% [puzzle.id, run.invalid_index, step.cause if step else ""]
			)
		elif not run.matches(puzzle.target_output):
			problems.append("Puzzle %d reference solution does not produce target_output." % puzzle.id)
	return problems
