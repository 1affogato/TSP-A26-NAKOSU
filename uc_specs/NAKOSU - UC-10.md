# NAKOSU - UC-10

> Convertido automáticamente desde `NAKOSU - UC-10` (Google Docs) — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 3 · `NAKOSU - UC-10`

### UC-10: Play Connect the Cables Minigame

**Principal actor:** Player

**Description:** General minigame, usable in every department. The player is shown a board with a column of concepts and a column of examples related to the department's concepts, and must connect each concept with the example that belongs to it using cables. The system determines whether every connection is correct and provides immediate feedback.

**Preconditions:**

- The Connect the Cables minigame has been selected for the current session (UC-02.4).

**Principal flow:**

- UC-10.1 The system selects a board from the current department's pool according to the department's ELO.

- UC-10.2 The system displays the board's concepts in one column and their corresponding examples in a second column, with the examples presented in a scrambled order.

- UC-10.3 The player connects one concept with its corresponding example.

- UC-10.4 The system records the connection made by the player.

- UC-10.5 Repeat UC-10.3 and UC-10.4 until every concept has a connection.

- UC-10.6 The player confirms the completed connections.

- UC-10.7 The system evaluates each connection by comparing it with the correct concept-example pairing defined for the board.

- UC-10.8 The system displays whether the player's connections are correct and shows the correct pairings.

- UC-10.9 The system ends the minigame and returns control to UC-02.5.

**Alternative flows:**

- **UC-10.A1 – Change an existing connection**

  - UC-10.A1.1 The player selects a concept or example that already has a connection and connects it to a different example or concept, respectively.

  - UC-10.A1.2 The system replaces the previous connection with the new connection.

  - UC-10.A1.3 The flow returns to UC-10.3.

- **UC-10.A2 – Pause the minigame**

  - The pause behavior is handled by UC-02.4.a1. After the minigame resumes, the flow returns to the step from which it was interrupted.

- **UC-10.A3 – Exit the minigame**

  - The exit behavior is handled by UC-02.4.a2, which manages the termination of the current minigame session.

**Postconditions:**

- The system has evaluated the player's connections and made the result available to UC-02.5.

- The minigame has ended, and control has returned to UC-02.5.
