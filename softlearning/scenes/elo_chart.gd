class_name EloChart
extends Control
## "Tu histórico" (UC-11): the department's ELO after each game, drawn as the
## area chart of the mockup. DepartmentView hands it the values; it only draws.

const LINE_COLOR := Color(0.145, 0.388, 0.922)
const FILL_COLOR := Color(0.145, 0.388, 0.922, 0.22)
const GRID_COLOR := Color(0.886, 0.91, 0.941)
const TEXT_COLOR := Color(0.392, 0.455, 0.545)
const FONT_SIZE := 11
## Room for the ELO labels on the left and for the dates underneath.
const AXIS_WIDTH := 40.0
const AXIS_HEIGHT := 18.0
## Distances between grid lines; the first one that needs 4 lines or fewer wins.
const STEPS := [5.0, 10.0, 20.0, 25.0, 50.0, 100.0, 200.0, 250.0, 500.0, 1000.0]

var _elos := PackedFloat32Array()
var _first_date := ""
var _last_date := ""


## `elos` holds the ELO before the first game and after each one; the two dates
## label the ends of the x axis.
func show_history(elos: PackedFloat32Array, first_date: String, last_date: String) -> void:
	_elos = elos
	_first_date = first_date
	_last_date = last_date
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if _elos.size() < 2:
		draw_string(font, Vector2(0.0, size.y / 2.0), "Juega una partida para ver cómo evoluciona tu ELO.",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, TEXT_COLOR)
		return

	var plot := Rect2(AXIS_WIDTH, FONT_SIZE / 2.0, size.x - AXIS_WIDTH, size.y - AXIS_HEIGHT - FONT_SIZE / 2.0)
	if plot.size.x <= 0.0 or plot.size.y <= 0.0:
		return

	var low := _elos[0]
	var high := _elos[0]
	for elo in _elos:
		low = minf(low, elo)
		high = maxf(high, elo)
	var step: float = STEPS[-1]
	for candidate: float in STEPS:
		if (high - low) / candidate <= 4.0:
			step = candidate
			break
	low = floorf(low / step) * step
	high = maxf(ceilf(high / step) * step, low + step)

	# Grid lines with their ELO value.
	var value := low
	while value <= high:
		var y := _y_of(value, low, high, plot)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), GRID_COLOR)
		draw_string(font, Vector2(0.0, y + FONT_SIZE / 3.0), str(roundi(value)),
			HORIZONTAL_ALIGNMENT_RIGHT, AXIS_WIDTH - 6.0, FONT_SIZE, TEXT_COLOR)
		value += step

	# The curve and the area under it.
	var line := PackedVector2Array()
	for i in _elos.size():
		var x := plot.position.x + plot.size.x * i / (_elos.size() - 1)
		line.append(Vector2(x, _y_of(_elos[i], low, high, plot)))
	var area := line.duplicate()
	area.append(plot.end)
	area.append(Vector2(plot.position.x, plot.end.y))
	draw_colored_polygon(area, FILL_COLOR)
	draw_polyline(line, LINE_COLOR, 2.0, true)

	# The dates of the first and the last game.
	var baseline := size.y - 3.0
	draw_string(font, Vector2(plot.position.x, baseline), _first_date,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR)
	if _last_date != _first_date:
		draw_string(font, Vector2(plot.end.x - 120.0, baseline), _last_date,
			HORIZONTAL_ALIGNMENT_RIGHT, 120.0, FONT_SIZE, TEXT_COLOR)


func _y_of(value: float, low: float, high: float, plot: Rect2) -> float:
	return plot.end.y - (value - low) / (high - low) * plot.size.y
