package caverace

import "core:fmt"
import rl "vendor:raylib"

MUSIC_CROSSFADE_SECONDS :: 0.45

// Application owns platform resources and allocated paths for the complete
// process lifetime managed by run_application.
Application :: struct {
	assets:        Assets,
	game:          Game,
	resource_root: string,
	settings_path: string,
	audio_ready:   bool,
	active_music:  Maybe(Music_Cue),
	outgoing_music: Maybe(Music_Cue),
	music_fade_elapsed: f64,
	input_poll:    Input_Poll_State,
	canvas:        rl.RenderTexture2D,
	applied_display_mode: Display_Mode,
	quit_requested: bool,
	controller_connected: bool,
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

	settings := default_settings()
	if path, path_ok := settings_path(); path_ok {
		app.settings_path = path
		if loaded, loaded_ok := load_settings_from_path(path); loaded_ok {
			settings = loaded
		}
	}
	defer delete(app.settings_path)
	init_game(&app.game, options.cheats_enabled, &settings)

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE)
	if !rl.IsWindowReady() {
		fmt.eprintln("Failed to initialize the game window.")
		return false
	}
	defer rl.CloseWindow()
	app.canvas = rl.LoadRenderTexture(WINDOW_WIDTH, WINDOW_HEIGHT)
	if !rl.IsRenderTextureValid(app.canvas) {
		fmt.eprintln("Failed to create the fixed-resolution presentation canvas.")
		return false
	}
	defer rl.UnloadRenderTexture(app.canvas)

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
	apply_display_settings(&app)
	if app.audio_ready do apply_sfx_volume(&app.assets, app.game.settings.sfx_volume)

	// Slow mode reduces rendering work only. Gameplay always advances at the
	// fixed GAMEPLAY_TICK_HZ rate through its accumulator.
	rl.SetTargetFPS(target_render_fps(options))

	for !rl.WindowShouldClose() && !app.quit_requested {
		input := poll_game_input(
			app.game.settings.bindings,
			app.game.settings.controller_bindings,
			&app.input_poll,
		)
		if input.controller_connected != app.controller_connected {
			app.controller_connected = input.controller_connected
			if input.controller_connected {
				fmt.println("Controller detected: ", rl.GetGamepadName(GAMEPAD_INDEX))
			} else {
				fmt.println("Controller disconnected; keyboard prompts restored.")
			}
		}
		frame_seconds := f64(rl.GetFrameTime())
		input, frame_seconds = prepare_application_frame(
			&app.game,
			input,
			frame_seconds,
			rl.IsWindowFocused(),
		)
		input.intro_music_controls_timing = app.audio_ready
		input.intro_music_finished = intro_music_stream_finished(&app)
		previous_input_device := app.game.last_input_device
		update_result := update_application(&app, input, frame_seconds)
		if app.game.last_input_device != previous_input_device {
			if app.game.last_input_device == .Controller {
				fmt.println("Input prompts switched to controller.")
			} else {
				fmt.println("Input prompts switched to keyboard.")
			}
		}
		if app.audio_ready {
			update_game_music(&app, frame_seconds)
			play_frame_audio(&app.assets, &update_result)
			apply_frame_rumble(&app, update_result.rumble)
		}

		draw_application_frame(&app)
	}

	return true
}

presentation_rectangle :: proc(screen_width, screen_height: int) -> rl.Rectangle {
	scale_x := f32(screen_width) / WINDOW_WIDTH
	scale_y := f32(screen_height) / WINDOW_HEIGHT
	scale := min(scale_x, scale_y)
	width := f32(WINDOW_WIDTH) * scale
	height := f32(WINDOW_HEIGHT) * scale
	return {
		x      = (f32(screen_width) - width) / 2,
		y      = (f32(screen_height) - height) / 2,
		width  = width,
		height = height,
	}
}

draw_application_frame :: proc(app: ^Application) {
	rl.BeginTextureMode(app.canvas)
		rl.ClearBackground(rl.BLACK)
		draw_game(&app.game, &app.assets)
	rl.EndTextureMode()

	destination := presentation_rectangle(int(rl.GetScreenWidth()), int(rl.GetScreenHeight()))
	shake_x, shake_y := screen_shake_offset(app.game.feedback, app.game.settings.screen_shake)
	presentation_scale := destination.width / WINDOW_WIDTH
	destination.x += f32(shake_x) * presentation_scale
	destination.y += f32(shake_y) * presentation_scale
	source := rl.Rectangle {
		width  = WINDOW_WIDTH,
		height = -WINDOW_HEIGHT,
	}
	rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(app.canvas.texture, source, destination, {}, 0, rl.WHITE)
	rl.EndDrawing()
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
	case .Tutorial:
		return .Cave_A
	case .Playing:
		switch game.gameplay.state {
		case .Won:
			return .Level_Complete
		case .Game_Won:
			return .You_Won
		case .Game_Over:
			return .Game_Over
		case .Load_Level, .Playing, .Dead, .Load_Failed:
			switch level_metadata(game.gameplay.level_index).music_band {
			case .A: return .Cave_A
			case .B: return .Cave_B
			case .C: return .Cave_C
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
	     .You_Won, .Game_Over:
		return false
	}
	return false
}

music_gain_for_game :: proc(game: ^Game) -> f32 {
	if game_is_paused(game) do return 0.5
	return 1
}

music_crossfade_gains :: proc(elapsed_seconds: f64) -> (incoming, outgoing: f32) {
	progress := f32(clamp(elapsed_seconds / MUSIC_CROSSFADE_SECONDS, 0, 1))
	return progress, 1 - progress
}

// intro_music_stream_finished reports a natural end only after the expected
// finite cue has actually been started. This prevents the first frame, cue
// changes, and silent startup from being mistaken for completed playback.
intro_music_stream_finished :: proc(app: ^Application) -> bool {
	if !app.audio_ready || app.game.screen != .Intro ||
	   app.game.front_end.transition_active {
		return false
	}
	active, active_ok := app.active_music.?
	if !active_ok || active != music_cue_for_game(&app.game) do return false
	return !rl.IsMusicStreamPlaying(app.assets.music[active])
}

// update_game_music switches tracks only when the requested cue changes and
// services the active raylib stream every frame.
update_game_music :: proc(app: ^Application, frame_seconds: f64) {
	desired := music_cue_for_game(&app.game)
	if active, ok := app.active_music.?; ok {
		if active != desired {
			if outgoing, outgoing_ok := app.outgoing_music.?; outgoing_ok {
				rl.StopMusicStream(app.assets.music[outgoing])
			}
			app.outgoing_music = active
			app.music_fade_elapsed = 0
			app.assets.music[desired].looping = music_cue_loops(desired)
			rl.SetMusicVolume(app.assets.music[desired], 0)
			rl.PlayMusicStream(app.assets.music[desired])
			app.active_music = desired
		}
	} else {
		app.assets.music[desired].looping = music_cue_loops(desired)
		rl.PlayMusicStream(app.assets.music[desired])
		app.active_music = desired
	}

	active, _ := app.active_music.?
	base_gain := music_gain_for_game(&app.game) *
		f32(clamp(app.game.settings.music_volume, 0, 100)) / 100
	if outgoing, ok := app.outgoing_music.?; ok {
		app.music_fade_elapsed += clamp(frame_seconds, 0, MAX_FRAME_DELTA_SECONDS)
		incoming_gain, outgoing_gain := music_crossfade_gains(app.music_fade_elapsed)
		rl.SetMusicVolume(app.assets.music[active], base_gain * incoming_gain)
		rl.SetMusicVolume(app.assets.music[outgoing], base_gain * outgoing_gain)
		rl.UpdateMusicStream(app.assets.music[active])
		rl.UpdateMusicStream(app.assets.music[outgoing])
		if app.music_fade_elapsed >= MUSIC_CROSSFADE_SECONDS {
			rl.StopMusicStream(app.assets.music[outgoing])
			app.outgoing_music = {}
		}
	} else {
		rl.SetMusicVolume(app.assets.music[active], base_gain)
		rl.UpdateMusicStream(app.assets.music[active])
	}
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
	if result.settings_changed {
		if len(app.settings_path) > 0 && !save_settings_to_path(app.settings_path, app.game.settings) {
			fmt.eprintln("Could not save settings; play can continue.")
		}
		if app.audio_ready do apply_sfx_volume(&app.assets, app.game.settings.sfx_volume)
	}
	if result.display_changed do apply_display_settings(app)
	if result.quit_requested do app.quit_requested = true
}

// prepare_application_frame opens the gameplay pause overlay on focus loss and
// suppresses input/time so recovery cannot replay actions or catch up.
prepare_application_frame :: proc(
	game: ^Game,
	input: Game_Input,
	frame_seconds: f64,
	window_focused: bool,
) -> (Game_Input, f64) {
	if window_focused do return input, frame_seconds
	game.gameplay.tick_state.input = {}
	if game.settings.pause_on_focus_loss {
		open_game_pause(game)
		return {}, 0
	}
	return {}, frame_seconds
}

supported_window_scale :: proc(requested, monitor_width, monitor_height: int) -> int {
	requested_scale := clamp(requested, 1, 3)
	for scale := requested_scale; scale >= 1; scale -= 1 {
		if WINDOW_WIDTH * scale <= monitor_width && WINDOW_HEIGHT * scale <= monitor_height {
			return scale
		}
	}
	return 1
}

apply_display_settings :: proc(app: ^Application) {
	desired := app.game.settings.display_mode
	if desired != app.applied_display_mode {
		rl.ToggleBorderlessWindowed()
		app.applied_display_mode = desired
	}
	if desired == .Windowed {
		monitor := rl.GetCurrentMonitor()
		scale := supported_window_scale(
			app.game.settings.window_scale,
			int(rl.GetMonitorWidth(monitor)),
			int(rl.GetMonitorHeight(monitor)),
		)
		rl.SetWindowSize(i32(WINDOW_WIDTH * scale), i32(WINDOW_HEIGHT * scale))
	}
}

apply_sfx_volume :: proc(assets: ^Assets, volume_percent: int) {
	volume := f32(clamp(volume_percent, 0, 100)) / 100
	for &sound in assets.sounds.bomb do rl.SetSoundVolume(sound, volume)
	rl.SetSoundVolume(assets.sounds.item, volume)
	rl.SetSoundVolume(assets.sounds.hit, volume)
	rl.SetSoundVolume(assets.sounds.squish, volume)
	rl.SetSoundVolume(assets.sounds.ticking, volume)
	rl.SetSoundVolume(assets.sounds.menu, volume)
	rl.SetSoundVolume(assets.sounds.record, volume)
}

limited_audio_request_count :: proc(requested, maximum: int) -> int {
	return clamp(requested, 0, maximum)
}

// play_frame_audio translates gameplay events from the latest update into
// raylib sound calls after game state has advanced.
play_frame_audio :: proc(assets: ^Assets, result: ^Game_Update_Result) {
	for _ in 0 ..< limited_audio_request_count(result.gameplay.ticks.ticking_requests, 1) {
		if rl.IsSoundPlaying(assets.sounds.ticking) do break
		rl.PlaySound(assets.sounds.ticking)
	}
	for _ in 0 ..< limited_audio_request_count(result.gameplay.ticks.contact_hit_requests, 1) {
		if rl.IsSoundPlaying(assets.sounds.hit) do break
		rl.PlaySound(assets.sounds.hit)
	}
	for sound_index in 0 ..< limited_audio_request_count(result.gameplay.ticks.explosion_sound_count, MAX_BOMBS) {
		bomb_sound := result.gameplay.ticks.explosion_sound_indices[sound_index]
		assert(bomb_sound < BOMB_SOUND_COUNT)
		if !rl.IsSoundPlaying(assets.sounds.bomb[bomb_sound]) {
			rl.PlaySound(assets.sounds.bomb[bomb_sound])
		}
	}
	for _ in 0 ..< limited_audio_request_count(result.gameplay.ticks.squish_requests, 1) {
		if rl.IsSoundPlaying(assets.sounds.squish) do break
		rl.PlaySound(assets.sounds.squish)
	}
	for _ in 0 ..< limited_audio_request_count(result.gameplay.ticks.item_sound_requests, 1) {
		if rl.IsSoundPlaying(assets.sounds.item) do break
		rl.PlaySound(assets.sounds.item)
	}
	if result.menu_sound_requests > 0 && !rl.IsSoundPlaying(assets.sounds.menu) {
		rl.PlaySound(assets.sounds.menu)
	}
	if result.record_sound_requests > 0 {
		rl.StopSound(assets.sounds.record)
		rl.PlaySound(assets.sounds.record)
	}
}

rumble_parameters :: proc(event: Rumble_Event) -> (left, right, duration: f32) {
	switch event {
	case .None:      return 0, 0, 0
	case .Light:     return 0.12, 0.18, 0.08
	case .Damage:    return 0.55, 0.75, 0.18
	case .Explosion: return 0.35, 0.55, 0.12
	case .Victory:   return 0.35, 0.65, 0.45
	}
	return 0, 0, 0
}

apply_frame_rumble :: proc(app: ^Application, event: Rumble_Event) {
	if event == .None || !app.controller_connected ||
	   !app.game.settings.controller_rumble {
		return
	}
	left, right, duration := rumble_parameters(event)
	rl.SetGamepadVibration(GAMEPAD_INDEX, left, right, duration)
}

// target_render_fps selects the normal or legacy slow-mode presentation rate;
// gameplay tick frequency is intentionally unaffected.
target_render_fps :: proc(options: Launch_Options) -> i32 {
	if options.slow_mode do return SLOW_RENDER_FPS
	return TARGET_RENDER_FPS
}
