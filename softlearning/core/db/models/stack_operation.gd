class_name StackOperation
extends Resource
## One operation of the Stack Puzzle editor (UC-06.4.a1/a3): a PUSH (take the
## next element of the input structure and push it) or a POP (pop the top of
## the Stack into the produced output). On Deque levels a PUSH also stores the
## end the element is taken from (UC-06.4.a2 / UC-06.4.a2.a1).
##
## Operations are never authored or saved: StackPuzzleMinigame builds them from
## the player's edits and the view renders them with to_text().

enum OperationKind { PUSH, POP }
enum DequeEnd { NONE, FRONT, REAR }

@export var kind: OperationKind = OperationKind.PUSH
## NONE on Queue and Priority Queue levels; FRONT/REAR only on Deque levels.
@export var deque_end: DequeEnd = DequeEnd.NONE


static func create(new_kind: OperationKind, new_end: DequeEnd = DequeEnd.NONE) -> StackOperation:
	var operation := StackOperation.new()
	operation.kind = new_kind
	operation.deque_end = new_end
	return operation


## Authoring helper: "PUSH" | "PUSH_FRONT" | "PUSH_REAR" | "POP" -> operation.
## Unknown tokens return null.
static func from_token(token: String) -> StackOperation:
	match token.strip_edges().to_upper():
		"PUSH":
			return create(OperationKind.PUSH, DequeEnd.NONE)
		"PUSH_FRONT":
			return create(OperationKind.PUSH, DequeEnd.FRONT)
		"PUSH_REAR":
			return create(OperationKind.PUSH, DequeEnd.REAR)
		"POP":
			return create(OperationKind.POP, DequeEnd.NONE)
	return null


func is_pop() -> bool:
	return kind == OperationKind.POP


## "PUSH" | "PUSH · frente" | "PUSH · final" | "POP".
func to_text() -> String:
	if is_pop():
		return "POP"
	match deque_end:
		DequeEnd.FRONT:
			return "PUSH · frente"
		DequeEnd.REAR:
			return "PUSH · final"
		_:
			return "PUSH"
