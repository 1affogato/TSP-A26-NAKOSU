extends SceneTree
## Self-check of the UC-12 "level up" rules that can break silently: the level
## range, the ELO thresholds, the daily gate, the three outcomes of a level-up
## session and the scripted pool behind it.
## It never saves: every change lives in memory until the process quits, and the
## level-up is resolved through DepartmentManager because the orchestrator writes
## to `user://save/` when it resolves (see `_check_orchestrator`).
## Run from softlearning/:  godot --headless --path . -s res://tests/uc12_check.gd

var _failures := 0


func _initialize() -> void:
	await process_frame # the autoloads run their _ready() on the first frame
	var manager := root.get_node("DepartmentManager")

	_check_level_range()
	_check_player_progress(manager)
	_check_thresholds(manager)
	_check_can_level_up(manager)
	_check_daily_gate(manager)
	_check_level_up_progress(manager)
	_check_company_levels(manager)
	_check_resolve_success(manager)
	_check_resolve_failures(manager)
	_check_resolve_interrupted(manager)
	_check_rollback(manager)
	_check_difficulty_for_level()
	_check_pool()
	_check_orchestrator(manager)

	print("uc12_check: ", "OK" if _failures == 0 else "%d FAILED" % _failures)
	quit(_failures)


## UC-12.1 / UC-12.2.a1: five levels, and a hand-edited save stays inside them.
func _check_level_range() -> void:
	var state := DepartmentState.create(Enums.Department.CODING)
	_check(
		DepartmentState.STARTING_LEVEL == 0
			and DepartmentState.MAX_LEVEL == 4
			and state.level == 0
			and not state.is_at_max_level(),
		"there are five levels, 0 to 4, and a new department starts at 0"
	)
	state.level = 7
	state.elo = -40.0
	state.sanitize()
	var high_ok := state.level == DepartmentState.MAX_LEVEL \
		and state.is_at_max_level() and state.elo == 0.0
	state.level = -3
	state.elo = 1200.0
	state.sanitize()
	_check(high_ok and state.level == 0 and state.elo == 1200.0,
		"sanitize() clamps the level into 0..4 and a negative ELO to 0")


## UC-12.2.a2 / UC-12.8: the daily level-up mark is a calendar day, not a flag.
func _check_player_progress(manager) -> void:
	var progress: PlayerProgress = manager.get_player_progress()
	var today := PlayerProgress.today()
	progress.last_level_up_date = ""
	_check(
		today.length() == 10
			and today.count("-") == 2
			and not progress.is_level_up_used_today(),
		"today() is a YYYY-MM-DD day and an empty mark means no level-up used"
	)
	progress.mark_level_up_used()
	_check(progress.last_level_up_date == today and progress.is_level_up_used_today(),
		"marking the level-up of today blocks it")
	progress.last_level_up_date = "2000-01-01"
	var other_day := not progress.is_level_up_used_today() \
		and progress.is_level_up_used_today("2000-01-01")
	progress.mark_level_up_used("2000-01-01")
	_check(other_day and progress.last_level_up_date == "2000-01-01",
		"the mark only counts for its own day, and an explicit day is honoured")


## UC-12 "ELO level-up thresholds": 1100, 1600, 2100 and 2600, nothing above.
func _check_thresholds(manager) -> void:
	var expected := [1100.0, 1600.0, 2100.0, 2600.0]
	var table: Array = manager.LEVEL_UP_THRESHOLDS
	var table_ok := table.size() == expected.size()
	for level in mini(table.size(), expected.size()):
		table_ok = table_ok and is_equal_approx(table[level], expected[level])
	var lookup_ok := true
	for level in expected.size():
		lookup_ok = lookup_ok and is_equal_approx(
			manager.get_level_up_threshold(level), expected[level]
		)
	_check(
		table_ok
			and lookup_ok
			and manager.get_level_up_threshold(4) == INF
			and manager.get_level_up_threshold(-1) == INF
			and manager.get_level_up_threshold(5) == INF,
		"the thresholds are 1100 / 1600 / 2100 / 2600 per level and INF beyond the last"
	)
	_check(
		manager.MAX_LEVEL_UP_FAILURES == 1 and manager.get_failed_level_up_penalty() == 25.0,
		"one miss is allowed and a failed level-up costs 25 ELO"
	)


## UC-12.1 / UC-12.2.a1: the threshold of the current level, and never at 4.
func _check_can_level_up(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 0, 1099.0)
	var below_low: bool = manager.can_level_up(department)
	_reset(manager, department, 0, 1100.0)
	_check(not below_low and manager.can_level_up(department),
		"level 0 levels up at 1100 ELO, not below")
	_reset(manager, department, 2, 2099.0)
	var below_high: bool = manager.can_level_up(department)
	_reset(manager, department, 2, 2100.0)
	_check(not below_high and manager.can_level_up(department), "level 2 levels up at 2100 ELO")
	_reset(manager, department, DepartmentState.MAX_LEVEL, 9999.0)
	_check(not manager.can_level_up(department), "the last level never levels up, whatever the ELO")


## UC-12.2.a2: the daily limit is global and only hides an option that is met.
func _check_daily_gate(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 1, 1600.0)
	var open: bool = manager.is_level_up_available(department)
	manager.get_player_progress().last_level_up_date = PlayerProgress.today()
	_check(
		open
			and not manager.is_level_up_available(department)
			and manager.can_level_up(department),
		"a level-up already done today hides an option that is otherwise met"
	)
	manager.get_player_progress().last_level_up_date = "2000-01-01"
	_check(manager.is_level_up_available(department), "another day's level-up does not block today")


## UC-12 "progress bar": measured from the previous threshold, never from 0.
func _check_level_up_progress(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 0, DepartmentState.STARTING_ELO)
	var start: float = manager.get_level_up_progress(department)
	_reset(manager, department, 0, 1100.0)
	var full: float = manager.get_level_up_progress(department)
	_reset(manager, department, DepartmentState.MAX_LEVEL, 1000.0)
	_check(
		is_zero_approx(start)
			and is_equal_approx(full, 1.0)
			and is_equal_approx(manager.get_level_up_progress(department), 1.0),
		"level 0 fills from 0 at 1000 ELO to full at 1100, and the last level is always full"
	)
	_reset(manager, department, 1, 1100.0)
	var floor_1: float = manager.get_level_up_progress(department)
	_reset(manager, department, 1, 1350.0)
	_check(
		is_zero_approx(floor_1)
			and is_equal_approx(manager.get_level_up_progress(department), 0.5),
		"level 1 measures from 1100 and is half full halfway to 1600"
	)


## UC-12.7: company level 0..16, one general level per four of company.
func _check_company_levels(manager) -> void:
	var departments: Array = Enums.all_departments()
	for department in departments:
		_reset(manager, department, 0, DepartmentState.STARTING_ELO)
	_check(manager.get_company_level() == 0 and manager.get_general_level() == 0,
		"four fresh departments are company level 0 / general level 0")
	for department in departments:
		_reset(manager, department, 1, DepartmentState.STARTING_ELO)
	var company_one_each: bool = manager.get_company_level() == 4 \
		and manager.get_general_level() == 1
	for department in departments:
		_reset(manager, department, DepartmentState.MAX_LEVEL, DepartmentState.STARTING_ELO)
	_check(
		company_one_each
			and manager.get_company_level() == 16
			and manager.get_general_level() == DepartmentState.MAX_LEVEL,
		"company level sums the four departments and general level is company / 4"
	)


## UC-12.5 / UC-12.6 / UC-12.8: passing raises the level and spends the day.
func _check_resolve_success(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 1, 1600.0)
	var outcome: int = manager.resolve_level_up(department, _results(department, 5, 1), true)
	_check(int(outcome) == int(Enums.LevelUpOutcome.SUCCESS),
		"a session with one miss raises the level")
	_check(
		manager.get_state(department).level == 2
			and is_equal_approx(manager.get_elo(department), 1600.0)
			and manager.get_player_progress().last_level_up_date == PlayerProgress.today(),
		"a successful level-up adds one level, leaves the ELO alone and marks today"
	)
	var again: int = manager.resolve_level_up(department, _results(department, 5, 1), true)
	_check(
		int(again) == int(Enums.LevelUpOutcome.UNAVAILABLE)
			and manager.get_state(department).level == 2,
		"a second level-up on the same day is unavailable"
	)


## UC-12.5.a1: two misses cost 25 ELO, keep the level and do not spend the day.
## The ELO starts above the threshold (2200 > 2100) so the 25 lost still leave
## the option within reach: at exactly the threshold the penalty would drop the
## department below it, which is the ELO rule, not the daily one, and it is not
## what this check is about.
func _check_resolve_failures(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 2, 2200.0)
	var outcome: int = manager.resolve_level_up(department, _results(department, 5, 2), true)
	_check(
		int(outcome) == int(Enums.LevelUpOutcome.FAILED)
			and manager.get_state(department).level == 2
			and is_equal_approx(manager.get_elo(department), 2175.0),
		"two misses fail the level-up: the level stays and the ELO drops 25"
	)
	_check(
		manager.get_player_progress().last_level_up_date.is_empty()
			and manager.is_level_up_available(department),
		"a failed level-up can be retried the same day"
	)


## UC-12.5.a2: leaving the session early counts as an interrupted, failed one.
func _check_resolve_interrupted(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 1, 1600.0)
	var no_results: Array[MinigameResult] = []
	var outcome: int = manager.resolve_level_up(department, no_results, false)
	_check(
		int(outcome) == int(Enums.LevelUpOutcome.FAILED)
			and manager.get_state(department).level == 1
			and is_equal_approx(manager.get_elo(department), 1575.0)
			and manager.get_player_progress().last_level_up_date.is_empty(),
		"an interrupted session fails: no level, 25 ELO lost and the day not spent"
	)


## UC-12.9.e1: a save that fails must leave nothing changed behind.
func _check_rollback(manager) -> void:
	var department := Enums.Department.CODING
	_reset(manager, department, 1, 1600.0)
	var snapshot: LevelUpSnapshot = manager.snapshot(department)
	manager.get_state(department).level = 2
	manager.get_state(department).elo = 1234.0
	manager.get_player_progress().mark_level_up_used()
	manager.rollback(snapshot)
	_check(
		manager.get_state(department).level == 1
			and is_equal_approx(manager.get_elo(department), 1600.0)
			and manager.get_player_progress().last_level_up_date.is_empty(),
		"rollback() restores the level, the ELO and the daily mark"
	)


## UC-12.4: the target level picks the difficulty, clamped outside 1..4.
func _check_difficulty_for_level() -> void:
	var expected := [
		Enums.Difficulty.FACIL,
		Enums.Difficulty.MEDIO,
		Enums.Difficulty.DIFICIL,
		Enums.Difficulty.MUY_DIFICIL,
	]
	var ordered := true
	for level in expected.size():
		ordered = ordered and Enums.difficulty_for_level(level + 1) == expected[level]
	_check(
		ordered
			and Enums.difficulty_for_level(0) == Enums.Difficulty.FACIL
			and Enums.difficulty_for_level(5) == Enums.Difficulty.MUY_DIFICIL,
		"levels 1..4 play at easy, medium, hard and very hard, clamped outside"
	)


## UC-12.4 / UC-12.4.e1: every department x target level is authored, nothing else.
func _check_pool() -> void:
	var pool: LevelUpPool = load("res://resources/level_up_pool.tres")
	var keys := ["QUIZ", "SWIPE", "NARRATIVE", "TRAIN", "BOMB", "PUZZLE"]
	var authored := 0
	var well_formed := true
	for department in Enums.all_departments():
		for target_level in range(1, DepartmentState.MAX_LEVEL + 1):
			var session: LevelUpSession = pool.get_session(department, target_level)
			if session == null:
				well_formed = false
				continue
			authored += 1
			well_formed = well_formed \
				and session.sequence.size() == 5 \
				and session.department == department \
				and session.target_level == target_level
			for key in session.sequence:
				if key not in keys:
					well_formed = false
	_check(
		authored == 16 and pool.sessions.size() == 16 and well_formed,
		"the pool holds 16 sessions, one per department and target level, of five known engines"
	)
	_check(
		pool.get_session(Enums.Department.CODING, 0) == null
			and pool.get_session(Enums.Department.CODING, 5) == null,
		"there is no session for level 0 or above the last level"
	)


## UC-12.3 / UC-12.4 / UC-12.5: the scripted start, its fixed order and the fact
## that a level-up result never moves the ELO nor the statistics.
## The resolve is not exercised here on purpose: `next()` at the end of the
## sequence and `exit()` both save to `user://save/`, so `level_up_ended` cannot
## be watched without writing a save file. `resolve_level_up()` above is what the
## orchestrator calls, and it is covered on its own.
func _check_orchestrator(manager) -> void:
	var department := Enums.Department.CODING
	var pool: LevelUpPool = load("res://resources/level_up_pool.tres")
	# Loaded at runtime for the same reason as the other tests, and the enum is
	# read from the script instead of naming `SessionOrchestrator`: a -s script
	# compiles before the autoloads exist, so it must not depend on a script that
	# refers to DepartmentManager.
	var script: GDScript = load("res://core/session_orchestrator.gd")
	var level_up_mode: int = script.get_script_constant_map()["SessionMode"]["LEVEL_UP"]

	# UC-12.2.a2: an option that is not available does not start, and says why.
	_reset(manager, department, 0, 1100.0)
	manager.get_player_progress().last_level_up_date = PlayerProgress.today()
	var blocked: Node = script.new()
	root.add_child(blocked)
	var reasons: Array[String] = []
	blocked.level_up_unavailable.connect(reasons.append)
	_check(
		not blocked.start_level_up_session(department)
			and reasons.size() == 1
			and blocked.current_minigame == null
			and manager.get_state(department).level == 0,
		"a level-up already used today does not start, reports why and changes nothing"
	)
	blocked.free()

	# UC-12.4: the scripted session starts at its target level, in authored order.
	_reset(manager, department, 0, 1200.0)
	var orchestrator: Node = script.new()
	root.add_child(orchestrator)
	_check(orchestrator.start_level_up_session(department),
		"the level-up starts when it is available")
	_check(
		orchestrator.mode == level_up_mode
			and orchestrator.level_up_target_level == 1
			and orchestrator.current_index == 0
			and orchestrator.current_minigame != null,
		"the level-up starts at the target level with its first minigame running"
	)
	_check(orchestrator.sequence == pool.get_session(department, 1).sequence,
		"the level-up plays the authored sequence, never a shuffled one")

	# UC-12.5: a level-up result is only collected; B1 counts the misses at the end.
	var statistics := root.get_node("StatisticsTracker")
	var elo_before: float = manager.get_elo(department)
	var history_before: int = statistics.get_history().size()
	var quiz := orchestrator.current_minigame as QuizMinigame
	quiz.answer(quiz.question.get_correct_response())
	_check(
		is_equal_approx(manager.get_elo(department), elo_before)
			and statistics.get_history().size() == history_before
			and orchestrator.results.size() == 1
			and orchestrator.current_index == 1,
		"a level-up result is collected without moving the ELO nor the statistics"
	)
	orchestrator.next()
	_check(
		orchestrator.current_minigame != null
			and manager.get_state(department).level == 0
			and orchestrator.mode == level_up_mode,
		"next() launches the following minigame without resolving the level-up"
	)
	orchestrator.free()


## Puts one department back to a known level and ELO, with no level-up used today.
func _reset(manager, department: Enums.Department, level: int, elo: float) -> void:
	var state := DepartmentState.create(department)
	state.level = level
	state.elo = elo
	manager.states[department] = state
	manager.get_player_progress().last_level_up_date = ""


## A session's results: `count` results of which the last `misses` are wrong.
func _results(
	department: Enums.Department, count: int, misses: int
) -> Array[MinigameResult]:
	var results: Array[MinigameResult] = []
	for index in count:
		results.append(MinigameResult.create(
			QuizMinigame.TYPE, index < count - misses, Enums.Difficulty.FACIL, department
		))
	return results


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAILED: ", what)
