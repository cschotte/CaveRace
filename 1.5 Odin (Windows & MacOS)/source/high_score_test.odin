package caverace

import "core:encoding/endian"
import "core:hash"
import "core:os"
import "core:path/filepath"
import "core:testing"

// Verifies the platform user-data location produces an absolute CaveRace-specific
// high-score path.
@(test)
platform_high_score_path_is_absolute_and_app_specific_test :: proc(t: ^testing.T) {
	path, path_error := high_score_storage_path()
	if !testing.expect(t, path_error == nil) do return
	defer delete(path)

	testing.expect(t, filepath.is_abs(path))
	testing.expect_value(t, filepath.base(path), HIGH_SCORE_FILENAME)
	testing.expect_value(t, filepath.base(filepath.dir(path)), HIGH_SCORE_DIRECTORY)
}

// Protects the names, scores, ordering, and validity of the legacy default table.
@(test)
legacy_high_score_defaults_test :: proc(t: ^testing.T) {
	table := default_high_score_table()
	expected_names := [HIGH_SCORE_ENTRY_COUNT]string {
		"CLEMENS SCHOTTE",
		"HARRO LOCK",
		"PAUL VAN CROONENBURG",
		"PAUL BOSSELAAR",
		"MARIJN SCHOTTE",
		"CLEMENS SCHOTTE",
		"PAUL VAN CROONENBURG",
		"PAUL BOSSELAAR",
	}
	expected_scores := [HIGH_SCORE_ENTRY_COUNT]u64 {
		10000, 9000, 8000, 7000, 6000, 5000, 4000, 3000,
	}
	testing.expect(t, high_score_table_is_valid(&table))
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		testing.expect_value(
			t,
			high_score_name_string(&table.entries[entry_index].name),
			expected_names[entry_index],
		)
		testing.expect_value(t, table.entries[entry_index].score, expected_scores[entry_index])
	}
}

// Confirms qualification is strict and insertion leaves existing equal scores
// ahead of a new tie.
@(test)
qualification_is_strict_and_ties_insert_stably_test :: proc(t: ^testing.T) {
	table := default_high_score_table()
	_, qualifies := high_score_insertion_index(&table, 3000)
	testing.expect(t, !qualifies)
	index := 0
	index, qualifies = high_score_insertion_index(&table, 3001)
	testing.expect(t, qualifies)
	testing.expect_value(t, index, 7)

	name: High_Score_Name
	set_high_score_name(&name, "NEW PLAYER")
	testing.expect(t, insert_high_score(&table, name, 9000))
	testing.expect_value(t, table.entries[0].score, u64(10000))
	testing.expect_value(t, table.entries[1].score, u64(9000))
	testing.expect_value(t, table.entries[2].score, u64(9000))
	testing.expect_value(t, high_score_name_string(&table.entries[1].name), "HARRO LOCK")
	testing.expect_value(t, high_score_name_string(&table.entries[2].name), "NEW PLAYER")
	testing.expect(t, high_score_table_is_valid(&table))
}

// Exercises name normalization, filtering, deletion, and fixed-capacity behavior
// through the interactive update path.
@(test)
name_entry_uppercases_filters_backspaces_and_truncates_test :: proc(t: ^testing.T) {
	name: High_Score_Name
	set_high_score_name(&name, "abcdefghijklmnopqrstuvwxyz")
	testing.expect_value(t, name.length, HIGH_SCORE_NAME_MAX)
	testing.expect_value(t, high_score_name_string(&name), "ABCDEFGHIJKLMNOPQRST")
	testing.expect(t, high_score_name_is_valid(&name))

	state := High_Score_State {table = default_high_score_table()}
	open_high_scores(&state, Completed_Run {score = 11000})
	testing.expect_value(t, state.mode, High_Score_Mode.Entering_Name)

	blocked_exit := update_high_scores(
		&state,
		Game_Input {
			back          = true,
			space_pressed = true,
			mouse         = {left_pressed = true},
		},
	)
	testing.expect(t, !blocked_exit.back_requested)
	testing.expect_value(t, state.mode, High_Score_Mode.Entering_Name)

	input: Game_Input
	input.text_codepoints[0] = 'a'
	input.text_codepoints[1] = 'b'
	input.text_codepoints[2] = '-'
	input.text_codepoints[3] = '3'
	input.text_codepoints[4] = ' '
	input.text_count = 5
	update_high_scores(&state, input)
	testing.expect_value(t, high_score_name_string(&state.input_name), "AB3 ")

	update_high_scores(&state, Game_Input {text_backspace = true})
	testing.expect_value(t, high_score_name_string(&state.input_name), "AB3")
	confirmed := update_high_scores(&state, Game_Input {confirm = true})
	testing.expect(t, confirmed.table_changed)
	testing.expect(t, !confirmed.back_requested)
	testing.expect_value(t, state.mode, High_Score_Mode.Viewing)
	testing.expect_value(t, state.table.entries[0].score, u64(11000))
	testing.expect_value(t, high_score_name_string(&state.table.entries[0].name), "AB3")
}

// Verifies confirming an empty qualifying name inserts the PLAYER fallback.
@(test)
empty_confirm_uses_player_name_test :: proc(t: ^testing.T) {
	state := High_Score_State {table = default_high_score_table()}
	open_high_scores(&state, Completed_Run {score = 12000})
	result := update_high_scores(&state, Game_Input {confirm = true})
	testing.expect(t, result.table_changed)
	testing.expect_value(t, high_score_name_string(&state.table.entries[0].name), "PLAYER")
}

// Protects the versioned binary format against header, checksum, name, ordering,
// and size corruption while preserving round trips.
@(test)
high_score_binary_round_trip_and_corruption_validation_test :: proc(t: ^testing.T) {
	expected := default_high_score_table()
	name: High_Score_Name
	set_high_score_name(&name, "ASTRONAUT 7")
	testing.expect(t, insert_high_score(&expected, name, 12345))
	encoded := encode_high_score_table(&expected)
	testing.expect_value(t, len(encoded), HIGH_SCORE_FILE_SIZE)

	decoded: High_Score_Table
	testing.expect(t, decode_high_score_table(encoded[:], &decoded))
	testing.expect_value(t, decoded, expected)

	bad_magic := encoded
	bad_magic[0] = 'X'
	testing.expect(t, !decode_high_score_table(bad_magic[:], &decoded))

	bad_checksum := encoded
	bad_checksum[HIGH_SCORE_FILE_CHECKSUM_OFFSET] =
		bad_checksum[HIGH_SCORE_FILE_CHECKSUM_OFFSET] ~ 0xff
	testing.expect(t, !decode_high_score_table(bad_checksum[:], &decoded))

	bad_order := encoded
	second_score_offset := HIGH_SCORE_FILE_HEADER_SIZE + HIGH_SCORE_FILE_ENTRY_SIZE +
		1 + HIGH_SCORE_NAME_MAX
	endian.unchecked_put_u64le(bad_order[second_score_offset:], 20000)
	checksum := hash.fnv32a(bad_order[:HIGH_SCORE_FILE_CHECKSUM_OFFSET])
	endian.unchecked_put_u32le(bad_order[HIGH_SCORE_FILE_CHECKSUM_OFFSET:], checksum)
	testing.expect(t, !decode_high_score_table(bad_order[:], &decoded))

	bad_name := encoded
	bad_name[HIGH_SCORE_FILE_HEADER_SIZE + 1] = '?'
	checksum = hash.fnv32a(bad_name[:HIGH_SCORE_FILE_CHECKSUM_OFFSET])
	endian.unchecked_put_u32le(bad_name[HIGH_SCORE_FILE_CHECKSUM_OFFSET:], checksum)
	testing.expect(t, !decode_high_score_table(bad_name[:], &decoded))

	lowercase_name := encoded
	lowercase_name[HIGH_SCORE_FILE_HEADER_SIZE + 1] = 'a'
	checksum = hash.fnv32a(lowercase_name[:HIGH_SCORE_FILE_CHECKSUM_OFFSET])
	endian.unchecked_put_u32le(lowercase_name[HIGH_SCORE_FILE_CHECKSUM_OFFSET:], checksum)
	testing.expect(t, !decode_high_score_table(lowercase_name[:], &decoded))
}

// Exercises missing, corrupt, and valid files plus temporary-file cleanup for
// safe high-score persistence.
@(test)
high_score_file_missing_corrupt_and_safe_round_trip_test :: proc(t: ^testing.T) {
	temporary_directory, directory_error := os.make_directory_temp(
		"",
		"caverace-high-score-*",
		context.allocator,
	)
	if !testing.expect(t, directory_error == nil) do return
	defer {
		_ = os.remove_all(temporary_directory)
		delete(temporary_directory)
	}

	path, path_error := filepath.join({temporary_directory, "scores.dat"})
	if !testing.expect(t, path_error == nil) do return
	defer delete(path)

	table: High_Score_Table
	status := load_high_score_table(path, &table)
	testing.expect_value(t, status, High_Score_Load_Status.Defaults_Missing)
	testing.expect_value(t, table, default_high_score_table())

	corrupt_data: [HIGH_SCORE_FILE_SIZE]u8
	if !testing.expect(t, os.write_entire_file(path, corrupt_data[:]) == nil) do return
	status = load_high_score_table(path, &table)
	testing.expect_value(t, status, High_Score_Load_Status.Defaults_Corrupt)
	testing.expect_value(t, table, default_high_score_table())

	name: High_Score_Name
	set_high_score_name(&name, "FILE TEST")
	testing.expect(t, insert_high_score(&table, name, 15000))
	testing.expect(t, save_high_score_table_safe(path, &table))

	loaded: High_Score_Table
	testing.expect_value(t, load_high_score_table(path, &loaded), High_Score_Load_Status.Loaded)
	testing.expect_value(t, loaded, table)

	temporary_path, temporary_path_error := filepath.join({temporary_directory, "scores.dat.tmp"})
	if testing.expect(t, temporary_path_error == nil) {
		_, stat_error := os.stat(temporary_path, context.temp_allocator)
		testing.expect(t, stat_error == os.General_Error.Not_Exist)
		delete(temporary_path)
	}
}

// Confirms a completed qualifying run is persisted only after the player
// confirms name entry, never while text is still being edited.
@(test)
game_over_name_submission_persists_only_after_confirmation_test :: proc(t: ^testing.T) {
	temporary_directory, directory_error := os.make_directory_temp(
		"",
		"caverace-high-score-flow-*",
		context.allocator,
	)
	if !testing.expect(t, directory_error == nil) do return
	defer {
		_ = os.remove_all(temporary_directory)
		delete(temporary_directory)
	}

	path, path_error := filepath.join({temporary_directory, "scores.dat"})
	if !testing.expect(t, path_error == nil) do return
	defer delete(path)

	game: Game
	init_game(&game, {}, path)
	completed_run: Maybe(Completed_Run) = Completed_Run {score = 14000}
	open_high_scores(&game.high_scores, completed_run)
	game.screen = .High_Scores

	text_input: Game_Input
	for character, character_index in "miner 9" {
		text_input.text_codepoints[character_index] = character
		text_input.text_count += 1
	}
	update_game(&game, text_input, 0)
	_, stat_error := os.stat(path, context.temp_allocator)
	testing.expect(t, stat_error == os.General_Error.Not_Exist)

	update_game(&game, Game_Input {confirm = true}, 0)
	testing.expect_value(t, game.high_scores.mode, High_Score_Mode.Viewing)
	testing.expect_value(t, game.high_scores.table.entries[0].score, u64(14000))
	testing.expect_value(
		t,
		high_score_name_string(&game.high_scores.table.entries[0].name),
		"MINER 9",
	)

	loaded: High_Score_Table
	testing.expect_value(t, load_high_score_table(path, &loaded), High_Score_Load_Status.Loaded)
	testing.expect_value(t, loaded, game.high_scores.table)
}
