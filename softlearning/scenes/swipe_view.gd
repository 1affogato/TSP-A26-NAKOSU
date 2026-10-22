extends Control
## UC-08 view: the card between its two categories (PlayScreen) and, once
## swiped, the feedback.
##
## It follows the SwipeMinigame it is given (card_ready, answered). The card
## follows the pointer (mouse or finger) and the category it heads to lights
## up; released past the threshold (R08-4) it calls minigame.swipe(),
## otherwise it slides back to the center and nothing is recorded
## (UC-08.3.a1). The left and right arrow keys swipe too (N08-1).
## Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

## Offset (px) at which the category the card heads to lights up.
const HIGHLIGHT_AT := 24.0
## Degrees of tilt per pixel dragged, and the most it tilts.
const TILT_PER_PIXEL := 0.03
const MAX_TILT := 12.0
## Seconds the card takes to slide back after an incomplete swipe.
const RETURN_TIME := 0.2

## Shown by SessionView under the pause menu (N08-4).
var pause_note := "Se conserva la tarjeta que se está mostrando."
var minigame: SwipeMinigame
var _card_data: SwipeCard
## R08-2: the category on each side, drawn at random for this card.
var _left: SwipeCard.SwipeCategory
var _right: SwipeCard.SwipeCategory
var _chosen: SwipeCard.SwipeCategory
var _dragging := false
var _drag_start := 0.0
var _offset := 0.0
var _done := false


func _ready() -> void:
	%Card.gui_input.connect(_on_card_input)
	%CardArea.resized.connect(_place_card)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `swipe` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(swipe: SwipeMinigame, progress: String) -> void:
	minigame = swipe
	%Progress.text = progress
	swipe.card_ready.connect(_on_card_ready)
	swipe.answered.connect(show_feedback)


## UC-08.2: reads the card as the sequence diagram does, then shows it.
func _on_card_ready(card: SwipeCard) -> void:
	_card_data = card
	%DepartmentTag.text = DepartmentManager.get_department_name(card.department)
	%Concept.text = card.get_concept().to_upper()
	show_card(card.get_example_text(), card.get_categories())


## UC-08.2: the example in the middle and one category on each side, the side
## drawn at random (R08-2).
func show_card(example_text: String, categories: Array[SwipeCard.SwipeCategory]) -> void:
	_done = false
	var sides := categories.duplicate()
	sides.shuffle()
	_left = sides[0]
	_right = sides[1]
	%LeftName.text = SwipeCard.category_name(_left)
	%RightName.text = SwipeCard.category_name(_right)
	%Example.text = "“%s”" % example_text
	_set_offset(0.0)
	$Feedback.hide()
	$PlayScreen.show()


## UC-08.4
func show_feedback(is_correct: bool, correct_category: SwipeCard.SwipeCategory) -> void:
	var feedback := $Feedback
	if is_correct:
		feedback.show_result(true, "¡Correcto!", "El ejemplo pertenece a la categoría que elegiste.")
	else:
		feedback.show_result(false, "Incorrecto", "El ejemplo pertenece a otra categoría.")
	feedback.add_text("Ejemplo", "“%s”" % _card_data.get_example_text())
	feedback.add_separator()
	feedback.add_chips("Tu elección:", [SwipeCard.category_name(_chosen)], is_correct)
	if not is_correct:
		feedback.add_chips("Categoría correcta:", [SwipeCard.category_name(correct_category)], true)
	$PlayScreen.hide()
	feedback.show()


## N08-1: the arrow keys swipe straight to that side.
func _unhandled_input(event: InputEvent) -> void:
	if _done or minigame == null or minigame.paused or not $PlayScreen.visible:
		return
	if event.is_action_pressed("ui_left"):
		_on_card_swiped(_left)
	elif event.is_action_pressed("ui_right"):
		_on_card_swiped(_right)


## UC-08.3: drag with the mouse or a finger (touch arrives as mouse events).
func _on_card_input(event: InputEvent) -> void:
	if _done or minigame.paused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start = event.global_position.x - _offset
		elif _dragging:
			_dragging = false
			_release()
	elif event is InputEventMouseMotion and _dragging:
		_set_offset(event.global_position.x - _drag_start)


## R08-4: only past a third of the screen width from the center.
func _release() -> void:
	var threshold := get_viewport_rect().size.x / 3.0
	if absf(_offset) >= threshold:
		_on_card_swiped(_left if _offset < 0.0 else _right)
	else:
		# UC-08.3.a1: back to the center, no answer recorded.
		create_tween().tween_method(_set_offset, _offset, 0.0, RETURN_TIME)


## UC-08.3: the swipe that counts goes to the engine.
func _on_card_swiped(category: SwipeCard.SwipeCategory) -> void:
	_done = true
	_chosen = category
	minigame.swipe(category)


## Moves and tilts the card and lights up the category it heads to.
func _set_offset(value: float) -> void:
	_offset = value
	_place_card()
	%Card.rotation = deg_to_rad(clampf(value * TILT_PER_PIXEL, -MAX_TILT, MAX_TILT))
	%LeftCategory.button_pressed = value < -HIGHLIGHT_AT
	%RightCategory.button_pressed = value > HIGHLIGHT_AT


func _place_card() -> void:
	var card: Control = %Card
	card.size = card.get_combined_minimum_size()
	card.pivot_offset = card.size / 2.0
	card.position = (%CardArea.size - card.size) / 2.0 + Vector2(_offset, 0.0)
