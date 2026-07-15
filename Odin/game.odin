package caverace

import rl "vendor:raylib"

Game_Screen :: enum {
	Main_Menu,
	Playing,
	High_Scores,
}

Game :: struct {
	screen:  Game_Screen,
	level:   Level,
	options: Launch_Options,
}

init_game :: proc(game: ^Game, options: Launch_Options) {
	game^ = Game {
		screen = .Main_Menu,
		options = options,
	}
}

update_game :: proc(game: ^Game) {
	switch game.screen {
		case .Main_Menu:
			update_main_menu(game)
		case .Playing:
			update_playing(game)
		case .High_Scores:
			update_high_scores(game)
	}
}

draw_game :: proc(game: ^Game, assets: ^Assets) {
	switch game.screen {
		case .Main_Menu:
			draw_main_menu(game, assets)
		case .Playing:
			draw_playing(game, assets)
		case .High_Scores:
			draw_high_scores(game, assets)
	}
}


update_main_menu :: proc(game: ^Game) {
}

draw_main_menu :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.menu, 0, 0, rl.WHITE)
}

update_playing :: proc(game: ^Game) {
}

draw_playing :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)
}

update_high_scores :: proc(game: ^Game) {
}

draw_high_scores :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.highscore, 0, 0, rl.WHITE)
}