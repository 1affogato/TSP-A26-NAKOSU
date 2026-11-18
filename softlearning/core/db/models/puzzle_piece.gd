class_name PuzzlePiece
extends Resource
## One piece of the puzzle in play (UC-05, "PuzzlePiece"). ConceptPuzzle builds
## them when the minigame starts (make_pieces); they are never authored or
## saved.

## Unique within one puzzle: the view and the engine refer to pieces by it.
@export var id: int = 0
@export var text: String = ""
## Name of the category the piece belongs to; empty for a decoy.
@export var category: String = ""


static func create(new_id: int, new_text: String, new_category: String) -> PuzzlePiece:
	var piece := PuzzlePiece.new()
	piece.id = new_id
	piece.text = new_text
	piece.category = new_category
	return piece


## A decoy belongs to none of the puzzle's categories.
func is_decoy() -> bool:
	return category.is_empty()
