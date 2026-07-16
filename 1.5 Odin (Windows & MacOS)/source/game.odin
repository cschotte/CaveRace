package caverace

import rl "vendor:raylib"

Game_Screen :: enum {
	Menu,
	Playing,
	High_Scores,
}

Game :: struct {
	screen:         Game_Screen,
	menu:      Menu_State,
	level:          Level,
	input:          Game_Input,
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
	game.input = input

	switch game.screen {
	case .Menu:
		update_menu(game, input)
	case .Playing:
		update_playing(game, input)
	case .High_Scores:
		update_high_scores(game, input)
	}
}

draw_game :: proc(game: ^Game, assets: ^Assets) {
	switch game.screen {
	case .Menu:
		draw_menu(game, assets)
	case .Playing:
		draw_playing(game, assets)
	case .High_Scores:
		draw_high_scores(game, assets)
	}
}

update_playing :: proc(game: ^Game, input: Game_Input) {
	if input.back do game.screen = .Menu
}

draw_playing :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.game, 0, 0, rl.WHITE)
}

update_high_scores :: proc(game: ^Game, input: Game_Input) {
	if input.back do game.screen = .Menu
}

draw_high_scores :: proc(game: ^Game, assets: ^Assets) {
	rl.DrawTexture(assets.screens.highscore, 0, 0, rl.WHITE)
}
