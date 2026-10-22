class_name NarrativePool
extends ContentPool
## Narrative Fill-in-the-Blank pool (B2) of UC-09. Difficulty choice and draw
## without repeats live in ContentPool.

@export var scenarios: Array[NarrativeScenario]


## UC-09.1
func get_narrative(department: Enums.Department, elo: float) -> NarrativeScenario:
	return _pick(scenarios, department, elo)
