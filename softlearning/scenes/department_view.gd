extends Control
## UC-11: the player picks a floor of the building (SelectScreen) and then
## consults that department's statistics (DetailScreen). "Comenzar Partida"
## starts a session there (UC-02.1), and the session comes back through
## select_department() (UC-02.9).
##
## The floor buttons are connected in the scene, each one binding its
## `Enums.Department`, so this script needs no node paths for them.
##
## Every number comes from the two global managers, and the view only reads:
## the general and detailed statistics from `StatisticsTracker` (B6), and the
## ELO, the names and the level-up condition from `DepartmentManager` (B1).
##
## The diagram's `stats: StatisticsTracker` field is the autoload itself, so
## there is no reference to store here: the view calls the singleton directly.

## Texto de las filas por dificultad ("Retos fáciles hechos"). B6 trabaja con la
## clave ("MUY_DIFICIL"); pasarla a algo legible es cosa de la vista.
const DIFFICULTY_LABELS := {
	"FACIL": "fáciles",
	"MEDIO": "medios",
	"DIFICIL": "difíciles",
	"MUY_DIFICIL": "muy difíciles",
}

## Lo mismo para las filas por minijuego: B6 agrupa por la clave del motor
## (`QuizMinigame.TYPE`), y aquí se pasa a texto del mockup.
const MINIGAME_LABELS := {
	QuizMinigame.TYPE: "quizes",
}

## Descripción de cada departamento: texto de presentación de la vista (sale del
## mockup), no es un dato de B1.
const DESCRIPTIONS := {
	Enums.Department.DATA_STRUCTURES: "Listas, pilas, colas y árboles: las piezas con las que se construye casi todo lo demás.",
	Enums.Department.REQUIREMENTS: "¿El cliente pidió una app rápida y bonita? Tranquilo, aquí hablamos ese idioma y lo traducimos a criterios de aceptación.",
	Enums.Department.SOFTWARE_DEV: "Del requisito al entregable: aquí se planifica, se construye y se mantiene el software.",
	Enums.Department.CODING: "Estilos, patrones y buenas prácticas: el arte de escribir código que otros puedan leer.",
}

## Qué departamento hay detrás de cada piso. Coincide con los `binds` de las
## conexiones del .tscn (Piso 1 = Requerimientos, ... Piso 4 = Desarrollo).
const FLOOR_DEPARTMENTS := {
	"Floor1": Enums.Department.REQUIREMENTS,
	"Floor2": Enums.Department.DATA_STRUCTURES,
	"Floor3": Enums.Department.CODING,
	"Floor4": Enums.Department.SOFTWARE_DEV,
}

## Oficina de cada departamento (assets/). Como las descripciones, es
## presentación de la vista, no un dato de B1.
const OFFICE_IMAGES := {
	Enums.Department.DATA_STRUCTURES: "res://assets/data structures view.png",
	Enums.Department.REQUIREMENTS: "res://assets/requirements view.png",
	Enums.Department.SOFTWARE_DEV: "res://assets/software_department_view.jpeg",
	Enums.Department.CODING: "res://assets/coding_paradigms_view.png",
}

## Department shown in DetailScreen, set by the floor that was pressed.
var department: Enums.Department = Enums.Department.DATA_STRUCTURES

@onready var _select_screen: MarginContainer = $SelectScreen
@onready var _detail_screen: MarginContainer = $DetailScreen
@onready var _floors: VBoxContainer = $SelectScreen/Layout/Body/Floors

@onready var _dept_name: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/Header/Texts/DeptName
@onready var _dept_description: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/Header/Texts/DeptDescription
@onready var _played_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/PlayedCard/Content/Value
@onready var _wins_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/WinsCard/Content/Value
@onready var _elo_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/EloCard/Content/Value

@onready var _start_button: Button = $DetailScreen/Layout/TopRow/Actions/StartButton
@onready var _level_up_button: Button = $DetailScreen/Layout/TopRow/Actions/LevelUpButton

@onready var _office_image: TextureRect = $DetailScreen/Layout/BottomRow/OfficeImage

## Indexed by `Enums.StatType`, in the order of the tabs.
@onready var _tabs: Array[Button] = [
	$DetailScreen/Layout/BottomRow/StatsPanel/Content/Tabs/ByMinigameTab,
	$DetailScreen/Layout/BottomRow/StatsPanel/Content/Tabs/ByDifficultyTab,
	$DetailScreen/Layout/BottomRow/StatsPanel/Content/Tabs/HistoryTab,
]
@onready var _columns: ScrollContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll
@onready var _played_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/Played
@onready var _won_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/Won
@onready var _accuracy_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/Accuracy
@onready var _chart_card: PanelContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/ChartCard
@onready var _elo_chart: EloChart = $DetailScreen/Layout/BottomRow/StatsPanel/Content/ChartCard/Content/EloChart


func _ready() -> void:
	_refresh_floors()


# ------------------------------------------------------------------- UC-11.1

## El jugador ha elegido un departamento. También es la vuelta de una sesión
## (UC-02.9): SessionView lo llama con el departamento que se jugó.
func select_department(selected: Enums.Department) -> void:
	department = selected

	_select_screen.hide()
	_detail_screen.show()

	_dept_name.text = DepartmentManager.get_department_name(department)
	_dept_description.text = String(DESCRIPTIONS.get(department, ""))
	_office_image.texture = load(OFFICE_IMAGES[department])

	show_general_stats(StatisticsTracker.get_general_stats(department))

	# Se abre con la primera pestaña, como en el mockup.
	_on_stat_selected(Enums.StatType.BY_MINIGAME)


# --------------------------------------------------------- UC-11.2 / UC-11.3

## Pinta la vista general de un departamento.
func show_general_stats(stats: GeneralStats) -> void:
	_played_value.text = str(stats.total_played)
	_wins_value.text = str(stats.total_correct)
	# El ELO no viaja en GeneralStats: es dato de B1, no de B6.
	_elo_value.text = "%d" % roundi(DepartmentManager.get_elo(stats.department))

	if stats.upgrade_available:
		show_upgrade_option()
	else:
		_level_up_button.disabled = true


## UC-11.3.a1: el departamento cumple la condición de subida, así que se ofrece
## la opción de subir de nivel. Lo que hace ese botón es UC-12.
func show_upgrade_option() -> void:
	_level_up_button.disabled = false


# ------------------------------------------------------------- UC-11.4 / 11.5

## UC-11.5: una fila por grupo del detalle (cada minijuego o cada dificultad) y,
## en las tres columnas, cuántos se jugaron, cuántos se ganaron y la efectividad.
func show_detailed_stats(detail: DetailedStats) -> void:
	var entries := detail.entries
	if detail.type == Enums.StatType.BY_DIFFICULTY:
		entries = _all_difficulties(entries)
	var played := PackedStringArray()
	var won := PackedStringArray()
	var accuracy := PackedStringArray()
	for entry in entries:
		if detail.type == Enums.StatType.BY_DIFFICULTY:
			var level: String = DIFFICULTY_LABELS.get(entry.label, entry.label)
			played.append("%d\nRetos %s hechos" % [entry.played, level])
			won.append("%d\nRetos %s ganados" % [entry.correct, level])
		else:
			var minigame: String = MINIGAME_LABELS.get(entry.label, entry.label)
			played.append("%d\n%s jugados" % [entry.played, minigame])
			won.append("%d\n%s ganados" % [entry.correct, minigame])
		accuracy.append("%d%%\nporcentaje de efectividad" % roundi(entry.get_accuracy() * 100.0))
	_fill_column(_played_column, played)
	_fill_column(_won_column, won)
	_fill_column(_accuracy_column, accuracy)


# ------------------------------------------------------------------ botones

## UC-11.4: el jugador elige una estadística con las pestañas (conectadas en el
## .tscn). Por minijuego y por dificultad llenan las columnas con su detalle;
## "Tu histórico" las cambia por la gráfica del ELO tras cada partida, con las
## fechas de la primera y la última.
func _on_stat_selected(type: Enums.StatType) -> void:
	_tabs[type].button_pressed = true
	var detail := StatisticsTracker.get_detailed_stats(department, type)
	var over_time := type == Enums.StatType.OVER_TIME
	_columns.visible = not over_time
	_chart_card.visible = over_time
	if not over_time:
		show_detailed_stats(detail)
		return
	var days := detail.entries
	_elo_chart.show_history(StatisticsTracker.get_elo_history(department),
		days[0].label if days else "", days[-1].label if days else "")


## UC-11.3.a1.1: inicia UC-12 (Upgrade Department), que todavía no existe.
func _on_upgrade_pressed() -> void:
	push_warning("UC-12 (Upgrade Department) todavía no está implementado.")


## UC-02.1: abre SessionView con el departamento elegido. Su orquestador (B4)
## arranca la sesión y, al terminar, vuelve aquí con select_department() (UC-02.9).
func _on_play_pressed() -> void:
	var session_view: Node = load("res://scenes/session_view.tscn").instantiate()
	session_view.ready.connect(session_view.open.bind(department))
	get_tree().change_scene_to_node(session_view)


func _show_select() -> void:
	_detail_screen.hide()
	_select_screen.show()
	# Al volver de una partida el ELO ha cambiado, así que las barras se rehacen.
	_refresh_floors()


# ---------------------------------------------------------------- internals

## La barra de cada piso muestra el progreso del departamento hacia su umbral de
## subida de nivel (B1).
func _refresh_floors() -> void:
	for floor_name in FLOOR_DEPARTMENTS:
		var department_id: Enums.Department = FLOOR_DEPARTMENTS[floor_name]
		var floor: Button = _floors.get_node(floor_name)
		var progress := floor.get_node("Progress") as ProgressBar
		progress.value = DepartmentManager.get_level_up_progress(department_id) * 100.0


## Las cuatro dificultades siempre, de fácil a muy difícil, como en el mockup:
## B6 solo trae las que ya se jugaron, y las que faltan se muestran en cero.
func _all_difficulties(entries: Array[StatEntry]) -> Array[StatEntry]:
	var played_levels := {}
	for entry in entries:
		played_levels[entry.label] = entry
	var all: Array[StatEntry] = []
	for difficulty in Enums.Difficulty.values():
		var key := Enums.difficulty_to_key(difficulty)
		all.append(played_levels[key] if played_levels.has(key) else StatEntry.create(key, 0, 0))
	return all


## Rehace las filas de una columna: la primera fila escrita en la escena queda
## oculta como plantilla, así que se muestran tantos grupos como tenga el
## historial, nunca quedan filas de ejemplo a la vista y una columna vacía
## (departamento sin historial) se puede volver a llenar después.
func _fill_column(column: VBoxContainer, rows: PackedStringArray) -> void:
	if column.get_child_count() == 0:
		return

	var template := column.get_child(0) as PanelContainer
	template.hide()
	for i in range(column.get_child_count() - 1, 0, -1):
		var old_row := column.get_child(i)
		column.remove_child(old_row)
		old_row.queue_free()

	for text in rows:
		var row := template.duplicate() as PanelContainer
		row.show()
		column.add_child(row)
		(row.get_node("Row/Text") as Label).text = text
