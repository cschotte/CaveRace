package caverace

// Level_Metadata adds modern presentation and tuning data beside the preserved
// 1,045-byte legacy level format. Par times and pursuit chances are initial
// Milestone 4 targets. They are intentionally generous and remain
// subject to the documented cohort balance pass; medals never gate content.
Level_Metadata :: struct {
	name:                  string,
	theme:                 Tile_Theme,
	treasure_total:         int,
	par_seconds:            f32,
	enemy_pursuit_chance:   f32,
}

LEVEL_METADATA :: [LEVEL_COUNT]Level_Metadata {
	{"Cave 1",  .Forest, 4, 120, 0.00},
	{"Cave 2",  .Winter, 3, 150, 0.00},
	{"Cave 3",  .Desert, 3, 180, 0.00},
	{"Cave 4",  .Oil,    3, 210, 0.00},
	{"Cave 5",  .Lava,   3, 240, 0.05},
	{"Cave 6",  .Forest, 3, 270, 0.10},
	{"Cave 7",  .Winter, 3, 300, 0.15},
	{"Cave 8",  .Desert, 3, 330, 0.20},
	{"Cave 9",  .Oil,    3, 360, 0.25},
	{"Cave 10", .Lava,   5, 420, 0.30},
}

#assert(len(LEVEL_METADATA) == LEVEL_COUNT)

// level_metadata looks up one cave's fixed presentation and tuning data.
// level_index must already be validated (0..<LEVEL_COUNT); callers own that
// bounds check since it comes from run-controlled state, never raw input.
level_metadata :: proc(level_index: int) -> Level_Metadata {
	assert(level_index >= 0 && level_index < LEVEL_COUNT)
	metadata := LEVEL_METADATA
	return metadata[level_index]
}
