class_name QuizMinigame
extends Minigame
## Quiz engine (B5) of UC-07: one multiple-choice question from the quiz pool
## (B2), to be answered within `time_limit` seconds.
##
## QuizView follows question_ready, time_updated and answered, and forwards the
## player's choice with answer(). SessionOrchestrator only uses the Minigame
## contract.

## UC-07.2
signal question_ready(question: QuizQuestion)
## UC-07.3: every frame while the player can still answer.
signal time_updated(time_left: float)
## UC-07.4, and UC-07.3.a1 when the time runs out.
signal answered(is_correct: bool)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "QUIZ"
const POOL: MinigamePool = preload("res://resources/quiz_pool.tres")

var question: QuizQuestion
var time_limit := 30.0
var time_left := 0.0
var selected_response := ""
var is_correct := false
## True from start() until the question is answered, times out or is aborted.
var _waiting := false


func _ready() -> void:
	set_process(false)


## UC-07.1 / UC-07.2
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	question = POOL.get_question(department, elo)
	time_left = time_limit
	_waiting = true
	question_ready.emit(question)
	set_process(true)


func pause() -> void:
	paused = true
	set_process(false)


func resume() -> void:
	paused = false
	set_process(_waiting)


func abort() -> void:
	_waiting = false
	set_process(false)


## UC-07.3 / UC-07.4. Ignored while paused or once the question is closed.
func answer(response: String) -> void:
	if paused or not _waiting:
		return
	selected_response = response
	is_correct = question.is_correct_response(response)
	_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, question.difficulty, department)


func _process(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	time_updated.emit(time_left)
	if time_left == 0.0:
		_on_timeout()


## UC-07.3.a1: the time ran out, so the question counts as wrong.
func _on_timeout() -> void:
	is_correct = false
	_finish()


## UC-07.5: feedback first, then the result goes back to UC-02.5.
func _finish() -> void:
	_waiting = false
	set_process(false)
	answered.emit(is_correct)
	finished.emit(get_result())
