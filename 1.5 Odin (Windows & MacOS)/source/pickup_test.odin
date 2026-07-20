package caverace

import "core:testing"

// Pickup_Timing_Summary captures collection events and resulting map/player
// state from a render-rate comparison scenario.
Pickup_Timing_Summary :: struct {
	items_collected:     int,
	treasures_collected: int,
	item_sounds:         int,
	player_position:     Grid_Position,
	bomb_power:          int,
	score:               int,
	item_cell:           u8,
}

// run_pickup_timing_scenario advances the same item approach at a chosen render
// rate and returns collection events and final state for comparison.
run_pickup_timing_scenario :: proc(render_fps, seconds: int) -> Pickup_Timing_Summary {
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
		summary.items_collected += frame.ticks.items_collected
		summary.treasures_collected += frame.ticks.treasures_collected
		summary.item_sounds += frame.ticks.item_sound_requests
	}

	summary.player_position = gameplay.player.position
	summary.bomb_power = gameplay.player.bomb_power
	summary.score = gameplay.player.score
	summary.item_cell = gameplay.level.data.item[1][0]
	return summary
}

// Verifies every Standard score event is a visible attributable reward.
@(test)
all_standard_score_events_use_the_central_rule_set_test :: proc(t: ^testing.T) {
	player: Player_State
	apply_score_event(&player, .Item_Collected)
	testing.expect_value(t, player.score, SCORE_ITEM_PICKUP)
	apply_score_event(&player, .Capped_Item_Salvaged)
	testing.expect_value(t, player.score, SCORE_ITEM_PICKUP + SCORE_CAPPED_ITEM_SALVAGE)
	apply_score_event(&player, .Enemy_Destroyed)
	testing.expect_value(
		t,
		player.score,
		SCORE_ITEM_PICKUP + SCORE_CAPPED_ITEM_SALVAGE + SCORE_ENEMY_DESTROYED,
	)
	apply_score_event(&player, .Treasure_Collected)
	testing.expect_value(
		t,
		player.score,
		SCORE_ITEM_PICKUP + SCORE_CAPPED_ITEM_SALVAGE +
			SCORE_ENEMY_DESTROYED + SCORE_TREASURE_PICKUP,
	)
	apply_score_event(&player, .Level_Won)
	testing.expect_value(
		t,
		player.score,
		SCORE_ITEM_PICKUP + SCORE_CAPPED_ITEM_SALVAGE + SCORE_ENEMY_DESTROYED +
			SCORE_TREASURE_PICKUP + SCORE_LEVEL_WON,
	)
}

// Confirms each beneficial item mutates the intended stat, clears its map cell,
// awards score, and emits one collection event.
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

// Capped items become visible salvage, clear immediately, and stop blocking
// treasure while awarding the smaller attributable salvage reward.
@(test)
capped_items_become_salvage_and_stop_blocking_treasure_test :: proc(t: ^testing.T) {
	position := Grid_Position {6, 6}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_power = PLAYER_MAX_BOMB_POWER
	gameplay.level.data.item[position.x][position.y] = ITEM_POWER
	gameplay.level.data.treasure[position.x][position.y] = 1

	capped := collect_player_cell(&gameplay)
	testing.expect(t, !capped.item_collected)
	testing.expect(t, capped.item_salvaged)
	testing.expect(t, !capped.treasure_collected)
	testing.expect_value(t, gameplay.level.data.item[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(1))
	testing.expect_value(t, gameplay.player.score, SCORE_CAPPED_ITEM_SALVAGE)

	treasure := collect_player_cell(&gameplay)
	testing.expect(t, !treasure.item_collected)
	testing.expect(t, treasure.treasure_collected)
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.player.score, SCORE_CAPPED_ITEM_SALVAGE + SCORE_TREASURE_PICKUP)
}

// Verifies every capped item type clears and awards salvage without changing
// the already-capped player values.
@(test)
each_item_at_its_cap_is_salvaged_test :: proc(t: ^testing.T) {
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
		testing.expect(t, result.item_salvaged)
		testing.expect_value(t, gameplay.level.data.item[position.x][position.y], u8(0))
		testing.expect_value(t, gameplay.player.score, SCORE_CAPPED_ITEM_SALVAGE)
	}
}

// Confirms collection occurs only after the movement action commits the player's
// destination cell, not during interpolation.
@(test)
pickup_occurs_only_when_action_reaches_occupied_cell_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.bomb_power = PLAYER_START_BOMB_POWER
	gameplay.level.data.item[2][1] = ITEM_POWER

	queue_gameplay_input(&gameplay.tick_state, Game_Input {move_right = true})
	before_arrival := run_gameplay_ticks(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * GAMEPLAY_TICK_SECONDS,
	)
	testing.expect_value(t, before_arrival.items_collected, 0)
	testing.expect_value(t, before_arrival.item_sound_requests, 0)
	testing.expect_value(t, gameplay.level.data.item[2][1], u8(ITEM_POWER))

	arrival := run_gameplay_ticks(&gameplay, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, gameplay.player.position, Grid_Position {2, 1})
	testing.expect_value(t, arrival.items_collected, 1)
	testing.expect_value(t, arrival.item_sound_requests, 1)
	testing.expect_value(t, gameplay.level.data.item[2][1], u8(0))
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER + 1)
	testing.expect_value(t, gameplay.player.score, SCORE_ITEM_PICKUP)
}

// Verifies treasure collection requests the shared item sound exactly once at
// action completion.
@(test)
treasure_requests_one_item_sound_on_action_completion_test :: proc(t: ^testing.T) {
	position := Grid_Position {3, 3}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.level.data.treasure[position.x][position.y] = 2

	before_completion := run_gameplay_ticks(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * GAMEPLAY_TICK_SECONDS,
	)
	testing.expect_value(t, before_completion.treasures_collected, 0)
	frame := run_gameplay_ticks(&gameplay, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, frame.treasures_collected, 1)
	testing.expect_value(t, frame.items_collected, 0)
	testing.expect_value(t, frame.item_sound_requests, 1)
	testing.expect_value(t, gameplay.level.data.treasure[position.x][position.y], u8(0))
	testing.expect_value(t, gameplay.player.score, SCORE_TREASURE_PICKUP)
}

// Empty actions never create unexplained score.
@(test)
empty_action_does_not_change_score_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.score = 0

	run_gameplay_ticks(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * GAMEPLAY_TICK_SECONDS,
	)
	testing.expect_value(t, gameplay.player.score, 0)
	run_gameplay_ticks(&gameplay, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, gameplay.player.score, 0)
}

// Confirms pickup timing, scoring, audio requests, and resulting player state are
// independent of render frequency.
@(test)
pickup_timing_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_pickup_timing_scenario(30, 1)
	at_60_fps := run_pickup_timing_scenario(60, 1)
	at_144_fps := run_pickup_timing_scenario(144, 1)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_144_fps)
	testing.expect_value(t, at_60_fps.items_collected, 1)
	testing.expect_value(t, at_60_fps.treasures_collected, 0)
	testing.expect_value(t, at_60_fps.item_sounds, 1)
	testing.expect_value(t, at_60_fps.bomb_power, PLAYER_START_BOMB_POWER + 1)
	testing.expect_value(t, at_60_fps.score, SCORE_ITEM_PICKUP)
	testing.expect_value(t, at_60_fps.item_cell, u8(0))
}

// Verifies the compact numeric HUD includes resources and explicit objectives.
@(test)
hud_snapshot_includes_numeric_resources_and_objectives_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.level_index = 2
	gameplay.initial_enemy_count = 4
	gameplay.enemy_count = 4
	gameplay.enemies[0].active = true
	gameplay.enemies[1].active = true
	gameplay.treasure_total = 5
	gameplay.treasure_collected = 2
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
	testing.expect_value(t, hud.level, 3)
	testing.expect_value(t, hud.aliens_remaining, 2)
	testing.expect_value(t, hud.treasure_collected, 2)
	testing.expect_value(t, hud.treasure_total, 5)
	testing.expect_value(t, hud.available_bombs, 2)
	testing.expect_value(t, hud.bomb_capacity, 4)
	testing.expect_value(t, hud.bomb_power, 8)
	testing.expect_value(t, hud.score, 12345)
}
