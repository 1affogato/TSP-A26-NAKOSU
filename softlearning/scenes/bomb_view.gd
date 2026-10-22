extends Control
## UC-04 view: the bomb with its countdown and locks, the question of the
## current lock and its three wires (PlayScreen) and, at the end, the
## feedback.
##
## It follows the BombMinigame it is given (question_ready, time_updated,
## lock_deactivated, answered) and forwards each cut with cut_wire(). A wire
## is cut with a click or a tap (N04-2). Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

const WIRE_COLORS := [Color(0.937, 0.267, 0.267), Color(0.918, 0.702, 0.031), Color(0.231, 0.51, 0.965)]
const LOCK_CURRENT := Color(0.145, 0.388, 0.922)
const LOCK_DONE := Color(0.086, 0.5, 0.24)
const LOCK_IDLE := Color(0.2, 0.255, 0.333)

## Shown by SessionView under the pause menu (N04-4).
var pause_note := "Se conservan el tiempo restante, los candados ya desactivados y la pregunta actual."
var minigame: BombMinigame
## Every question shown so far, in order (the feedback lists them).
var _questions: Array[BombQuestion] = []
## Text of the wire the player cut last ("" when the countdown ran out).
var _cut_wire := ""
var _total_locks := 3


func _ready() -> void:
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `bomb` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(bomb: BombMinigame, progress: String) -> void:
	minigame = bomb
	%Progress.text = progress
	bomb.question_ready.connect(show_question)
	bomb.time_updated.connect(update_countdown)
	bomb.answered.connect(show_feedback)


## UC-04.2 / UC-04.7
func show_question(question: BombQuestion, locks_left: int) -> void:
	if _questions.is_empty():
		_total_locks = locks_left
		%DepartmentTag.text = DepartmentManager.get_department_name(minigame.department)
		$Feedback.hide()
		$PlayScreen.show()
	_questions.append(question)
	_cut_wire = ""
	var number := _total_locks - locks_left + 1
	%LockCaption.text = "Candado %d de %d" % [number, _total_locks]
	%Question.text = question.text
	%Defused.visible = number > 1
	%Defused.text = "Candado %d desactivado" % (number - 1)
	_build_locks(number)
	_build_wires(question)


## UC-04.3 / N04-1: the countdown stays visible.
func update_countdown(time_left: float) -> void:
	var clock := _clock(time_left)
	%Countdown.text = clock
	%TimeLeft.text = clock


## UC-04.9, UC-04.5.a1 and UC-04.4.a1.
func show_feedback(is_correct: bool, correct_wire: String) -> void:
	var feedback := $Feedback
	var current: BombQuestion = _questions.back()
	if is_correct:
		feedback.show_result(true, "¡Bomba desactivada!", "Desactivaste los %d candados con %s restantes." % [_total_locks, _clock(minigame.time_left)])
		for i in _questions.size():
			if i > 0:
				feedback.add_separator()
			feedback.add_text("Candado %d" % (i + 1), _questions[i].text)
			feedback.add_chips("Respuesta:", [_questions[i].get_correct_wire()], true)
	elif not _cut_wire.is_empty():
		feedback.show_result(false, "¡La bomba explotó!", "Cortaste un cable incorrecto.")
		feedback.add_text("Candado %d de %d" % [_questions.size(), _total_locks], current.text)
		feedback.add_chips("Cable cortado:", [_cut_wire], false)
		feedback.add_chips("Cable correcto:", [correct_wire], true)
	else:
		feedback.show_result(false, "Se acabó el tiempo", "La cuenta regresiva llegó a 00:00 antes de desactivar los %d candados." % _total_locks)
		feedback.add_text("Candado %d de %d" % [_questions.size(), _total_locks], current.text)
		feedback.add_chips("Cable correcto:", [correct_wire], true)
	$PlayScreen.hide()
	feedback.show()


## The list on the bomb: done, current, still locked.
func _build_locks(current: int) -> void:
	for row in %Locks.get_children():
		row.queue_free()
	for i in range(1, _total_locks + 1):
		var label := Label.new()
		var color := LOCK_IDLE
		label.text = "Candado %d" % i
		if i < current:
			color = LOCK_DONE
			label.text += " · desactivado"
		elif i == current:
			color = LOCK_CURRENT
			label.text += " · actual"
		label.add_theme_color_override("font_color", Color.WHITE if i <= current else Color(0.6, 0.65, 0.72))
		label.add_theme_font_size_override("font_size", 13)
		var box := StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(6)
		box.content_margin_left = 10
		box.content_margin_right = 10
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		label.add_theme_stylebox_override("normal", box)
		%Locks.add_child(label)


## One row per wire: the colored cable and the answer it carries. Clicking
## either cuts it.
func _build_wires(question: BombQuestion) -> void:
	for row in %Wires.get_children():
		row.queue_free()
	for i in question.wires.size():
		var wire_text := question.wires[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var cable := Button.new()
		cable.flat = true
		cable.custom_minimum_size = Vector2(160, 28)
		cable.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cable.size_flags_stretch_ratio = 0.6
		var color: Color = WIRE_COLORS[i % WIRE_COLORS.size()]
		cable.draw.connect(_draw_cable.bind(cable, color))
		var answer := Button.new()
		answer.text = wire_text
		answer.theme_type_variation = &"Option"
		answer.alignment = HORIZONTAL_ALIGNMENT_LEFT
		answer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answer.custom_minimum_size = Vector2(0, 44)
		answer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cable.pressed.connect(_on_wire_cut.bind(wire_text, cable))
		answer.pressed.connect(_on_wire_cut.bind(wire_text, cable))
		row.add_child(cable)
		row.add_child(answer)
		%Wires.add_child(row)


## The cable with its two plugs; a cut cable shows a gap in the middle.
func _draw_cable(cable: Button, color: Color) -> void:
	var y := cable.size.y / 2.0
	var w := cable.size.x
	var plug := Color(0.2, 0.255, 0.333)
	cable.draw_rect(Rect2(0, y - 9, 8, 18), plug)
	cable.draw_rect(Rect2(w - 8, y - 9, 8, 18), plug)
	if cable.has_meta("cut"):
		cable.draw_rect(Rect2(8, y - 4, w / 2.0 - 22, 8), color)
		cable.draw_rect(Rect2(w / 2.0 + 14, y - 4, w / 2.0 - 22, 8), color)
	else:
		cable.draw_rect(Rect2(8, y - 4, w - 16, 8), color)


## UC-04.4: a cut cannot be undone (R04-6).
func _on_wire_cut(wire: String, cable: Button) -> void:
	if minigame.paused or cable.has_meta("cut"):
		return
	cable.set_meta("cut", true)
	cable.queue_redraw()
	_cut_wire = wire
	minigame.cut_wire(wire)


func _clock(seconds: float) -> String:
	var total := ceili(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
