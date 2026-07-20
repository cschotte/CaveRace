package caverace

import "core:testing"

@(test)
pause_freezes_gameplay_and_clears_input_on_both_edges_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	game.gameplay.player.energy = PLAYER_START_ENERGY
	game.gameplay.tick_state = {
		accumulator_seconds = GAMEPLAY_TICK_SECONDS / 2,
		action_step         = 7,
		input = {
			move_right   = true,
			bomb_pending = true,
		},
	}

	expected_gameplay := game.gameplay
	expected_gameplay.tick_state.input = {}
	update_game(&game, Game_Input {pause_pressed = true}, GAMEPLAY_TICK_SECONDS * 4)
	testing.expect(t, game_is_paused(&game))
	testing.expect_value(t, music_gain_for_game(&game), f32(0.5))
	testing.expect_value(t, game.gameplay, expected_gameplay)

	update_game(&game, Game_Input {move_right = true, space_pressed = true}, 10.0)
	testing.expect(t, game_is_paused(&game))
	testing.expect_value(t, game.gameplay, expected_gameplay)

	update_game(&game, Game_Input {pause_pressed = true}, GAMEPLAY_TICK_SECONDS * 4)
	testing.expect(t, !game_is_paused(&game))
	testing.expect_value(t, music_gain_for_game(&game), f32(1))
	testing.expect_value(t, game.gameplay, expected_gameplay)
	update_game(&game, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.gameplay.tick_state.action_step, 8)
}

@(test)
escape_returns_active_gameplay_to_main_menu_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing

	update_game(&game, Game_Input {back = true}, 0)
	testing.expect(t, !game_is_paused(&game))
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}

@(test)
pause_is_available_only_during_active_gameplay_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Dead

	update_game(&game, Game_Input {pause_pressed = true}, 0)
	testing.expect(t, !game_is_paused(&game))
	testing.expect_value(t, game.screen, App_Screen.Playing)
}

@(test)
new_game_and_main_menu_clear_pause_state_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	open_game_pause(&game)
	if !testing.expect(t, game_is_paused(&game)) do return

	show_main_menu(&game)
	testing.expect(t, !game_is_paused(&game))
	game.pause = {open = true}
	start_new_game(&game)
	testing.expect(t, !game_is_paused(&game))
}

@(test)
pause_restart_requires_confirmation_and_preserves_run_progress_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	game.gameplay.player.lives = 2
	game.gameplay.player.energy = 1
	game.gameplay.player.score = 375
	open_game_pause(&game)

	update_game(&game, Game_Input {menu_down_pressed = true}, 0)
	testing.expect_value(t, game.pause.selected, Pause_Menu_Item.Restart_Level)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.pause.confirmation, Pause_Confirmation.Restart_Level)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing)

	result := update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect(t, !game_is_paused(&game))
	testing.expect(t, result.load_level_requested)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, game.gameplay.player.lives, 2)
	testing.expect_value(t, game.gameplay.player.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, game.gameplay.player.score, 375)
}

@(test)
pause_main_menu_requires_confirmation_and_cancel_is_safe_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	open_game_pause(&game)
	move_pause_selection(&game.pause, -1)
	testing.expect_value(t, game.pause.selected, Pause_Menu_Item.Main_Menu)

	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.pause.confirmation, Pause_Confirmation.Main_Menu)
	update_game(&game, Game_Input {back = true}, 0)
	testing.expect(t, game_is_paused(&game))
	testing.expect_value(t, game.pause.confirmation, Pause_Confirmation.None)
	testing.expect_value(t, game.screen, App_Screen.Playing)

	update_game(&game, Game_Input {confirm = true}, 0)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect(t, !game_is_paused(&game))
}

@(test)
pause_menu_accepts_controller_independent_semantic_edges_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	open_game_pause(&game)

	update_game(&game, Game_Input {menu_down_pressed = true}, 0)
	update_game(&game, Game_Input {menu_up_pressed = true}, 0)
	testing.expect_value(t, game.pause.selected, Pause_Menu_Item.Resume)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect(t, !game_is_paused(&game))
}
