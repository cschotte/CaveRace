package caverace

MAX_RUN_RECORDS :: 10

Run_Mode :: enum {
	Campaign,
	Practice,
	Tutorial,
}

Medal :: enum {
	None,
	Bronze,
	Silver,
	Gold,
}

Run_Stats :: struct {
	elapsed_ticks: int,
	hits:          int,
	deaths:        int,
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
	valid:              bool,
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
	new_best_time:      bool,
	new_best_medal:     bool,
}

Level_Record :: struct {
	best_time_ticks: int,
	best_medal:      Medal,
}

Profile_Record :: struct {
	best_run_score: int,
	best_cave:      int,
	run_scores:     [MAX_RUN_RECORDS]int,
	run_score_count: int,
	levels:         [LEVEL_COUNT]Level_Record,
}

Local_Records :: struct {
	standard: Profile_Record,
	assisted: Profile_Record,
}

record_for_profile :: proc(records: ^Local_Records, profile: Difficulty_Profile) -> ^Profile_Record {
	switch profile {
	case .Standard: return &records.standard
	case .Assisted: return &records.assisted
	}
	return &records.standard
}

unlocked_level_count :: proc(record: ^Profile_Record) -> int {
	// best_cave retains the version-1 meaning: highest cave number reached.
	return clamp(max(record.best_cave, 1), 1, LEVEL_COUNT)
}

run_scores_are_valid :: proc(record: ^Profile_Record) -> bool {
	if record.run_score_count < 0 || record.run_score_count > MAX_RUN_RECORDS do return false
	for index in 0 ..< record.run_score_count {
		if record.run_scores[index] < 0 do return false
		if index > 0 && record.run_scores[index] > record.run_scores[index - 1] do return false
	}
	return true
}

submit_run_score :: proc(record: ^Profile_Record, score: int) -> bool {
	if score < 0 do return false
	insert_at := record.run_score_count
	for index in 0 ..< record.run_score_count {
		if score > record.run_scores[index] {
			insert_at = index
			break
		}
	}
	if insert_at >= MAX_RUN_RECORDS do return false
	last := min(record.run_score_count, MAX_RUN_RECORDS - 1)
	for index := last; index > insert_at; index -= 1 {
		record.run_scores[index] = record.run_scores[index - 1]
	}
	record.run_scores[insert_at] = score
	record.run_score_count = min(record.run_score_count + 1, MAX_RUN_RECORDS)
	record.best_run_score = record.run_scores[0]
	return true
}

update_level_record :: proc(record: ^Profile_Record, result: ^Level_Result) -> bool {
	if !result.valid || result.level_index < 0 || result.level_index >= LEVEL_COUNT do return false
	changed := false
	previous_best_cave := record.best_cave
	level := &record.levels[result.level_index]
	if result.elapsed_ticks > 0 &&
	   (level.best_time_ticks == 0 || result.elapsed_ticks < level.best_time_ticks) {
		level.best_time_ticks = result.elapsed_ticks
		result.new_best_time = true
		changed = true
	}
	if result.medal > level.best_medal {
		level.best_medal = result.medal
		result.new_best_medal = true
		changed = true
	}
	record.best_cave = max(record.best_cave, min(result.level_index + 2, LEVEL_COUNT))
	return changed || record.best_cave != previous_best_cave
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

begin_level_tracking :: proc(gameplay: ^Gameplay) {
	gameplay.level_stats = {start_score = gameplay.player.score}
	gameplay.level_result = {}
	gameplay.level_tracking_active = true
}

record_gameplay_damage :: proc(gameplay: ^Gameplay, amount: int) {
	if amount <= 0 do return
	gameplay.level_stats.hits += 1
	gameplay.level_stats.damage_taken += amount
	gameplay.run_stats.hits += 1
}

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
		valid                = true,
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
