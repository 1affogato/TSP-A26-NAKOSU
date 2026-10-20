class_name TrainMinigame
extends Minigame
## Train Sorting engine (B5) of UC-03: one sequence from the train pool (B2),
## shown scrambled, to be put in order within `time_limit` seconds.
##
## TrainView follows sequence_ready, order_changed, time_updated and answered,
## and forwards the player's moves with move_wagon() and confirm().
## SessionOrchestrator only uses the Minigame contract.

## UC-03.2
signal sequence_ready(instruction: String, wagons: Array[String])
## UC-03.4: after every move.
signal order_changed(order: Array[String])
## UC-03.3: every frame while the player can still confirm.
signal time_updated(time_left: float)
## UC-03.6, and UC-03.5.a1 when the time runs out.
signal answered(is_correct: bool, correct_order: Array[String])

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "TRAIN"
const POOL: TrainPool = preload("res://resources/train_pool.tres")

var sequence: TrainSequence
## Current order of the wagons on screen.
var order: Array[String] = []
## R03-5
var time_limit := 60.0
var time_left := 0.0
var is_correct := false
## True from start() until the order is confirmed, times out or is aborted.
var _waiting := false


func _ready() -> void:
	set_process(false)


## UC-03.1 / UC-03.2 / UC-03.3
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	sequence = POOL.get_sequence(department, elo)
	order = _scramble()
	time_left = time_limit
	_waiting = true
	sequence_ready.emit(sequence.instruction, order.duplicate())
	set_process(true)


## N03-4: the order and the remaining time stay as they are.
func pause() -> void:
	paused = true
	set_process(false)


func resume() -> void:
	paused = false
	set_process(_waiting)


func abort() -> void:
	_waiting = false
	set_process(false)


## UC-03.4 / R03-6: moves the wagon at `from` to position `to`, as many times
## as the player wants. Ignored while paused or once the order is closed.
func move_wagon(from: int, to: int) -> void:
	if paused or not _waiting:
		return
	if from == to or from < 0 or to < 0 or from >= order.size() or to >= order.size():
		return
	order.insert(to, order.pop_at(from))
	order_changed.emit(order.duplicate())


## UC-03.5 / UC-03.6: the order can be confirmed only once (R03-6).
func confirm() -> void:
	if paused or not _waiting:
		return
	is_correct = sequence.is_correct_order(order)
	_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, sequence.difficulty, department)


func _process(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	time_updated.emit(time_left)
	if time_left == 0.0:
		_on_timeout()


## R03-3: a random order that is never the correct one. The wagons are all
## different and at least four, so the loop always ends.
func _scramble() -> Array[String]:
	var scrambled: Array[String] = sequence.wagons.duplicate()
	while scrambled == sequence.wagons:
		scrambled.shuffle()
	return scrambled


## UC-03.5.a1: the time ran out, so the order counts as wrong.
func _on_timeout() -> void:
	is_correct = false
	_finish()


## UC-03.6 feedback first, then the result goes back to UC-02.5 (UC-03.7).
func _finish() -> void:
	_waiting = false
	set_process(false)
	answered.emit(is_correct, sequence.wagons.duplicate())
	finished.emit(get_result())
