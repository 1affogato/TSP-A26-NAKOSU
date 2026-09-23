# NAKOSU - GENERAL ARQUITECTURE

> Convertido automáticamente desde `NAKOSU - GENERAL ARQUITECTURE.docx` — no editar el .docx sin regenerar este .md.
> Fuente: `TSP-A26-NAKOSU\arquitectura\NAKOSU - GENERAL ARQUITECTURE.docx`

# Arquitectura General — 7 Bloques

Especificación final de los bloques conceptuales de la arquitectura general del videojuego didáctico de ingeniería de software (Godot). Cada bloque incluye su descripción, los datos que maneja, y sus operaciones externas (lo que expone a otros bloques) e internas (lógica propia, no expuesta hacia afuera).

## 1. Gestión de departamentos

**Descripción:** administra el catálogo de los 4 departamentos fijos del juego y su estado evolutivo.

**Departamentos:** Data Structures and Algorithms, Requirements, Coding Paradigms, Software development.

**Datos:**

- Identificador y nombre de cada departamento.

- Nivel actual.

- ELO actual (valor continuo).

- Condición/umbral para subir de nivel.

- Lista de minijuegos específicos habilitados por departamento (los minijuegos genéricos no se guardan aquí).

**Operaciones externas:**

- Listar departamentos.

- Obtener estado de un departamento (nivel + ELO).

- Actualizar el ELO de un departamento dado un resultado.

- Evaluar si un departamento cumple la condición de subir de nivel.

- Obtener los minijuegos específicos habilitados de un departamento.

**Operaciones internas:**

- Cálculo del ajuste de ELO ponderado por el nivel de dificultad del ítem jugado (acierto en dificultad alta suma más; error en dificultad alta resta menos).

## 2. Pools de contenido por tipo de minijuego

**Descripción:** almacena el contenido ya moldeado para cada tipo de minijuego y selecciona ítems según la dificultad apropiada.

**Datos — Pool de Quiz:**

- Id, departamento, enunciado de la pregunta.

- Cuatro opciones de respuesta (una correcta).

- Nivel de dificultad (4 niveles, facil, medio, dificil y muy dificil).

**Datos — Pool de Swipe:**

- Id, departamento, contenido del ejemplo.

- Categoría correcta.

- Categorías posibles (propias de cada ítem, autoradas a mano).

- Nivel de dificultad (discreto).

**Operaciones externas:**

- Obtener un ítem del pool de Quiz, dado un departamento y su ELO actual.

- Obtener un ítem del pool de Swipe, dado un departamento y su ELO actual.

- (Extensible a nuevos pools para minijuegos futuros.)

**Operaciones internas:**

- Selección ponderada: probabilidad de elegir un nivel de dificultad más alto conforme aumenta el ELO recibido.

## 3. Contrato de minijuego

**Descripción:** interfaz única de entrada/salida entre el orquestador de sesión y cualquier motor de minijuego.

**Datos de entrada:**

- Departamento.

- ELO actual del departamento.

**Datos de salida:**

- Tipo de minijuego jugado.

- Resultado: acierto o error.

- Nivel de dificultad del ítem jugado.

**Protocolo (operaciones externas):**

- Iniciar.

- Pausar / reanudar (preservando y restaurando estado interno).

- Terminar sin resultado (salida anticipada).

- Señal de finalización, entregando el resultado.

## 4. Orquestación de sesión de juego

**Descripción:** implementa el flujo completo de una sesión de juego: arma la secuencia de minijuegos, los lanza, gestiona pausa/salida, y coordina actualización de ELO, estadísticas y guardado.

**Datos:**

- Departamento seleccionado.

- Secuencia de minijuegos de la sesión, ya armada.

- Posición actual dentro de la secuencia.

- Estado de la sesión (activa / pausada / terminada).

- Resultados acumulados de la sesión.

- Temporizador de timeout de pausa.

**Operaciones externas:**

- Iniciar sesión (dado un departamento).

- Pausar / reanudar sesión.

- Salir de la sesión.

- Arma el paquete y entrega a persistencia al cerrar sesión.

**Operaciones internas:**

- Armar la secuencia (minijuegos específicos del departamento + genéricos).

- Lanzar cada minijuego vía el contrato, pasando departamento + ELO.

- Al recibir un resultado: actualizar ELO y registrar estadística.

- Manejar el timeout de una pausa prolongada.

- Finalizar la sesión.

## 5. Motor de cada minijuego (Quiz, Swipe, y futuros)

**Descripción:** implementa las reglas propias de un minijuego concreto, cumpliendo el contrato hacia afuera y consumiendo su pool específico hacia adentro. Recibe la entrada del usuario para determinar el resultado

**Datos internos comunes:**

- Ítem de contenido actual.

- Estado de la respuesta del jugador.

- Estado interno de pausa.

**Operaciones externas (cumplimiento del contrato):**

- Iniciar, pausar/reanudar, terminar sin resultado.

- Reportar resultado al finalizar.

**Operaciones internas:**

- Pedir un ítem al pool correspondiente, dado departamento + ELO.

- Presentar el ítem al jugador.

- Evaluar la respuesta del jugador.

- Dar retroalimentación inmediata.

- Reglas propias de cada minijuego: Quiz maneja un temporizador (fuerza resultado incorrecto si expira); Swipe no tiene límite de tiempo.

## 6. Estadísticas y progreso del jugador

**Descripción:** expone la vista general y detallada de estadísticas de un departamento, a partir del historial de resultados.

**Datos:**

- Registro histórico por resultado: departamento, tipo de minijuego, nivel de dificultad, acierto/error, momento en que ocurrió.

**Operaciones externas:**

- Registrar un resultado.

- Obtener vista general de un departamento (total jugados, total aciertos).

- Obtener vista detallada de un departamento (desglose por tipo de minijuego, por nivel de dificultad, y evolución en el tiempo).

**Operaciones internas:**

- Cálculo de las vistas general y detallada, derivadas del historial (sin contadores duplicados).

## 7. Persistencia

**Descripción:** guarda y recupera de forma confiable los datos generados por el jugador. Al iniciar el juego, 7 entrega el estado inicial directamente a 1 y 6. Al cerrar sesión, es 4 quien recolecta el estado de 1 y 6 y lo entrega empaquetado a 7.

**Datos:**

- ELO y nivel actual de cada departamento.

- Registro histórico completo de resultados.

**No incluye:** pools de contenido, configuración de minijuegos por departamento (datos de autoría del juego), ni el estado de una sesión en curso (no se persiste).

**Operaciones externas:**

- Guardar el progreso completo.

- Cargar el progreso al iniciar el juego.

- Reportar un fallo de guardado.

- Entregar un estado inicial por defecto cuando no hay guardado previo (4 departamentos en su ELO/nivel base, historial vacío).

## Relación entre bloques

- **4** dirige la sesión y solo conoce a los minijuegos a través de **3**.

- **5** cumple el contrato (**3**) y consume su pool específico de **2**.

- **2** decide, con su propio pool, la dificultad del siguiente ítem según el ELO recibido.

- El resultado de cada minijuego alimenta a **1** (ajuste de ELO) y a **6** (registro estadístico), ambos mensajeados a través de **4**.

- **7** es el único que persiste datos, y solo los que el jugador genera jugando (ELO, nivel, historial de **1** y **6**).
