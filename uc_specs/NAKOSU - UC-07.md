# NAKOSU - UC-07

> Convertido automáticamente desde `NAKOSU - UC-07.docx` — no editar el .docx sin regenerar este .md.
> Fuente: `TSP-A26-NAKOSU\uc_specs\NAKOSU - UC-07.docx`

### UC-07: Play Quiz Minigame

**Principal actor:** Player

**Description:** The player answers a single multiple-choice question related to the department's concepts. The question presents its content in a given format along with four answer options, one of them correct, and the system provides immediate feedback on the response.

**Preconditions:**

- The Quiz minigame has been selected for the current session (UC-02.4).

**Principal flow:**

- UC-07.1 The system selects a question from the pool of concepts corresponding to the department.

- UC-07.2 The system presents the question, along with four answer options, one of them correct.

- UC-07.3 The player selects an answer option within the time limit.

- UC-07.4 The system records the selected answer and determines whether it is correct, providing immediate feedback.

- UC-07.5 The minigame session ends and returns to UC-02.5.

**Alternative flows:**

- **UC-07.3.a1 – Time runs out:** The player does not select an option within the time limit.

  - UC-07.3.a1.1 The system detects that the question timer has expired.

  - UC-07.3.a1.2 The system records the question as incorrect and provides the corresponding feedback.

  - UC-07.3.a1.3 The flow continues at UC-07.5.

**Postconditions:**

- The quiz result has been determined for use by UC-02.
