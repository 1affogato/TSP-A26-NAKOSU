@abstract
class_name Minigame
extends Node
## Minigame contract (B3): the only thing SessionOrchestrator (B4) knows about
## a minigame. Input: department + ELO through start(). Output: one
## MinigameResult, delivered with `finished` (UC-02.5).
##
## Every engine (B5) extends this class and implements all of its methods;
## Godot refuses to instantiate an engine that leaves one out.

## The minigame reached its end condition. Never emitted after abort().
signal finished(result: MinigameResult)

var department: Enums.Department
var elo: float
var paused := false


## UC-02.3 / UC-02.4: takes the item for `new_department` at `new_elo` from its
## pool and begins.
@abstract func start(new_department: Enums.Department, new_elo: float) -> void

## UC-02.4.a1.1: keeps the current state (timers included) until resume().
@abstract func pause() -> void

## UC-02.4.a1.4: continues from the state kept by pause().
@abstract func resume() -> void

## UC-02.4.a2 / UC-02.4.a1.3.a1: ends right away without a result.
@abstract func abort() -> void

@abstract func get_result() -> MinigameResult
