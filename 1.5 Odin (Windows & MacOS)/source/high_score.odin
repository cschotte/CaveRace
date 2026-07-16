package caverace

import rl "vendor:raylib"

update_high_scores :: proc(input: Game_Input) -> (back_requested: bool) {
	return input.back
}

draw_high_scores :: proc(background: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)
}
