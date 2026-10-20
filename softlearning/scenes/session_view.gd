extends Control
## UC-02 session screen. It hosts the view of the current minigame and owns
## every session control: the pause button and menu (UC-02.4.a1), the exit
## (UC-02.4.a2), the save error (UC-02.8.e1) and the ELO change of the last
## result (UC-02.6). Minigame views never pause or leave the session
## themselves.
##
## The logic is SessionOrchestrator (B4), a child of this scene. The scene
## wires them: B4's signals call the methods below, and the buttons (plus each
## minigame view's exit_requested / next_requested) call B4's public methods.

## The view of each engine (B5). Every view has set_minigame(minigame,
## progress), the signals exit_requested / next_requested and a `pause_note`.
const VIEWS := {
	"QUIZ": preload("res://scenes/quiz_view.tscn"),
	"SWIPE": preload("res://scenes/swipe_view.tscn"),
	"NARRATIVE": preload("res://scenes/narrative_view.tscn"),
	"TRAIN": preload("res://scenes/train_view.tscn"),
	"BOMB": preload("res://scenes/bomb_view.tscn"),
}

@onready var session: SessionOrchestrator = $SessionOrchestrator
var _view: Control


## UC-02.1: DepartmentView calls it once this scene is in the tree.
func open(department: Enums.Department) -> void:
	session.start_session(department)


## UC-02.4: replaces the previous view with the one of the minigame that is
## about to start. The view is placed under the progress bar, the pause button
## and the menus, so the pause menu covers it (UC-02.4.a1).
func show_minigame(minigame: Minigame) -> void:
	var number := session.current_index + 1
	var total := session.sequence.size()
	$SessionProgress.max_value = total
	$SessionProgress.value = number
	$EloChange.hide()
	if _view:
		_view.queue_free()
		# Frees the name now, so the new view keeps it ("QuizView", ...).
		remove_child(_view)
	_view = VIEWS[session.sequence[session.current_index]].instantiate()
	add_child(_view)
	move_child(_view, $Background.get_index() + 1)
	_view.exit_requested.connect(session.exit)
	_view.next_requested.connect(session.next)
	_view.set_minigame(minigame, "Minijuego %d de %d" % [number, total])
	%PauseNote.text = _view.pause_note


## UC-02.6: "ELO 1016 (+16)" while the feedback is on screen.
func show_elo_change(delta: float, elo: float) -> void:
	var symbol := "+" if delta >= 0.0 else "−"
	$EloChange.text = "ELO %d  (%s%d)" % [roundi(elo), symbol, absi(roundi(delta))]
	$EloChange.theme_type_variation = &"RightAnswer" if delta >= 0.0 else &"WrongAnswer"
	$EloChange.show()


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
