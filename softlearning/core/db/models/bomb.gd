class_name Bomb
extends Resource
## One bomb of the Bomb Defusal pool (UC-04, "Bomb"): three locks, one
## question each (R04-1). Authored content that lives in BombPool (B2).

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.REQUIREMENTS
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
## The locks in the order they are played.
@export var questions: Array[BombQuestion] = []


func is_valid() -> bool:
	return questions.size() == 3 and questions.all(func(q: BombQuestion): return q.is_valid())
