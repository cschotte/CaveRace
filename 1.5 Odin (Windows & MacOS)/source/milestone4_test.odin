package caverace

import "core:encoding/json"
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
practice_result_returns_to_menu_without_persistence_request_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	game.screen = .Playing
	game.gameplay.mode = .Practice
	game.gameplay.state = .Won
	game.gameplay.player.score = 9999
	game.gameplay.level_result = {valid = true, level_index = 0, elapsed_ticks = 120}
	result := update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.screen, App_Screen.Main_Menu)
	testing.expect(t, !result.settings_changed)
}

@(test)
practice_menu_lists_all_levels_and_launches_selection_test :: proc(t: ^testing.T) {
	game: Game
	init_game(&game)
	show_main_menu(&game)
	game.settings.tutorial_complete = true
	game.menu.selected = int(Main_Menu_Item.Practice)
	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.menu.page, Menu_Page.Level_Select)

	for _ in 0 ..< LEVEL_COUNT - 1 do update_game(&game, Game_Input {menu_down_pressed = true}, 0)
	testing.expect_value(t, game.menu.selected, LEVEL_COUNT - 1)
	result := update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect(t, result.load_level_requested)
	testing.expect_value(t, game.screen, App_Screen.Playing)
	testing.expect_value(t, game.gameplay.mode, Run_Mode.Practice)
	testing.expect_value(t, game.gameplay.level_index, LEVEL_COUNT - 1)
}

@(test)
legacy_settings_versions_load_without_score_or_time_data_test :: proc(t: ^testing.T) {
	settings := default_settings()
	settings.difficulty = .Assisted
	document := settings_to_document(settings)
	document.version = 1
	migrated, migrated_ok := settings_from_document(document)
	testing.expect(t, migrated_ok)
	testing.expect_value(t, migrated.difficulty, Difficulty_Profile.Assisted)

	// Existing version-3 files may still contain the removed record namespace.
	// Those obsolete keys must not prevent the remaining settings from loading.
	legacy_json := `{"version":3,"music_volume":42,"standard_best_run_score":9999,"standard_best_cave":8}`
	legacy_document: Persisted_Settings
	testing.expect(t, json.unmarshal(transmute([]byte)legacy_json, &legacy_document) == nil)
	from_json, json_ok := settings_from_document(legacy_document)
	testing.expect(t, json_ok)
	testing.expect_value(t, from_json.music_volume, 42)
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
