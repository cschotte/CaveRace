package caverace

SETTINGS_VERSION :: 4

Display_Mode :: enum {
	Windowed,
	Borderless,
}

Settings :: struct {
	music_volume:       int,
	sfx_volume:         int,
	display_mode:       Display_Mode,
	window_scale:       int,
	reduced_flashes:    bool,
	screen_shake:       int,
	controller_rumble:  bool,
	high_contrast_preview: bool,
	pause_on_focus_loss: bool,
	difficulty:         Difficulty_Profile,
	bindings:           Keyboard_Bindings,
	controller_bindings: Controller_Bindings,
	tutorial_complete:  bool,
}

default_settings :: proc() -> Settings {
	return {
		music_volume         = 80,
		sfx_volume           = 85,
		display_mode         = .Windowed,
		window_scale         = 1,
		reduced_flashes      = false,
		screen_shake         = 50,
		controller_rumble    = true,
		high_contrast_preview = false,
		pause_on_focus_loss  = true,
		difficulty           = .Standard,
		bindings             = default_keyboard_bindings(),
		controller_bindings  = default_controller_bindings(),
	}
}

settings_are_valid :: proc(settings: Settings) -> bool {
	return settings.music_volume >= 0 && settings.music_volume <= 100 &&
	       settings.sfx_volume >= 0 && settings.sfx_volume <= 100 &&
	       int(settings.display_mode) >= 0 && int(settings.display_mode) < len(Display_Mode) &&
	       settings.window_scale >= 1 && settings.window_scale <= 3 &&
	       settings.screen_shake >= 0 && settings.screen_shake <= 100 &&
	       int(settings.difficulty) >= 0 && int(settings.difficulty) < len(Difficulty_Profile) &&
	       keyboard_bindings_are_valid(settings.bindings) &&
	       controller_bindings_are_valid(settings.controller_bindings)
}

difficulty_label :: proc(profile: Difficulty_Profile) -> cstring {
	if profile == .Assisted do return "ASSISTED"
	return "STANDARD"
}
