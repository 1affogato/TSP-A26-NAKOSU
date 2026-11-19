class_name StackPuzzleMinigame
extends Minigame
## Stack Puzzle engine (B5) of UC-06, specific to Data Structures and
## Algorithms. No time limit. StackPuzzleView follows the signals below.
##
## The player builds a sequence of PUSH and POP operations (UC-06.4), executes
## it (UC-06.6) and reviews the simulation step by step (UC-06.7.a2). The engine
## never talks to the view: it emits signals and the view calls it downward.
##
## A run is correct when it is valid and its produced output matches the target
## (D5). An invalid run and a mismatch spend exactly one attempt each, never
## both (D6). Reviewing the steps does not end the minigame: feedback_ready and
## finished are emitted only from show_result() (D7).

## UC-06.2 / UC-06.3
signal puzzle_ready(puzzle: StackPuzzle, attempts_left: int)
## UC-06.4 / UC-06.5
signal editor_changed(operations: Array[StackOperation], can_execute: bool)
## UC-06.7
signal simulation_ready(run: SimulationRun)
## UC-06.7 / UC-06.7.a2
signal step_shown(step: SimulationStep, index: int, total: int)
## UC-06.7.a1.2
signal simulation_invalid(index: int, cause: String, attempts_left: int)
## UC-06.8.a1.2
signal output_mismatch(produced: Array[int], target: Array[int], attempts_left: int)
## UC-06.9
signal feedback_ready(
	produced: Array[int], target: Array[int],
	solution: Array[StackOperation], explanation: String
)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "STACK_PUZZLE"
const POOL: StackPuzzlePool = preload("res://resources/stack_puzzle_pool.tres")

var puzzle: StackPuzzle
var operations: Array[StackOperation] = []
var attempts_left := 0
var max_attempts := 0
## Null while editing; the last execution while reviewing (D8).
var run: SimulationRun
## 1-based; 0 while editing.
var step_index := 0
var is_correct := false
## True from start() until the result is shown or the game is aborted.
var _waiting := false
var _result_decided := false


## UC-06.1 / UC-06.2: draws the puzzle and leaves the editor empty.
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	puzzle = POOL.get_puzzle(department, elo)
	if puzzle == null:
		return
	operations = []
	attempts_left = puzzle.max_attempts
	max_attempts = puzzle.max_attempts
	run = null
	step_index = 0
	is_correct = false
	_result_decided = false
	_waiting = true
	puzzle_ready.emit(puzzle, attempts_left)
	_emit_editor()


## UC-02.4.a1: the edited sequence, the run, the shown step and the attempts
## stay as they are.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


## UC-02.4.a2: ends right away without a result.
func abort() -> void:
	_waiting = false


## UC-06.4.a1 / UC-06.4.a3: inserts and emits the new sequence. On Deque levels
## the chosen end is stored; every other level forces NONE (D10).
func insert_operation(index: int, kind: StackOperation.OperationKind, end: StackOperation.DequeEnd) -> void:
	if not _can_edit():
		return
	index = clampi(index, 0, operations.size())
	end = _normalize_end(end)
	_discard_run()
	operations.insert(index, StackOperation.create(kind, end))
	_emit_editor()


## UC-06.4.a4
func remove_operation(index: int) -> void:
	if not _can_edit() or index < 0 or index >= operations.size():
		return
	_discard_run()
	operations.remove_at(index)
	_emit_editor()


## UC-06.4.a5: takes the operation out and puts it back at `to_index`, closing
## the gap. Both indexes are 0-based (D12).
func move_operation(from_index: int, to_index: int) -> void:
	if not _can_edit():
		return
	if from_index < 0 or from_index >= operations.size():
		return
	if to_index < 0 or to_index >= operations.size():
		return
	if from_index == to_index:
		return
	_discard_run()
	var operation := operations[from_index]
	operations.remove_at(from_index)
	operations.insert(to_index, operation)
	_emit_editor()


## UC-06.4.a6
func clear_operations() -> void:
	if not _can_edit():
		return
	operations.clear()
	_discard_run()
	_emit_editor()


## UC-06.5: at least one operation and no run in play.
func can_execute() -> bool:
	return _can_edit() and run == null and not operations.is_empty()


## UC-06.6 / UC-06.7: simulates once and resolves the attempt (5.7.2). The
## simulation_ready and first step_shown arrive before simulation_invalid or
## output_mismatch, so the view already has the run when it paints them.
func execute() -> void:
	if not can_execute():
		return
	run = StackPuzzleSimulator.simulate(puzzle, operations)
	step_index = 1
	simulation_ready.emit(run)
	step_shown.emit(run.get_step(1), 1, run.size())
	_resolve()


## UC-06.7.a2: moves inside 1..run.size() and emits only when the step changes.
## Never touches the attempts or the result.
func next_step() -> void:
	if run == null or not _waiting or paused or step_index >= run.size():
		return
	step_index += 1
	step_shown.emit(run.get_step(step_index), step_index, run.size())


func previous_step() -> void:
	if run == null or not _waiting or paused or step_index <= 1:
		return
	step_index -= 1
	step_shown.emit(run.get_step(step_index), step_index, run.size())


## UC-06.7.a1.3 / UC-06.8.a1.3: discards the run, keeps the operations, returns
## to the editor.
func edit_sequence() -> void:
	if not _can_edit():
		return
	_discard_run()
	_emit_editor()


## UC-06.7.a2 / UC-06.9: only once the result is decided, so the player reviews
## every step first.
func show_result() -> void:
	if not _waiting or not _result_decided:
		return
	_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, puzzle.difficulty, department)


func _can_edit() -> bool:
	return _waiting and not paused and not _result_decided


func _discard_run() -> void:
	run = null
	step_index = 0


func _emit_editor() -> void:
	editor_changed.emit(operations.duplicate(), can_execute())


## D10: only a Deque level keeps FRONT/REAR; the rest force NONE, and a Deque
## PUSH without a choice takes the front.
func _normalize_end(end: StackOperation.DequeEnd) -> StackOperation.DequeEnd:
	if puzzle == null or not puzzle.is_deque_level():
		return StackOperation.DequeEnd.NONE
	if end == StackOperation.DequeEnd.NONE:
		return StackOperation.DequeEnd.FRONT
	return end


## 5.7.2: exactly one penalty per execution (D6).
func _resolve() -> void:
	if not run.valid:
		attempts_left = maxi(0, attempts_left - 1)
		var step := run.get_step(run.invalid_index)
		simulation_invalid.emit(run.invalid_index, step.cause, attempts_left)
		if attempts_left == 0:
			is_correct = false
			_result_decided = true
	elif not run.matches(puzzle.target_output):
		attempts_left = maxi(0, attempts_left - 1)
		output_mismatch.emit(run.produced.duplicate(), puzzle.target_output.duplicate(), attempts_left)
		if attempts_left == 0:
			is_correct = false
			_result_decided = true
	else:
		is_correct = true
		_result_decided = true


## UC-06.9 / UC-06.10: feedback first, then the result goes back to UC-02.5.
## The `_waiting` lock makes `finished` arrive exactly once.
func _finish() -> void:
	_waiting = false
	feedback_ready.emit(
		run.produced.duplicate(),
		puzzle.target_output.duplicate(),
		puzzle.get_valid_sequence(),
		puzzle.explanation
	)
	finished.emit(get_result())
