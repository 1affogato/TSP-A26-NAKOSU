class_name DbDefaults
extends RefCounted
## Values a brand-new save file starts with.
##
## Keeping them in one place guarantees that a profile created on the first
## run and a profile loaded from an old file end up in exactly the same state.

const DEFAULT_USERNAME := "Jugador"
const STARTING_COMPANY_LEVEL := 1
const STARTING_LEVEL := 1
const STARTING_ELO := 1000.0
