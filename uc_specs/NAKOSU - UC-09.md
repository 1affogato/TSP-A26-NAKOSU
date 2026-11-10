# NAKOSU - UC-09

> Convertido automáticamente desde `NAKOSU - SOFTWARE REQUIREMENTS SPECIFICATION_v1.2` — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 2 · SRS v1.2, §2.3.5

### UC-09: Play Narrative Fill-in-the-Blank Minigame

**Principal actor:** Player

**Description:** The player takes on a software role (for example Product Owner or Junior Developer) inside a short narrative scenario and resolves it by filling every blank embedded in the story. Each blank is a decision tied to a department concept, such as classifying a client's statement as a business, user or system requirement, or choosing the data structure that fits a stated system need. The player fills the blanks from a shared bank of eight answer options that mixes correct answers with distractors: plausible but wrong options, or false ones such as emotional requirements. An option may be used in more than one blank.

The player answers by filling all the blanks and then confirming. If the answers are not all correct, the player tries again while attempts remain. Attempts work like lives, presented through a narrative skin chosen by the scenario (Credibility, Budget or Sprint time); the skin changes how attempts are shown, not how they work. When the answers are correct or the attempts run out, the player reaches a feedback screen with the correct answers and a short closing dialogue that ends the story. The minigame returns only correct or incorrect to UC-02.

**Preconditions:**

- The Narrative Fill-in-the-Blank minigame has been selected for the current session (UC-02.4).

- The concepts associated with the department have been loaded (UC-02.3).

**Principal flow:**

- UC-09.1 The system selects a narrative scenario from the pool of concepts corresponding to the department. The scenario defines the player's role, the story text with its blanks, the bank of eight options and the narrative skin of the attempts (Credibility, Budget or Sprint time).

- UC-09.2 The system initializes the attempts with their starting value, shown through the scenario's skin.

- UC-09.3 The system presents the narrative: the player's role, the context, the story text with its blanks, the bank of eight answer options and the attempts indicator.

- UC-09.4 The player fills every blank with an option from the bank.

- UC-09.5 The system enables confirmation once every blank is filled.

- UC-09.6 The player confirms the answers.

- UC-09.7 The system checks the answers. If every blank holds the correct option, the result is correct.

- UC-09.8 The system presents the feedback screen: the correct answer for every blank and a short closing dialogue that ends the story well if the result is correct, or badly if it is incorrect.

- UC-09.9 The minigame ends and returns the result (correct or incorrect) to UC-02.5.

**Alternative flows:**

- **UC-09.4.a1 – Rearrange answers:** The player changes the answers before confirming.

  - UC-09.4.a1.1 The player replaces, clears or moves an option between blanks.

  - UC-09.4.a1.2 The system updates the blanks without any penalty.

  - UC-09.4.a1.3 The flow returns to UC-09.4.

- **UC-09.7.a1 – Incorrect answers with attempts remaining:** At least one blank holds a wrong option and the player still has attempts.

  - UC-09.7.a1.1 The system deducts one attempt, shown through the scenario's skin (credibility lost, budget spent or sprint time used).

  - UC-09.7.a1.2 The system tells the player that the answers did not work, without revealing which blanks are wrong or the correct options.

  - UC-09.7.a1.3 The flow returns to UC-09.4, keeping the player's current answers.

- **UC-09.7.a2 – Attempts exhausted:** At least one blank holds a wrong option and no attempts remain.

  - UC-09.7.a2.1 The system sets the result as incorrect.

  - UC-09.7.a2.2 The flow continues at UC-09.7.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The minigame result (correct or incorrect) has been determined for use by UC-02.

- The feedback screen with the correct answers and the closing dialogue has been presented.
