class_name CableBoard
extends Resource
## One board of the Connect the Cables pool (UC-10, "CableBoard"): a column of
## concepts and the example that belongs to each one.
##
## Authored content that lives in CablePool (B2); CableMinigame receives exactly
## one (UC-10.1). `examples[i]` is the example of `concepts[i]`, so that pairing
## is the correct one (UC-10.7); the engine shows the examples in a scrambled
## order (UC-10.2) so the player has to find it.
##
## Nothing here is scrambled: the board is stored "as authored", and the engine
## is the one that shuffles a copy for the screen.

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.SOFTWARE_DEV
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
## Left column: the concepts of the board, in the order they are shown. Between
## 3 and 5, at most 60 characters each and all different, so every concept has
## exactly one cable.
@export var concepts: Array[String] = []
## Right column: the example of each concept, in the same order (the example of
## `concepts[i]` is `examples[i]`). Between 3 and 5, at most 72 characters each,
## all different, so no two concepts can be paired with the same example.
@export var examples: Array[String] = []


## The example that belongs to `concept_index`, or "" when the index is outside
## the board.
func get_example_of(concept_index: int) -> String:
	if concept_index < 0 or concept_index >= examples.size():
		return ""
	return examples[concept_index]


## How many concepts the board has: the number of cables the player must place
## before confirming (UC-10.5 / UC-10.6).
func size() -> int:
	return concepts.size()


func is_valid() -> bool:
	if concepts.size() < 3 or concepts.size() > 5 or examples.size() != concepts.size():
		return false
	var seen_concepts := {}
	for concept in concepts:
		if concept.is_empty() or concept.length() > 60:
			return false
		seen_concepts[concept] = true
	var seen_examples := {}
	for example in examples:
		if example.is_empty() or example.length() > 72:
			return false
		seen_examples[example] = true
	return seen_concepts.size() == concepts.size() and seen_examples.size() == examples.size()
