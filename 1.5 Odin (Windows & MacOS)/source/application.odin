package caverace

import "core:fmt"
import rl "vendor:raylib"

// Application owns platform resources and borrowed-path backing storage for the
// complete process lifetime managed by run_application.
Application :: struct {
	assets:                  Assets,
	game:                    Game,
	high_score_storage_path: string,
	resource_root:           string,
	audio_ready:             bool,
}

// run_application owns platform startup, resource lifetimes, and the main
// update/draw loop; main calls it once after parsing launch options.
run_application :: proc(options: Launch_Options) -> bool {
	app: Application
	resource_root, resource_root_ok := resolve_resource_root()
	if !resource_root_ok {
		fmt.eprintln("Could not locate the CaveRace media directory beside the executable.")
		return false
	}
	app.resource_root = resource_root
	defer delete(app.resource_root)

	storage_path, storage_path_error := high_score_storage_path()
	if storage_path_error != nil {
		fmt.eprintln("Could not resolve the high-score storage path; scores will not persist.")
	} else {
		app.high_score_storage_path = storage_path
		defer delete(app.high_score_storage_path)
	}
	init_game(&app.game, options, app.high_score_storage_path, app.resource_root)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !rl.IsWindowReady() {
		fmt.eprintln("Failed to initialize the game window.")
		return false
	}
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	app.audio_ready = rl.IsAudioDeviceReady()
	defer {
		if app.audio_ready do rl.CloseAudioDevice()
	}
	if !app.audio_ready {
		fmt.eprintln("Could not initialize audio; continuing without sound.")
	}

	assets_loaded := load_assets(&app.assets, app.resource_root, app.audio_ready)
	defer unload_assets(&app.assets)
	if !assets_loaded {
		fmt.eprintln("Failed to load one or more game assets.")
		return false
	}

	// Disable the default exit key (ESC) to allow custom handling
	rl.SetExitKey(.KEY_NULL)

	// Hide the mouse cursor since we are drawing our own
	rl.HideCursor()

	// Slow mode reduces rendering work only. Gameplay always advances at the
	// fixed GAMEPLAY_TICK_HZ rate through its accumulator.
	rl.SetTargetFPS(target_render_fps(options))

	for application_should_continue(&app.game, rl.WindowShouldClose()) {
		input := poll_game_input()
		frame_seconds := f64(rl.GetFrameTime())
		input, frame_seconds = prepare_application_frame(
			&app.game,
			input,
			frame_seconds,
			rl.IsWindowFocused(),
		)
		update_result := update_game(&app.game, input, frame_seconds)
		if app.audio_ready {
			play_frame_audio(&app.assets, &update_result)
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			draw_game(&app.game, &app.assets, input.mouse)
		rl.EndDrawing()
	}

	return true
}

// application_should_continue combines the in-game quit request with the
// native window close signal and is evaluated at the start of every frame.
application_should_continue :: proc(game: ^Game, window_should_close: bool) -> bool {
	return !game.quit_requested && !window_should_close
}

// prepare_application_frame suppresses input and elapsed time while focus is
// lost so returning to the window cannot replay queued actions or catch up.
prepare_application_frame :: proc(
	game: ^Game,
	input: Game_Input,
	frame_seconds: f64,
	window_focused: bool,
) -> (Game_Input, f64) {
	if window_focused do return input, frame_seconds
	// Stop held and queued actions while preserving the current gameplay state.
	game.gameplay.tick_state.input = {}
	return {}, 0
}

// play_frame_audio translates gameplay and menu events from the latest update
// into raylib sound calls after game state has advanced.
play_frame_audio :: proc(assets: ^Assets, result: ^Game_Update_Result) {
	if result.menu_selection_changed {
		rl.PlaySound(assets.sounds.menu)
	}
	if result.gameplay.ticks.ticking_requested {
		rl.PlaySound(assets.sounds.ticking)
	}
	for sound_index in 0 ..< result.gameplay.ticks.explosion_sound_count {
		bomb_sound := result.gameplay.ticks.explosion_sound_indices[sound_index]
		assert(bomb_sound < BOMB_SOUND_COUNT)
		rl.PlaySound(assets.sounds.bomb[bomb_sound])
	}
	for _ in 0 ..< result.gameplay.ticks.squish_requests {
		rl.PlaySound(assets.sounds.squish)
	}
	for _ in 0 ..< result.gameplay.ticks.item_sound_requests {
		rl.PlaySound(assets.sounds.item)
	}
}

// target_render_fps selects the normal or legacy slow-mode presentation rate;
// gameplay tick frequency is intentionally unaffected.
target_render_fps :: proc(options: Launch_Options) -> i32 {
	if options.slow_mode do return SLOW_RENDER_FPS
	return TARGET_RENDER_FPS
}
