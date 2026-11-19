class_name StackPuzzle
extends Resource
## One puzzle of the Stack Puzzle pool (UC-06.1): input sequence held in an
## input structure (Queue, Deque or Priority Queue), target output, starting
## attempts, reference solution and a short explanation.
##
## Authored content that lives in StackPuzzlePool (B2); StackPuzzleMinigame
## receives exactly one (UC-06.1). The reference solution is authored as tokens
## (D2) so the .tres stays readable; get_valid_sequence() turns it into the
## operations the engine and the view handle.

enum InputStructure { QUEUE, DEQUE, PRIORITY_QUEUE }
enum PriorityMode { NONE, MAX, MIN }

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
@export var input_structure: InputStructure = InputStructure.QUEUE
@export var priority_mode: PriorityMode = PriorityMode.NONE
@export var input_sequence: Array[int] = []
@export var target_output: Array[int] = []
@export var max_attempts: int = 3
## Reference solution as tokens ("PUSH", "PUSH_FRONT", "PUSH_REAR", "POP").
@export var solution: PackedStringArray = PackedStringArray()
@export var explanation: String = ""


## Level variant (UC-06 "Level variants"): how the input structure delivers the
## next element. The view paints it next to the input sequence.
func get_delivery_rule() -> String:
	match input_structure:
		InputStructure.DEQUE:
			return "El PUSH toma el extremo que elijas (frente o final)"
		InputStructure.PRIORITY_QUEUE:
			if priority_mode == PriorityMode.MIN:
				return "Prioridad mínima · el PUSH toma el menor"
			return "Prioridad máxima · el PUSH toma el mayor"
		_:
			return "FIFO · el PUSH toma el elemento del frente"


func is_deque_level() -> bool:
	return input_structure == InputStructure.DEQUE


func is_priority_level() -> bool:
	return input_structure == InputStructure.PRIORITY_QUEUE


## UC-06.1: the authored solution as operations. Empty when a token is unknown.
func get_valid_sequence() -> Array[StackOperation]:
	var operations: Array[StackOperation] = []
	for token in solution:
		var operation := StackOperation.from_token(token)
		if operation == null:
			return []
		operations.append(operation)
	return operations


## D4: the input as it is delivered. Queue and Deque keep the authored order
## (front...rear); a Priority Queue is sorted by priority, MAX descending and
## MIN ascending.
func initial_input_state() -> Array[int]:
	var state: Array[int] = input_sequence.duplicate()
	if is_priority_level():
		state.sort()
		if priority_mode == PriorityMode.MAX:
			state.reverse()
	return state


## Structural check only (D13): it never simulates, so the pool and this model
## do not depend on StackPuzzleSimulator. Whether the solution reaches the
## target is checked by StackPuzzlePool.validate() and the test.
func is_valid() -> bool:
	if input_sequence.is_empty() or target_output.size() != input_sequence.size():
		return false

	# Every element is a positive integer and appears once inside the puzzle.
	var input_set := {}
	for element in input_sequence:
		if element < 1 or input_set.has(element):
			return false
		input_set[element] = true
	var target_set := {}
	for element in target_output:
		if element < 1 or target_set.has(element) or not input_set.has(element):
			return false
		target_set[element] = true
	if target_set.size() != input_set.size():
		return false

	# Only a Priority Queue level carries a priority mode.
	if is_priority_level():
		if priority_mode != PriorityMode.MAX and priority_mode != PriorityMode.MIN:
			return false
	elif priority_mode != PriorityMode.NONE:
		return false

	if max_attempts < 1 or max_attempts > 5:
		return false

	if solution.is_empty():
		return false
	for token in solution:
		if StackOperation.from_token(token) == null:
			return false

	return not explanation.strip_edges().is_empty()
