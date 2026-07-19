package caverace

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// Gameplay_State describes the lifecycle within the Playing screen. Gameplay
// systems should use change_gameplay_state instead of assigning it directly.
Gameplay_State :: enum {
	Load_Level,
	Playing,
	Dead,
	Won,
	Load_Failed,
}

Gameplay :: struct {
	state:          Gameplay_State,
	level:          Level,
	level_index:    int,
	theme:          Tile_Theme,
	player:         Player_State,
	enemies:        [MAX_ENEMIES]Enemy_State,
	enemy_count:    int,
	bombs:          [MAX_BOMBS]Bomb_State,
	explosions:     [MAX_BOMBS]Explosion_State,
	bomb_occupancy: Map_Grid,
	simulation:     Gameplay_Simulation_State,
	random_state:   rand.Xoshiro256_Random_State,
}

Gameplay_Frame_Result :: struct {
	back_requested: bool,
	simulation:     Gameplay_Simulation_Result,
}

init_gameplay :: proc(gameplay: ^Gameplay) {
	gameplay^ = Gameplay {
		state  = .Load_Level,
		player = new_player_state(),
	}
	seed_gameplay_random(gameplay, rand.uint64())
}

change_gameplay_state :: proc(gameplay: ^Gameplay, next_state: Gameplay_State) {
	gameplay.state = next_state
}

// update_gameplay performs one non-blocking frame update. Playing-state logic
// advances through the fixed-step accumulator; screen transitions remain
// immediate so menu/back input is responsive at any render rate.
update_gameplay :: proc(
	gameplay: ^Gameplay,
	input: Game_Input,
	frame_seconds: f64,
) -> Gameplay_Frame_Result {
	result: Gameplay_Frame_Result
	if input.back {
		result.back_requested = true
		return result
	}

	switch gameplay.state {
	case .Load_Level:
		if load_level(&gameplay.level, gameplay.level_index) {
			if runtime_error := initialize_level_runtime(gameplay); runtime_error == .None {
				gameplay.theme = Tile_Theme(gameplay_random_max(gameplay, len(Tile_Theme)))
				change_gameplay_state(gameplay, .Playing)
			} else {
				fmt.eprintln("Failed to initialize level runtime:", runtime_error)
				change_gameplay_state(gameplay, .Load_Failed)
			}
		} else {
			change_gameplay_state(gameplay, .Load_Failed)
		}

	case .Playing:
		buffer_gameplay_input(&gameplay.simulation, input)
		result.simulation = advance_gameplay_simulation(gameplay, frame_seconds)
		// Level completion and retry/game-over transitions are introduced by the
		// next milestone; the fixed simulation owns active gameplay state.

	case .Dead:
		if input.confirm {
			reset_player_for_level_start(&gameplay.player)
			change_gameplay_state(gameplay, .Load_Level)
		}

	case .Won:
		if input.confirm {
			reset_player_for_level_start(&gameplay.player)
			gameplay.level_index = (gameplay.level_index + 1) % LEVEL_COUNT
			change_gameplay_state(gameplay, .Load_Level)
		}

	case .Load_Failed:
		if input.confirm do change_gameplay_state(gameplay, .Load_Level)
	}

	return result
}

draw_gameplay :: proc(gameplay: ^Gameplay, assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)

	// Draw the level, if applicable.
	switch gameplay.state {
	case .Playing, .Dead, .Won:
		draw_level_tiles(&gameplay.level, assets.tiles[gameplay.theme], &assets.sprites)
		draw_level_entities(gameplay, &assets.sprites)
		draw_gameplay_hud(gameplay, assets.sprites.tools)
	case .Load_Level, .Load_Failed:
	}

	// Draw the gameplay message on top of the level, if applicable.
	switch gameplay.state {
	case .Load_Level:
		draw_gameplay_message("Loading level...")
	case .Dead:
		draw_gameplay_message("You died - press Enter to retry")
	case .Won:
		draw_gameplay_message("Level complete - press Enter to continue")
	case .Load_Failed:
		draw_gameplay_message("Could not load level - Enter to retry, Esc for menu")
	case .Playing:
	}
}

draw_gameplay_message :: proc(message: cstring) {
	font_size: i32 = 20
	text_width := rl.MeasureText(message, font_size)
	text_x := (WINDOW_WIDTH - text_width) / 2
	text_y := WINDOW_HEIGHT / 2 - font_size / 2

	rl.DrawRectangle(text_x - 12, text_y - 8, text_width + 24, font_size + 16, rl.BLACK)
	rl.DrawText(message, text_x, text_y, font_size, rl.WHITE)
}
