package caverace

import rl "vendor:raylib"

Game_Input :: struct {
	menu_selection: Maybe(Menu_Item),
	menu_next:      bool,
	menu_previous:  bool,
	confirm:        bool,
	back:           bool,
	mouse_x:        i32,
	mouse_y:        i32,
}

poll_game_input :: proc() -> Game_Input {
	input: Game_Input

	if rl.IsKeyPressed(.ONE) do input.menu_selection = Menu_Item.Start_Game
	if rl.IsKeyPressed(.TWO) do input.menu_selection = Menu_Item.High_Scores
	if rl.IsKeyPressed(.THREE) do input.menu_selection = Menu_Item.Quit

	input.menu_next     = rl.IsKeyPressed(.DOWN)
	input.menu_previous = rl.IsKeyPressed(.UP)
	input.confirm       = rl.IsKeyPressed(.ENTER)
	input.back          = rl.IsKeyPressed(.ESCAPE)

	mouse := rl.GetMousePosition()
	input.mouse_x = i32(mouse.x)
	input.mouse_y = i32(mouse.y)

	return input
}
