package caverace

import "core:testing"

// Bomb_Timing_Summary captures observable placement, expiry, capacity, score,
// and occupancy results for render-rate comparison scenarios.
Bomb_Timing_Summary :: struct {
	placements:      int,
	ticking_requests: int,
	expirations:     int,
	active_bombs:    int,
	available_bombs: int,
	score:           int,
	occupied:        u8,
}

// run_bomb_timing_scenario executes the same timed placement at a chosen render
// rate so timing tests can compare the resulting bomb state.
run_bomb_timing_scenario :: proc(render_fps, seconds: int) -> Bomb_Timing_Summary {
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
		if frame.ticks.bomb_placed do summary.placements += 1
		summary.ticking_requests += frame.ticks.ticking_requests
		summary.expirations += frame.ticks.bombs_expired
	}

	summary.active_bombs = active_bomb_count(&gameplay)
	summary.available_bombs = available_bomb_count(&gameplay)
	summary.score = gameplay.player.score
	summary.occupied = gameplay.bomb_occupancy[position.x][position.y]
	return summary
}

// Verifies that placement captures position, fuse, power, occupancy, and score
// from the player state at the action boundary.
@(test)
bomb_placement_captures_current_player_values_test :: proc(t: ^testing.T) {
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
	testing.expect_value(t, gameplay.bombs[0].fuse_ticks, BOMB_FUSE_TICKS)
	testing.expect_value(t, gameplay.bombs[0].power, 6)
	testing.expect_value(t, gameplay.player.score, 12)

	gameplay.player.bomb_power = 1
	testing.expect_value(t, gameplay.bombs[0].power, 6)
	testing.expect(t, !try_place_bomb(&gameplay))
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
	testing.expect_value(t, gameplay.player.score, 12)
}

// Protects Standard's visible-event scoring: placing a bomb is score-neutral.
@(test)
bomb_placement_is_score_neutral_test :: proc(t: ^testing.T) {
	for initial_score in 0 ..= 10 {
		gameplay := open_gameplay_at({initial_score, 0})
		gameplay.player.bomb_capacity = 1
		gameplay.player.bomb_power = 1
		gameplay.player.score = initial_score
		testing.expect(t, try_place_bomb(&gameplay))
		testing.expect_value(t, gameplay.player.score, initial_score)
	}
}

@(test)
bomb_warning_window_and_tick_cadence_accelerate_test :: proc(t: ^testing.T) {
	bomb := Bomb_State {
		active     = true,
		position   = {5, 5},
		fuse_ticks = BOMB_DANGER_PREVIEW_TICKS + 1,
		power      = 4,
	}
	preview: Explosion_State
	visible: bool
	_, visible = bomb_danger_footprint(&bomb)
	testing.expect(t, !visible)
	bomb.fuse_ticks = BOMB_DANGER_PREVIEW_TICKS
	preview, visible = bomb_danger_footprint(&bomb)
	testing.expect(t, visible)
	testing.expect(t, preview.cell_count > 1)
	testing.expect_value(t, bomb_tick_interval(GAMEPLAY_TICK_HZ * 2 + 1), 30)
	testing.expect_value(t, bomb_tick_interval(GAMEPLAY_TICK_HZ + 1), 15)
	testing.expect_value(t, bomb_tick_interval(GAMEPLAY_TICK_HZ), 6)
}

// Verifies that fixed bomb slots return to player capacity exactly once after
// their explosions finish.
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

// Guards the hard four-slot storage limit even if player capacity is corrupted
// beyond its supported maximum.
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

// Verifies fixed-tick fuse expiry starts an explosion and the paired slot is
// released only after its animation/damage lifetime.
@(test)
bomb_fuse_starts_explosion_then_releases_slot_once_test :: proc(t: ^testing.T) {
	position := Grid_Position {2, 2}
	gameplay := open_gameplay_at(position)
	gameplay.player.bomb_capacity = 1
	gameplay.player.bomb_power = 2
	testing.expect(t, try_place_bomb(&gameplay))

	for expected_fuse := BOMB_FUSE_TICKS - 1; expected_fuse >= 1; expected_fuse -= 1 {
		_ = advance_bomb_fuses(&gameplay)
		testing.expect(t, gameplay.bombs[0].active)
		testing.expect_value(t, gameplay.bombs[0].fuse_ticks, expected_fuse)
		testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(1))
	}

	_ = advance_bomb_fuses(&gameplay)
	result: Gameplay_Tick_Result
	start_ready_explosions(&gameplay, &result)
	testing.expect_value(t, result.explosions_started, 1)
	testing.expect(t, gameplay.bombs[0].active)
	testing.expect(t, gameplay.explosions[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(0))
	for _ in 1 ..< EXPLOSION_STEPS do testing.expect_value(t, advance_explosion_ages(&gameplay), 0)
	testing.expect_value(t, advance_explosion_ages(&gameplay), 1)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect_value(t, available_bomb_count(&gameplay), 1)
}

// Confirms that a placed bomb participates in the shared walkability rules for
// both player and enemy movement.
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

// Verifies that ticking audio is requested only for a successful placement and
// that a latched retry is evaluated at the next action boundary.
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
		GAMEPLAY_TICK_SECONDS,
	)
	testing.expect(t, placed.ticks.bomb_action_started)
	testing.expect(t, placed.ticks.bomb_placed)
	testing.expect_value(t, placed.ticks.ticking_requests, 1)
	testing.expect_value(t, gameplay.bombs[0].fuse_ticks, BOMB_FUSE_TICKS)

	queue_gameplay_input(&gameplay.tick_state, Game_Input {space_pressed = true})
	before_boundary := run_gameplay_ticks(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * GAMEPLAY_TICK_SECONDS,
	)
	testing.expect_value(t, before_boundary.action_decisions, 0)
	failed := run_gameplay_ticks(&gameplay, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, failed.bomb_action_started)
	testing.expect(t, !failed.bomb_placed)
	testing.expect_value(t, failed.ticking_requests, 0)
	testing.expect_value(t, active_bomb_count(&gameplay), 1)
}

// Protects fixed-tick bomb behavior from changes in presentation frame rate.
@(test)
bomb_timing_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_bomb_timing_scenario(30, 4)
	at_60_fps := run_bomb_timing_scenario(60, 4)
	at_144_fps := run_bomb_timing_scenario(144, 4)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_144_fps)
	testing.expect_value(t, at_60_fps.placements, 1)
	testing.expect_value(t, at_60_fps.ticking_requests, 16)
	testing.expect_value(t, at_60_fps.expirations, 1)
	testing.expect_value(t, at_60_fps.active_bombs, 0)
	testing.expect_value(t, at_60_fps.available_bombs, 1)
	testing.expect_value(t, at_60_fps.score, 10)
	testing.expect_value(t, at_60_fps.occupied, u8(0))
}
