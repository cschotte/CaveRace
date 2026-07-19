package caverace

import "core:testing"

@(test)
explosion_cells_are_clipped_and_unique_at_every_map_edge_test :: proc(t: ^testing.T) {
	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			bomb := Bomb_State {
				active   = true,
				position = {grid_x, grid_y},
				power    = PLAYER_MAX_BOMB_POWER,
			}
			explosion := build_explosion_state(&bomb)
			expected_count := 1 +
				min(PLAYER_MAX_BOMB_POWER, grid_y) +
				min(PLAYER_MAX_BOMB_POWER, MAP_HEIGHT - 1 - grid_y) +
				min(PLAYER_MAX_BOMB_POWER, grid_x) +
				min(PLAYER_MAX_BOMB_POWER, MAP_WIDTH - 1 - grid_x)
			testing.expect_value(t, explosion.cell_count, expected_count)
			testing.expect(t, explosion.cell_count <= MAX_EXPLOSION_CELLS)

			seen: [MAP_WIDTH][MAP_HEIGHT]bool
			for cell_index in 0 ..< explosion.cell_count {
				cell := explosion.cells[cell_index]
				testing.expect(t, is_in_map(cell.position))
				testing.expect(t, !seen[cell.position.x][cell.position.y])
				seen[cell.position.x][cell.position.y] = true
			}
		}
	}
}

@(test)
explosion_animation_uses_legacy_directional_sprite_sets_test :: proc(t: ^testing.T) {
	expected_sets := [EXPLOSION_STEPS]int {
		0, 0, 0,
		1, 1, 1,
		2, 2, 2, 2,
		1, 1, 1,
		0, 0, 0,
	}
	first_sprites := [3]int {
		EXPLOSION_SET_1_FIRST_SPRITE,
		EXPLOSION_SET_2_FIRST_SPRITE,
		EXPLOSION_SET_3_FIRST_SPRITE,
	}
	for age_step in 1 ..= EXPLOSION_STEPS {
		set := expected_sets[age_step - 1]
		testing.expect_value(t, explosion_animation_set(age_step), set)
		for kind_index in 0 ..< 5 {
			actual := explosion_sprite_index(
				Explosion_Cell_Kind(kind_index),
				age_step,
			)
			testing.expect_value(t, actual, u8(first_sprites[set] + kind_index))
		}
	}
}

@(test)
explosion_preserves_legacy_object_and_treasure_rules_test :: proc(t: ^testing.T) {
	center := Grid_Position {5, 5}
	gameplay := open_gameplay_at({0, 0})
	bomb := Bomb_State {active = true, position = center, power = 1}
	explosion := build_explosion_state(&bomb)

	gameplay.level.data.item[5][5] = 5
	gameplay.level.data.treasure[5][5] = 1
	gameplay.level.data.item[5][6] = 8
	gameplay.level.data.item[4][5] = INDESTRUCTIBLE_ITEM_FIRST
	gameplay.level.data.item[5][4] = ITEM_SPRITE_COUNT - 1
	gameplay.level.data.treasure[5][4] = 1
	gameplay.level.data.treasure[6][5] = 2
	for cell_index in 0 ..< explosion.cell_count {
		cell := explosion.cells[cell_index]
		gameplay.level.data.background[cell.position.x][cell.position.y] = 17
	}

	apply_explosion_to_level(&gameplay, &explosion)
	testing.expect_value(t, gameplay.level.data.item[5][5], u8(5))
	testing.expect_value(t, gameplay.level.data.treasure[5][5], u8(1))
	testing.expect_value(t, gameplay.level.data.item[5][6], u8(0))
	testing.expect_value(t, gameplay.level.data.item[4][5], u8(INDESTRUCTIBLE_ITEM_FIRST))
	testing.expect_value(t, gameplay.level.data.item[5][4], u8(0))
	testing.expect_value(t, gameplay.level.data.treasure[5][4], u8(0))
	testing.expect_value(t, gameplay.level.data.treasure[6][5], u8(0))
	for cell_index in 0 ..< explosion.cell_count {
		cell := explosion.cells[cell_index]
		testing.expect_value(
			t,
			gameplay.level.data.background[cell.position.x][cell.position.y],
			u8(17),
		)
	}
}

@(test)
explosion_chain_settles_once_without_recursion_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	seed_gameplay_random(&gameplay, 0xC0FFEE)
	gameplay.bombs[0] = {active = true, position = {7, 5}, fuse_actions = 8, power = 2}
	gameplay.bombs[1] = {active = true, position = {9, 5}, fuse_actions = 8, power = 2}
	gameplay.bombs[2] = {active = true, position = {5, 5}, fuse_actions = 1, power = 2}
	gameplay.bombs[3] = {active = true, position = {15, 5}, fuse_actions = 8, power = 2}

	result: Gameplay_Simulation_Result
	start_ready_explosions(&gameplay, &result)
	testing.expect_value(t, result.explosions_started, 3)
	testing.expect_value(t, result.explosion_sound_count, 3)
	for bomb_index in 0 ..< 3 {
		testing.expect(t, gameplay.explosions[bomb_index].active)
		testing.expect_value(t, gameplay.bombs[bomb_index].fuse_actions, 1)
	}
	testing.expect(t, !gameplay.explosions[3].active)
	testing.expect_value(t, gameplay.bombs[3].fuse_actions, 8)
	for sound_index in 0 ..< result.explosion_sound_count {
		testing.expect(t, result.explosion_sound_indices[sound_index] < BOMB_SOUND_COUNT)
	}

	second_result: Gameplay_Simulation_Result
	start_ready_explosions(&gameplay, &second_result)
	testing.expect_value(t, second_result.explosions_started, 0)
	testing.expect_value(t, second_result.explosion_sound_count, 0)
}

@(test)
overlapping_explosions_destroy_each_enemy_and_score_once_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.score = 10
	first_bomb := Bomb_State {active = true, position = {5, 5}, power = 2}
	second_bomb := Bomb_State {active = true, position = {7, 5}, power = 2}
	gameplay.explosions[0] = build_explosion_state(&first_bomb)
	gameplay.explosions[1] = build_explosion_state(&second_bomb)
	gameplay.enemies[0] = enemy_at({6, 5})
	gameplay.enemies[1] = enemy_at({5, 7})
	gameplay.enemies[2] = enemy_at({0, 1})
	gameplay.enemy_count = 3

	result: Gameplay_Simulation_Result
	apply_active_explosions_to_entities(&gameplay, &result)
	testing.expect_value(t, result.enemies_destroyed, 2)
	testing.expect_value(t, result.squish_requests, 2)
	testing.expect_value(t, gameplay.player.score, 10 + 2 * SCORE_ENEMY_DESTROYED)
	testing.expect(t, !gameplay.enemies[0].active)
	testing.expect(t, !gameplay.enemies[1].active)
	testing.expect(t, gameplay.enemies[2].active)

	second_result: Gameplay_Simulation_Result
	apply_active_explosions_to_entities(&gameplay, &second_result)
	testing.expect_value(t, second_result.enemies_destroyed, 0)
	testing.expect_value(t, second_result.squish_requests, 0)
	testing.expect_value(t, gameplay.player.score, 10 + 2 * SCORE_ENEMY_DESTROYED)
}

@(test)
explosion_hit_sets_player_energy_to_zero_and_transitions_dead_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({5, 6})
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.bombs[0] = {active = true, position = {5, 5}, fuse_actions = 2, power = 1}
	gameplay.bomb_occupancy[5][5] = BOMB_TICKING_SPRITE
	seed_gameplay_random(&gameplay, 17)

	frame := update_gameplay(&gameplay, {}, SIMULATION_STEP_SECONDS)
	testing.expect_value(t, frame.simulation.explosions_started, 1)
	testing.expect_value(t, frame.simulation.explosion_sound_count, 1)
	testing.expect(t, frame.simulation.player_damaged)
	testing.expect(t, frame.simulation.player_died)
	testing.expect_value(t, gameplay.player.energy, 0)
	testing.expect_value(t, gameplay.state, Gameplay_State.Dead)
	testing.expect(t, gameplay.explosions[0].active)
	testing.expect_value(t, gameplay.explosions[0].age_step, 1)
}

@(test)
expired_bomb_releases_its_explosion_and_occupancy_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	position := Grid_Position {3, 3}
	gameplay.bombs[0] = {active = true, position = position, fuse_actions = 1, power = 3}
	gameplay.explosions[0] = build_explosion_state(&gameplay.bombs[0])
	gameplay.bomb_occupancy[position.x][position.y] = BOMB_TICKING_SPRITE

	testing.expect_value(t, advance_bomb_fuses(&gameplay), 1)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect(t, !gameplay.explosions[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[position.x][position.y], u8(0))
	clear_bomb_slot(&gameplay, 0)
	testing.expect(t, !gameplay.explosions[0].active)
}
