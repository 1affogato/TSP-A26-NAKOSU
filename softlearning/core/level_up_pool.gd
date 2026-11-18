class_name LevelUpPool
extends Resource
## Level-up pool (B2) of UC-12: the scripted sessions of every department and
## target level. Same role as the other content pools, but it draws nothing at
## random: `get_session()` returns the authored session or null (UC-12.4.e1).
##
## The content lives in `resources/level_up_pool.tres`.

@export var sessions: Array[LevelUpSession] = []


## UC-12.4: the fixed sequence that unlocks `target_level` in `department`, or
## null when that level was never authored (UC-12.4.e1).
func get_session(department: Enums.Department, target_level: int) -> LevelUpSession:
	for session in sessions:
		if session != null and session.department == department \
				and session.target_level == target_level:
			return session
	return null
