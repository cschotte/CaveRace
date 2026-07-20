package caverace

// Cave_Music_Band keeps level progression independent from raylib music
// handles while giving Application an explicit A/B/C campaign cue.
Cave_Music_Band :: enum {
	A,
	B,
	C,
}

// Level_Metadata adds modern presentation and tuning data beside the preserved
// 1,045-byte legacy level format. Par times and pursuit chances are initial
// Milestone 4 targets. They are intentionally generous and remain
// subject to the documented cohort balance pass; medals never gate content.
Level_Metadata :: struct {
	name:                  string,
	theme:                 Tile_Theme,
	music_band:            Cave_Music_Band,
	treasure_total:         int,
	par_seconds:            f32,
	show_tutorial_hints:    bool,
	enemy_pursuit_chance:   f32,
}

LEVEL_METADATA :: [LEVEL_COUNT]Level_Metadata {
	{"Cave 1",  .Forest, .A, 4, 120, true,  0},
	{"Cave 2",  .Winter, .A, 3, 150, true,  0},
	{"Cave 3",  .Desert, .A, 3, 180, true,  0},
	{"Cave 4",  .Oil,    .B, 3, 210, false, 0},
	{"Cave 5",  .Lava,   .B, 3, 240, false, 0},
	{"Cave 6",  .Forest, .B, 3, 270, false, 0},
	{"Cave 7",  .Winter, .B, 3, 300, false, 0},
	{"Cave 8",  .Desert, .C, 3, 330, false, 0},
	{"Cave 9",  .Oil,    .C, 3, 360, false, 0},
	{"Cave 10", .Lava,   .C, 5, 420, false, 0},
}

#assert(len(LEVEL_METADATA) == LEVEL_COUNT)

level_metadata :: proc(level_index: int) -> Level_Metadata {
	assert(level_index >= 0 && level_index < LEVEL_COUNT)
	metadata := LEVEL_METADATA
	return metadata[level_index]
}
