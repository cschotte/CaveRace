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

init_game :: proc(game: ^Game, options: Launch_Options) {
	game^ = Game {
		screen    = .Menu,
		menu      = {selected = .Start_Game},
		options   = options,
	}
}

update_game :: proc(game: ^Game, input: Game_Input) {
	switch game.screen {
	case .Menu:
		confirmed := update_menu(&game.menu, input)
		if selected, ok := confirmed.?; ok {
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
		update_playing(game, input)
	case .High_Scores:
		update_high_scores(game, input)
	}
}

draw_game :: proc(game: ^Game, assets: ^Assets, mouse: Mouse_State) {
	switch game.screen {
	case .Menu:
		draw_menu(game.menu, assets)
	case .Playing:
		draw_playing(assets)
	case .High_Scores:
		draw_high_scores(assets)
	}

	draw_mouse(mouse, assets.sprites.tools)
}

update_playing :: proc(game: ^Game, input: Game_Input) {
	if input.back do game.screen = .Menu
}

draw_playing :: proc(assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)
}
