package caverace

// clear_level_state releases all mutable data owned by the current level while
// preserving run-wide player progress between retries and level changes.
clear_level_state :: proc(gameplay: ^Gameplay) {
	gameplay.enemies = {}
	gameplay.enemy_count = 0
	gameplay.treasure_total = 0
	gameplay.treasure_collected = 0
	gameplay.bombs = {}
	gameplay.explosions = {}
	gameplay.bomb_occupancy = {}
	gameplay.tick_state = {}
	gameplay.level_completion_enabled = false
}

// begin_level_retry restores per-level player values and schedules the same
// level to load. Standard no longer applies an opaque retry score penalty.
begin_level_retry :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Dead)
	assert(gameplay.player.lives > 0)
	prepare_player_for_retry(&gameplay.player, gameplay.difficulty)
	clear_level_state(gameplay)
	gameplay.state = .Load_Level
}

// begin_level_restart is the pause-menu restart path. It preserves run-wide
// lives, score, and upgrades, restores energy, and reloads the same cave.
begin_level_restart :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Playing)
	prepare_player_for_next_level(&gameplay.player, gameplay.difficulty)
	clear_level_state(gameplay)
	gameplay.state = .Load_Level
}

// Standard death resets upgrades; Assisted death preserves earned capacity
// and power. Both profiles restore energy and movement state.
prepare_player_for_retry :: proc(player: ^Player_State, difficulty: Difficulty_Profile) {
	capacity, power := player.bomb_capacity, player.bomb_power
	reset_player_for_level_start(player, difficulty)
	if difficulty == .Assisted {
		player.bomb_capacity = capacity
		player.bomb_power = power
	}
}

// begin_next_level advances to the next available level, restores per-level
// player values, and schedules loading after the level-complete screen.
begin_next_level :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Won)
	if gameplay.level_index == LEVEL_COUNT - 1 {
		gameplay.state = .Game_Won
		return
	}
	gameplay.level_index += 1
	prepare_player_for_next_level(&gameplay.player, gameplay.difficulty)
	gameplay.level_tracking_active = false
	clear_level_state(gameplay)
	gameplay.state = .Load_Level
}

prepare_player_for_next_level :: proc(player: ^Player_State, difficulty: Difficulty_Profile) {
	tuning := gameplay_tuning(difficulty)
	player.move_from = player.position
	player.move_to = player.position
	player.movement_step = 0
	player.direction = .None
	player.contact_grace_ticks = 0
	player.blast_grace_ticks = 0
	player.energy = tuning.player_start_energy
}

// resolve_gameplay_outcome applies win or death transitions after each frame's
// gameplay ticks. CheckLevelComplete resolves an empty enemy set first, so a
// simultaneous last-enemy kill and player hit wins without consuming a life.
resolve_gameplay_outcome :: proc(
	gameplay: ^Gameplay,
	ticks: Gameplay_Tick_Result,
) {
	if gameplay.level_completion_enabled && active_enemy_count(gameplay) == 0 {
		finalize_level_result(gameplay)
		clear_level_state(gameplay)
		gameplay.state = .Won
		return
	}

	if !ticks.player_died do return
	gameplay.level_stats.deaths += 1
	gameplay.player.lives = max(gameplay.player.lives - 1, 0)
	if gameplay.mode == .Practice && gameplay.player.lives == 0 {
		gameplay.player.lives = 1
	}
	if gameplay.player.lives > 0 {
		gameplay.state = .Dead
		return
	}

	clear_level_state(gameplay)
	gameplay.state = .Game_Over
}
