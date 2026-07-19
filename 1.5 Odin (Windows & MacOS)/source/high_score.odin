package caverace

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

// High_Score_Name stores a validated, zero-terminated fixed-capacity name for
// rendering and the on-disk leaderboard format.
High_Score_Name :: struct {
	bytes:  [HIGH_SCORE_NAME_CAPACITY]u8,
	length: int,
}

// High_Score_Entry pairs one normalized name with its unsigned persisted score.
High_Score_Entry :: struct {
	name:  High_Score_Name,
	score: u64,
}

// High_Score_Table owns the fixed, descending leaderboard shared by screen logic
// and persistence.
High_Score_Table :: struct {
	entries: [HIGH_SCORE_ENTRY_COUNT]High_Score_Entry,
}

// High_Score_Mode distinguishes passive table viewing from an active qualifying
// name-entry session.
High_Score_Mode :: enum {
	Viewing,
	Entering_Name,
}

// High_Score_State owns only the current table and entry workflow. Persistence
// paths remain with Application and never enter screen/domain state.
High_Score_State :: struct {
	table:         High_Score_Table,
	mode:          High_Score_Mode,
	input_name:    High_Score_Name,
	pending_score: u64,
}

// High_Score_Update_Result reports screen dismissal and whether a confirmed name
// changed the table and therefore requires persistence.
High_Score_Update_Result :: struct {
	back_requested: bool,
	table_changed:  bool,
}

// high_score_character normalizes one accepted ASCII rune for deterministic
// fixed-size name entry and rejects unsupported input from the platform layer.
high_score_character :: proc(character: rune) -> (normalized: u8, ok: bool) {
	if character >= 'a' && character <= 'z' {
		return u8(character - 'a' + 'A'), true
	}
	if character >= 'A' && character <= 'Z' do return u8(character), true
	if character >= '0' && character <= '9' do return u8(character), true
	if character == ' ' do return ' ', true
	return 0, false
}

// append_high_score_character appends one normalized character while enforcing
// the legacy name limit during text input and default-table construction.
append_high_score_character :: proc(name: ^High_Score_Name, character: rune) -> bool {
	if name.length >= HIGH_SCORE_NAME_MAX do return false
	normalized, ok := high_score_character(character)
	if !ok do return false
	name.bytes[name.length] = normalized
	name.length += 1
	name.bytes[name.length] = 0
	return true
}

// remove_high_score_character applies one backspace to the fixed name buffer
// while preserving its C-compatible zero terminator.
remove_high_score_character :: proc(name: ^High_Score_Name) -> bool {
	if name.length == 0 do return false
	name.length -= 1
	name.bytes[name.length] = 0
	return true
}

// set_high_score_name replaces a fixed name from trusted defaults or fallback
// text using the same normalization rules as interactive entry.
set_high_score_name :: proc(name: ^High_Score_Name, text: string) {
	name^ = {}
	for character in text {
		append_high_score_character(name, character)
		if name.length == HIGH_SCORE_NAME_MAX do break
	}
}

// high_score_name_string exposes the occupied bytes as a borrowed Odin string
// for comparisons, persistence tests, and other non-C consumers.
high_score_name_string :: proc(name: ^High_Score_Name) -> string {
	return string(name.bytes[:name.length])
}

// high_score_name_is_valid verifies length, allowed characters, and trailing
// zero bytes before persisted data is accepted or written.
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

// default_high_score_table builds the original leaderboard used on first run
// and whenever stored data is missing or invalid.
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

// high_score_table_is_valid checks every entry and descending score order at
// the persistence boundary.
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

// high_score_insertion_index finds the stable position for a completed score;
// existing ties remain ahead to match the legacy ordering.
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

// insert_high_score shifts lower entries and adds a qualifying score after the
// player confirms their name.
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

// completed_run_score converts the signed gameplay score to the unsigned file
// representation while safely mapping non-positive values to zero.
completed_run_score :: proc(run: Completed_Run) -> u64 {
	if run.score <= 0 do return 0
	return u64(run.score)
}

// open_high_scores prepares viewing or name-entry mode whenever Game routes to
// the leaderboard, optionally carrying a just-completed run.
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

// update_high_scores handles one frame of dismissal or fixed-buffer name entry
// and reports when persistence is required.
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
