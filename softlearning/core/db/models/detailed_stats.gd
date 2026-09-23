class_name DetailedStats
extends Resource
## Detailed breakdown of one department (UC-11.4, "DetailedStats").
##
## A computed snapshot, like [GeneralStats]: B6 groups the history according to
## `type` and returns the rows as [StatEntry] objects.

@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var type: Enums.StatType = Enums.StatType.BY_MINIGAME
@export var entries: Array[StatEntry] = []


static func create(
	new_department: Enums.Department,
	new_type: Enums.StatType,
	new_entries: Array[StatEntry]
) -> DetailedStats:
	var stats := DetailedStats.new()
	stats.department = new_department
	stats.type = new_type
	stats.entries = new_entries
	return stats
