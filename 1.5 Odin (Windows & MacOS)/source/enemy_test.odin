package caverace

import "core:testing"

// enemy_at creates a stationary active enemy for focused movement and contact
// tests without loading a complete level.
enemy_at :: proc(position: Grid_Position, kind: u8 = 1) -> Enemy_State {
	return Enemy_State {
		active    = true,
		kind      = kind,
		position  = position,
		move_from = position,
		move_to   = position,
	}
}

// block_cardinal_neighbors surrounds one cell with blocked terrain so tests can
// exercise enemy behavior when every random direction is unavailable.
block_cardinal_neighbors :: proc(data: ^Map_Data, position: Grid_Position) {
	directions := [4]Direction {
		.Down,
		.Up,
		.Right,
		.Left,
	}
	for direction in directions {
		delta := direction_delta(direction)
		neighbor := Grid_Position {position.x + delta.x, position.y + delta.y}
		if is_in_map(neighbor) {
			data.background[neighbor.x][neighbor.y] = WALKABLE_TERRAIN_LIMIT
		}
	}
}

// Enemy_Run_Summary captures final enemy movement and random state from a seeded
// timing scenario so different render rates can be compared exactly.
Enemy_Run_Summary :: struct {
	enemies: [MAX_ENEMIES]Enemy_State,
	energy:  int,
	state:   Gameplay_State,
}

// run_seeded_enemy_scenario advances identical seeded gameplay at a chosen
// render rate and returns the final enemy state for comparison.
run_seeded_enemy_scenario :: proc(render_fps, seconds: int, seed: u64) -> Enemy_Run_Summary {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.energy = PLAYER_START_ENERGY
	block_cardinal_neighbors(&gameplay.level.data, gameplay.player.position)
	gameplay.enemies[0] = enemy_at({5, 5}, 1)
	gameplay.enemies[1] = enemy_at({10, 5}, 2)
	gameplay.enemies[2] = enemy_at({15, 5}, 3)
	gameplay.enemy_count = 3
	seed_gameplay_random(&gameplay, seed)

	for _ in 0 ..< render_fps * seconds {
		update_gameplay(&gameplay, {}, 1.0 / f64(render_fps))
	}
	return {
		enemies = gameplay.enemies,
		energy  = gameplay.player.energy,
		state   = gameplay.state,
	}
}

// run_stationary_contact_one_second counts damage events while player and
// enemy overlap, allowing contact cadence to be compared across render rates.
run_stationary_contact_one_second :: proc(render_fps: int) -> int {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemy_count = 1
	block_cardinal_neighbors(&gameplay.level.data, position)
	seed_gameplay_random(&gameplay, 99)

	for _ in 0 ..< render_fps {
		update_gameplay(&gameplay, {}, 1.0 / f64(render_fps))
	}
	return gameplay.player.energy
}

// Verifies random roll mapping and session seeding produce repeatable enemy
// direction sequences.
@(test)
enemy_direction_and_seed_are_deterministic_test :: proc(t: ^testing.T) {
	testing.expect_value(t, enemy_direction_from_roll(0), Direction.Down)
	testing.expect_value(t, enemy_direction_from_roll(1), Direction.Up)
	testing.expect_value(t, enemy_direction_from_roll(2), Direction.Right)
	testing.expect_value(t, enemy_direction_from_roll(3), Direction.Left)
	testing.expect_value(t, enemy_direction_from_roll(4), Direction.None)

	a, b: Gameplay
	seed_gameplay_random(&a, 0xCAFE_FACE)
	seed_gameplay_random(&b, 0xCAFE_FACE)
	for _ in 0 ..< 64 {
		testing.expect_value(
			t,
			gameplay_random_max(&a, 4),
			gameplay_random_max(&b, 4),
		)
	}
}

@(test)
cosmetic_random_draws_do_not_change_seeded_enemy_trace_test :: proc(t: ^testing.T) {
	a, b: Gameplay
	seed_gameplay_random(&a, 0xA11E_0001)
	seed_gameplay_random(&b, 0xA11E_0001)

	for _ in 0 ..< 64 {
		_ = gameplay_cosmetic_random_max(&b, BOMB_SOUND_COUNT)
	}
	for _ in 0 ..< 128 {
		testing.expect_value(
			t,
			gameplay_random_max(&a, 4),
			gameplay_random_max(&b, 4),
		)
	}
	testing.expect_value(t, a.run_seed, b.run_seed)
}

// Protects seeded enemy movement and random-state progression from render-rate
// dependent behavior.
@(test)
enemy_updates_are_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_seeded_enemy_scenario(30, 8, 12345)
	at_60_fps := run_seeded_enemy_scenario(60, 8, 12345)
	at_144_fps := run_seeded_enemy_scenario(144, 8, 12345)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_144_fps)
	testing.expect_value(t, at_60_fps.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, at_60_fps.state, Gameplay_State.Playing)
}

// Confirms enemy interpolation covers exactly one tile over twelve movement
// steps before committing the target cell.
@(test)
enemy_moves_one_tile_in_twelve_steps_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.enemies[0] = enemy_at({1, 1})
	gameplay.enemy_count = 1
	enemy := &gameplay.enemies[0]

	begin_enemy_action(&gameplay, enemy, .Right)
	advance_enemy_action_steps(&gameplay, 1)
	testing.expect_value(t, enemy.position, Grid_Position {1, 1})
	testing.expect_value(t, enemy.move_to, Grid_Position {2, 1})
	x, y := enemy_screen_position(enemy)
	testing.expect_value(
		t,
		x,
		i32(MAP_OFFSET_X + MAP_TILE_SIZE + MAP_TILE_SIZE / MOVEMENT_STEPS_PER_TILE),
	)
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))

	advance_enemy_action_steps(&gameplay, MOVEMENT_STEPS_PER_TILE)
	testing.expect_value(t, enemy.position, Grid_Position {2, 1})
	x, y = enemy_screen_position(enemy)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + 2 * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))
}

// Exercises terrain, item, bomb, and map-edge blocking rules used when enemies
// choose their next target.
@(test)
enemy_walkability_and_map_edges_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.enemies[0] = enemy_at({1, 1})
	gameplay.enemy_count = 1
	enemy := &gameplay.enemies[0]

	gameplay.level.data.background[2][1] = WALKABLE_TERRAIN_LIMIT
	begin_enemy_action(&gameplay, enemy, .Right)
	testing.expect_value(t, enemy.move_to, enemy.position)

	gameplay.level.data.background[2][1] = 0
	gameplay.level.data.item[2][1] = PASSABLE_ITEM_LIMIT + 1
	begin_enemy_action(&gameplay, enemy, .Right)
	testing.expect_value(t, enemy.move_to, enemy.position)

	gameplay.level.data.item[2][1] = 0
	gameplay.bomb_occupancy[2][1] = 1
	begin_enemy_action(&gameplay, enemy, .Right)
	testing.expect_value(t, enemy.move_to, enemy.position)

	gameplay.bomb_occupancy[2][1] = 0
	enemy.position = {0, 0}
	begin_enemy_action(&gameplay, enemy, .Up)
	testing.expect_value(t, enemy.move_to, Grid_Position {0, 0})
	begin_enemy_action(&gameplay, enemy, .Left)
	testing.expect_value(t, enemy.move_to, Grid_Position {0, 0})
}

// Runs seeded enemies across every shipped level to catch invalid movement or
// out-of-bounds regressions in real map data.
@(test)
seeded_enemies_stay_walkable_on_all_levels_test :: proc(t: ^testing.T) {
	for level_index in 0 ..< LEVEL_COUNT {
		gameplay: Gameplay
		if !testing.expect(t, load_level(&gameplay.level, level_index)) do continue
		if !testing.expect_value(
			t,
			setup_level_state(&gameplay),
			Level_Setup_Error.None,
		) {
			continue
		}
		seed_gameplay_random(&gameplay, u64(level_index + 1))

		for _ in 0 ..< 100 {
			begin_enemy_actions(&gameplay)
			for enemy_index in 0 ..< gameplay.enemy_count {
				enemy := &gameplay.enemies[enemy_index]
				if !enemy.active do continue
				testing.expect(t, is_in_map(enemy.move_to))
				if enemy.move_to != enemy.position {
					testing.expect(t, is_walkable(
						&gameplay.level.data,
						&gameplay.bomb_occupancy,
						enemy.move_to,
					))
				}
			}
			advance_enemy_action_steps(&gameplay, MOVEMENT_STEPS_PER_TILE)
		}
	}
}

// Verifies sub-tile contact recognizes actors crossing between adjacent cells
// before either movement action completes.
@(test)
crossing_entities_overlap_at_pixel_step_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.player.move_to = {2, 1}
	gameplay.player.movement_step = 5
	gameplay.enemies[0] = enemy_at({2, 1})
	gameplay.enemies[0].move_to = {1, 1}
	gameplay.enemies[0].movement_step = 5
	gameplay.enemy_count = 1
	testing.expect(t, !player_touches_enemy(&gameplay))

	gameplay.player.movement_step = 6
	gameplay.enemies[0].movement_step = 6
	testing.expect(t, player_touches_enemy(&gameplay))
}

// Contact grace is independent from movement boundaries and prevents another
// hit for exactly 0.75 seconds across render rates.
@(test)
contact_grace_prevents_repeat_damage_across_render_rates_test :: proc(t: ^testing.T) {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemies[1] = enemy_at(position)
	gameplay.enemy_count = 2
	block_cardinal_neighbors(&gameplay.level.data, position)
	seed_gameplay_random(&gameplay, 7)

	first_contact := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, first_contact.ticks.player_damaged)
	testing.expect_value(t, first_contact.ticks.contact_hit_requests, 1)
	testing.expect_value(t, gameplay.player.contact_grace_ticks, CONTACT_GRACE_TICKS)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY - ENEMY_CONTACT_DAMAGE)

	for _ in 1 ..< CONTACT_GRACE_TICKS {
		frame := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
		testing.expect(t, !frame.ticks.player_damaged)
	}
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY - ENEMY_CONTACT_DAMAGE)

	second_contact := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, second_contact.ticks.player_damaged)
	testing.expect_value(t, second_contact.ticks.contact_hit_requests, 1)
	testing.expect_value(
		t,
		gameplay.player.energy,
		PLAYER_START_ENERGY - 2 * ENEMY_CONTACT_DAMAGE,
	)

	expected_energy := PLAYER_START_ENERGY - 2 * ENEMY_CONTACT_DAMAGE
	testing.expect_value(t, run_stationary_contact_one_second(30), expected_energy)
	testing.expect_value(t, run_stationary_contact_one_second(60), expected_energy)
	testing.expect_value(t, run_stationary_contact_one_second(144), expected_energy)
}

// Confirms contact that reduces energy to zero reports death and routes gameplay
// to the Dead lifecycle state.
@(test)
zero_energy_transitions_to_dead_test :: proc(t: ^testing.T) {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.lives = 2
	gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemy_count = 1
	block_cardinal_neighbors(&gameplay.level.data, position)
	seed_gameplay_random(&gameplay, 11)

	frame := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, frame.ticks.player_damaged)
	testing.expect(t, frame.ticks.player_died)
	testing.expect_value(t, gameplay.player.energy, 0)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.state, Gameplay_State.Dead)
}
