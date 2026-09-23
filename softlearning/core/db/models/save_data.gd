class_name SaveData
extends Resource
## The bundle UC-02 hands to the persistence service when a session ends
## (UC-02, "SaveData").
##
## The `SessionOrchestrator` fills it with `DepartmentManager.get_all_states()`
## (B1) and `StatisticsTracker.get_history()` (B6), and `save_progress()` splits
## it on disk: one `.tres` per department state, and every history record as one
## line of `result_history.jsonl`.

@export var department_states: Array[DepartmentState] = []
@export var history: Array[ResultRecord] = []


static func create() -> SaveData:
	return SaveData.new()


## State of one department inside this bundle, or null when it is not here.
func get_state(department: Enums.Department) -> DepartmentState:
	for state in department_states:
		if state.department == department:
			return state
	return null
