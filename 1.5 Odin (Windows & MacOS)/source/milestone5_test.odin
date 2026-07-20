package caverace

import "core:testing"

@(test)
music_crossfade_pause_duck_and_voice_limits_test :: proc(t: ^testing.T) {
	incoming, outgoing := music_crossfade_gains(0)
	testing.expect_value(t, incoming, f32(0))
	testing.expect_value(t, outgoing, f32(1))
	incoming, outgoing = music_crossfade_gains(MUSIC_CROSSFADE_SECONDS / 2)
	testing.expect_value(t, incoming, f32(0.5))
	testing.expect_value(t, outgoing, f32(0.5))
	incoming, outgoing = music_crossfade_gains(MUSIC_CROSSFADE_SECONDS * 2)
	testing.expect_value(t, incoming, f32(1))
	testing.expect_value(t, outgoing, f32(0))
	testing.expect_value(t, limited_audio_request_count(-1, 4), 0)
	testing.expect_value(t, limited_audio_request_count(9, 4), 4)
	testing.expect_value(t, limited_audio_request_count(2, 4), 2)
}

@(test)
rumble_is_bounded_and_controller_setting_migrates_test :: proc(t: ^testing.T) {
	left, right, duration := rumble_parameters(.Damage)
	testing.expect(t, left > 0 && left <= 1)
	testing.expect(t, right > 0 && right <= 1)
	testing.expect(t, duration > 0 && duration < 1)
	left, right, duration = rumble_parameters(.None)
	testing.expect_value(t, left, f32(0))
	testing.expect_value(t, right, f32(0))
	testing.expect_value(t, duration, f32(0))

	settings := default_settings()
	document := settings_to_document(settings)
	document.version = 2
	document.controller_rumble = false
	migrated, migrated_ok := settings_from_document(document)
	testing.expect(t, migrated_ok)
	testing.expect(t, migrated.controller_rumble)
	document.version = SETTINGS_VERSION
	current, current_ok := settings_from_document(document)
	testing.expect(t, current_ok)
	testing.expect(t, !current.controller_rumble)
}

@(test)
particle_and_popup_pools_are_bounded_replaceable_and_expire_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)
	seed_gameplay_random(&gameplay, 0xEFFE_C750)
	effects: Game_Effects
	spawn_effect_burst(&effects, &gameplay, 100, 100, MAX_EFFECT_PARTICLES * 3, .Explosion)
	for index in 0 ..< MAX_SCORE_POPUPS * 3 {
		spawn_score_popup(&effects, {index % MAP_WIDTH, 1}, 10 + index)
	}
	testing.expect_value(t, effect_particle_count(&effects), MAX_EFFECT_PARTICLES)
	testing.expect_value(t, score_popup_count(&effects), MAX_SCORE_POPUPS)
	advance_game_effects(&effects, 1)
	for _ in 0 ..< 8 do advance_game_effects(&effects, MAX_FRAME_DELTA_SECONDS)
	testing.expect_value(t, effect_particle_count(&effects), 0)
	testing.expect_value(t, score_popup_count(&effects), 0)
}

@(test)
reduced_flashes_reduce_bursts_without_removing_shape_feedback_test :: proc(t: ^testing.T) {
	gameplay_a, gameplay_b: Gameplay
	init_gameplay(&gameplay_a)
	init_gameplay(&gameplay_b)
	seed_gameplay_random(&gameplay_a, 700)
	seed_gameplay_random(&gameplay_b, 700)
	ticks := Gameplay_Tick_Result {explosions_started = 1}
	ticks.explosion_positions[0] = {3, 3}
	normal, reduced: Game_Effects
	request_game_effects(&normal, &gameplay_a, &ticks, false, false)
	request_game_effects(&reduced, &gameplay_b, &ticks, false, true)
	testing.expect_value(t, effect_particle_count(&normal), 8)
	testing.expect_value(t, effect_particle_count(&reduced), 4)
}

@(test)
cosmetic_effect_draws_cannot_change_ai_random_trace_test :: proc(t: ^testing.T) {
	a, b: Gameplay
	init_gameplay(&a)
	init_gameplay(&b)
	seed_gameplay_random(&a, 0xABCD_5005)
	seed_gameplay_random(&b, 0xABCD_5005)
	effects: Game_Effects
	spawn_effect_burst(&effects, &b, 100, 100, MAX_EFFECT_PARTICLES, .Victory)
	for _ in 0 ..< 128 {
		testing.expect_value(t, gameplay_random_max(&a, 1000), gameplay_random_max(&b, 1000))
	}
}

@(test)
late_cave_pursuit_is_walkable_profiled_and_metadata_bounded_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({8, 5})
	gameplay.level_index = LEVEL_COUNT - 1
	gameplay.enemies[0] = enemy_at({5, 5})
	gameplay.enemy_count = 1
	seed_gameplay_random(&gameplay, 88)
	testing.expect_value(t, pursuit_direction(&gameplay, &gameplay.enemies[0]), Direction.Right)
	gameplay.player.position = {8, 8}
	gameplay.enemies[0].direction = .Up
	// Down would reverse the previous action; Right is equally reducing.
	testing.expect_value(t, pursuit_direction(&gameplay, &gameplay.enemies[0]), Direction.Right)
	testing.expect_value(t, enemy_pursuit_chance(&gameplay), f32(0.30))
	gameplay.difficulty = .Assisted
	testing.expect_value(t, enemy_pursuit_chance(&gameplay), f32(0.15))

	previous: f32 = 0
	for level_index in 0 ..< LEVEL_COUNT {
		chance := level_metadata(level_index).enemy_pursuit_chance
		testing.expect(t, chance >= previous && chance <= 0.35)
		if level_index < 4 do testing.expect_value(t, chance, f32(0))
		previous = chance
	}
}

@(test)
menu_audio_and_victory_effect_requests_follow_committed_transitions_test :: proc(t: ^testing.T) {
	menu_game: Game
	init_game(&menu_game)
	show_main_menu(&menu_game)
	menu_result := update_game(&menu_game, Game_Input {menu_down_pressed = true}, 0)
	testing.expect_value(t, menu_result.menu_sound_requests, 1)

	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay = open_gameplay_at({1, 1})
	game.gameplay.level_completion_enabled = true
	game.gameplay.level_tracking_active = true
	game.gameplay.enemy_count = 0
	update_game(&game, {}, 0)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Won)

	game.gameplay.level_index = LEVEL_COUNT - 1
	victory_result := update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect(t, victory_result.victory_started)
	testing.expect_value(t, victory_result.rumble, Rumble_Event.Victory)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Game_Won)
	testing.expect(t, effect_particle_count(&game.effects) > 0)
}

@(test)
screen_shake_is_small_deterministic_and_exactly_disabled_at_zero_test :: proc(t: ^testing.T) {
	feedback := Game_Feedback {
		shake_remaining = SCREEN_SHAKE_SECONDS,
		shake_strength = 1.35,
	}
	x, y := screen_shake_offset(feedback, 0)
	testing.expect_value(t, x, i32(0))
	testing.expect_value(t, y, i32(0))
	x, y = screen_shake_offset(feedback, 100)
	testing.expect(t, abs(x) <= 2 && abs(y) <= 2)
	testing.expect(t, x != 0 || y != 0)
	feedback.shake_remaining = 0
	x, y = screen_shake_offset(feedback, 100)
	testing.expect_value(t, x, i32(0))
	testing.expect_value(t, y, i32(0))
}

@(test)
effect_pool_soak_remains_bounded_across_repeated_run_transitions_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	seed_gameplay_random(&game.gameplay, 9001)
	for cycle in 0 ..< 1000 {
		ticks := Gameplay_Tick_Result {
			explosions_started = MAX_BOMBS,
			items_collected = 1,
			treasures_collected = 1,
		}
		for bomb_index in 0 ..< MAX_BOMBS {
			ticks.explosion_positions[bomb_index] = {bomb_index + 1, bomb_index + 1}
		}
		request_game_effects(
			&game.effects,
			&game.gameplay,
			&ticks,
			cycle % 20 == 0,
			cycle % 2 == 0,
		)
		advance_game_effects(&game.effects, GAMEPLAY_TICK_SECONDS)
		testing.expect(t, effect_particle_count(&game.effects) <= MAX_EFFECT_PARTICLES)
		testing.expect(t, score_popup_count(&game.effects) <= MAX_SCORE_POPUPS)
	}
	game.effects = {}
	testing.expect_value(t, effect_particle_count(&game.effects), 0)
	testing.expect_value(t, score_popup_count(&game.effects), 0)
}
