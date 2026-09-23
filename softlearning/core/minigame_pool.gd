class_name MinigamePool
extends Resource

@export var questions: Array[QuizQuestion]

func get_question(department: Enums.Department, elo: float) -> QuizQuestion:
	# Returns a minigame instance. If it could not find any mathchingminigame returns null.
	var difficulty := _select_difficulty(elo)
	var possible := Array()
	
	for q in questions:
		if q.difficulty == difficulty and q.department == department:
			possible.append(q)

	if len(possible) == 0:
		return null
	
	var index := RandomNumberGenerator.new().randi_range(0, len(possible))
	
	return possible[index]


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
