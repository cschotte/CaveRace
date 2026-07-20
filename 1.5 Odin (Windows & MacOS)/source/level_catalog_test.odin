package caverace

import "core:testing"

@(test)
level_metadata_matches_all_legacy_levels_test :: proc(t: ^testing.T) {
	resource_root, root_ok := resolve_resource_root()
	if !testing.expect(t, root_ok) do return
	defer delete(resource_root)

	for level_index in 0 ..< LEVEL_COUNT {
		metadata := level_metadata(level_index)
		testing.expect(t, len(metadata.name) > 0)
		testing.expect(t, metadata.par_seconds >= 0)
		testing.expect(t, metadata.enemy_pursuit_chance >= 0)
		testing.expect(t, metadata.enemy_pursuit_chance <= 1)

		level: Level
		if !testing.expect(t, load_level(&level, level_index, resource_root)) do continue
		treasure_total := 0
		for grid_y in 0 ..< MAP_HEIGHT {
			for grid_x in 0 ..< MAP_WIDTH {
				if level.data.treasure[grid_x][grid_y] != 0 {
					treasure_total += 1
				}
			}
		}
		testing.expect_value(t, treasure_total, metadata.treasure_total)
	}
}

@(test)
level_metadata_defines_three_campaign_music_bands_test :: proc(t: ^testing.T) {
	for level_index in 0 ..< LEVEL_COUNT {
		expected: Cave_Music_Band
		switch {
		case level_index <= 2: expected = .A
		case level_index <= 6: expected = .B
		case:                  expected = .C
		}
		testing.expect_value(t, level_metadata(level_index).music_band, expected)
	}
}

@(test)
retry_uses_the_same_fixed_level_theme_test :: proc(t: ^testing.T) {
	resource_root, root_ok := resolve_resource_root()
	if !testing.expect(t, root_ok) do return
	defer delete(resource_root)

	gameplay: Gameplay
	init_gameplay(&gameplay)
	gameplay.level_index = 5
	load_gameplay_level(&gameplay, resource_root)
	if !testing.expect_value(t, gameplay.state, Gameplay_State.Playing) do return
	expected_theme := level_metadata(gameplay.level_index).theme
	testing.expect_value(t, gameplay.theme, expected_theme)

	gameplay.state = .Dead
	begin_level_retry(&gameplay)
	load_gameplay_level(&gameplay, resource_root)
	testing.expect_value(t, gameplay.theme, expected_theme)
}
