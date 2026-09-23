extends Control
## UC-11: the player picks a floor of the building (SelectScreen) and then
## consults that department's stats (DetailScreen). "Comenzar Partida" starts a
## session there (UC-02.1), and the session comes back through
## select_department() (UC-02.9).
##
## The floor buttons are connected in the scene, each one binding its
## `Enums.Department`, so this script needs no node paths for them.

## Department shown in DetailScreen.
var department: Enums.Department


## UC-11.1, and UC-02.9 when a session returns here.
func select_department(selected: Enums.Department) -> void:
	department = selected
	# ponytail: the labels keep the mockup values until UC-11 exists
	# (StatisticsTracker.get_general_stats / get_detailed_stats); fill them here.
	$SelectScreen.hide()
	$DetailScreen.show()


func _show_select() -> void:
	$DetailScreen.hide()
	$SelectScreen.show()


## UC-02.1: opens SessionView for the department on screen.
func _on_play_pressed() -> void:
	var session_view: Node = load("res://scenes/session_view.tscn").instantiate()
	session_view.ready.connect(session_view.open.bind(department))
	get_tree().change_scene_to_node(session_view)
