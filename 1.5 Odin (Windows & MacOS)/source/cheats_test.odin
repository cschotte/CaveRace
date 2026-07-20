package caverace

import "core:testing"

// Verifies all legacy powerblast effects, including fixed storage caps and
// saturating score doubling.
@(test)
legacy_cheat_effects_and_safe_limits_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({2, 2})
	gameplay.player = Player_State {
		lives         = 1,
		energy        = 1,
		bomb_capacity = 1,
		bomb_power    = PLAYER_MAX_BOMB_POWER - 1,
		score         = 125,
	}
	gameplay.enemies[0] = enemy_at({3, 2})
	gameplay.enemies[1] = enemy_at({4, 2})
	gameplay.enemy_count = 2

	apply_gameplay_cheat(&gameplay, .F2)
	testing.expect_value(t, gameplay.player.lives, PLAYER_MAX_LIVES)
	testing.expect_value(t, gameplay.player.energy, PLAYER_MAX_ENERGY)

	apply_gameplay_cheat(&gameplay, .F3)
	testing.expect_value(t, gameplay.player.bomb_capacity, PLAYER_MAX_BOMB_CAPACITY)

	apply_gameplay_cheat(&gameplay, .F4)
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_MAX_BOMB_POWER)
	apply_gameplay_cheat(&gameplay, .F4)
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_MAX_BOMB_POWER)

	apply_gameplay_cheat(&gameplay, .F5)
	testing.expect_value(t, gameplay.player.score, 250)
	gameplay.player.score = max(int) / 2 + 1
	apply_gameplay_cheat(&gameplay, .F5)
	testing.expect_value(t, gameplay.player.score, max(int))

	apply_gameplay_cheat(&gameplay, .F1)
	testing.expect_value(t, active_enemy_count(&gameplay), 0)
}

// Confirms cheats are ignored without -powerblast and consumed only by the
// fixed gameplay tick path when enabled.
@(test)
cheats_require_powerblast_and_run_on_fixed_tick_test :: proc(t: ^testing.T) {
	input: Game_Input
	input.cheat_pressed[.F1] = true

	disabled: Game
	init_game(&disabled, false)
	disabled.screen = .Playing
	disabled.gameplay = open_gameplay_at({1, 1})
	disabled.gameplay.level_completion_enabled = true
	disabled.gameplay.enemies[0] = enemy_at({4, 4})
	disabled.gameplay.enemy_count = 1
	disabled_result := update_game(&disabled, input, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, disabled.gameplay.enemies[0].active)
	testing.expect_value(t, disabled.gameplay.state, Gameplay_State.Playing)
	testing.expect(t, !disabled_result.gameplay.ticks.cheat_pressed[.F1])

	enabled: Game
	init_game(&enabled, true)
	enabled.screen = .Playing
	enabled.gameplay = open_gameplay_at({1, 1})
	enabled.gameplay.level_completion_enabled = true
	enabled.gameplay.enemies[0] = enemy_at({4, 4})
	enabled.gameplay.enemy_count = 1
	enabled_result := update_game(&enabled, input, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, enabled_result.gameplay.ticks.cheat_pressed[.F1])
	testing.expect_value(t, enabled.gameplay.state, Gameplay_State.Won)
	testing.expect_value(t, enabled.gameplay.player.score, SCORE_LEVEL_WON)
}

// Protects damage-over-pickup flash priority and the expected non-blocking
// decay timings used by the renderer.
@(test)
feedback_flash_priority_and_timing_test :: proc(t: ^testing.T) {
	feedback: Game_Feedback
	result := Gameplay_Tick_Result {
		items_collected     = 1,
		treasures_collected = 1,
	}
	request_gameplay_feedback(&feedback, &result)
	testing.expect_value(t, feedback.flash, Feedback_Flash.Treasure)
	testing.expect(t, feedback_flash_alpha(feedback) > 0)

	result.player_damaged = true
	request_gameplay_feedback(&feedback, &result)
	testing.expect_value(t, feedback.flash, Feedback_Flash.Damage)

	advance_game_feedback(&feedback, FEEDBACK_FLASH_SECONDS)
	testing.expect_value(t, feedback.flash, Feedback_Flash.None)
	testing.expect_value(t, feedback_flash_alpha(feedback), f32(0))

	start_transition_fade(&feedback)
	testing.expect_value(t, transition_fade_alpha(feedback), f32(1))
	advance_game_feedback(&feedback, TRANSITION_FADE_SECONDS / 2)
	testing.expect_value(t, transition_fade_alpha(feedback), f32(0.5))
	advance_game_feedback(&feedback, TRANSITION_FADE_SECONDS / 2)
	testing.expect_value(t, transition_fade_alpha(feedback), f32(0))
}

@(test)
reduced_flashes_suppresses_screen_damage_flash_but_keeps_local_blink_test :: proc(
	t: ^testing.T,
) {
	feedback := Game_Feedback {reduced_flashes = true}
	result := Gameplay_Tick_Result {player_damaged = true}
	request_gameplay_feedback(&feedback, &result)
	testing.expect_value(t, feedback.flash, Feedback_Flash.None)
	testing.expect_value(t, feedback_flash_alpha(feedback), f32(0))
	testing.expect(t, !contact_grace_player_visible(CONTACT_GRACE_TICKS))
	testing.expect(t, contact_grace_player_visible(CONTACT_GRACE_TICKS - 4))
}

// Verifies that screen fades remain visual-only and never suppress immediate
// back input or routing.
@(test)
visual_transitions_do_not_block_game_input_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	update_game(&game, Game_Input {back = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	update_game(&game, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, transition_fade_alpha(game.feedback), f32(1))

	update_game(&game, Game_Input {back = true}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, transition_fade_alpha(game.feedback), f32(1))
}
