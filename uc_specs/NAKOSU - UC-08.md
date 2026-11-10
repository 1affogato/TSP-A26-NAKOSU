# NAKOSU - UC-08

> Convertido automáticamente desde `NAKOSU - SOFTWARE REQUIREMENTS SPECIFICATION_v1.2` — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 2 · SRS v1.2, §2.3.4

### UC-08: Play Swipe! Minigame

**Principal actor:** Player

**Description:** The player is shown a single card containing an example related to the department's concepts and must swipe toward the category they believe it belongs to, among two or more possible options. The system determines whether the choice is correct and provides immediate feedback.

**Preconditions:**

- The Swipe! minigame has been selected by the system for the current session (UC-02.4).

**Principal flow:**

- UC-08.1 The system selects a concept from the pool corresponding to the department and fetches a related example.

- UC-08.2 The system presents the example along with the possible category options it may belong to.

- UC-08.3 The player swipes toward the option they consider correct.

- UC-08.4 The system determines whether the chosen category is correct and provides immediate feedback.

- UC-08.5 The minigame session ends and returns to UC-02.5.

**Alternative flows:**

- **UC-08.3.a1 – Incorrect swipe:** The player swipes toward the wrong option.

  - UC-08.3.a1.1 The system records the result as incorrect and provides the corresponding feedback.

  - UC-08.3.a1.2 The flow continues at UC-08.5.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The swipe result has been determined for use by UC-02.
