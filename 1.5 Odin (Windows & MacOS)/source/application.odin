package caverace

import "core:fmt"
import rl "vendor:raylib"

Application :: struct {
	assets: Assets,
	game:   Game,
}

run_application :: proc(options: Launch_Options) -> bool {
	app: Application
	init_game(&app.game, options)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !rl.IsWindowReady() {
		fmt.eprintln("Failed to initialize the game window.")
		return false
	}
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	if !rl.IsAudioDeviceReady() {
		fmt.eprintln("Failed to initialize the audio device.")
		return false
	}
	defer rl.CloseAudioDevice()

	assets_loaded := load_assets(&app.assets)
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
	// fixed SIMULATION_HZ rate through its accumulator.
	rl.SetTargetFPS(target_render_fps(options))

	for !app.game.quit_requested && !rl.WindowShouldClose() {
		input := poll_game_input()
		frame_seconds := f64(rl.GetFrameTime())
		update_result := update_game(&app.game, input, frame_seconds)
		if update_result.menu_selection_changed {
			rl.PlaySound(app.assets.sounds.menu)
		}
		if update_result.gameplay.simulation.ticking_requested {
			rl.PlaySound(app.assets.sounds.ticking)
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			draw_game(&app.game, &app.assets, input.mouse)
		rl.EndDrawing()
	}

	return true
}

target_render_fps :: proc(options: Launch_Options) -> i32 {
	if options.slow_mode do return SLOW_RENDER_FPS
	return TARGET_RENDER_FPS
}
