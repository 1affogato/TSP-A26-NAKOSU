# NAKOSU - UC-01

> Convertido automáticamente desde `NAKOSU - UC-01` (Google Docs) — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 3 · `NAKOSU - UC-01`

### UC-01: Start with tutorial

**Principal actor:** Player

**Description:** Use case that describes the process of the player’s first time opening the app. It describes the tutorial that shows the player the basic options and systems such as ELO, minigames (not specific minigames, but the minigame mechanic overall), and more. It will consist of floating windows with text where the user progresses by clicking on the element the tutorial step requires. It will guide the user onto playing a minigame session and, once it finishes, a final message demonstrating the ELO change and wishing luck to the player.

The tutorial is mandatory: the player cannot skip it. The guided minigame session updates the department's ELO like a normal session, but the adjustment is amplified while the system places the player: the first results weigh more and the weight decreases with each result until it returns to the normal value at the end of the session.

**Preconditions:**

- The player opens the application for the first time.

- The tutorial has not been marked as completed in the saved progress.

**Principal flow:**

- UC-01.1 The player opens the app for the first time.

- UC-01.2 The system detects that the tutorial has not been completed and starts it before the player can use the main interface.

- UC-01.3 The system displays a floating window that introduces the departments and highlights the department buttons. The user can freely choose any department.

- UC-01.4 The player clicks on a department button, entering the selected department and marking the step as completed.

- UC-01.5 The system displays a floating window and highlights the ELO graph to introduce the ELO system.

- UC-01.6 The user clicks on any part of the screen, marking the step as completed.

- UC-01.7 The system highlights the button that starts a minigame session in the selected department.

- UC-01.8 The player starts the guided minigame session, which executes UC-02.

- UC-01.9 The system applies the placement adjustment to the ELO update of each result of the guided session (UC-02.6): the first results weigh more, and the weight decreases with each result until it returns to the normal value at the end of the session. The first weight is 10x, the next question is 9x, then 8x and so on.

- UC-01.10 When UC-02 ends, the system displays a final floating window with the ELO change produced by the session and a farewell wishing the player luck.

- UC-01.11 The system marks the tutorial as completed by clicking anywhere on the screen.

- UC-01.12 The system marks the tutorial as completed internally to not repeat it again, closes it and returns control to the player in the department view.

**Alternative flows:**

- **UC-01.2.a1 – Interrupted tutorial:** The player closes the application before completing the tutorial.

  - UC-01.2.a1.1 TThe tutorial starts over (go to UC-01.2).

- **UC-01.4.a1 – Wrong element selected:** The player clicks an element other than the highlighted one.

  - UC-01.4.a1.1 The system does not advance the tutorial and keeps the current step active.

  - UC-01.4.a1.3 The flow returns to UC-01.4.

- **UC-01.8.a1 – Guided session exited:** The player leaves the guided minigame session before completing it (UC-02.4.a2).

  - UC-01.8.a1.1 The guided minigame session is marked as completed.

  - UC-01.8.a1.2 The flow follows to UC-01.10.

**Exception flows:**

- **UC-01.11.e1 – Save failure:** The system is unable to save the tutorial completion state.

  - UC-01.11.e1.1 The system reports the failure and keeps the tutorial marked as incomplete.

  - UC-01.11.e1.2 The tutorial is shown again on the next launch.

**Postconditions:**

- The player has been introduced to the departments, the ELO and the minigame mechanic.

- The guided minigame session has been completed and its results have been saved.

- The ELO change produced by the guided session has been presented to the player.

- The tutorial has been marked as completed and its state has been saved.
