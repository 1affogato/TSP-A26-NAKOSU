extends SceneTree
## Self-check of the UC-01 rules that can break silently: placement weights,
## the persisted multiplier, the tutorial step machine and the ELO curve.
## It never saves: every change lives in memory until the process quits.
## Run from softlearning/:  godot --headless --path . -s res://tests/uc01_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame
	var manager := root.get_node("DepartmentManager")
	var original_elo: float = manager.get_elo(Enums.Department.CODING)
	var original_completed: bool = manager.is_tutorial_completed()

	_check_placement_weights()
	_check_session_delta(manager)
	_check_elo_multiplier(manager)
	_check_record_multiplier_round_trip()
	_check_elo_curve_multiplier(manager)
	_check_tutorial_steps(manager)
	_check_tutorial_completion_flag(manager)
	await _check_department_view_integration(manager)

	manager.get_state(Enums.Department.CODING).elo = original_elo
	manager.set_tutorial_completed(original_completed)
	TutorialRun.reset()

	print("uc01_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## UC-01.9: 10, 9, 8 … and never below 1.
func _check_placement_weights() -> void:
	# Loaded at runtime: a -s script compiles before the autoloads exist, and
	# the orchestrator script refers to DepartmentManager.
	var orchestrator: Node = load("res://core/session_orchestrator.gd").new()
	var expected := [10.0, 9.0, 8.0, 7.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.0, 1.0]
	for index in expected.size():
		var weight: float = orchestrator.placement_weight(index)
		_check(
			is_equal_approx(weight, expected[index]),
			"placement weight %d is %s" % [index, expected[index]]
		)
	orchestrator.free()


## UC-01.10: the guided session reports its net ELO change through
## `session_ended(department, elo_delta)` so the final message can show it.
func _check_session_delta(manager) -> void:
	# Loaded at runtime for the same reason as the orchestrator above.
	var orchestrator: Node = load("res://core/session_orchestrator.gd").new()
	var department := Enums.Department.CODING
	var before: float = manager.get_elo(department)
	orchestrator.department = department
	orchestrator.elo_at_session_start = before

	var emitted: Array = []
	orchestrator.session_ended.connect(
		func(ended_department, elo_delta): emitted.append([ended_department, elo_delta])
	)

	var state: DepartmentState = manager.get_state(department)
	state.elo = before + 37.5
	orchestrator._end_session()

	_check(emitted.size() == 1, "the session emits session_ended once")
	if emitted.size() == 1:
		_check(
			int(emitted[0][0]) == int(department),
			"session_ended reports the department it belongs to"
		)
		var delta: float = emitted[0][1]
		_check(
			absf(delta - 37.5) < 0.01,
			"session_ended reports the net ELO change of the session"
		)
	orchestrator.free()


## UC-01.9: B1 multiplies the normal ELO delta by the placement weight.
func _check_elo_multiplier(manager) -> void:
	var department := Enums.Department.CODING
	var state: DepartmentState = manager.get_state(department)
	state.elo = 1200.0
	manager.update_elo(MinigameResult.create(QuizMinigame.TYPE, true, Enums.Difficulty.FACIL, department))
	var normal_delta: float = state.elo - 1200.0
	state.elo = 1200.0
	manager.update_elo(
		MinigameResult.create(QuizMinigame.TYPE, true, Enums.Difficulty.FACIL, department),
		10.0
	)
	var amplified_delta: float = state.elo - 1200.0
	_check(normal_delta > 0.0, "a hit on an easy item adds ELO")
	_check(
		absf(amplified_delta - normal_delta * 10.0) < 0.01,
		"the placement weight multiplies the ELO delta by 10"
	)


## The multiplier must survive the JSON round-trip, and old lines default to 1.
func _check_record_multiplier_round_trip() -> void:
	var record := ResultRecord.create(
		QuizMinigame.TYPE,
		Enums.Department.CODING,
		Enums.Difficulty.MEDIO,
		true,
		123456,
		7.5
	)
	var restored: ResultRecord = ResultRecord.from_dict(record.to_dict())
	_check(restored != null, "a record can be rebuilt from its dict")
	_check(is_equal_approx(restored.multiplier, 7.5), "the multiplier survives the JSON round-trip")

	var old_format: ResultRecord = ResultRecord.from_dict({
		"department": "CODING",
		"type": QuizMinigame.TYPE,
		"level": "FACIL",
		"success": true,
		"timestamp": 1,
	})
	_check(is_equal_approx(old_format.multiplier, 1.0), "old records default multiplier to 1")


## The "Tu histórico" chart must reproduce the amplified tutorial results.
func _check_elo_curve_multiplier(manager) -> void:
	var normal: Array[ResultRecord] = [ResultRecord.create(
		QuizMinigame.TYPE, Enums.Department.CODING, Enums.Difficulty.FACIL, true, 1, 1.0
	)]
	var guided: Array[ResultRecord] = [ResultRecord.create(
		QuizMinigame.TYPE, Enums.Department.CODING, Enums.Difficulty.FACIL, true, 2, 10.0
	)]
	var normal_curve: PackedFloat32Array = manager.get_elo_curve(normal)
	var guided_curve: PackedFloat32Array = manager.get_elo_curve(guided)
	var start := DepartmentState.STARTING_ELO
	_check(normal_curve.size() == 2 and guided_curve.size() == 2, "the curve has one point per result")
	_check(
		absf((guided_curve[1] - start) - (normal_curve[1] - start) * 10.0) < 0.01,
		"the curve applies each record's multiplier"
	)


## DEPARTMENTS -> ELO -> PLAY -> SESSION -> FINAL, with the carried state.
func _check_tutorial_steps(manager) -> void:
	manager.set_tutorial_completed(false)
	TutorialRun.reset()
	# Loaded at runtime for the same reason as the orchestrator above.
	var controller: Node = load("res://core/tutorial_controller.gd").new()
	_check(controller.start_if_pending(), "the tutorial starts when it is pending")
	_check_equal_step(controller.step, Enums.TutorialStep.DEPARTMENTS, "starts at DEPARTMENTS")

	controller.on_department_selected(Enums.Department.REQUIREMENTS)
	_check_equal_step(controller.step, Enums.TutorialStep.ELO, "advances to ELO")
	_check(TutorialRun.department == Enums.Department.REQUIREMENTS, "remembers the chosen department")

	controller.on_elo_step_confirmed()
	_check_equal_step(controller.step, Enums.TutorialStep.PLAY, "advances to PLAY")

	_check(controller.on_play_pressed(), "the PLAY press belongs to the tutorial")
	_check_equal_step(controller.step, Enums.TutorialStep.SESSION, "advances to SESSION")

	controller.resume_after_session(42.5)
	_check_equal_step(controller.step, Enums.TutorialStep.FINAL, "advances to FINAL")
	_check(is_equal_approx(controller.get_elo_delta(), 42.5), "carries the session ELO delta")
	controller.free()


## UC-01.11: B1 can mark and roll back the completion flag in memory.
func _check_tutorial_completion_flag(manager) -> void:
	manager.complete_tutorial()
	_check(manager.is_tutorial_completed(), "complete_tutorial() marks the flag")
	manager.set_tutorial_completed(false)
	_check(not manager.is_tutorial_completed(), "set_tutorial_completed(false) rolls it back")


## Real DepartmentView + overlay wiring, without opening the session scene.
func _check_department_view_integration(manager) -> void:
	manager.set_tutorial_completed(false)
	TutorialRun.reset()
	var view: Control = load("res://scenes/department_view.tscn").instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	await process_frame

	var overlay: Control = view.get_node("TutorialOverlay")
	var controller: Node = view.get_node("TutorialController")
	_check(overlay.visible, "the overlay appears on the first step")
	_check(overlay.size.x > 0.0 and overlay.size.y > 0.0, "the overlay fills the viewport")
	_check_equal_step(controller.step, Enums.TutorialStep.DEPARTMENTS, "the view starts at DEPARTMENTS")
	_check_callout_fits(overlay, view, "the first message")

	view.select_department(Enums.Department.CODING)
	await process_frame
	await process_frame
	await process_frame
	_check_equal_step(controller.step, Enums.TutorialStep.ELO, "choosing a department opens ELO")
	_check(view.get_node("DetailScreen/Layout/BottomRow/StatsPanel/Content/ChartCard").visible,
		"the ELO step shows the history chart")

	view._on_tutorial_screen_clicked()
	await process_frame
	await process_frame
	await process_frame
	_check_equal_step(controller.step, Enums.TutorialStep.PLAY, "clicking the chart opens PLAY")

	controller.on_play_pressed()
	_check_equal_step(controller.step, Enums.TutorialStep.SESSION, "the play press opens SESSION")
	_check(not overlay.visible, "the overlay hides during the session")

	view.resume_after_session(Enums.Department.CODING, 42.0)
	await process_frame
	await process_frame
	await process_frame
	_check_equal_step(controller.step, Enums.TutorialStep.FINAL, "the session return opens FINAL")
	_check(overlay.visible, "the final message is visible")
	var title: Label = overlay.get_node("Callout/Content/Title")
	_check(title.text.contains("NAKOSU"), "the final message welcomes the player")
	_check_callout_fits(overlay, view, "the final message")

	view.queue_free()
	await process_frame
	manager.set_tutorial_completed(false)
	TutorialRun.reset()


## Regression: the callout must be measured after its labels are laid out at the
## final width. Otherwise the autowrap reports a one-word-per-line height and the
## panel grows taller than the screen, cutting the text (UC-01 first and final
## messages, which are the first thing each DepartmentView shows).
func _check_callout_fits(overlay: Control, view: Control, what: String) -> void:
	var callout: Control = overlay.get_node("Callout")
	_check(callout.visible, what + ": the callout is visible")
	_check(callout.size.y > 60.0, what + ": the callout has room for its text")
	_check(callout.size.y < view.size.y * 0.8, what + ": the callout fits on screen")
	_check(is_equal_approx(callout.modulate.a, 1.0), what + ": the callout is not left transparent")


func _check_equal_step(actual, expected: Enums.TutorialStep, what: String) -> void:
	_check(int(actual) == int(expected), what)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
