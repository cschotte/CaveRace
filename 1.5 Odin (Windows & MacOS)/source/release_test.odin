package caverace

import "core:os"
import "core:path/filepath"
import "core:testing"

// Verifies resource discovery prefers packaged files, then the repository
// development layout, using isolated temporary directories.
@(test)
resource_root_finds_packaged_and_development_layouts_test :: proc(t: ^testing.T) {
	temporary_directory, directory_error := os.make_directory_temp(
		"",
		"caverace-resources-*",
		context.allocator,
	)
	if !testing.expect(t, directory_error == nil) do return
	defer {
		_ = os.remove_all(temporary_directory)
		delete(temporary_directory)
	}

	project, project_error := filepath.join({temporary_directory, "project"})
	build, build_error := filepath.join({project, "build"})
	source, source_error := filepath.join({project, "source"})
	source_media, source_media_error := filepath.join(
		{source, RESOURCE_MEDIA_DIRECTORY, "screens"},
	)
	working, working_error := filepath.join({temporary_directory, "working"})
	if !testing.expect(
		t,
		project_error == nil && build_error == nil && source_error == nil &&
		source_media_error == nil && working_error == nil,
	) {
		return
	}
	defer {
		delete(project)
		delete(build)
		delete(source)
		delete(source_media)
		delete(working)
	}
	if !testing.expect(t, os.make_directory_all(build) == nil) do return
	if !testing.expect(t, os.make_directory_all(source_media) == nil) do return
	if !testing.expect(t, os.make_directory_all(working) == nil) do return
	source_marker, source_marker_error := filepath.join({source_media, "game.png"})
	if !testing.expect(t, source_marker_error == nil) do return
	defer delete(source_marker)
	if !testing.expect(t, os.write_entire_file(source_marker, "") == nil) do return

	root, root_ok := find_resource_root_from(build, working)
	if testing.expect(t, root_ok) {
		testing.expect_value(t, root, source)
		delete(root)
	}

	packaged_media, packaged_media_error := filepath.join(
		{build, RESOURCE_MEDIA_DIRECTORY, "screens"},
	)
	if !testing.expect(t, packaged_media_error == nil) do return
	defer delete(packaged_media)
	if !testing.expect(t, os.make_directory_all(packaged_media) == nil) do return
	packaged_marker, packaged_marker_error := filepath.join({packaged_media, "game.png"})
	if !testing.expect(t, packaged_marker_error == nil) do return
	defer delete(packaged_marker)
	if !testing.expect(t, os.write_entire_file(packaged_marker, "") == nil) do return
	root, root_ok = find_resource_root_from(build, working)
	if testing.expect(t, root_ok) {
		testing.expect_value(t, root, build)
		delete(root)
	}
}

// Confirms real startup discovery returns an absolute usable resource root in
// the current development environment.
@(test)
resolved_resource_root_is_absolute_and_contains_media_test :: proc(t: ^testing.T) {
	root, root_ok := resolve_resource_root()
	if !testing.expect(t, root_ok) do return
	defer delete(root)
	testing.expect(t, filepath.is_abs(root))
	testing.expect(t, resource_root_is_usable(root))
}

// Protects sprite-sheet validation at the minimum required rows and with extra
// complete rows while rejecting malformed dimensions.
@(test)
sprite_sheet_validation_accepts_minimum_or_more_complete_rows_test :: proc(t: ^testing.T) {
	testing.expect(t, vertical_sheet_dimensions_are_valid(32, 17 * 32, 17))
	testing.expect(t, vertical_sheet_dimensions_are_valid(32, 20 * 32, 17))
	testing.expect(t, !vertical_sheet_dimensions_are_valid(31, 17 * 32, 17))
	testing.expect(t, !vertical_sheet_dimensions_are_valid(32, 16 * 32, 17))
	testing.expect(t, !vertical_sheet_dimensions_are_valid(32, 17 * 32 + 1, 17))
	testing.expect(t, !vertical_sheet_dimensions_are_valid(32, 32, 0))
}

// Verifies missing or malformed level files fail recoverably without replacing
// the last valid Level value or trapping the lifecycle state.
@(test)
missing_and_invalid_level_files_do_not_replace_valid_state_test :: proc(t: ^testing.T) {
	temporary_directory, directory_error := os.make_directory_temp(
		"",
		"caverace-level-failure-*",
		context.allocator,
	)
	if !testing.expect(t, directory_error == nil) do return
	defer {
		_ = os.remove_all(temporary_directory)
		delete(temporary_directory)
	}

	missing_path, missing_error := filepath.join({temporary_directory, "missing.bin"})
	invalid_path, invalid_error := filepath.join({temporary_directory, "invalid.bin"})
	if !testing.expect(t, missing_error == nil && invalid_error == nil) do return
	defer {
		delete(missing_path)
		delete(invalid_path)
	}

	level: Level
	level.data.background[0][0] = 7
	testing.expect(t, !load_level_from_path(&level, missing_path))
	testing.expect_value(t, level.data.background[0][0], u8(7))

	invalid_data := [1]u8 {0xff}
	if !testing.expect(t, os.write_entire_file(invalid_path, invalid_data[:]) == nil) do return
	testing.expect(t, !load_level_from_path(&level, invalid_path))
	testing.expect_value(t, level.data.background[0][0], u8(7))

	gameplay: Gameplay
	init_gameplay(&gameplay)
	load_gameplay_level(&gameplay, temporary_directory)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Failed)
	update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
}

// Confirms focus loss and recovery do not mutate owned game state or replay
// queued gameplay input.
@(test)
focus_loss_is_non_destructive_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.gameplay.tick_state.input = {
		move_right   = true,
		bomb_pending = true,
	}
	input := Game_Input {
		move_right     = true,
		space_pressed  = true,
	}
	unfocused_input, unfocused_seconds := prepare_application_frame(
		&game,
		input,
		0.2,
		false,
	)
	testing.expect_value(t, unfocused_input, Game_Input {})
	testing.expect_value(t, unfocused_seconds, f64(0))
	testing.expect_value(t, game.gameplay.tick_state.input, Gameplay_Input_Buffer {})

	focused_input, focused_seconds := prepare_application_frame(&game, input, 0.2, true)
	testing.expect_value(t, focused_input, input)
	testing.expect_value(t, focused_seconds, f64(0.2))
}

// Exercises repeated title/gameplay routing to ensure the Application-owned
// resource root remains valid across fresh runs.
@(test)
repeated_main_menu_game_transitions_keep_application_path_test :: proc(t: ^testing.T) {
	app := Application {resource_root = "resources.test"}
	init_game(&app.game)
	show_main_menu(&app.game)
	for _ in 0 ..< 12 {
		update_game(&app.game, Game_Input {any_key_pressed = true}, 0)
		testing.expect_value(t, app.game.screen, App_Screen.Playing)
		update_game(&app.game, Game_Input {back = true}, 0)
		testing.expect_value(t, app.game.screen, App_Screen.Main_Menu)
		testing.expect_value(t, app.resource_root, "resources.test")
	}
}

// Verifies Game reports level I/O as an explicit request and only Application,
// which owns the resource root, performs the load.
@(test)
game_update_requests_level_load_at_application_boundary_test :: proc(t: ^testing.T) {
	resource_root, root_ok := resolve_resource_root()
	if !testing.expect(t, root_ok) do return
	defer delete(resource_root)

	app := Application {resource_root = resource_root}
	init_game(&app.game)
	update_game(&app.game, Game_Input {back = true}, 0)
	update_game(&app.game, Game_Input {any_key_pressed = true}, 0)

	result := update_game(&app.game, {}, 0)
	testing.expect(t, result.load_level_requested)
	testing.expect_value(t, app.game.gameplay.state, Gameplay_State.Load_Level)

	process_game_requests(&app, &result)
	testing.expect_value(t, app.game.gameplay.state, Gameplay_State.Playing)
}

// Runs a deterministic end-to-end game flow through the new front end, loading,
// pickup, win, retry, game over, menu return, and a fresh run.
@(test)
deterministic_complete_run_smoke_test :: proc(t: ^testing.T) {
	resource_root, root_ok := resolve_resource_root()
	if !testing.expect(t, root_ok) do return
	defer delete(resource_root)

	app := Application {resource_root = resource_root}
	init_game(&app.game)
	game := &app.game
	testing.expect_value(t, game.screen, App_Screen.Intro)
	update_application(&app, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	update_application(&app, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	update_application(&app, {}, 0)
	if !testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing) do return

	position := game.gameplay.player.position
	game.gameplay.level.data.item[position.x][position.y] = 0
	game.gameplay.level.data.treasure[position.x][position.y] = 1
	game.gameplay.tick_state.action_step = MOVEMENT_STEPS_PER_TILE - 1
	pickup_frame := update_application(&app, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, pickup_frame.gameplay.ticks.treasures_collected, 1)
	testing.expect(t, game.gameplay.player.score >= SCORE_TREASURE_PICKUP)

	for enemy_index in 0 ..< game.gameplay.enemy_count {
		game.gameplay.enemies[enemy_index].active = false
	}
	update_application(&app, {}, 0)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Won)
	update_application(&app, Game_Input {confirm = true}, 0)
	update_application(&app, {}, 0)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing)
	testing.expect_value(t, game.gameplay.level_index, 1)

	game.gameplay.player.lives = 2
	game.gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	game.gameplay.enemies = {}
	game.gameplay.enemies[0] = enemy_at(game.gameplay.player.position)
	game.gameplay.enemy_count = 1
	update_application(&app, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Dead)
	testing.expect_value(t, game.gameplay.player.lives, 1)
	update_application(&app, Game_Input {confirm = true}, 0)
	update_application(&app, {}, 0)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing)

	game.gameplay.player.score = 5000
	game.gameplay.player.lives = 1
	game.gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	game.gameplay.enemies = {}
	game.gameplay.enemies[0] = enemy_at(game.gameplay.player.position)
	game.gameplay.enemy_count = 1
	update_application(&app, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Game_Over)

	update_application(&app, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	update_application(&app, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, game.gameplay.player.score, 0)
}
