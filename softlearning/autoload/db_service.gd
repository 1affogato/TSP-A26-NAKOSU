extends Node
## DbService — autoload singleton, the "PersistenceService" (B7) of UC-02.
##
## Every piece of persistent data goes through this node: gameplay code asks
## it for the model it needs and calls `save_all()` when work is done. No
## other script opens the JSON files.
##
## Files written under `user://save/`:
##   player_profile.json    -> PlayerProfile           (single object)
##   department_stats.json  -> Array[DepartmentStats]  (one entry per department)
##   minigame_stats.json    -> Array[MinigameStats]
##   result_history.json    -> Array[ResultRecord]     (append-only log)
##
## Usage from anywhere:
## [codeblock]
## var stats := DbService.get_department_stats(Enums.Department.SOFTWARE_DEV)
## print(stats.get_win_rate())
## DbService.save_all()
## [/codeblock]

## Emitted after a load finished (the first one happens automatically).
signal data_loaded()
## Emitted when a write failed; `reason` is ready to show to the player
## (UC-02.8.e1 "save_failed").
signal save_failed(reason: String)

const SAVE_DIR := "user://save"
const PLAYER_PROFILE_FILE := "player_profile.json"
const DEPARTMENT_STATS_FILE := "department_stats.json"
const MINIGAME_STATS_FILE := "minigame_stats.json"
const RESULT_HISTORY_FILE := "result_history.jsonl"

var player_profile: PlayerProfile = null
var department_stats: Array[DepartmentStats] = []
var minigame_stats: Array[MinigameStats] = []
var result_history: Array[ResultRecord] = []

var _last_error: String = ""


func _ready() -> void:
	load_all()


# --------------------------------------------------------------------- load

## True when a previous run already left a profile file behind. Use it to
## decide between "continue" and "new game" in the main menu.
func has_save_data() -> bool:
	return FileAccess.file_exists(_save_path(PLAYER_PROFILE_FILE))


## Reads every file from disk into memory, filling in defaults for whatever is
## missing (first run) or unreadable. Returns false only when the save folder
## itself cannot be created.
func load_all() -> bool:
	_last_error = ""
	if not _ensure_save_dir():
		return false

	var profile_data: Variant = _read_json(_save_path(PLAYER_PROFILE_FILE))
	if profile_data is Dictionary:
		player_profile = PlayerProfile.from_dict(profile_data as Dictionary)
	else:
		player_profile = PlayerProfile.create()
	player_profile.touch_login()

	department_stats = _load_department_stats()
	minigame_stats = _load_minigame_stats()
	result_history = _load_result_history()

	data_loaded.emit()
	return true


## Writes every file. Returns false when something failed (UC-02.8.e1), but
## the remaining files are still attempted, so one broken file does not hide
## the part of the save that did work.
func save_all() -> bool:
	_last_error = ""
	if not _ensure_save_dir():
		_emit_save_failed()
		return false

	var all_ok := true
	all_ok = _write_json(_save_path(PLAYER_PROFILE_FILE), player_profile.to_dict()) and all_ok
	all_ok = _write_json(_save_path(DEPARTMENT_STATS_FILE), _department_stats_to_array()) and all_ok
	all_ok = _write_json(_save_path(MINIGAME_STATS_FILE), _minigame_stats_to_array()) and all_ok
	all_ok = _write_json(_save_path(RESULT_HISTORY_FILE), _result_history_to_array()) and all_ok

	if not all_ok:
		_emit_save_failed()
	return all_ok


## Deletes the save files and rebuilds the in-memory state from scratch.
## Nothing is written back to disk until the next `save_all()`, so a reset
## that is never saved does not destroy anything.
func reset_all() -> void:
	for file_name in [PLAYER_PROFILE_FILE, DEPARTMENT_STATS_FILE, MINIGAME_STATS_FILE, RESULT_HISTORY_FILE]:
		var path := _save_path(file_name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	player_profile = PlayerProfile.create()
	player_profile.touch_login()
	department_stats = _default_department_stats()
	minigame_stats.clear()
	result_history.clear()


## Last error produced by a read or a write ("" when everything went fine).
## Feed it to the error screen of UC-02.8.e1 together with `save_failed`.
func get_last_error() -> String:
	return _last_error


# -------------------------------------------------------------------- read

## UC-11 `PlayerProfile.getDepartmentStats()`. Always returns a valid object:
## if the entry is missing it is created and added to the list.
func get_department_stats(department: Enums.Department) -> DepartmentStats:
	for stats in department_stats:
		if stats.department == department:
			return stats
	var created := DepartmentStats.create(department)
	department_stats.append(created)
	return created


## UC-11 `DepartmentStats.getMinigameStats()`. Creates the entry on first use,
## so the first game of a minigame already has somewhere to count itself.
func get_minigame_stats(
	department: Enums.Department,
	minigame_id: String,
	minigame_name: String = ""
) -> MinigameStats:
	var existing := find_minigame_stats(department, minigame_id)
	if existing != null:
		if not minigame_name.is_empty():
			existing.minigame_name = minigame_name
		return existing
	var created := MinigameStats.create(department, minigame_id, minigame_name)
	minigame_stats.append(created)
	return created


## Same as `get_minigame_stats()`, but read-only: returns null instead of
## creating an entry for a minigame that was never played.
func find_minigame_stats(department: Enums.Department, minigame_id: String) -> MinigameStats:
	for stats in minigame_stats:
		if stats.department == department and stats.minigame_id == minigame_id:
			return stats
	return null


## All minigame statistics of one department, for the detailed stats screen
## of UC-11.
func get_minigame_stats_for(department: Enums.Department) -> Array[MinigameStats]:
	var found: Array[MinigameStats] = []
	for stats in minigame_stats:
		if stats.department == department:
			found.append(stats)
	return found


## Result history, newest first. Pass a department to filter it; the default
## (-1) returns everything.
func get_history(department: int = -1) -> Array[ResultRecord]:
	var found: Array[ResultRecord] = []
	for index in range(result_history.size() - 1, -1, -1):
		var record: ResultRecord = result_history[index]
		if department < 0 or record.department == department:
			found.append(record)
	return found


# ------------------------------------------------------------------- write

## Applies one finished minigame to every aggregate and appends it to the
## history (UC-02.5 / UC-02.6).
##
## The ELO rules stay in `DepartmentManager` (B1): it computes the delta and
## passes it in. Persisting is still a separate decision — call `save_all()`
## when the session ends (UC-02.8), not after every single game.
func register_result(record: ResultRecord, department_elo_delta: float = 0.0) -> void:
	var stats := get_department_stats(record.department)
	stats.register_result(record.success, record.score, department_elo_delta)

	var minigame := get_minigame_stats(record.department, record.minigame_type, record.minigame_name)
	minigame.record_game_result(record.success, record.score, record.duration_seconds)
	# Per-minigame ELO is not defined by the diagrams yet (UC-11 only lists the
	# field), so it mirrors the department value until B1/B5 define a rule.
	minigame.current_elo = stats.elo

	result_history.append(record)


## Adds play time to the profile (called when a session ends).
func add_play_time(seconds: int) -> void:
	player_profile.add_play_time(seconds)


# --------------------------------------------------------------- internals

func _load_department_stats() -> Array[DepartmentStats]:
	var loaded: Array[DepartmentStats] = []
	var data: Variant = _read_json(_save_path(DEPARTMENT_STATS_FILE))
	if data is Array:
		for entry in (data as Array):
			if entry is Dictionary:
				loaded.append(DepartmentStats.from_dict(entry as Dictionary))
	return _complete_department_stats(loaded)


func _load_minigame_stats() -> Array[MinigameStats]:
	var loaded: Array[MinigameStats] = []
	var data: Variant = _read_json(_save_path(MINIGAME_STATS_FILE))
	if data is Array:
		for entry in (data as Array):
			if entry is Dictionary:
				loaded.append(MinigameStats.from_dict(entry as Dictionary))
	return loaded


func _load_result_history() -> Array[ResultRecord]:
	var loaded: Array[ResultRecord] = []
	var data: Variant = _read_json(_save_path(RESULT_HISTORY_FILE))
	if data is Array:
		for entry in (data as Array):
			if entry is Dictionary:
				loaded.append(ResultRecord.from_dict(entry as Dictionary))
	return loaded


## Whatever the file contained, the result has exactly one entry per
## department, in enum order, so gameplay code never has to check.
func _complete_department_stats(loaded: Array[DepartmentStats]) -> Array[DepartmentStats]:
	var complete: Array[DepartmentStats] = []
	for department in Enums.all_departments():
		var found: DepartmentStats = null
		for stats in loaded:
			if stats.department == department:
				found = stats
				break
		complete.append(found if found != null else DepartmentStats.create(department))
	return complete


func _default_department_stats() -> Array[DepartmentStats]:
	var created: Array[DepartmentStats] = []
	for department in Enums.all_departments():
		created.append(DepartmentStats.create(department))
	return created


func _department_stats_to_array() -> Array:
	var data := []
	for stats in department_stats:
		data.append(stats.to_dict())
	return data


func _minigame_stats_to_array() -> Array:
	var data := []
	for stats in minigame_stats:
		data.append(stats.to_dict())
	return data


func _result_history_to_array() -> Array:
	var data := []
	for record in result_history:
		data.append(record.to_dict())
	return data


func _save_path(file_name: String) -> String:
	return "%s/%s" % [SAVE_DIR, file_name]


func _ensure_save_dir() -> bool:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return true
	var error := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if error != OK:
		_last_error = "No se pudo crear la carpeta de guardado (%s)." % error_string(error)
		push_error(_last_error)
		return false
	return true


## Reads and parses one file. Returns null when the file does not exist or is
## unusable; a corrupt file is renamed to `.corrupt_<timestamp>` instead of
## being silently overwritten, so no save data disappears without a trace.
func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_error = "No se pudo abrir %s (%s)." % [path, error_string(FileAccess.get_open_error())]
		push_error(_last_error)
		return null
	var text := file.get_as_text()
	file.close()

	var parser := JSON.new()
	if parser.parse(text) != OK:
		var quarantined := "%s.corrupt_%d" % [path, int(Time.get_unix_time_from_system())]
		DirAccess.rename_absolute(path, quarantined)
		_last_error = "Archivo de guardado dañado (%s). Se movió a %s." % [path, quarantined]
		push_warning(_last_error)
		return null
	return parser.data


## Writes one JSON file. The data goes to a temporary file first and only
## replaces the old file once it is fully written, so a crash halfway through
## never leaves a truncated save behind.
func _write_json(path: String, data: Variant) -> bool:
	var temp_path := "%s.tmp" % path
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		_last_error = "No se pudo escribir %s (%s)." % [
			temp_path, error_string(FileAccess.get_open_error())
		]
		push_error(_last_error)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	if FileAccess.file_exists(path):
		var remove_error := DirAccess.remove_absolute(path)
		if remove_error != OK:
			DirAccess.remove_absolute(temp_path)
			_last_error = "No se pudo reemplazar %s (%s)." % [path, error_string(remove_error)]
			push_error(_last_error)
			return false

	var rename_error := DirAccess.rename_absolute(temp_path, path)
	if rename_error != OK:
		_last_error = "No se pudo mover %s a %s (%s)." % [
			temp_path, path, error_string(rename_error)
		]
		push_error(_last_error)
		return false
	return true


func _emit_save_failed() -> void:
	save_failed.emit(_last_error if not _last_error.is_empty() else "No se pudo guardar la partida.")
