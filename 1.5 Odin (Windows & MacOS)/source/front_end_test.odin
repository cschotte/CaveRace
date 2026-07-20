package caverace

import "core:testing"

advance_intro_for_test :: proc(front_end: ^Front_End_State, seconds: f64) -> bool {
	remaining := seconds
	completed := false
	for remaining > 0 {
		step := min(remaining, MAX_FRAME_DELTA_SECONDS)
		completed = advance_intro(front_end, step)
		remaining -= step
	}
	return completed
}

@(test)
intro_panel_timing_matches_packaged_track_lengths_test :: proc(t: ^testing.T) {
	expected_seconds := [7]f64 {
		59.3,
		48.992,
		44.928,
		53.68,
		43.4226666666667,
		39.3093333333333,
		40.0866666666667,
	}
	for expected, panel_index in expected_seconds {
		testing.expect_value(t, intro_image_seconds(panel_index), expected)
	}
}

@(test)
intro_advances_zero_through_six_then_completes_test :: proc(t: ^testing.T) {
	front_end: Front_End_State
	begin_intro(&front_end)

	for expected_image in INTRO_FIRST_IMAGE ..= INTRO_LAST_IMAGE {
		testing.expect_value(t, front_end.image_index, expected_image)
		completed := advance_intro_for_test(
			&front_end,
			intro_image_seconds(expected_image),
		)
		testing.expect_value(t, completed, expected_image == INTRO_LAST_IMAGE)
		if expected_image < INTRO_LAST_IMAGE {
			testing.expect(t, front_end.transition_active)
			visual_image, alpha := front_end_visual(front_end)
			testing.expect_value(t, visual_image, expected_image)
			testing.expect_value(t, alpha, f32(1))

			advance_intro(&front_end, FRONT_END_TRANSITION_SECONDS / 2)
			visual_image, alpha = front_end_visual(front_end)
			testing.expect_value(t, visual_image, expected_image + 1)
			testing.expect_value(t, alpha, f32(0))

			advance_intro(&front_end, FRONT_END_TRANSITION_SECONDS / 2)
			testing.expect(t, !front_end.transition_active)
		}
	}
}

@(test)
main_menu_alternates_seven_and_eight_every_five_seconds_test :: proc(t: ^testing.T) {
	front_end: Front_End_State
	begin_main_menu(&front_end)
	testing.expect_value(t, front_end.image_index, MAIN_MENU_FIRST_IMAGE)

	for _ in 0 ..< int(MAIN_MENU_IMAGE_SECONDS / MAX_FRAME_DELTA_SECONDS) {
		advance_main_menu(&front_end, MAX_FRAME_DELTA_SECONDS)
	}
	testing.expect_value(t, front_end.image_index, MAIN_MENU_LAST_IMAGE)
	testing.expect(t, front_end.transition_active)
	visual_image, alpha := front_end_visual(front_end)
	testing.expect_value(t, visual_image, MAIN_MENU_FIRST_IMAGE)
	testing.expect_value(t, alpha, f32(1))

	advance_main_menu(&front_end, FRONT_END_TRANSITION_SECONDS / 2)
	visual_image, alpha = front_end_visual(front_end)
	testing.expect_value(t, visual_image, MAIN_MENU_LAST_IMAGE)
	testing.expect_value(t, alpha, f32(0))
	advance_main_menu(&front_end, FRONT_END_TRANSITION_SECONDS / 2)
	testing.expect(t, !front_end.transition_active)

	for _ in 0 ..< int(MAIN_MENU_IMAGE_SECONDS / MAX_FRAME_DELTA_SECONDS) {
		advance_main_menu(&front_end, MAX_FRAME_DELTA_SECONDS)
	}
	testing.expect_value(t, front_end.image_index, MAIN_MENU_FIRST_IMAGE)
}

@(test)
escape_skips_intro_and_any_main_menu_input_starts_game_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	testing.expect_value(t, game.screen, App_Screen.Intro)
	testing.expect_value(t, game.front_end.image_index, INTRO_FIRST_IMAGE)

	update_game(&game, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)

	update_game(&game, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
}

@(test)
space_skips_one_intro_panel_and_last_panel_enters_menu_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)

	for expected_image in INTRO_FIRST_IMAGE + 1 ..= INTRO_LAST_IMAGE {
		update_game(&game, Game_Input {space_pressed = true}, 0)
		testing.expect_value(t, game.screen, App_Screen.Intro)
		testing.expect_value(t, game.front_end.image_index, expected_image)
	}

	update_game(&game, Game_Input {space_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)
}

@(test)
completed_intro_routes_to_main_menu_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	for _ in 0 ..< 2000 {
		if game.screen != .Intro do break
		update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	}

	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)
}

@(test)
music_cues_follow_intro_menu_level_and_outcome_state_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Intro_Space)
	game.front_end.image_index = INTRO_LAST_IMAGE
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Intro_Bombs)

	show_main_menu(&game)
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Main_Menu)
	start_new_game(&game)

	game.gameplay.level_index = 0
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Cave_A)
	game.gameplay.level_index = 3
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Cave_B)
	game.gameplay.level_index = 7
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Cave_C)

	game.gameplay.state = .Won
	game.gameplay.level_index = LEVEL_COUNT - 2
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Level_Complete)
	game.gameplay.state = .Game_Won
	game.gameplay.level_index = LEVEL_COUNT - 1
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.You_Won)
	game.gameplay.state = .Game_Over
	testing.expect_value(t, music_cue_for_game(&game), Music_Cue.Game_Over)

	testing.expect(t, music_cue_loops(.Main_Menu))
	testing.expect(t, music_cue_loops(.Cave_A))
	testing.expect(t, !music_cue_loops(.Intro_Space))
	testing.expect(t, !music_cue_loops(.Level_Complete))
}
