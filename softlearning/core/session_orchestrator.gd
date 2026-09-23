class_name SessionOrchestrator
extends Node
## Session orchestrator (B4) of UC-02: builds the sequence of one session,
## launches each minigame through the Minigame contract (B3), feeds every
## result to DepartmentManager (B1) and StatisticsTracker (B6), handles pause
## and exit, and hands the progress to PersistenceService (B7) when the session
## ends.
##
## It is a node of the SessionView scene, never an autoload, so every session
## starts from a fresh orchestrator. It never calls the view: SessionView
## listens to the signals below and its buttons call the public methods.
##
## One step differs from the UC-02 sequence diagram: after a result it waits
## for next() before launching the following minigame, so the player can read
## the feedback ("Siguiente Pregunta" in the mockup) instead of losing it on the
## same frame.

## UC-02.4: `minigame` exists and is about to start; the view binds to it now.
signal minigame_started(minigame: Minigame)
## UC-02.4.a1.1
signal paused
## UC-02.4.a1.4
signal resumed
## UC-02.8.e1
signal save_failed
## UC-02.9
signal session_ended(department: Enums.Department)

enum SessionState { ACTIVE, PAUSED, ENDED }

## Minigames per session (the mockup shows "Pregunta 4 de 10").
const SEQUENCE_LENGTH := 10

## UC-02.4.a1.3.a1: seconds a pause may last before the session ends by itself.
@export var pause_time_limit := 300.0

var department: Enums.Department
## Minigames playable in every department (the quiz pool covers all four).
var generic_minigames: Array[String] = [QuizMinigame.TYPE]
var sequence: Array[String] = []
var current_index := 0
var current_minigame: Minigame
## ENDED until start_session(): nothing runs before that.
var state := SessionState.ENDED
var results: Array[MinigameResult] = []
var pause_time_left := 0.0


## UC-02.1 / UC-02.2
func start_session(new_department: Enums.Department) -> void:
	department = new_department
	_build_sequence()
	current_index = 0
	results.clear()
	state = SessionState.ACTIVE
	_launch_next()


## UC-02.4.a1
func pause() -> void:
	if state != SessionState.ACTIVE:
		return
	if current_minigame:
		current_minigame.pause()
	state = SessionState.PAUSED
	pause_time_left = pause_time_limit
	paused.emit()


## UC-02.4.a1.3 / UC-02.4.a1.4
func resume() -> void:
	if state != SessionState.PAUSED:
		return
	if current_minigame:
		current_minigame.resume()
	state = SessionState.ACTIVE
	resumed.emit()


## UC-02.4.a2: the minigame in play gives no result; what was finished is saved.
func exit() -> void:
	if state == SessionState.ENDED:
		return
	if current_minigame:
		current_minigame.abort()
		_drop_minigame()
	_save_progress()
	_end_session()


## UC-02.7: launches the next minigame, or saves and closes the session after
## the last one (UC-02.8 / UC-02.9). Ignored while a minigame is being played.
func next() -> void:
	if state != SessionState.ACTIVE or current_minigame:
		return
	if current_index < sequence.size():
		_launch_next()
	else:
		_save_progress()
		_end_session()


func _process(delta: float) -> void:
	if state != SessionState.PAUSED:
		return
	pause_time_left -= delta
	if pause_time_left <= 0.0:
		_on_pause_timeout()


## UC-02.2: the department's own minigames plus the generic ones, taken in
## turns until the sequence is full.
func _build_sequence() -> void:
	var available := DepartmentManager.get_enabled_minigames(department) + generic_minigames
	available.shuffle()
	sequence.clear()
	for i in SEQUENCE_LENGTH:
		sequence.append(available[i % available.size()])


## UC-02.3 / UC-02.4
func _launch_next() -> void:
	var elo := DepartmentManager.get_elo(department)
	current_minigame = _create_minigame(sequence[current_index])
	minigame_started.emit(current_minigame)
	current_minigame.start(department, elo)


## One arm per engine (B5) the orchestrator can create.
func _create_minigame(type: String) -> Minigame:
	var minigame: Minigame
	match type:
		QuizMinigame.TYPE:
			minigame = QuizMinigame.new()
	minigame.finished.connect(_on_minigame_finished)
	add_child(minigame)
	return minigame


## UC-02.5 / UC-02.6
func _on_minigame_finished(result: MinigameResult) -> void:
	results.append(result)
	DepartmentManager.update_elo(result)
	StatisticsTracker.register_result(result)
	current_index += 1
	_drop_minigame()


## UC-02.4.a1.3.a1: ends the session exactly like an exit.
func _on_pause_timeout() -> void:
	exit()


## UC-02.8, and UC-02.8.e1 when PersistenceService cannot write.
func _save_progress() -> void:
	var data := SaveData.create()
	data.department_states = DepartmentManager.get_all_states()
	data.history = StatisticsTracker.get_history()
	if not PersistenceService.save_progress(data):
		save_failed.emit()


## UC-02.9
func _end_session() -> void:
	state = SessionState.ENDED
	session_ended.emit(department)


func _drop_minigame() -> void:
	current_minigame.queue_free()
	current_minigame = null
