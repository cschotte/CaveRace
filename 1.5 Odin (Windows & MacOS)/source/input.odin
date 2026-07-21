package caverace

import rl "vendor:raylib"

GAMEPAD_INDEX      :: 0
GAMEPAD_DEAD_ZONE  :: f32(0.35)

// Input_Poll_State turns analog stick threshold crossings into UI edges while
// gameplay continues to consume held directions.
Input_Poll_State :: struct {
	stick_up:    bool,
	stick_down:  bool,
	stick_left:  bool,
	stick_right: bool,
}

// Game_Input is the semantic, allocation-free input snapshot passed unchanged
// to the active screen. Platform key/button identities stop at poll_game_input.
Game_Input :: struct {
	any_key_pressed: bool,
	confirm:         bool,
	back:            bool,
	pause_pressed:   bool,
	restart_pressed: bool,
	menu_up_pressed: bool,
	menu_down_pressed: bool,
	menu_left_pressed: bool,
	menu_right_pressed: bool,
	space_pressed:   bool,
	move_down:       bool,
	move_up:         bool,
	move_right:      bool,
	move_left:       bool,
	pressed_key:     rl.KeyboardKey,
	pressed_gamepad_button: rl.GamepadButton,
	keyboard_activity: bool,
	controller_activity: bool,
	controller_connected: bool,
	presentation_music_controls_timing: bool,
	presentation_music_finished: bool,
	debug_toggle_pressed: bool,
	cheat_pressed:   [Cheat_Key]bool,
}

key_pressed_for_action :: proc(bindings: Keyboard_Bindings, action: Input_Action) -> bool {
	return rl.IsKeyPressed(bindings[action])
}

key_down_for_action :: proc(bindings: Keyboard_Bindings, action: Input_Action) -> bool {
	return rl.IsKeyDown(bindings[action])
}

// poll_game_input maps the current bindings plus conventional arrow fallbacks
// and Xbox-style controller controls into one semantic frame snapshot.
poll_game_input :: proc(
	bindings: Keyboard_Bindings,
	controller_bindings: Controller_Bindings,
	poll_state: ^Input_Poll_State,
) -> Game_Input {
	input: Game_Input
	input.pressed_key = rl.GetKeyPressed()
	input.any_key_pressed = input.pressed_key != .KEY_NULL
	input.controller_connected = rl.IsGamepadAvailable(GAMEPAD_INDEX)

	keyboard_confirm := key_pressed_for_action(bindings, .Confirm) || rl.IsKeyPressed(.SPACE)
	keyboard_up := key_pressed_for_action(bindings, .Move_Up) || rl.IsKeyPressed(.UP)
	keyboard_down := key_pressed_for_action(bindings, .Move_Down) || rl.IsKeyPressed(.DOWN)
	keyboard_left := key_pressed_for_action(bindings, .Move_Left) || rl.IsKeyPressed(.LEFT)
	keyboard_right := key_pressed_for_action(bindings, .Move_Right) || rl.IsKeyPressed(.RIGHT)

	controller_up, controller_down := false, false
	controller_left, controller_right := false, false
	controller_confirm, controller_back := false, false
	controller_pause, controller_restart := false, false
	controller_bomb := false
	stick_up, stick_down, stick_left, stick_right := false, false, false, false
	if input.controller_connected {
		input.pressed_gamepad_button = rl.GetGamepadButtonPressed()
		controller_up = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Move_Up])
		controller_down = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Move_Down])
		controller_left = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Move_Left])
		controller_right = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Move_Right])
		controller_confirm = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Confirm])
		controller_bomb = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Bomb])
		controller_back = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, .RIGHT_FACE_RIGHT)
		controller_pause = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Pause])
		controller_restart = rl.IsGamepadButtonPressed(GAMEPAD_INDEX, controller_bindings[.Restart])

		axis_x := rl.GetGamepadAxisMovement(GAMEPAD_INDEX, .LEFT_X)
		axis_y := rl.GetGamepadAxisMovement(GAMEPAD_INDEX, .LEFT_Y)
		stick_left = axis_x < -GAMEPAD_DEAD_ZONE
		stick_right = axis_x > GAMEPAD_DEAD_ZONE
		stick_up = axis_y < -GAMEPAD_DEAD_ZONE
		stick_down = axis_y > GAMEPAD_DEAD_ZONE
	}

	input.confirm = keyboard_confirm || controller_confirm
	input.back = rl.IsKeyPressed(.ESCAPE) || controller_back
	input.pause_pressed = key_pressed_for_action(bindings, .Pause) || controller_pause
	input.restart_pressed = key_pressed_for_action(bindings, .Restart) || controller_restart
	input.menu_up_pressed = keyboard_up || controller_up || (stick_up && !poll_state.stick_up)
	input.menu_down_pressed = keyboard_down || controller_down || (stick_down && !poll_state.stick_down)
	input.menu_left_pressed = keyboard_left || controller_left || (stick_left && !poll_state.stick_left)
	input.menu_right_pressed = keyboard_right || controller_right || (stick_right && !poll_state.stick_right)
	input.space_pressed = key_pressed_for_action(bindings, .Bomb) || controller_bomb

	input.move_down = key_down_for_action(bindings, .Move_Down) || rl.IsKeyDown(.DOWN) ||
	                  (input.controller_connected && (rl.IsGamepadButtonDown(GAMEPAD_INDEX, controller_bindings[.Move_Down]) || stick_down))
	input.move_up = key_down_for_action(bindings, .Move_Up) || rl.IsKeyDown(.UP) ||
	                (input.controller_connected && (rl.IsGamepadButtonDown(GAMEPAD_INDEX, controller_bindings[.Move_Up]) || stick_up))
	input.move_right = key_down_for_action(bindings, .Move_Right) || rl.IsKeyDown(.RIGHT) ||
	                   (input.controller_connected && (rl.IsGamepadButtonDown(GAMEPAD_INDEX, controller_bindings[.Move_Right]) || stick_right))
	input.move_left = key_down_for_action(bindings, .Move_Left) || rl.IsKeyDown(.LEFT) ||
	                  (input.controller_connected && (rl.IsGamepadButtonDown(GAMEPAD_INDEX, controller_bindings[.Move_Left]) || stick_left))

	input.keyboard_activity = input.any_key_pressed || keyboard_confirm || rl.IsKeyPressed(.ESCAPE) ||
	                          key_pressed_for_action(bindings, .Pause) ||
	                          key_pressed_for_action(bindings, .Restart) ||
	                          keyboard_up || keyboard_down || keyboard_left || keyboard_right ||
	                          key_pressed_for_action(bindings, .Bomb)
	input.controller_activity = controller_up || controller_down || controller_left || controller_right ||
	                            controller_confirm || controller_back || controller_pause || controller_restart ||
	                            input.pressed_gamepad_button != .UNKNOWN ||
	                            stick_up || stick_down || stick_left || stick_right

	poll_state^ = {
		stick_up    = stick_up,
		stick_down  = stick_down,
		stick_left  = stick_left,
		stick_right = stick_right,
	}

	when ODIN_DEBUG {
		input.debug_toggle_pressed = rl.IsKeyPressed(.F10)
	}
	input.cheat_pressed[.F1] = rl.IsKeyPressed(.F1)
	input.cheat_pressed[.F2] = rl.IsKeyPressed(.F2)
	input.cheat_pressed[.F3] = rl.IsKeyPressed(.F3)
	input.cheat_pressed[.F4] = rl.IsKeyPressed(.F4)
	input.cheat_pressed[.F5] = rl.IsKeyPressed(.F5)
	return input
}
