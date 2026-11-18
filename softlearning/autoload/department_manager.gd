extends Node
## DepartmentManager (B1) — autoload singleton.
##
## Owns the four departments: their [DepartmentState] (level + ELO), their name,
## the ELO threshold that allows a level-up, and the specific minigames enabled
## for each one. It is the only block that decides how a result moves the ELO;
## B4 (the session orchestrator) just reports the results. UC-12 changes levels
## here too: it decides whether a level-up is available and resolves it.
##
## The states come from the persistence service (B7) when the game starts and go
## back to it through [SaveData] when a session ends (UC-02.8). The thresholds
## and minigame lists are authored data: they are never persisted (UC-11).

## Largest ELO change a single result can cause (UC-02.6).
const K_FACTOR := 32.0

## DATOS DE AUTORÍA — nombre visible de cada departamento (bloque 1: "identificador
## y nombre de cada departamento"). Los pisos del edificio usan los mismos.
var department_names: Dictionary[Enums.Department, String] = {
	Enums.Department.DATA_STRUCTURES: "Estructuras de datos",
	Enums.Department.REQUIREMENTS: "Requerimientos",
	Enums.Department.SOFTWARE_DEV: "Desarrollo de Software",
	Enums.Department.CODING: "Programación",
}

## DATOS DE AUTORÍA — ajústalos aquí; no se guardan en la partida.
## Minijuegos ESPECÍFICOS de cada departamento. Los genéricos no van aquí: los
## añade el orquestador (B4) al armar la secuencia (UC-02.2). Quiz, Swipe! y
## Narrativa son genéricos (sus pools cubren los cuatro departamentos). Cada
## valor es la clave TYPE del motor: "BOMB" = BombMinigame (UC-04),
## "TRAIN" = TrainMinigame (UC-03), "PUZZLE" = PuzzleMinigame (UC-05).
var enabled_minigames: Dictionary[Enums.Department, Array] = {
	Enums.Department.DATA_STRUCTURES: [],
	Enums.Department.REQUIREMENTS: ["BOMB"],
	Enums.Department.SOFTWARE_DEV: ["TRAIN"],
	Enums.Department.CODING: ["PUZZLE"],
}

## DATOS DE AUTORÍA — ELO necesario para pasar del nivel `i` al `i + 1`
## (UC-12, "ELO level-up thresholds"). El índice es el nivel actual: el nivel 0
## pide 1100, el 1 pide 1600, el 2 pide 2100 y el 3 pide 2600. No se guardan.
const LEVEL_UP_THRESHOLDS: Array[float] = [1100.0, 1600.0, 2100.0, 2600.0]
## UC-12.5: failing more minigames than this fails the level-up session.
const MAX_LEVEL_UP_FAILURES := 1
## UC-12.5.a1: ELO the department loses when its level-up session fails.
const FAILED_LEVEL_UP_PENALTY := 25.0

var states: Dictionary[Enums.Department, DepartmentState] = {}
## Flags that are not tied to one department: the tutorial (UC-01) and the
## daily level-up mark (UC-12).
var player_progress: PlayerProgress


func _ready() -> void:
	states.clear()
	for state in PersistenceService.load_department_states():
		states[state.department] = state
	player_progress = PersistenceService.load_player_progress()


# -------------------------------------------------------------------- read

## Level and ELO of one department. Always returns a usable state: B7
## guarantees one per department, and this falls back to a base one if the
## dictionary is ever missing it.
func get_state(department: Enums.Department) -> DepartmentState:
	var state: DepartmentState = states.get(department)
	if state == null:
		state = DepartmentState.create(department)
		states[department] = state
	return state


func get_elo(department: Enums.Department) -> float:
	return get_state(department).elo


## Bloque 1: el nombre visible del departamento. Si no hay ninguno autorado cae
## a la clave del enum, para que la vista nunca muestre un texto vacío.
func get_department_name(department: Enums.Department) -> String:
	return department_names.get(department, Enums.department_to_key(department))


## Bloque 1 / UC-02.2: the department's specific minigames. Returns a copy, so
## whoever builds the sequence cannot alter the authored data.
func get_enabled_minigames(department: Enums.Department) -> Array[String]:
	var enabled: Array[String] = []
	for minigame_type in enabled_minigames.get(department, []):
		enabled.append(String(minigame_type))
	return enabled


## UC-11.3.a1 / UC-12.1: whether the department's ELO reached the threshold of
## its next level. False at level 4, which has no level above (UC-12.2.a1).
func can_level_up(department: Enums.Department) -> bool:
	var state := get_state(department)
	if state.is_at_max_level():
		return false
	return state.elo >= get_level_up_threshold(state.level)


## ELO needed to leave `level`. INF means there is no next level.
func get_level_up_threshold(level: int) -> float:
	if level < 0 or level >= LEVEL_UP_THRESHOLDS.size():
		return INF
	return LEVEL_UP_THRESHOLDS[level]


## UC-12.5.a1: the ELO the department loses when a level-up session fails. The
## view shows it in the result message.
func get_failed_level_up_penalty() -> float:
	return FAILED_LEVEL_UP_PENALTY


## UC-12.2: the "Subir nivel" option is offered only when the threshold is met
## and no level-up was completed today, by any department (UC-12.2.a2).
func is_level_up_available(department: Enums.Department) -> bool:
	return can_level_up(department) and not get_player_progress().is_level_up_used_today()


## UC-12.7: the company level is just the sum of every department's level, from
## 0 to 4 × 4 = 16.
func get_company_level() -> int:
	var total := 0
	for department in Enums.all_departments():
		total += get_state(department).level
	return total


## General (company-wide) level that picks the office sprite: it goes up one
## step per department level gained, so every +4 of company level is one
## general level, from 0 to 4.
func get_general_level() -> int:
	var departments := Enums.all_departments().size()
	return clampi(floori(float(get_company_level()) / float(departments)),
		0, DepartmentState.MAX_LEVEL)


## Progress from this level's threshold to the next one, from 0.0 to 1.0. 1.0
## means the department already meets the condition or is at the last level. It
## is what the building's floor bars show. Measured from the previous threshold
## and not from 0, so a department that just leveled up starts at 0 % and every
## point won shows (the bar used to start at 67 % and barely move).
func get_level_up_progress(department: Enums.Department) -> float:
	var state := get_state(department)
	if state.is_at_max_level():
		return 1.0
	var threshold := get_level_up_threshold(state.level)
	var floor_elo := DepartmentState.STARTING_ELO
	if state.level > 0:
		floor_elo = get_level_up_threshold(state.level - 1)
	var span := threshold - floor_elo
	if not is_finite(span) or span <= 0.0:
		return 0.0
	return clampf((state.elo - floor_elo) / span, 0.0, 1.0)


## UC-02.8: the orchestrator packs these into a [SaveData].
func get_all_states() -> Array[DepartmentState]:
	var all: Array[DepartmentState] = []
	for department in Enums.all_departments():
		all.append(get_state(department))
	return all


## UC-01: the progress stored outside any one department.
func get_player_progress() -> PlayerProgress:
	if player_progress == null:
		player_progress = PlayerProgress.create()
	return player_progress


## UC-01.2: whether the first-run tutorial was already completed.
func is_tutorial_completed() -> bool:
	return get_player_progress().tutorial_completed


## UC-01.11: marks the tutorial as completed in memory. B4 stores it afterwards
## through `PersistenceService.save_player_progress()`.
func complete_tutorial() -> void:
	set_tutorial_completed(true)


## UC-01.11.e1: lets B4 roll the flag back when the save fails.
func set_tutorial_completed(completed: bool) -> void:
	get_player_progress().tutorial_completed = completed


## UC-11 "evolución en el tiempo": the ELO before the first of `records` and
## after each one, oldest first, replaying the same rule update_elo() applies.
## B6 hands it the records of one department.
# ponytail: assumes the ELO only moves through results; UC-12's failed
# level-up penalty (-25) is therefore missing from the curve. Fixing that means
# storing the ELO in each ResultRecord (a new field in an append-only log).
func get_elo_curve(records: Array[ResultRecord]) -> PackedFloat32Array:
	var elo := DepartmentState.STARTING_ELO
	var curve := PackedFloat32Array([elo])
	for record in records:
		var delta := _compute_elo_delta(elo, record.level, record.success)
		elo = maxf(0.0, elo + delta * record.multiplier)
		curve.append(elo)
	return curve


# ------------------------------------------------------------------- write

## UC-02.6: applies the ELO adjustment of one finished minigame. UC-01.9 passes
## the placement multiplier (10, 9, … 1) while the tutorial is running; every
## other session uses the default 1.0.
func update_elo(result: MinigameResult, multiplier: float = 1.0) -> void:
	var state := get_state(result.department)
	var delta := _compute_elo_delta(state.elo, result.level, result.success)
	state.elo = maxf(0.0, state.elo + delta * maxf(0.0, multiplier))


# ------------------------------------------------------------------- UC-12

## UC-12.9.e1: everything a level-up session can change, so B4 can undo it when
## the new state cannot be saved.
func snapshot(department: Enums.Department) -> LevelUpSnapshot:
	var state := get_state(department)
	return LevelUpSnapshot.create(
		department,
		state.level,
		state.elo,
		get_player_progress().last_level_up_date
	)


## UC-12.9.e1: puts back the department and the daily mark as they were.
func rollback(snapshot: LevelUpSnapshot) -> void:
	var state := get_state(snapshot.department)
	state.level = snapshot.level
	state.elo = snapshot.elo
	get_player_progress().last_level_up_date = snapshot.last_level_up_date


## UC-12.5 / UC-12.5.a1 / UC-12.5.a2: resolves one level-up session. Passing it
## (`completed` and at most `MAX_LEVEL_UP_FAILURES` failures) raises the level by
## one and marks the daily level-up as used (UC-12.6 / UC-12.8); anything else —
## too many failures or an interrupted session — costs
## `FAILED_LEVEL_UP_PENALTY` ELO and keeps the level. The daily mark is only
## spent by a successful level-up, so a failed attempt can be retried the same
## day (UC-12.5.a1).
func resolve_level_up(
	department: Enums.Department,
	results: Array[MinigameResult],
	completed: bool
) -> Enums.LevelUpOutcome:
	if not is_level_up_available(department):
		return Enums.LevelUpOutcome.UNAVAILABLE

	var failures := 0
	for result in results:
		if result != null and not result.success:
			failures += 1

	if completed and failures <= MAX_LEVEL_UP_FAILURES:
		var state := get_state(department)
		state.level = mini(state.level + 1, DepartmentState.MAX_LEVEL)
		get_player_progress().mark_level_up_used()
		return Enums.LevelUpOutcome.SUCCESS

	var failed_state := get_state(department)
	failed_state.elo = maxf(0.0, failed_state.elo - FAILED_LEVEL_UP_PENALTY)
	return Enums.LevelUpOutcome.FAILED


# ---------------------------------------------------------------- internals

## Standard Elo with the item as the opponent, rated by its difficulty on the
## pool's ELO anchors (`Enums.difficulty_to_elo`): a hit on a hard item adds
## more, and a miss on a hard item subtracts less, than the same result on an
## easy one.
func _compute_elo_delta(elo: float, level: Enums.Difficulty, success: bool) -> float:
	var gap := Enums.difficulty_to_elo(level) - elo
	var expected := 1.0 / (1.0 + pow(10.0, gap / 400.0))
	return K_FACTOR * ((1.0 if success else 0.0) - expected)
