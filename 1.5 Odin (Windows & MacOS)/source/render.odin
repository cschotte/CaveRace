package caverace

import "core:fmt"
import rl "vendor:raylib"

// draw_game dispatches the active screen renderer, then draws shared feedback
// overlays at the end of every render frame.
draw_game :: proc(game: ^Game, assets: ^Assets) {
	switch game.screen {
	case .Intro:
		draw_front_end(game.front_end, &assets.screens)
		draw_story_prompt(game)
	case .Main_Menu:
		background := assets.screens.front_end[MAIN_MENU_FIRST_IMAGE]
		if game.menu.page == .Records do background = assets.screens.score
		rl.DrawTexture(background, 0, 0, rl.WHITE)
		draw_main_menu(game)
	case .Tutorial:
		draw_gameplay(game, assets)
		draw_tutorial_prompt(game)
	case .Playing:
		draw_gameplay(game, assets)
	}
	if game.screen == .Tutorial ||
	   (game.screen == .Playing &&
	    (game.gameplay.state == .Playing || game.gameplay.state == .Dead ||
	     game.gameplay.state == .Game_Won)) {
		draw_game_effects(&game.effects)
	}
	if (game.screen == .Playing || game.screen == .Tutorial) && game.pause.open {
		draw_game_pause(game)
	}

	draw_game_feedback(game.feedback)
	when ODIN_DEBUG {
		if (game.screen == .Playing || game.screen == .Tutorial) && game.debug_overlay_visible {
			draw_debug_overlay(game)
		}
	}
}

pause_menu_item_label :: proc(item: Pause_Menu_Item) -> cstring {
	switch item {
	case .Resume:        return "RESUME"
	case .Restart_Level: return "RESTART LEVEL"
	case .Settings:      return "SETTINGS"
	case .Controls:      return "CONTROLS"
	case .Main_Menu:     return "MAIN MENU"
	}
	return ""
}

// draw_game_pause renders the keyboard/controller pause menu and destructive
// action confirmation without mutating gameplay.
draw_game_pause :: proc(game: ^Game) {
	pause := &game.pause
	if pause.page == .Settings {
		draw_settings_menu(game)
		return
	}
	if pause.page == .Controls {
		draw_bindings_menu(game)
		return
	}
	panel_width: i32 = 430
	panel_height: i32 = 320
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
		confirm_buffer: [128]byte
		confirm: cstring
		if game.last_input_device == .Keyboard {
			formatted := fmt.bprintf(
				confirm_buffer[:len(confirm_buffer) - 1],
				"%s: CONFIRM    ESC: CANCEL",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
			confirm_buffer[len(formatted)] = 0
			confirm = cstring(raw_data(confirm_buffer[:]))
		} else {
			formatted := fmt.bprintf(
				confirm_buffer[:len(confirm_buffer) - 1],
				"%s: CONFIRM    B: CANCEL",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
			confirm_buffer[len(formatted)] = 0
			confirm = cstring(raw_data(confirm_buffer[:]))
		}
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
		y := panel_y + 72 + i32(item_index) * 38
		rl.DrawText(prefix, panel_x + 100, y, 20, color)
		rl.DrawText(label, panel_x + 130, y, 20, color)
	}
	footer_buffer: [160]byte
	footer: cstring
	if game.last_input_device == .Keyboard {
		formatted := fmt.bprintf(
			footer_buffer[:len(footer_buffer) - 1],
			"ARROWS / %s/%s/%s/%s    %s SELECT    %s PAUSE",
			keyboard_key_label(game.settings.bindings[.Move_Up]),
			keyboard_key_label(game.settings.bindings[.Move_Left]),
			keyboard_key_label(game.settings.bindings[.Move_Down]),
			keyboard_key_label(game.settings.bindings[.Move_Right]),
			action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			action_prompt(.Pause, .Keyboard, game.settings.bindings),
		)
		footer_buffer[len(formatted)] = 0
		footer = cstring(raw_data(footer_buffer[:]))
	} else {
		formatted := fmt.bprintf(
			footer_buffer[:len(footer_buffer) - 1],
			"LEFT STICK / MOVE BUTTONS    %s SELECT    %s PAUSE",
			action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			action_prompt(.Pause, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
		footer_buffer[len(formatted)] = 0
		footer = cstring(raw_data(footer_buffer[:]))
	}
	footer_width := rl.MeasureText(footer, 13)
	rl.DrawText(footer, (WINDOW_WIDTH - footer_width) / 2, panel_y + 286, 13, rl.LIGHTGRAY)
}

// draw_front_end displays the story, title, or controls image selected by the
// platform-independent front-end state.
draw_front_end :: proc(front_end: Front_End_State, screens: ^Screen_Assets) {
	image_index, alpha := front_end_visual(front_end)
	assert(image_index >= 0 && image_index < FRONT_END_IMAGE_COUNT)
	rl.DrawTexture(screens.front_end[image_index], 0, 0, rl.Fade(rl.WHITE, alpha))
}

main_menu_item_label :: proc(item: Main_Menu_Item) -> cstring {
	switch item {
	case .Start_Game:   return "START GAME"
	case .Practice:     return "PRACTICE / LEVEL SELECT"
	case .Records:      return "RECORDS"
	case .Tutorial:     return "TUTORIAL"
	case .How_To_Play:  return "HOW TO PLAY"
	case .Settings:     return "SETTINGS"
	case .Replay_Story: return "REPLAY STORY"
	case .Quit:         return "QUIT"
	}
	return ""
}

draw_duration :: proc(x, y, size: i32, color: rl.Color, ticks: int) {
	if ticks <= 0 {
		rl.DrawText("--:--.-", x, y, size, color)
		return
	}
	total_seconds := ticks / GAMEPLAY_TICK_HZ
	tenths := (ticks % GAMEPLAY_TICK_HZ) * 10 / GAMEPLAY_TICK_HZ
	draw_ui_format(x, y, size, color, "%02d:%02d.%d", total_seconds / 60, total_seconds % 60, tenths)
}

first_run_item_label :: proc(item: First_Run_Item) -> cstring {
	switch item {
	case .Tutorial: return "TUTORIAL (RECOMMENDED)"
	case .Campaign: return "START CAMPAIGN"
	case .Back:     return "BACK"
	}
	return ""
}

draw_ui_format :: proc(x, y, size: i32, color: rl.Color, format: string, args: ..any) {
	buffer: [256]byte
	formatted := fmt.bprintf(buffer[:len(buffer) - 1], format, ..args)
	buffer[len(formatted)] = 0
	rl.DrawText(cstring(raw_data(buffer[:])), x, y, size, color)
}

draw_menu_row :: proc(label: cstring, index, selected, y: int) {
	color := rl.LIGHTGRAY
	prefix: cstring = "  "
	if index == selected {
		color = rl.GOLD
		prefix = "> "
	}
	rl.DrawText(prefix, 177, i32(y), 18, color)
	rl.DrawText(label, 203, i32(y), 18, color)
}

draw_menu_panel :: proc(title: cstring, height: i32 = 310) {
	panel_x: i32 = 80
	panel_y: i32 = 58
	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Fade(rl.BLACK, 0.34))
	rl.DrawRectangle(panel_x, panel_y, 480, height, rl.Fade(rl.BLACK, 0.92))
	rl.DrawRectangleLines(panel_x, panel_y, 480, height, rl.GOLD)
	title_width := rl.MeasureText(title, 24)
	rl.DrawText(title, (WINDOW_WIDTH - title_width) / 2, panel_y + 14, 24, rl.GOLD)
}

draw_device_footer :: proc(game: ^Game, text_y: i32 = 372) {
	buffer: [180]byte
	footer: cstring
	if game.last_input_device == .Keyboard {
		formatted := fmt.bprintf(
			buffer[:len(buffer) - 1],
			"ARROWS / %s/%s/%s/%s    %s: SELECT    ESC: BACK",
			keyboard_key_label(game.settings.bindings[.Move_Up]),
			keyboard_key_label(game.settings.bindings[.Move_Left]),
			keyboard_key_label(game.settings.bindings[.Move_Down]),
			keyboard_key_label(game.settings.bindings[.Move_Right]),
			action_prompt(.Confirm, .Keyboard, game.settings.bindings),
		)
		buffer[len(formatted)] = 0
		footer = cstring(raw_data(buffer[:]))
	} else {
		formatted := fmt.bprintf(
			buffer[:len(buffer) - 1],
			"LEFT STICK / MOVE BUTTONS    %s: SELECT    B: BACK",
			action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
		buffer[len(formatted)] = 0
		footer = cstring(raw_data(buffer[:]))
	}
	width := rl.MeasureText(footer, 14)
	rl.DrawText(footer, (WINDOW_WIDTH - width) / 2, text_y, 14, rl.LIGHTGRAY)
}

draw_settings_menu :: proc(game: ^Game) {
	draw_menu_panel("SETTINGS", 334)
	settings := &game.settings
	for item_index in 0 ..< len(Settings_Menu_Item) {
		item := Settings_Menu_Item(item_index)
		color := rl.LIGHTGRAY
		prefix: cstring = "  "
		if game.menu.selected == item_index {
			color = rl.GOLD
			prefix = "> "
		}
		y := i32(88 + item_index * 22)
		rl.DrawText(prefix, 163, y, 16, color)
		switch item {
		case .Music:              draw_ui_format(187, y, 16, color, "MUSIC                 %3d%%", settings.music_volume)
		case .Sfx:                draw_ui_format(187, y, 16, color, "SFX                   %3d%%", settings.sfx_volume)
		case .Display_Mode:
			mode: cstring = "WINDOWED"
			if settings.display_mode == .Borderless do mode = "BORDERLESS"
			draw_ui_format(187, y, 16, color, "DISPLAY        %s", mode)
		case .Window_Scale:       draw_ui_format(187, y, 16, color, "WINDOW SCALE            %dx", settings.window_scale)
		case .Reduced_Flashes:    draw_ui_format(187, y, 16, color, "REDUCED FLASHES        %s", "ON" if settings.reduced_flashes else "OFF")
		case .Screen_Shake:       draw_ui_format(187, y, 16, color, "SCREEN SHAKE          %3d%%", settings.screen_shake)
		case .Controller_Rumble:  draw_ui_format(187, y, 16, color, "CONTROLLER RUMBLE      %s", "ON" if settings.controller_rumble else "OFF")
		case .High_Contrast:      draw_ui_format(187, y, 16, color, "DANGER HATCHING        %s", "ON" if settings.high_contrast_preview else "OFF")
		case .Pause_On_Focus_Loss: draw_ui_format(187, y, 16, color, "FOCUS PAUSE             %s", "ON" if settings.pause_on_focus_loss else "OFF")
		case .Difficulty:         draw_ui_format(187, y, 16, color, "DIFFICULTY       %s", difficulty_label(settings.difficulty))
		case .Bindings:           rl.DrawText("REMAP CONTROLS", 187, y, 16, color)
		case .Back:               rl.DrawText("BACK", 187, y, 16, color)
		}
	}
	draw_device_footer(game, 378)
}

draw_bindings_menu :: proc(game: ^Game) {
	title: cstring = "KEYBOARD BINDINGS"
	if game.menu.binding_device == .Controller do title = "CONTROLLER BINDINGS"
	draw_menu_panel(title, 328)
	for action_index in 0 ..< len(Input_Action) {
		action := Input_Action(action_index)
		color := rl.LIGHTGRAY
		prefix: cstring = "  "
		if game.menu.selected == action_index {
			color = rl.GOLD
			prefix = "> "
		}
		y := i32(92 + action_index * 29)
		rl.DrawText(prefix, 167, y, 16, color)
		if game.menu.binding_device == .Keyboard {
			draw_ui_format(191, y, 16, color, "%-14s %s", input_action_label(action), keyboard_key_label(game.settings.bindings[action]))
		} else {
			draw_ui_format(191, y, 16, color, "%-14s %s", input_action_label(action), controller_action_label(action, game.settings.controller_bindings))
		}
	}
	draw_menu_row("BACK", len(Input_Action), game.menu.selected, 92 + len(Input_Action) * 29)
	if game.menu.binding_waiting {
		rl.DrawRectangle(153, 164, 334, 70, rl.BLACK)
		rl.DrawRectangleLines(153, 164, 334, 70, rl.GOLD)
		waiting := "PRESS A KEY FOR %s"
		if game.menu.binding_device == .Controller do waiting = "PRESS A BUTTON FOR %s"
		draw_ui_format(174, 180, 18, rl.WHITE, waiting, input_action_label(game.menu.binding_action))
		rl.DrawText("ESC CANCELS", 254, 210, 14, rl.LIGHTGRAY)
	} else if game.menu.binding_conflict_seconds > 0 {
		rl.DrawText("KEY ALREADY USED", 236, 342, 16, rl.RED)
	}
	rl.DrawText("LEFT / RIGHT: SWITCH DEVICE", 203, 365, 14, rl.LIGHTGRAY)
}

draw_how_to_play :: proc(game: ^Game) {
	draw_menu_panel("HOW TO PLAY", 324)
	if game.menu.help_page == 0 {
		if game.last_input_device == .Controller {
			draw_ui_format(150, 95, 16, rl.WHITE, "MOVE U/D   %s / %s + LEFT STICK", controller_action_label(.Move_Up, game.settings.controller_bindings), controller_action_label(.Move_Down, game.settings.controller_bindings))
			draw_ui_format(150, 123, 16, rl.WHITE, "MOVE L/R   %s / %s + LEFT STICK", controller_action_label(.Move_Left, game.settings.controller_bindings), controller_action_label(.Move_Right, game.settings.controller_bindings))
			draw_ui_format(150, 157, 17, rl.WHITE, "BOMB       %s", action_prompt(.Bomb, .Controller, game.settings.bindings, &game.settings.controller_bindings))
			draw_ui_format(150, 189, 17, rl.WHITE, "PAUSE      %s", action_prompt(.Pause, .Controller, game.settings.bindings, &game.settings.controller_bindings))
			draw_ui_format(150, 221, 17, rl.WHITE, "RETRY      %s", action_prompt(.Restart, .Controller, game.settings.bindings, &game.settings.controller_bindings))
			rl.DrawText("BACK       B", 150, 253, 17, rl.WHITE)
		} else {
			draw_ui_format(165, 105, 16, rl.WHITE, "MOVE UP/DOWN     %s / %s", keyboard_key_label(game.settings.bindings[.Move_Up]), keyboard_key_label(game.settings.bindings[.Move_Down]))
			draw_ui_format(165, 135, 16, rl.WHITE, "MOVE LEFT/RIGHT  %s / %s", keyboard_key_label(game.settings.bindings[.Move_Left]), keyboard_key_label(game.settings.bindings[.Move_Right]))
			draw_ui_format(165, 165, 16, rl.WHITE, "BOMB             %s", action_prompt(.Bomb, .Keyboard, game.settings.bindings))
			draw_ui_format(165, 195, 16, rl.WHITE, "PAUSE            %s", action_prompt(.Pause, .Keyboard, game.settings.bindings))
			draw_ui_format(165, 225, 16, rl.WHITE, "RETRY            %s", action_prompt(.Restart, .Keyboard, game.settings.bindings))
			rl.DrawText("ARROW KEYS ALSO MOVE. ESC GOES BACK.", 165, 262, 14, rl.GOLD)
		}
		rl.DrawText("PAGE 1/2", 284, 326, 14, rl.LIGHTGRAY)
	} else {
		rl.DrawText("DRIVE OUT EVERY ALIEN TO CLEAR A CAVE.", 130, 92, 16, rl.WHITE)
		rl.DrawText("TREASURE IS OPTIONAL AND ADDS SCORE.", 130, 116, 16, rl.WHITE)
		rl.DrawText("HUD: ALIENS / TREASURE / LIFE / ENERGY / BOMBS.", 130, 147, 15, rl.GOLD)
		rl.DrawText("POWER EXTENDS BLASTS; BOMB ITEMS ADD CAPACITY.", 130, 172, 15, rl.WHITE)
		rl.DrawText("ENERGY AND LIFE ITEMS RESTORE SURVIVAL.", 130, 197, 15, rl.WHITE)
		rl.DrawText("BOMBS CROSS OBSTACLES. LEAVE THE MARKED BLAST.", 130, 228, 15, rl.WHITE)
		rl.DrawText("STANDARD IS LETHAL. ASSISTED: -1 CONTACT,", 130, 253, 15, rl.WHITE)
		rl.DrawText("-4 BLAST, LONGER WARNING; SAME CONTENT.", 130, 278, 15, rl.WHITE)
		rl.DrawText("PAGE 2/2", 284, 326, 14, rl.LIGHTGRAY)
	}
	draw_device_footer(game, 374)
}

draw_level_select :: proc(game: ^Game) {
	draw_menu_panel("PRACTICE / LEVEL SELECT", 320)
	record := record_for_profile(&game.settings.records, game.settings.difficulty)
	unlocked := unlocked_level_count(record)
	for level_index in 0 ..< unlocked {
		color := rl.LIGHTGRAY
		prefix: cstring = "  "
		if game.menu.selected == level_index {
			color = rl.GOLD
			prefix = "> "
		}
		y := i32(88 + level_index * 23)
		rl.DrawText(prefix, 112, y, 15, color)
		metadata := level_metadata(level_index)
		draw_ui_format(136, y, 15, color, "%-8s  %-6s", metadata.name, medal_label(record.levels[level_index].best_medal))
		draw_duration(385, y, 15, color, record.levels[level_index].best_time_ticks)
	}
	draw_menu_row("BACK", unlocked, game.menu.selected, 88 + unlocked * 23)
	draw_ui_format(148, 346, 13, rl.GOLD, "%s PROFILE - PRACTICE NEVER CHANGES RECORDS", difficulty_label(game.settings.difficulty))
	draw_device_footer(game, 378)
}

draw_records :: proc(game: ^Game) {
	record := record_for_profile(&game.settings.records, game.settings.difficulty)
	if game.menu.records_page == 0 {
		draw_ui_format(157, 116, 15, rl.BLACK, "TOP RUN SCORES - %s", difficulty_label(game.settings.difficulty))
		if record.run_score_count == 0 {
			rl.DrawText("NO CAMPAIGN RUNS YET", 217, 178, 16, rl.BLACK)
		} else {
			for index in 0 ..< MAX_RUN_RECORDS {
				y := i32(143 + index * 19)
				if index < record.run_score_count {
					draw_ui_format(211, y, 16, rl.BLACK, "%2d.  %08d", index + 1, record.run_scores[index])
				} else {
					draw_ui_format(211, y, 16, rl.DARKBROWN, "%2d.  --------", index + 1)
				}
			}
		}
		rl.DrawText("PAGE 1/2", 288, 339, 13, rl.DARKBROWN)
	} else {
		draw_ui_format(175, 116, 15, rl.BLACK, "CAVE BESTS - %s", difficulty_label(game.settings.difficulty))
		for level_index in 0 ..< LEVEL_COUNT {
			y := i32(143 + level_index * 19)
			level_record := record.levels[level_index]
			draw_ui_format(173, y, 15, rl.BLACK, "%2d  %-6s", level_index + 1, medal_label(level_record.best_medal))
			draw_duration(376, y, 15, rl.BLACK, level_record.best_time_ticks)
		}
		rl.DrawText("PAGE 2/2", 288, 339, 13, rl.DARKBROWN)
	}
	rl.DrawText("LEFT / RIGHT / CONFIRM: PAGE", 205, 358, 13, rl.GOLD)
	draw_device_footer(game, 378)
}

draw_story_prompt :: proc(game: ^Game) {
	buffer: [160]byte
	prompt: cstring
	if game.last_input_device == .Controller {
		formatted := fmt.bprintf(
			buffer[:len(buffer) - 1],
			"%s: NEXT     B: SKIP STORY",
			action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
		buffer[len(formatted)] = 0
		prompt = cstring(raw_data(buffer[:]))
	} else {
		formatted := fmt.bprintf(
			buffer[:len(buffer) - 1],
			"%s / %s: NEXT     ESC: SKIP STORY",
			action_prompt(.Bomb, .Keyboard, game.settings.bindings),
			action_prompt(.Confirm, .Keyboard, game.settings.bindings),
		)
		buffer[len(formatted)] = 0
		prompt = cstring(raw_data(buffer[:]))
	}
	width := rl.MeasureText(prompt, 14)
	rl.DrawRectangle((WINDOW_WIDTH - width) / 2 - 8, 370, width + 16, 22, rl.Fade(rl.BLACK, 0.82))
	rl.DrawText(prompt, (WINDOW_WIDTH - width) / 2, 373, 14, rl.GOLD)
}

draw_main_menu :: proc(game: ^Game) {
	switch game.menu.page {
	case .Settings:    draw_settings_menu(game)
	case .Bindings:    draw_bindings_menu(game)
	case .How_To_Play: draw_how_to_play(game)
	case .Level_Select: draw_level_select(game)
	case .Records:      draw_records(game)
	case .Main:
		draw_menu_panel("CAVERACE", 320)
		for item_index in 0 ..< len(Main_Menu_Item) {
			draw_menu_row(main_menu_item_label(Main_Menu_Item(item_index)), item_index, game.menu.selected, 82 + item_index * 31)
		}
		draw_ui_format(175, 337, 14, rl.GOLD, "MODE: %s", difficulty_label(game.settings.difficulty))
		draw_device_footer(game, 378)
	case .First_Run:
		draw_menu_panel("CHOOSE YOUR START", 254)
		rl.DrawText("LEARN MOVEMENT, BOMBS, PICKUPS AND SAFETY.", 161, 101, 14, rl.WHITE)
		for item_index in 0 ..< len(First_Run_Item) {
			draw_menu_row(first_run_item_label(First_Run_Item(item_index)), item_index, game.menu.selected, 145 + item_index * 42)
		}
		draw_ui_format(172, 292, 14, rl.GOLD, "RULES: %s", difficulty_label(game.settings.difficulty))
		draw_device_footer(game)
	}
}

draw_level_result :: proc(game: ^Game) {
	result := &game.gameplay.level_result
	rl.DrawRectangle(38, 26, 564, 342, rl.Fade(rl.BLACK, 0.96))
	rl.DrawRectangleLines(38, 26, 564, 342, rl.GOLD)
	draw_ui_format(216, 40, 23, rl.GOLD, "CAVE %d COMPLETE", result.level_index + 1)
	draw_ui_format(72, 73, 15, rl.WHITE, "TIME")
	draw_duration(135, 73, 15, rl.WHITE, result.elapsed_ticks)
	draw_ui_format(233, 73, 15, rl.LIGHTGRAY, "PAR")
	draw_duration(276, 73, 15, rl.LIGHTGRAY, result.par_ticks)
	draw_ui_format(402, 73, 15, rl.WHITE, "TREASURE %d/%d", result.treasure_collected, result.treasure_total)
	draw_ui_format(72, 96, 14, rl.LIGHTGRAY, "HITS %d   DAMAGE %d   DEATHS %d", result.hits, result.damage_taken, result.deaths)

	draw_ui_format(72, 126, 14, rl.WHITE, "ALIENS             %3d x %3d     +%4d", result.enemies_destroyed, gameplay_tuning(game.gameplay.difficulty).score_enemy_destroyed, result.enemy_points)
	draw_ui_format(72, 147, 14, rl.WHITE, "TREASURE           %3d x %3d     +%4d", result.treasure_pickups, gameplay_tuning(game.gameplay.difficulty).score_treasure_pickup, result.treasure_points)
	draw_ui_format(72, 168, 14, rl.WHITE, "ITEMS              %3d x %3d     +%4d", result.items_collected, gameplay_tuning(game.gameplay.difficulty).score_item_pickup, result.item_points)
	draw_ui_format(72, 189, 14, rl.WHITE, "SALVAGED ITEMS     %3d x %3d     +%4d", result.items_salvaged, gameplay_tuning(game.gameplay.difficulty).score_capped_item_salvage, result.salvage_points)
	draw_ui_format(72, 210, 14, rl.WHITE, "CAVE CLEAR                         +%4d", result.clear_bonus)
	draw_ui_format(72, 231, 14, rl.WHITE, "ALL TREASURE                       +%4d", result.all_treasure_bonus)
	draw_ui_format(72, 252, 14, rl.WHITE, "NO DAMAGE                          +%4d", result.no_damage_bonus)
	draw_ui_format(72, 273, 14, rl.WHITE, "UNDER PAR                          +%4d", result.par_bonus)
	if result.score_adjustment != 0 {
		draw_ui_format(72, 294, 13, rl.RED, "SCORE ADJUSTMENT                    %+d", result.score_adjustment)
	}
	draw_ui_format(72, 314, 16, rl.GOLD, "TOTAL +%d     SCORE %08d     MEDAL %s", result.score_delta, result.final_score, medal_label(result.medal))
	if result.new_best_time || result.new_best_medal {
		rl.DrawText("NEW CAVE RECORD", 426, 334, 13, rl.GREEN)
	}
	footer: cstring = "CONTINUE"
	if game.gameplay.mode == .Practice do footer = "RETURN TO MENU"
	draw_ui_format(72, 348, 13, rl.LIGHTGRAY, "%s: %s", action_prompt(.Confirm, game.last_input_device, game.settings.bindings, &game.settings.controller_bindings), footer)
}

draw_tutorial_prompt :: proc(game: ^Game) {
	rl.DrawRectangle(92, 312, 456, 42, rl.Fade(rl.BLACK, 0.9))
	rl.DrawRectangleLines(92, 312, 456, 42, rl.GOLD)
	instruction := tutorial_instruction(game.tutorial.step)
	width := rl.MeasureText(instruction, 16)
	rl.DrawText(instruction, (WINDOW_WIDTH - width) / 2, 318, 16, rl.WHITE)
	footer_buffer: [128]byte
	footer: cstring
	if game.last_input_device == .Keyboard {
		formatted := fmt.bprintf(
			footer_buffer[:len(footer_buffer) - 1],
			"ESC: SKIP     %s: PAUSE",
			action_prompt(.Pause, .Keyboard, game.settings.bindings),
		)
		footer_buffer[len(formatted)] = 0
		footer = cstring(raw_data(footer_buffer[:]))
	} else {
		formatted := fmt.bprintf(
			footer_buffer[:len(footer_buffer) - 1],
			"B: SKIP     %s: PAUSE",
			action_prompt(.Pause, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
		footer_buffer[len(formatted)] = 0
		footer = cstring(raw_data(footer_buffer[:]))
	}
	if game.tutorial.step == .Complete {
		if game.last_input_device == .Keyboard {
			formatted := fmt.bprintf(
				footer_buffer[:len(footer_buffer) - 1],
				"%s: START CAMPAIGN",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
			footer_buffer[len(formatted)] = 0
			footer = cstring(raw_data(footer_buffer[:]))
		} else {
			formatted := fmt.bprintf(
				footer_buffer[:len(footer_buffer) - 1],
				"%s: START CAMPAIGN",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
			footer_buffer[len(formatted)] = 0
			footer = cstring(raw_data(footer_buffer[:]))
		}
	}
	footer_width := rl.MeasureText(footer, 13)
	rl.DrawText(footer, (WINDOW_WIDTH - footer_width) / 2, 337, 13, rl.GOLD)
}

// draw_gameplay renders terminal screens directly; otherwise it draws the
// active level when available and overlays its lifecycle message.
draw_gameplay :: proc(game: ^Game, assets: ^Assets) {
	gameplay := &game.gameplay
	if gameplay.state == .Game_Over {
		rl.DrawTexture(assets.screens.game_over, 0, 0, rl.WHITE)
		if game.last_input_device == .Controller {
			draw_gameplay_message_format(
				"%s: NEW RUN     %s: MAIN MENU",
				action_prompt(.Restart, .Controller, game.settings.bindings, &game.settings.controller_bindings),
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		} else {
			draw_gameplay_message_format(
				"%s: NEW RUN     %s: MAIN MENU",
				action_prompt(.Restart, .Keyboard, game.settings.bindings),
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
		}
		return
	}
	if gameplay.state == .Game_Won {
		rl.DrawTexture(assets.screens.you_won, 0, 0, rl.WHITE)
		if game.last_input_device == .Controller {
			draw_gameplay_message_format(
				"%s: MAIN MENU",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		} else {
			draw_gameplay_message_format(
				"%s: MAIN MENU",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
		}
		return
	}

	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)

	switch gameplay.state {
	case .Playing, .Dead, .Won:
		draw_level_tiles(&gameplay.level, assets.tiles[gameplay.theme], &assets.sprites)
		draw_level_entities(
			gameplay,
			&assets.sprites,
			game.settings.high_contrast_preview,
		)
		draw_gameplay_hud(gameplay, assets.sprites.tools)
	case .Load_Level, .Game_Won, .Game_Over, .Load_Failed:
	}

	switch gameplay.state {
	case .Load_Level:
		draw_gameplay_message("Loading level...")
	case .Dead:
		if game.last_input_device == .Controller {
			draw_gameplay_message_format(
				"YOU DIED - %s OR %s TO RETRY, B FOR MENU",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
				action_prompt(.Restart, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		} else {
			draw_gameplay_message_format(
				"YOU DIED - %s OR %s TO RETRY, ESC FOR MENU",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
				action_prompt(.Restart, .Keyboard, game.settings.bindings),
			)
		}
	case .Won:
		draw_level_result(game)
	case .Game_Won, .Game_Over:
	case .Load_Failed:
		if game.last_input_device == .Controller {
			draw_gameplay_message_format(
				"LOAD FAILED - %s TO RETRY, B FOR MENU",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		} else {
			draw_gameplay_message_format(
				"LOAD FAILED - %s TO RETRY, ESC FOR MENU",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
		}
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

draw_gameplay_message_format :: proc(format: string, args: ..any) {
	buffer: [256]byte
	formatted := fmt.bprintf(buffer[:len(buffer) - 1], format, ..args)
	buffer[len(formatted)] = 0
	draw_gameplay_message(cstring(raw_data(buffer[:])))
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
