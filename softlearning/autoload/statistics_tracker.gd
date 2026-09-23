extends Node
## StatisticsTracker — autoload singleton, "Estadísticas y progreso" (B6).
##
## Owns the history of every finished minigame while the game runs: it starts
## from what DbService (B7) stored, SessionOrchestrator (B4) adds each new
## result (UC-02.6) and hands the whole history back to B7 when a session ends
## (UC-02.8).

var history: Array[ResultRecord] = []


func _ready() -> void:
	history = DbService.load_history()


## UC-02.6: stores `result` stamped with the current time.
func register_result(result: MinigameResult) -> void:
	history.append(ResultRecord.create(result.type, result.department, result.level, result.success))


## UC-02.8: the complete history, oldest first, as DbService.save_progress()
## expects it.
func get_history() -> Array[ResultRecord]:
	return history
