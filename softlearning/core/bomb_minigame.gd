class_name BombMinigame
extends Minigame
## Bomb Defusal engine (B5) of UC-04: one bomb from the bomb pool (B2) with
## three locks, all to be deactivated within a single countdown.
##
## BombView follows question_ready, time_updated, lock_deactivated and
## answered, and forwards each cut with cut_wire(). SessionOrchestrator only
## uses the Minigame contract.

## UC-04.2 / UC-04.7
signal question_ready(question: BombQuestion, locks_left: int)
## UC-04.3: every frame while the countdown runs.
signal time_updated(time_left: float)
## UC-04.6
signal lock_deactivated(locks_left: int)
## UC-04.9, UC-04.5.a1 and UC-04.4.a1. `correct_wire` belongs to the current
## lock (the last one when the bomb was defused).
signal answered(is_correct: bool, correct_wire: String)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "BOMB"
const POOL: BombPool = preload("res://resources/bomb_pool.tres")

var bomb: Bomb
var locks_left := 0
## R04-3: one countdown for the whole bomb.
var time_limit := 60.0
var time_left := 0.0
var is_correct := false
## True from start() until the bomb is defused, explodes, times out or is
## aborted.
var _waiting := false


func _ready() -> void:
	set_process(false)


## UC-04.1 / UC-04.2 / UC-04.3
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	bomb = POOL.get_bomb(department, elo)
	locks_left = bomb.questions.size()
	time_left = time_limit
	_waiting = true
	question_ready.emit(get_current_question(), locks_left)
	set_process(true)


## N04-4: the countdown, the locks already deactivated and the current
## question stay as they are.
func pause() -> void:
	paused = true
	set_process(false)


func resume() -> void:
	paused = false
	set_process(_waiting)


func abort() -> void:
	_waiting = false
	set_process(false)


## UC-04.4 / UC-04.5: a right wire deactivates the lock (UC-04.6) and shows
## the next one (UC-04.7); a wrong wire ends the minigame (UC-04.5.a1, R04-4).
func cut_wire(wire: String) -> void:
	if paused or not _waiting:
		return
	if not get_current_question().is_correct_wire(wire):
		is_correct = false
		_finish()
		return
	locks_left -= 1
	lock_deactivated.emit(locks_left)
	if locks_left == 0:
		is_correct = true
		_finish()
	else:
		question_ready.emit(get_current_question(), locks_left)


## The lock being played, or the last one once the bomb is defused.
func get_current_question() -> BombQuestion:
	var index := mini(bomb.questions.size() - locks_left, bomb.questions.size() - 1)
	return bomb.questions[index]


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, bomb.difficulty, department)


func _process(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	time_updated.emit(time_left)
	if time_left == 0.0:
		_on_timeout()


## UC-04.4.a1: the countdown reached zero before the three locks.
func _on_timeout() -> void:
	is_correct = false
	_finish()


## UC-04.9 feedback first, then the result goes back to UC-02.5 (UC-04.10).
func _finish() -> void:
	_waiting = false
	set_process(false)
	answered.emit(is_correct, get_current_question().get_correct_wire())
	finished.emit(get_result())
