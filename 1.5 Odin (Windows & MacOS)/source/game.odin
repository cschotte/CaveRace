package caverace

// App_Screen identifies the top-level update and render route currently owned
// by Game.
App_Screen :: enum {
	Menu,
	Playing,
	High_Scores,
}

// Game owns all screen-level state. Filesystem paths and platform resources are
// owned by Application and are deliberately absent from this domain state.
Game :: struct {
	screen:          App_Screen,
	menu:            Menu_State,
	gameplay:        Gameplay,
	high_scores:     High_Score_State,
	feedback:        Game_Feedback,
	cheats_enabled:  bool,
	quit_requested:  bool,
}

// Game_Update_Result carries transient effects and explicit I/O requests to the
// application boundary. The game update itself never touches the filesystem.
Game_Update_Result :: struct {
	menu_selection_changed:     bool,
	gameplay:                   Gameplay_Frame_Result,
	load_level_requested:       bool,
	save_high_scores_requested: bool,
}

// init_game establishes platform-independent screen, gameplay, and high-score
// state. Application supplies only the gameplay policy it parsed at launch.
init_game :: proc(game: ^Game, cheats_enabled := false) {
	game^ = Game {
		screen         = .Menu,
		menu           = {selected = .Start_Game},
		cheats_enabled = cheats_enabled,
	}
	init_gameplay(&game.gameplay)
	init_high_scores(&game.high_scores)
}

// start_new_game resets all run progress and enters the Playing screen when the
// menu confirms Start Game.
start_new_game :: proc(game: ^Game) {
	init_gameplay(&game.gameplay)
	game.screen = .Playing
}

// update_game routes one frame to the active screen, performs state transitions,
// and returns transient effects plus any work for the application boundary.
update_game :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Game_Update_Result {
	result: Game_Update_Result
	advance_game_feedback(&game.feedback, frame_seconds)
	previous_screen := game.screen
	previous_gameplay_state := game.gameplay.state

	switch game.screen {
	case .Menu:
		menu_result := update_menu(&game.menu, input, frame_seconds)
		result.menu_selection_changed = menu_result.selection_changed

		if selected, ok := menu_result.confirmed.?; ok {
			switch selected {
			case .Start_Game:
				start_new_game(game)
			case .High_Scores:
				open_high_scores(&game.high_scores, nil)
				game.screen = .High_Scores
			case .Quit:
				game.quit_requested = true
			}
		}
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
			game.screen = .Menu
		} else if completed_run, ok := result.gameplay.completed_run.?; ok {
			open_high_scores(&game.high_scores, completed_run)
			game.screen = .High_Scores
		}
	case .High_Scores:
		high_score_result := update_high_scores(&game.high_scores, input)
		result.save_high_scores_requested = high_score_result.table_changed
		if high_score_result.back_requested {
			game.screen = .Menu
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
