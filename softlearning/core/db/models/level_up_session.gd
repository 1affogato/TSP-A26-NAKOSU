class_name LevelUpSession
extends Resource
## One scripted level-up sequence (UC-12.4, "LevelUpSession").
##
## Unlike a normal session, the order is authored and never shuffled: the player
## must finish all of `sequence`, failing at most one minigame, to raise the
## department's level. The difficulty is not stored here: it comes from
## `target_level` through `Enums.difficulty_for_level()`.

## Department this session belongs to.
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
## Level the session unlocks (1..4): the department plays it while it is at
## `target_level - 1`.
@export var target_level: int = 1
## Fixed order of engine keys (B5), e.g. ["QUIZ", "SWIPE", ...]. Authored data.
@export var sequence: Array[String] = []


static func create(
	new_department: Enums.Department,
	new_target_level: int,
	new_sequence: Array[String]
) -> LevelUpSession:
	var session := LevelUpSession.new()
	session.department = new_department
	session.target_level = new_target_level
	session.sequence = new_sequence
	return session
