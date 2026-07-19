package caverace

import "core:strconv"
import rl "vendor:raylib"

HIGH_SCORE_ENTRY_COUNT   :: 8
HIGH_SCORE_NAME_MAX      :: 20
HIGH_SCORE_NAME_CAPACITY :: HIGH_SCORE_NAME_MAX + 1

HIGH_SCORE_HEADER_X    :: 140
HIGH_SCORE_SCORE_X     :: 420
HIGH_SCORE_HEADER_Y    :: 126
HIGH_SCORE_FIRST_ROW_Y :: 150
HIGH_SCORE_ROW_STEP    :: 21
HIGH_SCORE_FONT_SIZE   :: 18
HIGH_SCORE_HEADER_SIZE :: 20
HIGH_SCORE_INPUT_Y     :: 316
HIGH_SCORE_INPUT_SIZE  :: 14
HIGH_SCORE_INPUT_SCORE_X :: 465

High_Score_Name :: struct {
	bytes:  [HIGH_SCORE_NAME_CAPACITY]u8,
	length: int,
}

High_Score_Entry :: struct {
	name:  High_Score_Name,
	score: u64,
}

High_Score_Table :: struct {
	entries: [HIGH_SCORE_ENTRY_COUNT]High_Score_Entry,
}

High_Score_Mode :: enum {
	Viewing,
	Entering_Name,
}

High_Score_State :: struct {
	table:         High_Score_Table,
	mode:          High_Score_Mode,
	input_name:    High_Score_Name,
	pending_score: u64,
	// Borrowed from Application and valid for the complete Game lifetime.
	storage_path:  string,
}

High_Score_Update_Result :: struct {
	back_requested: bool,
	table_changed:  bool,
}

high_score_character :: proc(character: rune) -> (normalized: u8, ok: bool) {
	if character >= 'a' && character <= 'z' {
		return u8(character - 'a' + 'A'), true
	}
	if character >= 'A' && character <= 'Z' do return u8(character), true
	if character >= '0' && character <= '9' do return u8(character), true
	if character == ' ' do return ' ', true
	return 0, false
}

append_high_score_character :: proc(name: ^High_Score_Name, character: rune) -> bool {
	if name.length >= HIGH_SCORE_NAME_MAX do return false
	normalized, ok := high_score_character(character)
	if !ok do return false
	name.bytes[name.length] = normalized
	name.length += 1
	name.bytes[name.length] = 0
	return true
}

remove_high_score_character :: proc(name: ^High_Score_Name) -> bool {
	if name.length == 0 do return false
	name.length -= 1
	name.bytes[name.length] = 0
	return true
}

set_high_score_name :: proc(name: ^High_Score_Name, text: string) {
	name^ = {}
	for character in text {
		append_high_score_character(name, character)
		if name.length == HIGH_SCORE_NAME_MAX do break
	}
}

high_score_name_string :: proc(name: ^High_Score_Name) -> string {
	return string(name.bytes[:name.length])
}

high_score_name_is_valid :: proc(name: ^High_Score_Name) -> bool {
	if name.length < 0 || name.length > HIGH_SCORE_NAME_MAX do return false
	for index in 0 ..< name.length {
		character := name.bytes[index]
		if !(
			(character >= 'A' && character <= 'Z') ||
			(character >= '0' && character <= '9') ||
			character == ' '
		) {
			return false
		}
	}
	for index in name.length ..< HIGH_SCORE_NAME_CAPACITY {
		if name.bytes[index] != 0 do return false
	}
	return true
}

default_high_score_table :: proc() -> High_Score_Table {
	table: High_Score_Table
	defaults := [HIGH_SCORE_ENTRY_COUNT]struct {
		name:  string,
		score: u64,
	} {
		{"CLEMENS SCHOTTE", 10000},
		{"HARRO LOCK", 9000},
		{"PAUL VAN CROONENBURG", 8000},
		{"PAUL BOSSELAAR", 7000},
		{"MARIJN SCHOTTE", 6000},
		{"CLEMENS SCHOTTE", 5000},
		{"PAUL VAN CROONENBURG", 4000},
		{"PAUL BOSSELAAR", 3000},
	}
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		set_high_score_name(&table.entries[entry_index].name, defaults[entry_index].name)
		table.entries[entry_index].score = defaults[entry_index].score
	}
	return table
}

high_score_table_is_valid :: proc(table: ^High_Score_Table) -> bool {
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		entry := &table.entries[entry_index]
		if !high_score_name_is_valid(&entry.name) do return false
		if entry_index > 0 && table.entries[entry_index - 1].score < entry.score {
			return false
		}
	}
	return true
}

high_score_insertion_index :: proc(
	table: ^High_Score_Table,
	score: u64,
) -> (index: int, qualifies: bool) {
	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		// Existing equal scores stay first, matching the stable legacy sort.
		if score > table.entries[entry_index].score do return entry_index, true
	}
	return HIGH_SCORE_ENTRY_COUNT, false
}

insert_high_score :: proc(
	table: ^High_Score_Table,
	name: High_Score_Name,
	score: u64,
) -> bool {
	insert_at, qualifies := high_score_insertion_index(table, score)
	if !qualifies do return false
	for entry_index := HIGH_SCORE_ENTRY_COUNT - 1; entry_index > insert_at; entry_index -= 1 {
		table.entries[entry_index] = table.entries[entry_index - 1]
	}
	table.entries[insert_at] = {name = name, score = score}
	return true
}

completed_run_score :: proc(run: Completed_Run) -> u64 {
	if run.score <= 0 do return 0
	return u64(run.score)
}

open_high_scores :: proc(state: ^High_Score_State, completed_run: Maybe(Completed_Run)) {
	state.mode = .Viewing
	state.input_name = {}
	state.pending_score = 0
	if run, ok := completed_run.?; ok {
		score := completed_run_score(run)
		_, qualifies := high_score_insertion_index(&state.table, score)
		if qualifies {
			state.mode = .Entering_Name
			state.pending_score = score
		}
	}
}

update_high_scores :: proc(
	state: ^High_Score_State,
	input: Game_Input,
) -> High_Score_Update_Result {
	result: High_Score_Update_Result
	if state.mode == .Viewing {
		result.back_requested = input.back || input.space_pressed ||
			input.mouse.left_pressed || input.mouse.right_pressed
		return result
	}

	if input.text_backspace do remove_high_score_character(&state.input_name)
	for text_index in 0 ..< input.text_count {
		append_high_score_character(&state.input_name, input.text_codepoints[text_index])
	}

	if input.confirm {
		if state.input_name.length == 0 {
			set_high_score_name(&state.input_name, "PLAYER")
		}
		result.table_changed = insert_high_score(
			&state.table,
			state.input_name,
			state.pending_score,
		)
		state.mode = .Viewing
		state.pending_score = 0
	}
	return result
}

draw_high_scores :: proc(state: ^High_Score_State, background: rl.Texture) {
	rl.DrawTexture(background, 0, 0, rl.WHITE)
	rl.DrawText("NAME", HIGH_SCORE_HEADER_X, HIGH_SCORE_HEADER_Y, HIGH_SCORE_HEADER_SIZE, rl.BLACK)
	rl.DrawText("SCORE", HIGH_SCORE_SCORE_X, HIGH_SCORE_HEADER_Y, HIGH_SCORE_HEADER_SIZE, rl.BLACK)

	for entry_index in 0 ..< HIGH_SCORE_ENTRY_COUNT {
		entry := &state.table.entries[entry_index]
		row_y := HIGH_SCORE_FIRST_ROW_Y + entry_index * HIGH_SCORE_ROW_STEP
		name_text := cstring(raw_data(entry.name.bytes[:]))
		rl.DrawText(name_text, HIGH_SCORE_HEADER_X, i32(row_y), HIGH_SCORE_FONT_SIZE, rl.BLACK)

		score_buffer: [32]byte
		score_text := strconv.write_uint(score_buffer[:len(score_buffer) - 1], entry.score, 10)
		rl.DrawText(
			cstring(raw_data(score_text)),
			HIGH_SCORE_SCORE_X,
			i32(row_y),
			HIGH_SCORE_FONT_SIZE,
			rl.BLACK,
		)
	}

	if state.mode == .Entering_Name {
		input_buffer: [HIGH_SCORE_NAME_CAPACITY + 1]u8
		copy(input_buffer[:], state.input_name.bytes[:state.input_name.length])
		input_buffer[state.input_name.length] = '_'
		rl.DrawText(
			"NEW HIGH SCORE - NAME:",
			HIGH_SCORE_HEADER_X,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)
		rl.DrawText(
			cstring(raw_data(input_buffer[:])),
			300,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)

		score_buffer: [32]byte
		score_text := strconv.write_uint(score_buffer[:len(score_buffer) - 1], state.pending_score, 10)
		rl.DrawText(
			cstring(raw_data(score_text)),
			HIGH_SCORE_INPUT_SCORE_X,
			HIGH_SCORE_INPUT_Y,
			HIGH_SCORE_INPUT_SIZE,
			rl.BLACK,
		)
	}
}
