class_name Enums
extends RefCounted
## The two enumerations every diagram shares (UC-02, UC-07 and UC-11).
##
## They live together in one script so the models can use `Enums.Department`
## and `Enums.Difficulty` as type hints without importing anything.
##
## Save files store enums as their *name* ("SOFTWARE_DEV"), never as a number:
## a number would silently point at the wrong department the day somebody
## inserts a value in the middle of the enum, and names keep the log readable.
## (`DepartmentState` is the exception: as a `.tres` resource it stores the raw
## int, because that is what the resource format does on its own.)
## UC-11 spells the last department `CODING_PARADIG` while UC-02 and UC-07
## spell it `CODING`; both spellings are accepted when reading.

enum Department {
	DATA_STRUCTURES,
	REQUIREMENTS,
	SOFTWARE_DEV,
	CODING,
}

enum Difficulty {
	FACIL,
	MEDIO,
	DIFICIL,
	MUY_DIFICIL,
}

## Cómo se agrupa el desglose detallado de estadísticas (UC-11.4 / UC-11.5).
enum StatType {
	BY_MINIGAME,
	BY_DIFFICULTY,
	OVER_TIME,
}

static func difficulty_to_elo(difficulty: Enums.Difficulty) -> float:
	match difficulty:
		Difficulty.FACIL:
			return 1000
		Difficulty.MEDIO:
			return 1500
		Difficulty.DIFICIL:
			return 2000
		_:
			return 2500

## Every department, in enum order. Used to guarantee that a save file always
## holds exactly one entry per department.
static func all_departments() -> Array:
	return [
		Department.DATA_STRUCTURES,
		Department.REQUIREMENTS,
		Department.SOFTWARE_DEV,
		Department.CODING,
	]


## `Department.SOFTWARE_DEV` -> "SOFTWARE_DEV" (the key used in the JSON).
static func department_to_key(department: Enums.Department) -> String:
	match department:
		Department.REQUIREMENTS:
			return "REQUIREMENTS"
		Department.SOFTWARE_DEV:
			return "SOFTWARE_DEV"
		Department.CODING:
			return "CODING"
		_:
			return "DATA_STRUCTURES"


## "SOFTWARE_DEV" -> `Department.SOFTWARE_DEV`. Unknown keys fall back to
## `DATA_STRUCTURES` with a warning, so one bad field cannot break loading.
static func department_from_key(key: String) -> Enums.Department:
	match key.strip_edges().to_upper():
		"REQUIREMENTS":
			return Department.REQUIREMENTS
		"SOFTWARE_DEV":
			return Department.SOFTWARE_DEV
		"CODING", "CODING_PARADIG", "CODING_PARADIGM":
			return Department.CODING
		"DATA_STRUCTURES":
			return Department.DATA_STRUCTURES
	push_warning("Enums: unknown department '%s', falling back to DATA_STRUCTURES." % key)
	return Department.DATA_STRUCTURES


## `Difficulty.MUY_DIFICIL` -> "MUY_DIFICIL" (the key used in the JSON).
static func difficulty_to_key(difficulty: Enums.Difficulty) -> String:
	match difficulty:
		Difficulty.MEDIO:
			return "MEDIO"
		Difficulty.DIFICIL:
			return "DIFICIL"
		Difficulty.MUY_DIFICIL:
			return "MUY_DIFICIL"
		_:
			return "FACIL"


## "MUY_DIFICIL" -> `Difficulty.MUY_DIFICIL`. Unknown keys fall back to
## `FACIL` with a warning.
static func difficulty_from_key(key: String) -> Enums.Difficulty:
	match key.strip_edges().to_upper():
		"MEDIO", "MEDIUM":
			return Difficulty.MEDIO
		"DIFICIL", "DIFFICULT", "HARD":
			return Difficulty.DIFICIL
		"MUY_DIFICIL", "VERY_HARD":
			return Difficulty.MUY_DIFICIL
		"FACIL", "EASY":
			return Difficulty.FACIL
	push_warning("Enums: unknown difficulty '%s', falling back to FACIL." % key)
	return Difficulty.FACIL
