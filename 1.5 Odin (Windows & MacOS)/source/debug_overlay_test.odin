package caverace

import "core:testing"

@(test)
debug_overlay_toggle_is_debug_build_only_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	update_game(&game, Game_Input {debug_toggle_pressed = true}, 0)
	when ODIN_DEBUG {
		testing.expect(t, game.debug_overlay_visible)
	} else {
		testing.expect(t, !game.debug_overlay_visible)
	}
}
