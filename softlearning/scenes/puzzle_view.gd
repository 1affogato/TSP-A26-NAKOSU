extends Control
## UC-05 view: the categories of the board with their slots, the tray and the
## checks left (PlayScreen) and, at the end, the feedback with the category of
## every piece and the decoys.
##
## It follows the PuzzleMinigame it is given (puzzle_ready, board_changed,
## check_failed, answered) and forwards the player's moves with
## place_piece(), move_to_tray() and check(). A piece moves by dragging it
## onto a slot (or back onto the tray), or by clicking it and then the slot
## or the tray (mouse and touch). Locked pieces cannot be picked up.
## Pause and exit belong to SessionView.

## "Volver al departamento": SessionView ends the session (UC-02.4.a2).
signal exit_requested
## "Siguiente minijuego": SessionView moves the session on (UC-02.7).
signal next_requested

const BLUE := Color(0.145, 0.388, 0.922)
const BLUE_DARK := Color(0.114, 0.306, 0.847)
const BLUE_BG := Color(0.937, 0.965, 1.0)
const BLUE_HELD := Color(0.859, 0.918, 0.996)
const BLUE_TEXT := Color(0.118, 0.227, 0.541)
const GREEN := Color(0.086, 0.639, 0.29)
const GREEN_BG := Color(0.941, 0.992, 0.957)
const GREEN_TEXT := Color(0.086, 0.396, 0.204)
const GREY := Color(0.796, 0.835, 0.882)
const GREY_DARK := Color(0.58, 0.639, 0.722)
const INK := Color(0.118, 0.161, 0.231)
const PANEL_BG := Color(0.973, 0.98, 0.988)
const PANEL_BORDER := Color(0.886, 0.91, 0.941)

## Shown by SessionView under the pause menu.
var pause_note := "Se conservan las piezas colocadas, las piezas fijas y los intentos que quedan."
var minigame: PuzzleMinigame
var _puzzle: ConceptPuzzle
## Slot index -> piece, as the engine last reported it.
var _placements: Dictionary = {}
var _tray: Array[PuzzlePiece] = []
var _locked: Array[int] = []
var _checks_left := 0
## Piece picked with a click, waiting for its slot (-1: none).
var _held := -1
## Whether a check already failed (changes the hints).
var _failed := false
## Hint for the next redraw only ("" when none).
var _note := ""
var _bold: Font
## Look of slots and pieces: "empty", "filled", "held", "locked" -> [normal, hover].
var _looks := {}
var _category_box: StyleBoxFlat


func _ready() -> void:
	_bold = get_theme_font(&"font", &"Badge")
	# A picked-up piece looks lifted, like the dragged piece of the mockup.
	var lifted := _box(BLUE_HELD, BLUE_DARK)
	lifted.shadow_color = Color(BLUE, 0.35)
	lifted.shadow_size = 6
	lifted.shadow_offset = Vector2(0, 3)
	_looks = {
		"empty": [_box(Color.WHITE, GREY), _box(BLUE_BG, BLUE)],
		"filled": [_box(BLUE_BG, BLUE), _box(BLUE_HELD, BLUE_DARK)],
		"held": [lifted, lifted],
		"locked": [_box(GREEN_BG, GREEN), _box(GREEN_BG, GREEN)],
	}
	_category_box = _box(PANEL_BG, PANEL_BORDER, 1, 14)
	_category_box.content_margin_top = 10
	_category_box.content_margin_bottom = 10
	%CheckButton.pressed.connect(_on_check_pressed)
	%Checks.draw.connect(_draw_checks)
	%TrayPanel.gui_input.connect(_on_tray_input)
	%TrayPanel.set_drag_forwarding(Callable(), _can_drop_on_tray, _drop_on_tray)
	$Feedback.home_pressed.connect(exit_requested.emit)
	$Feedback.next_pressed.connect(next_requested.emit)


## Follows `puzzle_minigame` from now on. `progress` is the "Minijuego X de Y" text.
func set_minigame(puzzle_minigame: PuzzleMinigame, progress: String) -> void:
	minigame = puzzle_minigame
	%Progress.text = progress
	puzzle_minigame.puzzle_ready.connect(show_puzzle)
	puzzle_minigame.board_changed.connect(show_board)
	puzzle_minigame.check_failed.connect(show_check_failed)
	puzzle_minigame.answered.connect(show_feedback)


## UC-05.2
func show_puzzle(puzzle: ConceptPuzzle, tray: Array[PuzzlePiece], checks_left: int) -> void:
	_puzzle = puzzle
	_tray = tray
	_placements = {}
	_locked = []
	_checks_left = checks_left
	_held = -1
	_failed = false
	_note = ""
	%DepartmentTag.text = DepartmentManager.get_department_name(puzzle.department)
	%Rules.text = _rules(puzzle.decoys.size())
	%Rules.show()
	%Checks.queue_redraw()
	%FailBanner.hide()
	%CheckButton.disabled = true
	_refresh()
	$Feedback.hide()
	$PlayScreen.show()


## UC-05.4 and UC-05.3.a1 to a3: the board after every move.
func show_board(placements: Dictionary, tray: Array[PuzzlePiece], can_check: bool) -> void:
	_placements = placements
	_tray = tray
	%CheckButton.disabled = not can_check
	_refresh()


## UC-05.7.a1: the right pieces are now locked and the wrong ones went back
## to the tray (board_changed redraws them right after); the banner says how
## many and how many checks are left.
func show_check_failed(locked_slots: Array[int], checks_left: int) -> void:
	_failed = true
	_locked = locked_slots
	_checks_left = checks_left
	%Checks.queue_redraw()
	var returned := _puzzle.slot_count() - locked_slots.size()
	var pieces := "1 pieza no iba ahí y regresó" if returned == 1 else "%d piezas no iban ahí y regresaron" % returned
	var left := "Te queda 1 intento." if checks_left == 1 else "Te quedan %d intentos." % checks_left
	%FailBanner.text = "%s a la bandeja. %s" % [pieces, left]
	# The rules were read already: the banner takes their place, so the tray
	# with the returned pieces stays in view.
	%Rules.hide()
	%FailBanner.show()


## UC-05.8, or UC-05.7.a2: the category of every piece and the decoys, plus
## the pieces that were misplaced in the last check.
func show_feedback(is_correct: bool, puzzle: ConceptPuzzle, placements: Dictionary) -> void:
	var feedback := $Feedback
	if is_correct:
		feedback.show_result(true, "¡Rompecabezas completo!", "Todas las piezas quedaron en su categoría.")
	else:
		feedback.show_result(false, "Se acabaron los intentos", "Así se armaba el rompecabezas.")
	for category in puzzle.categories:
		feedback.add_chips(category.name, category.pieces, true)
	if not puzzle.decoys.is_empty():
		if is_correct:
			feedback.add_note(_decoys_note(puzzle.decoys))
		else:
			feedback.add_chips("Trampas (ninguna categoría)", puzzle.decoys, false)
	if not is_correct:
		var wrong: Array[int] = []
		for slot in placements:
			if placements[slot].category != puzzle.category_of_slot(slot):
				wrong.append(slot)
		wrong.sort()
		feedback.add_separator()
		feedback.add_text("Tu última revisión", "%d de %d piezas estaban en su categoría."
				% [placements.size() - wrong.size(), placements.size()])
		for slot in wrong:
			var piece: PuzzlePiece = placements[slot]
			var caption := piece.text + (" (trampa)" if piece.is_decoy() else "")
			feedback.add_chips(caption, ["Tu lugar: %s" % puzzle.category_of_slot(slot)], false)
	$PlayScreen.hide()
	feedback.show()


func _refresh() -> void:
	_build_board()
	_build_tray()
	_update_hint()


## One column per category, each with its slots (numbered across columns).
func _build_board() -> void:
	for column in %Board.get_children():
		column.queue_free()
	var slot := 0
	for category in _puzzle.categories:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 5)
		var title := Label.new()
		title.text = category.name
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.add_theme_font_override("font", _bold)
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", INK)
		box.add_child(title)
		for i in category.pieces.size():
			box.add_child(_make_slot(slot))
			slot += 1
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _category_box)
		panel.add_child(box)
		%Board.add_child(panel)


## An empty slot, a placed piece (blue, movable) or a locked one (green). A
## panel and not a button, so a long text wraps and the slot grows with it.
func _make_slot(slot: int) -> PanelContainer:
	var piece: PuzzlePiece = _placements.get(slot)
	var locked := _locked.has(slot)
	var look := "empty"
	if piece:
		look = "locked" if locked else ("held" if piece.id == _held else "filled")
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(0, 38)
	box.mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
	box.add_theme_stylebox_override("panel", _looks[look][0])
	box.mouse_entered.connect(box.add_theme_stylebox_override.bind("panel", _looks[look][1]))
	box.mouse_exited.connect(box.add_theme_stylebox_override.bind("panel", _looks[look][0]))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = piece.text if piece else "Espacio vacío"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", {"empty": GREY_DARK, "locked": GREEN_TEXT}.get(look, BLUE_TEXT))
	if piece:
		label.add_theme_font_override("font", _bold)
	row.add_child(label)
	if locked:
		row.add_child(_lock_tag())
		box.tooltip_text = "Pieza fija: ya está en su categoría."
	box.add_child(row)
	box.gui_input.connect(_on_slot_input.bind(slot))
	box.set_drag_forwarding(_get_slot_drag.bind(slot, box), _can_drop_piece, _drop_on_slot.bind(slot))
	return box


## "fija" next to a small padlock drawn in code, on the right of a locked slot.
func _lock_tag() -> Control:
	var tag := HBoxContainer.new()
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_theme_constant_override("separation", 5)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(11, 14)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		icon.draw_arc(Vector2(5.5, 6.0), 3.5, PI, TAU, 12, GREEN_TEXT, 1.8, true)
		icon.draw_rect(Rect2(0.5, 6.0, 10.0, 8.0), GREEN_TEXT))
	tag.add_child(icon)
	var label := Label.new()
	label.text = "fija"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", _bold)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", GREEN_TEXT)
	tag.add_child(label)
	return tag


## The pieces waiting in the tray, as blue chips.
func _build_tray() -> void:
	for chip in %Tray.get_children():
		chip.queue_free()
	for piece in _tray:
		var button := _chip(piece.text, "held" if piece.id == _held else "filled")
		button.pressed.connect(_on_tray_piece_pressed.bind(piece.id))
		button.set_drag_forwarding(_get_piece_drag.bind(piece, button), _can_drop_on_tray, _drop_on_tray)
		%Tray.add_child(button)


func _update_hint() -> void:
	var filled := _placements.size()
	var status := "%d de %d espacios llenos · " % [filled, _puzzle.slot_count()]
	if not _note.is_empty():
		%Hint.text = _note
		_note = ""
	elif _held != -1:
		var placed := _slot_of(_held) != -1
		%Hint.text = status + ("haz clic en otro espacio o en la bandeja para moverla" if placed else "haz clic en un espacio para colocarla")
	elif filled < _puzzle.slot_count():
		%Hint.text = status + ("las piezas fijas ya no se mueven" if _failed else "sin límite de tiempo")
	else:
		%Hint.text = status + "puedes mover o reemplazar piezas antes de revisar"


func _rules(decoys: int) -> String:
	var text := "Arrastra cada pieza a un espacio de su categoría, o haz clic en ella y después en el espacio."
	if decoys == 1:
		text += " Una pieza es trampa: déjala en la bandeja."
	elif decoys > 1:
		text += " %d piezas son trampa: déjalas en la bandeja." % decoys
	return text + " Tienes %d intentos." % minigame.max_checks


func _decoys_note(decoys: Array[String]) -> String:
	if decoys.size() == 1:
		return "La trampa era «%s»: no pertenece a ninguna categoría, por eso se quedó en la bandeja." % decoys[0]
	var quoted := decoys.map(func(text): return "«%s»" % text)
	var listed: String = ", ".join(quoted.slice(0, -1)) + " y " + quoted.back()
	return "Las trampas eran %s: no pertenecen a ninguna categoría, por eso se quedaron en la bandeja." % listed


## Slot that holds the piece `piece_id`, -1 when it is in the tray.
func _slot_of(piece_id: int) -> int:
	for slot in _placements:
		if _placements[slot].id == piece_id:
			return slot
	return -1


# ------------------------------------------------------------ player input

## Click a piece of the tray to pick it up, or click it again to let it go.
## With a placed piece picked up, a click anywhere on the tray, a piece
## included, sends that piece back, as the hint says (UC-05.3.a1).
func _on_tray_piece_pressed(piece_id: int) -> void:
	if _held != -1 and _slot_of(_held) != -1:
		_on_piece_to_tray(_held)
		return
	_held = -1 if _held == piece_id else piece_id
	_refresh()


## With a piece picked up, the slot receives it; otherwise the slot's piece
## is picked up, unless it is locked.
func _on_slot_pressed(slot: int) -> void:
	if _held != -1:
		_on_piece_dropped(_held, slot)
		return
	var piece: PuzzlePiece = _placements.get(slot)
	if piece and not _locked.has(slot):
		_held = piece.id
	_refresh()


## A slot reacts on release, like a button: a press that turned into a drag
## never releases here, so dragging a piece does not also pick it up.
func _on_slot_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_slot_pressed(slot)


## A click on the tray takes back the placed piece that was picked up.
func _on_tray_input(event: InputEvent) -> void:
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click and _held != -1 and _slot_of(_held) != -1:
		_on_piece_to_tray(_held)


func _get_piece_drag(_at: Vector2, piece: PuzzlePiece, button: Button) -> Variant:
	button.set_drag_preview(_chip(piece.text, "held"))
	return {"piece": piece.id}


func _get_slot_drag(_at: Vector2, slot: int, source: Control) -> Variant:
	var piece: PuzzlePiece = _placements.get(slot)
	if piece == null or _locked.has(slot):
		return null
	source.set_drag_preview(_chip(piece.text, "held"))
	return {"piece": piece.id, "from_slot": slot}


func _can_drop_piece(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("piece")


func _drop_on_slot(_at: Vector2, data: Variant, slot: int) -> void:
	_on_piece_dropped(data.piece, slot)


## Only a placed piece can go back to the tray.
func _can_drop_on_tray(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("from_slot", -1) != -1


func _drop_on_tray(_at: Vector2, data: Variant) -> void:
	_on_piece_to_tray(data.piece)


## UC-05.3, UC-05.3.a1 to a3: a piece dropped (or clicked) onto a slot. On a
## locked slot the engine leaves everything as it was.
func _on_piece_dropped(piece_id: int, slot: int) -> void:
	_held = -1
	if _locked.has(slot) and _slot_of(piece_id) != slot:
		_note = "Ese espacio ya tiene una pieza fija: tu pieza regresó a donde estaba."
	minigame.place_piece(piece_id, slot)


## UC-05.3.a1: a placed piece goes back to the tray.
func _on_piece_to_tray(piece_id: int) -> void:
	_held = -1
	minigame.move_to_tray(piece_id)


## UC-05.6: the verdict comes back through check_failed or answered.
func _on_check_pressed() -> void:
	_held = -1
	minigame.check()


# ------------------------------------------------------------------ drawing

## The checks left as blue dots and the used ones in grey.
func _draw_checks() -> void:
	var dots: Control = %Checks
	var total := minigame.max_checks if minigame else 3
	for i in total:
		dots.draw_circle(Vector2(6.0 + i * 18.0, dots.size.y / 2.0), 6.0, BLUE if i < _checks_left else GREY)


## A piece as a chip: the tray, and the preview while it is dragged.
func _chip(text: String, look: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	_dress(button, look)
	button.add_theme_font_override("font", _bold)
	button.add_theme_font_size_override("font_size", 13)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, BLUE_TEXT)
	return button


func _dress(button: Button, look: String) -> void:
	var normal: StyleBoxFlat = _looks[look][0]
	var hover: StyleBoxFlat = _looks[look][1]
	for state in ["normal", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, normal)
	for state in ["hover", "hover_pressed"]:
		button.add_theme_stylebox_override(state, hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _box(bg: Color, border: Color, border_width := 2, radius := 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box
