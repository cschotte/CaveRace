package caverace

import "core:testing"

@(test)
level_result_explains_every_score_point_and_medal_condition_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay, .Standard)
	gameplay.state = .Playing
	gameplay.level_index = 0
	gameplay.player.score = 1000
	gameplay.treasure_total = 4
	gameplay.treasure_collected = 4
	begin_level_tracking(&gameplay)
	gameplay.level_stats.elapsed_ticks = 100
	gameplay.level_stats.enemies_destroyed = 3
	gameplay.level_stats.items_collected = 2
	gameplay.level_stats.items_salvaged = 1
	gameplay.level_stats.treasures_collected = 4
	for _ in 0 ..< 3 do apply_score_event(&gameplay.player, .Enemy_Destroyed)
	for _ in 0 ..< 2 do apply_score_event(&gameplay.player, .Item_Collected)
	apply_score_event(&gameplay.player, .Capped_Item_Salvaged)
	for _ in 0 ..< 4 do apply_score_event(&gameplay.player, .Treasure_Collected)

	finalize_level_result(&gameplay)
	result := gameplay.level_result
	explained := result.enemy_points + result.item_points + result.salvage_points +
		result.treasure_points + result.clear_bonus + result.all_treasure_bonus +
		result.no_damage_bonus + result.par_bonus + result.score_adjustment
	testing.expect(t, result.valid)
	testing.expect_value(t, result.score_delta, explained)
	testing.expect_value(t, result.final_score, 1000 + explained)
	testing.expect_value(t, gameplay.player.score, result.final_score)
	testing.expect_value(t, result.medal, Medal.Gold)
	testing.expect_value(t, result.treasure_collected, 4)
	testing.expect_value(t, result.treasure_total, 4)
	testing.expect_value(t, result.treasure_pickups, 4)
	testing.expect_value(t, result.score_adjustment, 0)

	testing.expect_value(t, medal_for_conditions(false, false), Medal.Bronze)
	testing.expect_value(t, medal_for_conditions(true, false), Medal.Silver)
	testing.expect_value(t, medal_for_conditions(false, true), Medal.Silver)
	testing.expect_value(t, medal_for_conditions(true, true), Medal.Gold)
}

@(test)
non_event_score_changes_are_explicitly_balanced_in_results_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay)
	gameplay.level_index = 0
	gameplay.player.score = 100
	begin_level_tracking(&gameplay)
	gameplay.player.score = 200 // Models the gated F5 score cheat.
	gameplay.level_stats.elapsed_ticks = 1
	finalize_level_result(&gameplay)
	testing.expect_value(t, gameplay.level_result.score_adjustment, 100)
	explained := gameplay.level_result.clear_bonus +
		gameplay.level_result.no_damage_bonus + gameplay.level_result.par_bonus +
		gameplay.level_result.score_adjustment
	testing.expect_value(t, gameplay.level_result.score_delta, explained)
}

@(test)
top_ten_scores_are_descending_tie_stable_and_bounded_test :: proc(t: ^testing.T) {
	record: Profile_Record
	scores := [12]int{50, 100, 20, 80, 80, 10, 70, 60, 40, 30, 90, 110}
	for score in scores {
		_ = submit_run_score(&record, score)
	}
	expected := [MAX_RUN_RECORDS]int{110, 100, 90, 80, 80, 70, 60, 50, 40, 30}
	testing.expect_value(t, record.run_score_count, MAX_RUN_RECORDS)
	testing.expect_value(t, record.run_scores, expected)
	testing.expect_value(t, record.best_run_score, 110)
	testing.expect(t, run_scores_are_valid(&record))
	testing.expect(t, !submit_run_score(&record, 29))
	testing.expect_value(t, record.run_scores, expected)
}

@(test)
level_records_unlock_reached_caves_without_medal_gates_test :: proc(t: ^testing.T) {
	record: Profile_Record
	testing.expect_value(t, unlocked_level_count(&record), 1)
	bronze := Level_Result {
		valid = true,
		level_index = 0,
		elapsed_ticks = 600,
		medal = .Bronze,
	}
	testing.expect(t, update_level_record(&record, &bronze))
	testing.expect_value(t, record.best_cave, 2)
	testing.expect_value(t, unlocked_level_count(&record), 2)
	testing.expect_value(t, record.levels[0].best_time_ticks, 600)
	testing.expect_value(t, record.levels[0].best_medal, Medal.Bronze)

	slower_gold := Level_Result {
		valid = true,
		level_index = 0,
		elapsed_ticks = 900,
		medal = .Gold,
	}
	testing.expect(t, update_level_record(&record, &slower_gold))
	testing.expect(t, !slower_gold.new_best_time)
	testing.expect(t, slower_gold.new_best_medal)
	testing.expect_value(t, record.levels[0].best_time_ticks, 600)
	testing.expect_value(t, unlocked_level_count(&record), 2)
}

@(test)
version_one_reached_cave_semantics_do_not_unlock_an_extra_cave_test :: proc(t: ^testing.T) {
	legacy_record := Profile_Record {best_cave = 4}
	testing.expect_value(t, unlocked_level_count(&legacy_record), 4)
}

@(test)
active_timer_excludes_pause_loading_and_results_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay = open_gameplay_at({1, 1})
	game.gameplay.level_tracking_active = true

	update_game(&game, Game_Input {pause_pressed = true}, GAMEPLAY_TICK_SECONDS)
	testing.expect(t, game.pause.open)
	testing.expect_value(t, game.gameplay.level_stats.elapsed_ticks, 0)
	update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	testing.expect_value(t, game.gameplay.level_stats.elapsed_ticks, 0)
	update_game(&game, Game_Input {pause_pressed = true}, 0)
	testing.expect(t, !game.pause.open)
	update_game(&game, {}, GAMEPLAY_TICK_SECONDS)
	testing.expect_value(t, game.gameplay.level_stats.elapsed_ticks, 1)

	game.gameplay.state = .Load_Level
	update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	testing.expect_value(t, game.gameplay.level_stats.elapsed_ticks, 1)
	game.gameplay.state = .Won
	update_game(&game, {}, MAX_FRAME_DELTA_SECONDS)
	testing.expect_value(t, game.gameplay.level_stats.elapsed_ticks, 1)
}

@(test)
practice_exit_and_record_submission_are_isolated_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay.mode = .Practice
	game.gameplay.state = .Won
	game.gameplay.player.score = 9999
	game.gameplay.level_result = {valid = true, level_index = 0, elapsed_ticks = 120}
	testing.expect(t, !update_local_record(&game))
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect_value(t, game.settings.records.standard.run_score_count, 0)
	testing.expect_value(t, game.settings.records.standard.best_cave, 0)

	campaign: Game
	init_game(&campaign)
	campaign.gameplay.mode = .Campaign
	campaign.gameplay.player.score = 9999
	testing.expect(t, update_local_record(&campaign))
	testing.expect_value(t, campaign.settings.records.standard.run_scores[0], 9999)
	testing.expect(t, !update_local_record(&campaign))

	cheat_game: Game
	init_game(&cheat_game, true)
	cheat_game.gameplay.player.score = 999999
	testing.expect(t, !update_local_record(&cheat_game))
	testing.expect_value(t, cheat_game.settings.records.standard.run_score_count, 0)
}

@(test)
practice_menu_lists_only_reached_levels_and_launches_selection_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	show_main_menu(&game)
	game.settings.tutorial_complete = true
	game.settings.records.standard.best_cave = 3
	game.menu.selected = int(Main_Menu_Item.Practice)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.menu.page, Menu_Page.Level_Select)

	// Three caves are available (initial plus two reached); the fourth row is Back.
	for _ in 0 ..< 2 do update_game(&game, Game_Input {menu_down_pressed = true}, 0)
	testing.expect_value(t, game.menu.selected, 2)
	result := update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect(t, result.load_level_requested)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, game.gameplay.mode, Run_Mode.Practice)
	testing.expect_value(t, game.gameplay.level_index, 2)
}

@(test)
record_persistence_round_trip_migration_and_namespace_corruption_test :: proc(t: ^testing.T) {
	settings := default_settings()
	settings.difficulty = .Assisted
	_ = submit_run_score(&settings.records.standard, 500)
	_ = submit_run_score(&settings.records.standard, 900)
	settings.records.standard.best_cave = 3
	settings.records.standard.levels[2] = {best_time_ticks = 1234, best_medal = .Silver}
	_ = submit_run_score(&settings.records.assisted, 700)
	document := settings_to_document(settings)
	loaded, ok := settings_from_document(document)
	testing.expect(t, ok)
	testing.expect_value(t, loaded.records, settings.records)

	legacy := document
	legacy.version = 1
	legacy.standard_run_scores = {}
	legacy.standard_run_score_count = 0
	legacy.standard_level_best_ticks = {}
	legacy.standard_level_medals = {}
	migrated, migrated_ok := settings_from_document(legacy)
	testing.expect(t, migrated_ok)
	testing.expect_value(t, migrated.records.standard.run_score_count, 1)
	testing.expect_value(t, migrated.records.standard.run_scores[0], 900)
	testing.expect_value(t, migrated.records.standard.best_cave, 3)

	corrupt := document
	corrupt.standard_run_score_count = MAX_RUN_RECORDS + 1
	partial, partial_ok := settings_from_document(corrupt)
	testing.expect(t, partial_ok)
	testing.expect_value(t, partial.records.standard, Profile_Record{})
	testing.expect_value(t, partial.records.assisted, settings.records.assisted)
}

@(test)
upgrade_carry_over_matches_standard_and_assisted_rules_test :: proc(t: ^testing.T) {
	standard := Player_State {bomb_capacity = 4, bomb_power = 7, energy = 1}
	prepare_player_for_next_level(&standard, .Standard)
	testing.expect_value(t, standard.bomb_capacity, 4)
	testing.expect_value(t, standard.bomb_power, 7)
	testing.expect_value(t, standard.energy, PLAYER_START_ENERGY)
	prepare_player_for_retry(&standard, .Standard)
	testing.expect_value(t, standard.bomb_capacity, PLAYER_START_BOMB_CAPACITY)
	testing.expect_value(t, standard.bomb_power, PLAYER_START_BOMB_POWER)
	standard.bomb_capacity, standard.bomb_power = 3, 6
	prepare_player_for_next_level(&standard, .Standard)
	testing.expect_value(t, standard.bomb_capacity, 3)
	testing.expect_value(t, standard.bomb_power, 6)

	assisted := Player_State {bomb_capacity = 4, bomb_power = 7, energy = 1}
	prepare_player_for_retry(&assisted, .Assisted)
	testing.expect_value(t, assisted.bomb_capacity, 4)
	testing.expect_value(t, assisted.bomb_power, 7)
	testing.expect_value(t, assisted.energy, PLAYER_START_ENERGY)
}

@(test)
ten_level_campaign_reaches_victory_in_both_profiles_test :: proc(t: ^testing.T) {
	for profile in Difficulty_Profile {
		gameplay: Gameplay
		init_gameplay(&gameplay, profile)
		for level_index in 0 ..< LEVEL_COUNT {
			gameplay.level_index = level_index
			gameplay.state = .Playing
			gameplay.level_completion_enabled = true
			gameplay.level_tracking_active = true
			gameplay.enemy_count = 0
			update_gameplay(&gameplay, {}, 0)
			testing.expect_value(t, gameplay.state, Gameplay_State.Won)
			update_gameplay(&gameplay, Game_Input {confirm = true}, 0)
			if level_index < LEVEL_COUNT - 1 {
				testing.expect_value(t, gameplay.state, Gameplay_State.Load_Level)
			} else {
				testing.expect_value(t, gameplay.state, Gameplay_State.Game_Won)
			}
		}
	}
}
