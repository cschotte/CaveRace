package caverace

Menu_Page :: enum {
	Main,
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

Settings_Menu_Item :: enum {
	Music,
	Sfx,
	Display_Mode,
	Window_Scale,
	Reduced_Flashes,
	Screen_Shake,
	Controller_Rumble,
	High_Contrast,
	Pause_On_Focus_Loss,
	Difficulty,
	Bindings,
	Back,
}

Menu_State :: struct {
	page:              Menu_Page,
	selected:          int,
	binding_waiting:   bool,
	binding_action:    Input_Action,
	binding_device:    Input_Device,
	binding_conflict_seconds: f64,
	// Time since the current page opened, purely for the cosmetic entrance
	// fade/slide; it never affects input handling or navigation.
	page_elapsed_seconds: f64,
}

Menu_Update_Result :: struct {
	start_campaign: bool,
	start_tutorial: bool,
	replay_story:   bool,
	quit_requested: bool,
	settings_changed: bool,
	display_changed:  bool,
}

UI_Rect :: struct {
	x, y, width, height: f32,
}

ui_rect_contains :: proc(rect: UI_Rect, pointer: Pointer_Input) -> bool {
	return pointer.valid && pointer.x >= rect.x && pointer.y >= rect.y &&
	       pointer.x < rect.x + rect.width && pointer.y < rect.y + rect.height
}

menu_item_rect :: proc(menu: ^Menu_State, item_index: int) -> (UI_Rect, bool) {
	if item_index < 0 || item_index >= menu_item_count(menu.page) do return {}, false
	switch menu.page {
	case .Main:
		panel_x, panel_y, panel_width, _ := main_menu_panel_geometry(menu.page_elapsed_seconds)
		y := panel_y + MAIN_MENU_LIST_TOP + i32(item_index) * 24 + main_menu_item_gap(item_index)
		return {f32(panel_x + 10), f32(y - 3), f32(panel_width - 20), 22}, true
	case .Settings, .Bindings:
		row_count := menu_item_count(menu.page)
		height := menu_narrow_panel_height(row_count)
		panel_y := WINDOW_HEIGHT - height - MENU_PANEL_BOTTOM_MARGIN
		panel_x := (WINDOW_WIDTH - MENU_NARROW_PANEL_WIDTH) / 2
		y := panel_y + MENU_PANEL_CONTENT_GAP + i32(item_index) * MENU_ROW_SPACING
		return {
			f32(panel_x + MENU_GLOW_INSET),
			f32(y - 2),
			f32(MENU_NARROW_PANEL_WIDTH - MENU_GLOW_INSET * 2),
			f32(MENU_ROW_HEIGHT),
		}, true
	case .How_To_Play:
	}
	return {}, false
}

menu_hovered_item :: proc(menu: ^Menu_State, pointer: Pointer_Input) -> (int, bool) {
	for item_index in 0 ..< menu_item_count(menu.page) {
		if rect, ok := menu_item_rect(menu, item_index); ok && ui_rect_contains(rect, pointer) {
			return item_index, true
		}
	}
	return 0, false
}

SETTINGS_DECREMENT_OFFSET :: 198
SETTINGS_INCREMENT_OFFSET :: 300
SETTINGS_CONTROL_WIDTH     :: 28
SETTINGS_VALUE_CENTER_OFFSET :: 263

settings_adjustment_rects :: proc(menu: ^Menu_State, item_index: int) -> (UI_Rect, UI_Rect, bool) {
	if menu.page != .Settings || item_index < 0 || item_index >= len(Settings_Menu_Item) {
		return {}, {}, false
	}
	item := Settings_Menu_Item(item_index)
	if item == .Bindings || item == .Back do return {}, {}, false
	row, ok := menu_item_rect(menu, item_index)
	if !ok do return {}, {}, false
	panel_x := (WINDOW_WIDTH - MENU_NARROW_PANEL_WIDTH) / 2
	left := UI_Rect {
		x = f32(panel_x + SETTINGS_DECREMENT_OFFSET),
		y = row.y,
		width = SETTINGS_CONTROL_WIDTH,
		height = row.height,
	}
	right := left
	right.x = f32(panel_x + SETTINGS_INCREMENT_OFFSET)
	return left, right, true
}

bindings_header_rect :: proc(menu: ^Menu_State) -> (UI_Rect, bool) {
	if menu.page != .Bindings do return {}, false
	height := menu_narrow_panel_height(menu_item_count(menu.page))
	panel_y := WINDOW_HEIGHT - height - MENU_PANEL_BOTTOM_MARGIN
	panel_x := (WINDOW_WIDTH - MENU_NARROW_PANEL_WIDTH) / 2
	return {f32(panel_x), f32(panel_y), MENU_NARROW_PANEL_WIDTH, 42}, true
}

begin_menu :: proc(menu: ^Menu_State) {
	menu^ = {}
}

menu_item_count :: proc(page: Menu_Page) -> int {
	switch page {
	case .Main:        return len(Main_Menu_Item)
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

// open_menu_page switches pages and resets per-page transient state (the
// selected row and any in-progress rebind), so nothing from the previous
// page's interaction leaks into the next one.
open_menu_page :: proc(menu: ^Menu_State, page: Menu_Page) {
	menu.page = page
	menu.selected = 0
	menu.binding_waiting = false
	menu.binding_conflict_seconds = 0
	menu.page_elapsed_seconds = 0
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
	case .Controller_Rumble:
		settings.controller_rumble = !settings.controller_rumble
		changed = true
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

// update_menu is the single per-frame input handler for every menu page
// (Main, Settings, Bindings, Level info). It handles rebind-
// waiting and back navigation first, then falls through to page-specific
// confirm handling, returning any settings/display/session changes to apply.
update_menu :: proc(
	menu: ^Menu_State,
	settings: ^Settings,
	input: Game_Input,
	frame_seconds: f64,
) -> Menu_Update_Result {
	result: Menu_Update_Result
	back_pressed := input.back ||
	                (input.pointer.valid && input.pointer.secondary_pressed)
	menu.binding_conflict_seconds = max(
		menu.binding_conflict_seconds - clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS),
		0,
	)
	menu.page_elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)

	if menu.page == .How_To_Play {
		if back_pressed || input.confirm ||
		   (input.pointer.valid && input.pointer.primary_pressed) {
			open_menu_page(menu, .Main)
		}
		return result
	}
	if menu.page == .Bindings && menu.binding_waiting {
		if back_pressed {
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

	if back_pressed {
		switch menu.page {
		case .Main:
		case .Settings:
			open_menu_page(menu, .Main)
		case .Bindings:
			open_menu_page(menu, .Settings)
		case .How_To_Play:
		}
		return result
	}

	if input.pointer.moved {
		if hovered, ok := menu_hovered_item(menu, input.pointer); ok {
			menu.selected = hovered
		}
	}
	if menu.page == .Bindings && input.pointer.primary_pressed {
		if header, ok := bindings_header_rect(menu); ok && ui_rect_contains(header, input.pointer) {
			menu.binding_device = .Controller if menu.binding_device == .Keyboard else .Keyboard
			return result
		}
	}
	if menu.page == .Settings && (input.pointer.primary_pressed || input.pointer.wheel != 0) {
		if hovered, ok := menu_hovered_item(menu, input.pointer); ok {
			menu.selected = hovered
			item := Settings_Menu_Item(hovered)
			if item != .Bindings && item != .Back {
				delta := 0
				if input.pointer.wheel != 0 {
					delta = 1 if input.pointer.wheel > 0 else -1
				} else if left, right, has_controls := settings_adjustment_rects(menu, hovered); has_controls {
					if ui_rect_contains(left, input.pointer) do delta = -1
					if ui_rect_contains(right, input.pointer) do delta = 1
				}
				if delta != 0 {
					changed, display_changed := adjust_setting(settings, item, delta)
					result.settings_changed = changed
					result.display_changed = display_changed
					return result
				}
			}
		}
	}
	if menu.page != .Settings && input.pointer.wheel != 0 {
		move_menu_selection(menu, -1 if input.pointer.wheel > 0 else 1)
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

	confirm_pressed := input.confirm
	if input.pointer.primary_pressed {
		if hovered, ok := menu_hovered_item(menu, input.pointer); ok {
			menu.selected = hovered
			confirm_pressed = true
		}
	}
	if !confirm_pressed do return result
	switch menu.page {
	case .Main:
		switch Main_Menu_Item(menu.selected) {
		case .Start_Game:   result.start_campaign = true
		case .Tutorial:     result.start_tutorial = true
		case .How_To_Play:
			open_menu_page(menu, .How_To_Play)
		case .Settings:     open_menu_page(menu, .Settings)
		case .Replay_Story: result.replay_story = true
		case .Quit:         result.quit_requested = true
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
