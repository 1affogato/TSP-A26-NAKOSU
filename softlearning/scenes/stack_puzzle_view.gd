extends Control
## UC-06 view: the input structure, the Stack and the produced output of the
## puzzle, the editor of the PUSH/POP sequence (PlayScreen) and, at the end, the
## feedback with the produced output, the target and a valid sequence.
##
## It follows the StackPuzzleMinigame it is given (puzzle_ready, editor_changed,
## simulation_ready, step_shown, simulation_invalid, output_mismatch,
## feedback_ready) and forwards the player's moves by calling the engine
## downward. The view never decides correctness or attempts (D14): it only
## paints the engine's signals and caches the last SimulationStep to repaint.
## Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

const RULES := "Añade operaciones con + PUSH y + POP. Selecciona una para eliminarla o moverla. Los intentos solo se gastan al ejecutar."
const EDIT_HINT := "Sin límite de tiempo. Revisa el estado de la entrada, el Stack y la salida."
const REVIEW_HINT := "Puedes avanzar y retroceder por los pasos: no cambia la secuencia, ni los intentos, ni el resultado."

const BLUE := Color(0.145, 0.388, 0.922)
const BLUE_DARK := Color(0.114, 0.306, 0.847)
const INK := Color(0.106, 0.169, 0.294)
const GREY := Color(0.89, 0.914, 0.961)
const GREY_DARK := Color(0.58, 0.639, 0.722)

const CELL_BORDER := Color(0.812, 0.855, 0.945)
const TARGET_BG := Color(0.992, 0.965, 0.847)
const TARGET_BORDER := Color(0.906, 0.839, 0.553)

const PUSH_BG := Color(0.918, 0.945, 1.0)
const PUSH_BORDER := Color(0.745, 0.827, 0.98)
const PUSH_TEXT := Color(0.118, 0.31, 0.749)
const POP_BG := Color(1.0, 0.957, 0.898)
const POP_BORDER := Color(0.957, 0.824, 0.635)
const POP_TEXT := Color(0.604, 0.353, 0.071)

const STACK_FILL_BG := Color(0.949, 0.969, 1.0)
const STACK_FILL_BORDER := Color(0.725, 0.796, 0.914)
const STACK_EMPTY_BORDER := Color(0.824, 0.867, 0.937)

const ERROR_TEXT := Color(0.651, 0.169, 0.169)
const WARN_TEXT := Color(0.541, 0.353, 0.059)

## Shown by SessionView under the pause menu.
var pause_note := "Se conservan la secuencia editada, el paso de la simulación y los intentos restantes."
var minigame: StackPuzzleMinigame
var _puzzle: StackPuzzle
var _operations: Array[StackOperation] = []
## Operation picked with a click (-1: none).
var _selected := -1
## Last SimulationStep received: the view repaints from it.
var _step: SimulationStep
var _step_index := 0
var _total_steps := 0
## True while the simulation is reviewed (editor_changed leaves it).
var _review := false
var _attempts_left := 0
var _max_attempts := 0
## Verdict cached during the review and shown when "Ver resultado" is pressed.
var _alert_text := ""
var _alert_is_error := true
## End chosen for the next PUSH on a Deque level.
var _end := StackOperation.DequeEnd.FRONT
var _bold: Font
var _error_box: StyleBoxFlat
var _warn_box: StyleBoxFlat


func _ready() -> void:
	_bold = get_theme_font(&"font", &"Badge")
	_error_box = _alert_style(Color(0.992, 0.929, 0.929), Color(0.949, 0.749, 0.749))
	_warn_box = _alert_style(Color(1.0, 0.965, 0.898), Color(0.945, 0.839, 0.627))
	%EditorTitle.add_theme_font_override("font", _bold)
	%EditorTitle.add_theme_font_size_override("font_size", 16)
	%Attempts.draw.connect(_draw_attempts)
	%PushButton.pressed.connect(_on_push_pressed)
	%PopButton.pressed.connect(_on_pop_pressed)
	%FrontButton.pressed.connect(_on_end_front_pressed)
	%RearButton.pressed.connect(_on_end_rear_pressed)
	%RemoveButton.pressed.connect(_on_remove_pressed)
	%LeftButton.pressed.connect(_on_left_pressed)
	%RightButton.pressed.connect(_on_right_pressed)
	%ClearButton.pressed.connect(_on_clear_pressed)
	%ExecuteButton.pressed.connect(_on_execute_pressed)
	%PrevButton.pressed.connect(_on_prev_pressed)
	%NextStepButton.pressed.connect(_on_next_pressed)
	%ResultButton.pressed.connect(_on_result_pressed)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `puzzle_minigame` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(puzzle_minigame: StackPuzzleMinigame, progress: String) -> void:
	minigame = puzzle_minigame
	%Progress.text = progress
	puzzle_minigame.puzzle_ready.connect(show_puzzle)
	puzzle_minigame.editor_changed.connect(show_editor)
	puzzle_minigame.simulation_ready.connect(show_simulation)
	puzzle_minigame.step_shown.connect(show_step)
	puzzle_minigame.simulation_invalid.connect(show_invalid)
	puzzle_minigame.output_mismatch.connect(show_mismatch)
	puzzle_minigame.feedback_ready.connect(show_feedback)


## UC-06.3: presents the puzzle with its initial state and an empty editor.
func show_puzzle(puzzle: StackPuzzle, attempts_left: int) -> void:
	_puzzle = puzzle
	_operations = []
	_selected = -1
	_step = null
	_step_index = 0
	_total_steps = 0
	_review = false
	_alert_text = ""
	_attempts_left = attempts_left
	_max_attempts = puzzle.max_attempts
	_end = StackOperation.DequeEnd.FRONT
	%DepartmentTag.text = DepartmentManager.get_department_name(puzzle.department)
	%Rules.text = RULES
	%Rules.show()
	%AlertBanner.hide()
	%EditorTitle.text = "Secuencia de operaciones"
	%EditorActions.show()
	%EndPicker.visible = puzzle.is_deque_level()
	_sync_end_picker()
	%ExecuteButton.show()
	%ExecuteButton.disabled = true
	%PrevButton.hide()
	%NextStepButton.hide()
	%ResultButton.hide()
	%Hint.text = EDIT_HINT
	%Attempts.custom_minimum_size.x = maxf(60.0, _max_attempts * 18.0)
	%Attempts.queue_redraw()
	_paint_initial()
	_build_ops()
	_update_editor_hint()
	$Feedback.hide()
	$PlayScreen.show()


## UC-06.4 / UC-06.5: every edit returns to the editor, discards the run and
## repaints the initial state.
func show_editor(operations: Array[StackOperation], can_execute: bool) -> void:
	_operations = operations.duplicate()
	_review = false
	_step = null
	_step_index = 0
	_total_steps = 0
	if _selected >= _operations.size():
		_selected = _operations.size() - 1
	if _operations.is_empty():
		_selected = -1
	%EditorTitle.text = "Secuencia de operaciones"
	%EditorActions.show()
	%EndPicker.visible = _puzzle != null and _puzzle.is_deque_level()
	_sync_end_picker()
	%ExecuteButton.show()
	%ExecuteButton.disabled = not can_execute
	%PrevButton.hide()
	%NextStepButton.hide()
	%ResultButton.hide()
	%AlertBanner.hide()
	_attempts_left = minigame.attempts_left
	%Attempts.queue_redraw()
	_paint_initial()
	_build_ops()
	_update_editor_hint()
	%Hint.text = EDIT_HINT


## UC-06.7: the execution is ready; the step navigation replaces the editor.
## The verdict stays hidden until the player asks for it with "Ver resultado".
func show_simulation(run: SimulationRun) -> void:
	_review = true
	_alert_text = ""
	_operations = minigame.operations.duplicate()
	_step_index = 0
	_total_steps = run.size()
	%EditorTitle.text = "Ejecución"
	%EditorActions.hide()
	%ExecuteButton.hide()
	%PrevButton.show()
	%NextStepButton.show()
	%ResultButton.show()
	%AlertBanner.hide()
	%Hint.text = REVIEW_HINT


## UC-06.7 / UC-06.7.a2: paints one snapshot of the simulation. It stays
## neutral: neither the invalid operation nor the attempts are revealed here.
func show_step(step: SimulationStep, index: int, total: int) -> void:
	_step = step
	_step_index = index
	_total_steps = total
	_review = true
	%EditorHint.text = "Paso %d de %d" % [index, total]
	_paint_state(step.input_state, step.stack_state, step.produced_state)
	_build_ops()
	%PrevButton.disabled = index <= 1
	%NextStepButton.disabled = index >= total
	%Hint.text = REVIEW_HINT


## UC-06.7.a1.2: caches the invalid operation for the verdict; the engine emits
## it as soon as the run starts, but the player learns about it later.
func show_invalid(index: int, cause: String, attempts_left: int) -> void:
	_alert_text = (("Operación %d inválida. %s; la simulación se detuvo en ese paso. "
			+ "Corrige la secuencia y vuelve a ejecutar. %s")
			% [index, cause, _attempts_suffix(attempts_left)]).strip_edges()
	_alert_is_error = true


## UC-06.8.a1.2: caches the mismatch for the verdict, same as above.
func show_mismatch(_produced: Array[int], _target: Array[int], attempts_left: int) -> void:
	_alert_text = ("La salida no coincide con el objetivo. Corrige la secuencia y vuelve a ejecutar. %s"
			% _attempts_suffix(attempts_left)).strip_edges()
	_alert_is_error = false


## UC-06.9: the feedback screen with the produced output, the target, a valid
## sequence and the explanation.
func show_feedback(
	produced: Array[int], target: Array[int],
	solution: Array[StackOperation], explanation: String
) -> void:
	var feedback := $Feedback
	if minigame.is_correct:
		feedback.show_result(true, "¡Puzzle resuelto!", "La salida coincide y todas las operaciones fueron válidas.")
	else:
		feedback.show_result(false, "Se agotaron los intentos", "La salida producida no coincide con el objetivo.")
	feedback.add_chips("Producida", produced, minigame.is_correct)
	feedback.add_chips("Objetivo", target, true)
	feedback.add_chips("Secuencia válida", _sequence_texts(solution), true)
	feedback.add_note(explanation)
	%PlayScreen.hide()
	feedback.show()


# ------------------------------------------------------------ player input

## Chip `+`: inserts at the end, so it clears the selection.
func _on_plus_pressed() -> void:
	_selected = -1
	_build_ops()
	_update_editor_hint()


## UC-06.4.a1: PUSH before the selected operation, or at the end. The selection
## is cleared so the next insertion appends instead of landing before the chip
## that was just added.
func _on_push_pressed() -> void:
	var position := _selected if _selected >= 0 else _operations.size()
	var end := _end if _puzzle != null and _puzzle.is_deque_level() else StackOperation.DequeEnd.NONE
	_selected = -1
	minigame.insert_operation(position, StackOperation.OperationKind.PUSH, end)
	_update_editor_hint()


## UC-06.4.a3: POP before the selected operation, or at the end (same cursor
## rule as PUSH).
func _on_pop_pressed() -> void:
	var position := _selected if _selected >= 0 else _operations.size()
	_selected = -1
	minigame.insert_operation(position, StackOperation.OperationKind.POP, StackOperation.DequeEnd.NONE)
	_update_editor_hint()


func _on_remove_pressed() -> void:
	if _selected < 0:
		return
	var index := _selected
	_selected = -1
	minigame.remove_operation(index)


func _on_left_pressed() -> void:
	if _selected <= 0:
		return
	var target := _selected - 1
	var from := _selected
	_selected = target
	minigame.move_operation(from, target)


func _on_right_pressed() -> void:
	if _selected < 0 or _selected >= _operations.size() - 1:
		return
	var target := _selected + 1
	var from := _selected
	_selected = target
	minigame.move_operation(from, target)


## UC-06.4.a6
func _on_clear_pressed() -> void:
	_selected = -1
	minigame.clear_operations()


func _on_end_front_pressed() -> void:
	_end = StackOperation.DequeEnd.FRONT
	_sync_end_picker()


func _on_end_rear_pressed() -> void:
	_end = StackOperation.DequeEnd.REAR
	_sync_end_picker()


## UC-06.6
func _on_execute_pressed() -> void:
	minigame.execute()


## UC-06.7.a2
func _on_prev_pressed() -> void:
	minigame.previous_step()


func _on_next_pressed() -> void:
	minigame.next_step()


## UC-06.9: the verdict. A correct run (or one with no attempts left) goes to
## the feedback; a wrong run with attempts left returns to the editor and shows
## the message that was cached during the review.
func _on_result_pressed() -> void:
	if minigame.is_correct or minigame.attempts_left == 0:
		minigame.show_result()
		return
	var text := _alert_text
	var is_error := _alert_is_error
	_alert_text = ""
	minigame.edit_sequence()
	if not text.is_empty():
		_show_alert(text, is_error)


func _on_operation_pressed(index: int) -> void:
	_selected = -1 if _selected == index else index
	_build_ops()
	_update_editor_hint()


# ------------------------------------------------------------------ drawing

## The attempts left as blue diamonds and the spent ones in grey.
func _draw_attempts() -> void:
	for i in _max_attempts:
		var center := Vector2(8.0 + i * 18.0, %Attempts.size.y * 0.5)
		var diamond := PackedVector2Array([
			center + Vector2(0, -6), center + Vector2(6, 0),
			center + Vector2(0, 6), center + Vector2(-6, 0),
		])
		%Attempts.draw_colored_polygon(diamond, BLUE if i < _attempts_left else GREY)


## Editor chips, or the numbered operations of the reviewed run.
func _build_ops() -> void:
	for child in %OpsFlow.get_children():
		child.queue_free()
	for i in _operations.size():
		%OpsFlow.add_child(_operation_chip(i))
	if not _review:
		%OpsFlow.add_child(_plus_chip())


func _operation_chip(index: int) -> Button:
	var operation := _operations[index]
	var push := not operation.is_pop()
	var bg := PUSH_BG if push else POP_BG
	var border := PUSH_BORDER if push else POP_BORDER
	var text_color := PUSH_TEXT if push else POP_TEXT
	var normal := _chip_style(bg, border, 1)
	var hover := _chip_style(bg, BLUE, 2)
	var button := Button.new()
	button.text = "%d  %s" % [index + 1, operation.to_text()]
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _bold)
	button.add_theme_font_size_override("font_size", 13)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	if _review:
		if index == _step_index - 1:
			normal = _chip_style(bg, BLUE, 2)
			hover = normal
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		if index < _step_index - 1:
			button.modulate.a = 0.55
		elif index > _step_index - 1:
			button.modulate.a = 0.42
	elif index == _selected:
		normal = _chip_style(bg, BLUE, 2)
		hover = normal
	_dress(button, normal, hover)
	if not _review:
		button.pressed.connect(_on_operation_pressed.bind(index))
	return button


func _plus_chip() -> Button:
	var normal := _chip_style(Color(0.988, 0.992, 1.0), Color(0.827, 0.871, 0.933), 1)
	var hover := _chip_style(Color(0.918, 0.945, 1.0), BLUE, 1)
	var button := Button.new()
	button.text = "+"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(34, 0)
	button.add_theme_font_override("font", _bold)
	button.add_theme_font_size_override("font_size", 14)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, GREY_DARK)
	_dress(button, normal, hover)
	button.tooltip_text = "Añadir al final"
	button.pressed.connect(_on_plus_pressed)
	return button


func _paint_initial() -> void:
	if _puzzle == null:
		return
	var empty_stack: Array[int] = []
	var empty_produced: Array[int] = []
	_paint_state(_puzzle.initial_input_state(), empty_stack, empty_produced)


## Repaints the three zones from a snapshot (or the initial state).
func _paint_state(input_state: Array, stack_state: Array, produced_state: Array) -> void:
	_paint_input(input_state)
	_paint_stack(stack_state)
	_paint_output(produced_state)


## The row shows the element that leaves next on the right. Queue delivers in
## order, so its chips are painted reversed; a Deque keeps the front on the left
## and the rear on the right, so both exits are marked. A Priority Queue keeps
## the authored arrival order and no marker: working out what leaves next is the
## point of the level, and the note carries the rule.
func _paint_input(input_state: Array) -> void:
	for child in %InputFlow.get_children():
		child.queue_free()
	if input_state.is_empty():
		%InputFlow.add_child(_cell("—", Color.WHITE, CELL_BORDER, GREY_DARK))
	elif _puzzle.is_priority_level():
		var remaining := {}
		for element in input_state:
			remaining[int(element)] = true
		for element in _puzzle.input_sequence:
			if remaining.has(int(element)):
				%InputFlow.add_child(_cell(str(int(element)), Color.WHITE, CELL_BORDER, INK))
	elif _puzzle.is_deque_level():
		%InputFlow.add_child(_flow_label("← frente"))
		for element in input_state:
			%InputFlow.add_child(_cell(str(int(element)), Color.WHITE, CELL_BORDER, INK))
		%InputFlow.add_child(_flow_label("final →"))
	else:
		for i in range(input_state.size() - 1, -1, -1):
			%InputFlow.add_child(_cell(str(int(input_state[i])), Color.WHITE, CELL_BORDER, INK))
		%InputFlow.add_child(_flow_label("sale →"))
	%InputCaption.text = _input_caption()
	var note := "%s · %d de %d en la entrada" % [
		_puzzle.get_delivery_rule(), input_state.size(), _puzzle.input_sequence.size()
	]
	if _puzzle.is_priority_level():
		note = "%s · orden de llegada · %d de %d en la entrada" % [
			_puzzle.get_delivery_rule(), input_state.size(), _puzzle.input_sequence.size()
		]
	%InputNote.text = note


## The Stack grows from the bottom slot up, so `stack_state` (bottom -> top) is
## painted with the top of the Stack highest on screen.
func _paint_stack(stack_state: Array) -> void:
	for child in %StackBox.get_children():
		child.queue_free()
	var top_first := stack_state.duplicate()
	top_first.reverse()
	var rows := maxi(_puzzle.input_sequence.size(), 3)
	var empty_rows := rows - top_first.size()
	for row in rows:
		var slot := row - empty_rows
		var element := int(top_first[slot]) if slot >= 0 else 0
		var label := Label.new()
		label.custom_minimum_size = Vector2(90, 24)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", _bold)
		label.add_theme_font_size_override("font_size", 13)
		if element > 0:
			label.text = str(element)
			label.add_theme_color_override("font_color", INK)
			label.add_theme_stylebox_override("normal", _stack_style(true))
		else:
			label.text = "·"
			label.add_theme_color_override("font_color", GREY_DARK)
			label.add_theme_stylebox_override("normal", _stack_style(false))
		%StackBox.add_child(label)
	var count := stack_state.size()
	%StackNote.text = "vacío · 0" if count == 0 else ("1 elemento" if count == 1 else "%d elementos" % count)
	%StackNote.remove_theme_color_override("font_color")


func _paint_output(produced_state: Array) -> void:
	for child in %TargetFlow.get_children():
		child.queue_free()
	for child in %ProducedFlow.get_children():
		child.queue_free()
	var target := _puzzle.target_output
	for element in target:
		%TargetFlow.add_child(_cell(str(int(element)), TARGET_BG, TARGET_BORDER, INK))
	if produced_state.is_empty():
		%ProducedFlow.add_child(_cell("—", Color.WHITE, CELL_BORDER, GREY_DARK))
	else:
		# Neutral during the review: the comparison belongs to the feedback.
		for element in produced_state:
			%ProducedFlow.add_child(_cell(str(int(element)), Color.WHITE, CELL_BORDER, INK))
	%OutputNote.text = "%d de %d" % [produced_state.size(), target.size()]


func _input_caption() -> String:
	match _puzzle.input_structure:
		StackPuzzle.InputStructure.DEQUE:
			return "Entrada · Deque (frente ← → final)"
		StackPuzzle.InputStructure.PRIORITY_QUEUE:
			if _puzzle.priority_mode == StackPuzzle.PriorityMode.MIN:
				return "Entrada · Priority Queue · mín"
			return "Entrada · Priority Queue · máx"
		_:
			return "Entrada · Queue"


func _update_editor_hint() -> void:
	var count := _operations.size()
	var base := "1 operación" if count == 1 else "%d operaciones" % count
	if _selected >= 0 and _selected < count:
		%EditorHint.text = "%s · operación %d seleccionada" % [base, _selected + 1]
	else:
		%EditorHint.text = base


func _sync_end_picker() -> void:
	%FrontButton.button_pressed = _end == StackOperation.DequeEnd.FRONT
	%RearButton.button_pressed = _end == StackOperation.DequeEnd.REAR


## Paints the cached verdict. It is only shown from the editor (wrong run with
## attempts left), never during the step-by-step simulation.
func _show_alert(text: String, is_error: bool) -> void:
	%AlertBanner.add_theme_stylebox_override("normal", _error_box if is_error else _warn_box)
	%AlertBanner.add_theme_color_override("font_color", ERROR_TEXT if is_error else WARN_TEXT)
	%AlertBanner.text = text
	%AlertBanner.show()


func _attempts_suffix(attempts_left: int) -> String:
	if attempts_left <= 0:
		return ""
	if attempts_left == 1:
		return "Te queda 1 intento."
	return "Te quedan %d intentos." % attempts_left


## The valid sequence as "PUSH 3" / "POP 8" chips, like the mockup.
func _sequence_texts(solution: Array[StackOperation]) -> Array:
	var items := []
	var run: SimulationRun = StackPuzzleSimulator.simulate(_puzzle, solution) if _puzzle != null else null
	for i in solution.size():
		var text := solution[i].to_text()
		var step := run.get_step(i + 1) if run != null else null
		if step != null and step.element > 0:
			text += " %d" % step.element
		items.append(text)
	return items


func _flow_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Muted"
	label.add_theme_font_size_override("font_size", 13)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _cell(text: String, bg: Color, border: Color, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(32, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _bold)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_stylebox_override("normal", _cell_style(bg, border))
	return label


func _chip_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


func _cell_style(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box


func _stack_style(filled: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	if filled:
		box.bg_color = STACK_FILL_BG
		box.border_color = STACK_FILL_BORDER
	else:
		box.bg_color = Color.WHITE
		box.border_color = STACK_EMPTY_BORDER
	return box


func _alert_style(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


func _dress(button: Button, normal: StyleBoxFlat, hover: StyleBoxFlat) -> void:
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["hover", "hover_pressed"]:
		button.add_theme_stylebox_override(state, hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
