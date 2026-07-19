package caverace

import "core:strconv"
import rl "vendor:raylib"

MOUSE_POINTER_TILE_INDEX :: 4

// draw_game dispatches the active screen renderer, then draws shared pointer
// and feedback overlays at the end of every render frame.
draw_game :: proc(game: ^Game, assets: ^Assets, mouse: Mouse_State) {
	switch game.screen {
	case .Menu:
		draw_menu(game.menu, assets.screens.menu, assets.screens.select)
	case .Playing:
		draw_gameplay(&game.gameplay, assets)
	case .High_Scores:
		draw_high_scores(&game.high_scores, assets.screens.highscore)
	}

	draw_mouse(mouse, assets.sprites.tools)
	draw_game_feedback(game.feedback)
}

// draw_menu renders the static menu background and current animated selection
// when the application is on the Menu screen.
draw_menu :: proc(menu: Menu_State, background, selection: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)

	visual_item, visual_alpha := menu_selection_visual(menu)
	menu_selection_y := MENU_SELECTION_Y + i32(visual_item) * MENU_SELECTION_STEP
	rl.DrawTexture(
		selection,
		MENU_SELECTION_X,
		menu_selection_y,
		rl.Fade(rl.WHITE, visual_alpha),
	)
}

// draw_gameplay renders the active level when available and overlays the
// lifecycle message appropriate to the current gameplay state.
draw_gameplay :: proc(gameplay: ^Gameplay, assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)

	switch gameplay.state {
	case .Playing, .Dead, .Won, .Game_Over:
		draw_level_tiles(&gameplay.level, assets.tiles[gameplay.theme], &assets.sprites)
		draw_level_entities(gameplay, &assets.sprites)
		draw_gameplay_hud(gameplay, assets.sprites.tools)
	case .Load_Level, .Load_Failed:
	}

	switch gameplay.state {
	case .Load_Level:
		draw_gameplay_message("Loading level...")
	case .Dead:
		draw_gameplay_message("You died - press Enter to retry")
	case .Won:
		draw_gameplay_message("Level complete - press Enter to continue")
	case .Game_Over:
		draw_gameplay_message("Game over")
	case .Load_Failed:
		draw_gameplay_message("Could not load level - Enter to retry, Esc for menu")
	case .Playing:
	}
}

// draw_gameplay_message centers a readable black-backed status prompt over the
// gameplay screen for loading, retry, win, and failure states.
draw_gameplay_message :: proc(message: cstring) {
	font_size: i32 = 20
	text_width := rl.MeasureText(message, font_size)
	text_x := (WINDOW_WIDTH - text_width) / 2
	text_y := WINDOW_HEIGHT / 2 - font_size / 2

	rl.DrawRectangle(text_x - 12, text_y - 8, text_width + 24, font_size + 16, rl.BLACK)
	rl.DrawText(message, text_x, text_y, font_size, rl.WHITE)
}

// draw_high_scores renders the persisted table and, when applicable, the
// fixed-buffer name-entry prompt on the High Scores screen.
draw_high_scores :: proc(state: ^High_Score_State, background: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)
	rl.DrawText("NAME", HIGH_SCORE_HEADER_X, HIGH_SCORE_HEADER_Y, HIGH_SCORE_HEADER_SIZE, rl.BLACK)
	rl.DrawText("SCORE", HIGH_SCORE_SCORE_X, HIGH_SCORE_HEADER_Y, HIGH_SCORE_HEADER_SIZE, rl.BLACK)

	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		entry := &state.table.entries[entry_index]
		row_y := HIGH_SCORE_FIRST_ROW_Y + entry_index * HIGH_SCORE_ROW_STEP
		name_text := cstring(raw_data(entry.name.bytes[:]))
		rl.DrawText(name_text, HIGH_SCORE_HEADER_X, i32(row_y), HIGH_SCORE_FONT_SIZE, rl.BLACK)

		score_buffer: [32]byte
		score_text := strconv.write_uint(score_buffer[:len(score_buffer) - 1], entry.score, 10)
		rl.DrawText(
			cstring(raw_data(score_text)),
			HIGH_SCORE_SCORE_X,
			i32(row_y),
			HIGH_SCORE_FONT_SIZE,
			rl.BLACK,
		)
	}

	if state.mode == .Entering_Name {
		input_buffer: [HIGH_SCORE_NAME_CAPACITY + 1]u8
		copy(input_buffer[:], state.input_name.bytes[:state.input_name.length])
		input_buffer[state.input_name.length] = '_'
		rl.DrawText(
			"NEW HIGH SCORE - NAME:",
			HIGH_SCORE_HEADER_X,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)
		rl.DrawText(
			cstring(raw_data(input_buffer[:])),
			300,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)

		score_buffer: [32]byte
		score_text := strconv.write_uint(score_buffer[:len(score_buffer) - 1], state.pending_score, 10)
		rl.DrawText(
			cstring(raw_data(score_text)),
			HIGH_SCORE_INPUT_SCORE_X,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)
	}
}

// draw_mouse renders the custom legacy pointer after every screen so the native
// cursor can remain hidden for the application lifetime.
draw_mouse :: proc(mouse: Mouse_State, texture: rl.Texture) {
	tile_size := f32(texture.width)
	source := rl.Rectangle {
		x      = 0,
		y      = tile_size * MOUSE_POINTER_TILE_INDEX,
		width  = tile_size,
		height = tile_size,
	}
	position := rl.Vector2 {f32(mouse.x), f32(mouse.y)}
	rl.DrawTextureRec(texture, source, position, rl.WHITE)
}

// feedback_flash_color maps domain feedback kinds to raylib colors only at the
// rendering boundary.
feedback_flash_color :: proc(flash: Feedback_Flash) -> rl.Color {
	switch flash {
	case .Damage:   return rl.RED
	case .Item:     return rl.GREEN
	case .Treasure: return rl.BLUE
	case .None:     return rl.BLANK
	}
	return rl.BLANK
}

// draw_game_feedback overlays transition and gameplay flashes after all screen
// content, using alphas computed by the non-rendering feedback logic.
draw_game_feedback :: proc(feedback: Game_Feedback) {
	if fade_alpha := transition_fade_alpha(feedback); fade_alpha > 0 {
		rl.DrawRectangle(
			0,
			0,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			rl.Fade(rl.BLACK, fade_alpha),
		)
	}
	if flash_alpha := feedback_flash_alpha(feedback); flash_alpha > 0 {
		rl.DrawRectangle(
			0,
			0,
			WINDOW_WIDTH,
			WINDOW_HEIGHT,
			rl.Fade(feedback_flash_color(feedback.flash), flash_alpha),
		)
	}
}
