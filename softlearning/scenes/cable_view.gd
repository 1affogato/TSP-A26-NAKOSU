extends Control
## UC-10 view: the board with its two columns (the concepts on the left and the
## examples scrambled on the right), the cables the player draws between them
## and, at the end, the feedback.
##
## It follows the CableMinigame it is given (board_ready, connections_changed,
## answered) and forwards each cable with connect_pair() and the closing with
## confirm(). A cable is drawn by clicking a concept and then an example (or the
## other way round) or by dragging one onto the other; a connection can be
## changed until the board is confirmed (UC-10.A1). Pause and exit belong to
## SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

## Side of the board an item belongs to.
enum Side { NONE, CONCEPT, EXAMPLE }

## One color per concept, so a cable keeps its color when it is moved.
const CABLE_COLORS := [
	Color(0.145, 0.388, 0.922),
	Color(0.086, 0.639, 0.29),
	Color(0.918, 0.702, 0.031),
	Color(0.863, 0.149, 0.149),
	Color(0.545, 0.361, 0.965),
]
## How many straight segments each cable is drawn with.
const CABLE_STEPS := 24
const PLUG := Color(0.2, 0.255, 0.333)

const HINT := "Haz clic en un concepto y luego en su ejemplo (o al revés) para tender el cable; también puedes arrastrarlo. Puedes cambiar cualquier conexión antes de confirmar."

## Shown by SessionView under the pause menu (UC-10.A2).
var pause_note := "Se conservan las conexiones que ya hiciste."
var minigame: CableMinigame
## Left column, in board order.
var _concepts: Array[String] = []
## Right column, as the engine scrambled it (UC-10.2).
var _examples: Array[String] = []
## What the player connected: concept index -> index in `_examples`.
var _connections := {}
## Item picked with a click, waiting for its partner.
var _held_side := Side.NONE
var _held_index := -1
var _concept_buttons: Array[Button] = []
var _example_buttons: Array[Button] = []


func _ready() -> void:
	%ConfirmButton.pressed.connect(_on_confirm_pressed)
	%Wires.draw.connect(_draw_cables)
	%Wires.resized.connect(_refresh_cables)
	%Concepts.resized.connect(_refresh_cables)
	%Examples.resized.connect(_refresh_cables)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `cable` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(cable: CableMinigame, progress: String) -> void:
	minigame = cable
	%Progress.text = progress
	cable.board_ready.connect(show_board)
	cable.connections_changed.connect(show_connections)
	cable.answered.connect(show_feedback)


## UC-10.2
func show_board(concepts: Array[String], examples: Array[String]) -> void:
	_concepts = concepts
	_examples = examples
	_connections = {}
	_held_side = Side.NONE
	_held_index = -1
	%DepartmentTag.text = DepartmentManager.get_department_name(minigame.department)
	%PairsLeft.text = "0 de %d cables" % _concepts.size()
	%ConfirmButton.disabled = true
	%Hint.text = HINT
	_build_columns()
	$Feedback.hide()
	$PlayScreen.show()
	_refresh_cables()


## UC-10.4 / UC-10.A1.2 / UC-10.5
func show_connections(connections: Dictionary, is_complete: bool) -> void:
	_connections = connections
	%PairsLeft.text = "%d de %d cables" % [_connections.size(), _concepts.size()]
	%ConfirmButton.disabled = not is_complete
	%Hint.text = "Todos los conceptos tienen su cable: ya puedes confirmar." if is_complete else HINT
	_paint_buttons()
	_refresh_cables()


## UC-10.8: which cables were right and, for the wrong ones, the right pairing.
func show_feedback(is_correct: bool, correct_connections: Dictionary) -> void:
	var feedback := $Feedback
	_held_side = Side.NONE
	_held_index = -1
	if is_correct:
		feedback.show_result(true, "¡Cables conectados!", "Cada concepto quedó unido a su ejemplo.")
	else:
		var right := 0
		for concept_index in _concepts.size():
			if _connections.get(concept_index, -1) == correct_connections.get(concept_index, -2):
				right += 1
		feedback.show_result(
			false,
			"Conexiones incorrectas",
			"%d de %d cables quedaron bien." % [right, _concepts.size()]
		)
	for concept_index in _concepts.size():
		var caption := "%d. %s" % [concept_index + 1, _concepts[concept_index]]
		var mine: int = _connections.get(concept_index, -1)
		var right_index: int = correct_connections.get(concept_index, -1)
		if mine == right_index:
			feedback.add_chips(caption, [_example_text(right_index)], true)
			continue
		feedback.add_chips(caption, [_example_text(mine)], false)
		feedback.add_chips("Correcto:", [_example_text(right_index)], true)
	$PlayScreen.hide()
	feedback.show()


## Both columns, one Option button per item. Connections are painted later, so
## the buttons survive every change instead of being rebuilt.
func _build_columns() -> void:
	_concept_buttons.clear()
	_example_buttons.clear()
	for child in %Concepts.get_children():
		child.queue_free()
	for child in %Examples.get_children():
		child.queue_free()
	for concept_index in _concepts.size():
		var button := _make_item(_concepts[concept_index], Side.CONCEPT, concept_index)
		%Concepts.add_child(button)
		_concept_buttons.append(button)
	for example_index in _examples.size():
		var button := _make_item(_examples[example_index], Side.EXAMPLE, example_index)
		%Examples.add_child(button)
		_example_buttons.append(button)


func _make_item(text: String, side: int, index: int) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = &"Option"
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_text(button)
	button.pressed.connect(_on_item_pressed.bind(side, index))
	button.set_drag_forwarding(
		_get_item_drag.bind(side, index, button), _can_drop_item.bind(side), _drop_item.bind(side, index)
	)
	return button


## UC-10.3: click a concept and then its example, or the other way round. A
## second click on the same item lets it go; picking another item on the same
## side moves the selection there.
func _on_item_pressed(side: int, index: int) -> void:
	if minigame.paused:
		return
	var same_item := _held_side == side and _held_index == index
	if same_item or _held_side == Side.NONE or _held_side == side:
		_held_side = Side.NONE if same_item else side
		_held_index = -1 if same_item else index
		_paint_buttons()
		return
	var concept_index := index if side == Side.CONCEPT else _held_index
	var example_index := index if side == Side.EXAMPLE else _held_index
	_held_side = Side.NONE
	_held_index = -1
	_on_connected(concept_index, example_index)


func _get_item_drag(_at: Vector2, side: int, index: int, button: Button) -> Variant:
	button.set_drag_preview(_preview(button.text))
	return {"side": side, "index": index}


## Only the other column is a valid target: a concept has no cable to another
## concept.
func _can_drop_item(_at: Vector2, data: Variant, side: int) -> bool:
	return data is Dictionary and data.has("side") and data.side != side


## A cable dropped from the other column (UC-10.3). Dropping it back on its own
## column does nothing: that would connect a concept to a concept.
func _drop_item(_at: Vector2, data: Variant, side: int, index: int) -> void:
	if not data is Dictionary or not data.has("side"):
		return
	if data.side == side:
		return
	_held_side = Side.NONE
	_held_index = -1
	if side == Side.EXAMPLE:
		_on_connected(data.index, index)
	else:
		_on_connected(index, data.index)


## UC-10.3 / UC-10.A1: a cable between these two items (the engine replaces
## whatever was on either end).
func _on_connected(concept_index: int, example_index: int) -> void:
	minigame.connect_pair(concept_index, example_index)


## Which items are connected and which one is waiting for its partner.
func _paint_buttons() -> void:
	for concept_index in _concept_buttons.size():
		var held := _held_side == Side.CONCEPT and _held_index == concept_index
		_concept_buttons[concept_index].button_pressed = held or _connections.has(concept_index)
	var connected_examples: Array = _connections.values()
	for example_index in _example_buttons.size():
		var held := _held_side == Side.EXAMPLE and _held_index == example_index
		_example_buttons[example_index].button_pressed = held or connected_examples.has(example_index)


func _refresh_cables() -> void:
	if is_instance_valid(%Wires):
		%Wires.queue_redraw()


## One cable per connection: a curve from the right edge of the concept to the
## left edge of its example, with a plug at each end. The positions come from
## the buttons themselves, so the cables follow any resize or reflow.
func _draw_cables() -> void:
	var wires: Control = %Wires
	var origin := wires.get_global_rect().position
	for concept_index in _connections.keys():
		var example_index: int = _connections[concept_index]
		if concept_index < 0 or concept_index >= _concept_buttons.size():
			continue
		if example_index < 0 or example_index >= _example_buttons.size():
			continue
		var concept_rect: Rect2 = _concept_buttons[concept_index].get_global_rect()
		var example_rect: Rect2 = _example_buttons[example_index].get_global_rect()
		var start := Vector2(concept_rect.end.x, concept_rect.get_center().y) - origin
		var finish := Vector2(example_rect.position.x, example_rect.get_center().y) - origin
		var color: Color = CABLE_COLORS[concept_index % CABLE_COLORS.size()]
		var points := _curve(start, finish)
		# A dark sheath under a bright core, so it reads as a cable and not a line.
		wires.draw_polyline(points, color.darkened(0.35), 9.0, true)
		wires.draw_polyline(points, color, 5.0, true)
		for end in [start, finish]:
			wires.draw_circle(end, 6.0, PLUG)
			wires.draw_circle(end, 3.5, color)


func _curve(start: Vector2, finish: Vector2) -> PackedVector2Array:
	var reach := maxf((finish.x - start.x) * 0.5, 24.0)
	var control_a := start + Vector2(reach, 0.0)
	var control_b := finish - Vector2(reach, 0.0)
	var points := PackedVector2Array()
	for step in CABLE_STEPS + 1:
		var t := float(step) / CABLE_STEPS
		points.append(start.bezier_interpolate(control_a, control_b, finish, t))
	return points


func _example_text(index: int) -> String:
	if index < 0 or index >= _examples.size():
		return ""
	return _examples[index]


## The "Option" style keeps 64 px on the left for the quiz's A-D badge. Here
## there is no badge, so the text would sit off-center: same style, even margins.
func _center_text(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := ThemeDB.get_project_theme().get_stylebox(state, &"Option").duplicate() as StyleBoxFlat
		box.content_margin_left = 16.0
		box.content_margin_right = 16.0
		button.add_theme_stylebox_override(state, box)


func _preview(text: String) -> Control:
	var label := Button.new()
	label.text = text
	label.theme_type_variation = &"Option"
	label.custom_minimum_size = Vector2(220, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_text(label)
	label.modulate.a = 0.85
	return label


## UC-10.6: the verdict comes back through `answered` -> show_feedback().
func _on_confirm_pressed() -> void:
	minigame.confirm()
