class_name PlayerProgress
extends Resource
## Progress that is not tied to one department (UC-01, and later UC-12).
##
## `PersistenceService` (B7) stores it in `user://save/player_progress.tres`.
## Only durable flags live here: the current tutorial step is deliberately kept
## in memory (see `TutorialRun`), so closing the app in the middle of the
## tutorial makes it start over (UC-01.2.a1).

## UC-01: whether the first-run tutorial was completed and saved.
@export var tutorial_completed: bool = false


static func create() -> PlayerProgress:
	return PlayerProgress.new()
