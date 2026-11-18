class_name SessionOrchestrator
extends Node
## Session orchestrator (B4) of UC-02: builds the sequence of one session,
## launches each minigame through the Minigame contract (B3), feeds every
## result to DepartmentManager (B1) and StatisticsTracker (B6), handles pause
## and exit, and hands the progress to PersistenceService (B7) when the session
## ends. UC-12 reuses it for the level-up sessions: a fixed sequence, no ELO
## per result, and a level-up resolved when the session closes.
##
## It is a node of the SessionView scene, never an autoload, so every session
## starts from a fresh orchestrator. It never calls the view: SessionView
## listens to the signals below and its buttons call the public methods.
##
## One step differs from the UC-02 sequence diagram: after a result it waits
## for next() before launching the following minigame, so the player can read
## the feedback ("Siguiente minijuego" in the mockups) instead of losing it on the
## same frame. UC-12's `level_up_ended` plays the role of the diagram's
## `session_ended(outcome, new_level)`; the UC-02 signal of that name keeps its
## own signature.

## UC-12.4: the authored sequences of every department and target level.
const LEVEL_UP_POOL: LevelUpPool = preload("res://resources/level_up_pool.tres")

## UC-02.4: `minigame` exists and is about to start; the view binds to it now.
signal minigame_started(minigame: Minigame)
## UC-02.6: the ELO moved by `delta` and is now `elo`. Lets the view show the
## change next to the feedback, so the player can follow the calculation.
signal elo_updated(delta: float, elo: float)
## UC-02.4.a1.1
signal paused
## UC-02.4.a1.4
signal resumed
## UC-02.8.e1
signal save_failed
## UC-02.9: the session ended, with the total ELO change it produced. UC-01 uses
## the delta for the final tutorial message.
signal session_ended(department: Enums.Department, elo_delta: float)
## UC-12.4.e1 / UC-12.2: the level-up cannot start (no scripted session for the
## target level, or the option is not available anymore). `reason` is ready to
## be shown to the player; emitted by `start_level_up_session()`.
signal level_up_unavailable(reason: String)
## UC-12.10: the level-up session ended with `outcome` and the department is now
## at `new_level`. A CANCELLED outcome means the save failed (UC-12.9.e1).
signal level_up_ended(outcome: Enums.LevelUpOutcome, new_level: int)

enum SessionState { ACTIVE, PAUSED, ENDED }
## UC-01 turns a session into a guided one without changing the rest of UC-02.
enum SessionMode { NORMAL, TUTORIAL, LEVEL_UP }

## Minigames per session (the mockup shows "Pregunta 4 de 10").
const SEQUENCE_LENGTH := 10
## UC-01.9: the first result of the tutorial counts 10 times, then 9, … down to 1.
const TUTORIAL_PLACEMENT_WEIGHT := 10.0

## UC-02.4.a1.3.a1: seconds a pause may last before the session ends by itself.
@export var pause_time_limit := 300.0

var department: Enums.Department
var mode := SessionMode.NORMAL
## ELO when the session started, so `session_ended` can report the net change.
var elo_at_session_start := 0.0
## Minigames playable in every department (their pools cover all four).
var generic_minigames: Array[String] = [QuizMinigame.TYPE, SwipeMinigame.TYPE, NarrativeMinigame.TYPE]
var sequence: Array[String] = []
var current_index := 0
var current_minigame: Minigame
## ENDED until start_session(): nothing runs before that.
var state := SessionState.ENDED
var results: Array[MinigameResult] = []
var pause_time_left := 0.0
## UC-12: the scripted session in play, the level it unlocks and the state to
## roll back to if the save fails. All null/0 outside a level-up.
var level_up_session: LevelUpSession
var level_up_target_level := 0
var level_up_snapshot: LevelUpSnapshot


## UC-02.1 / UC-02.2
func start_session(new_department: Enums.Department) -> void:
	mode = SessionMode.NORMAL
	_begin(new_department)


## UC-01.8: the guided session behaves like UC-02, but each result is weighted
## by `placement_weight()` before B1/B6 see it (UC-01.9).
func start_tutorial_session(new_department: Enums.Department) -> void:
	mode = SessionMode.TUTORIAL
	_begin(new_department)


## UC-12.3 / UC-12.4: starts the scripted session that unlocks the department's
## next level. Returns false when the level-up cannot run, after emitting
## `level_up_unavailable` with the reason (UC-12.2.a1/a2, UC-12.4.e1); the
## department is left untouched in that case.
func start_level_up_session(new_department: Enums.Department) -> bool:
	var department_state := DepartmentManager.get_state(new_department)
	if not DepartmentManager.is_level_up_available(new_department):
		level_up_unavailable.emit(_level_up_unavailable_reason(new_department))
		return false

	var scripted := LEVEL_UP_POOL.get_session(new_department, department_state.level + 1)
	if scripted == null or scripted.sequence.is_empty():
		level_up_unavailable.emit(
			"No hay una sesión de subida de nivel para %s en el nivel %d."
			% [DepartmentManager.get_department_name(new_department), department_state.level + 1]
		)
		return false

	mode = SessionMode.LEVEL_UP
	department = new_department
	level_up_session = scripted
	level_up_target_level = scripted.target_level
	# UC-12.9.e1: taken before anything changes, so the save failure can undo it.
	level_up_snapshot = DepartmentManager.snapshot(new_department)
	elo_at_session_start = department_state.elo
	sequence = scripted.sequence.duplicate()
	current_index = 0
	results.clear()
	state = SessionState.ACTIVE
	_launch_next()
	return true


func _begin(new_department: Enums.Department) -> void:
	department = new_department
	elo_at_session_start = DepartmentManager.get_elo(department)
	_build_sequence()
	current_index = 0
	results.clear()
	state = SessionState.ACTIVE
	_launch_next()


## UC-01.9: 10 for the first result of the tutorial, 9 for the second, … and 1
## from the tenth on.
func placement_weight(index: int) -> float:
	return maxf(1.0, TUTORIAL_PLACEMENT_WEIGHT - float(index))


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
## UC-12.5.a2: an interrupted level-up counts as a failed one and is resolved.
func exit() -> void:
	if state == SessionState.ENDED:
		return
	if current_minigame:
		current_minigame.abort()
		_drop_minigame()
	if mode == SessionMode.LEVEL_UP:
		_resolve_level_up(false)
		return
	_save_progress()
	_end_session()


## UC-02.7: launches the next minigame, or saves and closes the session after
## the last one (UC-02.8 / UC-02.9). Ignored while a minigame is being played.
## In a level-up, finishing the whole sequence is what makes it pass (UC-12.5).
func next() -> void:
	if state != SessionState.ACTIVE or current_minigame:
		return
	if current_index < sequence.size():
		_launch_next()
	elif mode == SessionMode.LEVEL_UP:
		_resolve_level_up(true)
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
	if mode == SessionMode.LEVEL_UP:
		# UC-12.4: the scripted session plays at the target level's difficulty.
		# The engines take the difficulty from the ELO their pool receives, so
		# the level's anchor is what pins it (1 -> easy … 4 -> very hard).
		elo = Enums.difficulty_to_elo(Enums.difficulty_for_level(level_up_target_level))
	current_minigame = _create_minigame(sequence[current_index])
	minigame_started.emit(current_minigame)
	current_minigame.start(department, elo)


## One arm per engine (B5) the orchestrator can create.
func _create_minigame(type: String) -> Minigame:
	var minigame: Minigame
	match type:
		"QUIZ":
			minigame = QuizMinigame.new()
		"SWIPE":
			minigame = SwipeMinigame.new()
		"NARRATIVE":
			minigame = NarrativeMinigame.new()
		"TRAIN":
			minigame = TrainMinigame.new()
		"BOMB":
			minigame = BombMinigame.new()
		"PUZZLE":
			minigame = PuzzleMinigame.new()
		"STACK_PUZZLE":
			minigame = StackPuzzleMinigame.new()
	minigame.finished.connect(_on_minigame_finished)
	add_child(minigame)
	return minigame


## UC-02.5 / UC-02.6, with the UC-01.9 placement weight when in tutorial mode.
## UC-12: a level-up result never moves the ELO nor enters the statistics; only
## whether it was a miss matters, and B1 counts those at the end (UC-12.5).
func _on_minigame_finished(result: MinigameResult) -> void:
	results.append(result)
	if mode != SessionMode.LEVEL_UP:
		var weight := placement_weight(current_index) if mode == SessionMode.TUTORIAL else 1.0
		var elo_before := DepartmentManager.get_elo(result.department)
		DepartmentManager.update_elo(result, weight)
		StatisticsTracker.register_result(result, weight)
		var elo_after := DepartmentManager.get_elo(result.department)
		elo_updated.emit(elo_after - elo_before, elo_after)
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
	data.player_progress = DepartmentManager.get_player_progress()
	if not PersistenceService.save_progress(data):
		save_failed.emit()


## UC-02.9
func _end_session() -> void:
	state = SessionState.ENDED
	var elo_delta := DepartmentManager.get_elo(department) - elo_at_session_start
	session_ended.emit(department, elo_delta)


## UC-12.5 / UC-12.8 / UC-12.9: asks B1 to resolve the level-up with the results
## collected so far, saves, and only then reports it. When the save fails, the
## snapshot puts the department and the daily mark back and the outcome becomes
## CANCELLED (UC-12.9.e1); the save error screen is shown in both cases.
func _resolve_level_up(completed: bool) -> void:
	var outcome := DepartmentManager.resolve_level_up(department, results, completed)
	var data := SaveData.create()
	data.department_states = DepartmentManager.get_all_states()
	data.history = StatisticsTracker.get_history()
	data.player_progress = DepartmentManager.get_player_progress()
	if not PersistenceService.save_progress(data):
		DepartmentManager.rollback(level_up_snapshot)
		save_failed.emit()
		outcome = Enums.LevelUpOutcome.CANCELLED
	_end_level_up(outcome)


## UC-12.10: reports the outcome and the level the department ends up at.
func _end_level_up(outcome: Enums.LevelUpOutcome) -> void:
	state = SessionState.ENDED
	level_up_ended.emit(outcome, DepartmentManager.get_state(department).level)


## UC-12.2.a1 / UC-12.2.a2 / UC-12.1: why the option is not available, ready to
## show to the player.
func _level_up_unavailable_reason(department: Enums.Department) -> String:
	if DepartmentManager.get_state(department).is_at_max_level():
		return "El departamento ya está en el nivel %d, el máximo." % DepartmentState.MAX_LEVEL
	if DepartmentManager.get_player_progress().is_level_up_used_today():
		return "Ya se hizo una subida de nivel hoy; vuelve mañana."
	return "El departamento todavía no llegó al ELO necesario para subir de nivel."


func _drop_minigame() -> void:
	current_minigame.queue_free()
	current_minigame = null
