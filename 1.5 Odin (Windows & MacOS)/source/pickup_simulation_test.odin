package caverace

import "core:testing"

Pickup_Timing_Summary :: struct {
	items_collected:     int,
	treasures_collected: int,
	item_sounds:         int,
	player_position:     Grid_Position,
	bomb_power:          int,
	score:               int,
	item_cell:           u8,
}

run_pickup_timing_simulation :: proc(render_fps, seconds: int) -> Pickup_Timing_Summary {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.bomb_power = PLAYER_START_BOMB_POWER
	gameplay.level.data.item[1][0] = ITEM_POWER
	summary: Pickup_Timing_Summary

	for _ in 0 ..< render_fps * seconds {
		frame := update_gameplay(
			&gameplay,
			Game_Input {move_right = true},
			1.0 / f64(render_fps),
		)
		summary.items_collected += frame.simulation.items_collected
		summary.treasures_collected += frame.simulation.treasures_collected
		summary.item_sounds += frame.simulation.item_sound_requests
	}

	summary.player_position = gameplay.player.position
	summary.bomb_power = gameplay.player.bomb_power
	summary.score = gameplay.player.score
	summary.item_cell = gameplay.level.data.item[1][0]
	return summary
}

@(test)
all_legacy_score_events_use_the_central_rule_set_test :: proc(t: ^testing.T) {
	player := Player_State {score = SCORE_BOMB_COST - 1}
	apply_score_event(&player, .Bomb_Placed)
	testing.expect_value(t, player.score, SCORE_BOMB_COST - 1)
	player.score = SCORE_BOMB_COST
	apply_score_event(&player, .Bomb_Placed)
	testing.expect_value(t, player.score, 0)
	apply_score_event(&player, .Action_Floor)
	testing.expect_value(t, player.score, SCORE_BOMB_COST)

	player.score = 0
	apply_score_event(&player, .Item_Collected)
	testing.expect_value(t, player.score, SCORE_ITEM_PICKUP)
	apply_score_event(&player, .Enemy_Destroyed)
	testing.expect_value(t, player.score, SCORE_ITEM_PICKUP + SCORE_ENEMY_DESTROYED)
	apply_score_event(&player, .Treasure_Collected)
	testing.expect_value(
		t,
		player.score,
		SCORE_ITEM_PICKUP + SCORE_ENEMY_DESTROYED + SCORE_TREASURE_PICKUP,
	)
	apply_score_event(&player, .Level_Won)
	testing.expect_value(
		t,
		player.score,
		SCORE_ITEM_PICKUP + SCORE_ENEMY_DESTROYED +
			SCORE_TREASURE_PICKUP + SCORE_LEVEL_WON,
	)

	player.score = SCORE_DEATH_PENALTY - 1
	apply_score_event(&player, .Death_Retry)
	testing.expect_value(t, player.score, SCORE_DEATH_PENALTY - 1)
	player.score = SCORE_DEATH_PENALTY
	apply_score_event(&player, .Death_Retry)
	testing.expect_value(t, player.score, 0)
}

@(test)
all_four_beneficial_items_apply_caps_clear_and_score_test :: proc(t: ^testing.T) {
	position := Grid_Position {4, 4}

	power_gameplay := open_gameplay_at(position)
	power_gameplay.player.bomb_power = PLAYER_MAX_BOMB_POWER - 1
	power_gameplay.level.data.item[position.x][position.y] = ITEM_POWER
	power_result := collect_player_cell(&power_gameplay)
	testing.expect(t, power_result.item_collected)
	testing.expect_value(t, power_gameplay.player.bomb_power, PLAYER_MAX_BOMB_POWER)
	testing.expect_value(t, power_gameplay.player.score, SCORE_ITEM_PICKUP)
	testing.expect_value(t, power_gameplay.level.data.item[position.x][position.y], u8(0))

	bomb_gameplay := open_gameplay_at(position)
	bomb_gameplay.player.bomb_capacity = PLAYER_MAX_BOMB_CAPACITY - 1
	bomb_gameplay.level.data.item[position.x][position.y] = ITEM_BOMB_CAPACITY
	bomb_result := collect_player_cell(&bomb_gameplay)
	testing.expect(t, bomb_result.item_collected)
	testing.expect_value(t, bomb_gameplay.player.bomb_capacity, PLAYER_MAX_BOMB_CAPACITY)
	testing.expect_value(t, bomb_gameplay.player.score, SCORE_ITEM_PICKUP)

	energy_gameplay := open_gameplay_at(position)
	energy_gameplay.player.energy = 1
	energy_gameplay.level.data.item[position.x][position.y] = ITEM_ENERGY
	energy_result := collect_player_cell(&energy_gameplay)
	testing.expect(t, energy_result.item_collected)
	testing.expect_value(t, energy_gameplay.player.energy, PLAYER_MAX_ENERGY)
	testing.expect_value(t, energy_gameplay.player.score, SCORE_ITEM_PICKUP)

	life_gameplay := open_gameplay_at(position)
	life_gameplay.player.lives = PLAYER_MAX_LIVES - 1
	life_gameplay.level.data.item[position.x][position.y] = ITEM_LIFE
	life_result := collect_player_cell(&life_gameplay)
	testing.expect(t, life_result.item_collected)
	testing.expect_value(t, life_gameplay.player.lives, PLAYER_MAX_LIVES)
	testing.expect_value(t, life_gameplay.player.score, SCORE_ITEM_PICKUP)
}

@(test)
capped_items_remain_and_defer_treasure_test :: proc(t: ^testing.T) {
	position := Grid_Position {6, 6}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_power = PLAYER_MAX_BOMB_POWER
	gameplay.level.data.item[position.x][position.y] = ITEM_POWER
	gameplay.level.data.treasure[position.x][position.y] = 1

	capped := collect_player_cell(&gameplay)
	testing.expect(t, !capped.item_collected)
	testing.expect(t, !capped.treasure_collected)
	testing.expect_value(t, gameplay.level.data.item[position.x][position.y], u8(ITEM_POWER))
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(1))
	testing.expect_value(t, gameplay.player.score, 0)

	gameplay.player.bomb_power = PLAYER_MAX_BOMB_POWER - 1
	item := collect_player_cell(&gameplay)
	testing.expect(t, item.item_collected)
	testing.expect(t, !item.treasure_collected)
	testing.expect_value(t, gameplay.level.data.item[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(1))
	testing.expect_value(t, gameplay.player.score, SCORE_ITEM_PICKUP)

	treasure := collect_player_cell(&gameplay)
	testing.expect(t, !treasure.item_collected)
	testing.expect(t, treasure.treasure_collected)
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.player.score, SCORE_ITEM_PICKUP + SCORE_TREASURE_PICKUP)
}

@(test)
each_item_at_its_cap_is_retained_test :: proc(t: ^testing.T) {
	position := Grid_Position {2, 2}

	for item in u8(ITEM_POWER) ..= u8(ITEM_LIFE) {
		gameplay := open_gameplay_at(position)
		gameplay.player.bomb_power = PLAYER_MAX_BOMB_POWER
		gameplay.player.bomb_capacity = PLAYER_MAX_BOMB_CAPACITY
		gameplay.player.energy = PLAYER_MAX_ENERGY
		gameplay.player.lives = PLAYER_MAX_LIVES
		gameplay.level.data.item[position.x][position.y] = item

		result := collect_player_cell(&gameplay)
		testing.expect(t, !result.item_collected)
		testing.expect_value(t, gameplay.level.data.item[position.x][position.y], item)
		testing.expect_value(t, gameplay.player.score, 0)
	}
}

@(test)
pickup_occurs_only_when_action_reaches_occupied_cell_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.bomb_power = PLAYER_START_BOMB_POWER
	gameplay.level.data.item[2][1] = ITEM_POWER

	buffer_gameplay_input(&gameplay.simulation, Game_Input {move_right = true})
	before_arrival := advance_gameplay_simulation(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * SIMULATION_STEP_SECONDS,
	)
	testing.expect_value(t, before_arrival.items_collected, 0)
	testing.expect_value(t, before_arrival.item_sound_requests, 0)
	testing.expect_value(t, gameplay.level.data.item[2][1], u8(ITEM_POWER))

	arrival := advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect_value(t, gameplay.player.position, Grid_Position {2, 1})
	testing.expect_value(t, arrival.items_collected, 1)
	testing.expect_value(t, arrival.item_sound_requests, 1)
	testing.expect_value(t, gameplay.level.data.item[2][1], u8(0))
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER + 1)
	testing.expect_value(t, gameplay.player.score, SCORE_ITEM_PICKUP)
}

@(test)
treasure_requests_one_item_sound_on_action_completion_test :: proc(t: ^testing.T) {
	position := Grid_Position {3, 3}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.level.data.treasure[position.x][position.y] = 2

	before_completion := advance_gameplay_simulation(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * SIMULATION_STEP_SECONDS,
	)
	testing.expect_value(t, before_completion.treasures_collected, 0)
	frame := advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect_value(t, frame.treasures_collected, 1)
	testing.expect_value(t, frame.items_collected, 0)
	testing.expect_value(t, frame.item_sound_requests, 1)
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.player.score, SCORE_TREASURE_PICKUP)
}

@(test)
legacy_score_floor_applies_at_action_completion_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.score = 0

	advance_gameplay_simulation(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * SIMULATION_STEP_SECONDS,
	)
	testing.expect_value(t, gameplay.player.score, 0)
	advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect_value(t, gameplay.player.score, SCORE_BOMB_COST)
}

@(test)
pickup_timing_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_pickup_timing_simulation(30, 1)
	at_60_fps := run_pickup_timing_simulation(60, 1)
	at_240_fps := run_pickup_timing_simulation(240, 1)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_240_fps)
	testing.expect_value(t, at_60_fps.items_collected, 1)
	testing.expect_value(t, at_60_fps.treasures_collected, 0)
	testing.expect_value(t, at_60_fps.item_sounds, 1)
	testing.expect_value(t, at_60_fps.bomb_power, PLAYER_START_BOMB_POWER + 1)
	testing.expect_value(t, at_60_fps.score, SCORE_ITEM_PICKUP)
	testing.expect_value(t, at_60_fps.item_cell, u8(0))
}

@(test)
hud_snapshot_matches_runtime_state_and_legacy_positions_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.lives = 3
	gameplay.player.energy = 6
	gameplay.player.bomb_capacity = 4
	gameplay.player.bomb_power = 8
	gameplay.player.score = 12345
	gameplay.bombs[0].active = true
	gameplay.bombs[1].active = true

	hud := gameplay_hud_state(&gameplay)
	testing.expect_value(t, hud.lives, 3)
	testing.expect_value(t, hud.energy, 6)
	testing.expect_value(t, hud.available_bombs, 2)
	testing.expect_value(t, hud.bomb_power, 8)
	testing.expect_value(t, hud.score, 12345)

	testing.expect_value(t, HUD_LIVES_X, 16)
	testing.expect_value(t, HUD_LIVES_Y, 374)
	testing.expect_value(t, HUD_LIVES_SPACING, 20)
	testing.expect_value(t, HUD_ENERGY_X, 106)
	testing.expect_value(t, HUD_ENERGY_Y, 366)
	testing.expect_value(t, HUD_ENERGY_SPACING, 10)
	testing.expect_value(t, HUD_BOMBS_X, 196)
	testing.expect_value(t, HUD_BOMBS_SPACING, 12)
	testing.expect_value(t, HUD_POWER_X, 254)
	testing.expect_value(t, HUD_POWER_SPACING, 16)
	testing.expect_value(t, HUD_SCORE_RIGHT, 446)
}
