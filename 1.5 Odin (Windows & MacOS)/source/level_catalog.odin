package caverace

// Cave_Music_Band keeps level progression independent from raylib music
// handles while giving Application an explicit A/B/C campaign cue.
Cave_Music_Band :: enum {
	A,
	B,
	C,
}

// Level_Metadata adds modern presentation and tuning data beside the preserved
// 1,045-byte legacy level format. Zero par times and pursuit chances are
// deliberate Milestone 1 placeholders until balancing begins.
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
	{"Cave 1",  .Forest, .A, 4, 0, true,  0},
	{"Cave 2",  .Winter, .A, 3, 0, true,  0},
	{"Cave 3",  .Desert, .A, 3, 0, true,  0},
	{"Cave 4",  .Oil,    .B, 3, 0, false, 0},
	{"Cave 5",  .Lava,   .B, 3, 0, false, 0},
	{"Cave 6",  .Forest, .B, 3, 0, false, 0},
	{"Cave 7",  .Winter, .B, 3, 0, false, 0},
	{"Cave 8",  .Desert, .C, 3, 0, false, 0},
	{"Cave 9",  .Oil,    .C, 3, 0, false, 0},
	{"Cave 10", .Lava,   .C, 5, 0, false, 0},
}

#assert(len(LEVEL_METADATA) == LEVEL_COUNT)

level_metadata :: proc(level_index: int) -> Level_Metadata {
	assert(level_index >= 0 && level_index < LEVEL_COUNT)
	metadata := LEVEL_METADATA
	return metadata[level_index]
}
