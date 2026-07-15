package caverace

import rl "vendor:raylib"

Application :: struct {
	assets: Assets,
	game:   Game,
}

run_application :: proc(options: Launch_Options) {
	app: Application
	init_game(&app.game, options)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.InitAudioDevice()
	defer rl.CloseAudioDevice()

	rl.SetTargetFPS(TARGET_FPS)

	load_assets(&app.assets)
	defer unload_assets(&app.assets)

	for !rl.WindowShouldClose() {
		// Update game loop
		update_game(&app.game)

		// Draw game loop
		rl.BeginDrawing()
			rl.ClearBackground(rl.RAYWHITE)
			draw_game(&app.game, &app.assets)
		rl.EndDrawing()
	}
}
