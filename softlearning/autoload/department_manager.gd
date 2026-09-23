extends Node
## DepartmentManager (B1) — autoload singleton.
##
## Owns the four departments: their [DepartmentState] (level + ELO), their name,
## the ELO threshold that allows a level-up, and the specific minigames enabled
## for each one. It is the only block that decides how a result moves the ELO;
## B4 (the session orchestrator) just reports the results, and UC-12 changes
## levels.
##
## The states come from the persistence service (B7) when the game starts and go
## back to it through [SaveData] when a session ends (UC-02.8). The thresholds
## and minigame lists are authored data: they are never persisted (UC-11).

## ELO a successful game adds, and a failed game subtracts, before weighting by
## difficulty. Tune these two to change how fast the player climbs.
const ELO_GAIN_BASE := 10.0
const ELO_LOSS_BASE := 10.0

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
## añade el orquestador (B4) al armar la secuencia (UC-02.2).
var enabled_minigames: Dictionary[Enums.Department, Array] = {
	Enums.Department.DATA_STRUCTURES: ["quiz"],
	Enums.Department.REQUIREMENTS: ["quiz"],
	Enums.Department.SOFTWARE_DEV: ["quiz"],
	Enums.Department.CODING: ["quiz"],
}

## DATOS DE AUTORÍA — ELO a partir del cual el departamento puede subir de nivel
## (UC-11.3.a1). El cambio de nivel en sí pertenece a UC-12.
var level_up_thresholds: Dictionary[Enums.Department, float] = {
	Enums.Department.DATA_STRUCTURES: 1500.0,
	Enums.Department.REQUIREMENTS: 1500.0,
	Enums.Department.SOFTWARE_DEV: 1500.0,
	Enums.Department.CODING: 1500.0,
}

var states: Dictionary[Enums.Department, DepartmentState] = {}


func _ready() -> void:
	states.clear()
	for state in PersistenceService.load_department_states():
		states[state.department] = state


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


## UC-11.3.a1: whether the department's ELO reached its authored threshold.
func can_level_up(department: Enums.Department) -> bool:
	var threshold: float = level_up_thresholds.get(department, INF)
	return get_state(department).elo >= threshold


## Progress towards that threshold, from 0.0 to 1.0. 1.0 means the department
## already meets the condition. It is what the building's floor bars show.
func get_level_up_progress(department: Enums.Department) -> float:
	var threshold: float = level_up_thresholds.get(department, INF)
	if not is_finite(threshold) or threshold <= 0.0:
		return 0.0
	return clampf(get_state(department).elo / threshold, 0.0, 1.0)


## UC-02.8: the orchestrator packs these into a [SaveData].
func get_all_states() -> Array[DepartmentState]:
	var all: Array[DepartmentState] = []
	for department in Enums.all_departments():
		all.append(get_state(department))
	return all


# ------------------------------------------------------------------- write

## UC-02.6: applies the ELO adjustment of one finished minigame.
func update_elo(result: MinigameResult) -> void:
	if result == null:
		return
	var state := get_state(result.department)
	state.elo = maxf(0.0, state.elo + _compute_elo_delta(result))


# ---------------------------------------------------------------- internals

## Weighted by difficulty: getting it right on a hard item adds more, getting it
## wrong on a hard item subtracts less.
##
## The weight comes from the pool's ELO anchors (bloque 2): FACIL 1000,
## MEDIO 1500, DIFICIL 2000, MUY_DIFICIL 2500, so it is 1.0 / 1.5 / 2.0 / 2.5.
## With the base of 10 that means +10/-10 on FACIL up to +25/-4 on MUY_DIFICIL.
func _compute_elo_delta(result: MinigameResult) -> float:
	var weight := Enums.difficulty_to_elo(result.level) / Enums.difficulty_to_elo(Enums.Difficulty.FACIL)
	if result.success:
		return ELO_GAIN_BASE * weight
	return -ELO_LOSS_BASE / weight
