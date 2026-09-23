extends Control
## UC-11: the player picks a floor of the building (SelectScreen) and then
## consults that department's stats (DetailScreen).
##
## The floor buttons are connected in the scene, each one binding its
## `Enums.Department`, so this script needs no node paths for them.

## Department shown in DetailScreen, set by the floor that was pressed.
var department: Enums.Department


func _show_detail(selected: Enums.Department) -> void:
	department = selected
	# ponytail: the labels keep the mockup values until DepartmentManager (B1)
	# and StatisticsTracker (B6) exist; fill them here from `department`.
	$SelectScreen.hide()
	$DetailScreen.show()


func _show_select() -> void:
	$DetailScreen.hide()
	$SelectScreen.show()
