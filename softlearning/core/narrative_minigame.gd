class_name NarrativeMinigame
extends Minigame
## Narrative Fill-in-the-Blank engine (B5) of UC-09: one scenario from the
## narrative pool (B2) whose blanks the player fills from a bank of eight
## options, with a few attempts. No time limit.
##
## NarrativeView follows narrative_ready, answers_changed, attempt_failed and
## answered, and forwards the player's actions with place_option(),
## clear_blank() and confirm(). SessionOrchestrator only uses the Minigame
## contract.

## UC-09.3
signal narrative_ready(scenario: NarrativeScenario, attempts_left: int)
## UC-09.4 / UC-09.5: after every change; `answers` maps blank index -> option.
signal answers_changed(answers: Dictionary, can_confirm: bool)
## UC-09.7.a1
signal attempt_failed(attempts_left: int)
## UC-09.8
signal answered(is_correct: bool, correct_answers: Array[String])

## Key stored in MinigameResult.type and ResultRecord.type.
const TYPE := "NARRATIVE"
const POOL: NarrativePool = preload("res://resources/narrative_pool.tres")

var scenario: NarrativeScenario
## Blank index (1-based) -> option placed there.
var answers := {}
## UC-09.2: two lives, as the mockup shows them.
var max_attempts := 2
var attempts_left := 0
var is_correct := false
## True from start() until the result is decided or the game is aborted.
var _waiting := false


## UC-09.1 / UC-09.2 / UC-09.3
func start(new_department: Enums.Department, new_elo: float) -> void:
	department = new_department
	elo = new_elo
	scenario = POOL.get_narrative(department, elo)
	answers = {}
	attempts_left = max_attempts
	_waiting = true
	narrative_ready.emit(scenario, attempts_left)


## Nothing runs, so the answers and the attempts simply wait.
func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func abort() -> void:
	_waiting = false


## UC-09.4 / UC-09.4.a1: puts `option` in a blank, replacing what was there,
## without penalty. Only options of the bank and existing blanks count.
func place_option(blank_index: int, option: String) -> void:
	if paused or not _waiting:
		return
	if blank_index < 1 or blank_index > scenario.blanks.size() or not scenario.options.has(option):
		return
	answers[blank_index] = option
	_emit_answers()


## UC-09.4.a1: empties a blank without penalty.
func clear_blank(blank_index: int) -> void:
	if paused or not _waiting or not answers.has(blank_index):
		return
	answers.erase(blank_index)
	_emit_answers()


## UC-09.6 / UC-09.7: only once every blank is filled (UC-09.5).
func confirm() -> void:
	if paused or not _waiting or not _all_filled():
		return
	if _check_answers():
		is_correct = true
		_finish()
		return
	attempts_left -= 1
	if attempts_left > 0:
		attempt_failed.emit(attempts_left)
	else:
		is_correct = false
		_finish()


func get_result() -> MinigameResult:
	return MinigameResult.create(TYPE, is_correct, scenario.difficulty, department)


func _all_filled() -> bool:
	return answers.size() == scenario.blanks.size()


## UC-09.7: correct only if every blank holds its right option.
func _check_answers() -> bool:
	var correct := scenario.get_correct_answers()
	for i in correct.size():
		if answers.get(i + 1, "") != correct[i]:
			return false
	return true


func _emit_answers() -> void:
	answers_changed.emit(answers.duplicate(), _all_filled())


## UC-09.8 feedback first, then the result goes back to UC-02.5 (UC-09.9).
func _finish() -> void:
	_waiting = false
	answered.emit(is_correct, scenario.get_correct_answers())
	finished.emit(get_result())
