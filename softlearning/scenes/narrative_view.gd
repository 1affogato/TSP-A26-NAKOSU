extends Control
## UC-09 view: the role, the story with its blanks, the bank of eight options
## and the attempts (PlayScreen) and, at the end, the feedback with the right
## answers and the closing dialogue.
##
## It follows the NarrativeMinigame it is given (narrative_ready,
## answers_changed, attempt_failed, answered) and forwards the player's
## actions with place_option(), clear_blank() and confirm(). An option goes
## into a blank by dragging it there or by clicking it and then the blank; a
## filled blank can be dragged to another one or emptied with its "×".
## Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

const SKIN_NAMES := {
	NarrativeScenario.SkinType.CREDIBILITY: "Credibilidad",
	NarrativeScenario.SkinType.BUDGET: "Presupuesto",
	NarrativeScenario.SkinType.SPRINT_TIME: "Tiempo de sprint",
}
## UC-09.7.a1.1: how losing an attempt reads in each skin.
const SKIN_LOSS := {
	NarrativeScenario.SkinType.CREDIBILITY: "perdiste credibilidad",
	NarrativeScenario.SkinType.BUDGET: "gastaste parte del presupuesto",
	NarrativeScenario.SkinType.SPRINT_TIME: "usaste tiempo de sprint",
}
## UC-09.8: title of the bad ending.
const SKIN_OUT := {
	NarrativeScenario.SkinType.CREDIBILITY: "Se agotó tu credibilidad",
	NarrativeScenario.SkinType.BUDGET: "Se agotó tu presupuesto",
	NarrativeScenario.SkinType.SPRINT_TIME: "Se agotó tu tiempo de sprint",
}

## Shown by SessionView under the pause menu.
var pause_note := "Se conservan tus respuestas y tus intentos restantes."
var minigame: NarrativeMinigame
var _scenario: NarrativeScenario
var _answers := {}
## Option picked with a click, waiting for its blank ("" when none).
var _held := ""
## Whether an attempt already failed (changes the hints).
var _failed := false


func _ready() -> void:
	%ConfirmButton.pressed.connect(_on_confirm_pressed)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `narrative` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(narrative: NarrativeMinigame, progress: String) -> void:
	minigame = narrative
	%Progress.text = progress
	narrative.narrative_ready.connect(show_narrative)
	narrative.answers_changed.connect(show_answers)
	narrative.attempt_failed.connect(show_attempt_failed)
	narrative.answered.connect(show_feedback)


## UC-09.3
func show_narrative(scenario: NarrativeScenario, attempts_left: int) -> void:
	_scenario = scenario
	_answers = {}
	_held = ""
	_failed = false
	%DepartmentTag.text = DepartmentManager.get_department_name(scenario.department)
	%Role.text = "Tu rol: %s" % scenario.role
	%Context.text = scenario.context
	%SkinName.text = SKIN_NAMES[scenario.skin]
	%Attempts.show_attempts(scenario.skin, minigame.max_attempts, attempts_left)
	%FailBanner.hide()
	%ConfirmButton.disabled = true
	%Hint.text = "Arrastra una opción a un hueco, o haz clic en una opción y luego en el hueco. Puedes cambiarla, moverla o quitarla (×) sin penalización."
	_build_story()
	_build_options()
	$Feedback.hide()
	$PlayScreen.show()


## UC-09.4 / UC-09.5
func show_answers(answers: Dictionary, can_confirm: bool) -> void:
	_answers = answers
	%ConfirmButton.disabled = not can_confirm
	if _failed:
		%Hint.text = "Cambiaste una respuesta. Confirma cuando estés listo."
	elif can_confirm:
		%Hint.text = "Todos los huecos están llenos: ya puedes confirmar."
	_build_story()
	_build_options()


## UC-09.7.a1: says it did not work, never where; the answers stay.
func show_attempt_failed(attempts_left: int) -> void:
	_failed = true
	%Attempts.show_attempts(_scenario.skin, minigame.max_attempts, attempts_left)
	%FailBanner.text = "No funcionó: %s. Revisa tus respuestas." % SKIN_LOSS[_scenario.skin]
	%FailBanner.show()
	%Hint.text = "Tus respuestas se conservan. Cámbialas o vuelve a confirmar."


## UC-09.8: good or bad ending with every right answer.
func show_feedback(is_correct: bool, correct_answers: Array[String]) -> void:
	var feedback := $Feedback
	if is_correct:
		feedback.show_result(true, "¡Historia resuelta!", "Llenaste bien todos los huecos.")
	else:
		feedback.show_result(false, SKIN_OUT[_scenario.skin], "Ya no te quedan intentos.")
	var lines := _scenario.story.split("\n")
	for i in correct_answers.size():
		var line := _line_of_blank(lines, i + 1)
		feedback.add_chips("%d. %s" % [i + 1, line], [correct_answers[i]], true)
	feedback.add_note(_scenario.good_ending if is_correct else _scenario.bad_ending)
	$PlayScreen.hide()
	feedback.show()


## One flow row per story line: the words as labels and each "[BLANK_n]" as
## a drop target button.
func _build_story() -> void:
	for row in %Story.get_children():
		row.queue_free()
	var regex := RegEx.create_from_string("\\[BLANK_(\\d+)\\]")
	for line in _scenario.story.split("\n"):
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		var cursor := 0
		for found in regex.search_all(line):
			_add_words(flow, line.substr(cursor, found.get_start() - cursor))
			flow.add_child(_make_blank(int(found.get_string(1))))
			cursor = found.get_end()
		_add_words(flow, line.substr(cursor))
		%Story.add_child(flow)


func _add_words(flow: HFlowContainer, text: String) -> void:
	for word in text.split(" ", false):
		var label := Label.new()
		label.text = word
		label.add_theme_font_size_override("font_size", 16)
		flow.add_child(label)


func _make_blank(index: int) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	var button := Button.new()
	button.theme_type_variation = &"Option"
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(170, 34)
	var answer: String = _answers.get(index, "")
	button.text = "%d. %s" % [index, answer if answer else "hueco vacío"]
	button.button_pressed = not answer.is_empty()
	if answer.is_empty():
		button.modulate = Color(1, 1, 1, 0.75)
	button.pressed.connect(_on_blank_pressed.bind(index))
	button.set_drag_forwarding(_get_blank_drag.bind(index, button), _can_drop_on_blank, _drop_on_blank.bind(index))
	box.add_child(button)
	if not answer.is_empty():
		var clear := Button.new()
		clear.text = "×"
		clear.flat = true
		clear.add_theme_font_size_override("font_size", 22)
		clear.add_theme_color_override("font_color", Color(0.392, 0.455, 0.545))
		clear.add_theme_color_override("font_hover_color", Color(0.863, 0.149, 0.149))
		clear.tooltip_text = "Quitar"
		clear.pressed.connect(_on_blank_cleared.bind(index))
		box.add_child(clear)
	return box


## The bank: options in use stay highlighted (one option can fill several
## blanks, so they are never removed).
func _build_options() -> void:
	for option in %Options.get_children():
		option.queue_free()
	var used := _answers.values()
	for text in _scenario.get_options():
		var button := Button.new()
		button.text = text
		button.theme_type_variation = &"Option"
		button.toggle_mode = true
		button.button_pressed = text == _held or used.has(text)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_option_pressed.bind(text))
		button.set_drag_forwarding(_get_option_drag.bind(text, button), Callable(), Callable())
		%Options.add_child(button)


func _on_option_pressed(text: String) -> void:
	_held = "" if _held == text else text
	_build_options()


## A held option goes into the clicked blank.
func _on_blank_pressed(index: int) -> void:
	if _held.is_empty():
		_build_story()
		return
	var option := _held
	_held = ""
	_on_option_placed(index, option)


func _get_option_drag(_at: Vector2, text: String, button: Button) -> Variant:
	button.set_drag_preview(_preview(text))
	return {"option": text}


func _get_blank_drag(_at: Vector2, index: int, button: Button) -> Variant:
	var answer: String = _answers.get(index, "")
	if answer.is_empty():
		return null
	button.set_drag_preview(_preview(answer))
	return {"option": answer, "from": index}


func _can_drop_on_blank(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("option")


## UC-09.4 / UC-09.4.a1: dropped from the bank, or moved from another blank.
func _drop_on_blank(_at: Vector2, data: Variant, index: int) -> void:
	_held = ""
	if data.has("from") and data.from != index:
		_on_blank_cleared(data.from)
	_on_option_placed(index, data.option)


## UC-09.4: an option went into a blank (click or drop).
func _on_option_placed(blank_index: int, option: String) -> void:
	minigame.place_option(blank_index, option)


## UC-09.4.a1: a blank was emptied ("×" or moved away).
func _on_blank_cleared(blank_index: int) -> void:
	minigame.clear_blank(blank_index)


func _preview(text: String) -> Control:
	var label := Button.new()
	label.text = text
	label.theme_type_variation = &"Option"
	label.modulate.a = 0.85
	return label


## The text of the line that holds blank `index`, with the blank as "___".
func _line_of_blank(lines: PackedStringArray, index: int) -> String:
	var token := "[BLANK_%d]" % index
	for line in lines:
		if line.contains(token):
			var text := line.replace(token, "___")
			return RegEx.create_from_string("\\[BLANK_\\d+\\]").sub(text, "___", true)
	return ""


## UC-09.6: the verdict comes back through attempt_failed or answered.
func _on_confirm_pressed() -> void:
	minigame.confirm()
