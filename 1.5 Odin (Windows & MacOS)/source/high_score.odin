package caverace

import rl "vendor:raylib"

update_high_scores :: proc(game: ^Game, input: Game_Input) {
	if input.back do game.screen = .Menu
}

draw_high_scores :: proc(assets: ^Assets) {
	rl.DrawTexture(assets.screens.highscore, 0, 0, rl.WHITE)
}
