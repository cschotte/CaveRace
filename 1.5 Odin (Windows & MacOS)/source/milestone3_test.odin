package caverace

import "core:os"
import "core:path/filepath"
import "core:testing"
import rl "vendor:raylib"

@(test)
milestone3_profiles_match_documented_rules_test :: proc(t: ^testing.T) {
	standard := gameplay_tuning(.Standard)
	assisted := gameplay_tuning(.Assisted)
	testing.expect_value(t, standard.enemy_contact_damage, 2)
	testing.expect_value(t, standard.contact_grace_ticks, 45)
	testing.expect_value(t, standard.blast_damage, PLAYER_MAX_ENERGY)
	testing.expect_value(t, standard.bomb_danger_preview_ticks, 36)
	testing.expect_value(t, assisted.enemy_contact_damage, 1)
	testing.expect_value(t, assisted.contact_grace_ticks, 60)
	testing.expect_value(t, assisted.blast_damage, 4)
	testing.expect_value(t, assisted.blast_grace_ticks, 60)
	testing.expect_value(t, assisted.bomb_danger_preview_ticks, BOMB_FUSE_TICKS)
}

@(test)
assisted_explosion_deals_four_energy_only_once_during_grace_test :: proc(t: ^testing.T) {
	position := Grid_Position {4, 4}
	gameplay := open_gameplay_at(position)
	gameplay.difficulty = .Assisted
	gameplay.player.energy = PLAYER_MAX_ENERGY
	bomb := Bomb_State {active = true, position = position, power = 1}
	gameplay.explosions[0] = build_explosion_state(&bomb)

	first: Gameplay_Tick_Result
	apply_active_explosions_to_entities(&gameplay, &first)
	testing.expect_value(t, gameplay.player.energy, PLAYER_MAX_ENERGY - 4)
	testing.expect_value(t, gameplay.player.blast_grace_ticks, 60)
	testing.expect_value(t, gameplay.player.contact_grace_ticks, 60)
	testing.expect(t, first.player_damaged)

	second: Gameplay_Tick_Result
	apply_active_explosions_to_entities(&gameplay, &second)
	testing.expect_value(t, gameplay.player.energy, PLAYER_MAX_ENERGY - 4)
	testing.expect(t, !second.player_damaged)
}

@(test)
bindings_reject_conflicts_and_device_disconnect_falls_back_test :: proc(t: ^testing.T) {
	bindings := default_keyboard_bindings()
	testing.expect(t, keyboard_bindings_are_valid(bindings))
	testing.expect(t, !try_rebind_keyboard_action(&bindings, .Bomb, bindings[.Move_Up]))
	testing.expect(t, !try_rebind_keyboard_action(&bindings, .Bomb, .UP))
	testing.expect_value(t, bindings[.Bomb], rl.KeyboardKey.SPACE)
	testing.expect(t, try_rebind_keyboard_action(&bindings, .Bomb, .F))
	testing.expect_value(t, action_prompt(.Bomb, .Keyboard, bindings), cstring("F"))
	testing.expect_value(t, action_prompt(.Bomb, .Controller, bindings), cstring("A"))
	controller := default_controller_bindings()
	testing.expect(t, controller_bindings_are_valid(controller))
	testing.expect(t, !try_rebind_controller_action(&controller, .Pause, controller[.Restart]))
	testing.expect(t, !try_rebind_controller_action(&controller, .Bomb, .RIGHT_FACE_RIGHT))
	testing.expect(t, try_rebind_controller_action(&controller, .Bomb, .RIGHT_FACE_UP))
	testing.expect_value(
		t,
		action_prompt(.Bomb, .Controller, bindings, &controller),
		cstring("Y"),
	)

	device := resolve_last_input_device(.Keyboard, false, true, true)
	testing.expect_value(t, device, Input_Device.Controller)
	device = resolve_last_input_device(device, false, false, false)
	testing.expect_value(t, device, Input_Device.Keyboard)
}

@(test)
menu_navigation_wraps_and_explicit_confirm_routes_every_page_test :: proc(t: ^testing.T) {
	settings := default_settings()
	settings.tutorial_complete = true
	menu: Menu_State
	begin_menu(&menu)
	update_menu(&menu, &settings, Game_Input {menu_up_pressed = true}, 0)
	testing.expect_value(t, menu.selected, len(Main_Menu_Item) - 1)
	quit := update_menu(&menu, &settings, Game_Input {confirm = true}, 0)
	testing.expect(t, quit.quit_requested)

	begin_menu(&menu)
	menu.selected = int(Main_Menu_Item.How_To_Play)
	update_menu(&menu, &settings, Game_Input {confirm = true}, 0)
	testing.expect_value(t, menu.page, Menu_Page.How_To_Play)
	update_menu(&menu, &settings, Game_Input {confirm = true}, 0)
	testing.expect_value(t, menu.help_page, 1)
	update_menu(&menu, &settings, Game_Input {back = true}, 0)
	testing.expect_value(t, menu.page, Menu_Page.Main)

	menu.selected = int(Main_Menu_Item.Settings)
	update_menu(&menu, &settings, Game_Input {confirm = true}, 0)
	testing.expect_value(t, menu.page, Menu_Page.Settings)
	menu.selected = int(Settings_Menu_Item.Difficulty)
	changed := update_menu(&menu, &settings, Game_Input {menu_right_pressed = true}, 0)
	testing.expect(t, changed.settings_changed)
	testing.expect_value(t, settings.difficulty, Difficulty_Profile.Assisted)
}

@(test)
first_run_tutorial_can_be_started_skipped_and_replayed_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	show_main_menu(&game)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.menu.page, Menu_Page.First_Run)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Tutorial)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing)
	testing.expect_value(t, game.tutorial.step, Tutorial_Step.Move)

	result := update_game(&game, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect(t, game.settings.tutorial_complete)
	testing.expect(t, result.settings_changed)

	game.menu.selected = int(Main_Menu_Item.Tutorial)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Tutorial)
}

@(test)
settings_document_validates_sections_and_keeps_profile_namespaces_test :: proc(t: ^testing.T) {
	settings := default_settings()
	settings.music_volume = 35
	settings.difficulty = .Assisted
	settings.records.standard = {best_run_score = 900, best_cave = 4}
	settings.records.assisted = {best_run_score = 700, best_cave = 6}
	document := settings_to_document(settings)
	document.music_volume = 500
	document.bindings[.Bomb] = document.bindings[.Move_Up]
	loaded, ok := settings_from_document(document)
	testing.expect(t, ok)
	testing.expect_value(t, loaded.music_volume, default_settings().music_volume)
	testing.expect_value(t, loaded.difficulty, Difficulty_Profile.Assisted)
	testing.expect_value(t, loaded.bindings, default_keyboard_bindings())
	testing.expect_value(t, loaded.records.standard.best_run_score, 900)
	testing.expect_value(t, loaded.records.assisted.best_run_score, 700)
	testing.expect(t, record_for_profile(&loaded.records, .Standard) !=
	                  record_for_profile(&loaded.records, .Assisted))

	document.version = SETTINGS_VERSION - 1
	old, old_ok := settings_from_document(document)
	testing.expect(t, !old_ok)
	testing.expect_value(t, old, default_settings())
}

@(test)
settings_save_is_atomic_and_corruption_falls_back_test :: proc(t: ^testing.T) {
	directory, directory_error := os.make_directory_temp(
		"",
		"caverace-m3-settings-*",
		context.allocator,
	)
	if !testing.expect(t, directory_error == nil) do return
	defer {
		_ = os.remove_all(directory)
		delete(directory)
	}
	path, path_error := filepath.join({directory, SETTINGS_FILE_NAME})
	temporary, temporary_error := filepath.join({directory, "settings.tmp"})
	if !testing.expect(t, path_error == nil && temporary_error == nil) do return
	defer {
		delete(path)
		delete(temporary)
	}

	settings := default_settings()
	settings.music_volume = 25
	settings.window_scale = 3
	settings.tutorial_complete = true
	settings.controller_bindings[.Bomb] = .RIGHT_FACE_UP
	testing.expect(t, save_settings_to_path(path, settings))
	testing.expect(t, !os.exists(temporary))
	loaded, loaded_ok := load_settings_from_path(path)
	testing.expect(t, loaded_ok)
	testing.expect_value(t, loaded, settings)

	testing.expect(t, os.write_entire_file(path, "{broken") == nil)
	fallback, corrupt_ok := load_settings_from_path(path)
	testing.expect(t, !corrupt_ok)
	testing.expect_value(t, fallback, default_settings())
}

@(test)
display_scale_fits_monitor_and_canvas_letterboxes_test :: proc(t: ^testing.T) {
	testing.expect_value(t, supported_window_scale(3, 1920, 1200), 3)
	testing.expect_value(t, supported_window_scale(3, 1280, 800), 2)
	testing.expect_value(t, supported_window_scale(2, 800, 600), 1)
	rect := presentation_rectangle(1920, 1080)
	testing.expect_value(t, rect.width, f32(1728))
	testing.expect_value(t, rect.height, f32(1080))
	testing.expect_value(t, rect.x, f32(96))
}

@(test)
focus_policy_and_reduced_flashes_are_applied_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	game.settings.pause_on_focus_loss = false
	_, seconds := prepare_application_frame(&game, Game_Input {move_right = true}, 0.1, false)
	testing.expect_value(t, seconds, f64(0.1))
	testing.expect(t, !game.pause.open)

	feedback := Game_Feedback {reduced_flashes = true}
	request_gameplay_feedback(&feedback, &Gameplay_Tick_Result {items_collected = 1})
	testing.expect_value(t, feedback.flash, Feedback_Flash.None)
	request_gameplay_feedback(&feedback, &Gameplay_Tick_Result {player_damaged = true})
	testing.expect_value(t, feedback.flash, Feedback_Flash.None)
}
