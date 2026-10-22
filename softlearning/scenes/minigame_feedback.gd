extends MarginContainer
## Feedback screen shared by the Sprint 2 minigame views (UC-03.6, UC-04.9,
## UC-08.4, UC-09.8): the result badge, title and subtitle, a card the view
## fills with rows, and the two links of every mockup ("Volver al
## departamento" / "Siguiente minijuego").
##
## Pure presentation: it knows nothing about minigames. The view calls
## show_result() and the add_* methods, then forwards the two signals.

signal home_pressed
signal next_pressed

const GREEN := Color(0.086, 0.639, 0.29)
const GREEN_TEXT := Color(0.086, 0.396, 0.204)
const GREEN_BG := Color(0.941, 0.992, 0.957)
const RED := Color(0.863, 0.149, 0.149)
const RED_BG := Color(0.996, 0.949, 0.949)

var _is_correct := false


func _ready() -> void:
	%HomeButton.pressed.connect(home_pressed.emit)
	%NextButton.pressed.connect(next_pressed.emit)
	%Mark.draw.connect(_draw_mark)


## Empties the card and sets the badge, the title and the subtitle pill.
func show_result(is_correct: bool, title: String, subtitle: String) -> void:
	_is_correct = is_correct
	for row in %Rows.get_children():
		row.queue_free()
	var tone := "Right" if is_correct else "Wrong"
	%ResultBadge.theme_type_variation = tone + "Badge"
	%ResultTitle.theme_type_variation = tone + "Title"
	%ResultTitle.text = title
	%Subtitle.text = subtitle
	%Subtitle.add_theme_color_override("font_color", GREEN_TEXT if is_correct else RED)
	%Subtitle.add_theme_stylebox_override("normal", _pill(GREEN_BG if is_correct else RED_BG))
	%Mark.queue_redraw()


## A small caption over a block of text ("Instrucción", "Ejemplo").
func add_text(caption: String, text: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(_caption(caption))
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"QuestionText"
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	%Rows.add_child(box)


## A caption on the left and one chip per item, green (right) or red (wrong).
func add_chips(caption: String, items: Array, right: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := _caption(caption)
	label.custom_minimum_size.x = 170
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A long caption (a sentence of a story) takes the room and the chips
	# keep a fixed column on the right.
	if caption.length() > 30:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 15)
		flow.size_flags_horizontal = Control.SIZE_SHRINK_END
		flow.custom_minimum_size.x = 220
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for item in items:
		var chip := Label.new()
		chip.text = str(item)
		chip.theme_type_variation = &"RightAnswer" if right else &"WrongAnswer"
		chip.add_theme_font_size_override("font_size", 15)
		# No autowrap: inside a flow container it would wrap letter by letter.
		flow.add_child(chip)
	row.add_child(flow)
	%Rows.add_child(row)


## The closing dialogue of a story, in a soft box.
func add_note(text: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pill(Color(0.965, 0.976, 0.996), 12))
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Muted"
	label.add_theme_font_size_override("font_size", 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	%Rows.add_child(panel)


func add_separator() -> void:
	%Rows.add_child(HSeparator.new())


func _caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"Muted"
	label.add_theme_font_size_override("font_size", 13)
	return label


func _pill(color: Color, radius := 10) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


## A check or a cross drawn in white, so no icon font is needed.
func _draw_mark() -> void:
	var mark: Control = %Mark
	var c := mark.size / 2.0
	var s := minf(mark.size.x, mark.size.y) * 0.22
	if _is_correct:
		mark.draw_polyline(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(-s * 0.3, s * 0.7), c + Vector2(s, -s * 0.6)]), Color.WHITE, 5.0, true)
	else:
		mark.draw_line(c + Vector2(-s, -s), c + Vector2(s, s), Color.WHITE, 5.0, true)
		mark.draw_line(c + Vector2(s, -s), c + Vector2(-s, s), Color.WHITE, 5.0, true)
