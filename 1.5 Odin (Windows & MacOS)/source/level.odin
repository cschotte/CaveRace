package caverace

import "core:fmt"
import "core:mem"
import "core:os"

Map_Grid :: [MAP_WIDTH][MAP_HEIGHT]u8

// Exact layout stored in the original CaveRace 1,045-byte level files.
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

LEVEL_COUNT :: 10

level_paths := [LEVEL_COUNT]string {
	"levels/01.bin",
	"levels/02.bin",
	"levels/03.bin",
	"levels/04.bin",
	"levels/05.bin",
	"levels/06.bin",
	"levels/07.bin",
	"levels/08.bin",
	"levels/09.bin",
	"levels/10.bin",
}

load_level :: proc(level: ^Level, level_index: int) -> bool {
	if level_index < 0 || level_index >= LEVEL_COUNT {
		fmt.eprintln("Invalid level index:", level_index)
		return false
	}

	path := level_paths[level_index]
	file, open_error := os.open(path)
	if open_error != nil {
		fmt.eprintln("Failed to open level:", path, open_error)
		return false
	}
	defer os.close(file)

	file_size, size_error := os.file_size(file)
	if size_error != nil {
		fmt.eprintln("Failed to inspect level:", path, size_error)
		return false
	}

	if file_size != i64(size_of(Map_Data)) {
		fmt.eprintf(
			"Level %s has an invalid size: expected %d bytes, got %d.\n",
			path,
			size_of(Map_Data),
			file_size,
		)
		return false
	}

	data: Map_Data
	data_bytes := mem.byte_slice(&data, size_of(data))
	bytes_read, read_error := os.read_full(file, data_bytes)
	if read_error != nil || bytes_read != len(data_bytes) {
		fmt.eprintln("Failed to read level:", path, read_error)
		return false
	}

	level^ = Level {data = data}
	return true
}
