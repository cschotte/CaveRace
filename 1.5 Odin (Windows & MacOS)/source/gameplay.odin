package caverace

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
	state:       Gameplay_State,
	level:       Level,
	level_index: int,
	theme:       Tile_Theme,
}

init_gameplay :: proc(gameplay: ^Gameplay) {
	gameplay^ = Gameplay {
		state = .Load_Level,
	}
}

change_gameplay_state :: proc(gameplay: ^Gameplay, next_state: Gameplay_State) {
	gameplay.state = next_state
}

// update_gameplay performs one non-blocking update per application frame. The
// application loop remains responsible for platform events, drawing, and audio.
update_gameplay :: proc(gameplay: ^Gameplay, input: Game_Input) -> (back_requested: bool) {
	if input.back do return true

	switch gameplay.state {
	case .Load_Level:
		if load_level(&gameplay.level, gameplay.level_index) {
			gameplay.theme = Tile_Theme(rand.int_max(len(Tile_Theme)))
			change_gameplay_state(gameplay, .Playing)
		} else {
			change_gameplay_state(gameplay, .Load_Failed)
		}

	case .Playing:
		// Player, enemy, bomb, collision, and win-condition updates belong here.

	case .Dead:
		if input.confirm do change_gameplay_state(gameplay, .Load_Level)

	case .Won:
		if input.confirm {
			gameplay.level_index = (gameplay.level_index + 1) % LEVEL_COUNT
			change_gameplay_state(gameplay, .Load_Level)
		}

	case .Load_Failed:
		if input.confirm do change_gameplay_state(gameplay, .Load_Level)
	}

	return false
}

draw_gameplay :: proc(gameplay: ^Gameplay, assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)

	// Draw the level, if applicable.
	switch gameplay.state {
	case .Playing, .Dead, .Won:
		draw_level(&gameplay.level, assets.tiles[gameplay.theme], &assets.sprites)
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
