package caverace

Menu_Page :: enum {
	Main,
	First_Run,
	How_To_Play,
	Settings,
	Bindings,
}

Main_Menu_Item :: enum {
	Start_Game,
	Tutorial,
	How_To_Play,
	Settings,
	Replay_Story,
	Quit,
}

First_Run_Item :: enum {
	Tutorial,
	Campaign,
	Back,
}

Settings_Menu_Item :: enum {
	Music,
	Sfx,
	Display_Mode,
	Window_Scale,
	Reduced_Flashes,
	Screen_Shake,
	High_Contrast,
	Pause_On_Focus_Loss,
	Difficulty,
	Bindings,
	Back,
}

Menu_State :: struct {
	page:              Menu_Page,
	selected:          int,
	help_page:         int,
	binding_waiting:   bool,
	binding_action:    Input_Action,
	binding_device:    Input_Device,
	binding_conflict_seconds: f64,
}

Menu_Update_Result :: struct {
	start_campaign: bool,
	start_tutorial: bool,
	replay_story:   bool,
	quit_requested: bool,
	settings_changed: bool,
	display_changed:  bool,
}

begin_menu :: proc(menu: ^Menu_State) {
	menu^ = {}
}

menu_item_count :: proc(page: Menu_Page) -> int {
	switch page {
	case .Main:        return len(Main_Menu_Item)
	case .First_Run:   return len(First_Run_Item)
	case .Settings:    return len(Settings_Menu_Item)
	case .Bindings:    return len(Input_Action) + 1
	case .How_To_Play: return 0
	}
	return 0
}

move_menu_selection :: proc(menu: ^Menu_State, delta: int) {
	count := menu_item_count(menu.page)
	if count <= 0 do return
	menu.selected = (menu.selected + delta + count) % count
}

open_menu_page :: proc(menu: ^Menu_State, page: Menu_Page) {
	menu.page = page
	menu.selected = 0
	menu.binding_waiting = false
	menu.binding_conflict_seconds = 0
}

adjust_setting :: proc(
	settings: ^Settings,
	item: Settings_Menu_Item,
	delta: int,
) -> (changed, display_changed: bool) {
	switch item {
	case .Music:
		value := clamp(settings.music_volume + delta * 5, 0, 100)
		changed = value != settings.music_volume
		settings.music_volume = value
	case .Sfx:
		value := clamp(settings.sfx_volume + delta * 5, 0, 100)
		changed = value != settings.sfx_volume
		settings.sfx_volume = value
	case .Display_Mode:
		settings.display_mode = .Borderless if settings.display_mode == .Windowed else .Windowed
		changed, display_changed = true, true
	case .Window_Scale:
		value := clamp(settings.window_scale + delta, 1, 3)
		changed = value != settings.window_scale
		settings.window_scale = value
		display_changed = changed
	case .Reduced_Flashes:
		settings.reduced_flashes = !settings.reduced_flashes
		changed = true
	case .Screen_Shake:
		value := clamp(settings.screen_shake + delta * 10, 0, 100)
		changed = value != settings.screen_shake
		settings.screen_shake = value
	case .High_Contrast:
		settings.high_contrast_preview = !settings.high_contrast_preview
		changed = true
	case .Pause_On_Focus_Loss:
		settings.pause_on_focus_loss = !settings.pause_on_focus_loss
		changed = true
	case .Difficulty:
		settings.difficulty = .Assisted if settings.difficulty == .Standard else .Standard
		changed = true
	case .Bindings, .Back:
	}
	return
}

update_menu :: proc(
	menu: ^Menu_State,
	settings: ^Settings,
	input: Game_Input,
	frame_seconds: f64,
) -> Menu_Update_Result {
	result: Menu_Update_Result
	menu.binding_conflict_seconds = max(
		menu.binding_conflict_seconds - clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS),
		0,
	)

	if menu.page == .How_To_Play {
		if input.back {
			open_menu_page(menu, .Main)
		} else if input.menu_left_pressed {
			menu.help_page = max(menu.help_page - 1, 0)
		} else if input.menu_right_pressed || input.confirm {
			if menu.help_page < 1 {
				menu.help_page += 1
			} else {
				open_menu_page(menu, .Main)
			}
		}
		return result
	}

	if menu.page == .Bindings && menu.binding_waiting {
		if input.back {
			menu.binding_waiting = false
			return result
		}
		if menu.binding_device == .Keyboard && input.pressed_key == .KEY_NULL do return result
		if menu.binding_device == .Controller && input.pressed_gamepad_button == .UNKNOWN do return result
		rebound := false
		if menu.binding_device == .Keyboard {
			rebound = try_rebind_keyboard_action(
				&settings.bindings,
				menu.binding_action,
				input.pressed_key,
			)
		} else {
			rebound = try_rebind_controller_action(
				&settings.controller_bindings,
				menu.binding_action,
				input.pressed_gamepad_button,
			)
		}
		if rebound {
			menu.binding_waiting = false
			result.settings_changed = true
		} else {
			menu.binding_conflict_seconds = 2
		}
		return result
	}

	if input.back {
		switch menu.page {
		case .Main:
		case .First_Run, .Settings:
			open_menu_page(menu, .Main)
		case .Bindings:
			open_menu_page(menu, .Settings)
		case .How_To_Play:
		}
		return result
	}
	if input.menu_up_pressed do move_menu_selection(menu, -1)
	if input.menu_down_pressed do move_menu_selection(menu, 1)
	if menu.page == .Bindings && (input.menu_left_pressed || input.menu_right_pressed) {
		menu.binding_device = .Controller if menu.binding_device == .Keyboard else .Keyboard
		return result
	}

	if menu.page == .Settings && (input.menu_left_pressed || input.menu_right_pressed) {
		delta := -1 if input.menu_left_pressed else 1
		changed, display_changed := adjust_setting(
			settings,
			Settings_Menu_Item(menu.selected),
			delta,
		)
		result.settings_changed = changed
		result.display_changed = display_changed
		return result
	}

	if !input.confirm do return result
	switch menu.page {
	case .Main:
		switch Main_Menu_Item(menu.selected) {
		case .Start_Game:
			if settings.tutorial_complete {
				result.start_campaign = true
			} else {
				open_menu_page(menu, .First_Run)
			}
		case .Tutorial:     result.start_tutorial = true
		case .How_To_Play:
			open_menu_page(menu, .How_To_Play)
			menu.help_page = 0
		case .Settings:     open_menu_page(menu, .Settings)
		case .Replay_Story: result.replay_story = true
		case .Quit:         result.quit_requested = true
		}
	case .First_Run:
		switch First_Run_Item(menu.selected) {
		case .Tutorial: result.start_tutorial = true
		case .Campaign:
			settings.tutorial_complete = true
			result.settings_changed = true
			result.start_campaign = true
		case .Back: open_menu_page(menu, .Main)
		}
	case .Settings:
		item := Settings_Menu_Item(menu.selected)
		if item == .Bindings {
			open_menu_page(menu, .Bindings)
		} else if item == .Back {
			open_menu_page(menu, .Main)
		} else {
			changed, display_changed := adjust_setting(settings, item, 1)
			result.settings_changed = changed
			result.display_changed = display_changed
		}
	case .Bindings:
		if menu.selected == len(Input_Action) {
			open_menu_page(menu, .Settings)
		} else {
			menu.binding_action = Input_Action(menu.selected)
			menu.binding_waiting = true
		}
	case .How_To_Play:
	}
	return result
}
