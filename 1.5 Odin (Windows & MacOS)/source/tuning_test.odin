package caverace

import "core:testing"

@(test)
standard_tuning_preserves_milestone_one_legacy_values_test :: proc(t: ^testing.T) {
	tuning := gameplay_tuning(.Standard)
	testing.expect_value(t, tuning.player_start_lives, 4)
	testing.expect_value(t, tuning.player_max_lives, 4)
	testing.expect_value(t, tuning.player_start_energy, 8)
	testing.expect_value(t, tuning.player_max_energy, 8)
	testing.expect_value(t, tuning.player_start_bomb_capacity, 1)
	testing.expect_value(t, tuning.player_max_bomb_capacity, 4)
	testing.expect_value(t, tuning.player_start_bomb_power, 1)
	testing.expect_value(t, tuning.player_max_bomb_power, 10)
	testing.expect_value(t, tuning.enemy_contact_damage, 2)
	testing.expect_value(t, tuning.bomb_fuse_actions, 12)
	testing.expect_value(t, tuning.score_bomb_cost, 5)
	testing.expect_value(t, tuning.score_item_pickup, 50)
	testing.expect_value(t, tuning.score_enemy_destroyed, 75)
	testing.expect_value(t, tuning.score_treasure_pickup, 100)
	testing.expect_value(t, tuning.score_level_won, 100)
	testing.expect_value(t, tuning.score_death_penalty, 50)
}

@(test)
new_game_uses_selected_difficulty_tuning_test :: proc(t: ^testing.T) {
	gameplay: Gameplay
	init_gameplay(&gameplay, .Standard)
	tuning := gameplay_tuning(gameplay.difficulty)
	testing.expect_value(t, gameplay.player.lives, tuning.player_start_lives)
	testing.expect_value(t, gameplay.player.energy, tuning.player_start_energy)
	testing.expect_value(
		t,
		gameplay.player.bomb_capacity,
		tuning.player_start_bomb_capacity,
	)
	testing.expect_value(t, gameplay.player.bomb_power, tuning.player_start_bomb_power)
}
