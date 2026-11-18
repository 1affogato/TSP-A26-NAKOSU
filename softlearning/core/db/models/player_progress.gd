class_name PlayerProgress
extends Resource
## Progress that is not tied to one department (UC-01 tutorial, UC-12 level-ups).
##
## `PersistenceService` (B7) stores it in `user://save/player_progress.tres`.
## Only durable flags live here: the current tutorial step is deliberately kept
## in memory (see `TutorialRun`), so closing the app in the middle of the
## tutorial makes it start over (UC-01.2.a1).

## UC-01: whether the first-run tutorial was completed and saved.
@export var tutorial_completed: bool = false

## UC-12.8: calendar day ("YYYY-MM-DD") of the last successful level-up, or ""
## when the player never completed one. The limit is global: one level-up per
## day across every department (UC-12.2.a2).
@export var last_level_up_date: String = ""


static func create() -> PlayerProgress:
	return PlayerProgress.new()


## The current calendar day in the same "YYYY-MM-DD" form the file stores.
static func today() -> String:
	return Time.get_date_string_from_system()


## UC-12.2.a2: a level-up was already completed on `today_date` (empty means
## the current calendar day).
func is_level_up_used_today(today_date: String = "") -> bool:
	var day := today_date if not today_date.is_empty() else today()
	return not last_level_up_date.is_empty() and last_level_up_date == day


## UC-12.8: the level-up of `today_date` (empty means the current day) has been
## used, by any department.
func mark_level_up_used(today_date: String = "") -> void:
	last_level_up_date = today_date if not today_date.is_empty() else today()
