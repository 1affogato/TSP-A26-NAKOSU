# ナコス (NAKOSU)

Juego educativo de ingeniería de software hecho en **Godot 4.7**. El jugador entra a un edificio de cuatro pisos (un departamento por piso), juega partidas de 10 minijuegos y ve cómo cambia su nivel (ELO) y sus estadísticas.

| Departamento | Piso |
|---|---|
| Requerimientos | 1 |
| Estructuras de datos | 2 |
| Programación (Coding) | 3 |
| Desarrollo de Software | 4 |

| Minijuego | Dónde aparece | Contenido incluido |
|---|---|---|
| Quiz | los 4 departamentos | 160 preguntas |
| Swipe! | los 4 departamentos | 64 tarjetas |
| Narrativa | los 4 departamentos | 32 escenarios |
| Ordena el tren | Desarrollo de Software | 16 secuencias |
| Desactivar bomba | Requerimientos | 16 bombas (3 candados cada una) |

Este README es la **guía de operaciones para quien administra el juego**: cómo correrlo, publicarlo, mantener su contenido y atender problemas. Cómo se juega está en el manual de usuario (ver [Documentación](#documentación)).

---

## 1. Cómo funciona (lo que hay que saber antes de operarlo)

- **No hay servidor de datos ni base de datos.** El juego se exporta a la web como archivos estáticos (HTML, JS, WASM y un `.pck`). Cada jugador lo ejecuta en su navegador.
- **El progreso vive en el equipo del jugador**, no en el servidor: en la versión web, en el almacenamiento de su navegador; en escritorio, en su carpeta de usuario. Por eso muchas personas pueden jugar a la vez sin afectarse, y por eso el administrador **no puede ver ni recuperar** el progreso de nadie.
- Dos personas que usan el mismo navegador de la misma computadora **comparten progreso** (recomendar ventana de incógnito, sabiendo que ahí el progreso se borra al cerrarla).
- El progreso se guarda **al terminar la partida** o al pulsar «Salir» en la pausa (lo ya jugado se conserva).

## 2. Requisitos

| Para | Necesitas |
|---|---|
| Abrir o editar el proyecto | Godot **4.7.2** (renderizador *GL Compatibility*) |
| Exportar la versión web | Las plantillas de exportación de Godot 4.7.2 (*Editor > Manage Export Templates*) |
| Publicar | Docker Desktop (o Docker Engine con Compose) |
| Link público | Nada más: se usa Cloudflare Tunnel desde un contenedor |

## 3. Estructura del repositorio

```
softlearning/        Proyecto de Godot (se abre con project.godot)
  autoload/          Servicios globales: DepartmentManager, StatisticsTracker, PersistenceService
  core/              Lógica: sesión, motores de minijuego y pools de contenido
  scenes/            Pantallas (edificio/departamento, sesión y cada minijuego)
  resources/         Contenido editable (*.tres) y tema visual
  assets/            Imágenes
  tests/             Autoverificación (uc02_check.gd)
  softlearning/ y softlearning.zip   Export web anterior guardado en el repo (no lo usa Docker)
deploy/              Despliegue: Dockerfile, docker-compose.yml, nginx.conf (+ web/ generado, no versionado)
arquitectura/        Arquitectura general (7 bloques) y guía de conversión de diseño a Godot
uc_specs/            Especificaciones de casos de uso
diagramas/           Diagramas PlantUML
mockups/             Maquetas de pantalla
```

## 4. Correrlo en local

**Con el editor:** abre `softlearning/project.godot` en Godot 4.7.2 y pulsa *Ejecutar* (F5). En escritorio arranca a pantalla completa.

**Con línea de comandos**, desde `softlearning/`:

```
godot --path .
```

En un clon nuevo, la carpeta `.godot/` no existe (no se versiona). Abre el proyecto una vez en el editor o ejecuta antes:

```
godot --headless --path . --import
```

## 5. Exportar la versión web

Desde `softlearning/` (el preset «Web» ya está en `export_presets.cfg`; no usa hilos, así que no necesita cabeceras especiales):

```
godot --headless --path . --export-release "Web" ../deploy/web/index.html
```

Genera `index.html`, `index.js`, `index.wasm` (~38 MB), `index.pck` y los iconos dentro de `deploy/web/`. Esa carpeta no se sube al repo.

## 6. Publicarlo con Docker

Todo se ejecuta desde `deploy/` con Docker abierto.

**Levantar el juego en local:**

```
docker compose up -d --build
```

Queda en <http://localhost:8088>. Para otro puerto (por ejemplo si el 8088 está ocupado): `PORT=9000 docker compose up -d --build` (en PowerShell: `$env:PORT=9000; docker compose up -d --build`).

**Link público temporal** (Cloudflare Tunnel, sin cuenta):

```
docker compose --profile publico up -d --build
docker compose logs tunnel
```

El log muestra un link `https://<algo>.trycloudflare.com`; ese es el que se comparte. **Cambia cada vez que se levanta el túnel.**

**Link fijo:** crea un túnel con nombre en Cloudflare Zero Trust (*Networks > Tunnels*), apúntalo a `http://web:80` y levántalo con:

```
TUNNEL_TOKEN=<token> docker compose --profile fijo up -d
```

El token es un secreto: no lo escribas en archivos del repo.

## 7. Operación del día a día

| Tarea | Comando (desde `deploy/`) |
|---|---|
| Ver qué está corriendo | `docker compose ps` |
| Ver registros del juego | `docker compose logs -f web` |
| Ver el link público actual | `docker compose logs tunnel` |
| Publicar una versión nueva | Exportar de nuevo (sección 5) y `docker compose up -d --build` |
| Apagar todo | `docker compose --profile publico --profile fijo down` |

- Los servicios están con `restart: unless-stopped`: vuelven solos si Docker se reinicia, salvo que se hayan apagado con `down`.
- nginx responde con `Cache-Control: no-cache`: al publicar una versión nueva, los jugadores reciben la actualización la siguiente vez que abren el juego, sin vaciar caché.
- nginx comprime el `.wasm` (de ~38 MB a ~10 MB en la red). La primera carga puede tardar en conexiones lentas.

## 8. Progreso de los jugadores

| Versión | Dónde se guarda | Cómo reiniciarlo |
|---|---|---|
| Web | Almacenamiento del navegador del jugador, para ese sitio | Borrar los datos del sitio (DevTools > Application > Storage > *Clear site data*) o usar ventana de incógnito |
| Escritorio (Windows) | `%APPDATA%\Godot\app_userdata\softlearning\save\` | Borrar esa carpeta con el juego cerrado |

Contenido de la carpeta de guardado (archivos legibles):

- `department_state_<DEPARTAMENTO>.tres`: ELO y estado de cada uno de los 4 departamentos.
- `result_history.jsonl`: una línea JSON por resultado de minijuego (de aquí salen las estadísticas y la gráfica del histórico).

Respaldo y traslado: copiar la carpeta completa. El nombre de cada archivo `department_state_*` determina a qué departamento pertenece, así que se puede mover entre equipos. Un archivo ilegible no detiene el juego: ese departamento arranca desde cero y el archivo se deja intacto en disco.

## 9. Contenido del juego

Todo el contenido está en `softlearning/resources/` y se edita desde el editor de Godot (*FileSystem > doble clic en el `.tres` > Inspector*):

| Archivo | Contenido |
|---|---|
| `quiz_pool.tres` + `quiz_questions/` | Preguntas del Quiz (una `.tres` por pregunta) |
| `swipe_pool.tres` | Tarjetas de Swipe! |
| `narrative_pool.tres` | Escenarios de Narrativa (historia con huecos, banco de opciones, finales) |
| `train_pool.tres` | Secuencias de Ordena el tren |
| `bomb_pool.tres` | Bombas de Desactivar bomba |

Reglas para agregar contenido:

- Cada elemento tiene `id` (**único dentro de su pool**), `department` y `difficulty`. El `id` se usa para no repetir elementos en una misma sesión.
- Cada pregunta/tarjeta/escenario debe tener una dificultad y un departamento: el juego elige la dificultad según el ELO del jugador y, si no hay elementos de esa dificultad, usa la más cercana.
- Cada departamento debe tener elementos en los pools de Quiz, Swipe! y Narrativa (se usan en los 4), y en el de Ordena el tren / Desactivar bomba si es su departamento. Un pool vacío para un departamento rompe sus partidas.
- Después de editar, prueba el juego en local (sección 4) y vuelve a exportar (sección 5).

Valores que se ajustan en el código (se recomienda dejarlos como están salvo decisión del equipo):

| Qué | Valor actual | Dónde |
|---|---|---|
| Minijuegos por partida | 10 | `SEQUENCE_LENGTH` en `core/session_orchestrator.gd` |
| Tiempo máximo en pausa | 300 s (la partida termina sola y se guarda) | `pause_time_limit` en `core/session_orchestrator.gd` |
| Tiempo del Quiz / Ordena el tren / Bomba | 30 s / 60 s / 60 s | `time_limit` en cada `core/*_minigame.gd` |
| Intentos de Narrativa | 2 | `max_attempts` en `core/narrative_minigame.gd` |
| ELO inicial y factor K | 1000 y 32 | `core/db/models/department_state.gd`, `autoload/department_manager.gd` |
| ELO para poder subir de nivel | 1500 | `level_up_thresholds` en `autoload/department_manager.gd` |
| Minijuegos propios de cada departamento | Requerimientos: Bomba; Desarrollo de Software: Tren | `enabled_minigames` en `autoload/department_manager.gd` |

## 10. Verificación

Autoverificación del repo (reglas de ELO y pausa del Quiz), desde `softlearning/`. No guarda nada; debe terminar con `uc02_check: OK`:

```
godot --headless --path . -s res://tests/uc02_check.gd
```

Prueba manual tras publicar: abrir el link, entrar a un departamento, jugar un minijuego y pulsar «Salir» desde la pausa; al volver, el contador de «Total de jugados» debe haber aumentado.

## 11. Problemas frecuentes

| Síntoma | Causa probable y solución |
|---|---|
| `docker compose up` falla o no abre | Docker Desktop no está abierto |
| El puerto ya está en uso | Otro programa lo ocupa (en la PC donde se armó el despliegue el 8080 lo usa Oracle): usar `PORT=<otro>` |
| `docker compose build` falla al copiar `web/` | Falta exportar antes (sección 5) |
| El link `trycloudflare.com` dejó de funcionar | El link temporal cambia al reiniciar el túnel: `docker compose logs tunnel` para ver el nuevo, o usar link fijo |
| Tras publicar, un jugador ve la versión vieja | Recargar la página; nginx no cachea, pero el navegador puede conservar la pestaña abierta |
| La primera carga es lenta | El `.wasm` es pesado; depende de la conexión del jugador |
| El jugador dice que perdió su progreso | Cambió de navegador/equipo, borró datos del sitio o jugó en incógnito. El servidor no guarda progreso |
| Aparece «Ha ocurrido un error al guardar tu progreso» | No se pudo escribir el almacenamiento (suele ser espacio, permisos o un navegador en modo restringido). Lo de esa partida no quedó guardado; sigue solo en memoria hasta cerrar el juego |
| `Identifier not declared` al correr por línea de comandos | Falta importar el proyecto en un clon nuevo: `godot --headless --path . --import` |

## Limitaciones conocidas

- **«Subir nivel»** (UC-12) todavía no está implementado: el botón se activa a 1500 de ELO, pero aún no hace nada.
- El progreso no se puede consultar ni migrar desde el servidor (solo existe en el equipo de cada jugador).

## Documentación

- [`arquitectura/NAKOSU - GENERAL ARQUITECTURE.md`](arquitectura/NAKOSU%20-%20GENERAL%20ARQUITECTURE.md): los 7 bloques del sistema.
- [`arquitectura/GUIA CONVERSION DISEÑO A GODOT.md`](arquitectura/GUIA%20CONVERSION%20DISE%C3%91O%20A%20GODOT.md): cómo se traduce el diseño a Godot.
- [`uc_specs/`](uc_specs/): especificaciones de UC-02, UC-07 y UC-11. [`diagramas/`](diagramas/): diagramas PlantUML.
- [`deploy/README.md`](deploy/README.md): notas breves de despliegue.
- Manual de usuario con capturas (cómo se juega): documento *NAKOSU - Manual de operaciones* del Sprint 2, que se entrega aparte del repositorio.
