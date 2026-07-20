package caverace

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

// draw_game dispatches the active screen renderer, then draws shared feedback
// overlays at the end of every render frame.
draw_game :: proc(game: ^Game, assets: ^Assets) {
	switch game.screen {
	case .Branding:
		rl.DrawTexture(assets.screens.branding, 0, 0, rl.WHITE)
	case .Intro:
		draw_front_end(game.front_end, &assets.screens)
		draw_story_effects(game.front_end, game.settings.reduced_flashes)
	case .Main_Menu:
		background_index := MAIN_MENU_FIRST_IMAGE
		if game.menu.page == .How_To_Play do background_index = MAIN_MENU_LAST_IMAGE
		rl.DrawTexture(assets.screens.front_end[background_index], 0, 0, rl.WHITE)
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
	ease := f32(clamp(game.pause.elapsed_seconds / 0.15, 0, 1))

	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Fade(rl.BLACK, 0.72 * ease))
	rl.DrawRectangle(panel_x, panel_y, panel_width, panel_height, rl.Fade(rl.BLACK, ease))
	rl.DrawRectangleLines(panel_x, panel_y, panel_width, panel_height, rl.Fade(rl.GOLD, ease))

	title: cstring = "PAUSED"
	title_size: i32 = 32
	title_width := rl.MeasureText(title, title_size)
	rl.DrawText(
		title,
		(WINDOW_WIDTH - title_width) / 2,
		panel_y + 20,
		title_size,
		rl.Fade(rl.GOLD, ease),
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
			confirm = format_cstring(
				confirm_buffer[:],
				"%s: CONFIRM    ESC: CANCEL",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
		} else {
			confirm = format_cstring(
				confirm_buffer[:],
				"%s: CONFIRM    B: CANCEL",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		}
		confirm_width := rl.MeasureText(confirm, 14)
		rl.DrawText(confirm, (WINDOW_WIDTH - confirm_width) / 2, panel_y + 142, 14, rl.GOLD)
		return
	}

	pulse := ui_pulse(game.ui_clock, 1.6)
	for item_index in 0 ..< len(Pause_Menu_Item) {
		item := Pause_Menu_Item(item_index)
		label := pause_menu_item_label(item)
		color := rl.WHITE
		prefix: cstring = "  "
		y := panel_y + 72 + i32(item_index) * 38
		if pause.selected == item {
			draw_selection_glow(panel_x + 90, y - 5, panel_width - 80, 30, pulse * ease)
			color = rl.GOLD
			prefix = "> "
		}
		rl.DrawText(prefix, panel_x + 100, y, 20, rl.Fade(color, ease))
		rl.DrawText(label, panel_x + 130, y, 20, rl.Fade(color, ease))
	}
	footer_buffer: [160]byte
	footer: cstring
	if game.last_input_device == .Keyboard {
		footer = format_cstring(
			footer_buffer[:],
			"ARROWS / %s/%s/%s/%s    %s SELECT    %s PAUSE",
			keyboard_key_label(game.settings.bindings[.Move_Up]),
			keyboard_key_label(game.settings.bindings[.Move_Left]),
			keyboard_key_label(game.settings.bindings[.Move_Down]),
			keyboard_key_label(game.settings.bindings[.Move_Right]),
			action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			action_prompt(.Pause, .Keyboard, game.settings.bindings),
		)
	} else {
		footer = format_cstring(
			footer_buffer[:],
			"LEFT STICK / MOVE BUTTONS    %s SELECT    %s PAUSE",
			action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			action_prompt(.Pause, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
	}
	footer_width := rl.MeasureText(footer, 13)
	rl.DrawText(footer, (WINDOW_WIDTH - footer_width) / 2, panel_y + 286, 13, rl.Fade(rl.LIGHTGRAY, ease))
}

// draw_ken_burns_texture draws a full-canvas texture with a slow, subtle zoom
// and drift instead of a static blit, giving story and outcome screens a
// gentle sense of camera movement without any new gameplay-facing state.
draw_ken_burns_texture :: proc(texture: rl.Texture, zoom: f32, drift_right: bool, tint: rl.Color) {
	if zoom <= 0 || !rl.IsTextureValid(texture) {
		rl.DrawTexture(texture, 0, 0, tint)
		return
	}
	crop_width := f32(texture.width) * (1 - zoom)
	crop_height := f32(texture.height) * (1 - zoom)
	drift_x: f32 = 0.35
	if drift_right do drift_x = 0.65
	source := rl.Rectangle {
		x      = (f32(texture.width) - crop_width) * drift_x,
		y      = (f32(texture.height) - crop_height) * 0.5,
		width  = crop_width,
		height = crop_height,
	}
	dest := rl.Rectangle{width = WINDOW_WIDTH, height = WINDOW_HEIGHT}
	rl.DrawTexturePro(texture, source, dest, {}, 0, tint)
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

// format_cstring writes formatted text into a caller-owned buffer and
// null-terminates it, letting callers measure or center text before drawing.
format_cstring :: proc(buffer: []byte, format: string, args: ..any) -> cstring {
	formatted := fmt.bprintf(buffer[:len(buffer) - 1], format, ..args)
	buffer[len(formatted)] = 0
	return cstring(raw_data(buffer[:]))
}

draw_ui_format :: proc(x, y, size: i32, color: rl.Color, format: string, args: ..any) {
	buffer: [256]byte
	rl.DrawText(format_cstring(buffer[:], format, ..args), x, y, size, color)
}

// ui_pulse returns a smooth 0..1 breathing value from a free-running clock.
// It drives selection glow and ambient twinkles and never affects gameplay.
ui_pulse :: proc(clock: f64, period_seconds: f64) -> f32 {
	phase := math.mod(clock, period_seconds) / period_seconds
	return f32((math.sin(phase * math.TAU - math.PI / 2) + 1) / 2)
}

// draw_selection_glow paints a soft gold highlight bar and left accent tick
// behind the selected row of any list-style menu, shared across every menu
// screen so selection feedback reads consistently throughout the game.
draw_selection_glow :: proc(x, y, width, height: i32, pulse: f32) {
	glow_alpha := 0.14 + pulse * 0.10
	rl.DrawRectangle(x, y, width, height, rl.Fade(rl.GOLD, glow_alpha))
	rl.DrawRectangle(x, y, 3, height, rl.Fade(rl.GOLD, 0.85 + pulse * 0.15))
}

draw_menu_row :: proc(label: cstring, index, selected, y: int, pulse: f32 = 0) {
	color := rl.LIGHTGRAY
	prefix: cstring = "  "
	if index == selected {
		draw_selection_glow(163, i32(y) - 3, 320, 24, pulse)
		color = rl.GOLD
		prefix = "> "
	}
	rl.DrawText(prefix, 177, i32(y), 18, color)
	rl.DrawText(label, 203, i32(y), 18, color)
}

draw_menu_panel :: proc(title: cstring, height: i32 = 310) {
	panel_x: i32 = 80
	panel_y: i32 = 58
	rl.DrawRectangle(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, rl.Fade(rl.BLACK, 0.12))
	rl.DrawRectangle(panel_x + 5, panel_y + 6, 480, height, rl.Fade(rl.BLACK, 0.55))
	rl.DrawRectangle(panel_x, panel_y, 480, height, rl.Fade(rl.BLACK, 0.84))
	rl.DrawRectangle(panel_x + 1, panel_y + 1, 478, 42, rl.Fade(rl.DARKBROWN, 0.42))
	rl.DrawRectangleLines(panel_x, panel_y, 480, height, rl.GOLD)
	rl.DrawRectangleLines(panel_x + 3, panel_y + 3, 474, height - 6, rl.Fade(rl.GOLD, 0.28))
	title_width := rl.MeasureText(title, 24)
	rl.DrawText(title, (WINDOW_WIDTH - title_width) / 2, panel_y + 14, 24, rl.GOLD)
}

// MENU_PANEL_CONTENT_TOP sits just below draw_menu_panel's fixed title band
// (which ends at y=101), so row lists never draw under the panel title.
MENU_PANEL_CONTENT_TOP :: 106

// MENU_PANEL_VALUE_RIGHT is the shared right edge rows align their value to.
MENU_PANEL_VALUE_RIGHT :: 540

// draw_menu_value_row draws a label flush left and its value right-aligned to
// a shared column, using raylib's proportional default font. Formatting the
// two independently keeps values lined up regardless of label length, which
// embedding literal spaces in one string cannot guarantee.
draw_menu_value_row :: proc(
	label_x, y, size: i32,
	color: rl.Color,
	label: cstring,
	value_format: string,
	args: ..any,
) {
	rl.DrawText(label, label_x, y, size, color)
	value_buffer: [32]byte
	value := format_cstring(value_buffer[:], value_format, ..args)
	value_width := rl.MeasureText(value, size)
	rl.DrawText(value, MENU_PANEL_VALUE_RIGHT - value_width, y, size, color)
}

// main_menu_item_gap adds breathing room between the primary, secondary, and
// quit action groups so the list reads with clear hierarchy instead of one
// flat block.
main_menu_item_gap :: proc(item_index: int) -> i32 {
	gap: i32 = 0
	if item_index > 1 do gap += 8
	if item_index > 4 do gap += 8
	return gap
}

// draw_main_menu_ambience adds a handful of slow, story-effect-style twinkles
// over the quiet sky area of the title art so the menu feels alive even
// before the player touches a control.
draw_main_menu_ambience :: proc(game: ^Game) {
	points := [5]Story_Point{{40, 26}, {130, 54}, {238, 22}, {74, 96}, {305, 68}}
	for point, point_index in points {
		pulse := story_effect_pulse(game.ui_clock, point_index * 6, 26, game.settings.reduced_flashes)
		draw_story_glint(point, 2, rl.SKYBLUE, pulse, 1, game.settings.reduced_flashes)
	}
}

// main_menu_content_height returns the exact space the action list needs, so
// the card can be sized to fit its content instead of leaving empty space
// where the title used to sit.
main_menu_content_height :: proc() -> i32 {
	last_index := len(Main_Menu_Item) - 1
	last_y := MAIN_MENU_LIST_TOP + i32(last_index) * 24 + main_menu_item_gap(last_index)
	return last_y + 22 + MAIN_MENU_LIST_TOP
}

MAIN_MENU_LIST_TOP :: 16

// draw_main_menu_page preserves the title scene by keeping navigation in a
// compact command card on the quiet right side of the original artwork. A
// soft vignette replaces the old flat panel so the art stays the focus, and
// the card eases in when the menu is entered. The card has no title of its
// own and is sized to fit exactly around the action list.
draw_main_menu_page :: proc(game: ^Game) {
	panel_x: i32 = 388
	panel_width: i32 = 200
	panel_height := main_menu_content_height()
	panel_y := (WINDOW_HEIGHT - panel_height) / 2 + 50

	ease := clamp(f32(game.menu.page_elapsed_seconds) / 0.28, 0, 1)
	ease = ease * ease * (3 - 2 * ease)
	panel_x += i32((1 - ease) * 22)
	pulse := ui_pulse(game.ui_clock, 1.6)

	draw_main_menu_ambience(game)

	// Soft drop shadow, then a top/bottom vignette instead of a flat panel so
	// the artwork stays visible at the card's edges while the center, where
	// the text lives, stays readable.
	rl.DrawRectangle(panel_x + 5, panel_y + 6, panel_width, panel_height, rl.Fade(rl.BLACK, 0.45 * ease))
	half_height := panel_height / 2
	rl.DrawRectangleGradientV(panel_x, panel_y, panel_width, half_height, rl.Fade(rl.BLACK, 0.40 * ease), rl.Fade(rl.BLACK, 0.82 * ease))
	rl.DrawRectangleGradientV(panel_x, panel_y + half_height, panel_width, panel_height - half_height, rl.Fade(rl.BLACK, 0.82 * ease), rl.Fade(rl.BLACK, 0.40 * ease))
	rl.DrawRectangleLines(panel_x - 3, panel_y - 3, panel_width + 6, panel_height + 6, rl.Fade(rl.GOLD, 0.22 * ease))
	rl.DrawRectangle(panel_x, panel_y, 4, panel_height, rl.Fade(rl.GOLD, ease))
	rl.DrawRectangleLines(panel_x, panel_y, panel_width, panel_height, rl.Fade(rl.GOLD, 0.72 * ease))

	for item_index in 0 ..< len(Main_Menu_Item) {
		y := panel_y + MAIN_MENU_LIST_TOP + i32(item_index) * 24 + main_menu_item_gap(item_index)
		color := rl.Fade(rl.LIGHTGRAY, ease)
		label_x := panel_x + 29
		if game.menu.selected == item_index {
			draw_selection_glow(panel_x + 10, y - 3, panel_width - 20, 22, pulse)
			rl.DrawText(">", panel_x + 17, y, 16, rl.Fade(rl.GOLD, (0.85 + pulse * 0.15) * ease))
			color = rl.Fade(rl.GOLD, ease)
		}
		rl.DrawText(main_menu_item_label(Main_Menu_Item(item_index)), label_x, y, 16, color)
	}
}

draw_device_footer :: proc(game: ^Game, text_y: i32 = 372) {
	buffer: [180]byte
	footer: cstring
	if game.last_input_device == .Keyboard {
		footer = format_cstring(
			buffer[:],
			"ARROWS / %s/%s/%s/%s    %s: SELECT    ESC: BACK",
			keyboard_key_label(game.settings.bindings[.Move_Up]),
			keyboard_key_label(game.settings.bindings[.Move_Left]),
			keyboard_key_label(game.settings.bindings[.Move_Down]),
			keyboard_key_label(game.settings.bindings[.Move_Right]),
			action_prompt(.Confirm, .Keyboard, game.settings.bindings),
		)
	} else {
		footer = format_cstring(
			buffer[:],
			"LEFT STICK / MOVE BUTTONS    %s: SELECT    B: BACK",
			action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
	}
	width := rl.MeasureText(footer, 14)
	rl.DrawText(footer, (WINDOW_WIDTH - width) / 2, text_y, 14, rl.LIGHTGRAY)
}

draw_settings_menu :: proc(game: ^Game) {
	draw_menu_panel("SETTINGS", 334)
	settings := &game.settings
	pulse := ui_pulse(game.ui_clock, 1.6)
	for item_index in 0 ..< len(Settings_Menu_Item) {
		item := Settings_Menu_Item(item_index)
		color := rl.LIGHTGRAY
		prefix: cstring = "  "
		y := i32(MENU_PANEL_CONTENT_TOP + item_index * 22)
		if game.menu.selected == item_index {
			draw_selection_glow(163, y - 3, 400, 22, pulse)
			color = rl.GOLD
			prefix = "> "
		}
		rl.DrawText(prefix, 163, y, 16, color)
		switch item {
		case .Music:             draw_menu_value_row(187, y, 16, color, "MUSIC", "%d%%", settings.music_volume)
		case .Sfx:               draw_menu_value_row(187, y, 16, color, "SFX", "%d%%", settings.sfx_volume)
		case .Display_Mode:
			mode: cstring = "WINDOWED"
			if settings.display_mode == .Borderless do mode = "BORDERLESS"
			draw_menu_value_row(187, y, 16, color, "DISPLAY", "%s", mode)
		case .Window_Scale:       draw_menu_value_row(187, y, 16, color, "WINDOW SCALE", "%dx", settings.window_scale)
		case .Reduced_Flashes:    draw_menu_value_row(187, y, 16, color, "REDUCED FLASHES", "%s", "ON" if settings.reduced_flashes else "OFF")
		case .Screen_Shake:       draw_menu_value_row(187, y, 16, color, "SCREEN SHAKE", "%d%%", settings.screen_shake)
		case .Controller_Rumble:  draw_menu_value_row(187, y, 16, color, "CONTROLLER RUMBLE", "%s", "ON" if settings.controller_rumble else "OFF")
		case .High_Contrast:      draw_menu_value_row(187, y, 16, color, "DANGER HATCHING", "%s", "ON" if settings.high_contrast_preview else "OFF")
		case .Pause_On_Focus_Loss: draw_menu_value_row(187, y, 16, color, "FOCUS PAUSE", "%s", "ON" if settings.pause_on_focus_loss else "OFF")
		case .Difficulty:         draw_menu_value_row(187, y, 16, color, "DIFFICULTY", "%s", difficulty_label(settings.difficulty))
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
	pulse := ui_pulse(game.ui_clock, 1.6)
	for action_index in 0 ..< len(Input_Action) {
		action := Input_Action(action_index)
		color := rl.LIGHTGRAY
		prefix: cstring = "  "
		y := i32(MENU_PANEL_CONTENT_TOP + action_index * 29)
		if game.menu.selected == action_index {
			draw_selection_glow(167, y - 4, 400, 26, pulse)
			color = rl.GOLD
			prefix = "> "
		}
		rl.DrawText(prefix, 167, y, 16, color)
		if game.menu.binding_device == .Keyboard {
			draw_menu_value_row(191, y, 16, color, input_action_label(action), "%s", keyboard_key_label(game.settings.bindings[action]))
		} else {
			draw_menu_value_row(191, y, 16, color, input_action_label(action), "%s", controller_action_label(action, game.settings.controller_bindings))
		}
	}
	draw_menu_row("BACK", len(Input_Action), game.menu.selected, MENU_PANEL_CONTENT_TOP + len(Input_Action) * 29, pulse)
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
	rl.DrawRectangle(0, 374, WINDOW_WIDTH, 26, rl.Fade(rl.BLACK, 0.86))
	if game.last_input_device == .Controller {
		rl.DrawText("B  BACK", 292, 381, 13, rl.GOLD)
	} else {
		rl.DrawText("ESC  BACK", 283, 381, 13, rl.GOLD)
	}
}

draw_main_menu :: proc(game: ^Game) {
	switch game.menu.page {
	case .Settings:    draw_settings_menu(game)
	case .Bindings:    draw_bindings_menu(game)
	case .How_To_Play: draw_how_to_play(game)
	case .Main:
		draw_main_menu_page(game)
	case .First_Run:
		draw_menu_panel("CHOOSE YOUR START", 254)
		rl.DrawText("LEARN MOVEMENT, BOMBS, PICKUPS AND SAFETY.", 161, MENU_PANEL_CONTENT_TOP, 14, rl.WHITE)
		pulse := ui_pulse(game.ui_clock, 1.6)
		for item_index in 0 ..< len(First_Run_Item) {
			draw_menu_row(first_run_item_label(First_Run_Item(item_index)), item_index, game.menu.selected, 145 + item_index * 42, pulse)
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
	draw_ui_format(72, 348, 13, rl.LIGHTGRAY, "%s: CONTINUE", action_prompt(.Confirm, game.last_input_device, game.settings.bindings, &game.settings.controller_bindings))
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
		footer = format_cstring(
			footer_buffer[:],
			"ESC: SKIP     %s: PAUSE",
			action_prompt(.Pause, .Keyboard, game.settings.bindings),
		)
	} else {
		footer = format_cstring(
			footer_buffer[:],
			"B: SKIP     %s: PAUSE",
			action_prompt(.Pause, .Controller, game.settings.bindings, &game.settings.controller_bindings),
		)
	}
	if game.tutorial.step == .Complete {
		if game.last_input_device == .Keyboard {
			footer = format_cstring(
				footer_buffer[:],
				"%s: START CAMPAIGN",
				action_prompt(.Confirm, .Keyboard, game.settings.bindings),
			)
		} else {
			footer = format_cstring(
				footer_buffer[:],
				"%s: START CAMPAIGN",
				action_prompt(.Confirm, .Controller, game.settings.bindings, &game.settings.controller_bindings),
			)
		}
	}
	footer_width := rl.MeasureText(footer, 13)
	rl.DrawText(footer, (WINDOW_WIDTH - footer_width) / 2, 337, 13, rl.GOLD)
}

// draw_game_over_ambience adds a few slow smoke wisps over the cave opening
// in the game-over artwork for a dusty, gloomy mood, reusing the same story
// effect used for intro panels.
draw_game_over_ambience :: proc(game: ^Game) {
	origin := Story_Point{330, 90}
	for particle_index in 0 ..< story_effect_count(5, game.settings.reduced_flashes) {
		draw_story_smoke(origin, particle_index, game.ui_clock, 1, game.settings.reduced_flashes)
	}
}

// draw_gameplay renders terminal screens directly; otherwise it draws the
// active level when available and overlays its lifecycle message.
draw_gameplay :: proc(game: ^Game, assets: ^Assets) {
	gameplay := &game.gameplay
	if gameplay.state == .Game_Over {
		draw_ken_burns_texture(assets.screens.game_over, ui_pulse(game.ui_clock, 16) * 0.03, false, rl.WHITE)
		draw_game_over_ambience(game)
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
		draw_ken_burns_texture(assets.screens.you_won, ui_pulse(game.ui_clock, 16) * 0.03, true, rl.WHITE)
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

	rl.DrawTexture(assets.screens.border, 0, 0, rl.WHITE)

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
	draw_gameplay_message(format_cstring(buffer[:], format, ..args))
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
