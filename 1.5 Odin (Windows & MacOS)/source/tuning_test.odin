package caverace

import "core:testing"

@(test)
standard_tuning_contains_selected_milestone_two_values_test :: proc(t: ^testing.T) {
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
	testing.expect_value(t, tuning.movement_ticks_per_tile, 12)
	testing.expect_value(t, tuning.bomb_fuse_ticks, 180)
	testing.expect_value(t, tuning.contact_grace_ticks, 45)
	testing.expect_value(t, tuning.bomb_danger_preview_ticks, 36)
	testing.expect_value(t, tuning.score_bomb_cost, 0)
	testing.expect_value(t, tuning.score_item_pickup, 50)
	testing.expect_value(t, tuning.score_capped_item_salvage, 25)
	testing.expect_value(t, tuning.score_enemy_destroyed, 75)
	testing.expect_value(t, tuning.score_treasure_pickup, 100)
	testing.expect_value(t, tuning.score_level_won, 100)
	testing.expect_value(t, tuning.score_death_penalty, 0)
}

@(test)
milestone_two_selects_twelve_tick_response_over_legacy_sixteen_test :: proc(
	t: ^testing.T,
) {
	legacy_seconds := f64(16) / f64(GAMEPLAY_TICK_HZ)
	selected_seconds := f64(
		gameplay_tuning(.Standard).movement_ticks_per_tile,
	) / f64(GAMEPLAY_TICK_HZ)
	testing.expect(t, selected_seconds < legacy_seconds)
	testing.expect_value(t, selected_seconds, f64(0.2))
	testing.expect_value(t, f64(BOMB_FUSE_TICKS) / GAMEPLAY_TICK_HZ, f64(3))
	testing.expect_value(
		t,
		f64(BOMB_DANGER_PREVIEW_TICKS) / GAMEPLAY_TICK_HZ,
		f64(0.6),
	)
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
