class_name TrainSequence
extends Resource
## One sequence of the Train Sorting pool (UC-03, "TrainSequence"): the
## instruction and its wagons, stored in the correct order.
##
## Authored content that lives in TrainPool (B2); TrainMinigame receives
## exactly one (UC-03.1).

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.SOFTWARE_DEV
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
## Stays visible during the whole minigame (N03-1).
@export var instruction: String = ""
## Between 4 and 6 texts (R03-1) of at most 40 characters (N03-1), in the
## correct order, all different so the order is unique (R03-2).
@export var wagons: Array[String] = []


## UC-03.6 / R03-4: correct only when every wagon is in its place.
func is_correct_order(order: Array[String]) -> bool:
	return order == wagons


func is_valid() -> bool:
	var unique := {}
	for wagon in wagons:
		if wagon.is_empty() or wagon.length() > 40:
			return false
		unique[wagon] = true
	return not instruction.is_empty() and wagons.size() >= 4 and wagons.size() <= 6 and unique.size() == wagons.size()
