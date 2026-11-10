# NAKOSU - UC-04

> Convertido automáticamente desde `NAKOSU - SOFTWARE REQUIREMENTS SPECIFICATION_v1.2` — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 2 · SRS v1.2, §2.3.3 (Bomb Defusal)

### UC-04: Play Bomb Defusal Minigame ("Desactivar bomba")

**Principal actor:** Player

**Description:** Department-specific minigame of the Requirements department. The player is shown a bomb with a countdown and three locks. Each lock has a question about requirements and three wires, each wire labelled with one answer option; cutting the correct wire deactivates the lock. The player must deactivate the three locks before the countdown ends. The system determines whether the bomb was defused and provides immediate feedback.

**Preconditions:**

- The Bomb Defusal minigame has been selected by the system for the current session (UC-02.4).

- The selected department is Requirements.

**Principal flow:**

- UC-04.1 The system selects a bomb from the pool of the department, according to the department's ELO.

- UC-04.2 The system presents the bomb with the question of its first lock and the wires of that question.

- UC-04.3 The system starts the countdown.

- UC-04.4 The player cuts one wire.

- UC-04.5 The system determines that the wire that was cut is the correct one.

- UC-04.6 The system deactivates the lock.

- UC-04.7 The system presents the question of the next lock and its wires.

- UC-04.8 Repeat UC-04.4 to UC-04.7 until the three locks are deactivated.

- UC-04.9 The system records the result as correct and provides immediate feedback.

- UC-04.10 The minigame ends and returns to UC-02.5.

**Alternative flows:**

- **UC-04.4.a1 – Time runs out:** The countdown ends before the three locks are deactivated.

  - UC-04.4.a1.1 The system detects that the countdown has reached zero.

  - UC-04.4.a1.2 The system records the result as incorrect and provides the corresponding feedback, showing the correct wire of the current question.

  - UC-04.4.a1.3 The flow continues at UC-04.10.

- **UC-04.5.a1 – Wrong wire:** The wire that was cut is not the correct one.

  - UC-04.5.a1.1 The system records the result as incorrect and provides the corresponding feedback, showing the correct wire.

  - UC-04.5.a1.2 The flow continues at UC-04.10.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The bomb defusal result (correct or incorrect) has been determined for use by UC-02.
