package caverace

import rl "vendor:raylib"

// Game_Input is the semantic, allocation-free input snapshot passed unchanged to
// whichever screen updates during the current frame.
Game_Input :: struct {
	any_key_pressed: bool,
	confirm:         bool,
	back:            bool,
	space_pressed:   bool,
	move_down:       bool,
	move_up:         bool,
	move_right:      bool,
	move_left:       bool,
	cheat_pressed:   [Cheat_Key]bool,
}

// poll_game_input maps raylib keyboard state into one semantic frame snapshot
// consumed by the front end and gameplay.
poll_game_input :: proc() -> Game_Input {
	input: Game_Input

	input.confirm       = rl.IsKeyPressed(.ENTER)
	input.back          = rl.IsKeyPressed(.ESCAPE)
	input.space_pressed = rl.IsKeyPressed(.SPACE)

	input.move_down  = rl.IsKeyDown(.DOWN)
	input.move_up    = rl.IsKeyDown(.UP)
	input.move_right = rl.IsKeyDown(.RIGHT)
	input.move_left  = rl.IsKeyDown(.LEFT)

	input.cheat_pressed[.F1] = rl.IsKeyPressed(.F1)
	input.cheat_pressed[.F2] = rl.IsKeyPressed(.F2)
	input.cheat_pressed[.F3] = rl.IsKeyPressed(.F3)
	input.cheat_pressed[.F4] = rl.IsKeyPressed(.F4)
	input.cheat_pressed[.F5] = rl.IsKeyPressed(.F5)
	input.any_key_pressed = rl.GetKeyPressed() != .KEY_NULL
	return input
}
