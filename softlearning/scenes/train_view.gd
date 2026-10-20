extends Control
## UC-03 view: the instruction, the scrambled train and the timer
## (PlayScreen) and, once confirmed or out of time, the feedback.
##
## It follows the TrainMinigame it is given (sequence_ready, order_changed,
## time_updated, answered) and forwards the player's moves with move_wagon()
## and confirm(). A wagon moves by dragging it onto another position or by
## clicking it and then clicking the target position (mouse and touch,
## N03-2). Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

## Shown by SessionView under the pause menu (N03-4).
var pause_note := "Se conservan el orden actual de los vagones y el tiempo restante."
var minigame: TrainMinigame
var _order: Array[String] = []
## Wagon picked with a click, waiting for its target (-1: none).
var _selected := -1
## False when the feedback arrives before "Confirmar orden": time ran out.
var _confirmed := false


func _ready() -> void:
	%ConfirmButton.pressed.connect(_on_confirm_pressed)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `train` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(train: TrainMinigame, progress: String) -> void:
	minigame = train
	%Progress.text = progress
	train.sequence_ready.connect(show_sequence)
	train.order_changed.connect(show_order)
	train.time_updated.connect(update_timer)
	train.answered.connect(show_feedback)


## UC-03.2
func show_sequence(instruction: String, wagons: Array[String]) -> void:
	%DepartmentTag.text = DepartmentManager.get_department_name(minigame.department)
	%Instruction.text = instruction
	_confirmed = false
	_selected = -1
	_build_wagons(wagons)
	%Hint.text = "%d vagones · un solo orden correcto" % wagons.size()
	$Feedback.hide()
	$PlayScreen.show()


## UC-03.4
func show_order(order: Array[String]) -> void:
	_build_wagons(order)
	%Hint.text = "Ya acomodaste los vagones; confirma antes de que se acabe el tiempo."


## UC-03.3
func update_timer(time_left: float) -> void:
	%TimeLeft.text = str(ceili(time_left))


## UC-03.6, and UC-03.5.a1 when it arrives before the player confirmed.
func show_feedback(is_correct: bool, correct_order: Array[String]) -> void:
	var feedback := $Feedback
	if is_correct:
		feedback.show_result(true, "¡Orden correcto!", "Todos los vagones quedaron en su lugar.")
	elif _confirmed:
		feedback.show_result(false, "Orden incorrecto", "No hay crédito parcial: todos los vagones deben estar en su lugar.")
	else:
		feedback.show_result(false, "Respuesta incorrecta", "¡El tiempo se agotó! El orden se registró como incorrecto.")
	feedback.add_text("Instrucción", %Instruction.text)
	feedback.add_separator()
	if _confirmed:
		feedback.add_chips("Tu orden:", _numbered(_order), is_correct)
	if not is_correct:
		feedback.add_chips("Orden correcto:", _numbered(correct_order), true)
	$PlayScreen.hide()
	feedback.show()


func _build_wagons(order: Array[String]) -> void:
	_order = order
	for wagon in %Wagons.get_children():
		if wagon != %Locomotive:
			wagon.queue_free()
	for i in order.size():
		%Wagons.add_child(_make_wagon(i, order[i]))


## Number on top, the concept in a button, two wheels below.
func _make_wagon(index: int, text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var number := Label.new()
	number.text = str(index + 1)
	number.theme_type_variation = &"Muted"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number)
	var button := Button.new()
	button.theme_type_variation = &"Option"
	button.custom_minimum_size = Vector2(122, 76)
	button.toggle_mode = true
	button.tooltip_text = text
	# The text goes in a label of fixed width: a button inside a box
	# container would wrap it letter by letter.
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(112, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	button.add_child(label)
	button.button_pressed = index == _selected
	button.pressed.connect(_on_wagon_pressed.bind(index))
	button.set_drag_forwarding(_get_wagon_drag.bind(index, button), _can_drop_wagon, _drop_wagon.bind(index))
	box.add_child(button)
	var wheels := Control.new()
	wheels.custom_minimum_size = Vector2(122, 12)
	wheels.draw.connect(func():
		for x in [0.25, 0.75]:
			wheels.draw_circle(Vector2(wheels.size.x * x, 6), 6, Color(0.2, 0.255, 0.333)))
	box.add_child(wheels)
	return box


## Click a wagon, then click where it goes.
func _on_wagon_pressed(index: int) -> void:
	if _selected == -1:
		_selected = index
		_build_wagons(_order)
	elif _selected == index:
		_selected = -1
		_build_wagons(_order)
	else:
		var from := _selected
		_selected = -1
		_on_wagon_moved(from, index)


func _get_wagon_drag(_at: Vector2, index: int, button: Button) -> Variant:
	var preview := Button.new()
	preview.text = button.tooltip_text
	preview.theme_type_variation = &"Option"
	preview.custom_minimum_size = button.size
	preview.modulate.a = 0.8
	button.set_drag_preview(preview)
	return {"wagon": index}


func _can_drop_wagon(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("wagon")


func _drop_wagon(_at: Vector2, data: Variant, index: int) -> void:
	_selected = -1
	_on_wagon_moved(data.wagon, index)


## UC-03.4: a drag or the second click moved a wagon.
func _on_wagon_moved(from: int, to: int) -> void:
	minigame.move_wagon(from, to)


func _numbered(items: Array[String]) -> Array:
	var numbered := []
	for i in items.size():
		numbered.append("%d. %s" % [i + 1, items[i]])
	return numbered


## UC-03.5: the verdict comes back through `answered` -> show_feedback().
func _on_confirm_pressed() -> void:
	_confirmed = true
	minigame.confirm()
