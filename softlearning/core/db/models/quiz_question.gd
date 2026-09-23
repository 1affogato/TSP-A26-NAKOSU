class_name QuizQuestion
extends Resource
## One multiple-choice question of the quiz pool (UC-07, "QuizQuestion").
##
## These are authored content, not save data: the instances live in the content
## pool (`QuizPool`, B2) and `QuizMinigame` receives exactly one of them when it
## starts (UC-07.1). `DbService` never stores them — it is a `Resource` so the
## questions ship with the game and can be edited from the inspector.
##
## The diagram's plain accessors (`get_department()`, `get_title()`,
## `get_description()`, `get_difficulty()`) are the exported properties
## themselves, so they are read as `question.title`, `question.department`, and
## so on. Only the methods that compute or protect something are written out.

## Stable identifier of the question inside the pool.
@export var id: int = 0
## Department the question belongs to. UC-07 removed `QuizCategory`: this is a
## direct field of the question now.
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var title: String = ""
@export var description: String = ""
## The possible answers, in the order they are shown.
@export var responses: Array[String] = []
## Index into `responses` of the only right answer.
@export var correct_response_index: int = 0
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL


## UC-07.4: whether `response` is the right answer.
##
## The comparison is by text because that is what the view sends back
## (`QuizMinigame.answer(response)`). A misconfigured question has no right
## answer, so it marks everything as wrong instead of accepting a blank reply.
func is_correct_response(response: String) -> bool:
	var correct := get_correct_response()
	return not correct.is_empty() and response == correct


## The answers the view may show, in authored order. Returns a copy, so a view
## that shuffles them cannot modify the question itself.
func get_possible_responses() -> Array[String]:
	var copy: Array[String] = responses.duplicate()
	return copy


## The right answer, or "" when `correct_response_index` points outside
## `responses` (indexing the array directly would be an error).
func get_correct_response() -> String:
	if correct_response_index < 0 or correct_response_index >= responses.size():
		return ""
	return responses[correct_response_index]


## True when the question is usable: it has a title, at least two answers and a
## right answer inside the range. Handy while authoring, and it lets the pool
## skip a broken entry instead of crashing on it.
func is_valid() -> bool:
	return (
		not title.is_empty()
		and responses.size() >= 2
		and correct_response_index >= 0
		and correct_response_index < responses.size()
	)
