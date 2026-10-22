class_name NarrativeScenario
extends Resource
## One scenario of the Narrative Fill-in-the-Blank pool (UC-09,
## "NarrativeScenario"): the player's role, the story with its blanks, the bank
## of eight options and the skin of the attempts.
##
## Authored content that lives in NarrativePool (B2); NarrativeMinigame
## receives exactly one (UC-09.1). The diagram's plain getters (get_role(),
## get_story(), ...) are the exported properties themselves.
##
## `good_ending` and `bad_ending` are not in the data diagram: UC-09.8 asks for
## a closing dialogue that ends the story well or badly, and that text belongs
## to each scenario (see the defect log of Sprint 2).

## How the attempts are shown (UC-09.2). It changes the look, not the rules.
enum SkinType {
	CREDIBILITY,
	BUDGET,
	SPRINT_TIME,
}

@export var id: int = 0
@export var department: Enums.Department = Enums.Department.DATA_STRUCTURES
@export var difficulty: Enums.Difficulty = Enums.Difficulty.FACIL
## Badge on top of the story ("Tu rol: Product Owner").
@export var role: String = ""
## Introductory text.
@export var context: String = ""
## One sentence per line; blanks are written "[BLANK_1]", "[BLANK_2]", ...
@export_multiline var story: String = ""
@export var blanks: Array[Blank] = []
## Bank of eight options: the correct answers plus distractors. An option may
## fill more than one blank.
@export var options: Array[String] = []
@export var skin: SkinType = SkinType.CREDIBILITY
## UC-09.8 closing dialogue when every blank is right.
@export_multiline var good_ending: String = ""
## UC-09.8 closing dialogue when the attempts run out.
@export_multiline var bad_ending: String = ""


## The right option of every blank, ordered by Blank.index. Computed from
## `blanks`, never stored, so the two can never disagree.
func get_correct_answers() -> Array[String]:
	var ordered := blanks.duplicate()
	ordered.sort_custom(func(a: Blank, b: Blank): return a.index < b.index)
	var answers: Array[String] = []
	for blank in ordered:
		answers.append(blank.correct_answer)
	return answers


func get_options() -> Array[String]:
	var copy: Array[String] = options.duplicate()
	return copy


## Indexes 1..N without gaps or repeats, every blank marked in the story, every
## answer present in the bank of eight options.
func is_valid() -> bool:
	if blanks.is_empty() or options.size() != 8:
		return false
	var indexes := blanks.map(func(b: Blank): return b.index)
	for i in range(1, blanks.size() + 1):
		if not indexes.has(i) or not story.contains("[BLANK_%d]" % i):
			return false
	for blank in blanks:
		if not options.has(blank.correct_answer):
			return false
	return true
