package caverace

import "core:testing"

@(test)
gameplay_initial_state_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)

	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, gameplay.level_index, 0)
	testing.expect_value(t, gameplay.player.lives, PLAYER_START_LIVES)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, gameplay.player.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER)
	testing.expect_value(t, gameplay.player.score, 0)
	testing.expect_value(t, gameplay.enemy_count, 0)
}

@(test)
level_start_reset_preserves_run_progress_test :: proc(t: ^testing.T) {
	player := Player_State {
		direction     = .Right,
		lives         = 2,
		energy        = 3,
		bomb_capacity = 4,
		bomb_power    = 7,
		score         = 350,
	}

	reset_player_for_level_start(&player)
	testing.expect_value(t, player.direction, Direction.None)
	testing.expect_value(t, player.lives, 2)
	testing.expect_value(t, player.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, player.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
	testing.expect_value(t, player.bomb_power, PLAYER_START_BOMB_POWER)
	testing.expect_value(t, player.score, 350)
}

@(test)
all_levels_load_and_extract_spawns_test :: proc(t: ^testing.T) {
	for level_index in 0 ..< LEVEL_COUNT {
		gameplay: Gameplay
		init_gameplay(&gameplay)

		if !testing.expect(t, load_level(&gameplay.level, level_index)) do continue
		testing.expect_value(t, validate_level_data(&gameplay.level.data), Level_Data_Error.None)

		expected_player := Grid_Position {}
		expected_player_count := 0
		expected_enemy_count := 0
		for grid_y in 0 ..< MAP_HEIGHT {
			for grid_x in 0 ..< MAP_WIDTH {
				if gameplay.level.data.player[grid_x][grid_y] == PLAYER_SPAWN_MARKER {
					expected_player = {grid_x, grid_y}
					expected_player_count += 1
				}
				if gameplay.level.data.enemy[grid_x][grid_y] != 0 {
					expected_enemy_count += 1
				}
			}
		}

		runtime_error := initialize_level_runtime(&gameplay)
		testing.expect_value(t, runtime_error, Level_Runtime_Error.None)
		testing.expect_value(t, expected_player_count, 1)
		testing.expect_value(t, gameplay.player.position, expected_player)
		testing.expect(t, grid_position_is_valid(gameplay.player.position))
		testing.expect_value(t, gameplay.enemy_count, expected_enemy_count)
		testing.expect(t, gameplay.enemy_count <= MAX_ENEMIES)

		for enemy_index in 0 ..< gameplay.enemy_count {
			enemy := gameplay.enemies[enemy_index]
			testing.expect(t, enemy.active)
			testing.expect(t, grid_position_is_valid(enemy.position))
			testing.expect_value(
				t,
				enemy.kind,
				gameplay.level.data.enemy[enemy.position.x][enemy.position.y],
			)
		}
		for enemy_index in gameplay.enemy_count ..< MAX_ENEMIES {
			testing.expect(t, !gameplay.enemies[enemy_index].active)
		}
		for bomb in gameplay.bombs {
			testing.expect(t, !bomb.active)
		}
		for column in gameplay.bomb_occupancy {
			for occupied in column do testing.expect_value(t, occupied, u8(0))
		}
	}
}

@(test)
level_data_validation_test :: proc(t: ^testing.T) {
	data: Map_Data

	data.background[0][0] = TERRAIN_SPRITE_COUNT
	testing.expect_value(t, validate_level_data(&data), Level_Data_Error.Invalid_Background)

	data = {}
	data.item[0][0] = ITEM_SPRITE_COUNT
	testing.expect_value(t, validate_level_data(&data), Level_Data_Error.Invalid_Item)

	data = {}
	data.treasure[0][0] = TREASURE_SPRITE_COUNT
	testing.expect_value(t, validate_level_data(&data), Level_Data_Error.Invalid_Treasure)

	data = {}
	data.enemy[0][0] = ENEMY_SPRITE_COUNT
	testing.expect_value(t, validate_level_data(&data), Level_Data_Error.Invalid_Enemy)

	data = {}
	data.player[0][0] = PLAYER_SPAWN_MARKER + 1
	testing.expect_value(t, validate_level_data(&data), Level_Data_Error.Invalid_Player)
}

@(test)
spawn_validation_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)
	testing.expect_value(
		t,
		initialize_level_runtime(&gameplay),
		Level_Runtime_Error.Missing_Player,
	)

	gameplay.level.data.player[0][0] = PLAYER_SPAWN_MARKER
	gameplay.level.data.player[1][0] = PLAYER_SPAWN_MARKER
	testing.expect_value(
		t,
		initialize_level_runtime(&gameplay),
		Level_Runtime_Error.Multiple_Players,
	)

	gameplay.level.data = {}
	gameplay.level.data.player[0][0] = PLAYER_SPAWN_MARKER
	for enemy_index in 0 ..< MAX_ENEMIES + 1 {
		gameplay.level.data.enemy[enemy_index][0] = 1
	}
	testing.expect_value(
		t,
		initialize_level_runtime(&gameplay),
		Level_Runtime_Error.Too_Many_Enemies,
	)
}

@(test)
spawn_extraction_clears_stale_runtime_state_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)
	if !testing.expect(t, load_level(&gameplay.level, 0)) do return

	gameplay.player.direction = .Left
	gameplay.enemies[MAX_ENEMIES - 1].active = true
	gameplay.enemy_count = MAX_ENEMIES
	gameplay.bombs[0] = Bomb_State {
		active       = true,
		position     = {1, 1},
		fuse_actions = 3,
		power        = 2,
	}
	gameplay.bomb_occupancy[1][1] = 1

	testing.expect_value(
		t,
		initialize_level_runtime(&gameplay),
		Level_Runtime_Error.None,
	)
	testing.expect_value(t, gameplay.player.direction, Direction.None)
	testing.expect_value(t, gameplay.player.lives, PLAYER_START_LIVES)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[1][1], u8(0))
	for enemy_index in gameplay.enemy_count ..< MAX_ENEMIES {
		testing.expect(t, !gameplay.enemies[enemy_index].active)
	}
}

@(test)
grid_position_helpers_test :: proc(t: ^testing.T) {
	testing.expect(t, grid_position_is_valid({0, 0}))
	testing.expect(t, grid_position_is_valid({MAP_WIDTH - 1, MAP_HEIGHT - 1}))
	testing.expect(t, !grid_position_is_valid({-1, 0}))
	testing.expect(t, !grid_position_is_valid({0, -1}))
	testing.expect(t, !grid_position_is_valid({MAP_WIDTH, 0}))
	testing.expect(t, !grid_position_is_valid({0, MAP_HEIGHT}))

	x, y := grid_position_to_screen({0, 0})
	testing.expect_value(t, x, i32(MAP_OFFSET_X))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y))
	x, y = grid_position_to_screen({MAP_WIDTH - 1, MAP_HEIGHT - 1})
	testing.expect_value(t, x, i32(MAP_OFFSET_X + (MAP_WIDTH - 1) * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + (MAP_HEIGHT - 1) * MAP_TILE_SIZE))
}
