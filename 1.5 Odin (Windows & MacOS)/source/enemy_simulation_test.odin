package caverace

import "core:testing"

enemy_at :: proc(position: Grid_Position, kind: u8 = 1) -> Enemy_State {
	return Enemy_State {
		active    = true,
		kind      = kind,
		position  = position,
		move_from = position,
		move_to   = position,
	}
}

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

Enemy_Simulation_Summary :: struct {
	enemies: [MAX_ENEMIES]Enemy_State,
	energy:  int,
	state:   Gameplay_State,
}

run_seeded_enemy_simulation :: proc(render_fps, seconds: int, seed: u64) -> Enemy_Simulation_Summary {
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

run_stationary_contact_half_second :: proc(render_fps: int) -> int {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemy_count = 1
	block_cardinal_neighbors(&gameplay.level.data, position)
	seed_gameplay_random(&gameplay, 99)

	for _ in 0 ..< render_fps / 2 {
		update_gameplay(&gameplay, {}, 1.0 / f64(render_fps))
	}
	return gameplay.player.energy
}

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
enemy_simulation_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_seeded_enemy_simulation(30, 8, 12345)
	at_60_fps := run_seeded_enemy_simulation(60, 8, 12345)
	at_240_fps := run_seeded_enemy_simulation(240, 8, 12345)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_240_fps)
	testing.expect_value(t, at_60_fps.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, at_60_fps.state, Gameplay_State.Playing)
}

@(test)
enemy_moves_one_tile_in_sixteen_steps_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.enemies[0] = enemy_at({1, 1})
	gameplay.enemy_count = 1
	enemy := &gameplay.enemies[0]

	begin_enemy_action(&gameplay, enemy, .Right)
	advance_enemy_action_steps(&gameplay, 1)
	testing.expect_value(t, enemy.position, Grid_Position {1, 1})
	testing.expect_value(t, enemy.move_to, Grid_Position {2, 1})
	x, y := enemy_screen_position(enemy)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + MAP_TILE_SIZE + MOVEMENT_PIXELS_PER_STEP))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))

	advance_enemy_action_steps(&gameplay, MOVEMENT_STEPS_PER_TILE)
	testing.expect_value(t, enemy.position, Grid_Position {2, 1})
	x, y = enemy_screen_position(enemy)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + 2 * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))
}

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

@(test)
seeded_enemies_stay_walkable_on_all_levels_test :: proc(t: ^testing.T) {
	for level_index in 0 ..< LEVEL_COUNT {
		gameplay: Gameplay
		if !testing.expect(t, load_level(&gameplay.level, level_index)) do continue
		if !testing.expect_value(
			t,
			initialize_level_runtime(&gameplay),
			Level_Runtime_Error.None,
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

@(test)
crossing_entities_overlap_at_pixel_step_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.player.move_to = {2, 1}
	gameplay.player.movement_step = 7
	gameplay.enemies[0] = enemy_at({2, 1})
	gameplay.enemies[0].move_to = {1, 1}
	gameplay.enemies[0].movement_step = 7
	gameplay.enemy_count = 1
	testing.expect(t, !player_touches_enemy(&gameplay))

	gameplay.player.movement_step = 8
	gameplay.enemies[0].movement_step = 8
	testing.expect(t, player_touches_enemy(&gameplay))
}

@(test)
contact_damage_occurs_once_per_action_test :: proc(t: ^testing.T) {
	position := Grid_Position {5, 5}
	gameplay := open_gameplay_at(position)
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemies[1] = enemy_at(position)
	gameplay.enemy_count = 2
	block_cardinal_neighbors(&gameplay.level.data, position)
	seed_gameplay_random(&gameplay, 7)

	first_contact := update_gameplay(&gameplay, {}, SIMULATION_STEP_SECONDS)
	testing.expect(t, first_contact.simulation.player_damaged)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY - ENEMY_CONTACT_DAMAGE)

	for _ in 1 ..< MOVEMENT_STEPS_PER_TILE {
		frame := update_gameplay(&gameplay, {}, SIMULATION_STEP_SECONDS)
		testing.expect(t, !frame.simulation.player_damaged)
	}
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY - ENEMY_CONTACT_DAMAGE)

	second_contact := update_gameplay(&gameplay, {}, SIMULATION_STEP_SECONDS)
	testing.expect(t, second_contact.simulation.player_damaged)
	testing.expect_value(
		t,
		gameplay.player.energy,
		PLAYER_START_ENERGY - 2 * ENEMY_CONTACT_DAMAGE,
	)

	expected_energy := PLAYER_START_ENERGY - 2 * ENEMY_CONTACT_DAMAGE
	testing.expect_value(t, run_stationary_contact_half_second(30), expected_energy)
	testing.expect_value(t, run_stationary_contact_half_second(60), expected_energy)
	testing.expect_value(t, run_stationary_contact_half_second(240), expected_energy)
}

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

	frame := update_gameplay(&gameplay, {}, SIMULATION_STEP_SECONDS)
	testing.expect(t, frame.simulation.player_damaged)
	testing.expect(t, frame.simulation.player_died)
	testing.expect_value(t, gameplay.player.energy, 0)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.state, Gameplay_State.Dead)
}
