package caverace

import "core:testing"

// Protects legacy outcome precedence: destroying the last enemy wins even when
// the player is hit on the same tick.
@(test)
simultaneous_last_enemy_and_player_death_resolves_as_win_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({5, 6})
	gameplay.level_completion_enabled = true
	gameplay.player.lives = 2
	gameplay.player.energy = PLAYER_START_ENERGY
	gameplay.player.bomb_capacity = 3
	gameplay.player.bomb_power = 4
	gameplay.player.score = 10
	gameplay.enemies[0] = enemy_at({5, 5})
	gameplay.enemy_count = 1
	bomb := Bomb_State {active = true, position = {5, 5}, power = 1}
	gameplay.explosions[0] = build_explosion_state(&bomb)
	seed_gameplay_random(&gameplay, 23)

	frame := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, frame.ticks.player_died)
	testing.expect_value(t, frame.ticks.enemies_destroyed, 1)
	testing.expect_value(t, gameplay.state, Gameplay_State.Won)
	testing.expect_value(t, gameplay.player.lives, 2)
	testing.expect_value(t, gameplay.player.energy, 0)
	testing.expect_value(
		t,
		gameplay.player.score,
		10 + SCORE_ENEMY_DESTROYED + SCORE_LEVEL_WON,
	)
	testing.expect(t, !gameplay.level_completion_enabled)
	testing.expect_value(t, gameplay.enemy_count, 0)
	testing.expect(t, !gameplay.explosions[0].active)
	score_after_win := gameplay.player.score
	update_gameplay(&gameplay, {}, 1.0)
	testing.expect_value(t, gameplay.player.score, score_after_win)

	update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, gameplay.level_index, 1)
	testing.expect_value(t, gameplay.player.lives, 2)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, gameplay.player.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER)
	testing.expect_value(t, gameplay.player.score, score_after_win)
}

// Verifies death consumes one life, waits for confirmation, then reloads the
// same level with per-level values and score penalty reset correctly.
@(test)
death_removes_one_life_then_confirmed_retry_reloads_with_penalty_test :: proc(t: ^testing.T) {
	position := Grid_Position {4, 4}
	gameplay := open_gameplay_at(position)
	gameplay.level_completion_enabled = true
	gameplay.player.lives = 2
	gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	gameplay.player.bomb_capacity = 4
	gameplay.player.bomb_power = 7
	gameplay.player.score = 100
	gameplay.enemies[0] = enemy_at(position)
	gameplay.enemy_count = 1
	gameplay.bombs[0] = {active = true, position = {1, 1}, fuse_actions = 5, power = 2}
	gameplay.bomb_occupancy[1][1] = BOMB_TICKING_SPRITE
	seed_gameplay_random(&gameplay, 29)

	death := update_gameplay(&gameplay, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, death.ticks.player_died)
	testing.expect_value(t, gameplay.state, Gameplay_State.Dead)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.player.energy, 0)
	testing.expect_value(t, gameplay.player.score, 100)
	testing.expect(t, gameplay.level_completion_enabled)
	testing.expect_value(t, gameplay.enemy_count, 1)
	update_gameplay(&gameplay, {}, 1.0)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.player.score, 100)

	update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
	testing.expect_value(t, gameplay.player.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
	testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER)
	testing.expect_value(t, gameplay.player.score, 100 - SCORE_DEATH_PENALTY)
	testing.expect(t, !gameplay.level_completion_enabled)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[1][1], u8(0))

	load_gameplay_level(&gameplay, "")
	testing.expect_value(t, gameplay.state, Gameplay_State.Playing)
	testing.expect(t, gameplay.level_completion_enabled)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.player.score, 100 - SCORE_DEATH_PENALTY)
	for bomb_state in gameplay.bombs do testing.expect(t, !bomb_state.active)
}

// Confirms a retry penalty that reaches zero still receives the legacy minimum
// score floor before play resumes.
@(test)
retry_penalty_that_reaches_zero_applies_legacy_score_floor_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.state = .Dead
	gameplay.player.lives = 1
	gameplay.player.score = SCORE_DEATH_PENALTY

	begin_level_retry(&gameplay)
	testing.expect_value(t, gameplay.player.score, SCORE_BOMB_COST)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
}

// Verifies final death keeps the score in gameplay until input returns to the
// main menu.
@(test)
final_death_stays_on_game_over_until_input_returns_to_main_menu_test :: proc(t: ^testing.T) {
	position := Grid_Position {3, 3}
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay = open_gameplay_at(position)
	game.gameplay.level_completion_enabled = true
	game.gameplay.player.lives = 1
	game.gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	game.gameplay.player.score = 0
	game.gameplay.enemies[0] = enemy_at(position)
	game.gameplay.enemy_count = 1
	seed_gameplay_random(&game.gameplay, 31)

	update_game(&game, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Game_Over)
	testing.expect_value(t, game.gameplay.player.lives, 0)
	testing.expect_value(t, game.gameplay.player.score, SCORE_BOMB_COST)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect(t, !game.gameplay.level_completion_enabled)
	testing.expect_value(t, game.gameplay.enemy_count, 0)

	update_game(&game, Game_Input {any_key_pressed = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}

// Confirms Escape abandons active gameplay immediately without applying death
// logic or producing a completed score.
@(test)
escape_abandons_run_directly_without_completed_score_test :: proc(t: ^testing.T) {
	position := Grid_Position {2, 2}
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay = open_gameplay_at(position)
	game.gameplay.level_completion_enabled = true
	game.gameplay.player.lives = 1
	game.gameplay.player.energy = ENEMY_CONTACT_DAMAGE
	game.gameplay.player.score = 250
	game.gameplay.enemies[0] = enemy_at(position)
	game.gameplay.enemy_count = 1

	update_game(&game, Game_Input {back = true}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.gameplay.state, Gameplay_State.Playing)
	testing.expect_value(t, game.gameplay.player.lives, 1)
	testing.expect_value(t, game.gameplay.player.energy, ENEMY_CONTACT_DAMAGE)
}

// Exercises a full ten-level wraparound to ensure each transition reloads clean
// level state while preserving run-wide score progression.
@(test)
ten_level_cycle_wraps_and_reloads_without_stale_level_state_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)
	seed_gameplay_random(&gameplay, 37)

	for completed_level in 0 ..< LEVEL_COUNT {
		load_gameplay_level(&gameplay, "")
		testing.expect_value(t, gameplay.state, Gameplay_State.Playing)
		testing.expect_value(t, gameplay.level_index, completed_level)
		testing.expect(t, gameplay.level_completion_enabled)
		testing.expect(t, gameplay.enemy_count > 0)

		for enemy_index in 0 ..< gameplay.enemy_count {
			gameplay.enemies[enemy_index].active = false
		}
		gameplay.bombs[0] = {
			active       = true,
			position     = {1, 1},
			fuse_actions = 3,
			power        = 2,
		}
		gameplay.explosions[0] = build_explosion_state(&gameplay.bombs[0])
		gameplay.bomb_occupancy[1][1] = BOMB_TICKING_SPRITE
		gameplay.player.energy = 3
		gameplay.player.bomb_capacity = 4
		gameplay.player.bomb_power = 8

		update_gameplay(&gameplay, {}, 0)
		testing.expect_value(t, gameplay.state, Gameplay_State.Won)
		testing.expect_value(
			t,
			gameplay.player.score,
			(completed_level + 1) * SCORE_LEVEL_WON,
		)
		testing.expect(t, !gameplay.level_completion_enabled)
		testing.expect_value(t, gameplay.enemy_count, 0)
		testing.expect(t, !gameplay.bombs[0].active)
		testing.expect(t, !gameplay.explosions[0].active)
		testing.expect_value(t, gameplay.bomb_occupancy[1][1], u8(0))
		update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
		testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
		testing.expect_value(t, gameplay.level_index, (completed_level + 1) % LEVEL_COUNT)
		testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
		testing.expect_value(t, gameplay.player.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
		testing.expect_value(t, gameplay.player.bomb_power, PLAYER_START_BOMB_POWER)
	}

	testing.expect_value(t, gameplay.level_index, 0)
	load_gameplay_level(&gameplay, "")
	testing.expect_value(t, gameplay.state, Gameplay_State.Playing)
	testing.expect(t, gameplay.level_completion_enabled)
	testing.expect(t, gameplay.enemy_count > 0)
	for bomb_state in gameplay.bombs do testing.expect(t, !bomb_state.active)
	for explosion in gameplay.explosions do testing.expect(t, !explosion.active)
}
