package caverace

App_Screen :: enum {
	Menu,
	Playing,
	High_Scores,
}

Game :: struct {
	screen:         App_Screen,
	menu:           Menu_State,
	gameplay:       Gameplay,
	options:        Launch_Options,
	quit_requested: bool,
}

Game_Update_Result :: struct {
	menu_selection_changed: bool,
	gameplay:               Gameplay_Frame_Result,
}

init_game :: proc(game: ^Game, options: Launch_Options) {
	game^ = Game {
		screen    = .Menu,
		menu      = {selected = .Start_Game},
		options   = options,
	}
	init_gameplay(&game.gameplay)
}

start_new_game :: proc(game: ^Game) {
	init_gameplay(&game.gameplay)
	game.screen = .Playing
}

update_game :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Game_Update_Result {
	result: Game_Update_Result

	switch game.screen {
	case .Menu:
		menu_result := update_menu(&game.menu, input)
		result.menu_selection_changed = menu_result.selection_changed

		if selected, ok := menu_result.confirmed.?; ok {
			switch selected {
			case .Start_Game:
				start_new_game(game)
			case .High_Scores:
				game.screen = .High_Scores
			case .Quit:
				game.quit_requested = true
			}
		}
	case .Playing:
		result.gameplay = update_gameplay(&game.gameplay, input, frame_seconds)
		if result.gameplay.back_requested do game.screen = .Menu
	case .High_Scores:
		back_requested := update_high_scores(input)
		if back_requested do game.screen = .Menu
	}

	return result
}

draw_game :: proc(game: ^Game, assets: ^Assets, mouse: Mouse_State) {
	switch game.screen {
	case .Menu:
		draw_menu(game.menu, assets.screens.menu, assets.screens.select)
	case .Playing:
		draw_gameplay(&game.gameplay, assets)
	case .High_Scores:
		draw_high_scores(assets.screens.highscore)
	}

	draw_mouse(mouse, assets.sprites.tools)
}
