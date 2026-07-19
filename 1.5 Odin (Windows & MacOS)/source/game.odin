package caverace

App_Screen :: enum {
	Menu,
	Playing,
	High_Scores,
}

Game :: struct {
	screen:                App_Screen,
	menu:                  Menu_State,
	gameplay:              Gameplay,
	high_scores:           High_Score_State,
	feedback:              Game_Feedback,
	options:               Launch_Options,
	// Borrowed from Application for the complete Game lifetime.
	resource_root:         string,
	pending_completed_run: Maybe(Completed_Run),
	quit_requested:        bool,
}

Game_Update_Result :: struct {
	menu_selection_changed: bool,
	gameplay:               Gameplay_Frame_Result,
}

init_game :: proc(
	game: ^Game,
	options: Launch_Options,
	high_score_path: string = "",
	resource_root: string = "",
) {
	game^ = Game {
		screen        = .Menu,
		menu          = {selected = .Start_Game},
		options       = options,
		resource_root = resource_root,
	}
	init_gameplay(&game.gameplay, resource_root)
	init_high_scores(&game.high_scores, high_score_path)
}

start_new_game :: proc(game: ^Game) {
	init_gameplay(&game.gameplay, game.resource_root)
	game.pending_completed_run = nil
	game.screen = .Playing
}

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
				game.pending_completed_run = nil
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
			game.options.cheats_enabled,
		)
		if result.gameplay.back_requested {
			game.pending_completed_run = nil
			game.screen = .Menu
		} else if completed_run, ok := result.gameplay.completed_run.?; ok {
			game.pending_completed_run = completed_run
			open_high_scores(&game.high_scores, completed_run)
			game.screen = .High_Scores
		}
	case .High_Scores:
		high_score_result := update_high_scores(&game.high_scores, input)
		if high_score_result.table_changed do persist_high_scores(&game.high_scores)
		if high_score_result.back_requested {
			game.pending_completed_run = nil
			game.screen = .Menu
		}
	}

	request_simulation_feedback(&game.feedback, &result.gameplay.simulation)
	screen_changed := game.screen != previous_screen
	gameplay_state_changed := previous_screen == .Playing && game.screen == .Playing &&
		game.gameplay.state != previous_gameplay_state
	if screen_changed || gameplay_state_changed {
		start_transition_fade(&game.feedback)
	}

	return result
}

draw_game :: proc(game: ^Game, assets: ^Assets, mouse: Mouse_State) {
	switch game.screen {
	case .Menu:
		draw_menu(game.menu, assets.screens.menu, assets.screens.select)
	case .Playing:
		draw_gameplay(&game.gameplay, assets)
	case .High_Scores:
		draw_high_scores(&game.high_scores, assets.screens.highscore)
	}

	draw_mouse(mouse, assets.sprites.tools)
	draw_game_feedback(&game.feedback)
}
