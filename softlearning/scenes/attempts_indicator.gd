class_name AttemptsIndicator
extends Control
## The attempts of a narrative (UC-09.2) drawn with the scenario's skin:
## lightning bolts (Tiempo de sprint), coins (Presupuesto) or stars
## (Credibilidad). Full icons are the attempts left, grey ones the attempts
## used. Drawn in code, so it needs no image or icon font.

const FULL := {
	NarrativeScenario.SkinType.SPRINT_TIME: Color(0.918, 0.702, 0.031),
	NarrativeScenario.SkinType.BUDGET: Color(0.086, 0.639, 0.29),
	NarrativeScenario.SkinType.CREDIBILITY: Color(0.145, 0.388, 0.922),
}
const EMPTY := Color(0.796, 0.835, 0.882)
const ICON := 22.0
const GAP := 6.0

var skin := NarrativeScenario.SkinType.SPRINT_TIME
var total := 2
var left := 2


func show_attempts(new_skin: NarrativeScenario.SkinType, new_total: int, new_left: int) -> void:
	skin = new_skin
	total = new_total
	left = new_left
	custom_minimum_size = Vector2(total * (ICON + GAP), ICON)
	queue_redraw()


func _draw() -> void:
	for i in total:
		var color: Color = FULL[skin] if i < left else EMPTY
		var origin := Vector2(i * (ICON + GAP), (size.y - ICON) / 2.0)
		match skin:
			NarrativeScenario.SkinType.SPRINT_TIME:
				draw_colored_polygon(_bolt(origin), color)
			NarrativeScenario.SkinType.BUDGET:
				draw_circle(origin + Vector2(ICON, ICON) / 2.0, ICON / 2.0, color)
				draw_circle(origin + Vector2(ICON, ICON) / 2.0, ICON / 3.2, color.lightened(0.35))
			_:
				draw_colored_polygon(_star(origin + Vector2(ICON, ICON) / 2.0), color)


func _bolt(o: Vector2) -> PackedVector2Array:
	var s := ICON
	return PackedVector2Array([
		o + Vector2(0.58, 0.0) * s, o + Vector2(0.18, 0.56) * s, o + Vector2(0.46, 0.56) * s,
		o + Vector2(0.36, 1.0) * s, o + Vector2(0.82, 0.40) * s, o + Vector2(0.54, 0.40) * s,
	])


func _star(c: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var r := ICON / 2.0 if i % 2 == 0 else ICON / 4.6
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(c + Vector2(cos(a), sin(a)) * r)
	return points
