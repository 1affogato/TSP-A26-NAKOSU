# NAKOSU - UC-06

> Convertido automáticamente desde `NAKOSU - UC-06` (Google Docs) — no editar la fuente sin regenerar este .md.
> Fuente: Google Drive · Sprint 3 · `NAKOSU - UC-06`

### UC-06: Play Stack Puzzle Minigame

**Principal actor:** Player

**Description:** Department-specific minigame of the Data Structures and Algorithms department. The player receives an input sequence and a target output sequence. The input sequence is held in a level-defined input structure (Queue, Deque or Priority Queue), while a Stack is the central structure in every level. Using a simple editor, the player designs an ordered sequence of PUSH and POP operations: a PUSH takes the next element from the input structure and pushes it onto the Stack, and a POP removes the top element of the Stack and appends it to the produced output. The player then executes the sequence and the system simulates it step by step, showing the state of the input structure, the Stack and the produced output. The sequence is correct when the produced output matches the target output. If the sequence is incorrect or contains an invalid operation, the player may edit it and execute it again while attempts remain. Once the result is determined, the system presents a feedback screen with a valid operation sequence, and returns only correct or incorrect to UC-02.

**Preconditions:**

- The Stack Puzzle minigame has been selected for the current session (UC-02.4).

- The selected department is Data Structures and Algorithms.

- The concepts associated with the department have been loaded (UC-02.3).

**Principal flow:**

- UC-06.1 The system selects a puzzle from the pool of the department according to the department's ELO. The puzzle defines the input sequence, the target output sequence, the input structure (Queue, Deque or Priority Queue), the starting attempts and at least one valid operation sequence.

- UC-06.2 The system initializes the puzzle: it loads the input sequence into the input structure, empties the Stack and the produced output, and initializes the attempts with their starting value.

- UC-06.3 The system presents the puzzle: the input structure with its contents and delivery rule, the target output sequence, the Stack, the produced output, the operation editor, the attempts indicator and the execution control.

- UC-06.4 The player builds the operation sequence in the editor by adding PUSH and POP operations in the desired order. On Deque levels, a PUSH also requires the end from which the element is taken. On Priority Queue levels, during simulation, the PUSH operation selects an element from the input based on whether the level is in max-priority or min-priority mode.

- UC-06.5 The system enables execution once the editor contains at least one operation.

- UC-06.6 The player executes the operation sequence.

- UC-06.7 The system simulates the operations from the initial state in the order established by the editor, updating the input structure, the Stack and the produced output after each operation, and shows the state at each step.

- UC-06.8 The system compares the produced output with the target output at the end of the operation sequence. If they are equal and every operation was valid, the result is correct.

- UC-06.9 The system presents the feedback screen: the produced output, the target output, a valid operation sequence, and a short explanation of how the input structure and the Stack produce the target output.

- UC-06.10 The minigame ends and returns the result (correct or incorrect) to UC-02.5.

**Alternative flows:**

- **UC-06.4.a1 – Insert a PUSH operation:** The player inserts a PUSH operation into the operation sequence.

  - UC-06.4.a1.1 The player selects the position in the operation sequence where the PUSH operation will be inserted.

  - UC-06.4.a1.2 The player adds the PUSH operation. On Deque levels, the player also selects the end from which the element is taken (UC-06.4.a2).

  - UC-06.4.a1.3 The system inserts the PUSH operation at the selected position and updates the operation sequence in the editor without any penalty.

  - UC-06.4.a1.4 The flow returns to UC-06.4.

- **UC-06.4.a2 – Select the front end (Deque levels):** On a Deque level, when the player adds a PUSH operation and chooses the front end, the element is taken from the front of the Deque.

  - UC-06.4.a2.1 When the player adds a PUSH operation, the system presents the option to take the element from the front or from the rear of the Deque.

  - UC-06.4.a2.2 The player selects the front end.

  - UC-06.4.a2.3 The system records the front end as part of the PUSH operation.

  - UC-06.4.a2.4 The flow returns to UC-06.4.

- **UC-06.4.a2.a1 – Select the rear end (Deque levels):** At UC-06.4.a2.1, the player selects the rear end instead of the front.

  - UC-06.4.a2.a1.1 The player selects the rear end.

  - UC-06.4.a2.a1.2 The system records the rear end as part of the PUSH operation.

  - UC-06.4.a2.a1.3 The flow returns to UC-06.4.

- **UC-06.4.a3 – Insert a POP operation:** The player inserts a POP operation into the operation sequence.

  - UC-06.4.a3.1 The player selects the position in the operation sequence where the POP operation will be inserted.

  - UC-06.4.a3.2 The player adds the POP operation.

  - UC-06.4.a3.3 The system inserts the POP operation at the selected position and updates the operation sequence in the editor without any penalty.

  - UC-06.4.a3.4 The flow returns to UC-06.4.

- **UC-06.4.a4 – Remove an operation:** The player removes an existing operation from the operation sequence.

  - UC-06.4.a4.1 The player selects the operation to remove.

  - UC-06.4.a4.2 The system removes the selected operation and closes the gap in the operation sequence.

  - UC-06.4.a4.3 The system updates the editor without any penalty.

  - UC-06.4.a4.4 The flow returns to UC-06.4.

- **UC-06.4.a5 – Move an operation:** The player changes the position of an existing operation in the operation sequence.

  - UC-06.4.a5.1 The player selects the operation to move.

  - UC-06.4.a5.2 The player selects the new position in the operation sequence.

  - UC-06.4.a5.3 The system moves the operation to the new position and updates the editor without any penalty.

  - UC-06.4.a5.4 The flow returns to UC-06.4.

- **UC-06.4.a6 – Clear the operation sequence:** The player clears the editor.

  - UC-06.4.a6.1 The player requests to clear the operation sequence.

  - UC-06.4.a6.2 The system removes every operation from the editor and disables execution.

  - UC-06.4.a6.3 The flow returns to UC-06.4.

- **UC-06.7.a1 – Invalid operation:** During the simulation, a PUSH is executed on an empty input structure or a POP is executed on an empty Stack.

  - UC-06.7.a1.1 The system stops the simulation at the invalid operation.

  - UC-06.7.a1.2 The system marks the execution as invalid, deducts one attempt and shows the number of the invalid operation and its cause, without revealing a valid operation sequence.

  - UC-06.7.a1.3 If attempts remain, the flow returns to UC-06.4, keeping the operation sequence.

  - UC-06.7.a1.4 If no attempts remain, the system sets the result as incorrect and the flow continues at UC-06.9.

- **UC-06.8.a1 – Output mismatch with attempts remaining:** The produced output does not match the target output and the player still has attempts.

  - UC-06.8.a1.1 The system deducts one attempt.

  - UC-06.8.a1.2 The system tells the player that the produced output does not match the target output and shows the produced output, without revealing a valid operation sequence.

  - UC-06.8.a1.3 The flow returns to UC-06.4, keeping the operation sequence.

- **UC-06.8.a2 – Attempts exhausted:** The produced output does not match the target output and no attempts remain.

  - UC-06.8.a2.1 The system sets the result as incorrect.

  - UC-06.8.a2.2 The flow continues at UC-06.9.

Pause and exit are not repeated here: they are handled by UC-02.4.a1 and UC-02.4.a2.

**Postconditions:**

- The minigame result (correct or incorrect) has been determined for use by UC-02.

- The feedback screen with the produced output, the target output and a valid operation sequence has been presented.

**Notes:**

- Any operation sequence that produces the target output is accepted; a puzzle may have more than one valid solution.

- The valid operation sequence shown in the feedback screen is one of the solutions stored with the puzzle.

**Level variants:**

- Queue: Delivery rule: first in, first out. Elements are delivered in the order they appear in the input sequence. PUSH behavior: takes the element at the front.

- Deque: Delivery rule: elements can be taken from the front or from the rear. PUSH behavior: takes the element from the end selected by the player (front or rear).

- Priority Queue: Delivery rule: the level indicates whether it is min-priority or max-priority. In max-priority mode the element with the largest integer is delivered first; in min-priority mode the element with the smallest integer is delivered first. PUSH behavior: during simulation, takes the element determined by the level's priority mode; the player does not choose the element.

**Level variant notes:**

- Difficulty: Queue is the introductory level; Deque and Priority Queue are both more difficult than Queue, with no defined order of difficulty between them.

- Priority Queue sequences: In Priority Queue levels, the input and target sequences are integers, and each integer is both the element and its priority.
