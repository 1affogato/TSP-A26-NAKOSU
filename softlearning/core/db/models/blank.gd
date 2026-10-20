class_name Blank
extends Resource
## One blank of a NarrativeScenario (UC-09, "Blank"): its position in the story
## and the option that fills it correctly. It only exists inside its scenario.

## 1-based order of the blank in the story; the story marks it as "[BLANK_n]".
@export var index: int = 1
## Must be one of the scenario's options.
@export var correct_answer: String = ""


static func create(new_index: int, answer: String) -> Blank:
	var blank := Blank.new()
	blank.index = new_index
	blank.correct_answer = answer
	return blank
