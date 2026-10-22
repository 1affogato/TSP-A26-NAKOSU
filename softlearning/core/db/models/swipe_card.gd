class_name SwipeCard
extends Resource
## One card of the Swipe! pool (UC-08, "SwipeCard"): an example of a
## department concept and the two categories the player chooses between.
##
## Authored content, like QuizQuestion: the cards live in SwipePool (B2) and
## SwipeMinigame receives exactly one of them (UC-08.1).

## The categories of every card (diagram enum "SwipeCategory"). Each card uses
## two of them (R08-1); `category_name()` gives the text the view shows.
enum SwipeCategory {
	# Requerimientos
	FUNCTIONAL_REQUIREMENT,
	NON_FUNCTIONAL_REQUIREMENT,
	BUSINESS_REQUIREMENT,
	USER_REQUIREMENT,
	SYSTEM_REQUIREMENT,
	CONSTRAINT,
	QUALITY_ATTRIBUTE,
	AVAILABILITY,
	RELIABILITY,
	USABILITY,
	PERFORMANCE,
	SECURITY,
	INTERVIEWS,
	OBSERVATION,
	SURVEY,
	VERIFIABLE,
	AMBIGUOUS,
	# Estructuras de datos
	STACK,
	QUEUE,
	ARRAY,
	LINKED_LIST,
	HASH_TABLE,
	TREE,
	GRAPH,
	HEAP,
	CONSTANT_TIME,
	LOGARITHMIC_TIME,
	LINEAR_TIME,
	QUADRATIC_TIME,
	# Desarrollo de Software
	AGILE,
	WATERFALL,
	ANALYSIS,
	DESIGN,
	IMPLEMENTATION,
	TESTING,
	MAINTENANCE,
	VERIFICATION,
	VALIDATION,
	PRODUCT_OWNER,
	SCRUM_MASTER,
	DEVELOPMENT_TEAM,
	# Programación
	OBJECT_ORIENTED,
	FUNCTIONAL,
	PURE_FUNCTION,
	SIDE_EFFECT,
	INHERITANCE,
	COMPOSITION,
	ENCAPSULATION,
	POLYMORPHISM,
	SINGLE_RESPONSIBILITY,
	OPEN_CLOSED,
	LISKOV_SUBSTITUTION,
	DEPENDENCY_INVERSION,
}

const CATEGORY_NAMES := {
	SwipeCategory.FUNCTIONAL_REQUIREMENT: "Requisito funcional",
	SwipeCategory.NON_FUNCTIONAL_REQUIREMENT: "Requisito no funcional",
	SwipeCategory.BUSINESS_REQUIREMENT: "Requisito de negocio",
	SwipeCategory.USER_REQUIREMENT: "Requisito de usuario",
	SwipeCategory.SYSTEM_REQUIREMENT: "Requisito de sistema",
	SwipeCategory.CONSTRAINT: "Restricción",
	SwipeCategory.QUALITY_ATTRIBUTE: "Atributo de calidad",
	SwipeCategory.AVAILABILITY: "Disponibilidad",
	SwipeCategory.RELIABILITY: "Fiabilidad",
	SwipeCategory.USABILITY: "Usabilidad",
	SwipeCategory.PERFORMANCE: "Rendimiento",
	SwipeCategory.SECURITY: "Seguridad",
	SwipeCategory.INTERVIEWS: "Entrevista",
	SwipeCategory.OBSERVATION: "Observación",
	SwipeCategory.SURVEY: "Cuestionario",
	SwipeCategory.VERIFIABLE: "Verificable",
	SwipeCategory.AMBIGUOUS: "Ambiguo",
	SwipeCategory.STACK: "Pila",
	SwipeCategory.QUEUE: "Cola",
	SwipeCategory.ARRAY: "Arreglo",
	SwipeCategory.LINKED_LIST: "Lista enlazada",
	SwipeCategory.HASH_TABLE: "Tabla hash",
	SwipeCategory.TREE: "Árbol",
	SwipeCategory.GRAPH: "Grafo",
	SwipeCategory.HEAP: "Montículo",
	SwipeCategory.CONSTANT_TIME: "O(1) constante",
	SwipeCategory.LOGARITHMIC_TIME: "O(log n) logarítmica",
	SwipeCategory.LINEAR_TIME: "O(n) lineal",
	SwipeCategory.QUADRATIC_TIME: "O(n²) cuadrática",
	SwipeCategory.AGILE: "Ágil",
	SwipeCategory.WATERFALL: "Cascada",
	SwipeCategory.ANALYSIS: "Análisis",
	SwipeCategory.DESIGN: "Diseño",
	SwipeCategory.IMPLEMENTATION: "Implementación",
	SwipeCategory.TESTING: "Pruebas",
	SwipeCategory.MAINTENANCE: "Mantenimiento",
	SwipeCategory.VERIFICATION: "Verificación",
	SwipeCategory.VALIDATION: "Validación",
	SwipeCategory.PRODUCT_OWNER: "Product Owner",
	SwipeCategory.SCRUM_MASTER: "Scrum Master",
	SwipeCategory.DEVELOPMENT_TEAM: "Equipo de desarrollo",
	SwipeCategory.OBJECT_ORIENTED: "Orientado a objetos",
	SwipeCategory.FUNCTIONAL: "Funcional",
	SwipeCategory.PURE_FUNCTION: "Función pura",
	SwipeCategory.SIDE_EFFECT: "Con efecto secundario",
	SwipeCategory.INHERITANCE: "Herencia",
	SwipeCategory.COMPOSITION: "Composición",
	SwipeCategory.ENCAPSULATION: "Encapsulamiento",
	SwipeCategory.POLYMORPHISM: "Polimorfismo",
	SwipeCategory.SINGLE_RESPONSIBILITY: "Responsabilidad única",
	SwipeCategory.OPEN_CLOSED: "Abierto/cerrado",
	SwipeCategory.LISKOV_SUBSTITUTION: "Sustitución de Liskov",
	SwipeCategory.DEPENDENCY_INVERSION: "Inversión de dependencias",
}

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
## Concept the example illustrates, shown above the example ("Ejemplo").
@export var concept: String = ""
## At most 120 characters (N08-2).
@export var example_text: String = ""
## Exactly two (R08-1), one of them `correct_category`.
@export var possible_categories: Array[SwipeCategory] = []
@export var correct_category: SwipeCategory = SwipeCategory.FUNCTIONAL_REQUIREMENT


static func category_name(category: SwipeCategory) -> String:
	return CATEGORY_NAMES.get(category, SwipeCategory.find_key(category))


func get_concept() -> String:
	return concept


func get_example_text() -> String:
	return example_text


## The categories in authored order. Returns a copy, so the engine can shuffle
## the sides (R08-2) without touching the card.
func get_categories() -> Array[SwipeCategory]:
	var copy: Array[SwipeCategory] = possible_categories.duplicate()
	return copy


## UC-08.4
func check_answer(selected_category: SwipeCategory) -> bool:
	return selected_category == correct_category


## Usable card: an example and two different categories, one of them correct.
func is_valid() -> bool:
	return (
		not example_text.is_empty()
		and possible_categories.size() == 2
		and possible_categories[0] != possible_categories[1]
		and possible_categories.has(correct_category)
	)
