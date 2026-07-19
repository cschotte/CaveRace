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
apply_score_event :: proc(player: ^Player_State, event: Score_Event) {
	switch event {
	case .Bomb_Placed:
		if player.score >= SCORE_BOMB_COST do player.score -= SCORE_BOMB_COST
	case .Item_Collected:
		player.score += SCORE_ITEM_PICKUP
	case .Enemy_Destroyed:
		player.score += SCORE_ENEMY_DESTROYED
	case .Treasure_Collected:
		player.score += SCORE_TREASURE_PICKUP
	case .Level_Won:
		player.score += SCORE_LEVEL_WON
	case .Death_Retry:
		if player.score >= SCORE_DEATH_PENALTY {
			player.score -= SCORE_DEATH_PENALTY
		}
	case .Action_Floor:
		if player.score == 0 do player.score = SCORE_BOMB_COST
	}
}
