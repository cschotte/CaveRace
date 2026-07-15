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
			rl.DrawTexture(assets.screens.menu, 0, 0, rl.WHITE)
		case .Playing:
			rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)
		case .High_Scores:
			rl.DrawTexture(assets.screens.highscore, 0, 0, rl.WHITE)
	}
}

// Screen-specific update procedures are intentionally small extension points.
// New menu, level, and gameplay rules can be added without growing the app loop.
update_main_menu :: proc(game: ^Game) {
}

update_playing :: proc(game: ^Game) {
}

update_high_scores :: proc(game: ^Game) {
}
