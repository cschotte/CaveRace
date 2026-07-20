package caverace

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import rl "vendor:raylib"

SETTINGS_DIRECTORY_NAME :: "CaveRace"
SETTINGS_FILE_NAME      :: "settings.json"

Persisted_Settings :: struct {
	version:               int,
	music_volume:          int,
	sfx_volume:            int,
	display_mode:          int,
	window_scale:          int,
	reduced_flashes:       bool,
	screen_shake:          int,
	high_contrast_preview: bool,
	pause_on_focus_loss:    bool,
	difficulty:            int,
	bindings:              [Input_Action]int,
	controller_bindings:   [Input_Action]int,
	tutorial_complete:     bool,
	standard_best_run_score: int,
	standard_best_cave:      int,
	assisted_best_run_score: int,
	assisted_best_cave:      int,
}

settings_to_document :: proc(settings: Settings) -> Persisted_Settings {
	document := Persisted_Settings {
		version                  = SETTINGS_VERSION,
		music_volume             = settings.music_volume,
		sfx_volume               = settings.sfx_volume,
		display_mode             = int(settings.display_mode),
		window_scale             = settings.window_scale,
		reduced_flashes          = settings.reduced_flashes,
		screen_shake             = settings.screen_shake,
		high_contrast_preview    = settings.high_contrast_preview,
		pause_on_focus_loss      = settings.pause_on_focus_loss,
		difficulty               = int(settings.difficulty),
		tutorial_complete        = settings.tutorial_complete,
		standard_best_run_score = settings.records.standard.best_run_score,
		standard_best_cave      = settings.records.standard.best_cave,
		assisted_best_run_score = settings.records.assisted.best_run_score,
		assisted_best_cave      = settings.records.assisted.best_cave,
	}
	for key, action_index in settings.bindings {
		document.bindings[Input_Action(action_index)] = int(key)
	}
	for button, action_index in settings.controller_bindings {
		document.controller_bindings[Input_Action(action_index)] = int(button)
	}
	return document
}

// settings_from_document validates each section independently. A malformed
// scalar or records namespace reverts only that value; bindings revert as one
// conflict-sensitive unit.
settings_from_document :: proc(document: Persisted_Settings) -> (Settings, bool) {
	settings := default_settings()
	if document.version != SETTINGS_VERSION do return settings, false

	if document.music_volume >= 0 && document.music_volume <= 100 {
		settings.music_volume = document.music_volume
	}
	if document.sfx_volume >= 0 && document.sfx_volume <= 100 {
		settings.sfx_volume = document.sfx_volume
	}
	if document.display_mode >= 0 && document.display_mode < len(Display_Mode) {
		settings.display_mode = Display_Mode(document.display_mode)
	}
	if document.window_scale >= 1 && document.window_scale <= 3 {
		settings.window_scale = document.window_scale
	}
	settings.reduced_flashes = document.reduced_flashes
	if document.screen_shake >= 0 && document.screen_shake <= 100 {
		settings.screen_shake = document.screen_shake
	}
	settings.high_contrast_preview = document.high_contrast_preview
	settings.pause_on_focus_loss = document.pause_on_focus_loss
	if document.difficulty >= 0 && document.difficulty < len(Difficulty_Profile) {
		settings.difficulty = Difficulty_Profile(document.difficulty)
	}

	bindings: Keyboard_Bindings
	for key_value, action_index in document.bindings {
		bindings[Input_Action(action_index)] = rl.KeyboardKey(key_value)
	}
	if keyboard_bindings_are_valid(bindings) do settings.bindings = bindings
	controller_bindings: Controller_Bindings
	for button_value, action_index in document.controller_bindings {
		controller_bindings[Input_Action(action_index)] = rl.GamepadButton(button_value)
	}
	if controller_bindings_are_valid(controller_bindings) {
		settings.controller_bindings = controller_bindings
	}

	settings.tutorial_complete = document.tutorial_complete
	if document.standard_best_run_score >= 0 &&
	   document.standard_best_cave >= 0 && document.standard_best_cave <= LEVEL_COUNT {
		settings.records.standard = {
			best_run_score = document.standard_best_run_score,
			best_cave      = document.standard_best_cave,
		}
	}
	if document.assisted_best_run_score >= 0 &&
	   document.assisted_best_cave >= 0 && document.assisted_best_cave <= LEVEL_COUNT {
		settings.records.assisted = {
			best_run_score = document.assisted_best_run_score,
			best_cave      = document.assisted_best_cave,
		}
	}
	return settings, true
}

settings_path :: proc(allocator := context.allocator) -> (string, bool) {
	config_root, config_error := os.user_config_dir(allocator)
	if config_error != nil do return "", false
	defer delete(config_root, allocator)
	path, path_error := filepath.join(
		{config_root, SETTINGS_DIRECTORY_NAME, SETTINGS_FILE_NAME},
		allocator,
	)
	return path, path_error == nil
}

load_settings_from_path :: proc(path: string) -> (Settings, bool) {
	settings := default_settings()
	data, read_error := os.read_entire_file_from_path(path, context.allocator)
	if read_error != nil do return settings, false
	defer delete(data)
	document: Persisted_Settings
	if json.unmarshal(data, &document) != nil do return settings, false
	return settings_from_document(document)
}

// save_settings_to_path writes, flushes and syncs a sibling before one atomic
// replace. A failed write leaves the previous document untouched.
save_settings_to_path :: proc(path: string, settings: Settings) -> bool {
	directory := filepath.dir(path)
	if !os.exists(directory) {
		if directory_error := os.make_directory_all(directory); directory_error != nil {
			fmt.eprintln("Could not create settings directory:", directory_error)
			return false
		}
	}

	document := settings_to_document(settings)
	data, marshal_error := json.marshal(document)
	if marshal_error != nil {
		fmt.eprintln("Could not encode settings:", marshal_error)
		return false
	}
	defer delete(data)

	temporary_path, path_error := filepath.join({directory, "settings.tmp"})
	if path_error != nil do return false
	defer delete(temporary_path)
	file, create_error := os.create(temporary_path)
	if create_error != nil {
		fmt.eprintln("Could not create temporary settings file:", create_error)
		return false
	}
	written, write_error := os.write(file, data)
	flush_error := os.flush(file)
	sync_error := os.sync(file)
	close_error := os.close(file)
	if write_error != nil || written != len(data) || flush_error != nil ||
	   sync_error != nil || close_error != nil {
		fmt.eprintln("Could not flush temporary settings file:", write_error, flush_error, sync_error, close_error)
		_ = os.remove(temporary_path)
		return false
	}
	if rename_error := os.rename(temporary_path, path); rename_error != nil {
		fmt.eprintln("Could not replace settings file:", rename_error)
		_ = os.remove(temporary_path)
		return false
	}
	return true
}
