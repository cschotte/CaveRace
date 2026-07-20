package caverace

import rl "vendor:raylib"

// draw_game dispatches the active screen renderer, then draws shared feedback
// overlays at the end of every render frame.
draw_game :: proc(game: ^Game, assets: ^Assets) {
	switch game.screen {
	case .Intro, .Main_Menu:
		draw_front_end(game.front_end, &assets.screens)
	case .Playing:
		draw_gameplay(&game.gameplay, assets)
	}
	if game.screen == .Playing && game.pause.open {
		draw_game_pause(&game.pause)
	}

	draw_game_feedback(game.feedback)
	when ODIN_DEBUG {
		if game.screen == .Playing && game.debug_overlay_visible {
			draw_debug_overlay(game)
		}
	}
}

pause_menu_item_label :: proc(item: Pause_Menu_Item) -> cstring {
	switch item {
	case .Resume:        return "RESUME"
	case .Restart_Level: return "RESTART LEVEL"
	case .Main_Menu:     return "MAIN MENU"
	}
	return ""
}

// draw_game_pause renders the keyboard/controller pause menu and destructive
// action confirmation without mutating gameplay.
draw_game_pause :: proc(pause: ^Pause_State) {
	panel_width: i32 = 430
	panel_height: i32 = 250
	panel_x := (WINDOW_WIDTH - panel_width) / 2
	panel_y := (WINDOW_HEIGHT - panel_height) / 2

	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Fade(rl.BLACK, 0.72))
	rl.DrawRectangle(panel_x, panel_y, panel_width, panel_height, rl.BLACK)
	rl.DrawRectangleLines(panel_x, panel_y, panel_width, panel_height, rl.GOLD)

	title: cstring = "PAUSED"
	title_size: i32 = 32
	title_width := rl.MeasureText(title, title_size)
	rl.DrawText(
		title,
		(WINDOW_WIDTH - title_width) / 2,
		panel_y + 20,
		title_size,
		rl.GOLD,
	)

	if pause.confirmation != .None {
		prompt: cstring = "RESTART THIS LEVEL?"
		if pause.confirmation == .Main_Menu {
			prompt = "ABANDON RUN FOR MAIN MENU?"
		}
		prompt_width := rl.MeasureText(prompt, 18)
		rl.DrawText(prompt, (WINDOW_WIDTH - prompt_width) / 2, panel_y + 92, 18, rl.WHITE)
		confirm: cstring = "ENTER / A: CONFIRM    ESC / B: CANCEL"
		confirm_width := rl.MeasureText(confirm, 14)
		rl.DrawText(confirm, (WINDOW_WIDTH - confirm_width) / 2, panel_y + 142, 14, rl.GOLD)
		return
	}

	for item_index in 0 ..< len(Pause_Menu_Item) {
		item := Pause_Menu_Item(item_index)
		label := pause_menu_item_label(item)
		color := rl.WHITE
		prefix: cstring = "  "
		if pause.selected == item {
			color = rl.GOLD
			prefix = "> "
		}
		y := panel_y + 78 + i32(item_index) * 38
		rl.DrawText(prefix, panel_x + 100, y, 20, color)
		rl.DrawText(label, panel_x + 130, y, 20, color)
	}
	footer: cstring = "ARROWS / DPAD  ENTER / A  P / START"
	footer_width := rl.MeasureText(footer, 13)
	rl.DrawText(footer, (WINDOW_WIDTH - footer_width) / 2, panel_y + 214, 13, rl.LIGHTGRAY)
}

// draw_front_end displays the story, title, or controls image selected by the
// platform-independent front-end state.
draw_front_end :: proc(front_end: Front_End_State, screens: ^Screen_Assets) {
	image_index, alpha := front_end_visual(front_end)
	assert(image_index >= 0 && image_index < FRONT_END_IMAGE_COUNT)
	rl.DrawTexture(screens.front_end[image_index], 0, 0, rl.Fade(rl.WHITE, alpha))
}

// draw_gameplay renders terminal screens directly; otherwise it draws the
// active level when available and overlays its lifecycle message.
draw_gameplay :: proc(gameplay: ^Gameplay, assets: ^Assets) {
	if gameplay.state == .Game_Over {
		rl.DrawTexture(assets.screens.game_over, 0, 0, rl.WHITE)
		draw_gameplay_message("Press R for a new run, any other key for menu")
		return
	}
	if gameplay.state == .Game_Won {
		rl.DrawTexture(assets.screens.you_won, 0, 0, rl.WHITE)
		return
	}

	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)

	switch gameplay.state {
	case .Playing, .Dead, .Won:
		draw_level_tiles(&gameplay.level, assets.tiles[gameplay.theme], &assets.sprites)
		draw_level_entities(gameplay, &assets.sprites)
		draw_gameplay_hud(gameplay, assets.sprites.tools)
	case .Load_Level, .Game_Won, .Game_Over, .Load_Failed:
	}

	switch gameplay.state {
	case .Load_Level:
		draw_gameplay_message("Loading level...")
	case .Dead:
		draw_gameplay_message("You died - press Enter or R to retry")
	case .Won:
		draw_gameplay_message("Level complete - press Enter to continue")
	case .Game_Won, .Game_Over:
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
