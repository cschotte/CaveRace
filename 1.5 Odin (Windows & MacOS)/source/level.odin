package caverace

Map_Grid :: [MAP_WIDTH][MAP_HEIGHT]u8

// This is the exact layout stored in the original 1,045-byte level files.
Map_Data :: struct {
	background: Map_Grid,
	item:       Map_Grid,
	treasure:   Map_Grid,
	enemy:      Map_Grid,
	player:     Map_Grid,
}

#assert(size_of(Map_Data) == 1045)

// Bombs are runtime state and are not stored in the original level files.
Level :: struct {
	data:  Map_Data,
	bombs: Map_Grid,
}
