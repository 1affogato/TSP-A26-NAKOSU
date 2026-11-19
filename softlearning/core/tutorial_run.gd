class_name TutorialRun
extends RefCounted
## In-memory state of the UC-01 tutorial while it spans scenes (B4).
##
## `DepartmentView` owns a `TutorialController`, but the view is destroyed while
## the guided session runs. These static fields carry the step, the chosen
## department and the ELO delta across that scene change.
##
## Nothing here is persisted on purpose: closing the app in the middle of the
## tutorial resets it to the first step, as UC-01.2.a1 requires. Only
## `PlayerProgress.tutorial_completed` survives a restart.

static var active: bool = false
static var step: Enums.TutorialStep = Enums.TutorialStep.DEPARTMENTS
static var department: Enums.Department = Enums.Department.DATA_STRUCTURES
static var elo_delta: float = 0.0


## Forgets the tutorial run. Called when a new run starts and by the tests.
static func reset() -> void:
	active = false
	step = Enums.TutorialStep.DEPARTMENTS
	department = Enums.Department.DATA_STRUCTURES
	elo_delta = 0.0
