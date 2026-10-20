class_name BombQuestion
extends Resource
## The question of one lock of a Bomb (UC-04, "BombQuestion"): exactly three
## wires, each labelled with one answer, and one of them correct (R04-2).

@export var text: String = ""
@export var wires: Array[String] = []
## Index into `wires` of the right wire.
@export var correct_wire_index: int = 0


## UC-04.5
func is_correct_wire(wire: String) -> bool:
	var correct := get_correct_wire()
	return not correct.is_empty() and wire == correct


## The right wire, or "" when the index points outside `wires`.
func get_correct_wire() -> String:
	if correct_wire_index < 0 or correct_wire_index >= wires.size():
		return ""
	return wires[correct_wire_index]


func is_valid() -> bool:
	return not text.is_empty() and wires.size() == 3 and not get_correct_wire().is_empty()
