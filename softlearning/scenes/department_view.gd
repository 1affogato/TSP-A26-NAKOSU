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

## Lo mismo para las filas por minijuego: B6 agrupa por la clave TYPE del motor
## (p.ej. "QUIZ"), y aquí se pasa a texto del mockup.
const MINIGAME_LABELS := {
	"QUIZ": "Quiz",
	"SWIPE": "Swipe",
	"NARRATIVE": "Narrativa",
	"TRAIN": "Ordena el tren",
	"BOMB": "Desactivar bomba",
	"PUZZLE": "Rompecabezas",
	"STACK_PUZZLE": "Stack Puzzle",
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

## UC-12.6: sprite de la oficina por nivel general de la empresa. Sólo cambia
## con una subida de nivel general, no con la de un departamento.
## 5 visual levels mapped 1:1 to general levels 0..4.
## Missing files fall back to the department image.
const OFFICES_BY_LEVEL := {
	0: "res://assets/office_level_0.jpeg",
	1: "res://assets/office_level_1.jpeg",
	2: "res://assets/office_level_2.jpeg",
	3: "res://assets/office_level_3.jpeg",
	4: "res://assets/office_level_4.jpeg",
}

## Department shown in DetailScreen, set by the floor that was pressed.
var department: Enums.Department = Enums.Department.DATA_STRUCTURES

@onready var _select_screen: MarginContainer = $SelectScreen
@onready var _detail_screen: MarginContainer = $DetailScreen
@onready var _floors: VBoxContainer = $SelectScreen/Layout/Body/Floors
@onready var _building_image: TextureRect = $SelectScreen/Layout/Body/BuildingImage

@onready var _dept_name: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/Header/Texts/DeptName
@onready var _dept_description: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/Header/Texts/DeptDescription
@onready var _played_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/PlayedCard/Content/Value
@onready var _wins_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/WinsCard/Content/Value
@onready var _elo_value: Label = $DetailScreen/Layout/TopRow/InfoPanel/Content/StatCards/EloCard/Content/Value

@onready var _start_button: Button = $DetailScreen/Layout/TopRow/Actions/StartButton
@onready var _level_up_button: Button = $DetailScreen/Layout/TopRow/Actions/LevelUpButton
@onready var _level_up_result: Label = $DetailScreen/Layout/TopRow/Actions/LevelUpResult

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
@onready var _overlay: TutorialOverlay = $TutorialOverlay

## UC-01: the tutorial flow, a child of this view as the class diagram shows.
## Its cross-scene state lives in `TutorialRun`.
var _tutorial: TutorialController


func _ready() -> void:
	_refresh_floors()
	_setup_tutorial()


# ------------------------------------------------------------------- UC-11.1

## El jugador ha elegido un departamento. También es la vuelta de una sesión
## (UC-02.9): SessionView lo llama con el departamento que se jugó.
func select_department(selected: Enums.Department) -> void:
	department = selected

	_select_screen.hide()
	_detail_screen.show()

	_dept_name.text = DepartmentManager.get_department_name(department)
	_dept_description.text = String(DESCRIPTIONS.get(department, ""))
	show_office(DepartmentManager.get_general_level())
	_level_up_result.hide()

	show_general_stats(StatisticsTracker.get_general_stats(department))

	# Se abre con la primera pestaña, como en el mockup.
	_on_stat_selected(Enums.StatType.BY_MINIGAME)

	# UC-01.4: inside the tutorial this call comes from the highlighted floor,
	# so it also advances the first step. Returning from a session keeps the
	# current tutorial step (SESSION) and does not advance it.
	if _tutorial != null and _tutorial.step == Enums.TutorialStep.DEPARTMENTS:
		_tutorial.on_department_selected(selected)


# --------------------------------------------------------- UC-11.2 / UC-11.3

## Pinta la vista general de un departamento.
func show_general_stats(stats: GeneralStats) -> void:
	_played_value.text = str(stats.total_played)
	_wins_value.text = str(stats.total_correct)
	# El ELO no viaja en GeneralStats: es dato de B1, no de B6.
	_elo_value.text = "%d" % roundi(DepartmentManager.get_elo(stats.department))

	if stats.upgrade_available and DepartmentManager.is_level_up_available(stats.department):
		show_upgrade_option()
	else:
		_level_up_button.disabled = true


## UC-11.3.a1 / UC-12.2: el departamento cumple la condición de subida y todavía
## no se usó la subida del día, así que se ofrece la opción.
func show_upgrade_option() -> void:
	_level_up_button.disabled = false


## UC-12.6: pinta la oficina del nivel general de la empresa. Mientras no haya
## arte por nivel (see OFFICES_BY_LEVEL) se queda la imagen del departamento.
## 5 visual levels mapped 1:1 to general levels 0..4.
## Missing files fall back to the department image.
func show_office(level: int) -> void:
	var clamped_level := clampi(level, 0, DepartmentState.MAX_LEVEL)
	var path := String(OFFICES_BY_LEVEL.get(clamped_level, ""))
	var texture := load(OFFICE_IMAGES[department])
	if not path.is_empty() and ResourceLoader.exists(path):
		texture = load(path)
	_office_image.texture = texture
	_building_image.texture = texture


## UC-12.10: mensaje del resultado de la subida de nivel, sobre la vista del
## departamento. El nivel general (y con él la oficina) ya está actualizado.
## `detail` es el motivo que dio B4 cuando la subida no pudo empezar
## (UC-12.4.e1); si no llegó, se muestra el mensaje genérico.
func show_level_up_result(
	outcome: Enums.LevelUpOutcome, new_level: int, detail: String = ""
) -> void:
	match outcome:
		Enums.LevelUpOutcome.SUCCESS:
			_level_up_result.text = "¡Departamento en el nivel %d! La empresa llega al nivel general %d." % [
				new_level, DepartmentManager.get_general_level()
			]
			_level_up_result.theme_type_variation = &"RightAnswer"
		Enums.LevelUpOutcome.FAILED:
			_level_up_result.text = "La subida de nivel no salió: el departamento pierde %d de ELO y sigue en el nivel %d." % [
				roundi(DepartmentManager.get_failed_level_up_penalty()), new_level
			]
			_level_up_result.theme_type_variation = &"WrongAnswer"
		Enums.LevelUpOutcome.CANCELLED:
			_level_up_result.text = "No se pudo guardar la subida de nivel; el departamento queda como estaba."
			_level_up_result.theme_type_variation = &"WrongAnswer"
		_:
			_level_up_result.text = detail if not detail.is_empty() \
				else "La subida de nivel no está disponible ahora mismo."
			_level_up_result.theme_type_variation = &"Muted"
	_level_up_result.show()


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


## UC-11.3.a1.1 / UC-12.3: inicia una subida de nivel en el departamento.
## SessionView arranca la sesión scripted (UC-12.4) y vuelve aquí con
## resume_after_level_up() (UC-12.10); si no se puede jugar, también vuelve aquí,
## con UNAVAILABLE.
func _on_upgrade_pressed() -> void:
	var session_view: Node = load("res://scenes/session_view.tscn").instantiate()
	session_view.ready.connect(session_view.open_level_up.bind(department))
	get_tree().change_scene_to_node(session_view)


## UC-02.1: abre SessionView con el departamento elegido. Su orquestador (B4)
## arranca la sesión y, al terminar, vuelve aquí con select_department() (UC-02.9).
## UC-01.8: si el tutorial está en el paso PLAY, la sesión es la guiada.
func _on_play_pressed() -> void:
	var tutorial_session := _tutorial != null and _tutorial.on_play_pressed()
	var session_view: Node = load("res://scenes/session_view.tscn").instantiate()
	if tutorial_session:
		session_view.ready.connect(session_view.open_tutorial.bind(department))
	else:
		session_view.ready.connect(session_view.open.bind(department))
	get_tree().change_scene_to_node(session_view)


## UC-01.10: SessionView returns here after the guided session, with the total
## ELO change. The department detail is restored first, then the final message
## is shown over it.
func resume_after_session(selected: Enums.Department, elo_delta: float) -> void:
	select_department(selected)
	if _tutorial != null:
		_tutorial.resume_after_session(elo_delta)


## UC-12.10: SessionView returns here when the level-up session ends (or could
## not start). The department detail is restored first — which also refreshes
## the office of the new general level (UC-12.6/UC-12.7) — and then the result
## message is shown (UC-12.5.a1, UC-12.9.e1).
func resume_after_level_up(
	selected: Enums.Department,
	outcome: Enums.LevelUpOutcome,
	new_level: int,
	detail: String = ""
) -> void:
	select_department(selected)
	show_level_up_result(outcome, new_level, detail)


func _show_select() -> void:
	_detail_screen.hide()
	_select_screen.show()
	# Al volver de una partida el ELO ha cambiado, así que las barras se rehacen.
	_refresh_floors()


# -------------------------------------------------------------------- UC-01

## Creates the B4 flow and wires the overlay. The controller is a child of the
## view (as the class diagram says); `TutorialRun` carries its state across the
## session scene change.
func _setup_tutorial() -> void:
	_tutorial = TutorialController.new()
	_tutorial.name = "TutorialController"
	add_child(_tutorial)
	_tutorial.step_changed.connect(_on_tutorial_step)
	_tutorial.save_failed.connect(_on_tutorial_save_failed)
	_tutorial.tutorial_finished.connect(_on_tutorial_finished)

	var buttons := {}
	for floor_name in FLOOR_DEPARTMENTS:
		buttons[FLOOR_DEPARTMENTS[floor_name]] = _floors.get_node(floor_name)
	_overlay.configure(_floors, buttons, _chart_card, _start_button)
	_overlay.department_chosen.connect(_on_tutorial_department_chosen)
	_overlay.screen_clicked.connect(_on_tutorial_screen_clicked)
	_overlay.play_requested.connect(_on_tutorial_play_requested)
	_overlay.final_confirmed.connect(_on_tutorial_final_confirmed)

	_tutorial.start_if_pending()


func _on_tutorial_step(step: Enums.TutorialStep) -> void:
	match step:
		Enums.TutorialStep.DEPARTMENTS:
			if _detail_screen.visible:
				_show_select()
			_overlay.show_step(step)
		Enums.TutorialStep.ELO:
			# UC-01.5: the highlighted graph lives in the "Tu histórico" tab.
			_on_stat_selected(Enums.StatType.OVER_TIME)
			_overlay.show_step(step)
		Enums.TutorialStep.PLAY:
			_overlay.show_step(step)
		Enums.TutorialStep.SESSION:
			_overlay.hide_overlay()
		Enums.TutorialStep.FINAL:
			# A restored final step (save failure) needs the detail screen back.
			if not _detail_screen.visible:
				select_department(TutorialRun.department)
			_overlay.show_final_message(TutorialRun.elo_delta)
		Enums.TutorialStep.DONE:
			_overlay.hide_overlay()


func _on_tutorial_department_chosen(selected: Enums.Department) -> void:
	select_department(selected)


func _on_tutorial_screen_clicked() -> void:
	_tutorial.on_elo_step_confirmed()


func _on_tutorial_play_requested() -> void:
	_on_play_pressed()


func _on_tutorial_final_confirmed() -> void:
	_tutorial.complete()


func _on_tutorial_finished() -> void:
	_overlay.hide_overlay()


func _on_tutorial_save_failed(reason: String) -> void:
	_overlay.show_save_error(reason)


# ---------------------------------------------------------------- internals

## La barra de cada piso muestra el progreso del departamento hacia su umbral de
## subida de nivel (B1). Also updates the building image to the general level.
func _refresh_floors() -> void:
	for floor_name in FLOOR_DEPARTMENTS:
		var department_id: Enums.Department = FLOOR_DEPARTMENTS[floor_name]
		var floor: Button = _floors.get_node(floor_name)
		var progress := floor.get_node("Progress") as ProgressBar
		progress.value = DepartmentManager.get_level_up_progress(department_id) * 100.0
	# Update the building image on SelectScreen to reflect the general level
	show_office(DepartmentManager.get_general_level())


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
