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

	// Disable the default exit key (ESC) to allow custom handling
	rl.SetExitKey(.KEY_NULL)

	// Hide the mouse cursor since we are drawing our own
	rl.HideCursor()

	rl.InitAudioDevice()
	if !rl.IsAudioDeviceReady() {
		fmt.eprintln("Failed to initialize the audio device.")
		return false
	}
	defer rl.CloseAudioDevice()

	rl.SetTargetFPS(TARGET_FPS)

	assets_loaded := load_assets(&app.assets)
	defer unload_assets(&app.assets)
	if !assets_loaded {
		fmt.eprintln("Failed to load one or more game assets.")
		return false
	}

	for !app.game.quit_requested && !rl.WindowShouldClose() {
		input := poll_game_input()
		update_game(&app.game, input)

		rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			draw_game(&app.game, &app.assets, input.pointer)
		rl.EndDrawing()
	}

	return true
}
