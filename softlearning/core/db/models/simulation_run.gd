class_name SimulationRun
extends RefCounted
## One execution of the sequence (UC-06.7).
##
## `steps` holds one SimulationStep per executed operation. When the run is
## invalid the last step is the invalid operation and there are no steps after
## it (UC-06.7.a1.1), so size() is the total the step navigation uses.

var steps: Array[SimulationStep] = []
var produced: Array[int] = []
var valid := true
## 1-based; 0 when valid.
var invalid_index := 0


func size() -> int:
	return steps.size()


## 1-based; null out of range.
func get_step(index: int) -> SimulationStep:
	if index < 1 or index > steps.size():
		return null
	return steps[index - 1]


## Null when empty.
func get_last_step() -> SimulationStep:
	if steps.is_empty():
		return null
	return steps.back()


## D5: the produced output is exactly the target.
func matches(target: Array[int]) -> bool:
	return produced == target
