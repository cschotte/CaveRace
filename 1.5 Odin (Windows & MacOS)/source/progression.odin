package caverace

Run_Mode :: enum {
	Campaign,
	Tutorial,
}

Medal :: enum {
	None,
	Bronze,
	Silver,
	Gold,
}

Level_Stats :: struct {
	elapsed_ticks:    int,
	start_score:      int,
	hits:             int,
	damage_taken:     int,
	deaths:           int,
	enemies_destroyed: int,
	items_collected:   int,
	items_salvaged:    int,
	treasures_collected: int,
}

Level_Result :: struct {
	level_index:        int,
	elapsed_ticks:      int,
	par_ticks:          int,
	treasure_collected: int,
	treasure_total:     int,
	treasure_pickups:   int,
	hits:               int,
	damage_taken:       int,
	deaths:             int,
	enemies_destroyed:  int,
	items_collected:    int,
	items_salvaged:     int,
	enemy_points:       int,
	item_points:        int,
	salvage_points:     int,
	treasure_points:    int,
	clear_bonus:        int,
	all_treasure_bonus: int,
	no_damage_bonus:    int,
	par_bonus:          int,
	score_adjustment:   int,
	score_delta:        int,
	final_score:        int,
	medal:              Medal,
}

medal_for_conditions :: proc(all_treasure, under_par: bool) -> Medal {
	if all_treasure && under_par do return .Gold
	if all_treasure || under_par do return .Silver
	return .Bronze
}

medal_label :: proc(medal: Medal) -> cstring {
	switch medal {
	case .None:   return "NONE"
	case .Bronze: return "BRONZE"
	case .Silver: return "SILVER"
	case .Gold:   return "GOLD"
	}
	return ""
}

// begin_level_tracking starts a fresh per-level stats ledger, recording the
// player's current score as the baseline finalize_level_result later
// subtracts from to report this level's score delta.
begin_level_tracking :: proc(gameplay: ^Gameplay) {
	gameplay.level_stats = {start_score = gameplay.player.score}
	gameplay.level_result = {}
	gameplay.level_tracking_active = true
}

// record_gameplay_damage tallies a hit only when it actually reduced energy,
// so a blocked or zero-amount hit never inflates the level's hit count.
record_gameplay_damage :: proc(gameplay: ^Gameplay, amount: int) {
	if amount <= 0 do return
	gameplay.level_stats.hits += 1
	gameplay.level_stats.damage_taken += amount
}

// finalize_level_result computes medal conditions, applies the level-clear
// score bonuses, and builds the exact ledger the level-result screen draws.
// Called once, exactly when the last enemy is cleared.
finalize_level_result :: proc(gameplay: ^Gameplay) {
	metadata := level_metadata(gameplay.level_index)
	all_treasure := gameplay.treasure_total > 0 &&
		gameplay.treasure_collected == gameplay.treasure_total
	par_ticks := int(metadata.par_seconds * GAMEPLAY_TICK_HZ)
	under_par := par_ticks > 0 && gameplay.level_stats.elapsed_ticks <= par_ticks
	no_damage := gameplay.level_stats.hits == 0

	apply_score_event(&gameplay.player, .Level_Won, gameplay.difficulty)
	if all_treasure do apply_score_event(&gameplay.player, .All_Treasure, gameplay.difficulty)
	if no_damage do apply_score_event(&gameplay.player, .No_Damage, gameplay.difficulty)
	if under_par do apply_score_event(&gameplay.player, .Under_Par, gameplay.difficulty)

	tuning := gameplay_tuning(gameplay.difficulty)
	stats := gameplay.level_stats
	gameplay.level_result = {
		level_index          = gameplay.level_index,
		elapsed_ticks        = stats.elapsed_ticks,
		par_ticks            = par_ticks,
		treasure_collected   = gameplay.treasure_collected,
		treasure_total       = gameplay.treasure_total,
		treasure_pickups     = stats.treasures_collected,
		hits                 = stats.hits,
		damage_taken         = stats.damage_taken,
		deaths               = stats.deaths,
		enemies_destroyed    = stats.enemies_destroyed,
		items_collected      = stats.items_collected,
		items_salvaged       = stats.items_salvaged,
		enemy_points         = stats.enemies_destroyed * tuning.score_enemy_destroyed,
		item_points          = stats.items_collected * tuning.score_item_pickup,
		salvage_points       = stats.items_salvaged * tuning.score_capped_item_salvage,
		treasure_points      = stats.treasures_collected * tuning.score_treasure_pickup,
		clear_bonus          = tuning.score_level_won,
		all_treasure_bonus   = tuning.score_all_treasure if all_treasure else 0,
		no_damage_bonus      = tuning.score_no_damage if no_damage else 0,
		par_bonus            = tuning.score_under_par if under_par else 0,
		final_score          = gameplay.player.score,
		medal                = medal_for_conditions(all_treasure, under_par),
	}
	gameplay.level_result.score_delta =
		gameplay.level_result.final_score - stats.start_score
	explained := gameplay.level_result.enemy_points +
		gameplay.level_result.item_points + gameplay.level_result.salvage_points +
		gameplay.level_result.treasure_points + gameplay.level_result.clear_bonus +
		gameplay.level_result.all_treasure_bonus +
		gameplay.level_result.no_damage_bonus + gameplay.level_result.par_bonus
	gameplay.level_result.score_adjustment =
		gameplay.level_result.score_delta - explained
}
