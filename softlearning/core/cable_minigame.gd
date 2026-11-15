class_name CableMinigame
extends Minigame
## Connect the Cables engine (B5) of UC-10: one board from the cable pool (B2)
## with its examples scrambled, so the player pairs every concept with its
## example. No time limit, like Swipe and Narrative: the player connects the
## whole board (UC-10.5), may change any connection (UC-10.A1) and confirms when
## every concept has a cable (UC-10.6).
##
## CableView follows board_ready and connections_changed, and forwards the
## player's moves with connect_pair() and confirm(). SessionOrchestrator only
## uses the Minigame contract.

## UC-10.2: the two columns, left (concepts) in board order and right
## (examples) scrambled.
signal board_ready(concepts: Array[String], examples: Array[String])
## UC-10.4 / UC-10.A1.2: after every connection. `connections` maps the concept
## index to the index of the example it is connected to, and `is_complete` tells
## whether every concept already has a cable.
signal connections_changed(connections: Dictionary, is_complete: bool)
## UC-10.8: `correct_connections` has the same shape as `connections`.
signal answered(is_correct: bool, correct_connections: Dictionary)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "CABLE"
const POOL: CablePool = preload("res://resources/cable_pool.tres")

var board: CableBoard
## The left column, in board order.
var concepts: Array[String] = []
## The right column: the board's examples shuffled (UC-10.2).
var examples: Array[String] = []
## Concept index -> the index its example got in `examples` (UC-10.7).
var correct_connections := {}
## What the player connected so far: concept index -> index in `examples`.
var connections := {}
var is_correct := false
## True from start() until the board is confirmed or the game is aborted.
var _waiting := false


## UC-10.1 / UC-10.2
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	board = POOL.get_board(department, elo)
	concepts = board.concepts.duplicate()
	examples = _scramble(board.examples)
	correct_connections = _pair_up_board()
	connections = {}
	_waiting = true
	board_ready.emit(concepts.duplicate(), examples.duplicate())
	connections_changed.emit(connections.duplicate(), false)


## UC-10.A2 / N10-2: the connections already made stay as they are.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func abort() -> void:
	_waiting = false


## UC-10.3 / UC-10.4 / UC-10.A1: connects `concept_index` with the example at
## `example_index` of the right column. A concept carries one cable and an
## example takes one, so the new connection replaces whatever was on either end
## (UC-10.A1.2) instead of adding a second cable.
func connect_pair(concept_index: int, example_index: int) -> void:
	if paused or not _waiting:
		return
	if concept_index < 0 or concept_index >= concepts.size():
		return
	if example_index < 0 or example_index >= examples.size():
		return
	for other_concept in connections.keys():
		if connections[other_concept] == example_index and other_concept != concept_index:
			connections.erase(other_concept)
	connections[concept_index] = example_index
	connections_changed.emit(connections.duplicate(), is_complete())


## UC-10.5: every concept has its cable, so the player can confirm.
func is_complete() -> bool:
	return connections.size() == concepts.size()


## UC-10.6 / UC-10.7: only a complete board is evaluated, and it is correct only
## when every concept is connected to its own example.
func confirm() -> void:
	if paused or not _waiting or not is_complete():
		return
	is_correct = connections == correct_connections
	_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, board.difficulty, department)


## UC-10.2: a copy of the board's examples in another order, never the authored
## one, so the right pairing is not given away by the column.
func _scramble(items: Array[String]) -> Array[String]:
	var scrambled: Array[String] = items.duplicate()
	while scrambled == items and scrambled.size() > 1:
		scrambled.shuffle()
	return scrambled


## The board's pairing translated to the positions of the right column.
func _pair_up_board() -> Dictionary:
	var pairing := {}
	for concept_index in board.examples.size():
		var example_index := examples.find(board.examples[concept_index])
		if example_index != -1:
			pairing[concept_index] = example_index
	return pairing


## UC-10.8 feedback first, then the result goes back to UC-02.5 (UC-10.9).
func _finish() -> void:
	_waiting = false
	answered.emit(is_correct, correct_connections.duplicate())
	finished.emit(get_result())
