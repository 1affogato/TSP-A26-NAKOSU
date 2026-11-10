# NAKOSU - UC-05

> Convertido automáticamente desde `NAKOSU - UC-05.docx` — no editar el .docx sin regenerar este .md.
> Fuente: Google Drive · Sprint 3 · `NAKOSU - UC-05.docx`

### UC-05: Play Concept Puzzle Minigame ("Rompecabezas de conceptos")

**Principal actor:** Player

**Description:** Department-specific minigame of the Coding Paradigms department. The player is shown a puzzle board divided into categories of the department (for example, "Object-oriented" and "Functional"), each with empty slots, and a tray with pieces in scrambled order. Each piece carries one concept or code example (for example, "Inheritance" or "Pure function"). Depending on the difficulty, the tray can also hold decoy pieces that belong to none of the categories shown. The player fills every slot with a piece of the category it belongs to, leaves the decoys in the tray, and checks the puzzle. The result is correct if every slot holds a piece of its category within 3 checks. The minigame has no time limit.

**Preconditions:**

- The Concept Puzzle minigame has been selected for the current session (UC-02.4).

- The selected department is Coding Paradigms.

**Principal flow:**

- UC-05.1 The system selects a puzzle from the pool of the department, according to the department's ELO.

- UC-05.2 The system displays the categories of the puzzle, each with its empty slots, and the pieces in scrambled order in the tray.

- UC-05.3 The player places a piece from the tray in an empty slot.

- UC-05.4 The system records the placement.

- UC-05.5 Repeat UC-05.3 and UC-05.4 until every slot holds a piece.

- UC-05.6 The player checks the puzzle.

- UC-05.7 The system evaluates every placed piece by comparing it with the category of its slot.

- UC-05.8 The system displays that every piece is in its correct category.

- UC-05.9 The system records the result as correct.

- UC-05.10 The system ends the minigame and returns control to UC-02.5.

**Alternative flows:**

- **UC-05.3.a1 – Move a placed piece:** At any point between UC-05.3 and UC-05.6, the player moves a piece that is placed and not locked.

  - UC-05.3.a1.1 The player moves the piece back to the tray or to another empty slot.

  - UC-05.3.a1.2 The system records the new position of the piece.

  - UC-05.3.a1.3 The flow returns to UC-05.3.

- **UC-05.3.a2 – Place a piece on a slot with a movable piece:** At any point between UC-05.3 and UC-05.6, the player places a piece in a slot that already holds a piece that is not locked.

  - UC-05.3.a2.1 The system places the new piece in the slot.

  - UC-05.3.a2.2 The system returns the previous piece to the tray.

  - UC-05.3.a2.3 The flow returns to UC-05.3.

- **UC-05.3.a3 – Place a piece on a slot with a locked piece:** At any point between UC-05.3 and UC-05.6, the player places a piece in a slot that holds a locked piece.

  - UC-05.3.a3.1 The system returns the new piece to the position it came from.

  - UC-05.3.a3.2 The flow returns to UC-05.3.

- **UC-05.7.a1 – Incorrect pieces with checks remaining:** At least one piece is in a slot of another category, or is a decoy, and the player has used fewer than 3 checks.

  - UC-05.7.a1.1 The system locks the pieces that are in their correct category.

  - UC-05.7.a1.2 The system returns the incorrect pieces to the tray.

  - UC-05.7.a1.3 The system displays the number of checks left.

  - UC-05.7.a1.4 The flow returns to UC-05.3.

- **UC-05.7.a2 – Incorrect pieces with no checks remaining:** At least one piece is in a slot of another category, or is a decoy, and it was the player's third check.

  - UC-05.7.a2.1 The system records the result as incorrect.

  - UC-05.7.a2.2 The system displays the correct category of every piece and which pieces are decoys.

  - UC-05.7.a2.3 The flow continues at UC-05.10.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The puzzle result (correct or incorrect) has been determined for use by UC-02.

- The minigame has ended, and control has returned to UC-02.5.
