package caverace

import rl "vendor:raylib"

MAX_TEXT_CODEPOINTS_PER_FRAME :: 16

// Mouse_State is the frame snapshot shared by menu hit testing, high-score
// dismissal, and custom pointer rendering.
Mouse_State :: struct {
	x:             i32,
	y:             i32,
	moved:         bool,
	left_pressed:  bool,
	right_pressed: bool,
}

// Game_Input is the semantic, allocation-free input snapshot passed unchanged to
// whichever screen updates during the current frame.
Game_Input :: struct {
	menu_shortcut:   Maybe(Menu_Item),
	menu_next:       bool,
	menu_previous:   bool,
	confirm:         bool,
	back:            bool,
	space_pressed:   bool,
	move_down:       bool,
	move_up:         bool,
	move_right:      bool,
	move_left:       bool,
	cheat_pressed:   [Cheat_Key]bool,
	text_codepoints: [MAX_TEXT_CODEPOINTS_PER_FRAME]rune,
	text_count:      int,
	text_backspace:  bool,
	mouse:           Mouse_State,
}

// poll_game_input maps raylib keyboard, text, and mouse state into one semantic
// frame snapshot consumed by menu, gameplay, and high-score updates.
poll_game_input :: proc() -> Game_Input {
	input: Game_Input

	if rl.IsKeyPressed(.ONE) do input.menu_shortcut = Menu_Item.Start_Game
	if rl.IsKeyPressed(.TWO) do input.menu_shortcut = Menu_Item.High_Scores
	if rl.IsKeyPressed(.THREE) do input.menu_shortcut = Menu_Item.Quit

	input.menu_next     = rl.IsKeyPressed(.DOWN)
	input.menu_previous = rl.IsKeyPressed(.UP)
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

	input.text_backspace = rl.IsKeyPressed(.BACKSPACE)
	for input.text_count < MAX_TEXT_CODEPOINTS_PER_FRAME {
		codepoint := rl.GetCharPressed()
		if codepoint == 0 do break
		input.text_codepoints[input.text_count] = codepoint
		input.text_count += 1
	}

	mouse := rl.GetMousePosition()
	mouse_delta := rl.GetMouseDelta()
	input.mouse = {
		x             = i32(mouse.x),
		y             = i32(mouse.y),
		moved         = mouse_delta.x != 0 || mouse_delta.y != 0,
		left_pressed  = rl.IsMouseButtonPressed(.LEFT),
		right_pressed = rl.IsMouseButtonPressed(.RIGHT),
	}

	return input
}
