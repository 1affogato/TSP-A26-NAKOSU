class_name StackPuzzleSimulator
extends RefCounted
## Pure simulation of a Stack Puzzle sequence (UC-06.7): starts from the
## puzzle's initial state and applies the operations in editor order until the
## first invalid one, which becomes the last step of the run.
##
## Nothing is mutated: the puzzle, the operations and the arrays handed in stay
## as they were (D3), so executing twice gives the same run.

static func simulate(puzzle: StackPuzzle, operations: Array[StackOperation]) -> SimulationRun:
	var run := SimulationRun.new()
	var input := puzzle.initial_input_state()
	var stack: Array[int] = []
	var produced: Array[int] = []

	for operation_index in operations.size():
		var operation := operations[operation_index]
		var step := SimulationStep.new()
		step.index = operation_index + 1
		step.operation = operation

		if operation.is_pop():
			if stack.is_empty():
				step.valid = false
				step.cause = "POP sobre un Stack vacío"
			else:
				step.element = int(stack.pop_back())
				produced.append(step.element)
		else:
			if input.is_empty():
				step.valid = false
				step.cause = "PUSH sobre una entrada vacía"
			else:
				step.element = _deliver(puzzle, operation, input)
				stack.append(step.element)

		step.input_state = input.duplicate()
		step.stack_state = stack.duplicate()
		step.produced_state = produced.duplicate()
		run.steps.append(step)

		if not step.valid:
			run.valid = false
			run.invalid_index = step.index
			break

	run.produced = produced.duplicate()
	return run


## Level variant (UC-06 "Level variants"): Queue takes the front, Deque the end
## the operation chose (NONE counts as the front, D10) and a Priority Queue the
## greatest or smallest element of the level's priority mode.
static func _deliver(puzzle: StackPuzzle, operation: StackOperation, input: Array[int]) -> int:
	match puzzle.input_structure:
		StackPuzzle.InputStructure.DEQUE:
			if operation.deque_end == StackOperation.DequeEnd.REAR:
				return int(input.pop_back())
			return int(input.pop_front())
		StackPuzzle.InputStructure.PRIORITY_QUEUE:
			var element := 0
			if puzzle.priority_mode == StackPuzzle.PriorityMode.MIN:
				element = int(input.min())
			else:
				element = int(input.max())
			input.erase(element)
			return element
		_:
			return int(input.pop_front())
