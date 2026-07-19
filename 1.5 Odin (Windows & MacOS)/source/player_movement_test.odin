package caverace

import "core:testing"

// open_gameplay_at creates a minimal active gameplay state at one grid cell for
// movement and collision tests that do not require a loaded level.
open_gameplay_at :: proc(position: Grid_Position) -> Gameplay {
	return Gameplay {
		state = .Playing,
		player = {
			position  = position,
			move_from = position,
			move_to   = position,
		},
	}
}

// Exercises shared walkability rules for terrain, items, bombs, and map bounds.
@(test)
walkability_rules_test :: proc(t: ^testing.T) {
	data: Map_Data
	occupancy: Map_Grid
	position := Grid_Position {1, 1}

	data.background[position.x][position.y] = WALKABLE_TERRAIN_LIMIT - 1
	data.item[position.x][position.y] = PASSABLE_ITEM_LIMIT
	testing.expect(t, is_walkable(&data, &occupancy, position))

	data.background[position.x][position.y] = WALKABLE_TERRAIN_LIMIT
	testing.expect(t, !is_walkable(&data, &occupancy, position))

	data.background[position.x][position.y] = 0
	data.item[position.x][position.y] = PASSABLE_ITEM_LIMIT + 1
	testing.expect(t, !is_walkable(&data, &occupancy, position))

	data.item[position.x][position.y] = 0
	occupancy[position.x][position.y] = 1
	testing.expect(t, cell_has_bomb(&occupancy, position))
	testing.expect(t, !is_walkable(&data, &occupancy, position))

	testing.expect(t, !cell_has_bomb(&occupancy, {-1, 0}))
	testing.expect(t, !is_walkable(&data, &occupancy, {-1, 0}))
	testing.expect(t, !is_walkable(&data, &occupancy, {MAP_WIDTH, MAP_HEIGHT - 1}))
}

// Verifies grid-to-screen and screen-to-grid conversions at valid positions,
// offsets, and out-of-map coordinates.
@(test)
grid_and_screen_conversion_test :: proc(t: ^testing.T) {
	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			expected := Grid_Position {grid_x, grid_y}
			screen_x, screen_y := grid_position_to_screen(expected)
			actual, ok := screen_to_grid_position(screen_x, screen_y)
			testing.expect(t, ok)
			testing.expect_value(t, actual, expected)

			actual, ok = screen_to_grid_position(
				screen_x + MAP_TILE_SIZE - 1,
				screen_y + MAP_TILE_SIZE - 1,
			)
			testing.expect(t, ok)
			testing.expect_value(t, actual, expected)
		}
	}

	_, ok := screen_to_grid_position(MAP_OFFSET_X - 1, MAP_OFFSET_Y)
	testing.expect(t, !ok)
	_, ok = screen_to_grid_position(MAP_OFFSET_X, MAP_OFFSET_Y - 1)
	testing.expect(t, !ok)
	_, ok = screen_to_grid_position(
		MAP_OFFSET_X + MAP_WIDTH * MAP_TILE_SIZE,
		MAP_OFFSET_Y,
	)
	testing.expect(t, !ok)
	_, ok = screen_to_grid_position(
		MAP_OFFSET_X,
		MAP_OFFSET_Y + MAP_HEIGHT * MAP_TILE_SIZE,
	)
	testing.expect(t, !ok)
}

// Protects the separation between simulation-space interpolation and render
// coordinates for every cardinal direction and intermediate movement step.
@(test)
movement_subtile_and_screen_positions_are_equivalent_test :: proc(t: ^testing.T) {
	origin := Grid_Position {5, 5}
	directions := [4]Direction {
		.Down,
		.Up,
		.Right,
		.Left,
	}
	for direction in directions {
		delta := direction_delta(direction)
		target := Grid_Position {origin.x + delta.x, origin.y + delta.y}
		for movement_step in 0 ..= MOVEMENT_STEPS_PER_TILE {
			subtile := movement_subtile_position(origin, target, movement_step)
			screen_x, screen_y := movement_screen_position(
				origin,
				target,
				movement_step,
			)
			testing.expect_value(
				t,
				screen_x,
				i32(MAP_OFFSET_X + subtile.x * MOVEMENT_PIXELS_PER_STEP),
			)
			testing.expect_value(
				t,
				screen_y,
				i32(MAP_OFFSET_Y + subtile.y * MOVEMENT_PIXELS_PER_STEP),
			)

			grid_from_movement, movement_ok := movement_grid_position(
				origin,
				target,
				movement_step,
			)
			grid_from_screen, screen_ok := screen_to_grid_position(screen_x, screen_y)
			testing.expect_value(t, movement_ok, screen_ok)
			testing.expect_value(t, grid_from_movement, grid_from_screen)
		}
	}
}

// Confirms player movement interpolates over exactly sixteen steps, commits one
// tile, and starts the next queued direction only at the boundary.
@(test)
player_moves_one_tile_in_sixteen_steps_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	right_input := Game_Input {move_right = true}

	first_frame := update_gameplay(&gameplay, right_input, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, first_frame.ticks.last_action, Gameplay_Action.Move_Right)
	testing.expect_value(t, gameplay.player.position, Grid_Position {1, 1})
	testing.expect_value(t, gameplay.player.move_to, Grid_Position {2, 1})
	testing.expect_value(t, gameplay.player.movement_step, 1)
	x, y := player_screen_position(&gameplay.player)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + MAP_TILE_SIZE + MOVEMENT_PIXELS_PER_STEP))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))

	up_input := Game_Input {move_up = true}
	for _ in 1 ..< MOVEMENT_STEPS_PER_TILE {
		update_gameplay(&gameplay, up_input, GAMEPLAY_TICK_SECONDS)
		testing.expect_value(t, gameplay.player.direction, Direction.Right)
	}

	testing.expect_value(t, gameplay.player.position, Grid_Position {2, 1})
	testing.expect_value(t, gameplay.player.movement_step, MOVEMENT_STEPS_PER_TILE)
	x, y = player_screen_position(&gameplay.player)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + 2 * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))

	next_action := update_gameplay(&gameplay, up_input, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, next_action.ticks.last_action, Gameplay_Action.Move_Up)
	testing.expect_value(t, gameplay.player.direction, Direction.Up)
	testing.expect_value(t, gameplay.player.position, Grid_Position {2, 1})
	testing.expect_value(t, gameplay.player.move_to, Grid_Position {2, 0})
	x, y = player_screen_position(&gameplay.player)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + 2 * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE - MOVEMENT_PIXELS_PER_STEP))
}

// Verifies blocked actions keep player position and interpolation endpoints on
// the current cell for their full duration.
@(test)
blocked_player_action_stays_in_current_cell_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({1, 1})
	gameplay.level.data.background[2][1] = WALKABLE_TERRAIN_LIMIT

	for _ in 0 ..< MOVEMENT_STEPS_PER_TILE {
		update_gameplay(
			&gameplay,
			Game_Input {move_right = true},
			GAMEPLAY_TICK_SECONDS,
		)
	}

	testing.expect_value(t, gameplay.player.position, Grid_Position {1, 1})
	testing.expect_value(t, gameplay.player.move_to, Grid_Position {1, 1})
	testing.expect_value(t, gameplay.player.direction, Direction.Right)
	x, y := player_screen_position(&gameplay.player)
	testing.expect_value(t, x, i32(MAP_OFFSET_X + MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + MAP_TILE_SIZE))
}

// Protects direction-specific legacy animation speeds, sprite ranges, and idle
// fallback selection.
@(test)
player_directional_animation_test :: proc(t: ^testing.T) {
	player: Player_State
	testing.expect_value(t, player_sprite_index(&player), u8(PLAYER_IDLE_SPRITE))

	player.direction = .Down
	player.movement_step = 1
	testing.expect_value(t, player_sprite_index(&player), u8(1))
	player.movement_step = 3
	testing.expect_value(t, player_sprite_index(&player), u8(2))
	player.movement_step = 8
	testing.expect_value(t, player_sprite_index(&player), u8(4))
	player.movement_step = 16
	testing.expect_value(t, player_sprite_index(&player), u8(4))

	player.direction = .Up
	player.movement_step = 1
	testing.expect_value(t, player_sprite_index(&player), u8(5))
	player.movement_step = 16
	testing.expect_value(t, player_sprite_index(&player), u8(8))

	player.direction = .Left
	player.movement_step = 1
	testing.expect_value(t, player_sprite_index(&player), u8(9))
	player.movement_step = 5
	testing.expect_value(t, player_sprite_index(&player), u8(10))
	player.movement_step = 16
	testing.expect_value(t, player_sprite_index(&player), u8(12))

	player.direction = .Right
	player.movement_step = 1
	testing.expect_value(t, player_sprite_index(&player), u8(13))
	player.movement_step = 5
	testing.expect_value(t, player_sprite_index(&player), u8(14))
	player.movement_step = 16
	testing.expect_value(t, player_sprite_index(&player), u8(16))
}

// Checks every cardinal transition on every shipped level against the shared
// walkability predicate and final committed position.
@(test)
all_level_cardinal_transitions_respect_walkability_test :: proc(t: ^testing.T) {
	actions := [4]Gameplay_Action {
		.Move_Down,
		.Move_Up,
		.Move_Right,
		.Move_Left,
	}

	for level_index in 0 ..< LEVEL_COUNT {
		gameplay: Gameplay
		if !testing.expect(t, load_level(&gameplay.level, level_index)) do continue

		for grid_y in 0 ..< MAP_HEIGHT {
			for grid_x in 0 ..< MAP_WIDTH {
				source := Grid_Position {grid_x, grid_y}
				if !is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, source) {
					continue
				}

				for action in actions {
					gameplay.player = {
						position  = source,
						move_from = source,
						move_to   = source,
					}
					begin_player_action(&gameplay, action)

					delta := direction_delta(gameplay.player.direction)
					target := Grid_Position {source.x + delta.x, source.y + delta.y}
					expected := source
					if is_walkable(&gameplay.level.data, &gameplay.bomb_occupancy, target) {
						expected = target
					}
					testing.expect_value(t, gameplay.player.move_to, expected)

					advance_player_action_step(&gameplay.player, MOVEMENT_STEPS_PER_TILE)
					testing.expect_value(t, gameplay.player.position, expected)
					testing.expect(t, is_in_map(gameplay.player.position))
					testing.expect(
						t,
						is_walkable(
							&gameplay.level.data,
							&gameplay.bomb_occupancy,
							gameplay.player.position,
						),
					)
				}
			}
		}
	}
}
