# NAKOSU - UC-12

> Convertido automáticamente desde `NAKOSU - UC-12` (Google Docs) — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 3 · `NAKOSU - UC-12`

### UC-12: Level Up

**Principal actor:** Player

**Description:** Use case that describes the process in which the player can level up a department. The player initially starts with a very precarious, run down office, and can level up by increasing their ELO. There are 5 levels (0 to 4) and every department levels up separately. The user’s company level is just the sum of the level of all the departments. The user must complete a minigame session in order to level up. These level-up minigame sessions are scripted, meaning they don’t come from the random pool but from a set pool for that specific level. The user will level up if they complete the minigame session failing at most one question (one minigame result).

**ELO level-up thresholds:**

- Level 0: Default

- Level 1: 1100 ELO (Easy anchor).

- Level 2: 1600 ELO (Medium anchor).

- Level 3: 2100 ELO (Hard anchor).

- Level 4: 2600 ELO (Very Hard anchor).

Only one level-up can be completed per day, across all departments.

**Preconditions:**

- The department has reached the ELO threshold for its next level.

- The department has not reached level 4.

- The player has not completed a level-up for any department on the current calendar day.

**Principal flow:**

- UC-12.1 The player reaches the ELO threshold for the next level of a department.

- UC-12.2 The system detects the condition and offers the level-up option in the department view (UC-11.3.a1), provided the daily limit has not been used.

- UC-12.3 The player selects the level-up option.

- UC-12.4 The system loads the scripted minigame session for the target level.

- UC-12.5 The player completes the session, failing at most one minigame.

- UC-12.6 The system increases the department's level by one and updates its office sprite.

- UC-12.7 The system updates the company level.

- UC-12.8 The system marks the daily level-up as used.

- UC-12.9 The system saves the new department state.

- UC-12.10 The system returns to the department view.

**Alternative flows:**

- **UC-12.2.a1 – Maximum level reached:** The department is already at level 4.

  - UC-12.2.a1.1 The system does not offer the level-up option.

- **UC-12.2.a2 – Daily level-up already used:** The player has already completed a level-up for a department on the current calendar day.

  - UC-12.2.a2.1 The system does not offer the level-up option for any department until the next calendar day.

- **UC-12.5.a1 – Level-up session failed:** The player fails two or more minigames.

  - UC-12.5.a1.1 The system subtracts 25 ELO from the department.

  - UC-12.5.a1.2 The system keeps the department's current level.

  - UC-12.5.a1.3 The flow continues at UC-12.9.

- **UC-12.5.a2 – Level-up session interrupted:** The player exits the session (UC-02.4.a2) or the pause timeout ends it (UC-02.4.a1.3.a1).

  - UC-12.5.a2.1 The system treats the session as failed and proceeds with UC-12.5.a1.

**Exception flows:**

- **UC-12.4.e1 – Scripted session unavailable:** The system cannot load the scripted session for the target level.

  - UC-12.4.e1.1 The system reports the failure and cancels the level-up.

- **UC-12.9.e1 – Save failure:** The system is unable to save the new department state.

  - UC-12.9.e1.1 The system reports the failure and cancels the level-up.

**Postconditions:**

- The department's level has increased by one.

- The department's office sprite shows the new level.

- The company level has been increased by one.

- The new department state has been saved.

- The daily level-up has been marked as used for the current calendar day.
