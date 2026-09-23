extends Control
## UC-02 session screen. It hosts the view of the current minigame (QuizView)
## and owns every session control: the pause button and menu (UC-02.4.a1),
## the exit (UC-02.4.a2) and the save error (UC-02.8.e1). Minigame views never
## pause or leave the session themselves.
##
## ponytail: SessionOrchestrator (B4) doesn't exist yet, so the buttons drive
## these screens directly and _ready() shows one fixed question. When B4
## exists, the buttons call session.pause() / resume() / exit() and B4's
## signals (paused, resumed, save_failed, session_ended) call the methods below.


func _ready() -> void:
	$QuizView.show_question(load("res://resources/quiz_questions/quiz_question_004.tres"))


func show_pause_menu() -> void:
	$PauseMenu.show()


func hide_pause_menu() -> void:
	$PauseMenu.hide()


func show_save_error() -> void:
	$SaveError.show()


func return_to_department() -> void:
	get_tree().change_scene_to_file("res://scenes/department_view.tscn")
