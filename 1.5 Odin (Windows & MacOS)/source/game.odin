package caverace

App_Screen :: enum {
	Branding,
	Intro,
	Main_Menu,
	Tutorial,
	Playing,
}

Rumble_Event :: enum {
	None,
	Light,
	Damage,
	Explosion,
	Victory,
}

// Game owns all platform-independent screen, menu, settings and run state.
// Filesystem paths and raylib resources remain Application-owned.
Game :: struct {
	screen:                App_Screen,
	front_end:             Front_End_State,
	menu:                  Menu_State,
	tutorial:              Tutorial_State,
	gameplay:              Gameplay,
	settings:              Settings,
	last_input_device:     Input_Device,
	feedback:              Game_Feedback,
	effects:               Game_Effects,
	cheats_enabled:        bool,
	pause:                 Pause_State,
	debug_overlay_visible: bool,
	branding_elapsed_seconds: f64,
	// Free-running cosmetic clock for menu glow/pulse/twinkle animation only;
	// it never gates gameplay or input and is safe to ignore in tests.
	ui_clock:              f64,
}

Game_Update_Result :: struct {
	gameplay:             Gameplay_Frame_Result,
	load_level_requested: bool,
	settings_changed:     bool,
	display_changed:      bool,
	quit_requested:       bool,
	menu_sound_requests:  int,
	victory_started:      bool,
	rumble:               Rumble_Event,
}

// menu_audio_input reports whether this frame's input should trigger the
// shared menu click sound, independent of which specific action fired.
menu_audio_input :: proc(input: Game_Input) -> bool {
	return input.confirm || input.back || input.pause_pressed ||
	       input.menu_up_pressed || input.menu_down_pressed ||
	       input.menu_left_pressed || input.menu_right_pressed
}

// init_game sets up a freshly started process: applies loaded settings (or
// defaults), and starts on the branding screen. Called once at startup, never
// mid-session, since it fully overwrites game^.
init_game :: proc(
	game: ^Game,
	cheats_enabled := false,
	loaded_settings: ^Settings = nil,
) {
	settings := default_settings()
	if loaded_settings != nil do settings = loaded_settings^
	game^ = Game {
		screen         = .Branding,
		cheats_enabled = cheats_enabled,
		settings       = settings,
	}
	game.feedback.reduced_flashes = settings.reduced_flashes
	begin_intro(&game.front_end)
	begin_menu(&game.menu)
	init_gameplay(&game.gameplay, settings.difficulty)
}

// start_new_game begins a fresh campaign run, clearing leftover pause and
// cosmetic-effect state from whatever screen was active before.
start_new_game :: proc(game: ^Game) {
	init_gameplay(&game.gameplay, game.settings.difficulty)
	game.gameplay.mode = .Campaign
	game.effects = {}
	game.pause = {}
	game.screen = .Playing
}

// start_game_tutorial builds the tutorial's own in-memory level and enters it.
start_game_tutorial :: proc(game: ^Game) {
	game.gameplay.difficulty = game.settings.difficulty
	setup_tutorial_level(&game.gameplay, &game.tutorial)
	game.gameplay.mode = .Tutorial
	game.effects = {}
	game.pause = {}
	game.screen = .Tutorial
}

// show_main_menu returns to the main menu from any other screen, always
// clearing pause and cosmetic-effect state so nothing leaks in behind it.
show_main_menu :: proc(game: ^Game) {
	begin_main_menu(&game.front_end)
	begin_menu(&game.menu)
	game.pause = {}
	game.effects = {}
	game.screen = .Main_Menu
}

// complete_or_skip_tutorial marks the tutorial complete the first time it's
// called and reports whether that changed anything, so callers can save
// settings only on the actual transition rather than every call.
complete_or_skip_tutorial :: proc(game: ^Game) -> bool {
	if game.settings.tutorial_complete do return false
	game.settings.tutorial_complete = true
	return true
}

// update_game is the single per-frame entry point for all platform-independent
// state: it routes input to the active screen, advances cosmetic timers, and
// returns any filesystem/audio/quit requests for Application to fulfill. It
// never touches raylib or the filesystem directly.
update_game :: proc(game: ^Game, input: Game_Input, frame_seconds: f64) -> Game_Update_Result {
	result: Game_Update_Result
	game.last_input_device = resolve_last_input_device(
		game.last_input_device,
		input.keyboard_activity,
		input.controller_activity,
		input.controller_connected,
	)
	game.feedback.reduced_flashes = game.settings.reduced_flashes
	advance_game_feedback(&game.feedback, frame_seconds)
	advance_game_effects(&game.effects, frame_seconds)
	game.ui_clock += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
	when ODIN_DEBUG {
		if input.debug_toggle_pressed {
			game.debug_overlay_visible = !game.debug_overlay_visible
		}
	}
	previous_screen := game.screen
	previous_gameplay_state := game.gameplay.state
	previous_pause_open := game.pause.open
	menu_audio_context := previous_screen == .Main_Menu || game.pause.open

	switch game.screen {
	case .Branding:
		game.branding_elapsed_seconds += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
		if input.presentation_music_finished ||
		   (!input.presentation_music_controls_timing &&
		    game.branding_elapsed_seconds >= BRANDING_FALLBACK_SECONDS) {
			begin_intro(&game.front_end)
			game.screen = .Intro
		}
	case .Intro:
		if input.back {
			show_main_menu(game)
		} else if input.space_pressed || input.confirm {
			if skip_intro_image(&game.front_end) do show_main_menu(game)
		} else if advance_intro(
			&game.front_end,
			frame_seconds,
			input.presentation_music_finished,
			input.presentation_music_controls_timing,
		) {
			show_main_menu(game)
		}
	case .Main_Menu:
		menu_result := update_menu(&game.menu, &game.settings, input, frame_seconds)
		result.settings_changed = menu_result.settings_changed
		result.display_changed = menu_result.display_changed
		if menu_result.start_campaign {
			start_new_game(game)
			result.load_level_requested = true
		} else if menu_result.start_tutorial {
			start_game_tutorial(game)
		} else if menu_result.replay_story {
			begin_intro(&game.front_end)
			game.screen = .Intro
		} else if menu_result.quit_requested {
			result.quit_requested = true
		}
	case .Tutorial:
		if game.pause.open {
			pause_result := update_pause_menu(game, input, frame_seconds)
			result.settings_changed = pause_result.settings_changed
			result.display_changed = pause_result.display_changed
			if pause_result.restart_level {
				setup_tutorial_level(&game.gameplay, &game.tutorial)
			} else if pause_result.main_menu {
				result.settings_changed = complete_or_skip_tutorial(game)
				show_main_menu(game)
			}
		} else if input.pause_pressed {
			open_game_pause(game)
		} else if input.back {
			result.settings_changed = complete_or_skip_tutorial(game)
			show_main_menu(game)
		} else if game.tutorial.step == .Complete {
			if input.confirm {
				result.settings_changed = complete_or_skip_tutorial(game)
				start_new_game(game)
				result.load_level_requested = true
			}
		} else {
			result.gameplay = update_gameplay(
				&game.gameplay,
				input,
				frame_seconds,
				false,
			)
			advance_tutorial(&game.tutorial, &game.gameplay, result.gameplay.ticks)
			if result.gameplay.ticks.player_died {
				setup_tutorial_level(&game.gameplay, &game.tutorial)
			}
		}
	case .Playing:
		if game.pause.open {
			pause_result := update_pause_menu(game, input, frame_seconds)
			result.settings_changed = pause_result.settings_changed
			result.display_changed = pause_result.display_changed
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
		} else if previous_gameplay_state == .Game_Over &&
		          (input.confirm || input.presentation_music_finished) {
			show_main_menu(game)
		} else if previous_gameplay_state == .Game_Won &&
		          (input.confirm || input.presentation_music_finished) {
			show_main_menu(game)
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
			}
		}
	}

	request_gameplay_feedback(&game.feedback, &result.gameplay.ticks)
	if menu_audio_context && menu_audio_input(input) {
		result.menu_sound_requests = 1
	}
	if !previous_pause_open && game.pause.open do result.menu_sound_requests = 1
	result.victory_started = previous_screen == .Playing && game.screen == .Playing &&
		previous_gameplay_state != .Game_Won && game.gameplay.state == .Game_Won
	if result.victory_started {
		result.rumble = .Victory
	} else if result.gameplay.ticks.player_damaged {
		result.rumble = .Damage
	} else if result.gameplay.ticks.explosions_started > 0 {
		result.rumble = .Explosion
	} else if result.gameplay.ticks.items_collected > 0 ||
	          result.gameplay.ticks.treasures_collected > 0 {
		result.rumble = .Light
	}
	request_game_effects(
		&game.effects,
		&game.gameplay,
		&result.gameplay.ticks,
		result.victory_started,
		game.settings.reduced_flashes,
	)
	screen_changed := game.screen != previous_screen
	gameplay_state_changed := (previous_screen == .Playing || previous_screen == .Tutorial) &&
		game.screen == previous_screen && game.gameplay.state != previous_gameplay_state
	if screen_changed || gameplay_state_changed do start_transition_fade(&game.feedback)
	return result
}
