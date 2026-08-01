package caverace

import "core:testing"

autoplay_test_gameplay :: proc() -> Gameplay {
	gameplay: Gameplay
	init_gameplay(&gameplay, .Standard)
	gameplay.state = .Playing
	gameplay.player.position = {5, 5}
	gameplay.player.move_from = gameplay.player.position
	gameplay.player.move_to = gameplay.player.position
	seed_gameplay_random(&gameplay, 1)
	return gameplay
}

@(test)
test_autoplay_moves_away_from_adjacent_enemy :: proc(t: ^testing.T) {
	gameplay := autoplay_test_gameplay()
	gameplay.enemies[0] = Enemy_State {
		active    = true,
		position  = {5, 4},
		move_from = {5, 4},
		move_to   = {5, 4},
	}
	gameplay.enemy_count = 1
	autoplay := Autoplay_State {direction = .Up}

	direction := autoplay_choose_direction(&autoplay, &gameplay)
	target := autoplay_candidate_position(gameplay.player.position, direction)
	testing.expect(t, direction != .Up)
	testing.expect(t, autoplay_enemy_clearance(&gameplay, target) >= AUTOPLAY_ENEMY_SAFE_DISTANCE)
}

@(test)
test_autoplay_only_bombs_with_a_complete_escape_route :: proc(t: ^testing.T) {
	gameplay := autoplay_test_gameplay()
	gameplay.level.data.item[6][5] = PASSABLE_ITEM_LIMIT + 1

	direction, place_bomb := autoplay_plan_bomb(&gameplay)
	testing.expect(t, place_bomb)
	testing.expect(t, direction != .None)

	bomb := Bomb_State {
		active       = true,
		position     = gameplay.player.position,
		fuse_ticks   = gameplay_tuning(gameplay.difficulty).bomb_fuse_ticks,
		power        = gameplay.player.bomb_power,
	}
	_, distance, found := autoplay_escape_route(&gameplay, &bomb)
	testing.expect(t, found)
	testing.expect(t, distance > 0)
	testing.expect(
		t,
		distance + AUTOPLAY_ESCAPE_MARGIN_ACTIONS <=
		bomb.fuse_ticks / MOVEMENT_STEPS_PER_TILE,
	)
}

@(test)
test_autoplay_keeps_pursuing_cave_victory_across_seeds :: proc(t: ^testing.T) {
	resource_root, root_ok := resolve_resource_root()
	testing.expect(t, root_ok)
	if !root_ok do return
	defer delete(resource_root)

	for level_index in 0 ..< AUTOPLAY_LEVEL_COUNT {
		progressing_runs := 0
		for seed in u64(1) ..= u64(16) {
			gameplay: Gameplay
			init_gameplay(&gameplay, .Standard)
			gameplay.mode = .Autoplay
			gameplay.level_index = level_index
			seed_gameplay_random(&gameplay, seed)
			load_gameplay_level(&gameplay, resource_root)
			testing.expect_value(t, gameplay.state, Gameplay_State.Playing)
			initial_enemy_count := active_enemy_count(&gameplay)
			autoplay := Autoplay_State {active = true, needs_decision = true}
			last_position := gameplay.player.position
			player_died := false
			player_moved := false
			bomb_placed := false
			idle_frames, longest_idle_frames := 0, 0
			frames_run := 0

			// Exercise the complete attract-mode duration and require the bot to
			// keep pursuing the actual level objective instead of merely surviving.
			for _ in 0 ..< GAMEPLAY_TICK_HZ * 60 {
				frames_run += 1
				input := build_autoplay_input(&autoplay, &gameplay)
				frame := update_gameplay(&gameplay, input, GAMEPLAY_TICK_SECONDS, false)
				if gameplay.player.position != last_position {
					player_moved = true
					idle_frames = 0
					last_position = gameplay.player.position
				} else {
					idle_frames += 1
					longest_idle_frames = max(longest_idle_frames, idle_frames)
				}
				if frame.ticks.bomb_placed {
					bomb_placed = true
				}
				if frame.ticks.player_died {
					player_died = true
					break
				}
				if gameplay.state != .Playing do break
			}
			if player_died do testing.expect(t, frames_run > GAMEPLAY_TICK_HZ * 10)
			testing.expect(t, player_moved)
			testing.expect(t, bomb_placed)
			testing.expect(t, longest_idle_frames < GAMEPLAY_TICK_HZ * 8)
			if gameplay.state == .Won {
				progressing_runs += 1
			} else if active_enemy_count(&gameplay) < initial_enemy_count {
				progressing_runs += 1
			}
		}
		testing.expect(t, progressing_runs >= 14)
	}
}

@(test)
test_autoplay_uses_unmodified_gameplay_rules :: proc(t: ^testing.T) {
	profiles := [2]Difficulty_Profile{.Standard, .Assisted}
	for profile in profiles {
		game: Game
		init_game(&game)
		game.settings.difficulty = profile
		expected_player := new_player_state(profile)

		start_autoplay(&game)
		testing.expect_value(t, game.gameplay.difficulty, profile)
		testing.expect_value(
			t,
			game.gameplay.player.bomb_capacity,
			expected_player.bomb_capacity,
		)
		testing.expect_value(
			t,
			game.gameplay.player.bomb_power,
			expected_player.bomb_power,
		)
		testing.expect_value(t, game.gameplay.player.energy, expected_player.energy)
		testing.expect_value(t, game.gameplay.player.lives, expected_player.lives)
		testing.expect(t, try_place_bomb(&game.gameplay))
		testing.expect_value(
			t,
			game.gameplay.bombs[0].fuse_ticks,
			gameplay_tuning(profile).bomb_fuse_ticks,
		)
	}
}

@(test)
test_autoplay_alternates_between_first_two_levels :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)

	expected_levels := [4]int{0, 1, 0, 1}
	for expected_level in expected_levels {
		start_autoplay(&game)
		testing.expect_value(t, game.gameplay.level_index, expected_level)
		show_main_menu(&game)
	}
}

@(test)
test_main_menu_idle_starts_autoplay :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	show_main_menu(&game)

	for _ in 0 ..< 239 {
		result := update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
		testing.expect(t, !result.load_level_requested)
	}
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)

	result := update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	testing.expect(t, result.load_level_requested)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect(t, game.autoplay.active)
	testing.expect_value(t, game.gameplay.mode, Run_Mode.Autoplay)
}

@(test)
test_main_menu_activity_resets_autoplay_idle_clock :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	show_main_menu(&game)
	game.autoplay.menu_idle_seconds = AUTOPLAY_IDLE_SECONDS - 0.1

	update_game(&game, Game_Input {keyboard_activity = true}, 0.2)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.autoplay.menu_idle_seconds, f64(0))
}

@(test)
test_autoplay_key_or_click_returns_to_main_menu :: proc(t: ^testing.T) {
	click_cases := [2]bool{false, true}
	for click in click_cases {
		game: Game
		init_game(&game)
		start_autoplay(&game)
		input := Game_Input {keyboard_activity = !click}
		if click do input.pointer.any_button_pressed = true

		update_game(&game, input, 0)
		testing.expect_value(t, game.screen, App_Screen.Main_Menu)
		testing.expect(t, !game.autoplay.active)
	}

	controller_game: Game
	init_game(&controller_game)
	start_autoplay(&controller_game)
	update_game(&controller_game, Game_Input {controller_activity = true}, 0)
	testing.expect_value(t, controller_game.screen, App_Screen.Main_Menu)
}

@(test)
test_autoplay_returns_to_menu_after_one_minute :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	start_autoplay(&game)
	game.autoplay.elapsed_seconds = AUTOPLAY_DURATION_SECONDS - 0.1

	update_game(&game, {}, 0.2)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect(t, !game.autoplay.active)
}
