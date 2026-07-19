package caverace

clear_level_runtime :: proc(gameplay: ^Gameplay) {
	gameplay.enemies = {}
	gameplay.enemy_count = 0
	gameplay.bombs = {}
	gameplay.explosions = {}
	gameplay.bomb_occupancy = {}
	gameplay.simulation = {}
	gameplay.runtime_initialized = false
}

begin_level_retry :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Dead)
	assert(gameplay.player.lives > 0)
	apply_score_event(&gameplay.player, .Death_Retry)
	apply_score_event(&gameplay.player, .Action_Floor)
	reset_player_for_level_start(&gameplay.player)
	clear_level_runtime(gameplay)
	change_gameplay_state(gameplay, .Load_Level)
}

begin_next_level :: proc(gameplay: ^Gameplay) {
	assert(gameplay.state == .Won)
	gameplay.level_index = (gameplay.level_index + 1) % LEVEL_COUNT
	reset_player_for_level_start(&gameplay.player)
	clear_level_runtime(gameplay)
	change_gameplay_state(gameplay, .Load_Level)
}

// CheckLevelComplete in both legacy versions resolves an empty enemy set
// before checking player energy. Preserve that ordering so a simultaneous
// last-enemy kill and player hit completes the level without consuming a life.
resolve_gameplay_outcome :: proc(
	gameplay: ^Gameplay,
	simulation: Gameplay_Simulation_Result,
) -> Maybe(Completed_Run) {
	if gameplay.runtime_initialized && active_enemy_count(gameplay) == 0 {
		apply_score_event(&gameplay.player, .Level_Won)
		clear_level_runtime(gameplay)
		change_gameplay_state(gameplay, .Won)
		return nil
	}

	if !simulation.player_died do return nil
	gameplay.player.lives = max(gameplay.player.lives - 1, 0)
	if gameplay.player.lives > 0 {
		change_gameplay_state(gameplay, .Dead)
		return nil
	}

	apply_score_event(&gameplay.player, .Action_Floor)
	completed_run := Completed_Run {score = gameplay.player.score}
	clear_level_runtime(gameplay)
	change_gameplay_state(gameplay, .Game_Over)
	return completed_run
}
