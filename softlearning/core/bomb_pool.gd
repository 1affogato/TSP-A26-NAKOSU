class_name BombPool
extends ContentPool
## Bomb Defusal pool (B2) of UC-04. Difficulty choice and draw without repeats
## live in ContentPool.

@export var bombs: Array[Bomb]


## UC-04.1
func get_bomb(department: Enums.Department, elo: float) -> Bomb:
	return _pick(bombs, department, elo)
