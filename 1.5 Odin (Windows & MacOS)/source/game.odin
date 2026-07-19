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
	game.screen = .Playing
}

// show_main_menu skips or completes the story and resets the looping title
// presentation whenever play returns to the front end.
show_main_menu :: proc(game: ^Game) {
	begin_main_menu(&game.front_end)
	game.screen = .Main_Menu
}

// update_game routes one frame to the active screen, performs state transitions,
// and returns transient effects plus any work for the application boundary.
update_game :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Game_Update_Result {
	result: Game_Update_Result
	advance_game_feedback(&game.feedback, frame_seconds)
	previous_screen := game.screen
	previous_gameplay_state := game.gameplay.state

	switch game.screen {
	case .Intro:
		if input.back || advance_intro(&game.front_end, frame_seconds) {
			show_main_menu(game)
		}
	case .Main_Menu:
		advance_main_menu(&game.front_end, frame_seconds)
		if main_menu_start_requested(input) do start_new_game(game)
	case .Playing:
		result.gameplay = update_gameplay(
			&game.gameplay,
			input,
			frame_seconds,
			game.cheats_enabled,
		)
		if !result.gameplay.back_requested && previous_gameplay_state == .Load_Level {
			result.load_level_requested = true
		}
		if result.gameplay.back_requested {
			show_main_menu(game)
		} else if previous_gameplay_state == .Game_Over && main_menu_start_requested(input) {
			show_main_menu(game)
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
