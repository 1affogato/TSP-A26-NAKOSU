class_name StatEntry
extends Resource
## One row of the detailed breakdown (UC-11.5, "StatEntry").
##
## `label` depends on the [enum Enums.StatType] that was requested: the minigame
## type (BY_MINIGAME), the difficulty (BY_DIFFICULTY) or the date (OVER_TIME).

@export var label: String = ""
@export var played: int = 0
@export var correct: int = 0


static func create(new_label: String, played_count: int, correct_count: int) -> StatEntry:
	var entry := StatEntry.new()
	entry.label = new_label
	entry.played = played_count
	entry.correct = correct_count
	return entry


## Share of correct answers in this row. Returns 0.0 while nothing was played.
func get_accuracy() -> float:
	if played == 0:
		return 0.0
	return float(correct) / float(played)
