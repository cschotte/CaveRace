package caverace

import "core:testing"

Simulation_Test_Summary :: struct {
	steps:              int,
	action_decisions:   int,
	movement_decisions: int,
	player_position:    Grid_Position,
}

run_held_direction_simulation :: proc(render_fps, seconds: int) -> Simulation_Test_Summary {
	gameplay := Gameplay {state = .Playing}
	input := Game_Input {move_right = true}
	summary: Simulation_Test_Summary

	for _ in 0 ..< render_fps * seconds {
		frame_result := update_gameplay(&gameplay, input, 1.0 / f64(render_fps))
		summary.steps += frame_result.simulation.steps_run
		summary.action_decisions += frame_result.simulation.action_decisions
		if frame_result.simulation.action_decisions > 0 &&
		   frame_result.simulation.last_action == .Move_Right {
			summary.movement_decisions += 1
		}
	}
	summary.player_position = gameplay.player.position
	return summary
}

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
		testing.expect(t, is_in_map(gameplay.player.position))
		testing.expect_value(t, gameplay.enemy_count, expected_enemy_count)
		testing.expect(t, gameplay.enemy_count <= MAX_ENEMIES)

		for enemy_index in 0 ..< gameplay.enemy_count {
			enemy := gameplay.enemies[enemy_index]
			testing.expect(t, enemy.active)
			testing.expect(t, is_in_map(enemy.position))
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
	gameplay.simulation = Gameplay_Simulation_State {
		accumulator_seconds = 0.1,
		action_step         = 7,
		input               = {move_left = true, bomb_pending = true},
	}

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
	testing.expect_value(t, gameplay.simulation, Gameplay_Simulation_State {})
	for enemy_index in gameplay.enemy_count ..< MAX_ENEMIES {
		testing.expect(t, !gameplay.enemies[enemy_index].active)
	}
}

@(test)
grid_position_helpers_test :: proc(t: ^testing.T) {
	testing.expect(t, is_in_map({0, 0}))
	testing.expect(t, is_in_map({MAP_WIDTH - 1, MAP_HEIGHT - 1}))
	testing.expect(t, !is_in_map({-1, 0}))
	testing.expect(t, !is_in_map({0, -1}))
	testing.expect(t, !is_in_map({MAP_WIDTH, 0}))
	testing.expect(t, !is_in_map({0, MAP_HEIGHT}))

	x, y := grid_position_to_screen({0, 0})
	testing.expect_value(t, x, i32(MAP_OFFSET_X))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y))
	x, y = grid_position_to_screen({MAP_WIDTH - 1, MAP_HEIGHT - 1})
	testing.expect_value(t, x, i32(MAP_OFFSET_X + (MAP_WIDTH - 1) * MAP_TILE_SIZE))
	testing.expect_value(t, y, i32(MAP_OFFSET_Y + (MAP_HEIGHT - 1) * MAP_TILE_SIZE))
}

@(test)
fixed_simulation_is_render_rate_independent_test :: proc(t: ^testing.T) {
	at_30_fps := run_held_direction_simulation(30, 4)
	at_60_fps := run_held_direction_simulation(60, 4)
	at_240_fps := run_held_direction_simulation(240, 4)

	testing.expect_value(t, at_30_fps, at_60_fps)
	testing.expect_value(t, at_60_fps, at_240_fps)
	testing.expect_value(t, at_60_fps.steps, 4 * SIMULATION_HZ)
	testing.expect_value(t, at_60_fps.action_decisions, 15)
	testing.expect_value(t, at_60_fps.movement_decisions, 15)
	testing.expect_value(t, at_60_fps.player_position, Grid_Position {15, 0})
}

@(test)
legacy_action_priority_test :: proc(t: ^testing.T) {
	input := Gameplay_Input_Buffer {
		move_down   = true,
		move_up     = true,
		move_right  = true,
		move_left   = true,
		bomb_pending = true,
	}

	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.Place_Bomb)
	testing.expect(t, !input.bomb_pending)
	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.Move_Down)
	input.move_down = false
	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.Move_Up)
	input.move_up = false
	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.Move_Right)
	input.move_right = false
	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.Move_Left)
	input.move_left = false
	testing.expect_value(t, select_gameplay_action(&input), Gameplay_Action.None)
}

@(test)
bomb_press_is_latched_until_action_boundary_test :: proc(t: ^testing.T) {
	gameplay := Gameplay {simulation = {action_step = 1}}
	buffer_gameplay_input(&gameplay.simulation, Game_Input {space_pressed = true})

	before_step := advance_gameplay_simulation(&gameplay, 1.0 / 240.0)
	testing.expect_value(t, before_step.steps_run, 0)
	testing.expect(t, gameplay.simulation.input.bomb_pending)

	before_boundary := advance_gameplay_simulation(
		&gameplay,
		f64(MOVEMENT_STEPS_PER_TILE - 1) * SIMULATION_STEP_SECONDS,
	)
	testing.expect_value(t, before_boundary.steps_run, MOVEMENT_STEPS_PER_TILE - 1)
	testing.expect_value(t, before_boundary.action_decisions, 0)
	testing.expect(t, gameplay.simulation.input.bomb_pending)

	at_boundary := advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect_value(t, at_boundary.action_decisions, 1)
	testing.expect_value(t, at_boundary.last_action, Gameplay_Action.Place_Bomb)
	testing.expect(t, at_boundary.bomb_action_started)
	testing.expect(t, !gameplay.simulation.input.bomb_pending)
}

@(test)
edge_input_and_simulation_limits_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	input: Game_Input
	input.cheat_pressed[.F3] = true
	buffer_gameplay_input(&gameplay.simulation, input)

	before_step := advance_gameplay_simulation(&gameplay, 0)
	testing.expect(t, gameplay.simulation.input.cheat_pending[.F3])
	testing.expect(t, !before_step.cheat_pressed[.F3])

	after_step := advance_gameplay_simulation(&gameplay, SIMULATION_STEP_SECONDS)
	testing.expect(t, after_step.cheat_pressed[.F3])
	testing.expect(t, !gameplay.simulation.input.cheat_pending[.F3])

	clamped := advance_gameplay_simulation(&gameplay, 1.0)
	testing.expect_value(t, clamped.steps_run, MAX_SIMULATION_STEPS_PER_FRAME)
	testing.expect(t, MAX_SIMULATION_STEPS_PER_FRAME < MOVEMENT_STEPS_PER_TILE)
}

@(test)
render_rate_and_high_score_input_test :: proc(t: ^testing.T) {
	testing.expect_value(t, target_render_fps({}), i32(TARGET_RENDER_FPS))
	testing.expect_value(
		t,
		target_render_fps({slow_mode = true}),
		i32(SLOW_RENDER_FPS),
	)
	testing.expect(t, !update_high_scores({}))
	testing.expect(t, update_high_scores({space_pressed = true}))
	testing.expect(t, update_high_scores({mouse = {left_pressed = true}}))
	testing.expect(t, update_high_scores({mouse = {right_pressed = true}}))
}
