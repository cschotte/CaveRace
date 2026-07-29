package caverace

import "core:testing"

pointer_at_rect_center :: proc(rect: UI_Rect) -> Pointer_Input {
	return {
		x                  = rect.x + rect.width / 2,
		y                  = rect.y + rect.height / 2,
		valid              = true,
		primary_pressed    = true,
		any_button_pressed = true,
	}
}

@(test)
test_any_mouse_button_advances_intro :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Intro
	begin_intro(&game.front_end)

	update_game(
		&game,
		Game_Input {
			pointer = {valid = true, any_button_pressed = true},
			presentation_music_controls_timing = true,
		},
		0,
	)

	testing.expect_value(t, game.screen, App_Screen.Intro)
	testing.expect_value(t, game.front_end.image_index, INTRO_FIRST_IMAGE + 1)
	testing.expect(t, game.front_end.transition_active)
}

@(test)
test_any_mouse_button_finishes_intro :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Intro
	game.front_end.image_index = INTRO_LAST_IMAGE

	update_game(
		&game,
		Game_Input {
			pointer = {valid = true, any_button_pressed = true},
			presentation_music_controls_timing = true,
		},
		0,
	)

	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}

@(test)
test_mouse_activates_main_menu_item :: proc(t: ^testing.T) {
	menu: Menu_State
	begin_menu(&menu)
	settings := default_settings()
	settings.tutorial_complete = true
	rect, ok := menu_item_rect(&menu, int(Main_Menu_Item.Start_Game))
	testing.expect(t, ok)

	result := update_menu(
		&menu,
		&settings,
		Game_Input {pointer = pointer_at_rect_center(rect)},
		0,
	)
	testing.expect(t, result.start_campaign)
}

@(test)
test_mouse_adjusts_setting_in_both_directions :: proc(t: ^testing.T) {
	menu: Menu_State
	begin_menu(&menu)
	open_menu_page(&menu, .Settings)
	settings := default_settings()
	settings.music_volume = 50
	item_index := int(Settings_Menu_Item.Music)
	left, right, ok := settings_adjustment_rects(&menu, item_index)
	testing.expect(t, ok)

	result := update_menu(
		&menu,
		&settings,
		Game_Input {pointer = pointer_at_rect_center(left)},
		0,
	)
	testing.expect(t, result.settings_changed)
	testing.expect_value(t, settings.music_volume, 45)

	result = update_menu(
		&menu,
		&settings,
		Game_Input {pointer = pointer_at_rect_center(right)},
		0,
	)
	testing.expect(t, result.settings_changed)
	testing.expect_value(t, settings.music_volume, 50)
}

@(test)
test_mouse_opens_pause_submenu :: proc(t: ^testing.T) {
	game: Game
	game.pause = {open = true}
	game.settings = default_settings()
	begin_menu(&game.menu)
	rect, ok := pause_item_rect(int(Pause_Menu_Item.Settings))
	testing.expect(t, ok)

	update_pause_menu(
		&game,
		Game_Input {pointer = pointer_at_rect_center(rect)},
		0,
	)
	testing.expect_value(t, game.pause.page, Pause_Page.Settings)
	testing.expect_value(t, game.menu.page, Menu_Page.Settings)
}

@(test)
test_mouse_handles_pause_confirmation :: proc(t: ^testing.T) {
	confirm_rect, cancel_rect := pause_confirmation_rects()

	cancel_game: Game
	cancel_game.pause = {open = true, confirmation = .Restart_Level}
	update_pause_menu(
		&cancel_game,
		Game_Input {pointer = pointer_at_rect_center(cancel_rect)},
		0,
	)
	testing.expect(t, cancel_game.pause.open)
	testing.expect_value(t, cancel_game.pause.confirmation, Pause_Confirmation.None)

	confirm_game: Game
	confirm_game.pause = {open = true, confirmation = .Restart_Level}
	result := update_pause_menu(
		&confirm_game,
		Game_Input {pointer = pointer_at_rect_center(confirm_rect)},
		0,
	)
	testing.expect(t, result.restart_level)
	testing.expect(t, !confirm_game.pause.open)
}
