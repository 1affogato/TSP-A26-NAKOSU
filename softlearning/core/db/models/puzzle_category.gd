class_name PuzzleCategory
extends Resource
## One category of a concept puzzle (UC-05, "PuzzleCategory"): its name, shown
## over its slots, and the texts of the pieces that belong to it.
##
## Authored content inside a ConceptPuzzle of PuzzlePool (B2).

## Shown over the category's slots ("Orientado a objetos").
@export var name: String = ""
## Exactly 3 texts of at most 40 characters; the board has one slot per text.
@export var pieces: Array[String] = []
