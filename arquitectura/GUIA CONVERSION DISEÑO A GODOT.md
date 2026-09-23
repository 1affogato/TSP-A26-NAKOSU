# GUIA CONVERSION DISEÑO A GODOT

> Convertido automáticamente desde `GUIA CONVERSION DISEÑO A GODOT.docx` — no editar el .docx sin regenerar este .md.
> Fuente: `TSP-A26-NAKOSU\arquitectura\GUIA CONVERSION DISEÑO A GODOT.docx`

# MVC → Godot:

## 1. Los elementos de Godot que vamos a usar

- Node: vive dentro del árbol de la escena. Tiene ciclo de vida (nace, actualiza, muere), puede escuchar entradas del jugador y puede emitir o recibir señales en tiempo real. Se usa para todo lo que tiene comportamiento activo.

- Resource: es solo un dato, sin comportamiento en tiempo real. No vive en el árbol de la escena. Se puede editar directamente en el editor de Godot y se puede guardar como archivo.

- Autoload (Singleton): es un Node especial que se registra una sola vez en la configuración del proyecto. Existe durante toda la partida y es accesible desde cualquier parte del código, sin importar en qué escena estemos.

- Escena (.tscn): es una unidad completa (con su propio árbol de nodos) que se puede guardar, reutilizar e instanciar tantas veces como haga falta.

## 2. Tabla resumen

| Capa / componente | Elemento de Godot | Ejemplo en el proyecto |
| --- | --- | --- |
| Vista | Escena (Control) + script | DepartmentView, SessionView, QuizView |
| Orquestador de sesión (B4) | Node hijo, existe solo durante la sesión por lo que sera parte de la escena de session | SessionOrchestrator |
| Contrato de minijuego (B3) | Clase base + escenas concretas | Minigame → QuizMinigame, SwipeMinigame |
| Gestores globales (B1, B6, B7) | Autoload / Singleton | DepartmentManager, StatisticsTracker, PersistenceService |
| Datos puros | Resource | QuizQuestion, MinigameResult, DepartmentState, ResultRecord, GeneralStats, DetailedStats, StatEntry, SaveData |
| Pool de contenido (B2) | Resource contenedor | QuizPool |
| Enumeraciones | Enum compartido | Department, Difficulty, StatType |

## 3. Cómo se comunican: llamadas hacia abajo, señales hacia arriba

- Llamada hacia abajo: cuando una vista necesita algo de la lógica, llama directamente a una función pública que ya existe (start(), answer(), pause()). Es una llamada normal: quien llama sabe exactamente a quién le está hablando.

- Señal hacia arriba: cuando la lógica necesita avisar que algo pasó, no llama a nadie: emite una señal (finished, question_ready, answered). Quien esté escuchando esa señal reacciona, pero la lógica nunca sabe quién la escucha ni le importa.

Regla práctica: si necesitas pedir algo, llama a una función hacia abajo. Si necesitas avisar de algo, emite una señal hacia arriba. Nunca al revés: la lógica no debe llamar directamente a funciones de la vista.

## 4. Persistencia del progreso: JSON + JSONL

El progreso del jugador se guarda en dos archivos distintos porque cambian de forma distinta:

- department_states.json: guarda el estado actual de los 4 departamentos (nivel y ELO de cada uno). Es un solo objeto que se sobrescribe completo cada vez que se guarda la partida, porque solo nos importa el valor más reciente.

- results.jsonl: guarda el historial completo de resultados de minijuegos (cada ResultRecord). Es un archivo JSON Lines: cada línea es un objeto JSON independiente y completo, uno por resultado. Se usa este formato en vez de un solo array JSON porque el historial solo crece: cada vez que termina un minijuego, se agrega una línea nueva al final del archivo, sin necesidad de leer ni reescribir todo lo anterior.

## 5. Errores comunes a evitar

- Convertir todo en Autoload "por si acaso". Rompe el aislamiento del árbol de escena, oculta dependencias y dificulta las pruebas. Antes de usar un Autoload, pregunta: ¿de verdad necesita sobrevivir a un cambio de escena y ser accesible desde cualquier parte?

- Mutar un Resource compartido sin duplicarlo. Godot reutiliza (cachea) los Resources cargados desde disco. Si modificas uno en tiempo de ejecución sin llamar antes a .duplicate(), el cambio puede afectar a otras partes del juego que usan ese mismo Resource sin que te des cuenta. (Es poco probable que ocurra en nuestro contexto, solo no actualicen resources al vuelo)

- Saltarse el contrato y llamar directo a un nodo hermano. Si una vista llama a métodos internos de otro nodo en vez de usar el contrato y las señales ya definidas, se reintroduce el acoplamiento que se quería evitar, y cualquier cambio futuro en la lógica puede romper la vista sin previo aviso.

- Guardar el progreso del jugador como Resource nativo (.tres). Este formato puede ejecutar código al cargarse. Si el archivo puede ser editado, sincronizado o compartido, es un riesgo real. Por eso el progreso se guarda como JSON/JSONL, nunca como Resource.

- No respetar el ciclo de vida de cada clase. Por ejemplo, registrar SessionOrchestrator como Autoload por comodidad: si nadie reinicia su estado, arrastra datos de una partida a la siguiente.
