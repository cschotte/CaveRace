package caverace

// Score_Event keeps every visible score mutation in one small rule set so
// gameplay updates and lifecycle code do not duplicate thresholds or arithmetic.
Score_Event :: enum {
	Item_Collected,
	Capped_Item_Salvaged,
	Enemy_Destroyed,
	Treasure_Collected,
	Level_Won,
}

// apply_score_event centralizes every Standard score mutation and is called by
// gameplay systems exactly where the corresponding event is committed.
apply_score_event :: proc(
	player: ^Player_State,
	event: Score_Event,
	difficulty: Difficulty_Profile = .Standard,
) {
	tuning := gameplay_tuning(difficulty)
	switch event {
	case .Item_Collected:
		player.score += tuning.score_item_pickup
	case .Capped_Item_Salvaged:
		player.score += tuning.score_capped_item_salvage
	case .Enemy_Destroyed:
		player.score += tuning.score_enemy_destroyed
	case .Treasure_Collected:
		player.score += tuning.score_treasure_pickup
	case .Level_Won:
		player.score += tuning.score_level_won
	}
}
