extends SceneTree
## Self-check of the UC-10 rules that can break silently: the examples must be
## scrambled, the board can only be confirmed once every concept has its cable,
## a connection replaces the one on either end (UC-10.A1.2) and the board is
## correct only when every concept meets its own example (UC-10.7).
## It never saves: the ELO is not touched, only the engines run.
## Run from softlearning/:  godot --headless --path . -s res://tests/uc10_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame

	# UC-10.1: the pool answers for the four departments, which is why the
	# orchestrator can list this minigame as generic.
	var pool: CablePool = load("res://resources/cable_pool.tres")
	for board in pool.boards:
		_check(board.is_valid(), "board %d is well authored" % board.id)
	for department in Enums.all_departments():
		var board := pool.get_board(department, 1000.0)
		_check(board != null and board.department == department,
			"the pool has a board for %s" % Enums.department_to_key(department))

	# UC-10.2: one example per concept and never in the board's own order.
	var cable := CableMinigame.new()
	root.add_child(cable)
	var results: Array[MinigameResult] = []
	cable.finished.connect(results.append)
	cable.start(Enums.Department.CODING, 1000.0)
	_check(cable.concepts.size() == cable.board.size(), "the board has one concept per pair")
	_check(cable.examples.size() == cable.concepts.size(), "both columns have the same size")
	_check(cable.examples != cable.board.examples, "the examples are scrambled")

	# UC-10.6: an incomplete board is not evaluated.
	cable.connect_pair(0, _other_example(cable, 0))
	cable.confirm()
	_check(results.is_empty() and cable.connections.size() == 1,
		"an incomplete board cannot be confirmed")

	# UC-10.A1.2: an example takes one cable, so a second concept on the same
	# example moves it instead of doubling it.
	var example_of_first: int = cable.connections[0]
	cable.connect_pair(1, example_of_first)
	_check(cable.connections.size() == 1 and cable.connections.get(1, -1) == example_of_first,
		"a connection replaces the one on either end")

	# UC-10.A2: no cable is taken while paused, and it is taken again after.
	cable.pause()
	cable.connect_pair(2, _other_example(cable, 2))
	_check(cable.connections.size() == 1, "no connection is taken while paused")
	cable.resume()
	cable.connect_pair(2, _other_example(cable, 2))
	_check(cable.connections.size() == 2, "a connection is taken again after resuming")
	cable.free()

	# UC-10.7: the board is right only when every concept meets its own example.
	var right := _play(Enums.Department.CODING, 1000.0, false)
	_check(right.size() == 1 and right[0].success, "the board's pairing counts as right")
	_check(not right.is_empty() and right[0].type == CableMinigame.TYPE,
		"the result says which minigame it was")
	var wrong := _play(Enums.Department.REQUIREMENTS, 1500.0, true)
	_check(wrong.size() == 1 and not wrong[0].success, "a shifted pairing counts as wrong")

	print("uc10_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## Plays a whole board and returns the results the engine emitted. `make_wrong`
## shifts every concept one example, so all the cables are wrong.
func _play(department: Enums.Department, elo: float, make_wrong: bool) -> Array[MinigameResult]:
	var cable := CableMinigame.new()
	root.add_child(cable)
	var results: Array[MinigameResult] = []
	cable.finished.connect(results.append)
	cable.start(department, elo)
	var size := cable.concepts.size()
	for concept_index in size:
		var example_index: int = cable.correct_connections[concept_index]
		if make_wrong:
			example_index = (example_index + 1) % size
		cable.connect_pair(concept_index, example_index)
	_check(cable.is_complete(), "the whole board can be connected")
	cable.confirm()
	cable.free()
	return results


## An example that is not the one this concept belongs to.
func _other_example(cable: CableMinigame, concept_index: int) -> int:
	return (int(cable.correct_connections[concept_index]) + 1) % cable.examples.size()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
