class_name TutorialOverlay
extends Control
## UC-01 floating-window layer. It dims the screen, highlights one target and
## shows a white callout next to it.
##
## While it is visible it swallows every click (`mouse_filter = STOP`), so the
## buttons underneath cannot be pressed by accident. It decides which click is
## valid for the current step and emits the matching signal:
## - DEPARTMENTS: only a highlighted floor button -> `department_chosen`.
## - ELO: any click -> `screen_clicked`.
## - PLAY: only the start button -> `play_requested`.
## - FINAL: any click -> `final_confirmed`.
##
## The scene is instanced as the last child of `DepartmentView`, so it draws on
## top of both SelectScreen and DetailScreen.

signal department_chosen(department: Enums.Department)
signal screen_clicked()
signal play_requested()
signal final_confirmed()

const DIM_COLOR := Color(0.05, 0.07, 0.12, 0.72)
const GOLD := Color(1.0, 0.78, 0.18)
const CALLOUT_WIDTH := 340.0
const CALLOUT_MARGIN := 24.0
const TARGET_PADDING := 8.0
const ARROW_SIZE := 12.0

@onready var _callout: PanelContainer = $Callout
@onready var _title: Label = $Callout/Content/Title
@onready var _body: Label = $Callout/Content/Body

var _step: Enums.TutorialStep = Enums.TutorialStep.DONE
var _department_area: Control
var _department_buttons: Dictionary = {}
var _elo_target: Control
var _play_target: Control
var _target_rect := Rect2()
var _callout_rect := Rect2()
var _final_message := false
## Invalidates a layout pass that is waiting for the next frames.
var _layout_token := 0


## `department_buttons` maps an `Enums.Department` to the button that represents
## it; the overlay uses their global rectangles for hit-testing.
func configure(
	department_area: Control,
	department_buttons: Dictionary,
	elo_target: Control,
	play_target: Control
) -> void:
	_department_area = department_area
	_department_buttons = department_buttons
	_elo_target = elo_target
	_play_target = play_target
	resized.connect(_on_resized)


## UC-01.3 / UC-01.5 / UC-01.7: shows the callout for one step.
func show_step(step: Enums.TutorialStep) -> void:
	_step = step
	_final_message = false
	if step == Enums.TutorialStep.SESSION or step == Enums.TutorialStep.DONE:
		hide_overlay()
		return
	show()
	grab_focus()
	match step:
		Enums.TutorialStep.DEPARTMENTS:
			_set_copy(
				"Selecciona un departamento",
				"Cada piso es un departamento. Elige el que quieras para empezar."
			)
		Enums.TutorialStep.ELO:
			_set_copy(
				"Tu ELO",
				"El ELO mide tu nivel: sube cuando aciertas y baja cuando fallas. En «Tu histórico» verás cómo evoluciona tras cada partida."
			)
		Enums.TutorialStep.PLAY:
			_set_copy(
				"Empezar a jugar",
				"Pulsa «Comenzar Partida» para hacer tu primera sesión de 10 minijuegos."
			)
	_request_layout()


## UC-01.10: final floating window with the ELO change of the guided session.
func show_final_message(elo_delta: float) -> void:
	_step = Enums.TutorialStep.FINAL
	_final_message = true
	show()
	grab_focus()
	var sign_text := "+" if elo_delta >= 0.0 else "−"
	_set_copy(
		"¡Bienvenido a Softlearning!",
		"Tu primera sesión ha cambiado tu ELO en %s%d puntos.\n\nA partir de ahora puedes elegir cualquier departamento y jugar a tu ritmo. ¡Mucha suerte!"
			% [sign_text, absi(roundi(elo_delta))]
	)
	_request_layout()


## UC-01.11.e1: the tutorial completion could not be saved. The next click
## retries `complete()`; the tutorial will also appear again next launch.
func show_save_error(reason: String = "") -> void:
	_step = Enums.TutorialStep.FINAL
	_final_message = true
	show()
	grab_focus()
	var detail := reason.strip_edges()
	if detail.is_empty():
		detail = "No se pudo guardar el progreso del tutorial."
	_set_copy(
		"No se pudo guardar",
		"%s\n\nToca para volver a intentarlo. Si no funciona, el tutorial volverá a aparecer la próxima vez." % detail
	)
	_request_layout()


## Closes the layer and returns control to the department view (UC-01.12).
func hide_overlay() -> void:
	_layout_token += 1
	hide()
	_step = Enums.TutorialStep.DONE
	_final_message = false
	_target_rect = Rect2()
	_callout_rect = Rect2()
	_callout.modulate.a = 1.0
	_callout.hide()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	match _step:
		Enums.TutorialStep.DEPARTMENTS:
			var picked := _department_at(get_global_mouse_position())
			if picked >= 0:
				department_chosen.emit(picked)
		Enums.TutorialStep.ELO:
			screen_clicked.emit()
		Enums.TutorialStep.PLAY:
			if _target_rect.has_point(get_global_mouse_position()):
				play_requested.emit()
		Enums.TutorialStep.FINAL:
			final_confirmed.emit()
	accept_event()


func _on_resized() -> void:
	if visible:
		_request_layout()


# ------------------------------------------------------------------ layout

func _set_copy(title: String, body: String) -> void:
	_title.text = title
	_body.text = body
	_callout.custom_minimum_size.x = CALLOUT_WIDTH
	_callout.size = Vector2(CALLOUT_WIDTH, _callout.size.y)
	# It must stay visible (but transparent) while it is measured: an autowrapped
	# Label that was never laid out reports its height for a width of 0, one word
	# per line, and the panel would grow absurdly tall and cut the text.
	_callout.modulate.a = 0.0
	_callout.show()


## Waits for the containers to settle (the ELO chart is inside a tab that was
## just made visible) before measuring the target and placing the callout.
func _request_layout() -> void:
	_layout_token += 1
	var token := _layout_token
	await get_tree().process_frame
	await get_tree().process_frame
	if token == _layout_token and visible:
		_layout()


func _layout() -> void:
	_callout.custom_minimum_size.x = CALLOUT_WIDTH
	if _callout.size.x < CALLOUT_WIDTH:
		_callout.size.x = CALLOUT_WIDTH
	var minimum := _callout.get_combined_minimum_size()
	var callout_size := Vector2(maxf(CALLOUT_WIDTH, minimum.x), minimum.y)
	_callout.size = callout_size

	var target := _target_for_step()
	_target_rect = _target_rect_of(target)
	if _final_message or _target_rect.size.x <= 0.0:
		_callout.position = ((size - callout_size) * 0.5).floor()
	else:
		_place_callout(_target_rect, callout_size)
	_callout_rect = Rect2(_callout.position, _callout.size)
	_callout.modulate.a = 1.0
	queue_redraw()


func _target_for_step() -> Control:
	match _step:
		Enums.TutorialStep.DEPARTMENTS:
			return _department_area
		Enums.TutorialStep.ELO:
			return _elo_target
		Enums.TutorialStep.PLAY:
			return _play_target
		_:
			return null


func _target_rect_of(target: Control) -> Rect2:
	if target == null or not target.is_visible_in_tree():
		return Rect2()
	var rect := target.get_global_rect().grow(TARGET_PADDING)
	return rect.intersection(Rect2(Vector2.ZERO, size))


func _place_callout(target: Rect2, callout_size: Vector2) -> void:
	var place_left := target.get_center().x > size.x * 0.5
	var x: float
	if place_left:
		x = target.position.x - callout_size.x - CALLOUT_MARGIN
	else:
		x = target.end.x + CALLOUT_MARGIN
	var y := target.get_center().y - callout_size.y * 0.5
	x = clampf(x, CALLOUT_MARGIN, maxf(CALLOUT_MARGIN, size.x - callout_size.x - CALLOUT_MARGIN))
	y = clampf(y, CALLOUT_MARGIN, maxf(CALLOUT_MARGIN, size.y - callout_size.y - CALLOUT_MARGIN))
	_callout.position = Vector2(x, y).floor()


func _department_at(global_point: Vector2) -> int:
	for department in _department_buttons:
		var button := _department_buttons[department] as Control
		if button != null and button.is_visible_in_tree() and button.get_global_rect().has_point(global_point):
			return department
	return -1


# -------------------------------------------------------------------- draw

func _draw() -> void:
	if _target_rect.size.x <= 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), DIM_COLOR)
		return

	var hole := _target_rect
	draw_rect(Rect2(0.0, 0.0, size.x, hole.position.y), DIM_COLOR)
	draw_rect(Rect2(0.0, hole.end.y, size.x, maxf(0.0, size.y - hole.end.y)), DIM_COLOR)
	draw_rect(Rect2(0.0, hole.position.y, hole.position.x, hole.size.y), DIM_COLOR)
	draw_rect(Rect2(hole.end.x, hole.position.y, maxf(0.0, size.x - hole.end.x), hole.size.y), DIM_COLOR)
	draw_rect(hole, GOLD, false, 4.0)
	if not _final_message:
		_draw_arrow(hole)


func _draw_arrow(target: Rect2) -> void:
	if _callout_rect.size.x <= 0.0:
		return
	var y := clampf(
		target.get_center().y,
		_callout_rect.position.y + 18.0,
		_callout_rect.end.y - 18.0
	)
	if _callout_rect.end.x <= target.position.x:
		var x := _callout_rect.end.x
		draw_colored_polygon(
			PackedVector2Array([Vector2(x, y - 9.0), Vector2(x, y + 9.0), Vector2(x + ARROW_SIZE, y)]),
			GOLD
		)
	elif _callout_rect.position.x >= target.end.x:
		var x := _callout_rect.position.x
		draw_colored_polygon(
			PackedVector2Array([Vector2(x, y - 9.0), Vector2(x, y + 9.0), Vector2(x - ARROW_SIZE, y)]),
			GOLD
		)
