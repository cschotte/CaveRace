package caverace

import "core:encoding/endian"
import "core:fmt"
import "core:hash"
import "core:os"
import "core:path/filepath"
import "core:strings"

HIGH_SCORE_FILE_VERSION       :: 1
HIGH_SCORE_FILE_HEADER_SIZE   :: 12
HIGH_SCORE_FILE_ENTRY_SIZE    :: 1 + HIGH_SCORE_NAME_MAX + 8
HIGH_SCORE_FILE_CHECKSUM_SIZE :: 4
HIGH_SCORE_FILE_SIZE :: HIGH_SCORE_FILE_HEADER_SIZE +
	HIGH_SCORE_ENTRY_COUNT * HIGH_SCORE_FILE_ENTRY_SIZE +
	HIGH_SCORE_FILE_CHECKSUM_SIZE
HIGH_SCORE_FILE_CHECKSUM_OFFSET :: HIGH_SCORE_FILE_SIZE - HIGH_SCORE_FILE_CHECKSUM_SIZE

HIGH_SCORE_FILE_MAGIC :: [8]u8 {'C', 'A', 'V', 'E', 'H', 'I', '1', '5'}
HIGH_SCORE_DIRECTORY  :: "CaveRace"
HIGH_SCORE_FILENAME   :: "highscores.dat"

#assert(HIGH_SCORE_FILE_SIZE == 248)

High_Score_Load_Status :: enum {
	Loaded,
	Defaults_Missing,
	Defaults_Corrupt,
	Defaults_IO_Error,
}

encode_high_score_table :: proc(table: ^High_Score_Table) -> [HIGH_SCORE_FILE_SIZE]u8 {
	assert(high_score_table_is_valid(table))
	data: [HIGH_SCORE_FILE_SIZE]u8
	magic := HIGH_SCORE_FILE_MAGIC
	copy(data[:len(magic)], magic[:])
	endian.unchecked_put_u16le(data[8:], HIGH_SCORE_FILE_VERSION)
	data[10] = HIGH_SCORE_ENTRY_COUNT
	data[11] = HIGH_SCORE_NAME_MAX

	offset := HIGH_SCORE_FILE_HEADER_SIZE
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		entry := &table.entries[entry_index]
		data[offset] = u8(entry.name.length)
		offset += 1
		copy(data[offset:offset + HIGH_SCORE_NAME_MAX], entry.name.bytes[:HIGH_SCORE_NAME_MAX])
		offset += HIGH_SCORE_NAME_MAX
		endian.unchecked_put_u64le(data[offset:], entry.score)
		offset += 8
	}
	assert(offset == HIGH_SCORE_FILE_CHECKSUM_OFFSET)
	checksum := hash.fnv32a(data[:HIGH_SCORE_FILE_CHECKSUM_OFFSET])
	endian.unchecked_put_u32le(data[HIGH_SCORE_FILE_CHECKSUM_OFFSET:], checksum)
	return data
}

decode_high_score_table :: proc(data: []u8, table: ^High_Score_Table) -> bool {
	if len(data) != HIGH_SCORE_FILE_SIZE do return false
	magic := HIGH_SCORE_FILE_MAGIC
	for magic_index in 0 ..< len(magic) {
		if data[magic_index] != magic[magic_index] do return false
	}
	if endian.unchecked_get_u16le(data[8:]) != HIGH_SCORE_FILE_VERSION do return false
	if data[10] != HIGH_SCORE_ENTRY_COUNT || data[11] != HIGH_SCORE_NAME_MAX do return false
	expected_checksum := endian.unchecked_get_u32le(data[HIGH_SCORE_FILE_CHECKSUM_OFFSET:])
	actual_checksum := hash.fnv32a(data[:HIGH_SCORE_FILE_CHECKSUM_OFFSET])
	if expected_checksum != actual_checksum do return false

	decoded: High_Score_Table
	offset := HIGH_SCORE_FILE_HEADER_SIZE
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		name_length := int(data[offset])
		offset += 1
		if name_length > HIGH_SCORE_NAME_MAX do return false
		entry := &decoded.entries[entry_index]
		entry.name.length = name_length
		copy(entry.name.bytes[:HIGH_SCORE_NAME_MAX], data[offset:offset + HIGH_SCORE_NAME_MAX])
		offset += HIGH_SCORE_NAME_MAX
		entry.score = endian.unchecked_get_u64le(data[offset:])
		offset += 8
	}
	if offset != HIGH_SCORE_FILE_CHECKSUM_OFFSET do return false
	if !high_score_table_is_valid(&decoded) do return false
	table^ = decoded
	return true
}

load_high_score_table :: proc(path: string, table: ^High_Score_Table) -> High_Score_Load_Status {
	table^ = default_high_score_table()
	if path == "" do return .Defaults_Missing

	file, open_error := os.open(path)
	if open_error != nil {
		if open_error == os.General_Error.Not_Exist do return .Defaults_Missing
		return .Defaults_IO_Error
	}
	defer os.close(file)

	file_size, size_error := os.file_size(file)
	if size_error != nil do return .Defaults_IO_Error
	if file_size != HIGH_SCORE_FILE_SIZE do return .Defaults_Corrupt

	data: [HIGH_SCORE_FILE_SIZE]u8
	bytes_read, read_error := os.read_full(file, data[:])
	if read_error != nil || bytes_read != len(data) do return .Defaults_IO_Error
	if !decode_high_score_table(data[:], table) {
		table^ = default_high_score_table()
		return .Defaults_Corrupt
	}
	return .Loaded
}

save_high_score_table_safe :: proc(path: string, table: ^High_Score_Table) -> bool {
	if path == "" || !high_score_table_is_valid(table) do return false
	directory := filepath.dir(path)
	if directory_error := os.make_directory_all(directory);
	   directory_error != nil && directory_error != os.General_Error.Exist {
		return false
	}

	temporary_path, allocation_error := strings.concatenate({path, ".tmp"})
	if allocation_error != nil do return false
	defer delete(temporary_path)

	data := encode_high_score_table(table)
	if write_error := os.write_entire_file(temporary_path, data[:]); write_error != nil {
		_ = os.remove(temporary_path)
		return false
	}
	if rename_error := os.rename(temporary_path, path); rename_error != nil {
		_ = os.remove(temporary_path)
		return false
	}
	return true
}

high_score_storage_path :: proc(allocator := context.allocator) -> (string, os.Error) {
	user_data, user_data_error := os.user_data_dir(allocator)
	if user_data_error != nil do return "", user_data_error
	defer delete(user_data, allocator)

	path, allocation_error := filepath.join(
		{user_data, HIGH_SCORE_DIRECTORY, HIGH_SCORE_FILENAME},
		allocator,
	)
	if allocation_error != nil do return "", allocation_error
	return path, nil
}

init_high_scores :: proc(state: ^High_Score_State, storage_path: string) {
	state^ = High_Score_State {storage_path = storage_path}
	status := load_high_score_table(storage_path, &state.table)
	switch status {
	case .Defaults_Corrupt:
		fmt.eprintln("High-score data is corrupt; using defaults:", storage_path)
	case .Defaults_IO_Error:
		fmt.eprintln("Could not load high scores; using defaults:", storage_path)
	case .Loaded, .Defaults_Missing:
	}
}

persist_high_scores :: proc(state: ^High_Score_State) {
	if state.storage_path == "" do return
	if !save_high_score_table_safe(state.storage_path, &state.table) {
		fmt.eprintln("Could not save high scores:", state.storage_path)
	}
}
