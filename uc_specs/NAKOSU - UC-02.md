# NAKOSU - UC-02

> Convertido automáticamente desde `NAKOSU - UC-02.docx` — no editar el .docx sin regenerar este .md.
> Fuente: `TSP-A26-NAKOSU\uc_specs\NAKOSU - UC-02.docx`

### UC-02: Play Minigame

**Principal actor:** Player

**Description:** Generic flow followed by every minigame session, in which the player completes a sequence of minigames, each either generic (usable across departments) or specific (tied to a single department). The system prepares this sequence from the pool available for the department the player has previously chosen, then launches each minigame in turn, handling its outcome before proceeding to the next.

**Preconditions:**

- A department has been selected, determining which minigames are available to play.

**Principal flow:**

- UC-02.1 The player starts a minigame session.

- UC-02.2 The system prepares a sequence of minigames from the pool available for the selected department (generic or department-specific).

- UC-02.3 The system loads the set of concepts associated with the department for the next minigame in the sequence.

- UC-02.4 The system launches the corresponding minigame, executing its specific use case (UC-03 to UC-10).

- UC-02.5 The minigame executes its own flow until reaching a completion condition and returns to this use case.

- UC-02.6 The system updates the department's ELO according to the minigame's result.

- UC-02.7 Repeat UC-02.3 to UC-02.6 until every minigame in the sequence has been played.

- UC-02.8 The system saves the resulting progress and minigame data.

- UC-02.9 The system ends the session and returns to the department.

**Alternative flows:**

- **UC-02.4.a1 – Pause Minigame:** The player chooses to pause the current minigame.

  - UC-02.4.a1.1 The system pauses the minigame and preserves its current state.

  - UC-02.4.a1.2 The minigame remains paused, awaiting the player's action.

  - UC-02.4.a1.3 The player chooses to resume.

  - UC-02.4.a1.4 The system restores the preserved state and resumes execution.

  - UC-02.4.a1.5 The flow returns to UC-02.5.

- **UC-02.4.a1.3.a1 – Session timeout:** If the minigame remains paused beyond a maximum time threshold without the player resuming, the system automatically ends the paused session.

  - UC-02.4.a1.3.a1.1 The system records no completion result for the remaining sequence and ends the session, returning to the department.

- **UC-02.4.a2 – Exit Minigame:** The player chooses to leave the session before the sequence is complete.

  - UC-02.4.a2.1 The system ends the session without registering a completion result for the remaining sequence.

  - UC-02.4.a2.2 The system saves the resulting progress and minigame data for the minigames already completed.

  - UC-02.4.a2.3 The system returns to the department.

**Exception flows:**

- **UC-02.8.e1 – Save failure:** The system is unable to save the resulting progress or minigame data.

  - UC-02.8.e1.1 The system reports the failure and ends the session, returning to the department.

**Postconditions:**

- The minigame session has been completed, paused, or exited.

- The department's ELO has been updated for each minigame completed within the session, and progress has been saved.
