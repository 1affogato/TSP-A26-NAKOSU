extends Control
## UC-07 view: the question with its timer (QuestionScreen) and, once it is
## answered or the time runs out, the feedback (FeedbackScreen).
##
## It follows the QuizMinigame it is given (question_ready, time_updated,
## answered) and forwards the player's choice with minigame.answer(). Pause
## and exit belong to SessionView: this view only asks for them through
## exit_requested and next_requested.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

## Shown by SessionView under the pause menu, which covers the question.
var pause_note := "Se conservan la pregunta y el tiempo restante."

var minigame: QuizMinigame
var _question: QuizQuestion
## Text of the selected option ("" while nothing is selected).
var _response := ""
## False when the feedback arrives before "Confirmar Respuesta": the time ran out.
var _confirmed := false
var _is_correct := false


func _ready() -> void:
	%OptionA.button_group.pressed.connect(_highlight)
	%HomeButton.pressed.connect(exit_requested.emit)
	%NextButton.pressed.connect(next_requested.emit)
	$FeedbackScreen/Layout/ResultBadge/Icon.draw.connect(_draw_mark)


## Follows `quiz` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(quiz: QuizMinigame, progress: String) -> void:
	minigame = quiz
	%QuestionNumber.text = progress
	quiz.question_ready.connect(show_question)
	quiz.time_updated.connect(update_timer)
	quiz.answered.connect(show_feedback)


## UC-07.2
func show_question(question: QuizQuestion) -> void:
	_question = question
	_confirmed = false
	%DepartmentTag.text = DepartmentManager.get_department_name(question.department)
	%TopicTag.text = question.title
	%Question.text = question.description
	var responses := question.get_possible_responses()
	for i in %Options.get_child_count():
		var option: Button = %Options.get_child(i)
		option.text = responses[i]
		option.button_pressed = false
	_highlight(null)
	$FeedbackScreen.hide()
	$QuestionScreen.show()


## UC-07.3
func update_timer(time_left: float) -> void:
	%TimeLeft.text = str(ceili(time_left))


## UC-07.4, and UC-07.3.a1 when it arrives before the player confirmed.
func show_feedback(is_correct: bool) -> void:
	var tone := "Right" if is_correct else "Wrong"
	_is_correct = is_correct
	$FeedbackScreen/Layout/ResultBadge/Icon.queue_redraw()
	%ResultBadge.theme_type_variation = tone + "Badge"
	%ResultTitle.theme_type_variation = tone + "Title"
	%ResultTitle.text = "Respuesta Correcta" if is_correct else "Respuesta Incorrecta"
	%TimeoutBanner.visible = not _confirmed
	%FeedbackQuestion.text = _question.description
	%YourAnswer.theme_type_variation = tone + "Answer"
	%YourAnswer.text = _response if _response else "Sin respuesta"
	%CorrectRow.visible = not is_correct
	%CorrectAnswer.text = _question.get_correct_response()
	$QuestionScreen.hide()
	$FeedbackScreen.show()


## Selecting only highlights the option; nothing is answered until the player
## presses "Confirmar Respuesta".
func _highlight(selected: BaseButton) -> void:
	_response = selected.text if selected else ""
	%ConfirmButton.disabled = selected == null
	for option in %Options.get_children():
		option.get_node("Badge").theme_type_variation = &"BadgeOn" if option == selected else &"Badge"
		option.get_node("Check").visible = option == selected


## The badge's check or cross, drawn in white (there is no icon asset).
func _draw_mark() -> void:
	var icon: Control = $FeedbackScreen/Layout/ResultBadge/Icon
	var c := icon.size / 2.0
	var s := minf(icon.size.x, icon.size.y) * 0.22
	if _is_correct:
		icon.draw_polyline(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(-s * 0.3, s * 0.7), c + Vector2(s, -s * 0.6)]), Color.WHITE, 5.0, true)
	else:
		icon.draw_line(c + Vector2(-s, -s), c + Vector2(s, s), Color.WHITE, 5.0, true)
		icon.draw_line(c + Vector2(s, -s), c + Vector2(-s, s), Color.WHITE, 5.0, true)


## UC-07.3: the verdict comes back through `answered` -> show_feedback().
func _on_confirm_pressed() -> void:
	_confirmed = true
	minigame.answer(_response)
