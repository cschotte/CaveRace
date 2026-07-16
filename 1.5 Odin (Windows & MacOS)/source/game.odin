package caverace

import rl "vendor:raylib"

Game_Screen :: enum {
	Menu,
	Playing,
	High_Scores,
}

Game :: struct {
	screen:         Game_Screen,
	menu:           Menu_State,
	level:          Level,
	options:        Launch_Options,
	quit_requested: bool,
}

Game_Update_Result :: struct {
	menu_selection_changed: bool,
}

init_game :: proc(game: ^Game, options: Launch_Options) {
	game^ = Game {
		screen    = .Menu,
		menu      = {selected = .Start_Game},
		options   = options,
	}
}

update_game :: proc(game: ^Game, input: Game_Input) -> Game_Update_Result {
	result: Game_Update_Result

	switch game.screen {
	case .Menu:
		menu_result := update_menu(&game.menu, input)
		result.menu_selection_changed = menu_result.selection_changed

		if selected, ok := menu_result.confirmed.?; ok {
			switch selected {
			case .Start_Game:
				game.screen = .Playing
			case .High_Scores:
				game.screen = .High_Scores
			case .Quit:
				game.quit_requested = true
			}
		}
	case .Playing:
		back_requested := update_playing(input)
		if back_requested do game.screen = .Menu
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
		draw_playing(assets.screens.game)
	case .High_Scores:
		draw_high_scores(assets.screens.highscore)
	}

	draw_mouse(mouse, assets.sprites.tools)
}

update_playing :: proc(input: Game_Input) -> (back_requested: bool) {
	return input.back
}

draw_playing :: proc(background: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)
}
