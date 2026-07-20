package caverace

// Score_Event keeps every legacy score mutation in one small rule set so
// gameplay updates and lifecycle code do not duplicate thresholds or arithmetic.
Score_Event :: enum {
	Bomb_Placed,
	Item_Collected,
	Enemy_Destroyed,
	Treasure_Collected,
	Level_Won,
	Death_Retry,
	Action_Floor,
}

// apply_score_event centralizes every legacy score mutation and is called by
// gameplay systems exactly where the corresponding event is committed.
apply_score_event :: proc(
	player: ^Player_State,
	event: Score_Event,
	difficulty: Difficulty_Profile = .Standard,
) {
	tuning := gameplay_tuning(difficulty)
	switch event {
	case .Bomb_Placed:
		if player.score >= tuning.score_bomb_cost {
			player.score -= tuning.score_bomb_cost
		}
	case .Item_Collected:
		player.score += tuning.score_item_pickup
	case .Enemy_Destroyed:
		player.score += tuning.score_enemy_destroyed
	case .Treasure_Collected:
		player.score += tuning.score_treasure_pickup
	case .Level_Won:
		player.score += tuning.score_level_won
	case .Death_Retry:
		if player.score >= tuning.score_death_penalty {
			player.score -= tuning.score_death_penalty
		}
	case .Action_Floor:
		if player.score == 0 do player.score = tuning.score_bomb_cost
	}
}
