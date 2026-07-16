package caverace

import rl "vendor:raylib"

Game_Input :: struct {
	menu_shortcut: Maybe(Menu_Item),
	menu_next:     bool,
	menu_previous: bool,
	confirm:       bool,
	back:          bool,
	mouse:         Mouse_State,
}

poll_game_input :: proc() -> Game_Input {
	input: Game_Input

	if rl.IsKeyPressed(.ONE) do input.menu_shortcut = Menu_Item.Start_Game
	if rl.IsKeyPressed(.TWO) do input.menu_shortcut = Menu_Item.High_Scores
	if rl.IsKeyPressed(.THREE) do input.menu_shortcut = Menu_Item.Quit

	input.menu_next     = rl.IsKeyPressed(.DOWN)
	input.menu_previous = rl.IsKeyPressed(.UP)
	input.confirm       = rl.IsKeyPressed(.ENTER)
	input.back          = rl.IsKeyPressed(.ESCAPE)

	mouse := rl.GetMousePosition()
	mouse_delta := rl.GetMouseDelta()
	input.mouse = {
		x            = i32(mouse.x),
		y            = i32(mouse.y),
		moved        = mouse_delta.x != 0 || mouse_delta.y != 0,
		left_pressed = rl.IsMouseButtonPressed(.LEFT),
	}

	return input
}
