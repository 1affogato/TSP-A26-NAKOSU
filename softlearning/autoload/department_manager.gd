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
## añade el orquestador (B4) al armar la secuencia (UC-02.2). El Quiz es genérico
## (su pool cubre los cuatro departamentos), así que hoy ninguno tiene específicos.
var enabled_minigames: Dictionary[Enums.Department, Array] = {
	Enums.Department.DATA_STRUCTURES: [],
	Enums.Department.REQUIREMENTS: [],
	Enums.Department.SOFTWARE_DEV: [],
	Enums.Department.CODING: [],
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


## UC-11 "evolución en el tiempo": the ELO before the first of `records` and
## after each one, oldest first, replaying the same rule update_elo() applies.
## B6 hands it the records of one department.
# ponytail: assumes the ELO only moves through results; if UC-12 ever touches
# it, store the ELO in each ResultRecord instead of replaying.
func get_elo_curve(records: Array[ResultRecord]) -> PackedFloat32Array:
	var elo := DepartmentState.STARTING_ELO
	var curve := PackedFloat32Array([elo])
	for record in records:
		elo = maxf(0.0, elo + _compute_elo_delta(elo, record.level, record.success))
		curve.append(elo)
	return curve


# ------------------------------------------------------------------- write

## UC-02.6: applies the ELO adjustment of one finished minigame.
func update_elo(result: MinigameResult) -> void:
	var state := get_state(result.department)
	state.elo = maxf(0.0, state.elo + _compute_elo_delta(state.elo, result.level, result.success))


# ---------------------------------------------------------------- internals

## Standard Elo with the item as the opponent, rated by its difficulty on the
## pool's ELO anchors (`Enums.difficulty_to_elo`): a hit on a hard item adds
## more, and a miss on a hard item subtracts less, than the same result on an
## easy one.
func _compute_elo_delta(elo: float, level: Enums.Difficulty, success: bool) -> float:
	var gap := Enums.difficulty_to_elo(level) - elo
	var expected := 1.0 / (1.0 + pow(10.0, gap / 400.0))
	return K_FACTOR * ((1.0 if success else 0.0) - expected)
