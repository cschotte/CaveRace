package caverace

import rl "vendor:raylib"

// Input_Device drives the prompt vocabulary. The most recent real action wins;
// disconnecting a controller safely returns prompts to the keyboard.
Input_Device :: enum {
	Keyboard,
	Controller,
}

Input_Action :: enum {
	Move_Up,
	Move_Down,
	Move_Left,
	Move_Right,
	Bomb,
	Confirm,
	Pause,
	Restart,
}

Keyboard_Bindings :: [Input_Action]rl.KeyboardKey
Controller_Bindings :: [Input_Action]rl.GamepadButton

default_keyboard_bindings :: proc() -> Keyboard_Bindings {
	return {
		.Move_Up    = .W,
		.Move_Down  = .S,
		.Move_Left  = .A,
		.Move_Right = .D,
		.Bomb       = .SPACE,
		.Confirm    = .ENTER,
		.Pause      = .P,
		.Restart    = .R,
	}
}

default_controller_bindings :: proc() -> Controller_Bindings {
	return {
		.Move_Up    = .LEFT_FACE_UP,
		.Move_Down  = .LEFT_FACE_DOWN,
		.Move_Left  = .LEFT_FACE_LEFT,
		.Move_Right = .LEFT_FACE_RIGHT,
		.Bomb       = .RIGHT_FACE_DOWN,
		.Confirm    = .RIGHT_FACE_DOWN,
		.Pause      = .MIDDLE_RIGHT,
		.Restart    = .RIGHT_FACE_LEFT,
	}
}

// Bindable actions stay unique so one keyboard press never performs two
// unrelated actions. Contextual controller A remains Confirm in UI and Bomb in
// gameplay by design.
keyboard_bindings_are_valid :: proc(bindings: Keyboard_Bindings) -> bool {
	for key, action_index in bindings {
		if key == .KEY_NULL || !keyboard_key_is_bindable(key) do return false
		for other_index in int(action_index) + 1 ..< len(Input_Action) {
			if key == bindings[Input_Action(other_index)] do return false
		}
	}
	return true
}

// keyboard_key_is_bindable allows only printable/control keys that raylib
// groups into contiguous enum ranges (letters, editing keys, navigation,
// function keys, numpad); this assumes those ranges stay contiguous in the
// vendored raylib bindings.
keyboard_key_is_bindable :: proc(key: rl.KeyboardKey) -> bool {
	value := int(key)
	return value == int(rl.KeyboardKey.SPACE) ||
	       (value >= int(rl.KeyboardKey.A) && value <= int(rl.KeyboardKey.Z)) ||
	       (value >= int(rl.KeyboardKey.ENTER) && value <= int(rl.KeyboardKey.DELETE)) ||
	       (value >= int(rl.KeyboardKey.PAGE_UP) && value <= int(rl.KeyboardKey.END)) ||
	       (value >= int(rl.KeyboardKey.F1) && value <= int(rl.KeyboardKey.F12)) ||
	       (value >= int(rl.KeyboardKey.KP_0) && value <= int(rl.KeyboardKey.KP_EQUAL))
}

// controller_bindings_are_valid applies the same uniqueness rule as
// keyboard_bindings_are_valid, with the same Bomb/Confirm exception since
// controller A is contextually both in the real controller layout.
controller_bindings_are_valid :: proc(bindings: Controller_Bindings) -> bool {
	for button, action in bindings {
		if button == .UNKNOWN || button == .RIGHT_FACE_RIGHT do return false
		for other_index in int(action) + 1 ..< len(Input_Action) {
			other := Input_Action(other_index)
			if button != bindings[other] do continue
			if (action == .Bomb && other == .Confirm) ||
			   (action == .Confirm && other == .Bomb) {
				continue
			}
			return false
		}
	}
	return true
}

// try_rebind_controller_action rejects a button already bound to a different
// action (except the Bomb/Confirm pair, which may share one), leaving
// existing bindings untouched on rejection.
try_rebind_controller_action :: proc(
	bindings: ^Controller_Bindings,
	action: Input_Action,
	button: rl.GamepadButton,
) -> bool {
	if button == .UNKNOWN || button == .RIGHT_FACE_RIGHT do return false
	for existing, existing_action in bindings {
		if existing_action == action || existing != button do continue
		if (action == .Bomb && existing_action == .Confirm) ||
		   (action == .Confirm && existing_action == .Bomb) {
			continue
		}
		return false
	}
	bindings[action] = button
	return true
}

// try_rebind_keyboard_action rejects an already-used key (every keyboard
// action is exclusive, unlike the controller's Bomb/Confirm exception),
// leaving existing bindings untouched on rejection.
try_rebind_keyboard_action :: proc(
	bindings: ^Keyboard_Bindings,
	action: Input_Action,
	key: rl.KeyboardKey,
) -> bool {
	if !keyboard_key_is_bindable(key) do return false
	for existing, existing_action in bindings {
		if existing_action != action && existing == key do return false
	}
	bindings[action] = key
	return true
}

input_action_label :: proc(action: Input_Action) -> cstring {
	switch action {
	case .Move_Up:    return "MOVE UP"
	case .Move_Down:  return "MOVE DOWN"
	case .Move_Left:  return "MOVE LEFT"
	case .Move_Right: return "MOVE RIGHT"
	case .Bomb:       return "BOMB"
	case .Confirm:    return "CONFIRM"
	case .Pause:      return "PAUSE"
	case .Restart:    return "RESTART"
	}
	return ""
}

keyboard_key_label :: proc(key: rl.KeyboardKey) -> cstring {
	#partial switch key {
	case .SPACE:     return "SPACE"
	case .ENTER:     return "ENTER"
	case .ESCAPE:    return "ESC"
	case .TAB:       return "TAB"
	case .BACKSPACE: return "BACKSPACE"
	case .UP:        return "UP"
	case .DOWN:      return "DOWN"
	case .LEFT:      return "LEFT"
	case .RIGHT:     return "RIGHT"
	case .P:         return "P"
	case .R:         return "R"
	case .W:         return "W"
	case .A:         return "A"
	case .S:         return "S"
	case .D:         return "D"
	case .Q:         return "Q"
	case .E:         return "E"
	case .F:         return "F"
	case .X:         return "X"
	case .Z:         return "Z"
	case .F1: return "F1"
	case .F2: return "F2"
	case .F3: return "F3"
	case .F4: return "F4"
	case .F5: return "F5"
	case .F6: return "F6"
	case .F7: return "F7"
	case .F8: return "F8"
	case .F9: return "F9"
	case .F10: return "F10"
	case .F11: return "F11"
	case .F12: return "F12"
	case:
		return "KEY"
	}
}

controller_button_label :: proc(button: rl.GamepadButton) -> cstring {
	switch button {
	case .LEFT_FACE_UP:       return "DPAD UP"
	case .LEFT_FACE_DOWN:     return "DPAD DOWN"
	case .LEFT_FACE_LEFT:     return "DPAD LEFT"
	case .LEFT_FACE_RIGHT:    return "DPAD RIGHT"
	case .RIGHT_FACE_DOWN:    return "A"
	case .RIGHT_FACE_RIGHT:   return "B"
	case .RIGHT_FACE_LEFT:    return "X"
	case .RIGHT_FACE_UP:      return "Y"
	case .LEFT_TRIGGER_1:     return "LB"
	case .RIGHT_TRIGGER_1:    return "RB"
	case .LEFT_TRIGGER_2:     return "LT"
	case .RIGHT_TRIGGER_2:    return "RT"
	case .MIDDLE_LEFT:        return "VIEW"
	case .MIDDLE_RIGHT:       return "START"
	case .LEFT_THUMB:         return "L STICK"
	case .RIGHT_THUMB:        return "R STICK"
	case .MIDDLE:             return "GUIDE"
	case .UNKNOWN:            return "BUTTON"
	}
	return ""
}

controller_action_label :: proc(
	action: Input_Action,
	bindings: Controller_Bindings,
) -> cstring {
	return controller_button_label(bindings[action])
}

// action_prompt returns the current device's label for an action, used to
// build on-screen hints. A nil controller falls back to the default layout,
// letting call sites that only care about keyboard prompts omit it.
action_prompt :: proc(
	action: Input_Action,
	device: Input_Device,
	bindings: Keyboard_Bindings,
	controller: ^Controller_Bindings = nil,
) -> cstring {
	if device == .Controller {
		controller_bindings := default_controller_bindings()
		if controller != nil do controller_bindings = controller^
		return controller_action_label(action, controller_bindings)
	}
	return keyboard_key_label(bindings[action])
}

// resolve_last_input_device favors real controller activity while it's
// connected, otherwise keyboard activity, and falls back to keyboard the
// moment a controller disconnects so prompts never point at a dead device.
resolve_last_input_device :: proc(
	previous: Input_Device,
	keyboard_activity, controller_activity, controller_connected: bool,
) -> Input_Device {
	if controller_activity && controller_connected do return .Controller
	if keyboard_activity do return .Keyboard
	if previous == .Controller && !controller_connected do return .Keyboard
	return previous
}
