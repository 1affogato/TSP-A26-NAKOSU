class_name SwipePool
extends ContentPool
## Swipe! pool (B2) of UC-08. Difficulty choice and draw without repeats live
## in ContentPool.

@export var cards: Array[SwipeCard]


## UC-08.1
func get_card(department: Enums.Department, elo: float) -> SwipeCard:
	return _pick(cards, department, elo)
