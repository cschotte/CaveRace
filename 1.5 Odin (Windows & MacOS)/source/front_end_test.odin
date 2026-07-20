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

enter_intro_for_test :: proc(game: ^Game) {
	update_game(game, Game_Input {presentation_music_finished = true}, 0)
}

expect_music_cue :: proc(t: ^testing.T, game: ^Game, expected: Music_Cue) {
	actual, ok := music_cue_for_game(game).?
	testing.expect(t, ok)
	if ok do testing.expect_value(t, actual, expected)
}

@(test)
intro_panel_timing_matches_packaged_track_lengths_test :: proc(t: ^testing.T) {
	expected_seconds := [7]f64 {
		8.222063,
		10.444218,
		11.110884,
		7.481315,
		10.221995,
		14.81449,
		10.370159,
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
main_menu_keeps_stable_title_art_for_navigation_test :: proc(t: ^testing.T) {
	front_end: Front_End_State
	begin_main_menu(&front_end)
	testing.expect_value(t, front_end.image_index, MAIN_MENU_FIRST_IMAGE)
	testing.expect(t, !front_end.transition_active)
	visual_image, alpha := front_end_visual(front_end)
	testing.expect_value(t, visual_image, MAIN_MENU_FIRST_IMAGE)
	testing.expect_value(t, alpha, f32(1))
}

@(test)
escape_skips_intro_and_menu_requires_explicit_confirm_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	testing.expect_value(t, game.screen, App_Screen.Branding)
	enter_intro_for_test(&game)
	testing.expect_value(t, game.screen, App_Screen.Intro)
	testing.expect_value(t, game.front_end.image_index, INTRO_FIRST_IMAGE)

	update_game(&game, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)

	game.settings.tutorial_complete = true
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
}

@(test)
space_skips_one_intro_panel_and_last_panel_enters_menu_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	enter_intro_for_test(&game)

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
	enter_intro_for_test(&game)
	for _ in 0 ..< 2000 {
		if game.screen != .Intro do break
		update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	}

	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)
}

@(test)
finished_music_advances_without_user_and_manual_skips_remain_available_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	enter_intro_for_test(&game)

	update_game(&game, Game_Input {presentation_music_finished = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Intro)
	testing.expect_value(t, game.front_end.image_index, INTRO_FIRST_IMAGE + 1)

	// Confirm skips the next individual panel even though its music is active.
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.front_end.image_index, INTRO_FIRST_IMAGE + 2)

	// Back remains the complete-story skip from any panel.
	update_game(&game, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.front_end.image_index, MAIN_MENU_FIRST_IMAGE)
}

@(test)
active_music_not_wall_clock_controls_automatic_advance_test :: proc(t: ^testing.T) {
	front_end: Front_End_State
	begin_intro(&front_end)
	for _ in 0 ..< 300 {
		advance_intro(&front_end, MAX_FRAME_DELTA_SECONDS, false, true)
	}
	testing.expect_value(t, front_end.image_index, INTRO_FIRST_IMAGE)
	testing.expect(t, !front_end.transition_active)

	completed := advance_intro(&front_end, 0, true, true)
	testing.expect(t, !completed)
	testing.expect_value(t, front_end.image_index, INTRO_FIRST_IMAGE + 1)
	testing.expect(t, front_end.transition_active)
}

@(test)
every_story_panel_has_a_distinct_bounded_effect_profile_test :: proc(t: ^testing.T) {
	for image_index in INTRO_FIRST_IMAGE ..= INTRO_LAST_IMAGE {
		testing.expect_value(
			t,
			int(story_effect_kind(image_index)),
			image_index - INTRO_FIRST_IMAGE,
		)
	}
	testing.expect_value(t, story_effect_count(12, false), 12)
	testing.expect_value(t, story_effect_count(12, true), 6)
	for step in 0 ..< 100 {
		pulse := story_effect_pulse(f64(step) / 10, step, 24, false)
		testing.expect(t, pulse >= 0 && pulse <= 1)
		testing.expect_value(t, pulse, story_effect_pulse(f64(step) / 10, step, 24, false))
	}
}

@(test)
music_cues_follow_intro_menu_level_and_outcome_state_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	expect_music_cue(t, &game, .Branding)
	enter_intro_for_test(&game)
	expect_music_cue(t, &game, .Intro_Eldora)
	game.front_end.image_index = INTRO_LAST_IMAGE
	expect_music_cue(t, &game, .Intro_Protect)

	show_main_menu(&game)
	expect_music_cue(t, &game, .Menu)
	start_new_game(&game)

	_, gameplay_has_music := music_cue_for_game(&game).?
	testing.expect(t, !gameplay_has_music)

	game.gameplay.state = .Won
	game.gameplay.level_index = LEVEL_COUNT - 2
	expect_music_cue(t, &game, .Level_Complete)
	game.gameplay.state = .Game_Won
	game.gameplay.level_index = LEVEL_COUNT - 1
	expect_music_cue(t, &game, .You_Won)
	game.gameplay.state = .Game_Over
	expect_music_cue(t, &game, .Game_Over)

	testing.expect(t, music_cue_loops(.Menu))
	testing.expect(t, !music_cue_loops(.Branding))
	testing.expect(t, !music_cue_loops(.Intro_Eldora))
	testing.expect(t, !music_cue_loops(.Level_Complete))
}
