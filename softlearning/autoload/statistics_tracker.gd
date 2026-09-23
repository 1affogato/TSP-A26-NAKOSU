extends Node
## StatisticsTracker (B6) — autoload singleton.
##
## Keeps the player's history of results and derives every statistic from it:
## there are no counters stored anywhere, only the [ResultRecord] list, so the
## general and detailed views can never drift out of sync with the history.
##
## Reads the stored history from the persistence service (B7) when the game
## starts and hands it back with `get_history()` so the orchestrator (B4) can
## save it again at the end of a session (UC-02.8).

var history: Array[ResultRecord] = []


func _ready() -> void:
	history = PersistenceService.load_history()


# ------------------------------------------------------------------- write

## UC-02.6: records a finished minigame.
##
## The diagram is explicit that B6 is what builds the [ResultRecord], stamping
## the current moment, which is why this takes a [MinigameResult] rather than a
## record. This is the only way into the history.
func register_result(result: MinigameResult) -> void:
	if result == null:
		return
	history.append(ResultRecord.create(result.type, result.department, result.level, result.success))


# -------------------------------------------------------------------- read

## UC-02.8: the whole history, for the orchestrator to store. Returns a copy, so
## nobody can append to the tracker's list behind its back.
func get_history() -> Array[ResultRecord]:
	var copy: Array[ResultRecord] = history.duplicate()
	return copy


## UC-11.2 / UC-11.3: games played and games won in one department, plus whether
## it can level up. That last part is B1's call, not B6's.
func get_general_stats(department: Enums.Department) -> GeneralStats:
	var records := _records_of(department)
	var total_correct := 0
	for record in records:
		if record.success:
			total_correct += 1
	return GeneralStats.create(
		department,
		records.size(),
		total_correct,
		DepartmentManager.can_level_up(department)
	)


## UC-11.4 / UC-11.5: the same history, grouped by minigame type, by difficulty
## or by date, depending on `type`.
func get_detailed_stats(department: Enums.Department, type: Enums.StatType) -> DetailedStats:
	var totals := _totals_by_label(_records_of(department), type)
	var entries: Array[StatEntry] = []
	for label in _ordered_labels(totals, type):
		entries.append(StatEntry.create(label, totals[label][0], totals[label][1]))
	return DetailedStats.create(department, type, entries)


# ---------------------------------------------------------------- internals

## UC-11.2: only the records of one department.
func _records_of(department: Enums.Department) -> Array[ResultRecord]:
	var records: Array[ResultRecord] = []
	for record in history:
		if record.department == department:
			records.append(record)
	return records


## label -> [played, correct] for the grouping the caller asked for.
func _totals_by_label(records: Array[ResultRecord], type: Enums.StatType) -> Dictionary:
	var totals := {}
	for record in records:
		var label := _label_of(record, type)
		if not totals.has(label):
			totals[label] = [0, 0]
		totals[label][0] += 1
		if record.success:
			totals[label][1] += 1
	return totals


func _label_of(record: ResultRecord, type: Enums.StatType) -> String:
	match type:
		Enums.StatType.BY_MINIGAME:
			return record.type
		Enums.StatType.BY_DIFFICULTY:
			return Enums.difficulty_to_key(record.level)
		_:
			return Time.get_date_string_from_unix_time(record.timestamp)


## Row order: difficulties from easy to hard, dates chronologically (ISO dates
## compare correctly as text), minigame types alphabetically. Labels that never
## appear are left out.
func _ordered_labels(totals: Dictionary, type: Enums.StatType) -> Array:
	if type == Enums.StatType.BY_DIFFICULTY:
		var difficulties := []
		for difficulty in Enums.Difficulty.values():
			var key := Enums.difficulty_to_key(difficulty)
			if totals.has(key):
				difficulties.append(key)
		return difficulties

	var labels := totals.keys()
	labels.sort()
	return labels
