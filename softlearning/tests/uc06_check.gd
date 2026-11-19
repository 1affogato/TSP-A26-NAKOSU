extends SceneTree
## Self-check of the UC-06 rules that can break silently: the pool content and
## its reference solutions, the level variants (Queue, Deque, Priority Queue),
## the editor, the pure simulation and the attempts of the engine.
## It never saves: no ELO change, no statistics and no persistence.
## Run from softlearning/:  godot --headless --path . -s res://tests/uc06_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame

	var pool: StackPuzzlePool = load("res://resources/stack_puzzle_pool.tres")
	_check_pool(pool)
	_check_editor(pool)
	_check_simulation()
	_check_engine()

	# --- VIEW / INTEGRATION CHECKS (Parte B, §6.7): añade aquí las comprobaciones de UI ---
	await _check_view()

	print("uc06_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## UI block of Part B: the view is registered, followed and able to run the
## whole flow headless. It only checks visibility and disabled states.
func _check_view() -> void:
	var manager := root.get_node("DepartmentManager")
	_check(
		manager.get_enabled_minigames(Enums.Department.DATA_STRUCTURES).has(StackPuzzleMinigame.TYPE),
		"the Data Structures session enables the stack puzzle"
	)
	var scene := load("res://scenes/stack_puzzle_view.tscn") as PackedScene
	_check(scene != null, "the stack puzzle view scene loads")
	var session_script := load("res://scenes/session_view.gd") as GDScript
	_check(session_script.VIEWS.has("STACK_PUZZLE"), "the session view registers the stack puzzle")
	if scene == null:
		return

	var game := StackPuzzleMinigame.new()
	root.add_child(game)
	var view := scene.instantiate()
	root.add_child(view)
	await process_frame
	view.call("set_minigame", game, "Minijuego 1 de 10")
	game.start(Enums.Department.DATA_STRUCTURES, 1000.0)
	await process_frame

	var execute_button := view.get_node("%ExecuteButton") as Button
	_check(execute_button != null and execute_button.disabled, "the execute button starts disabled")
	var solution := game.puzzle.get_valid_sequence()
	for index in solution.size():
		var operation := solution[index]
		game.insert_operation(index, operation.kind, operation.deque_end)
	await process_frame
	_check(execute_button != null and not execute_button.disabled,
		"the execute button is enabled once the sequence has operations")

	game.execute()
	game.show_result()
	await process_frame
	var feedback := view.get_node("%Feedback") as Control
	_check(feedback != null and feedback.visible, "the feedback is shown once the result is asked for")

	view.queue_free()
	game.free()


## Cases 1-5: the authored content and the level variants.
func _check_pool(pool: StackPuzzlePool) -> void:
	# 1. is_valid() plus the reference solution simulated to the target.
	_check(pool.validate().is_empty(), "every puzzle is well authored and its solution reaches the target")

	# 2. Data Structures only, unique ids, three per difficulty and twelve total.
	# 3. Easy levels are Queue only, and the three variants are covered.
	var ids := {}
	var per_difficulty := {}
	var has_deque := false
	var has_max := false
	var has_min := false
	for puzzle in pool.puzzles:
		_check(puzzle.department == Enums.Department.DATA_STRUCTURES, "puzzle %d belongs to Data Structures" % puzzle.id)
		_check(not ids.has(puzzle.id), "puzzle id %d is unique" % puzzle.id)
		ids[puzzle.id] = true
		per_difficulty[puzzle.difficulty] = per_difficulty.get(puzzle.difficulty, 0) + 1
		if puzzle.is_deque_level():
			has_deque = true
		if puzzle.is_priority_level() and puzzle.priority_mode == StackPuzzle.PriorityMode.MAX:
			has_max = true
		if puzzle.is_priority_level() and puzzle.priority_mode == StackPuzzle.PriorityMode.MIN:
			has_min = true
		if puzzle.difficulty == Enums.Difficulty.FACIL:
			_check(puzzle.input_structure == StackPuzzle.InputStructure.QUEUE, "the easy puzzle %d is a Queue level" % puzzle.id)
	_check(pool.puzzles.size() >= 12, "the pool holds at least twelve puzzles")
	for difficulty in Enums.Difficulty.values():
		_check(per_difficulty.get(difficulty, 0) >= 3, "three puzzles or more of difficulty %d" % difficulty)
	_check(has_deque and has_max and has_min, "the pool covers Deque, PQ MAX and PQ MIN")

	var queue := _find_puzzle(pool, StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE)
	var deque := _find_puzzle(pool, StackPuzzle.InputStructure.DEQUE, StackPuzzle.PriorityMode.NONE)
	var max_queue := _find_puzzle(pool, StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MAX)
	var min_queue := _find_puzzle(pool, StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MIN)
	if queue == null or deque == null or max_queue == null or min_queue == null:
		_check(false, "the pool has a sample of every input structure")
		return

	# 4. The delivery rule is never empty and differs per variant.
	var rules := {}
	for puzzle in [queue, deque, max_queue, min_queue]:
		var rule: String = puzzle.get_delivery_rule()
		_check(not rule.strip_edges().is_empty(), "puzzle %d has a delivery rule" % puzzle.id)
		rules[rule] = true
	_check(rules.size() == 4, "each input variant has its own delivery rule")

	# 5. Queue and Deque keep the authored order; the Priority Queue sorts.
	_check(queue.initial_input_state() == queue.input_sequence, "the Queue keeps the authored order")
	_check(deque.initial_input_state() == deque.input_sequence, "the Deque keeps the authored order")
	var max_state := max_queue.initial_input_state()
	var max_sorted := max_queue.input_sequence.duplicate()
	max_sorted.sort()
	max_sorted.reverse()
	_check(max_state == max_sorted, "PQ MAX delivers from the greatest to the smallest")
	var min_state := min_queue.initial_input_state()
	var min_sorted := min_queue.input_sequence.duplicate()
	min_sorted.sort()
	_check(min_state == min_sorted, "PQ MIN delivers from the smallest to the greatest")


## Cases 6-11: the editor (UC-06.4 / UC-06.5) and the pause.
func _check_editor(pool: StackPuzzlePool) -> void:
	# 6. A new puzzle: empty editor, no execution and the authored attempts.
	var game := _new_game()
	_check(game.puzzle != null, "start() draws a puzzle")
	_check(game.operations.is_empty(), "a new puzzle starts with an empty editor")
	_check(not game.can_execute(), "an empty editor cannot execute")
	_check(game.attempts_left == game.max_attempts and game.max_attempts == game.puzzle.max_attempts,
		"the attempts start at their authored value")
	_check(game.run == null and game.step_index == 0 and not game.is_correct, "a new puzzle has no run")
	game.free()

	# 7. Every edit reports the sequence and whether it can execute.
	game = _new_game()
	var flags := []
	var counts := []
	game.editor_changed.connect(func(operations, can_execute):
		counts.append(operations.size())
		flags.append(can_execute)
	)
	game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	_check(counts.size() == 1 and counts[0] == 1 and flags[0], "the first operation enables execution")
	game.insert_operation(1, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(counts.size() == 2 and counts[1] == 2 and flags[1], "a second operation keeps execution enabled")
	game.clear_operations()
	_check(counts.size() == 3 and counts[2] == 0 and not flags[2], "clearing the sequence disables execution")
	game.free()

	# 8. An insert past the end is clamped; out-of-range remove/move do nothing.
	game = _new_game()
	game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	game.insert_operation(99, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(game.operations.size() == 2 and game.operations[1].is_pop(), "an insert index past the end is clamped")
	game.remove_operation(99)
	game.remove_operation(-1)
	game.move_operation(0, 99)
	game.move_operation(-1, 0)
	_check(game.operations.size() == 2, "out-of-range remove and move keep the sequence")
	game.free()

	# 9. Moving takes the operation out and closes the gap.
	game = _new_game()
	game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	game.insert_operation(1, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	game.insert_operation(2, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	game.move_operation(0, 2)
	_check(game.operations.size() == 3, "moving keeps every operation")
	_check(game.operations[0].is_pop() and not game.operations[1].is_pop() and not game.operations[2].is_pop(),
		"moving closes the gap and reorders the sequence")
	game.free()

	# 10. D10: only a Deque level keeps an end; NONE becomes the front.
	var queue := _find_puzzle(pool, StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE)
	var deque := _find_puzzle(pool, StackPuzzle.InputStructure.DEQUE, StackPuzzle.PriorityMode.NONE)
	game = _new_game()
	if queue != null and deque != null:
		game.puzzle = queue
		game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.REAR)
		_check(game.operations[0].deque_end == StackOperation.DequeEnd.NONE, "a Queue PUSH always takes the front")
		game.puzzle = deque
		game.insert_operation(1, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
		_check(game.operations[1].deque_end == StackOperation.DequeEnd.FRONT,
			"a Deque PUSH without a choice takes the front")
		game.insert_operation(2, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.REAR)
		_check(game.operations[2].deque_end == StackOperation.DequeEnd.REAR, "a Deque PUSH keeps the chosen end")
	else:
		_check(false, "the pool has a Queue and a Deque sample")
	game.free()

	# 11. UC-02.4.a1: nothing changes while paused, and resume() restores it.
	game = _new_game()
	game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	var shown := []
	game.step_shown.connect(func(_step, index, total): shown.append([index, total]))
	game.pause()
	game.insert_operation(1, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(game.operations.size() == 1, "no operation is inserted while paused")
	_check(not game.can_execute(), "a paused puzzle cannot execute")
	game.execute()
	game.next_step()
	game.previous_step()
	_check(game.run == null and game.step_index == 0 and shown.is_empty(), "no execution or navigation while paused")
	game.resume()
	game.insert_operation(1, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(game.operations.size() == 2 and game.can_execute(), "resume() restores the editor")
	game.free()


## Cases 12-17: the pure simulation (UC-06.7).
func _check_simulation() -> void:
	# 12. Every pool solution simulates to a valid run with the target, and
	# simulate() leaves the puzzle untouched.
	var pool: StackPuzzlePool = load("res://resources/stack_puzzle_pool.tres")
	for puzzle in pool.puzzles:
		var before := puzzle.initial_input_state()
		var run := StackPuzzleSimulator.simulate(puzzle, puzzle.get_valid_sequence())
		_check(run.valid, "puzzle %d has a valid reference solution" % puzzle.id)
		_check(run.matches(puzzle.target_output), "puzzle %d reference solution produces its target" % puzzle.id)
		_check(puzzle.initial_input_state() == before, "puzzle %d is not mutated by the simulation" % puzzle.id)

	# 12 (explicit): the five verified examples of the plan.
	_check_example(1, StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE,
		[3, 8, 5], ["PUSH", "PUSH", "POP", "POP", "PUSH", "POP"], [8, 3, 5])
	_check_example(2, StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE,
		[1, 2, 3], ["PUSH", "POP", "PUSH", "POP", "PUSH", "POP"], [1, 2, 3])
	# The tabled example 3 has seven operations for four elements; every element
	# needs its own PUSH, so the last one gets the missing PUSH_FRONT.
	_check_example(3, StackPuzzle.InputStructure.DEQUE, StackPuzzle.PriorityMode.NONE,
		[4, 9, 6, 2], ["PUSH_FRONT", "PUSH_REAR", "POP", "POP", "PUSH_FRONT", "POP", "PUSH_FRONT", "POP"], [2, 4, 9, 6])
	_check_example(4, StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MAX,
		[9, 7, 4], ["PUSH", "PUSH", "PUSH", "POP", "POP", "POP"], [4, 7, 9])
	_check_example(5, StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MIN,
		[5, 2, 8], ["PUSH", "PUSH", "PUSH", "POP", "POP", "POP"], [8, 5, 2])

	# 13. The two ends of a Deque deliver different elements from the same state.
	var deque := _local_puzzle(StackPuzzle.InputStructure.DEQUE, StackPuzzle.PriorityMode.NONE, [4, 9, 6, 2])
	var front_ops: Array[StackOperation] = []
	front_ops.append(StackOperation.create(StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.FRONT))
	var rear_ops: Array[StackOperation] = []
	rear_ops.append(StackOperation.create(StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.REAR))
	var front_run := StackPuzzleSimulator.simulate(deque, front_ops)
	var rear_run := StackPuzzleSimulator.simulate(deque, rear_ops)
	_check(front_run.get_last_step().element == 4 and rear_run.get_last_step().element == 2,
		"PUSH_FRONT and PUSH_REAR take opposite ends of the Deque")

	# 14. A Priority Queue delivers by priority.
	var max_puzzle := _local_puzzle(StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MAX, [5, 1, 4, 3])
	var min_puzzle := _local_puzzle(StackPuzzle.InputStructure.PRIORITY_QUEUE, StackPuzzle.PriorityMode.MIN, [5, 1, 4, 3])
	var all_pushed := _push_then_pop(4)
	var ascending: Array[int] = [1, 3, 4, 5]
	var descending: Array[int] = [5, 4, 3, 1]
	_check(StackPuzzleSimulator.simulate(max_puzzle, all_pushed).matches(ascending),
		"PQ MAX with every PUSH then every POP produces ascending output")
	_check(StackPuzzleSimulator.simulate(min_puzzle, all_pushed).matches(descending),
		"PQ MIN with every PUSH then every POP produces descending output")

	# 15. POP on an empty Stack.
	var pop_only: Array[StackOperation] = []
	pop_only.append(StackOperation.create(StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE))
	var empty_stack := StackPuzzleSimulator.simulate(
		_local_puzzle(StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE, [3, 8, 5]), pop_only)
	_check(not empty_stack.valid and empty_stack.invalid_index == 1 and empty_stack.size() == 1,
		"a POP on an empty Stack is invalid at step 1")
	_check(empty_stack.get_step(1) != null and empty_stack.get_step(1).cause.contains("Stack"),
		"the cause of the invalid POP names the Stack")

	# 16. PUSH on an exhausted input stops the run at that step.
	var too_many: Array[StackOperation] = []
	too_many.append(StackOperation.create(StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE))
	too_many.append(StackOperation.create(StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE))
	too_many.append(StackOperation.create(StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE))
	var exhausted := StackPuzzleSimulator.simulate(
		_local_puzzle(StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE, [3]), too_many)
	_check(not exhausted.valid and exhausted.invalid_index == 2 and exhausted.size() == 2,
		"a PUSH on an empty input is invalid at its step and stops the run")
	_check(exhausted.get_step(2) != null and exhausted.get_step(2).cause.contains("entrada"),
		"the cause of the invalid PUSH names the input")

	# 17. Out-of-range steps and the size of the run.
	_check(exhausted.get_step(0) == null and exhausted.get_step(3) == null, "get_step() outside the range is null")
	_check(exhausted.size() == 2, "size() counts only the executed steps")
	var no_ops: Array[StackOperation] = []
	var empty_run := StackPuzzleSimulator.simulate(
		_local_puzzle(StackPuzzle.InputStructure.QUEUE, StackPuzzle.PriorityMode.NONE, [3]), no_ops)
	_check(empty_run.valid and empty_run.size() == 0 and empty_run.get_last_step() == null,
		"an empty sequence is a valid run with no steps")


## Cases 18-23: the engine, its attempts and its signals.
func _check_engine() -> void:
	_check_correct_run()
	_check_output_mismatch()
	_check_invalid_operation()
	_check_exhausted_attempts()
	_check_step_navigation()
	_check_abort()


## 18. The authored solution wins without spending an attempt and freezes the
## editor; the feedback is shown once, and only when asked.
func _check_correct_run() -> void:
	var game := _new_game()
	var attempts_before := game.attempts_left
	var feedback := []
	var results: Array[MinigameResult] = []
	game.feedback_ready.connect(func(produced, target, solution, explanation):
		feedback.append([produced, target, solution, explanation])
	)
	game.finished.connect(results.append)
	_insert_solution(game)
	_check(game.can_execute(), "the authored solution can be executed")
	game.execute()
	_check(game.is_correct, "executing the authored solution is correct")
	_check(game.attempts_left == attempts_before, "a correct run does not spend an attempt")
	_check(not game.can_execute(), "a correct run freezes the editor")
	var operation_count := game.operations.size()
	game.insert_operation(0, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(game.operations.size() == operation_count, "no operation is inserted once the result is decided")
	game.show_result()
	game.show_result()
	_check(feedback.size() == 1 and results.size() == 1, "show_result() emits the feedback and finishes once")
	if results.size() == 1:
		_check(results[0].type == StackPuzzleMinigame.TYPE, "the result carries the engine key")
		_check(results[0].success, "the result is a success")
		_check(results[0].level == game.puzzle.difficulty, "the result carries the difficulty")
		_check(results[0].department == Enums.Department.DATA_STRUCTURES, "the result carries the department")
	if feedback.size() == 1:
		_check(feedback[0][0] == game.puzzle.target_output, "the feedback shows the produced output")
		_check(feedback[0][1] == game.puzzle.target_output, "the feedback shows the target output")
		_check(not feedback[0][2].is_empty(), "the feedback shows a valid sequence")
		_check(not feedback[0][3].is_empty(), "the feedback shows the explanation")
	game.free()


## 19. A different output spends one attempt, does not end the minigame and
## lets the player edit and execute again.
func _check_output_mismatch() -> void:
	var game := _new_game()
	var attempts_before := game.attempts_left
	var mismatches := []
	var results: Array[MinigameResult] = []
	game.output_mismatch.connect(func(produced, target, left): mismatches.append([produced, target, left]))
	game.finished.connect(results.append)
	_insert_mismatch(game)
	game.execute()
	_check(mismatches.size() == 1, "a different output reports the mismatch")
	_check(game.attempts_left == attempts_before - 1, "a mismatch spends one attempt")
	_check(results.is_empty(), "a mismatch with attempts left does not end the minigame")
	if mismatches.size() == 1:
		_check(mismatches[0][2] == game.attempts_left, "the mismatch reports the attempts left")
		_check(mismatches[0][0] != game.puzzle.target_output, "the mismatch shows the produced output")
	_check(game.run != null, "the run stays available for review")
	_check(not game.can_execute(), "the same sequence cannot be executed twice")
	game.edit_sequence()
	_check(game.run == null and game.can_execute(), "editing discards the run and allows executing again")
	game.free()


## 20. An invalid operation is the last step, spends one attempt and does not
## change while the player reviews it.
func _check_invalid_operation() -> void:
	var game := _new_game()
	var attempts_before := game.attempts_left
	var invalid := []
	var shown := []
	game.simulation_invalid.connect(func(index, cause, left): invalid.append([index, cause, left]))
	game.step_shown.connect(func(_step, index, total): shown.append([index, total]))
	game.insert_operation(0, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	game.execute()
	_check(invalid.size() == 1, "an invalid operation is reported")
	if invalid.size() == 1:
		_check(invalid[0][0] == 1 and String(invalid[0][1]).contains("Stack"),
			"the invalid operation reports its index and cause")
		_check(invalid[0][2] == attempts_before - 1, "the invalid operation reports the attempts left")
	_check(game.attempts_left == attempts_before - 1, "an invalid run spends one attempt")
	_check(game.run.size() == 1 and game.step_index == 1, "the invalid operation is the last step")
	_check(shown.size() == 1 and shown[0][0] == 1 and shown[0][1] == 1, "the invalid step is shown first")
	game.next_step()
	game.previous_step()
	_check(game.attempts_left == attempts_before - 1 and game.step_index == 1 and not game.is_correct,
		"reviewing does not change the attempts or the result")
	game.free()


## 21. Spending the last attempt decides an incorrect result.
func _check_exhausted_attempts() -> void:
	var game := _new_game()
	var results: Array[MinigameResult] = []
	game.finished.connect(results.append)
	_insert_mismatch(game)
	while game.attempts_left > 0:
		game.execute()
		_check(game.run != null and not game.run.matches(game.puzzle.target_output),
			"every attempt simulates a different output")
		if game.attempts_left > 0:
			game.edit_sequence()
	_check(game.attempts_left == 0 and not game.is_correct, "the last attempt leaves an incorrect result")
	_check(game._result_decided, "the result is decided when the attempts run out")
	game.show_result()
	_check(results.size() == 1 and not results[0].success, "the feedback closes the minigame as incorrect")
	game.free()


## 22. The step navigation stops at both ends.
func _check_step_navigation() -> void:
	var game := _new_game()
	_insert_solution(game)
	var shown := []
	game.step_shown.connect(func(_step, index, total): shown.append([index, total]))
	game.execute()
	var total := game.run.size()
	_check(total >= 1 and shown.size() == 1, "the execution shows its first step")
	game.previous_step()
	_check(shown.size() == 1, "previous_step() at the first step does not emit")
	for i in total - 1:
		game.next_step()
	_check(shown.size() == total and game.step_index == total, "next_step() walks every step")
	game.next_step()
	_check(shown.size() == total, "next_step() at the last step does not emit")
	game.previous_step()
	_check(shown.size() == total + 1, "previous_step() emits inside the range")
	game.free()


## 23. abort() ends without a result and leaves nothing editable or executable.
func _check_abort() -> void:
	var game := _new_game()
	var results: Array[MinigameResult] = []
	game.finished.connect(results.append)
	game.insert_operation(0, StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	game.abort()
	_check(results.is_empty(), "abort() gives no result")
	game.insert_operation(1, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_check(game.operations.size() == 1, "nothing is edited after abort()")
	_check(not game.can_execute(), "nothing is executed after abort()")
	game.execute()
	_check(game.run == null, "execute() after abort() does nothing")
	game.free()


## One of the five verified examples of the plan, built on the fly.
func _check_example(
	id: int,
	structure: StackPuzzle.InputStructure,
	priority: StackPuzzle.PriorityMode,
	sequence: Array,
	tokens: Array,
	target: Array
) -> void:
	var puzzle := _local_puzzle(structure, priority, sequence)
	puzzle.id = id
	puzzle.target_output = _int_array(target)
	var solution := PackedStringArray()
	for token in tokens:
		solution.append(str(token))
	puzzle.solution = solution
	puzzle.explanation = "Ejemplo verificado."
	_check(puzzle.is_valid(), "example %d is structurally valid" % id)
	var run := StackPuzzleSimulator.simulate(puzzle, puzzle.get_valid_sequence())
	_check(run.valid and run.matches(puzzle.target_output), "example %d produces its target" % id)


## A puzzle built in memory, outside the pool, to pin one level variant.
func _local_puzzle(structure: StackPuzzle.InputStructure, priority: StackPuzzle.PriorityMode, sequence: Array) -> StackPuzzle:
	var puzzle := StackPuzzle.new()
	puzzle.input_structure = structure
	puzzle.priority_mode = priority
	puzzle.input_sequence = _int_array(sequence)
	puzzle.target_output = _int_array(sequence)
	return puzzle


## `count` PUSH operations followed by `count` POP operations.
func _push_then_pop(count: int) -> Array[StackOperation]:
	var operations: Array[StackOperation] = []
	for i in count:
		operations.append(StackOperation.create(StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE))
	for i in count:
		operations.append(StackOperation.create(StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE))
	return operations


## The authored solution of the drawn puzzle, operation by operation.
func _insert_solution(game: StackPuzzleMinigame) -> void:
	var solution := game.puzzle.get_valid_sequence()
	for index in solution.size():
		var operation := solution[index]
		game.insert_operation(index, operation.kind, operation.deque_end)


## A valid but short sequence: one PUSH and one POP never reach a longer target.
func _insert_mismatch(game: StackPuzzleMinigame) -> void:
	game.insert_operation(game.operations.size(), StackOperation.OperationKind.PUSH, StackOperation.DequeEnd.NONE)
	game.insert_operation(game.operations.size(), StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)


func _new_game(elo := 1000.0) -> StackPuzzleMinigame:
	var game := StackPuzzleMinigame.new()
	root.add_child(game)
	game.start(Enums.Department.DATA_STRUCTURES, elo)
	return game


func _find_puzzle(pool: StackPuzzlePool, structure: StackPuzzle.InputStructure, priority: StackPuzzle.PriorityMode) -> StackPuzzle:
	for puzzle in pool.puzzles:
		if puzzle.input_structure == structure and puzzle.priority_mode == priority:
			return puzzle
	return null


func _int_array(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
