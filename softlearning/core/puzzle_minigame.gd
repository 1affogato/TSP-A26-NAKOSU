class_name PuzzleMinigame
extends Minigame
## Concept Puzzle engine (B5) of UC-05, specific to Coding Paradigms: one
## puzzle from the puzzle pool (B2) whose slots the player fills with the
## pieces of the tray, with three checks. No time limit.
##
## PuzzleView follows puzzle_ready, board_changed, check_failed and answered,
## and forwards the player's moves with place_piece(), move_to_tray() and
## check(). SessionOrchestrator only uses the Minigame contract.

## UC-05.2
signal puzzle_ready(puzzle: ConceptPuzzle, tray: Array[PuzzlePiece], checks_left: int)
## UC-05.4 and UC-05.3.a1 to a3: after every move, even one that changed
## nothing (a piece dropped on a locked slot stays where it came from).
## `placements` maps slot index -> piece.
signal board_changed(placements: Dictionary, tray: Array[PuzzlePiece], can_check: bool)
## UC-05.7.a1: every slot locked so far and the checks left.
signal check_failed(locked_slots: Array[int], checks_left: int)
## UC-05.8, and UC-05.7.a2 after the last failed check. `placements` is the
## board as it was checked the last time.
signal answered(is_correct: bool, puzzle: ConceptPuzzle, placements: Dictionary)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "PUZZLE"
const POOL: PuzzlePool = preload("res://resources/puzzle_pool.tres")

var puzzle: ConceptPuzzle
## Pieces waiting in the tray, in the order they are shown.
var tray: Array[PuzzlePiece] = []
## Slot index -> piece placed there.
var placements: Dictionary[int, PuzzlePiece] = {}
## UC-05.7.a1.1: slots whose piece was right in a check. They never change again.
var locked_slots: Array[int] = []
## UC-05 description: the puzzle must be solved within 3 checks.
var max_checks := 3
var checks_left := 0
var is_correct := false
## True from start() until the result is decided or the game is aborted.
var _waiting := false


## UC-05.1 / UC-05.2
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	puzzle = POOL.get_puzzle(department, elo)
	tray = puzzle.make_pieces()
	placements = {}
	locked_slots = []
	checks_left = max_checks
	is_correct = false
	_waiting = true
	puzzle_ready.emit(puzzle, tray.duplicate(), checks_left)


## Nothing runs, so the pieces, the locks and the checks simply wait.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func abort() -> void:
	_waiting = false


## UC-05.3 / UC-05.4: puts the piece `piece_id` (from the tray or from another
## slot, UC-05.3.a1) in `slot_index`. A movable piece already there goes back
## to the tray (UC-05.3.a2); a locked slot keeps its piece and the new one
## stays where it was (UC-05.3.a3). Locked pieces never move.
func place_piece(piece_id: int, slot_index: int) -> void:
	if paused or not _waiting or slot_index < 0 or slot_index >= puzzle.slot_count():
		return
	var piece := _find_piece(piece_id)
	var origin := _slot_of(piece_id)
	if piece == null or locked_slots.has(origin):
		return
	if not locked_slots.has(slot_index) and origin != slot_index:
		var previous: PuzzlePiece = placements.get(slot_index)
		_take(piece_id)
		if previous:
			tray.append(previous)
		placements[slot_index] = piece
	_emit_board()


## UC-05.3.a1: a placed piece that is not locked goes back to the tray.
func move_to_tray(piece_id: int) -> void:
	if paused or not _waiting:
		return
	var slot := _slot_of(piece_id)
	if slot == -1 or locked_slots.has(slot):
		return
	tray.append(placements[slot])
	placements.erase(slot)
	_emit_board()


## UC-05.6 / UC-05.7: only once every slot holds a piece (UC-05.5).
func check() -> void:
	if paused or not _waiting or not _all_filled():
		return
	checks_left -= 1
	var wrong := _wrong_slots()
	if wrong.is_empty():
		is_correct = true
		_finish()
	elif checks_left > 0:
		_lock_and_return(wrong)
	else:
		is_correct = false
		_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, puzzle.difficulty, department)


## UC-05.7: slots whose piece belongs to another category or is a decoy.
func _wrong_slots() -> Array[int]:
	var wrong: Array[int] = []
	for slot in placements:
		if placements[slot].category != puzzle.category_of_slot(slot):
			wrong.append(slot)
	wrong.sort()
	return wrong


## UC-05.7.a1.1 to UC-05.7.a1.3: the right pieces are locked, the wrong ones
## go back to the tray, and the view learns how many checks are left.
func _lock_and_return(wrong: Array[int]) -> void:
	for slot in placements:
		if not wrong.has(slot) and not locked_slots.has(slot):
			locked_slots.append(slot)
	locked_slots.sort()
	for slot in wrong:
		tray.append(placements[slot])
		placements.erase(slot)
	check_failed.emit(locked_slots.duplicate(), checks_left)
	_emit_board()


func _all_filled() -> bool:
	return placements.size() == puzzle.slot_count()


func _find_piece(piece_id: int) -> PuzzlePiece:
	for piece in tray:
		if piece.id == piece_id:
			return piece
	for piece in placements.values():
		if piece.id == piece_id:
			return piece
	return null


## Slot that holds the piece `piece_id`, -1 when it is in the tray.
func _slot_of(piece_id: int) -> int:
	for slot in placements:
		if placements[slot].id == piece_id:
			return slot
	return -1


## Takes the piece `piece_id` out of its slot or out of the tray.
func _take(piece_id: int) -> void:
	var slot := _slot_of(piece_id)
	if slot != -1:
		placements.erase(slot)
		return
	for i in tray.size():
		if tray[i].id == piece_id:
			tray.remove_at(i)
			return


func _emit_board() -> void:
	board_changed.emit(placements.duplicate(), tray.duplicate(), _all_filled())


## UC-05.8 / UC-05.7.a2 feedback first, then the result goes back to UC-02.5
## (UC-05.10).
func _finish() -> void:
	_waiting = false
	answered.emit(is_correct, puzzle, placements.duplicate())
	finished.emit(get_result())
