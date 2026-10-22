class_name MinigamePool
extends ContentPool
## Quiz pool (B2, "QuizPool" in the UC-07 diagram). The difficulty choice and
## the draw without repeats live in ContentPool.

@export var questions: Array[QuizQuestion]

func get_question(department: Enums.Department, elo: float) -> QuizQuestion:
	# Returns a question of the department. Null only if the department has none.
	return _pick(questions, department, elo)
