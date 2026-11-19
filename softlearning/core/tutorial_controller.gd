class_name TutorialController
extends Node
## Tutorial flow (UC-01, B4). `DepartmentView` creates one as its child, so the
## composition matches the class diagram; the state that has to survive the
## guided session (step, department, ELO delta) lives in `TutorialRun`.
##
## The controller never touches the overlay or the session view: it emits
## `step_changed`, and `DepartmentView` decides what to show. `complete()` is the
## only method that writes through B1/B7, and only at the end (UC-01.11).

## The next step the view has to show. SESSION and DONE mean "no overlay".
signal step_changed(step: Enums.TutorialStep)
## UC-01.11.e1: the completion could not be saved; the run stays incomplete.
signal save_failed(reason: String)
## UC-01.12: the completion was saved and the view may close the overlay.
signal tutorial_finished()

## Read-only view of the step carried by `TutorialRun`.
var step: Enums.TutorialStep:
	get:
		return TutorialRun.step


## UC-01.2: starts the tutorial when it has not been completed yet. Restores an
## in-progress run after the guided session, and resets it after an app restart
## (UC-01.2.a1). Returns whether the tutorial is running.
func start_if_pending() -> bool:
	if DepartmentManager.is_tutorial_completed():
		TutorialRun.active = false
		TutorialRun.step = Enums.TutorialStep.DONE
		return false
	if not TutorialRun.active:
		TutorialRun.reset()
		TutorialRun.active = true
	step_changed.emit(TutorialRun.step)
	return true


func is_active() -> bool:
	return TutorialRun.active and not DepartmentManager.is_tutorial_completed()


## UC-01.4: the player chose a department. Only the highlighted floor buttons
## reach this method (the overlay filters the click), and it only advances from
## the first step.
func on_department_selected(department: Enums.Department) -> void:
	if not is_active() or TutorialRun.step != Enums.TutorialStep.DEPARTMENTS:
		return
	TutorialRun.department = department
	TutorialRun.step = Enums.TutorialStep.ELO
	step_changed.emit(TutorialRun.step)


## UC-01.6: a click anywhere completes the ELO explanation.
func on_elo_step_confirmed() -> void:
	if not is_active() or TutorialRun.step != Enums.TutorialStep.ELO:
		return
	TutorialRun.step = Enums.TutorialStep.PLAY
	step_changed.emit(TutorialRun.step)


## UC-01.8: the player started the guided session. Returns true when this
## press belongs to the tutorial, so the view opens the session in tutorial
## mode instead of a normal one.
func on_play_pressed() -> bool:
	if not is_active() or TutorialRun.step != Enums.TutorialStep.PLAY:
		return false
	TutorialRun.step = Enums.TutorialStep.SESSION
	step_changed.emit(TutorialRun.step)
	return true


## UC-01.10: the guided session ended (also when the player left it early,
## UC-01.8.a1). `elo_delta` is the total change the session produced.
func resume_after_session(elo_delta: float) -> void:
	if not is_active() or TutorialRun.step != Enums.TutorialStep.SESSION:
		return
	TutorialRun.elo_delta = elo_delta
	TutorialRun.step = Enums.TutorialStep.FINAL
	step_changed.emit(TutorialRun.step)


## UC-01.11 / UC-01.12: marks the tutorial as completed and stores it through
## B7. On failure B1 is rolled back and the run stays at FINAL so the player can
## retry (UC-01.11.e1); the tutorial will also be shown again next launch.
func complete() -> bool:
	if not is_active() or TutorialRun.step != Enums.TutorialStep.FINAL:
		return false
	DepartmentManager.complete_tutorial()
	if PersistenceService.save_player_progress(DepartmentManager.get_player_progress()):
		TutorialRun.step = Enums.TutorialStep.DONE
		TutorialRun.active = false
		step_changed.emit(TutorialRun.step)
		tutorial_finished.emit()
		return true
	DepartmentManager.set_tutorial_completed(false)
	save_failed.emit(PersistenceService.get_last_error())
	return false


func get_elo_delta() -> float:
	return TutorialRun.elo_delta
