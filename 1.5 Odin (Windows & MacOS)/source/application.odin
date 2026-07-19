package caverace

import "core:fmt"
import rl "vendor:raylib"

// Application owns platform resources and allocated paths for the complete
// process lifetime managed by run_application.
Application :: struct {
	assets:        Assets,
	game:          Game,
	resource_root: string,
	audio_ready:   bool,
	active_music:  Maybe(Music_Cue),
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

	init_game(&app.game, options.cheats_enabled)

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

	// Slow mode reduces rendering work only. Gameplay always advances at the
	// fixed GAMEPLAY_TICK_HZ rate through its accumulator.
	rl.SetTargetFPS(target_render_fps(options))

	for !rl.WindowShouldClose() {
		input := poll_game_input()
		frame_seconds := f64(rl.GetFrameTime())
		input, frame_seconds = prepare_application_frame(
			&app.game,
			input,
			frame_seconds,
			rl.IsWindowFocused(),
		)
		update_result := update_application(&app, input, frame_seconds)
		if app.audio_ready {
			update_game_music(&app)
			play_frame_audio(&app.assets, &update_result)
		}

		rl.BeginDrawing()
			rl.ClearBackground(rl.BLACK)
			draw_game(&app.game, &app.assets)
		rl.EndDrawing()
	}

	return true
}

// music_cue_for_game maps the current platform-independent state to one active
// streamed track. Intro panels use matching tracks, cave music rotates by
// level, and completing the tenth level receives the victory cue.
music_cue_for_game :: proc(game: ^Game) -> Music_Cue {
	switch game.screen {
	case .Intro:
		assert(game.front_end.image_index >= INTRO_FIRST_IMAGE)
		assert(game.front_end.image_index <= INTRO_LAST_IMAGE)
		return Music_Cue(int(Music_Cue.Intro_Space) + game.front_end.image_index)
	case .Main_Menu:
		return .Main_Menu
	case .Playing:
		switch game.gameplay.state {
		case .Won:
			if game.gameplay.level_index == LEVEL_COUNT - 1 do return .Victory
			return .Level_Complete
		case .Game_Over:
			return .Game_Over
		case .Load_Level, .Playing, .Dead, .Load_Failed:
			switch game.gameplay.level_index % 3 {
			case 0: return .Cave_A
			case 1: return .Cave_B
			case 2: return .Cave_C
			}
		}
	}
	return .Main_Menu
}

// music_cue_loops distinguishes ambient screen/gameplay songs from finite
// story and outcome cues.
music_cue_loops :: proc(cue: Music_Cue) -> bool {
	switch cue {
	case .Main_Menu, .Cave_A, .Cave_B, .Cave_C:
		return true
	case .Intro_Space, .Intro_Eldora, .Intro_Mining, .Intro_Aliens,
	     .Intro_Defense, .Intro_Hero, .Intro_Bombs, .Level_Complete,
	     .Victory, .Game_Over:
		return false
	}
	return false
}

// update_game_music switches tracks only when the requested cue changes and
// services the active raylib stream every frame.
update_game_music :: proc(app: ^Application) {
	desired := music_cue_for_game(&app.game)
	if active, ok := app.active_music.?; ok {
		if active == desired {
			rl.UpdateMusicStream(app.assets.music[active])
			return
		}
		rl.StopMusicStream(app.assets.music[active])
	}

	app.assets.music[desired].looping = music_cue_loops(desired)
	rl.PlayMusicStream(app.assets.music[desired])
	app.active_music = desired
	rl.UpdateMusicStream(app.assets.music[desired])
}

// update_application advances platform-independent game state, then fulfills
// any resulting I/O requests before the current frame is presented.
update_application :: proc(
	app: ^Application,
	input: Game_Input,
	frame_seconds: f64,
) -> Game_Update_Result {
	result := update_game(&app.game, input, frame_seconds)
	process_game_requests(app, &result)
	return result
}

// process_game_requests is the single boundary where pure game-routing output
// may load a level using the Application-owned resource root.
process_game_requests :: proc(app: ^Application, result: ^Game_Update_Result) {
	if result.load_level_requested {
		load_gameplay_level(&app.game.gameplay, app.resource_root)
	}
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

// play_frame_audio translates gameplay events from the latest update into
// raylib sound calls after game state has advanced.
play_frame_audio :: proc(assets: ^Assets, result: ^Game_Update_Result) {
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
