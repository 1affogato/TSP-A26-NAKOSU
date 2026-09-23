# NAKOSU - UC-11

> Convertido automáticamente desde `NAKOSU - UC-11.docx` — no editar el .docx sin regenerar este .md.
> Fuente: `TSP-A26-NAKOSU\uc_specs\NAKOSU - UC-11.docx`

### UC-11: Consult Department Stats

**Principal actor:** Player

**Description:** The player selects a department and consults its general and detailed statistics related to its minigames, allowing them to track their performance and progress over time.

**Preconditions:**

- The player has an active game session.

**Principal flow:**

- UC-11.1 The player selects a specific department.

- UC-11.2 The system retrieves the statistics associated with the selected department and its related minigames.

- UC-11.3 The system displays the general statistics of the selected department.

- UC-11.4 The player selects a specific statistic to consult in greater detail.

- UC-11.5 The system displays the detailed information of the selected statistic.

**Alternative flows:**

- **UC-11.3.a1 – Upgrade available:** After UC-11.3, the system detects that the selected department meets the requirements to level up.

  - UC-11.3.a1.1 The player initiates UC-12 (Upgrade Department)..

**Postconditions:**

- The selected department's statistics have been displayed.
