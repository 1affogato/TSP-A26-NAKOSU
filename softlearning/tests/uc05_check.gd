extends SceneTree
## Self-check of the UC-05 rules that can break silently: every puzzle of the
## pool is well authored, an incomplete board is not checked (UC-05.5), a
## slot with a movable piece sends it back to the tray (UC-05.3.a2), a locked
## slot keeps its piece (UC-05.3.a3), a failed check locks the right pieces
## and returns the wrong ones (UC-05.7.a1), and the third failed check ends
## the puzzle as wrong (UC-05.7.a2).
## It never saves: the ELO is not touched, only the engine runs.
## Run from softlearning/:  godot --headless --path . -s res://tests/uc05_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame

	# Pool design (task 25) and task 45: valid puzzles, Coding Paradigms only,
	# at least three per difficulty.
	var pool: PuzzlePool = load("res://resources/puzzle_pool.tres")
	var per_difficulty := {}
	var ids := {}
	for puzzle in pool.puzzles:
		_check(puzzle.is_valid(), "puzzle %d is well authored" % puzzle.id)
		_check(puzzle.department == Enums.Department.CODING, "puzzle %d belongs to Coding Paradigms" % puzzle.id)
		_check(not ids.has(puzzle.id), "puzzle id %d is unique" % puzzle.id)
		ids[puzzle.id] = true
		per_difficulty[puzzle.difficulty] = per_difficulty.get(puzzle.difficulty, 0) + 1
	for difficulty in Enums.Difficulty.values():
		_check(per_difficulty.get(difficulty, 0) >= 3, "three puzzles or more of difficulty %d" % difficulty)
	# UC-05.2: the tray is always scrambled, never in the authored order
	# (that order groups the pieces by category).
	var smallest: ConceptPuzzle = pool.puzzles.filter(func(p): return p.slot_count() + p.decoys.size() == 6)[0]
	var authored := []
	for category in smallest.categories:
		authored.append_array(category.pieces)
	var scrambled := true
	for i in 2000:
		if smallest.make_pieces().map(func(piece): return piece.text) == authored:
			scrambled = false
	_check(scrambled, "the tray never shows the authored order")
	var manager := root.get_node("DepartmentManager")
	_check(manager.get_enabled_minigames(Enums.Department.CODING).has(PuzzleMinigame.TYPE),
		"Coding Paradigms enables the puzzle")

	# UC-05.1 / UC-05.2: a high ELO draws a puzzle with decoys; the tray holds
	# one piece per slot plus the decoys.
	var game := PuzzleMinigame.new()
	root.add_child(game)
	var results: Array[MinigameResult] = []
	var verdicts := []
	var failed := []
	game.finished.connect(results.append)
	game.answered.connect(func(is_correct, _puzzle, _placements): verdicts.append(is_correct))
	game.check_failed.connect(func(locked, left): failed.append([locked, left]))
	game.start(Enums.Department.CODING, 2500.0)
	var puzzle := game.puzzle
	_check(game.tray.size() == puzzle.slot_count() + puzzle.decoys.size(), "the tray holds every piece and decoy")
	_check(game.checks_left == 3 and not puzzle.decoys.is_empty(), "three checks and some decoys")

	# UC-05.5: an incomplete board is not checked.
	game.check()
	_check(game.checks_left == 3 and results.is_empty(), "an incomplete board cannot be checked")

	# UC-05.3.a2: a slot with a movable piece sends that piece back to the tray.
	var decoy := _tray_piece(game, "")
	var first := _tray_piece(game, puzzle.category_of_slot(0))
	game.place_piece(decoy.id, 0)
	game.place_piece(first.id, 0)
	_check(game.placements[0] == first and game.tray.has(decoy), "a replaced movable piece goes back to the tray")

	# UC-05.3.a1: a placed piece moves to another empty slot or back to the tray.
	game.place_piece(first.id, 1)
	_check(not game.placements.has(0) and game.placements[1] == first, "a placed piece moves to another slot")
	game.move_to_tray(first.id)
	_check(game.placements.is_empty() and game.tray.has(first), "a placed piece goes back to the tray")

	# UC-02.4.a1: nothing moves while paused.
	game.pause()
	game.place_piece(first.id, 0)
	_check(game.placements.is_empty(), "no piece moves while paused")
	game.resume()

	# UC-05.7.a1: every slot filled, three of them wrong (a decoy, a piece of
	# the last category in the first one and the other way round).
	_fill_right(game)
	var last := puzzle.slot_count() - 1
	var right_first: PuzzlePiece = game.placements[0]
	game.place_piece(decoy.id, 0)
	game.place_piece(game.placements[last].id, 1)
	game.place_piece(right_first.id, last)
	_check(game.placements.size() == puzzle.slot_count(), "every slot holds a piece")
	game.check()
	var expected: Array[int] = []
	for slot in puzzle.slot_count():
		if slot not in [0, 1, last]:
			expected.append(slot)
	_check(failed.size() == 1 and failed[0][0] == expected and failed[0][1] == 2,
		"a failed check locks the right pieces and leaves two checks")
	_check(game.placements.size() == expected.size() and game.tray.has(decoy), "the wrong pieces go back to the tray")

	# UC-05.3.a3: a locked slot keeps its piece, and a locked piece never moves.
	var locked_slot: int = expected[0]
	var locked_piece: PuzzlePiece = game.placements[locked_slot]
	game.place_piece(decoy.id, locked_slot)
	_check(game.placements[locked_slot] == locked_piece and game.tray.has(decoy), "a locked slot keeps its piece")
	game.move_to_tray(locked_piece.id)
	game.place_piece(locked_piece.id, 0)
	_check(game.placements[locked_slot] == locked_piece and not game.placements.has(0), "a locked piece never moves")

	# UC-05.7.a2: the third failed check ends the puzzle as wrong.
	_fill_wrong(game)
	game.check()
	_check(failed.size() == 2 and failed[1][1] == 1 and results.is_empty(), "the second failed check leaves one check")
	_fill_wrong(game)
	game.check()
	_check(results.size() == 1 and not results[0].success, "the third failed check ends the puzzle as wrong")
	_check(results[0].type == PuzzleMinigame.TYPE and results[0].level == puzzle.difficulty
		and results[0].department == Enums.Department.CODING, "the result carries type, difficulty and department")
	_check(verdicts == [false], "the feedback arrives once, as wrong")
	game.free()

	# UC-05.8 / UC-05.9: every piece in its category wins at the first check.
	var easy := PuzzleMinigame.new()
	root.add_child(easy)
	var easy_results: Array[MinigameResult] = []
	easy.finished.connect(easy_results.append)
	easy.start(Enums.Department.CODING, 1000.0)
	_fill_right(easy)
	easy.check()
	_check(easy_results.size() == 1 and easy_results[0].success and easy.checks_left == 2,
		"a right board wins at the first check")
	easy.free()

	print("uc05_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## A piece of `category` waiting in the tray ("" for a decoy).
func _tray_piece(game: PuzzleMinigame, category: String) -> PuzzlePiece:
	for piece in game.tray:
		if piece.category == category:
			return piece
	return null


## Every empty slot gets a piece of its own category.
func _fill_right(game: PuzzleMinigame) -> void:
	for slot in game.puzzle.slot_count():
		if not game.placements.has(slot):
			game.place_piece(_tray_piece(game, game.puzzle.category_of_slot(slot)).id, slot)


## Every empty slot gets a piece of another category or a decoy.
func _fill_wrong(game: PuzzleMinigame) -> void:
	for slot in game.puzzle.slot_count():
		if game.placements.has(slot):
			continue
		for piece in game.tray:
			if piece.category != game.puzzle.category_of_slot(slot):
				game.place_piece(piece.id, slot)
				break


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
