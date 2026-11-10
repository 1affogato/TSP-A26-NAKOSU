# NAKOSU - UC-03

> Convertido automáticamente desde `NAKOSU - SOFTWARE REQUIREMENTS SPECIFICATION_v1.2` — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 2 · SRS v1.2, §2.3.6

### UC-03: Play Train Sorting Minigame ("Ordena el tren")

**Principal actor:** Player

**Description:** Department-specific minigame of the Software development department. The player is shown a train whose wagons each carry one concept, in scrambled order, and must arrange the wagons into the sequence requested by the instruction (for example, the steps of an algorithm). The system determines whether the final order is correct and provides immediate feedback.

**Preconditions:**

- The Train Sorting minigame has been selected for the current session (UC-02.4).

- The selected department is Software development.

**Principal flow:**

- UC-03.1 The system selects a sequence from the pool of the department, according to the department's ELO.

- UC-03.2 The system presents the instruction and the wagons in scrambled order.

- UC-03.3 The system starts the timer.

- UC-03.4 The player moves the wagons to arrange them.

- UC-03.5 The player confirms the order within the time limit.

- UC-03.6 The system determines whether the confirmed order is correct and provides immediate feedback, showing the correct order.

- UC-03.7 The minigame ends and returns to UC-02.5.

**Alternative flows:**

- **UC-03.5.a1 – Time runs out:** The player does not confirm an order within the time limit.

  - UC-03.5.a1.1 The system detects that the timer has expired.

  - UC-03.5.a1.2 The system records the result as incorrect and provides the corresponding feedback, showing the correct order.

  - UC-03.5.a1.3 The flow continues at UC-03.7.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The train sorting result (correct or incorrect) has been determined for use by UC-02.
