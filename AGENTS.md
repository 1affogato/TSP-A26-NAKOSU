# AGENTS.md

## Project

Godot 4.7 (GL Compatibility) educational minigame. All executable code lives in `softlearning/`; run every Godot command from that directory.

The repo is mostly docs: `arquitectura/` (7-block architecture), `uc_specs/` (UC-02/07/11), `diagramas/` (PlantUML), `mockups/`. Docs are in Spanish; code comments are mostly English.

## Commands

```bash
cd softlearning
godot --path .                                 # run the game
godot --headless --path . --quit               # import + parse check (no test output)
godot --headless --path . -s res://tests/uc02_check.gd   # only test suite
```

There is no test framework, lint, typecheck, or CI. `tests/uc02_check.gd` is a standalone `SceneTree` script that exits nonzero on failure. Run from `softlearning/` so autoloads load.

## Architecture

Follow the 7-block design; block names in comments (`B1`...`B7`) map to it:

- `autoload/department_manager.gd` (B1), `autoload/statistics_tracker.gd` (B6), `autoload/persistent_service.gd` (B7) are autoload singletons.
- `core/session_orchestrator.gd` (B4) is **not** an autoload; it is a child of `scenes/session_view.tscn`.
- `core/minigame.gd` (B3) is the abstract contract; `core/quiz_minigame.gd` (B5) implements it.
- `core/db/models/` holds Resources (pure data). `core/db/json_util.gd` coerces parsed JSON values.
- Scenes: `department_view.tscn` (main scene), `session_view.tscn`, `quiz_view.tscn`.

Convention: views call logic downward (`start()`, `answer()`, `pause()`); logic emits signals upward (`finished`, `question_ready`, `answered`) and never calls views directly.

## Persistence and content gotchas

- Saves go under `user://save/`: one `department_state_<KEY>.tres` per department plus append-only `result_history.jsonl`. The architecture guide still recommends JSON for department states, but the code actually uses `.tres` (see `persistent_service.gd`); follow the code.
- `.tres` files store `department`/`difficulty` as raw enum ints (`result_history.jsonl` uses names). Append new enum values; never insert or reorder `Enums.Department`/`Difficulty` or existing saves and quiz questions silently change meaning.
- Quiz questions are Resources in `resources/quiz_questions/`. Adding one requires both the new `.tres` **and** an `ext_resource` plus an entry in the `questions` array of `resources/quiz_pool.tres`.
- In a question `.tres`, omitted `department`/`difficulty` silently default to `DATA_STRUCTURES`/`FACIL` (enum value 0). Always set them explicitly.
- Authored tuning data lives in `DepartmentManager`: `department_names`, `enabled_minigames`, `level_up_thresholds`, `K_FACTOR`. These are not persisted.
- ELO anchors are `Enums.difficulty_to_elo()` (1000/1500/2000/2500); difficulty selection weights are in `MinigamePool._select_difficulty()`.

## Adding a minigame

1. Extend `Minigame` and implement all abstract methods (`start`, `pause`, `resume`, `abort`, `get_result`).
2. Add a `TYPE` constant and a match arm in `SessionOrchestrator._create_minigame()`.
3. Register it in `generic_minigames` or `DepartmentManager.enabled_minigames`.
4. Wire its view in `SessionView.show_minigame()`, which currently assumes `$QuizView` — this needs a branch per minigame type.

## Repo hygiene

- `.uid` and `.import` files are tracked; keep them when moving/renaming assets, and regenerate them by opening the project rather than hand-editing.
- `softlearning/softlearning/` and `softlearning/softlearning.zip` are committed web-export artifacts. Do not hand-edit generated `.js`, `.wasm`, `.pck`, or `.zip`; the export preset writes to `softlearning/softlearning/softlearning.html`.
- `.godot/` is ignored and must not be committed.
