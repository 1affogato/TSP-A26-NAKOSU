extends Node
## DepartmentManager — autoload singleton, "Gestión de departamentos" (B1).
##
## Owns the four DepartmentState while the game runs: it starts from what
## DbService (B7) stored and SessionOrchestrator (B4) hands the states back to
## B7 at the end of every session (UC-02.8).

## How hard an item of each difficulty is, on the player's ELO scale. They are
## the same anchors MinigamePool uses to choose the difficulty from the ELO.
const DIFFICULTY_RATING := {
	Enums.Difficulty.FACIL: 1000.0,
	Enums.Difficulty.MEDIO: 1500.0,
	Enums.Difficulty.DIFICIL: 2000.0,
	Enums.Difficulty.MUY_DIFICIL: 2500.0,
}
## Largest ELO change a single result can cause.
const K_FACTOR := 32.0

var states: Dictionary[Enums.Department, DepartmentState] = {}


func _ready() -> void:
	for state in DbService.load_department_states():
		states[state.department] = state


func get_elo(department: Enums.Department) -> float:
	return states[department].elo


## UC-02.2: minigames that only this department plays (the generic ones live
## in SessionOrchestrator).
func get_enabled_minigames(_department: Enums.Department) -> Array[String]:
	# ponytail: no department-specific minigame exists yet; map
	# department -> minigame types here when the first one lands.
	return []


## UC-02.6
func update_elo(result: MinigameResult) -> void:
	var state := states[result.department]
	state.elo += _compute_elo_delta(result)
	state.sanitize()


## UC-02.8: the states to save, in enum order.
func get_all_states() -> Array[DepartmentState]:
	var all: Array[DepartmentState] = []
	all.assign(states.values())
	return all


## Standard Elo with the item as the opponent: a hit on a hard item adds more,
## and a miss on a hard item subtracts less, than the same result on an easy one.
func _compute_elo_delta(result: MinigameResult) -> float:
	var gap: float = DIFFICULTY_RATING[result.level] - get_elo(result.department)
	var expected := 1.0 / (1.0 + pow(10.0, gap / 400.0))
	return K_FACTOR * ((1.0 if result.success else 0.0) - expected)
