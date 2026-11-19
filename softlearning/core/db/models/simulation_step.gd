class_name SimulationStep
extends RefCounted
## Snapshot of the puzzle after one operation (UC-06.7). `index` is 1-based and
## the last step of an invalid run is the invalid operation itself.
##
## The states are copies (D3 / plan trap 3): a shared array would make every
## step show the state of the last one.

var index := 0
var operation: StackOperation
## Element pushed or popped by this operation; 0 when the operation was invalid.
var element := 0
## Remaining input, in delivery order (D4).
var input_state: Array[int] = []
## Stack from bottom to top.
var stack_state: Array[int] = []
var produced_state: Array[int] = []
var valid := true
## "" when valid.
var cause := ""
