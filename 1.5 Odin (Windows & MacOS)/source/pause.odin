package caverace

Pause_Menu_Item :: enum {
	Resume,
	Restart_Level,
	Settings,
	Controls,
	Main_Menu,
}

Pause_Page :: enum {
	Main,
	Settings,
	Controls,
}

Pause_Confirmation :: enum {
	None,
	Restart_Level,
	Main_Menu,
}

Pause_State :: struct {
	open:         bool,
	selected:     Pause_Menu_Item,
	confirmation: Pause_Confirmation,
	page:         Pause_Page,
	// Time since the pause overlay opened, purely for its cosmetic fade-in.
	elapsed_seconds: f64,
}

Pause_Update_Result :: struct {
	restart_level: bool,
	main_menu:     bool,
	settings_changed: bool,
	display_changed:  bool,
}

game_is_paused :: proc(game: ^Game) -> bool {
	return game.pause.open
}

// open_game_pause only takes effect during active Playing/Tutorial gameplay,
// and clears any queued movement/bomb input so it can't fire the instant
// gameplay resumes.
open_game_pause :: proc(game: ^Game) {
	if game.pause.open do return
	if (game.screen != .Playing && game.screen != .Tutorial) ||
	   game.gameplay.state != .Playing {
		return
	}
	game.pause = Pause_State {open = true}
	game.gameplay.tick_state.input = {}
}

// close_game_pause mirrors open_game_pause's input flush on the way out.
close_game_pause :: proc(game: ^Game) {
	game.pause = {}
	game.gameplay.tick_state.input = {}
}

move_pause_selection :: proc(state: ^Pause_State, delta: int) {
	count := len(Pause_Menu_Item)
	selected := (int(state.selected) + delta + count) % count
	state.selected = Pause_Menu_Item(selected)
}

pause_panel_geometry :: proc() -> (x, y, width, height: i32) {
	width = MENU_NARROW_PANEL_WIDTH
	last_row_offset := PAUSE_CONTENT_TOP + i32(len(Pause_Menu_Item) - 1) * PAUSE_ROW_SPACING
	height = last_row_offset + PAUSE_ROW_HEIGHT + 14
	x = (WINDOW_WIDTH - width) / 2
	y = WINDOW_HEIGHT - height - MENU_PANEL_BOTTOM_MARGIN
	return
}

pause_item_rect :: proc(item_index: int) -> (UI_Rect, bool) {
	if item_index < 0 || item_index >= len(Pause_Menu_Item) do return {}, false
	panel_x, panel_y, panel_width, _ := pause_panel_geometry()
	y := panel_y + PAUSE_CONTENT_TOP + i32(item_index) * PAUSE_ROW_SPACING
	return {
		f32(panel_x + MENU_GLOW_INSET),
		f32(y - 3),
		f32(panel_width - MENU_GLOW_INSET * 2),
		f32(PAUSE_ROW_HEIGHT),
	}, true
}

pause_hovered_item :: proc(pointer: Pointer_Input) -> (Pause_Menu_Item, bool) {
	for item_index in 0 ..< len(Pause_Menu_Item) {
		if rect, ok := pause_item_rect(item_index); ok && ui_rect_contains(rect, pointer) {
			return Pause_Menu_Item(item_index), true
		}
	}
	return {}, false
}

pause_confirmation_rects :: proc() -> (confirm, cancel: UI_Rect) {
	_, panel_y, _, _ := pause_panel_geometry()
	button_y := panel_y + 112
	confirm = {f32(WINDOW_WIDTH / 2 - 128), f32(button_y), 116, 28}
	cancel = {f32(WINDOW_WIDTH / 2 + 12), f32(button_y), 116, 28}
	return
}

// update_pause_menu handles input while paused: the confirmation prompt for
// destructive actions first, then the Resume/Restart/Settings/Controls/Main
// Menu list, delegating to update_menu while a Settings or Controls sub-page
// is open.
update_pause_menu :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Pause_Update_Result {
	assert(game.pause.open)
	result: Pause_Update_Result
	game.pause.elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	if game.pause.page != .Main {
		if input.pause_pressed {
			close_game_pause(game)
			return result
		}
		if game.pause.page == .Controls && input.back {
			game.pause.page = .Main
			return result
		}
		menu_result := update_menu(&game.menu, &game.settings, input, 0)
		result.settings_changed = menu_result.settings_changed
		result.display_changed = menu_result.display_changed
		if game.pause.page == .Settings && game.menu.page == .Main {
			game.pause.page = .Main
		} else if game.pause.page == .Controls && game.menu.page == .Settings {
			game.pause.page = .Main
		}
		return result
	}

	if game.pause.confirmation != .None {
		confirm_rect, cancel_rect := pause_confirmation_rects()
		pointer_cancel := input.pointer.primary_pressed &&
		                  ui_rect_contains(cancel_rect, input.pointer)
		if input.back || input.pause_pressed || input.pointer.secondary_pressed ||
		   pointer_cancel {
			game.pause.confirmation = .None
			return result
		}
		pointer_confirm := input.pointer.primary_pressed &&
		                   ui_rect_contains(confirm_rect, input.pointer)
		if !input.confirm && !pointer_confirm do return result

		switch game.pause.confirmation {
		case .Restart_Level: result.restart_level = true
		case .Main_Menu:     result.main_menu = true
		case .None:
		}
		close_game_pause(game)
		return result
	}

	if input.pause_pressed || input.back || input.pointer.secondary_pressed {
		close_game_pause(game)
		return result
	}
	if input.restart_pressed {
		game.pause.confirmation = .Restart_Level
		return result
	}
	if input.pointer.moved {
		if hovered, ok := pause_hovered_item(input.pointer); ok {
			game.pause.selected = hovered
		}
	}
	if input.pointer.wheel != 0 {
		move_pause_selection(&game.pause, -1 if input.pointer.wheel > 0 else 1)
	}
	if input.menu_up_pressed do move_pause_selection(&game.pause, -1)
	if input.menu_down_pressed do move_pause_selection(&game.pause, 1)
	confirm_pressed := input.confirm
	if input.pointer.primary_pressed {
		if hovered, ok := pause_hovered_item(input.pointer); ok {
			game.pause.selected = hovered
			confirm_pressed = true
		}
	}
	if !confirm_pressed do return result

	switch game.pause.selected {
	case .Resume:
		close_game_pause(game)
	case .Restart_Level:
		game.pause.confirmation = .Restart_Level
	case .Settings:
		open_menu_page(&game.menu, .Settings)
		game.pause.page = .Settings
	case .Controls:
		open_menu_page(&game.menu, .Bindings)
		game.pause.page = .Controls
	case .Main_Menu:
		game.pause.confirmation = .Main_Menu
	}
	return result
}
