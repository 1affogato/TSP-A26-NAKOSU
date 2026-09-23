extends Node
## PersistenceService (B7) — autoload singleton.
##
## Only two models are stored, and nothing else:
##   [DepartmentState] -> one `.tres` per department under `user://save/`
##   [ResultRecord]    -> one JSON object per line of `result_history.jsonl`
##
## UC-02.8: writing happens only when a session ends, through
## `save_progress(data)`. Reading happens when the game starts, so that
## `DepartmentManager` (B1) and `StatisticsTracker` (B6) can begin from the
## stored progress:
## [codeblock]
## var states := PersistenceService.load_department_states()   # -> B1
## var history := PersistenceService.load_history()            # -> B6
## # ... the session runs ...
## var data := SaveData.create()
## data.department_states = manager.get_all_states()
## data.history = tracker.get_history()
## if not PersistenceService.save_progress(data):
##     pass  # UC-02.8.e1: show the save error screen
## [/codeblock]
##
## The service keeps no copy of the progress in memory: while the game runs,
## B1 owns the states and B6 owns the history.

## UC-02.8.e1 — emitted by `save_progress()` when something could not be
## written. `reason` is ready to be shown to the player.
signal save_failed(reason: String)

const SAVE_DIR := "user://save"
const DEPARTMENT_STATE_PREFIX := "department_state_"
const DEPARTMENT_STATE_EXTENSION := ".tres"
const RESULT_HISTORY_FILE := "result_history.jsonl"

## How many history records are already in the log. `save_progress()` appends
## only what comes after this index, so calling it twice in one session never
## writes the same result twice.
var _persisted_history_count: int = 0
var _last_error: String = ""


func _ready() -> void:
	_ensure_save_dir()
	# Counts what a previous run already stored, so the first save of this
	# session appends only the new results.
	_persisted_history_count = load_history().size()


# --------------------------------------------------------------------- read

## The four department states, in enum order. This is the progress
## `DepartmentManager` (B1) starts from.
func load_department_states() -> Array[DepartmentState]:
	var states: Array[DepartmentState] = []
	for department in Enums.all_departments():
		states.append(load_department_state(department))
	return states


## State of one department. Always returns a usable object: a department with
## no `.tres` yet — or one whose file cannot be loaded — starts from a fresh
## state, and the unreadable file is left on disk untouched.
##
## The load bypasses the resource cache on purpose: otherwise Godot would hand
## back the instance that was saved earlier in the session, hiding both a
## `.tres` edited from the inspector and a file that has become unreadable.
func load_department_state(department: Enums.Department) -> DepartmentState:
	var path := _state_path(department)
	if not FileAccess.file_exists(path):
		return DepartmentState.create(department)

	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded == null or not (loaded is DepartmentState):
		_last_error = "%s no se pudo cargar; se usará un estado nuevo." % path
		push_warning(_last_error)
		return DepartmentState.create(department)

	var state: DepartmentState = loaded
	# The file name is the authority: moving a save between machines should not
	# be able to change which department a file belongs to.
	state.department = department
	state.sanitize()
	return state


## Every result stored so far, oldest first (the order of the log). This is the
## history `StatisticsTracker` (B6) starts from.
func load_history() -> Array[ResultRecord]:
	var history: Array[ResultRecord] = []
	var path := _save_path(RESULT_HISTORY_FILE)
	if not FileAccess.file_exists(path):
		return history

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_error = "No se pudo leer %s (%s)." % [path, error_string(FileAccess.get_open_error())]
		push_error(_last_error)
		return history
	while not file.eof_reached():
		var record := ResultRecord.from_json_line(file.get_line())
		if record != null:
			history.append(record)
	file.close()
	return history


## True when a previous run left something behind.
func has_save_data() -> bool:
	if FileAccess.file_exists(_save_path(RESULT_HISTORY_FILE)):
		return true
	for department in Enums.all_departments():
		if FileAccess.file_exists(_state_path(department)):
			return true
	return false


# -------------------------------------------------------------------- write

## UC-02.8: stores everything a finished session produced and returns whether
## it worked. On failure `save_failed` is emitted with a message ready to show
## to the player (UC-02.8.e1); whatever could be written is kept.
##
## `data.history` has to be the complete history (`B6.get_history()`), because
## only the records that are not in the log yet get appended. A new result must
## go through B6 first: `StatisticsTracker.register_result()` is what creates
## the record (UC-02.6).
func save_progress(data: SaveData) -> bool:
	_last_error = ""
	if data == null:
		return _fail("save_progress() recibió un SaveData nulo.")
	if not _ensure_save_dir():
		return _fail(_last_error)

	var all_ok := true
	for state in data.department_states:
		if state != null:
			all_ok = _save_department_state(state) and all_ok
	all_ok = _append_new_history(data.history) and all_ok

	if not all_ok:
		save_failed.emit(_last_error)
	return all_ok


## Deletes every stored file. The game keeps running with whatever is already
## in memory, so a reset that is never followed by `save_progress()` changes
## nothing on disk.
func reset_all() -> void:
	for department in Enums.all_departments():
		var path := _state_path(department)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var history_path := _save_path(RESULT_HISTORY_FILE)
	if FileAccess.file_exists(history_path):
		DirAccess.remove_absolute(history_path)
	_persisted_history_count = 0
	_last_error = ""


## Last error produced by a read or a write ("" when everything went fine).
func get_last_error() -> String:
	return _last_error


# ---------------------------------------------------------------- internals

func _save_department_state(state: DepartmentState) -> bool:
	state.sanitize()
	var path := _state_path(state.department)
	var error := ResourceSaver.save(state, path)
	if error != OK:
		_last_error = "No se pudo guardar %s (%s)." % [path, error_string(error)]
		push_error(_last_error)
		return false
	return true


## Appends the history records that are not in the log yet, one JSON line each,
## so the file only ever grows.
func _append_new_history(history: Array[ResultRecord]) -> bool:
	if history.size() <= _persisted_history_count:
		return true

	var path := _save_path(RESULT_HISTORY_FILE)
	var file := FileAccess.open(path, FileAccess.READ_WRITE)
	if file == null:
		# First save of the whole game: the log does not exist yet.
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_last_error = "No se pudo abrir %s (%s)." % [path, error_string(FileAccess.get_open_error())]
		push_error(_last_error)
		return false

	file.seek_end()
	for index in range(_persisted_history_count, history.size()):
		var record: ResultRecord = history[index]
		if record != null:
			file.store_line(record.to_json_line())
	file.close()

	_persisted_history_count = history.size()
	return true


func _state_path(department: Enums.Department) -> String:
	return _save_path("%s%s%s" % [
		DEPARTMENT_STATE_PREFIX,
		Enums.department_to_key(department),
		DEPARTMENT_STATE_EXTENSION,
	])


func _save_path(file_name: String) -> String:
	return "%s/%s" % [SAVE_DIR, file_name]


func _ensure_save_dir() -> bool:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return true
	var error := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if error != OK:
		_last_error = "No se pudo crear la carpeta de guardado (%s)." % error_string(error)
		return false
	return true


func _fail(message: String) -> bool:
	_last_error = message
	push_error(_last_error)
	save_failed.emit(_last_error)
	return false
