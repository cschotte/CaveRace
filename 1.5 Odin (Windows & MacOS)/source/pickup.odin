package caverace

// Pickup_Result reports which map layer changed at an action boundary so the
// tick result can aggregate score feedback and audio requests.
Pickup_Result :: struct {
	item_collected:     bool,
	treasure_collected: bool,
}

// try_collect_item applies one beneficial item if its player stat is below the
// legacy cap; collect_player_cell uses the result to decide whether to clear it.
try_collect_item :: proc(player: ^Player_State, item: u8) -> bool {
	switch item {
	case ITEM_POWER:
		if player.bomb_power >= PLAYER_MAX_BOMB_POWER do return false
		player.bomb_power += 1
	case ITEM_BOMB_CAPACITY:
		if player.bomb_capacity >= PLAYER_MAX_BOMB_CAPACITY do return false
		player.bomb_capacity += 1
	case ITEM_ENERGY:
		if player.energy >= PLAYER_MAX_ENERGY do return false
		player.energy = PLAYER_MAX_ENERGY
	case ITEM_LIFE:
		if player.lives >= PLAYER_MAX_LIVES do return false
		player.lives += 1
	case:
		return false
	}
	return true
}

// collect_player_cell resolves pickups when a movement action commits its target.
// It checks items before treasure, and any item defers treasure even when the
// player's corresponding stat is already capped.
collect_player_cell :: proc(gameplay: ^Gameplay) -> Pickup_Result {
	result: Pickup_Result
	position := gameplay.player.position
	if !is_in_map(position) do return result

	item := &gameplay.level.data.item[position.x][position.y]
	if item^ != 0 {
		if try_collect_item(&gameplay.player, item^) {
			item^ = 0
			apply_score_event(&gameplay.player, .Item_Collected)
			result.item_collected = true
		}
		return result
	}

	treasure := &gameplay.level.data.treasure[position.x][position.y]
	if treasure^ != 0 {
		treasure^ = 0
		apply_score_event(&gameplay.player, .Treasure_Collected)
		result.treasure_collected = true
	}
	return result
}
