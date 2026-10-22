class_name ContentPool
extends Resource
## What every content pool (B2) shares: the ELO-weighted choice of difficulty
## and the draw of one item without repeating it.
##
## Each concrete pool (MinigamePool for the quiz, SwipePool, NarrativePool,
## TrainPool, BombPool) holds its own list of items and exposes the getter of
## its diagram (get_question, get_card, ...), which only calls _pick(). Every
## item has `id`, `department` and `difficulty`.
##
## No repeats: items of one department and difficulty are handed out like a
## shuffled deck. An item comes back only after every other item of that group
## was served, so a session never shows the same question twice while the
## group still has unseen ones. The deck lives in memory only (it is not
## progress, B7 never saves it) and is shared by every session of the run,
## because Godot caches the pool resource.

## "department:difficulty" -> ids already served from that group.
var _served := {}


## The item to play for `department` at `elo`: the weighted difficulty first,
## then the nearest difficulty that has items, so a department with a gap in
## one level still gets content. Null only when the department has no items.
func _pick(items: Array, department: Enums.Department, elo: float) -> Resource:
	var target := _select_difficulty(elo)
	var of_department := items.filter(func(item): return item.department == department)
	if of_department.is_empty():
		return null
	for difficulty in _by_distance(target):
		var group := of_department.filter(func(item): return item.difficulty == difficulty)
		if not group.is_empty():
			return _draw(group, "%d:%d" % [department, difficulty])
	return null


## Every difficulty, the target first and then the closest ones (easier first
## on ties).
func _by_distance(target: Enums.Difficulty) -> Array:
	var order := Enums.Difficulty.values()
	order.sort_custom(func(a, b):
		var da := absi(a - target)
		var db := absi(b - target)
		return da < db or (da == db and a < b))
	return order


## One unseen item of `group`. When the whole group was served, the deck is
## reshuffled, leaving out the item served last so it never shows twice in a
## row.
func _draw(group: Array, key: String) -> Resource:
	var served: Array = _served.get(key, [])
	var unseen := group.filter(func(item): return not served.has(item.id))
	if unseen.is_empty():
		var last = served.back() if not served.is_empty() else null
		served = []
		unseen = group.filter(func(item): return item.id != last) if group.size() > 1 else group
	var item: Resource = unseen.pick_random()
	served.append(item.id)
	_served[key] = served
	return item


func _select_difficulty(elo: float) -> Enums.Difficulty:
	# Define key anchor points and their probabilities
	# Format: [ELO anchor, [P(FACIL), P(MEDIO), P(DIFICIL), P(MUY_DIFICIL)]]
	var anchors = [
		[1000.0, [0.90, 0.10, 0.00, 0.00]],
		[1500.0, [0.10, 0.80, 0.10, 0.00]],
		[2000.0, [0.00, 0.10, 0.80, 0.10]],
		[2500.0, [0.00, 0.00, 0.10, 0.90]]
	]

	# Clamp ELO to the lower and upper bounds
	elo = clampf(elo, 1000.0, 2500.0)

	# Find which segment the current ELO falls into
	var probs = [0.0, 0.0, 0.0, 0.0]

	if elo <= anchors[0][0]:
		probs = anchors[0][1]
	elif elo >= anchors[-1][0]:
		probs = anchors[-1][1]
	else:
		for i in range(anchors.size() - 1):
			var low_elo = anchors[i][0]
			var high_elo = anchors[i + 1][0]

			if elo >= low_elo and elo <= high_elo:
				# Calculate interpolation factor (0.0 to 1.0)
				var t = (elo - low_elo) / (high_elo - low_elo)
				var low_probs = anchors[i][1]
				var high_probs = anchors[i + 1][1]

				# Linearly interpolate each difficulty's probability
				for j in range(4):
					probs[j] = lerp(low_probs[j], high_probs[j], t)
				break

	# Weighted random selection
	var roll = randf()
	var cumulative = 0.0

	for i in range(probs.size()):
		cumulative += probs[i]
		if roll <= cumulative:
			return i as Enums.Difficulty

	return Enums.Difficulty.MUY_DIFICIL
