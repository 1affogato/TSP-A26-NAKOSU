class_name SwipeMinigame
extends Minigame
## Swipe! engine (B5) of UC-08: one card from the swipe pool (B2), swiped
## toward one of its two categories. No time limit (R08-3).
##
## SwipeView follows card_ready and answered and forwards the swipe that
## counts with swipe(). An incomplete swipe (UC-08.3.a1) never reaches the
## engine: the view returns the card to the center by itself.
## SessionOrchestrator only uses the Minigame contract.

## UC-08.2
signal card_ready(card: SwipeCard)
## UC-08.4
signal answered(is_correct: bool, correct_category: SwipeCard.SwipeCategory)

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "SWIPE"
const POOL: SwipePool = preload("res://resources/swipe_pool.tres")

var card: SwipeCard
var selected_category: SwipeCard.SwipeCategory
var is_correct := false
## True from start() until the card is swiped or aborted.
var _waiting := false


## UC-08.1 / UC-08.2
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	card = POOL.get_card(department, elo)
	_waiting = true
	card_ready.emit(card)


## N08-4: nothing runs, so the card simply waits.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func abort() -> void:
	_waiting = false


## UC-08.3 / UC-08.4: the first swipe that counts is final (R08-5). Ignored
## while paused or once the card was answered.
func swipe(category: SwipeCard.SwipeCategory) -> void:
	if paused or not _waiting:
		return
	selected_category = category
	is_correct = card.check_answer(category)
	_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, card.difficulty, department)


## UC-08.4 feedback first, then the result goes back to UC-02.5 (UC-08.5).
func _finish() -> void:
	_waiting = false
	answered.emit(is_correct, card.correct_category)
	finished.emit(get_result())
