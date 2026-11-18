class_name ConceptPuzzle
extends Resource
## One puzzle of the Concept Puzzle pool (UC-05, "ConceptPuzzle"): the
## categories of the board, each with the texts that belong to it, and the
## decoys that belong to none.
##
## Authored content that lives in PuzzlePool (B2); PuzzleMinigame receives
## exactly one (UC-05.1). The slots are numbered across the categories in
## order: the first category owns slots 0 to 2, the second 3 to 5, and so on.

## Pool design (task 25): pieces of every category.
const PIECES_PER_CATEGORY := 3
## Longest text a piece can show.
const MAX_TEXT := 40
## Pool design (task 25): categories and decoys of each difficulty.
const CATEGORIES := {
	Enums.Difficulty.FACIL: 2,
	Enums.Difficulty.MEDIO: 2,
	Enums.Difficulty.DIFICIL: 3,
	Enums.Difficulty.MUY_DIFICIL: 3,
}
const DECOYS := {
	Enums.Difficulty.FACIL: 0,
	Enums.Difficulty.MEDIO: 1,
	Enums.Difficulty.DIFICIL: 2,
	Enums.Difficulty.MUY_DIFICIL: 3,
}

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.CODING
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
@export var categories: Array[PuzzleCategory] = []
## Texts that belong to none of the categories (UC-05 description).
@export var decoys: Array[String] = []


## UC-05.2: one piece per text, decoys included, in scrambled order. Never
## the authored order, which would show the pieces grouped by category. The
## texts are all different and at least six, so the loop always ends.
func make_pieces() -> Array[PuzzlePiece]:
	var pieces: Array[PuzzlePiece] = []
	for category in categories:
		for text in category.pieces:
			pieces.append(PuzzlePiece.create(pieces.size() + 1, text, category.name))
	for text in decoys:
		pieces.append(PuzzlePiece.create(pieces.size() + 1, text, ""))
	var authored := pieces.duplicate()
	while pieces == authored:
		pieces.shuffle()
	return pieces


## One slot per piece of every category (decoys have no slot).
func slot_count() -> int:
	var total := 0
	for category in categories:
		total += category.pieces.size()
	return total


## UC-05.7: name of the category that owns `slot_index`, "" when there is none.
func category_of_slot(slot_index: int) -> String:
	if slot_index < 0:
		return ""
	var first := 0
	for category in categories:
		if slot_index < first + category.pieces.size():
			return category.name
		first += category.pieces.size()
	return ""


## Pool design (task 25): 2 categories on FACIL and MEDIO and 3 on DIFICIL and
## MUY_DIFICIL, 3 pieces each, 0 / 1 / 2 / 3 decoys, and texts of at most 40
## characters that never repeat inside the puzzle, so a decoy can never belong
## to a category.
func is_valid() -> bool:
	if categories.size() != CATEGORIES[difficulty] or decoys.size() != DECOYS[difficulty]:
		return false
	var names := {}
	var texts := {}
	for category in categories:
		if category == null or category.name.strip_edges().is_empty() or names.has(category.name):
			return false
		if category.pieces.size() != PIECES_PER_CATEGORY:
			return false
		names[category.name] = true
		for text in category.pieces:
			if not _is_new_text(text, texts):
				return false
	for text in decoys:
		if not _is_new_text(text, texts):
			return false
	return true


func _is_new_text(text: String, texts: Dictionary) -> bool:
	if text.strip_edges().is_empty() or text.length() > MAX_TEXT or texts.has(text):
		return false
	texts[text] = true
	return true
