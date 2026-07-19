package caverace

// clear_level_state releases all mutable data owned by the current level while
// preserving run-wide player progress between retries and level changes.
clear_level_state :: proc(gameplay: ^Gameplay) {
	gameplay.enemies = {}
	gameplay.enemy_count = 0
	gameplay.bombs = {}
	gameplay.explosions = {}
	gameplay.bomb_occupancy = {}
	gameplay.tick_state = {}
	gameplay.level_completion_enabled = false
}

// begin_level_retry applies the death penalty, restores per-level player
// values, and schedules the same level to load after Enter is confirmed.
begin_level_retry :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Dead)
	assert(gameplay.player.lives > 0)
	apply_score_event(&gameplay.player, .Death_Retry)
	apply_score_event(&gameplay.player, .Action_Floor)
	reset_player_for_level_start(&gameplay.player)
	clear_level_state(gameplay)
	gameplay.state = .Load_Level
}

// begin_next_level advances with wraparound, restores per-level player values,
// and schedules loading after the win screen is confirmed.
begin_next_level :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Won)
	gameplay.level_index = (gameplay.level_index + 1) % LEVEL_COUNT
	reset_player_for_level_start(&gameplay.player)
	clear_level_state(gameplay)
	gameplay.state = .Load_Level
}

// resolve_gameplay_outcome applies win or death transitions after each frame's
// gameplay ticks. CheckLevelComplete resolves an empty enemy set first, so a
// simultaneous last-enemy kill and player hit wins without consuming a life.
resolve_gameplay_outcome :: proc(
	gameplay: ^Gameplay,
	ticks: Gameplay_Tick_Result,
) {
	if gameplay.level_completion_enabled && active_enemy_count(gameplay) == 0 {
		apply_score_event(&gameplay.player, .Level_Won)
		clear_level_state(gameplay)
		gameplay.state = .Won
		return
	}

	if !ticks.player_died do return
	gameplay.player.lives = max(gameplay.player.lives - 1, 0)
	if gameplay.player.lives > 0 {
		gameplay.state = .Dead
		return
	}

	apply_score_event(&gameplay.player, .Action_Floor)
	clear_level_state(gameplay)
	gameplay.state = .Game_Over
}
