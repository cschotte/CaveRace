package caverace

import "core:testing"

@(test)
pause_toggle_freezes_gameplay_and_clears_queued_input_test :: proc(t: ^testing.T) {
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
	update_game(
		&game,
		Game_Input {pause_pressed = true},
		GAMEPLAY_TICK_SECONDS * 4,
	)
	testing.expect(t, game.paused)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, game.gameplay, expected_gameplay)

	update_game(
		&game,
		Game_Input {move_right = true, space_pressed = true},
		1.0,
	)
	testing.expect(t, game.paused)
	testing.expect_value(t, game.gameplay, expected_gameplay)

	update_game(
		&game,
		Game_Input {pause_pressed = true},
		GAMEPLAY_TICK_SECONDS * 4,
	)
	testing.expect(t, !game.paused)
	testing.expect_value(t, game.screen, App_Screen.Playing)
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
	testing.expect(t, !game.paused)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}

@(test)
pause_is_available_only_during_active_gameplay_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Dead

	update_game(&game, Game_Input {pause_pressed = true}, 0)
	testing.expect(t, !game.paused)
	testing.expect_value(t, game.screen, App_Screen.Playing)

	update_game(&game, Game_Input {back = true, pause_pressed = true}, 0)
	testing.expect(t, !game.paused)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}

@(test)
new_game_and_main_menu_clear_pause_state_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_new_game(&game)
	game.gameplay.state = .Playing
	update_game(&game, Game_Input {pause_pressed = true}, 0)
	if !testing.expect(t, game.paused) do return

	show_main_menu(&game)
	testing.expect(t, !game.paused)
	game.paused = true
	start_new_game(&game)
	testing.expect(t, !game.paused)
}
