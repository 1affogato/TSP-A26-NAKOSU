extends Control
## UC-11: the player picks a floor of the building (SelectScreen) and then
## consults that department's statistics (DetailScreen).
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

## Texto de la columna de dificultad. B6 trabaja con la clave ("MUY_DIFICIL");
## pasarla a algo legible es cosa de la vista.
const DIFFICULTY_LABELS := {
	"FACIL": "Fácil",
	"MEDIO": "Medio",
	"DIFICIL": "Difícil",
	"MUY_DIFICIL": "Muy difícil",
}

## Descripción de cada departamento: texto de presentación de la vista (sale del
## mockup), no es un dato de B1.
const DESCRIPTIONS := {
	Enums.Department.DATA_STRUCTURES: "Listas, pilas, colas y árboles: las piezas con las que se construye casi todo lo demás.",
	Enums.Department.REQUIREMENTS: "¿El cliente pidió una app rápida y bonita? Tranquilo, aquí hablamos ese idioma y lo traducimos a criterios de aceptación.",
	Enums.Department.SOFTWARE_DEV: "Del requisito al entregable: aquí se planifica, se construye y se mantiene el software.",
	Enums.Department.CODING: "Estilos, patrones y buenas prácticas: el arte de escribir código que otros puedan leer.",
}

## Las tres agrupaciones del detalle. En esta escena se ven a la vez, una por
## columna, como en el mockup.
const STAT_TYPES := [
	Enums.StatType.BY_MINIGAME,
	Enums.StatType.BY_DIFFICULTY,
	Enums.StatType.OVER_TIME,
]

## Qué departamento hay detrás de cada piso. Coincide con los `binds` de las
## conexiones del .tscn (Piso 1 = Requerimientos, ... Piso 4 = Desarrollo).
const FLOOR_DEPARTMENTS := {
	"Floor1": Enums.Department.REQUIREMENTS,
	"Floor2": Enums.Department.DATA_STRUCTURES,
	"Floor3": Enums.Department.CODING,
	"Floor4": Enums.Department.SOFTWARE_DEV,
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

@onready var _by_minigame_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/ByMinigame
@onready var _by_difficulty_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/ByDifficulty
@onready var _over_time_column: VBoxContainer = $DetailScreen/Layout/BottomRow/StatsPanel/Content/Scroll/Columns/History


func _ready() -> void:
	_refresh_floors()


# ------------------------------------------------------------------- UC-11.1

## El jugador ha elegido un departamento.
func select_department(selected: Enums.Department) -> void:
	department = selected

	_select_screen.hide()
	_detail_screen.show()

	_dept_name.text = DepartmentManager.get_department_name(department)
	_dept_description.text = String(DESCRIPTIONS.get(department, ""))

	show_general_stats(StatisticsTracker.get_general_stats(department))

	# UC-11.4: se pide el detalle de cada agrupación. En esta escena las tres
	# columnas se ven a la vez, así que se piden las tres de una vez.
	for type in STAT_TYPES:
		_on_stat_selected(type)


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

## Pinta una de las tres columnas de detalle.
func show_detailed_stats(detail: DetailedStats) -> void:
	var rows := PackedStringArray()
	for entry in detail.entries:
		rows.append(_row_text(entry, detail.type))
	_fill_column(_column_for(detail.type), rows)


# ------------------------------------------------------------------ botones

## UC-11.4: el jugador elige una estadística. Hoy los rótulos de las columnas
## son Labels, no botones, así que se llama una vez por tipo; si pasan a ser
## botones, basta con conectarlos aquí.
func _on_stat_selected(type: Enums.StatType) -> void:
	show_detailed_stats(StatisticsTracker.get_detailed_stats(department, type))


## UC-11.3.a1.1: inicia UC-12 (Upgrade Department), que todavía no existe.
func _on_upgrade_pressed() -> void:
	push_warning("UC-12 (Upgrade Department) todavía no está implementado.")


## UC-02.1: abre SessionView con el departamento elegido. Falta el orquestador de
## sesión (B4), que es quien arranca la sesión y quien vuelve aquí (UC-02.9).
func _on_play_pressed() -> void:
	push_warning("SessionOrchestrator (B4) todavía no existe; aquí va UC-02.1.")


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


func _column_for(type: Enums.StatType) -> VBoxContainer:
	match type:
		Enums.StatType.BY_DIFFICULTY:
			return _by_difficulty_column
		Enums.StatType.OVER_TIME:
			return _over_time_column
		_:
			return _by_minigame_column


## Texto de una fila, con la forma del mockup: el número arriba y qué mide
## abajo. Cada columna destaca una métrica distinta de StatEntry.
func _row_text(entry: StatEntry, type: Enums.StatType) -> String:
	match type:
		Enums.StatType.BY_MINIGAME:
			return "%d\n%s jugados" % [entry.played, entry.label]
		Enums.StatType.BY_DIFFICULTY:
			return "%d\n%s ganados" % [entry.correct, _difficulty_label(entry.label)]
		_:
			return "%d%%\n%s" % [roundi(entry.get_accuracy() * 100.0), entry.label]


func _difficulty_label(key: String) -> String:
	return String(DIFFICULTY_LABELS.get(key, key))


## Rehace las filas de una columna: las filas escritas en la escena hacen de
## plantilla, así que se muestran tantos grupos como tenga el historial y nunca
## quedan filas de ejemplo a la vista.
func _fill_column(column: VBoxContainer, rows: PackedStringArray) -> void:
	if column.get_child_count() == 0:
		return

	var template := column.get_child(0).duplicate() as PanelContainer
	for row in column.get_children():
		column.remove_child(row)
		row.queue_free()

	for text in rows:
		var row := template.duplicate() as PanelContainer
		column.add_child(row)
		(row.get_node("Row/Text") as Label).text = text

	template.free()
