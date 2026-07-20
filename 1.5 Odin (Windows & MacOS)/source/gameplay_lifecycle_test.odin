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
		10 + SCORE_ENEMY_DESTROYED + SCORE_LEVEL_WON + SCORE_UNDER_PAR,
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
	testing.expect_value(t, gameplay.player.bomb_capacity, 3)
	testing.expect_value(t, gameplay.player.bomb_power, 4)
	testing.expect_value(t, gameplay.player.score, score_after_win)
}

// Verifies death consumes one life, waits for confirmation, then reloads the
// same level with per-level values and score preserved.
@(test)
death_removes_one_life_then_confirmed_retry_preserves_score_test :: proc(t: ^testing.T) {
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
	gameplay.bombs[0] = {active = true, position = {1, 1}, fuse_ticks = 5, power = 2}
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
	testing.expect_value(t, gameplay.player.score, 100)
	testing.expect(t, !gameplay.level_completion_enabled)
	testing.expect(t, !gameplay.bombs[0].active)
	testing.expect_value(t, gameplay.bomb_occupancy[1][1], u8(0))

	load_gameplay_level(&gameplay, "")
	testing.expect_value(t, gameplay.state, Gameplay_State.Playing)
	testing.expect(t, gameplay.level_completion_enabled)
	testing.expect_value(t, gameplay.player.lives, 1)
	testing.expect_value(t, gameplay.player.score, 100)
	for bomb_state in gameplay.bombs do testing.expect(t, !bomb_state.active)
}

// Confirms retry never invents or removes score in Standard.
@(test)
retry_at_zero_keeps_zero_score_test :: proc(t: ^testing.T) {
	gameplay := open_gameplay_at({0, 0})
	gameplay.state = .Dead
	gameplay.player.lives = 1
	gameplay.player.score = 0

	begin_level_retry(&gameplay)
	testing.expect_value(t, gameplay.player.score, 0)
	testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
}

@(test)
quick_restart_handles_dead_attempt_and_game_over_new_run_test :: proc(t: ^testing.T) {
	dead_game: Game
	init_game(&dead_game)
	dead_game.screen = .Playing
	dead_game.gameplay = open_gameplay_at({2, 2})
	dead_game.gameplay.state = .Dead
	dead_game.gameplay.player.lives = 2
	dead_game.gameplay.player.score = 240
	dead_result := update_game(&dead_game, Game_Input {restart_pressed = true}, 0)
	testing.expect(t, dead_result.load_level_requested)
	testing.expect_value(t, dead_game.gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, dead_game.gameplay.player.lives, 2)
	testing.expect_value(t, dead_game.gameplay.player.score, 240)

	game_over: Game
	init_game(&game_over)
	game_over.screen = .Playing
	game_over.gameplay.state = .Game_Over
	game_over.gameplay.level_index = 8
	game_over.gameplay.player.lives = 0
	game_over.gameplay.player.score = 900
	new_run := update_game(&game_over, Game_Input {restart_pressed = true}, 0)
	testing.expect(t, new_run.load_level_requested)
	testing.expect_value(t, game_over.screen, App_Screen.Playing)
	testing.expect_value(t, game_over.gameplay.state, Gameplay_State.Load_Level)
	testing.expect_value(t, game_over.gameplay.level_index, 0)
	testing.expect_value(t, game_over.gameplay.player.lives, PLAYER_START_LIVES)
	testing.expect_value(t, game_over.gameplay.player.score, 0)
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
	testing.expect_value(t, game.gameplay.player.score, 0)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect(t, !game.gameplay.level_completion_enabled)
	testing.expect_value(t, game.gameplay.enemy_count, 0)

	update_game(&game, Game_Input {confirm = true}, 0)
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

// Exercises all ten levels to ensure each transition reloads clean level state,
// preserves run-wide score, and ends permanently in Game_Won after level 10.
@(test)
ten_level_run_ends_in_game_won_without_wrapping_test :: proc(t: ^testing.T) {
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
			fuse_ticks = 3,
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
			(completed_level + 1) * (SCORE_LEVEL_WON + SCORE_NO_DAMAGE + SCORE_UNDER_PAR),
		)
		testing.expect(t, !gameplay.level_completion_enabled)
		testing.expect_value(t, gameplay.enemy_count, 0)
		testing.expect(t, !gameplay.bombs[0].active)
		testing.expect(t, !gameplay.explosions[0].active)
		testing.expect_value(t, gameplay.bomb_occupancy[1][1], u8(0))
		update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
		if completed_level < LEVEL_COUNT - 1 {
			testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
			testing.expect_value(t, gameplay.level_index, completed_level + 1)
			testing.expect_value(t, gameplay.player.energy, PLAYER_START_ENERGY)
			testing.expect_value(t, gameplay.player.bomb_capacity, 4)
			testing.expect_value(t, gameplay.player.bomb_power, 8)
		} else {
			testing.expect_value(t, gameplay.state, Gameplay_State.Game_Won)
		}
	}

	testing.expect_value(t, gameplay.level_index, LEVEL_COUNT - 1)
	testing.expect_value(t, gameplay.state, Gameplay_State.Game_Won)
	update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
	testing.expect_value(t, gameplay.level_index, LEVEL_COUNT - 1)
	testing.expect_value(t, gameplay.state, Gameplay_State.Game_Won)
	for bomb_state in gameplay.bombs do testing.expect(t, !bomb_state.active)
	for explosion in gameplay.explosions do testing.expect(t, !explosion.active)
}

@(test)
game_won_screen_returns_to_main_menu_on_confirm_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay.state = .Game_Won
	game.gameplay.level_index = LEVEL_COUNT - 1

	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
}
