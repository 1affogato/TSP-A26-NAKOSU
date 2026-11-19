class_name SaveData
extends Resource
## The bundle UC-02 hands to the persistence service when a session ends
## (UC-02, "SaveData").
##
## The `SessionOrchestrator` fills it with `DepartmentManager.get_all_states()`
## (B1), `StatisticsTracker.get_history()` (B6) and the flags of
## `DepartmentManager.get_player_progress()` (UC-01, UC-12), and `save_progress()`
## splits it on disk: one `.tres` per department state, every history record as
## one line of `result_history.jsonl`, and `player_progress.tres`.

@export var department_states: Array[DepartmentState] = []
@export var history: Array[ResultRecord] = []
## UC-12.8: the daily level-up mark is saved with the session that spent it.
## Null means this bundle does not touch the flags (the tutorial writes them
## separately through `save_player_progress()`).
@export var player_progress: PlayerProgress


static func create() -> SaveData:
	return SaveData.new()


## State of one department inside this bundle, or null when it is not here.
func get_state(department: Enums.Department) -> DepartmentState:
	for state in department_states:
		if state.department == department:
			return state
	return null
