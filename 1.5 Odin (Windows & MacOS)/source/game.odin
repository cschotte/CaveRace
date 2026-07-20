package caverace

// App_Screen identifies the top-level update and render route currently owned
// by Game.
App_Screen :: enum {
	Intro,
	Main_Menu,
	Playing,
}

// Game owns all screen-level state. Filesystem paths and platform resources are
// owned by Application and are deliberately absent from this domain state.
Game :: struct {
	screen:          App_Screen,
	front_end:       Front_End_State,
	gameplay:        Gameplay,
	feedback:        Game_Feedback,
	cheats_enabled:  bool,
	pause:           Pause_State,
	debug_overlay_visible: bool,
}

// Game_Update_Result carries transient effects and explicit I/O requests to the
// application boundary. The game update itself never touches the filesystem.
Game_Update_Result :: struct {
	gameplay:             Gameplay_Frame_Result,
	load_level_requested: bool,
}

// init_game establishes platform-independent front-end and gameplay state.
// Application supplies only the gameplay policy it parsed at launch.
init_game :: proc(game: ^Game, cheats_enabled := false) {
	game^ = Game {
		screen         = .Intro,
		cheats_enabled = cheats_enabled,
	}
	begin_intro(&game.front_end)
	init_gameplay(&game.gameplay)
}

// start_new_game resets all run progress and enters Playing after any start
// input on the main menu.
start_new_game :: proc(game: ^Game) {
	init_gameplay(&game.gameplay)
	game.pause = {}
	game.screen = .Playing
}

// show_main_menu skips or completes the story and resets the looping title
// presentation whenever play returns to the front end.
show_main_menu :: proc(game: ^Game) {
	begin_main_menu(&game.front_end)
	game.pause = {}
	game.screen = .Main_Menu
}

// update_game routes one frame to the active screen, performs state transitions,
// and returns transient effects plus any work for the application boundary.
update_game :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Game_Update_Result {
	result: Game_Update_Result
	advance_game_feedback(&game.feedback, frame_seconds)
	when ODIN_DEBUG {
		if input.debug_toggle_pressed {
			game.debug_overlay_visible = !game.debug_overlay_visible
		}
	}
	previous_screen := game.screen
	previous_gameplay_state := game.gameplay.state

	switch game.screen {
	case .Intro:
		if input.back {
			show_main_menu(game)
		} else if input.space_pressed {
			if skip_intro_image(&game.front_end) do show_main_menu(game)
		} else if advance_intro(&game.front_end, frame_seconds) {
			show_main_menu(game)
		}
	case .Main_Menu:
		advance_main_menu(&game.front_end, frame_seconds)
		if main_menu_start_requested(input) do start_new_game(game)
	case .Playing:
		if game.pause.open {
			pause_result := update_pause_menu(game, input)
			if pause_result.restart_level {
				begin_level_restart(&game.gameplay)
				result.load_level_requested = true
			} else if pause_result.main_menu {
				show_main_menu(game)
			}
		} else if previous_gameplay_state == .Playing && input.pause_pressed {
			open_game_pause(game)
		} else if previous_gameplay_state == .Dead && input.restart_pressed {
			begin_level_retry(&game.gameplay)
			result.load_level_requested = true
		} else if previous_gameplay_state == .Game_Over && input.restart_pressed {
			start_new_game(game)
			result.load_level_requested = true
		} else {
			result.gameplay = update_gameplay(
				&game.gameplay,
				input,
				frame_seconds,
				game.cheats_enabled,
			)
			if !result.gameplay.back_requested && game.gameplay.state == .Load_Level {
				result.load_level_requested = true
			}
			if result.gameplay.back_requested {
				show_main_menu(game)
			} else if (previous_gameplay_state == .Game_Over ||
			           previous_gameplay_state == .Game_Won) &&
			          main_menu_start_requested(input) {
				show_main_menu(game)
			}
		}
	}

	request_gameplay_feedback(&game.feedback, &result.gameplay.ticks)
	screen_changed := game.screen != previous_screen
	gameplay_state_changed := previous_screen == .Playing && game.screen == .Playing &&
		game.gameplay.state != previous_gameplay_state
	if screen_changed || gameplay_state_changed {
		start_transition_fade(&game.feedback)
	}

	return result
}
