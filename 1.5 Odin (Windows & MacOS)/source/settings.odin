package caverace

SETTINGS_VERSION :: 1

Display_Mode :: enum {
	Windowed,
	Borderless,
}

Profile_Record :: struct {
	best_run_score: int,
	best_cave:      int,
}

Local_Records :: struct {
	standard: Profile_Record,
	assisted: Profile_Record,
}

Settings :: struct {
	music_volume:       int,
	sfx_volume:         int,
	display_mode:       Display_Mode,
	window_scale:       int,
	reduced_flashes:    bool,
	screen_shake:       int,
	high_contrast_preview: bool,
	pause_on_focus_loss: bool,
	difficulty:         Difficulty_Profile,
	bindings:           Keyboard_Bindings,
	controller_bindings: Controller_Bindings,
	tutorial_complete:  bool,
	records:            Local_Records,
}

default_settings :: proc() -> Settings {
	return {
		music_volume         = 80,
		sfx_volume           = 85,
		display_mode         = .Windowed,
		window_scale         = 1,
		reduced_flashes      = false,
		screen_shake         = 50,
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

record_for_profile :: proc(records: ^Local_Records, profile: Difficulty_Profile) -> ^Profile_Record {
	switch profile {
	case .Standard: return &records.standard
	case .Assisted: return &records.assisted
	}
	return &records.standard
}

difficulty_label :: proc(profile: Difficulty_Profile) -> cstring {
	if profile == .Assisted do return "ASSISTED"
	return "STANDARD"
}
