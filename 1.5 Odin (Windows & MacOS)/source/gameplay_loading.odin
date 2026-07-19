package caverace

import "core:fmt"

// load_gameplay_level is called by Game only while the Playing screen is in
// Load_Level. This keeps filesystem/resource concerns out of the fixed-step
// update while retaining Gameplay ownership of the loaded and mutable data.
load_gameplay_level :: proc(gameplay: ^Gameplay, resource_root: string) {
	assert(gameplay.state == .Load_Level)
	if !load_level(&gameplay.level, gameplay.level_index, resource_root) {
		gameplay.state = .Load_Failed
		return
	}

	if runtime_error := initialize_level_runtime(gameplay); runtime_error != .None {
		fmt.eprintln("Failed to initialize level runtime:", runtime_error)
		gameplay.state = .Load_Failed
		return
	}

	gameplay.theme = Tile_Theme(gameplay_random_max(gameplay, len(Tile_Theme)))
	gameplay.state = .Playing
}

// initialize_level_runtime converts immutable map spawn markers into mutable,
// fixed-capacity gameplay state. It validates into locals first, so failure
// never leaves a partly initialized session behind.
initialize_level_runtime :: proc(gameplay: ^Gameplay) -> Level_Runtime_Error {
	player_position: Grid_Position
	player_count := 0
	enemies: [MAX_ENEMIES]Enemy_State
	enemy_count := 0

	for grid_y in 0 ..< MAP_HEIGHT {
		for grid_x in 0 ..< MAP_WIDTH {
			if gameplay.level.data.player[grid_x][grid_y] == PLAYER_SPAWN_MARKER {
				player_count += 1
				if player_count > 1 do return .Multiple_Players
				player_position = {grid_x, grid_y}
			}

			if kind := gameplay.level.data.enemy[grid_x][grid_y]; kind != 0 {
				if enemy_count >= MAX_ENEMIES do return .Too_Many_Enemies
				enemies[enemy_count] = Enemy_State {
					active    = true,
					kind      = kind,
					position  = {grid_x, grid_y},
					move_from = {grid_x, grid_y},
					move_to   = {grid_x, grid_y},
				}
				enemy_count += 1
			}
		}
	}

	if player_count == 0 do return .Missing_Player

	gameplay.player.position = player_position
	gameplay.player.move_from = player_position
	gameplay.player.move_to = player_position
	gameplay.player.movement_step = 0
	gameplay.player.direction = .None
	gameplay.enemies = enemies
	gameplay.enemy_count = enemy_count
	gameplay.bombs = {}
	gameplay.explosions = {}
	gameplay.bomb_occupancy = {}
	gameplay.simulation = {}
	gameplay.level_completion_enabled = true
	return .None
}
