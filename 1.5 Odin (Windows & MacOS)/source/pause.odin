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

open_game_pause :: proc(game: ^Game) {
	if game.pause.open do return
	if (game.screen != .Playing && game.screen != .Tutorial) ||
	   game.gameplay.state != .Playing {
		return
	}
	game.pause = Pause_State {open = true}
	game.gameplay.tick_state.input = {}
}

close_game_pause :: proc(game: ^Game) {
	game.pause = {}
	game.gameplay.tick_state.input = {}
}

move_pause_selection :: proc(state: ^Pause_State, delta: int) {
	count := len(Pause_Menu_Item)
	selected := (int(state.selected) + delta + count) % count
	state.selected = Pause_Menu_Item(selected)
}

update_pause_menu :: proc(game: ^Game, input: Game_Input) -> Pause_Update_Result {
	assert(game.pause.open)
	result: Pause_Update_Result
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
		if input.back || input.pause_pressed {
			game.pause.confirmation = .None
			return result
		}
		if !input.confirm do return result

		switch game.pause.confirmation {
		case .Restart_Level: result.restart_level = true
		case .Main_Menu:     result.main_menu = true
		case .None:
		}
		close_game_pause(game)
		return result
	}

	if input.pause_pressed || input.back {
		close_game_pause(game)
		return result
	}
	if input.restart_pressed {
		game.pause.confirmation = .Restart_Level
		return result
	}
	if input.menu_up_pressed do move_pause_selection(&game.pause, -1)
	if input.menu_down_pressed do move_pause_selection(&game.pause, 1)
	if !input.confirm do return result

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
