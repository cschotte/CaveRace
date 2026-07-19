package caverace

import "core:testing"

Bomb_Timing_Summary :: struct {
	placements:      int,
	ticking_requests: int,
	expirations:     int,
	active_bombs:    int,
	available_bombs: int,
	score:           int,
	occupied:        u8,
}

run_bomb_timing_simulation :: proc(render_fps, seconds: int) -> Bomb_Timing_Summary {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 3
	gameplay.player.score = 10
	summary: Bomb_Timing_Summary

	for frame_index in 0 ..< render_fps * seconds {
		input: Game_Input
		if frame_index == 0 do input.space_pressed = true
		frame := update_gameplay(&gameplay, input, 1.0 / f64(render_fps))
		if frame.simulation.bomb_placed do summary.placements += 1
		if frame.simulation.ticking_requested do summary.ticking_requests += 1
		summary.expirations += frame.simulation.bombs_expired
	}

	summary.active_bombs = active_bomb_count(&gameplay)
	summary.available_bombs = available_bomb_count(&gameplay)
	summary.score = gameplay.player.score
	summary.occupied = gameplay.bomb_occupancy[position.x][position.y]
	return summary
}

@(test)
bomb_placement_captures_runtime_values_test :: proc(t: ^testing.T) {
	position := Grid_Position {3, 4}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 6
	gameplay.player.score = 12

	testing.expect(t, try_place_bomb(&gameplay))
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
	testing.expect_value(t, available_bomb_count(&gameplay), 0)
	testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(BOMB_TICKING_SPRITE))
	testing.expect(t, gameplay.bombs[0].active)
	testing.expect_value(t, gameplay.bombs[0].position, position)
	testing.expect_value(t, gameplay.bombs[0].fuse_actions, BOMB_FUSE_ACTIONS)
	testing.expect_value(t, gameplay.bombs[0].power, 6)
	testing.expect_value(t, gameplay.player.score, 12 - SCORE_BOMB_COST)

	gameplay.player.bomb_power = 1
	testing.expect_value(t, gameplay.bombs[0].power, 6)
	testing.expect(t, !try_place_bomb(&gameplay))
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
	testing.expect_value(t, gameplay.player.score, 12 - SCORE_BOMB_COST)
}

@(test)
bomb_score_cost_has_legacy_floor_test :: proc(t: ^testing.T) {
	for initial_score in 0 ..< SCORE_BOMB_COST {
		gameplay := open_gameplay_at({initial_score, 0})
		gameplay.player.bomb_capacity = 1
		gameplay.player.bomb_power = 1
		gameplay.player.score = initial_score
		testing.expect(t, try_place_bomb(&gameplay))
		testing.expect_value(t, gameplay.player.score, initial_score)
	}

	gameplay := open_gameplay_at({6, 0})
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 1
	gameplay.player.score = SCORE_BOMB_COST
	testing.expect(t, try_place_bomb(&gameplay))
	testing.expect_value(t, gameplay.player.score, 0)
}

@(test)
bomb_capacity_and_slots_are_released_once_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.bomb_capacity = 2
	gameplay.player.bomb_power = 1

	testing.expect(t, try_place_bomb(&gameplay))
	gameplay.player.position = {1, 0}
	testing.expect(t, try_place_bomb(&gameplay))
	testing.expect_value(t, active_bomb_count(&gameplay), 2)
	testing.expect_value(t, available_bomb_count(&gameplay), 0)

	gameplay.player.position = {2, 0}
	testing.expect(t, !try_place_bomb(&gameplay))
	clear_bomb_slot(&gameplay, 0)
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
	testing.expect_value(t, available_bomb_count(&gameplay), 1)
	testing.expect_value(t, gameplay.bomb_occupancy[0][0], u8(0))

	clear_bomb_slot(&gameplay, 0)
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
	testing.expect_value(t, available_bomb_count(&gameplay), 1)
	testing.expect(t, try_place_bomb(&gameplay))
	testing.expect_value(t, active_bomb_count(&gameplay), 2)
	testing.expect_value(t, available_bomb_count(&gameplay), 0)
}

@(test)
bomb_fixed_slot_limit_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.bomb_capacity = MAX_BOMBS
	gameplay.player.bomb_power = 1

	for bomb_index in 0 ..< MAX_BOMBS {
		gameplay.player.position = {bomb_index, 0}
		testing.expect(t, try_place_bomb(&gameplay))
	}
	testing.expect_value(t, active_bomb_count(&gameplay), MAX_BOMBS)
	testing.expect_value(t, available_bomb_count(&gameplay), 0)
	gameplay.player.position = {MAX_BOMBS, 0}
	testing.expect(t, !try_place_bomb(&gameplay))
}

@(test)
bomb_fuse_expires_and_clears_occupancy_once_test :: proc(t: ^testing.T) {
	position := Grid_Position {2, 2}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 2
	testing.expect(t, try_place_bomb(&gameplay))

	for expected_fuse := BOMB_FUSE_ACTIONS - 1; expected_fuse >= 1; expected_fuse -= 1 {
		testing.expect_value(t, advance_bomb_fuses(&gameplay), 0)
		testing.expect(t, gameplay.bombs[0].active)
		testing.expect_value(t, gameplay.bombs[0].fuse_actions, expected_fuse)
		testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(1))
	}

	testing.expect_value(t, advance_bomb_fuses(&gameplay), 1)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(0))
	testing.expect_value(t, active_bomb_count(&gameplay), 0)
	testing.expect_value(t, available_bomb_count(&gameplay), 1)
	testing.expect_value(t, advance_bomb_fuses(&gameplay), 0)
	testing.expect_value(t, available_bomb_count(&gameplay), 1)
}

@(test)
placed_bomb_blocks_player_and_enemy_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 1
	testing.expect(t, try_place_bomb(&gameplay))

	gameplay.player.position = {0, 1}
	begin_player_action(&gameplay, .Move_Right)
	testing.expect_value(t, gameplay.player.move_to, Grid_Position {0, 1})

	gameplay.enemies[0] = enemy_at({2, 1})
	gameplay.enemy_count = 1
	begin_enemy_action(&gameplay, &gameplay.enemies[0], .Left)
	testing.expect_value(t, gameplay.enemies[0].move_to, Grid_Position {2, 1})
}

@(test)
bomb_action_requests_ticking_only_on_success_test :: proc(t: ^testing.T) {
	position := Grid_Position {4, 4}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 2
	gameplay.player.score = 10

	placed := update_gameplay(
		&gameplay,
		Game_Input {space_pressed = true},
		SIMULATION_STEP_SECONDS,
	)
	testing.expect(t, placed.simulation.bomb_action_started)
	testing.expect(t, placed.simulation.bomb_placed)
	testing.expect(t, placed.simulation.ticking_requested)
	testing.expect_value(t, gameplay.bombs[0].fuse_actions, BOMB_FUSE_ACTIONS - 1)

	buffer_gameplay_input(&gameplay.simulation, Game_Input {space_pressed = true})
	before_boundary := advance_gameplay_simulation(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * SIMULATION_STEP_SECONDS,
	)
	testing.expect_value(t, before_boundary.action_decisions, 0)
	failed := advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect(t, failed.bomb_action_started)
	testing.expect(t, !failed.bomb_placed)
	testing.expect(t, !failed.ticking_requested)
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
}

@(test)
bomb_timing_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_bomb_timing_simulation(30, 3)
	at_60_fps := run_bomb_timing_simulation(60, 3)
	at_240_fps := run_bomb_timing_simulation(240, 3)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_240_fps)
	testing.expect_value(t, at_60_fps.placements, 1)
	testing.expect_value(t, at_60_fps.ticking_requests, 1)
	testing.expect_value(t, at_60_fps.expirations, 1)
	testing.expect_value(t, at_60_fps.active_bombs, 0)
	testing.expect_value(t, at_60_fps.available_bombs, 1)
	testing.expect_value(t, at_60_fps.score, 10 - SCORE_BOMB_COST)
	testing.expect_value(t, at_60_fps.occupied, u8(0))
}
