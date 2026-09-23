extends Control
## UC-02 session screen. It hosts the view of the current minigame (QuizView)
## and owns every session control: the pause button and menu (UC-02.4.a1),
## the exit (UC-02.4.a2) and the save error (UC-02.8.e1). Minigame views never
## pause or leave the session themselves.
##
## The logic is SessionOrchestrator (B4), a child of this scene. The scene
## wires them: B4's signals call the methods below, and the buttons (plus
## QuizView's exit_requested / next_requested) call B4's public methods.

@onready var session: SessionOrchestrator = $SessionOrchestrator


## UC-02.1: DepartmentView calls it once this scene is in the tree.
func open(department: Enums.Department) -> void:
	session.start_session(department)


## UC-02.4: binds the view of the minigame that is about to start.
func show_minigame(minigame: Minigame) -> void:
	var number := session.current_index + 1
	var total := session.sequence.size()
	$SessionProgress.max_value = total
	$SessionProgress.value = number
	# Quiz is the only minigame with a view so far.
	$QuizView.set_minigame(minigame, "Pregunta %d de %d" % [number, total])


func show_pause_menu() -> void:
	$PauseMenu.show()


func hide_pause_menu() -> void:
	$PauseMenu.hide()


func show_save_error() -> void:
	$SaveError.show()


## UC-02.9. After a save error (UC-02.8.e1) it first waits for the player to
## press "Volver a departamentos".
func return_to_department(department: Enums.Department) -> void:
	if $SaveError.visible:
		await $SaveError/Center/Layout/BackButton.pressed
	var view: Node = load("res://scenes/department_view.tscn").instantiate()
	view.ready.connect(view.select_department.bind(department))
	get_tree().change_scene_to_node(view)
