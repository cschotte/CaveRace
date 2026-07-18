package caverace

import rl "vendor:raylib"

update_high_scores :: proc(input: Game_Input) -> (back_requested: bool) {
	return input.back || input.space_pressed ||
	       input.mouse.left_pressed || input.mouse.right_pressed
}

draw_high_scores :: proc(background: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)
}
