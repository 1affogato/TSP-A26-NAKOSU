extends SceneTree
## Self-check of the UC-02 rules that can break silently. It never saves: the
## ELO changes it makes only live in memory until the process quits.
## Run from softlearning/:  godot --headless --path . -s res://tests/uc02_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame
	# UC-02.6: a hit on a hard item adds more, a miss on a hard item subtracts less.
	var hard_hit := _elo_delta(Enums.Difficulty.MUY_DIFICIL, true)
	var easy_hit := _elo_delta(Enums.Difficulty.FACIL, true)
	var hard_miss := _elo_delta(Enums.Difficulty.MUY_DIFICIL, false)
	var easy_miss := _elo_delta(Enums.Difficulty.FACIL, false)
	_check(hard_hit > easy_hit and easy_hit > 0.0, "a hit on a hard item adds more")
	_check(easy_miss < hard_miss and hard_miss < 0.0, "a miss on a hard item subtracts less")

	# UC-02.4.a1 / UC-07.3.a1: no answer while paused; a timeout is a wrong answer.
	var quiz := QuizMinigame.new()
	root.add_child(quiz)
	var results: Array[MinigameResult] = []
	quiz.finished.connect(results.append)
	quiz.start(Enums.Department.CODING, 1000.0)
	quiz.pause()
	quiz.answer(quiz.question.get_correct_response())
	_check(results.is_empty(), "no answer is taken while paused")
	quiz.resume()
	quiz._process(quiz.time_limit)
	_check(results.size() == 1 and not results[0].success, "a timeout counts as wrong")
	quiz.free()

	print("uc02_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## ELO change caused by one result, always from the same starting ELO.
## (A -s script compiles before the autoloads exist, so it looks B1 up by path.)
func _elo_delta(level: Enums.Difficulty, success: bool) -> float:
	var manager := root.get_node("DepartmentManager")
	var department := Enums.Department.CODING
	manager.states[department].elo = 1200.0
	manager.update_elo(MinigameResult.create(QuizMinigame.TYPE, success, level, department))
	return manager.get_elo(department) - 1200.0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
